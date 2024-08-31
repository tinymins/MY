--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Target')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 目标获取相关接口
--------------------------------------------------------------------------------

-- 取得目标类型和ID
-- (dwType, dwID) X.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) X.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
function X.GetTarget(...)
	local object = ...
	if select('#', ...) == 0 then
		object = X.GetClientPlayer()
	end
	if object and object.GetTarget then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end

-- 取得目标的目标类型和ID
-- (dwType, dwID) X.GetTargetTarget()       -- 取得自己当前的目标的目标类型和ID
-- (dwType, dwID) X.GetTargetTarget(object) -- 取得指定操作对象当前的目标的目标类型和ID
function X.GetTargetTarget(object)
	local nTarType, dwTarID = X.GetTarget(object)
	local KTar = X.GetTargetHandle(nTarType, dwTarID)
	if not KTar then
		return
	end
	return X.GetTarget(KTar)
end

X.RegisterRestriction('X.SET_TARGET', { ['*'] = true, intl = false })

-- 根据 dwType 类型和 dwID 设置目标
-- (void) X.SetTarget([number dwType, ]number dwID)
-- (void) X.SetTarget([number dwType, ]string szName)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function X.SetTarget(arg0, arg1)
	local dwType, dwID, szNames
	if X.IsUserdata(arg0) then
		dwType, dwID = TARGET[X.GetObjectType(arg0)], arg0.dwID
	elseif X.IsString(arg0) then
		szNames = arg0
	elseif X.IsNumber(arg0) then
		if X.IsNil(arg1) then
			dwID = arg0
		elseif X.IsString(arg1) then
			dwType, szNames = arg0, arg1
		elseif X.IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		end
	end
	if not dwID and not szNames then
		return
	end
	if dwID and not dwType then
		dwType = X.IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC
	end
	if szNames then
		local tTarget = {}
		for _, szName in pairs(X.SplitString(szNames:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		if not dwID and (not dwType or dwType == TARGET.NPC) then
			for _, p in ipairs(X.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and (not dwType or dwType == TARGET.PLAYER) then
			for _, p in ipairs(X.GetNearPlayer()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.PLAYER, p.dwID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return false
	end
	if dwType == TARGET.PLAYER then
		if X.IsInShieldedMap() and not X.IsParty(dwID) and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetTarget', 'Set target to player is forbiden in current map.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.NPC then
		local npc = X.GetNpc(dwID)
		if npc and not npc.IsSelectable() and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetTarget', 'Set target to unselectable npc.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.DOODAD then
		if X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetTarget', 'Set target to doodad.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	end
	SetTarget(dwType, dwID)
	return true
end

do
local CALLBACK_LIST
-- 获取到当前角色并执行函数
-- @param {function} callback 回调函数
function X.WithClientPlayer(callback)
	local me = X.GetClientPlayer()
	if me then
		X.SafeCall(callback, me)
	elseif CALLBACK_LIST then
		table.insert(CALLBACK_LIST, callback)
	else
		CALLBACK_LIST = {callback}
		X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), function()
			local me = X.GetClientPlayer()
			if me then
				for _, callback in ipairs(CALLBACK_LIST) do
					X.SafeCall(callback, me)
				end
				CALLBACK_LIST = nil
				X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), false)
			end
		end)
	end
end
end

-- 获取指定名字的右键菜单
function X.InsertPlayerContextMenu(t, szName, dwID, szGlobalID)
	-- 数据库获取 dwID, szGlobalID 补全信息
	if (not dwID or not szGlobalID) and _G.MY_Farbnamen and _G.MY_Farbnamen.Get then
		local tInfo = _G.MY_Farbnamen.Get(szName)
		if tInfo then
			if not dwID then
				dwID = tonumber(tInfo.dwID)
			end
			if not szGlobalID and X.IsGlobalID(tInfo.szGlobalID) then
				szGlobalID = tInfo.szGlobalID
			end
		end
	end
	-- 跨服处理
	local szOriginName, szServerName = X.DisassemblePlayerGlobalName(szName, true)
	-- 复制
	table.insert(t, {
		szOption = _L['Copy to chat input'],
		fnAction = function()
			X.SendChat(X.GetClientPlayer().szName, '[' .. szName .. ']')
		end,
	})
	-- 密聊 好友 邀请入帮 跟随
	X.Call(InsertPlayerCommonMenu, t, dwID, szName)
	-- 组队
	if szName and InsertInviteTeamMenu then
		InsertInviteTeamMenu(t, szName)
	end
	-- 查看装备
	if (dwID and X.GetClientPlayerID() ~= dwID) or (szGlobalID and szGlobalID ~= X.GetClientPlayerGlobalID()) then
		table.insert(t, {
			szOption = _L['View equipment'],
			fnAction = function()
				if szServerName and X.IsGlobalID(szGlobalID) then
					local dwServerID = X.GetServerIDByName(szServerName)
					X.ViewOtherPlayerByGlobalID(dwServerID, szGlobalID)
				elseif dwID then
					X.ViewOtherPlayerByID(dwID)
				end
			end,
		})
	end
	-- 查看名剑大会信息
	table.insert(t, {
		szOption = g_tStrings.LOOKUP_CORPS,
		-- fnDisable = function() return not X.GetPlayer(dwID) end,
		fnAction = function()
			X.UI.CloseFrame('ArenaCorpsPanel')
			OpenArenaCorpsPanel(true, dwID)
		end,
	})
	-- 加入角色备注
	if _G.MY_PlayerRemark and _G.MY_PlayerRemark.OpenEditPanel then
		table.insert(t, {
			szOption = _L['Edit in MY_PlayerRemark'],
			fnAction = function()
				_G.MY_PlayerRemark.OpenEditPanel(szServerName, dwID, szOriginName, szGlobalID)
			end,
		})
	end
	-- 奇穴 -- 标记
	if dwID and InsertTargetMenu then
		local tx = {}
		InsertTargetMenu(tx, TARGET.PLAYER, dwID, szName)
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.LOOKUP_INFO or v.szOption == g_tStrings.STR_LOOKUP_MORE then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then -- 查看奇穴
						table.insert(t, vv)
						break
					end
				end
				break
			end
		end
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.STR_ARENA_INVITE_TARGET -- 邀请入名剑队
			or v.szOption == g_tStrings.LOOKUP_INFO             -- 查看更多信息
			or v.szOption == g_tStrings.STR_LOOKUP_MORE         -- 查看更多
			or v.szOption == g_tStrings.CHANNEL_MENTOR          -- 师徒
			or v.szOption == g_tStrings.STR_ADD_SHANG           -- 发布悬赏
			or v.szOption == g_tStrings.STR_MARK_TARGET         -- 标记目标
			or v.szOption == g_tStrings.STR_MAKE_TRADDING       -- 交易
			or v.szOption == g_tStrings.REPORT_RABOT            -- 举报外挂
			then
				table.insert(t, v)
			end
		end
	end

	if IsCtrlKeyDown() and X.IsDebugClient(true) then
		table.insert(t, {
			szOption = _L['Copy debug information'],
			fnAction = function()
				local tDebugInfo
				if _G.MY_Farbnamen and _G.MY_Farbnamen.Get then
					tDebugInfo = _G.MY_Farbnamen.Get(szName)
				else
					tDebugInfo = {
						szName = szName,
						dwID = dwID,
						szGlobalID = szGlobalID,
					}
				end
				X.UI.OpenTextEditor(X.EncodeLUAData(tDebugInfo, '\t'))
			end,
		})
	end

	return t
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
