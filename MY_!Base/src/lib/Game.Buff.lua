--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Buff')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do local BUFF_CACHE = {}
function X.GetBuffName(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. '_' .. dwLevel
	end
	if not BUFF_CACHE[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			BUFF_CACHE[xKey] = X.Pack(tLine.szName, tLine.dwIconID)
		else
			local szName = 'BUFF#' .. dwBuffID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			BUFF_CACHE[xKey] = X.Pack(szName, 1436)
		end
	end
	return X.Unpack(BUFF_CACHE[xKey])
end
end

function X.GetBuffIconID(dwBuffID, dwLevel)
	local nIconID = Table_GetBuffIconID(dwBuffID, dwLevel)
	if nIconID ~= -1 then
		return nIconID
	end
end

-- 通过BUFF名称获取BUFF信息
-- (table) X.GetBuffByName(szName)
do local CACHE
function X.GetBuffByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}, nil, nil
		local Buff = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Buff', true)
		if Buff then
			for i = 1, Buff:GetRowCount() do
				tLine = Buff:GetRow(i)
				if tLine and tLine.szName then
					tExist = aCache[tLine.szName]
					if not tExist or (tLine.bShow == 1 and tExist.bShow == 0) then
						aCache[tLine.szName] = tLine
					end
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

--------------------------------------------------------------------------------
-- 气劲
--------------------------------------------------------------------------------

do
-- “气劲下标” 到 “气劲” 的映射缓存
local BUFF_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_PROXY = setmetatable({}, { __mode = 'v' })
-- “目标对象” 到 “气劲列表” 的映射缓存
local BUFF_LIST_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_LIST_PROXY = setmetatable({}, { __mode = 'v' })
-- 缓存保护
local function Reject()
	assert(false, X.NSFormatString('Modify buff list from {$NS}.GetBuffList is forbidden!'))
end
-- 缓存刷新
local function GeneObjectBuffCache(KObject, nTarIndex)
	-- 气劲列表原数据与代理表创建
	local aList, pList = BUFF_LIST_CACHE[KObject], BUFF_LIST_PROXY[KObject]
	if not aList or not pList then
		aList = {}
		pList = setmetatable({}, {
			__index = aList,
			__newindex = Reject,
			__metatable = { const_table = aList },
		})
		BUFF_LIST_CACHE[KObject] = aList
		BUFF_LIST_PROXY[KObject] = pList
	end
	-- 刷新气劲列表缓存
	local nCount, tBuff, pBuff = 0, nil, nil
	for i = 1, KObject.GetBuffCount() or 0 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
		if dwID then
			tBuff, pBuff = BUFF_CACHE[nIndex], BUFF_PROXY[nIndex]
			if not tBuff or not pBuff then
				tBuff = {}
				pBuff = setmetatable({}, {
					__index = tBuff,
					__newindex = Reject,
					__metatable = { const_table = tBuff },
				})
				BUFF_CACHE[nIndex] = tBuff
				BUFF_PROXY[nIndex] = pBuff
			end
			nCount = nCount + 1
			tBuff.szKey        = dwSkillSrcID .. ':' .. dwID .. ',' .. nLevel
			tBuff.dwID         = dwID
			tBuff.nLevel       = nLevel
			tBuff.bCanCancel   = bCanCancel
			tBuff.nEndFrame    = nEndFrame
			tBuff.nIndex       = nIndex
			tBuff.nStackNum    = nStackNum
			tBuff.dwSkillSrcID = dwSkillSrcID
			tBuff.bValid       = bValid
			tBuff.szName, tBuff.nIcon = X.GetBuffName(dwID, nLevel)
			aList[nCount] = BUFF_PROXY[nIndex]
		end
	end
	-- 删除对象过期气劲缓存
	for i = nCount + 1, aList.nCount or 0 do
		aList[i] = nil
	end
	aList.nCount = nCount
	-- 如果有目标气劲下标，直接返回指定气劲
	if nTarIndex then
		return BUFF_PROXY[nTarIndex]
	end
	return pList, nCount
end

-- 获取对象的buff列表和数量
-- (table, number) X.GetBuffList(KObject)
-- 注意：返回表每帧会重复利用，如有缓存需求请调用X.CloneBuff接口固化数据
function X.GetBuffList(KObject)
	if KObject then
		return GeneObjectBuffCache(KObject)
	end
	return X.CONSTANT.EMPTY_TABLE, 0
end

-- 获取对象的buff
-- tBuff: {[dwID1] = nLevel1, [dwID2] = nLevel2}
-- (table) X.GetBuff(dwID[, nLevel[, dwSkillSrcID]])
-- (table) X.GetBuff(KObject, dwID[, nLevel[, dwSkillSrcID]])
-- (table) X.GetBuff(tBuff[, dwSkillSrcID])
-- (table) X.GetBuff(KObject, tBuff[, dwSkillSrcID])
function X.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
	local tBuff = {}
	if type(dwID) == 'table' then
		tBuff, dwSkillSrcID = dwID, nLevel
	elseif type(dwID) == 'number' then
		if type(nLevel) == 'number' then
			tBuff[dwID] = nLevel
		else
			tBuff[dwID] = 0
		end
	end
	if X.IsNumber(dwSkillSrcID) and dwSkillSrcID > 0 then
		if KObject.GetBuffByOwner then
			for k, v in pairs(tBuff) do
				local KBuffNode = KObject.GetBuffByOwner(k, v, dwSkillSrcID)
				if KBuffNode then
					return GeneObjectBuffCache(KObject, KBuffNode.nIndex)
				end
			end
		else
			for _, buff in X.ipairs_c(X.GetBuffList(KObject)) do
				if (tBuff[buff.dwID] == buff.nLevel or tBuff[buff.dwID] == 0) and buff.dwSkillSrcID == dwSkillSrcID then
					return buff
				end
			end
		end
	else
		for k, v in pairs(tBuff) do
			local KBuffNode = KObject.GetBuff(k, v)
			if KBuffNode then
				return GeneObjectBuffCache(KObject, KBuffNode.nIndex)
			end
		end
	end
end
end

-- 点掉自己的buff
-- (table) X.CancelBuff(KObject, dwID[, nLevel = 0])
function X.CancelBuff(KObject, dwID, nLevel)
	local KBuffNode = KObject.GetBuff(dwID, nLevel or 0)
	if KBuffNode then
		KObject.CancelBuff(KBuffNode.nIndex)
	end
end

function X.CloneBuff(buff, dst)
	if not dst then
		dst = {}
	end
	dst.szKey = buff.szKey
	dst.dwID = buff.dwID
	dst.nLevel = buff.nLevel
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	dst.bCanCancel = buff.bCanCancel
	dst.nEndFrame = buff.nEndFrame
	dst.nIndex = buff.nIndex
	dst.nStackNum = buff.nStackNum
	dst.dwSkillSrcID = buff.dwSkillSrcID
	dst.bValid = buff.bValid
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	return dst
end

do
local BUFF_CACHE
function X.IsBossFocusBuff(dwID, nLevel, nStackNum)
	if not BUFF_CACHE then
		BUFF_CACHE = {}
		local BossFocusBuff = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('BossFocusBuff', true)
		if BossFocusBuff then
			if BossFocusBuff then
				for i = 2, BossFocusBuff:GetRowCount() do
					local tLine = BossFocusBuff:GetRow(i)
					if tLine then
						if not BUFF_CACHE[tLine.nBuffID] then
							BUFF_CACHE[tLine.nBuffID] = {}
						end
						BUFF_CACHE[tLine.nBuffID][tLine.nBuffLevel] = tLine.nBuffStack
					end
				end
			end
		end
	end
	return BUFF_CACHE[dwID] and BUFF_CACHE[dwID][nLevel] and nStackNum >= BUFF_CACHE[dwID][nLevel]
end
end

function X.IsVisibleBuff(dwID, nLevel)
	if Table_BuffIsVisible(dwID, nLevel) then
		return true
	end
	if X.IsBossFocusBuff(dwID, nLevel, 0xffff) then
		return true
	end
	return false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
