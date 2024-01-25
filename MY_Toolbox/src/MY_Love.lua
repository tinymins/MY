--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 剑侠情缘
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_Love'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local LOVER_DATA = {
	dwID = 0, -- 情缘 ID
	szName = '', -- 情缘名字
	szTitle = '', -- 我的结缘称号
	nSendItem = '', -- 结缘时送对方的东西
	nReceiveItem = '', -- 结缘时对方送的东西
	dwAvatar = 0, -- 情缘头像
	dwForceID = 0, -- 门派
	nRoleType = 0, -- 情缘体型（0：无情缘）
	nLoverType = 0, -- 情缘类型（单向：0，双向：1）
	nLoverTime = 0, -- 情缘开始时间（单位：秒）
	szLoverTitle = '', -- 对方结缘称号
	dwMapID = 0, -- 所在地图
	bOnline = false, -- 是否在线
}

local O = X.CreateUserSettingsModule('MY_Love', _L['Target'], {
	bQuiet = { -- 免打扰（拒绝其它人的查看请求）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szNone = { -- 没情缘时显示的字
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = _L['Singleton'],
	},
	szJabber = { -- 搭讪用语
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = _L['Hi, I seem to meet you somewhere ago'],
	},
	szSign = { -- 情缘宣言（个性签名）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	bAutoFocus = { -- 自动焦点
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bHookPlayerView = { -- 在查看装备界面上显示情缘
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoReplyLover = { -- 无需确认即可查看我的情缘
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = X.SetmetaLazyload({
	-- 导出常量
	nLoveAttraction = 200,
	nDoubleLoveAttraction = 800,
	-- 本地变量
	aAutoSay = { -- 神秘表白语（单数：表白，双数：取消单恋通知）
		_L['Some people fancy you.'],
		_L['Other side terminate love you.'],
		_L['Some people fall in love with you.'],
		_L['Other side gave up love you.'],
	},
	lover = X.Clone(LOVER_DATA),
	tOtherLover = {}, -- 查看的情缘数据
	tViewer = {}, -- 等候查看您的玩家列表
	aLoverItem = { -- 可用于结缘的烟花信息
		{ nItem = 1, szTitle = _L['FIREWORK_TITLE_67291'], aUIID = {67291, 151179, 160465, 163486} }, -- 真橙之心
		{ nItem = 2, szTitle = _L['FIREWORK_TITLE_151303'], aUIID = {151303, 160961, 161078} }, -- 无间长情 真心人
		{ nItem = 3, szTitle = _L['FIREWORK_TITLE_151743'], aUIID = {151743, 160964, 161079} }, -- 千衷不渝
		{ nItem = 4, szTitle = _L['FIREWORK_TITLE_152844'], aUIID = {152844, 160962} }, -- 心不释手
		{ nItem = 5, szTitle = _L['FIREWORK_TITLE_154319'], aUIID = {154319, 160965} }, -- 鸿福齐天 惜福人
		{ nItem = 6, szTitle = _L['FIREWORK_TITLE_154320'], aUIID = {154320, 160968} }, -- 情人心 一心人
		{ nItem = 7, szTitle = _L['FIREWORK_TITLE_153641'], aUIID = {153641, 156447, 160963} }, -- 素月流天
		{ nItem = 8, szTitle = _L['FIREWORK_TITLE_153642'], aUIID = {153642, 160966} }, -- 万家灯火
		{ nItem = 9, szTitle = _L['FIREWORK_TITLE_156413'], aUIID = {156413, 160970} }, -- 冰荷逢春 有福人
		{ nItem = 10, szTitle = _L['FIREWORK_TITLE_156446'], aUIID = {154313, 156446, 160967} }, -- 荷渡鸾桥 同心人
		{ nItem = 11, szTitle = _L['FIREWORK_TITLE_157096'], aUIID = {157096, 160969} }, -- 莲心并蒂 恒心人
		{ nItem = 12, szTitle = _L['FIREWORK_TITLE_157378'], aUIID = {157378, 160971} }, -- 素心竹月 知心人
		{ nItem = 13, szTitle = _L['FIREWORK_TITLE_158339'], aUIID = {158339, 160972} }, -- 流光绮梦 衷情人
		{ nItem = 14, szTitle = _L['FIREWORK_TITLE_159250'], aUIID = {159250, 160974} }, -- 莲心问情 倾心人
		{ nItem = 15, szTitle = _L['FIREWORK_TITLE_160982'], aUIID = {68338, 160982} }, -- 海誓山盟
		{ nItem = 16, szTitle = _L['FIREWORK_TITLE_160993'], aUIID = {160993, 163339} }, -- 鹊桥引仙 相思人
		{ nItem = 17, szTitle = _L['FIREWORK_TITLE_161367'], aUIID = {161367, 163340} }, -- 金缕诉情 深情人
		{ nItem = 18, szTitle = _L['FIREWORK_TITLE_161887'], aUIID = {161887, 163341} }, -- 蝶梦剪窗 称心人
		{ nItem = 19, szTitle = _L['FIREWORK_TITLE_162307'], aUIID = {162307, 163435} }, -- 花语相思 还愿人
		{ nItem = 20, szTitle = _L['FIREWORK_TITLE_162308'], aUIID = {162308, 163427} }, -- 在吗
		{ nItem = 21, szTitle = _L['FIREWORK_TITLE_158577'], aUIID = {158577, 160973} }, -- 金鸾喻情 玲珑心
		-- { nItem = 63, szTitle = X.GetItemNameByUIID(65625), aUIID = {65625} }, -- 测试用 焰火棒
	},
	tLoverItem = {},
	nPendingItem = 0, -- 请求结缘烟花nItem序号缓存
	aStorageData = nil, -- 防止被恢复界面配置篡改
}, {
	PW = function() return X.SECRET['FILE::LOVE_BACKUP_PW'] end,
})
for _, p in ipairs(D.aLoverItem) do
	assert(not D.tLoverItem[p.nItem], 'MY_Love item index conflict: ' .. p.nItem)
	D.tLoverItem[p.nItem] = p
end

X.RegisterRemoteStorage(
	'MY_Love', 32, 88,
	function(aBit)
		local dwID, nTime, nType, nSendItem, nReceiveItem, nCrc = 0, 0, 0, 0, 0, 6
		local aByte = {}
		for i = 1, #aBit, 8 do
			local nByte = 0
			for j = 1, 8 do
				nByte = nByte * 2 + aBit[(i - 1) + j]
			end
			table.insert(aByte, nByte)
		end
		-- 1 crc
		for i = 1, #aByte do
			nCrc = X.NumberBitXor(nCrc, aByte[i])
		end
		if nCrc == 0 then
			-- 2 - 5 dwID
			for i = 5, 2, -1 do
				dwID = X.NumberBitShl(dwID, 8)
				dwID = X.NumberBitOr(dwID, aByte[i])
			end
			-- 6 - 9 nTime
			for i = 9, 6, -1 do
				nTime = X.NumberBitShl(nTime, 8)
				nTime = X.NumberBitOr(nTime, aByte[i])
			end
			-- 10 (nType << 4) | ((nSendItem >> 2) & 0xf)
			nType = X.NumberBitShr(aByte[10], 4)
			nSendItem = X.NumberBitShl(X.NumberBitAnd(aByte[10], 0xf), 2)
			-- 11 (nSendItem & 0x3) << 6 | (nReceiveItem & 0x3f)
			nSendItem = X.NumberBitOr(nSendItem, X.NumberBitShr(aByte[11], 6))
			nReceiveItem = X.NumberBitAnd(aByte[11], 0x3f)
			return dwID, nTime, nType, nSendItem, nReceiveItem
		end
		return 0, 0, 0, 0, 0
	end,
	function(...)
		local dwID, nTime, nType, nSendItem, nReceiveItem = ...
		assert(dwID >= 0 and dwID <= 0xffffffff, 'Value of dwID out of 32bit unsigned int range!')
		assert(nTime >= 0 and nTime <= 0xffffffff, 'Value of nTime out of 32bit unsigned int range!')
		assert(nType >= 0 and nType <= 0xf, 'Value of nType out of range 4bit unsigned int range!')
		assert(nSendItem >= 0 and nSendItem <= 0x3f, 'Value of nSendItem out of 6bit unsigned int range!')
		assert(nReceiveItem >= 0 and nReceiveItem <= 0x3f, 'Value of nReceiveItem out of 6bit unsigned int range!')
		local aByte, nCrc = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 6
		-- 2 - 5 dwID
		for i = 2, 5 do
			aByte[i] = X.NumberBitAnd(dwID, 0xff)
			dwID = X.NumberBitShr(dwID, 8)
		end
		-- 6 - 9 nTime
		for i = 6, 9 do
			aByte[i] = X.NumberBitAnd(nTime, 0xff)
			nTime = X.NumberBitShr(nTime, 8)
		end
		-- 10 (nType << 4) | ((nSendItem >> 2) & 0xf)
		aByte[10] = X.NumberBitOr(X.NumberBitShl(nType, 4), X.NumberBitAnd(X.NumberBitShr(nSendItem, 2), 0xf))
		-- 11 (nSendItem & 0x3) << 6 | (nReceiveItem & 0x3f)
		aByte[11] = X.NumberBitOr(X.NumberBitShl(X.NumberBitAnd(nSendItem, 0x3), 6), X.NumberBitAnd(nReceiveItem, 0x3f))
		-- 1 crc
		for i = 2, #aByte do
			nCrc = X.NumberBitXor(nCrc, aByte[i])
		end
		aByte[1] = nCrc

		local aBit = {}
		for _, nByte in ipairs(aByte) do
			local aByteBit = { 0, 0, 0, 0, 0, 0, 0, 0 }
			for i = 8, 1, -1 do
				aByteBit[i] = math.mod(nByte, 2)
				nByte = math.floor(nByte / 2)
			end
			for _, v in ipairs(aByteBit) do
				table.insert(aBit, v)
			end
		end
		return aBit
	end)

--[[
剑侠情缘
========
1. 每个角色只允许有一个情缘，情缘必须是好友
2. 爱要坦荡荡，情缘信息无法隐藏（队友可直接查看，其它人则等您确认）
3. 建立双向情缘，要求六重好友组队并在5尺内，背包中要有真橙之心，并选其为目标，再点插件确认
4. 单向情缘，可以选择一个 3重好感以上的在线好友，对方会收到匿名通知
5. 情缘可以随时单向解除，但会密聊通知对方（单向情缘若不在线则不通知）
6. 若删除情缘好友则自动解除情缘关系


心动情缘：
	XXXXXXXXX (198大号字 ...) [斩情丝]
	类型：单恋/双向  时长：X天X小时X分钟X秒

	与六重队友结连理：[___________] （距离4尺内，带一个真橙之心）
	单恋某个三重好友：[___________] （要求在线，匿名通知对方）
	没情缘时显示什么：[___________]  [**] 开启免打扰模式

	情缘宣言： [________________________________________________________]
	搭讪用语： [________________________________________________________]

小提示：
	1. 仅安装本插件的玩家才能相互看见设置
	2. 情缘可以单方面删除，双向情缘会通过密聊告知对方
	3. 非队友查看情缘时目会弹出确认框（可开启免打扰屏蔽）
--]]

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------

local Schema = X.Schema
local BACKUP_DATA_SCHEMA = X.Schema.Record({
	szName = X.Schema.String,
	szUUID = X.Schema.String,
	szLoverName = X.Schema.String,
	szLoverUUID = X.Schema.String,
	nLoverType = X.Schema.Number,
	nLoverTime = X.Schema.Number,
	nSendItem = X.Schema.Number,
	nReceiveItem = X.Schema.Number,
})

-- 功能屏蔽
function D.IsShielded()
	return X.ENVIRONMENT.GAME_BRANCH == 'classic'
end

-- 获取背包指定ID物品列表
function D.GetBagItemPos(aUIID)
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it then
				for _, nUIID in ipairs(aUIID) do
					if it.nUiId == nUIID then
						return dwBox, dwX
					end
				end
			end
		end
	end
end

-- 根据背包坐标获取物品及数量
function D.GetBagItemNum(dwBox, dwX)
	local item = GetPlayerItem(X.GetClientPlayer(), dwBox, dwX)
	if not item then
		return 0
	elseif not item.bCanStack then
		return 1
	else
		return item.nStackNum
	end
end

-- 是否可结双向好友，并返回真橙之心的位置
function D.GetDoubleLoveItem(aInfo, aUIID)
	if aInfo then
		local tar = X.GetPlayer(aInfo.id)
		if aInfo.attraction >= D.nDoubleLoveAttraction and tar and X.IsParty(tar.dwID) and X.GetDistance(tar) <= 4 then
			return D.GetBagItemPos(aUIID)
		end
	end
end

function D.UseDoubleLoveItem(aInfo, aUIID, callback)
	local dwBox, dwX = D.GetDoubleLoveItem(aInfo, aUIID)
	if dwBox then
		local nNum = D.GetBagItemNum(dwBox, dwX)
		SetTarget(TARGET.PLAYER, aInfo.id)
		OnUseItem(dwBox, dwX)
		local nFinishTime = GetTime() + 500
		X.BreatheCall(function()
			local me = X.GetClientPlayer()
			if not me then
				return 0
			end
			local nType = X.GetOTActionState(me)
			if nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_ITEM_SKILL
			or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE then -- otActionItemSkill
				nFinishTime = GetTime() + 500
			elseif GetTime() > nFinishTime then
				callback(D.GetBagItemNum(dwBox, dwX) ~= nNum)
				return 0
			end
		end)
	end
end

function D.CreateFireworkSelect(callback)
	local nCol = 3 -- 按钮列数
	local nMargin = 30 -- 左右边距
	local nLineHeight = 40 -- 行高
	local nItemWidth = 100 -- 按钮宽度
	local nItemHeight = 30 -- 按钮高度
	local nItemPadding = 10 -- 按钮间距
	local ui = X.UI.CreateFrame('MY_Love_SetLover', {
		w = nItemWidth * nCol + nMargin * 2 + nItemPadding * (nCol - 1),
		h = 50 + math.ceil(#D.aLoverItem / nCol) * nLineHeight + 30,
		text = _L['Select a firework'],
	})
	local nX, nY = nMargin, 50
	for i, p in ipairs(D.aLoverItem) do
		ui:Append('WndButton', {
			x = nX, y = nY + (nLineHeight - nItemHeight) / 2, w = nItemWidth, h = nItemHeight,
			text = X.GetItemNameByUIID(p.aUIID[1]),
			enable = not not D.GetBagItemPos(p.aUIID),
			onClick = function() callback(p) end,
			tip = {
				render = p.szTitle,
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		})
		if i % nCol == 0 then
			nX = nMargin
			nY = nY + nLineHeight
		else
			nX = nX + nItemWidth + nItemPadding
		end
	end
end

-- 加入校验和确保数据不被篡改（0-255）
function D.EncodeString(szData)
	local nCrc = 0
	for i = 1, string.len(szData) do
		nCrc = (nCrc + string.byte(szData, i)) % 255
	end
	return string.format('%02x', nCrc) .. szData
end

-- 剔除校验和提取原始数据
function D.DecodeHMString(szData)
	if not X.IsEmpty(szData) and X.IsString(szData) and string.len(szData) > 2 then
		local nCrc = 0
		for i = 3, string.len(szData) do
			nCrc = (nCrc + string.byte(szData, i)) % 255
		end
		if nCrc == tonumber(string.sub(szData, 1, 2), 16) then
			return string.sub(szData, 3)
		end
	end
end

-- 获取情缘信息（成功返回数据 + rawInfo，失败 nil）
function D.GetLover()
	if MY_Love.IsShielded() then
		return
	end
	local szKey, me = '#HM#LOVER#', X.GetClientPlayer()
	if not me or not X.CanUseOnlineRemoteStorage() then
		return
	end
	local dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem = X.GetRemoteStorage('MY_Love')
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for i = #aFriend, 1, -1 do
			local info = aFriend[i]
			if nLoverTime == 0 then -- 时间为非0表示不是第一次了 拒绝加载海鳗数据
				local bMatch = string.sub(info.remark, 1, string.len(szKey)) == szKey
				-- fetch data
				-- 兼容海鳗：情缘信息从好友备注中提取数据
				if bMatch then
					local szData = D.DecodeHMString(string.sub(info.remark, string.len(szKey) + 1))
					if not X.IsEmpty(szData) then
						local data = X.SplitString(szData, '#')
						local nType = data[1] and tonumber(data[1])
						local nTime = data[2] and tonumber(data[2])
						if nType and nTime and (nType == 0 or nType == 1) and (nTime > 0 and nTime < GetCurrentTime()) then
							dwLoverID = info.id
							nLoverType = nType
							nLoverTime = nTime
							nSendItem = 0
							nReceiveItem = 0
							X.SetRemoteStorage('MY_Love', dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem)
							D.UpdateProtectData()
						end
					end
					me.SetFellowshipRemark(info.id, '')
				end
			end
			-- 遍历到情缘，获取基础信息并返回
			if info.id == dwLoverID and info.istwoway then
				local fellowClient = GetFellowshipCardClient()
				if fellowClient then
					local card = fellowClient.GetFellowshipCardInfo(info.id)
					if not card or (card.dwMapID == 0 and info.isonline) then
						fellowClient.ApplyFellowshipCard(255, {info.id})
					else
						return {
							dwID = dwLoverID,
							szName = info.name,
							szTitle = D.tLoverItem[D.lover.nSendItem] and D.tLoverItem[D.lover.nSendItem].szTitle or '',
							nSendItem = nSendItem,
							nReceiveItem = nReceiveItem,
							nLoverType = nLoverType,
							nLoverTime = nLoverTime,
							szLoverTitle = D.tLoverItem[D.lover.nReceiveItem] and D.tLoverItem[D.lover.nReceiveItem].szTitle or '',
							dwAvatar = card.dwMiniAvatarID,
							dwForceID = card.dwForceID,
							nRoleType = card.nRoleType,
							dwMapID = card.dwMapID,
							bOnline = info.isonline,
						}
					end
				end
			end
		end
	end
end

-- 转换好友信息为情缘信息
function D.UpdateLocalLover()
	if MY_Love.IsShielded() then
		return
	end
	local lover = D.GetLover()
	if not lover then
		lover = LOVER_DATA
	end
	local bDiff = false
	for k, _ in pairs(LOVER_DATA) do
		if D.lover[k] ~= lover[k] then
			D.lover[k] = lover[k]
			bDiff = true
		end
	end
	if bDiff then
		FireUIEvent('MY_LOVE_UPDATE')
	end
end

function D.Init()
	local K = string.char(75, 69)
	local k = string.char(80, 87)
	if X.IsString(D[k]) then
		D[k] = X[K](D[k] .. string.char(77, 89))
	end
	D.bReady = true
end

function D.FormatTimeCounter(nSec)
	if nSec <= 60 then
		return nSec .. _L['sec']
	elseif nSec < 3600 then -- X分钟X秒
		return _L('%d min %d sec', nSec / 60, nSec % 60)
	elseif nSec < 86400 then -- X小时X分钟
		return _L('%d hour %d min', nSec / 3600, (nSec % 3600) / 60)
	elseif nSec < 31536000 then -- X天X小时
		return _L('%d day %d hour', nSec / 86400, (nSec % 86400) / 3600)
	else -- X年X天
		return _L('%d year %d day', nSec / 31536000, (nSec % 31536000) / 86400)
	end
end

-- 获取情缘字符串
function D.FormatLoverString(szPatt, lover)
	if X.StringFindW(szPatt, '{$type}') then
		if lover.nLoverType == 1 then
			szPatt = X.StringReplaceW(szPatt, '{$type}', _L['Mutual love'])
		else
			szPatt = X.StringReplaceW(szPatt, '{$type}', _L['Blind love'])
		end
	end
	if X.StringFindW(szPatt, '{$time}') then
		szPatt = X.StringReplaceW(szPatt, '{$time}', D.FormatTimeCounter(GetCurrentTime() - lover.nLoverTime))
	end
	if X.StringFindW(szPatt, '{$name}') then
		szPatt = X.StringReplaceW(szPatt, '{$name}', lover.szName)
	end
	if X.StringFindW(szPatt, '{$map}') then
		szPatt = X.StringReplaceW(szPatt, '{$map}', Table_GetMapName(lover.dwMapID))
	end
	return szPatt
end

-- 保存情缘
function D.SaveLover(nTime, dwID, nType, nSendItem, nReceiveItem)
	-- 设为无情缘时除dwID外其他改为1由于区别未设置
	if dwID == 0 then
		nTime, nType, nSendItem, nReceiveItem = 1, 1, 1, 1
	end
	X.SetRemoteStorage('MY_Love', dwID, nTime, nType, nSendItem, nReceiveItem)
	D.UpdateProtectData()
	D.UpdateLocalLover()
end

-- 设置情缘
function D.SetLover(dwID, nType)
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	local aInfo = X.GetFriend(dwID)
	if not aInfo or not aInfo.isonline then
		if nType == -1 then
			return X.Alert(_L['Lover must online'])
		end
		return X.Alert(_L['Lover must be a online friend'])
	end
	if nType == -1 then
		-- 重复放烟花刷新称号
		if dwID == D.lover.dwID then
			D.CreateFireworkSelect(function(p)
				if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
					return X.Systopmsg(_L['Light firework is a sensitive action, please unlock to continue.'])
				end
				D.UseDoubleLoveItem(aInfo, p.aUIID, function(bSuccess)
					if bSuccess then
						D.SaveLover(D.lover.nLoverTime, D.lover.dwID, D.lover.nLoverType, p.nItem, D.lover.nReceiveItem)
						X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_FIREWORK', p.nItem})
						X.UI.CloseFrame('MY_Love_SetLover')
					else
						X.Systopmsg(_L['Failed to light firework.'])
					end
				end)
			end)
		end
	elseif nType == 0 then
		-- 设置成为情缘（在线好友）
		-- 单向情缘（简单）
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			return X.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
		end
		X.Confirm(_L('Do you want to blind love with [%s]?', aInfo.name), function()
			local aInfo = X.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return X.Alert(_L['Lover must be a online friend'])
			end
			if aInfo.attraction < MY_Love.nLoveAttraction then
				return X.Alert(_L['Inadequate conditions, requiring Lv2 friend'])
			end
			D.SaveLover(GetCurrentTime(), dwID, nType, 0, 0)
			X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE0'})
		end)
	else
		-- 设置成为情缘（在线好友）
		-- 双向情缘（在线，组队一起，并且在4尺内，发起方带有一个指定烟花）
		D.CreateFireworkSelect(function(p)
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
			end
			local aInfo = X.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return X.Alert(_L['Lover must be a online friend'])
			end
			X.Confirm(_L('Do you want to mutual love with [%s]?', aInfo.name), function()
				if not D.GetDoubleLoveItem(aInfo, p.aUIID) then
					return X.Alert(_L('Inadequate conditions, requiring Lv6 friend/party/4-feet distance/%s', p.szName))
				end
				D.nPendingItem = p.nItem
				X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_ASK'})
				X.Systopmsg(_L('Love request has been sent to [%s], wait please', aInfo.name))
			end)
		end)
	end
end

-- 删除情缘
function D.RemoveLover()
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Systopmsg(_L['Remove lover is a sensitive action, please unlock to continue.'])
	end
	local lover = X.Clone(D.lover)
	if lover.dwID ~= 0 then
		local nTime = GetCurrentTime() - lover.nLoverTime
		if nTime < 3600 then
			return X.Alert(_L('Love can not run a red-light, wait for %s left.', D.FormatTimeCounter(3600 - nTime)))
		end
		-- 取消情缘
		if lover.nLoverType == 0 then -- 单向
			X.Confirm(_L('Are you sure to cut blind love with [%s]?', lover.szName), function()
				-- 单向只通知在线的
				local aInfo = X.GetFriend(lover.dwID)
				if aInfo and aInfo.isonline then
					X.SendBgMsg(lover.szName, 'MY_LOVE', {'REMOVE0'})
				end
				D.SaveLover(0, 0, 0, 0, 0)
				X.Sysmsg(_L['Congratulations, cut blind love finish.'])
			end)
		elseif lover.nLoverType == 1 then -- 双向
			X.Confirm(_L('Are you sure to cut mutual love with [%s]?', lover.szName), function()
				X.DelayCall(50, function()
					X.Confirm(_L['Past five hundred times looking back only in exchange for a chance encounter this life, you really decided?'], function()
						X.DelayCall(50, function()
							X.Confirm(_L['You do not really want to cut off love it, really sure?'], function()
								-- 双向则密聊提醒
								X.SendChat(lover.szName, _L['Sorry, I decided to just a swordman, bye my plugin lover'])
								D.SaveLover(0, 0, 0, 0, 0)
								-- X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('A blade and cut, no longer meet with [%s].', lover.szName))
								X.Sysmsg(_L['Congratulations, do not repeat the same mistakes ah.'])
							end)
						end)
					end)
				end)
			end)
		end
	end
end

-- 修复双向情缘
function D.FixLover()
	if D.lover.nLoverType ~= 1 then
		return X.Alert(_L['Repair feature only supports mutual love!'])
	end
	if not X.IsParty(D.lover.dwID) then
		return X.Alert(_L['Both sides must in a team to be repaired!'])
	end
	X.SendBgMsg(D.lover.szName, 'MY_LOVE', {'FIX1', {
		D.lover.nLoverTime,
		D.lover.nSendItem,
		D.lover.nReceiveItem,
	}})
	X.Systopmsg(_L['Repair request has been sent, wait please.'])
end

-- 获取查看目标
function D.GetPlayerInfo(dwID)
	local tar = X.GetPlayer(dwID)
	if not tar then
		local aCard = GetFellowshipCardClient().GetFellowshipCardInfo(dwID)
		if aCard and aCard.bExist then
			tar = { dwID = dwID, szName = aCard.szName, nGender = 1 }
			if aCard.nRoleType == 2 or aCard.nRoleType == 4 or aCard.nRoleType == 6 then
				tar.nGender = 2
			end
		end
	end
	return tar
end

-- 后台请求别人的情缘数据
function D.RequestOtherLover(dwID, nX, nY, fnAutoClose)
	local tar = D.GetPlayerInfo(dwID)
	if not tar then
		return
	end
	if nX == true or X.IsParty(dwID) then
		if not D.tOtherLover[dwID] then
			D.tOtherLover[dwID] = {}
		end
		FireUIEvent('MY_LOVE_OTHER_UPDATE', dwID)
		if tar.bFightState and not X.IsParty(tar.dwID) then
			FireUIEvent('MY_LOVE_PV_ACTIVE_CHANGE', tar.dwID, false)
			return X.Systopmsg(_L('[%s] is in fighting, no time for you.', tar.szName))
		end
		local me = X.GetClientPlayer()
		X.SendBgMsg(tar.szName, 'MY_LOVE', {'VIEW', X.PACKET_INFO.AUTHOR_ROLES[me.dwID] == me.szName and 'Author' or 'Player'})
	else
		local tMsg = {
			x = nX, y = nY,
			szName = 'MY_Love_Confirm',
			szMessage = _L('[%s] is not in your party, do you want to send a request for accessing data?', tar.szName),
			szAlignment = 'CENTER',
			fnAutoClose = fnAutoClose,
			{
				szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					D.RequestOtherLover(dwID, true)
				end,
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		}
		MessageBox(tMsg)
	end
end

function D.GetOtherLover(dwID)
	return D.tOtherLover[dwID]
end

function D.BackupLover(...)
	local szLoverName, szLoverUUID = ...
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Systopmsg(_L['Backup lover is a sensitive action, please unlock to continue.'])
	end
	local lover = X.Clone(D.lover)
	if select('#', ...) == 2 then
		if szLoverName == lover.szName and szLoverUUID then
			local szPath = X.FormatPath(
				{
					'export/lover_backup/'
						.. X.GetUserRoleName() .. '_' .. X.GetPlayerGUID() .. '-'
						.. szLoverName .. '_' .. szLoverUUID .. '-'
						.. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
						.. '.lover.jx3dat',
					X.PATH_TYPE.ROLE
				})
			X.SaveLUAData(
				szPath,
				{
					szName = X.GetUserRoleName(),
					szUUID = X.GetPlayerGUID(),
					szLoverName = szLoverName,
					szLoverUUID = szLoverUUID,
					nLoverType = lover.nLoverType,
					nLoverTime = lover.nLoverTime,
					nSendItem = lover.nSendItem,
					nReceiveItem = lover.nReceiveItem,
				},
				{ passphrase = D.PW }
			)
			local szFullPath = X.GetAbsolutePath(szPath)
			X.Alert(_L('Backup lover successed, file located at: %s.', szFullPath))
			X.Sysmsg(_L('Backup lover successed, file located at: %s.', szFullPath))
		end
	else
		if lover.nLoverType == 1 then -- 双向
			local info = GetClientTeam().GetMemberInfo(lover.dwID)
			if not info or not info.bIsOnLine then
				X.Systopmsg(_L['Lover must in your team and online to do backup.'])
			else
				X.SendBgMsg(lover.szName, 'MY_LOVE', {'BACKUP'})
				X.Systopmsg(_L['Backup request has been sent, wait please.'])
			end
		else
			X.Systopmsg(_L['Backup feature only supports mutual love!'])
		end
	end
end

function D.RestoreLover(szFilePath)
	local data = X.LoadLUAData(szFilePath, { passphrase = D.PW })
	local errs = X.Schema.CheckSchema(data, BACKUP_DATA_SCHEMA)
	if errs then
		return X.Alert(_L['Error: file is not a valid lover backup!'])
	end
	if data.szUUID == X.GetPlayerGUID() then
		GetUserInput(_L['Please input your lover\'s current name:'], function(szLoverName)
			szLoverName = X.StringReplaceW(X.StringReplaceW(X.TrimString(szLoverName), '[', ''), ']', '')
			X.Confirm(
				_L('Send restore lover request to [%s]?', szLoverName),
				function()
					X.SendBgMsg(szLoverName, 'MY_LOVE', {'RESTORE', data})
				end
			)
		end, nil, nil, nil, data.szLoverName)
	else
		X.Alert(_L['This file is not your lover backup, please check!'])
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
-- 好友数据更新，随时检查情缘变化（删除好友改备注等）
do
local function OnFellowshipUpdate()
	if MY_Love.IsShielded() then
		return
	end
	-- 上线提示
	local lover = D.GetLover()
	if lover and lover.bOnline and lover.dwMapID ~= 0
	and (D.lover.dwID ~= lover.dwID or D.lover.bOnline ~= lover.bOnline) then
		D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] is happy in [{$map}].'), lover))
	end
	-- 载入情缘
	D.UpdateLocalLover()
end
X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE', 'MY_Love', OnFellowshipUpdate)
X.RegisterEvent('FELLOWSHIP_CARD_CHANGE', 'MY_Love', OnFellowshipUpdate)
X.RegisterEvent('UPDATE_FELLOWSHIP_CARD', 'MY_Love', OnFellowshipUpdate)
end

-- 回复情缘信息
function D.ReplyLove(bCancel)
	local szName = D.lover.szName
	if D.lover.dwID == 0 then
		szName = '<' .. O.szNone .. '>'
	elseif bCancel then
		szName = _L['<Not tell you>']
	end
	for k, v in pairs(D.tViewer) do
		X.SendBgMsg(v, 'MY_LOVE', {'REPLY', {
			D.lover.dwID,
			szName,
			D.lover.dwAvatar or 0,
			O.szSign,
			D.lover.dwForceID or 0,
			D.lover.nRoleType or 0,
			D.lover.nLoverType,
			D.lover.nLoverTime,
			D.lover.szLoverTitle,
		}})
	end
	D.tViewer = {}
end

-- 后台同步
do
local function OnBgTalk(_, aData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if MY_Love.IsShielded() then
		return
	end
	if not bSelf then
		if not X.CanUseOnlineRemoteStorage() then
			X.SendBgMsg(szTalkerName, 'MY_LOVE', {'DATA_NOT_SYNC'})
			return
		end
		local szKey, data = aData[1], aData[2]
		if szKey == 'VIEW' then
			if X.IsParty(dwTalkerID) or data == 'Author' or O.bAutoReplyLover then
				D.tViewer[dwTalkerID] = szTalkerName
				D.ReplyLove()
			elseif not X.GetClientPlayer().bFightState and not O.bQuiet then
				D.tViewer[dwTalkerID] = szTalkerName
				X.Confirm(
					_L('[%s] want to see your lover info, OK?', szTalkerName),
					function() D.ReplyLove() end,
					function() D.ReplyLove(true) end
				)
			end
		elseif szKey == 'LOVE0' or szKey == 'REMOVE0' then
			local i = X.Random(1, math.floor(table.getn(D.aAutoSay)/2)) * 2
			if szKey == 'LOVE0' then
				i = i - 1
			end
			OutputMessage('MSG_WHISPER', _L['[Mystery] quietly said:'] .. D.aAutoSay[i] .. '\n')
			PlaySound(SOUND.UI_SOUND,g_sound.Whisper)
		elseif szKey == 'LOVE_ASK' then
			if D.lover.dwID == dwTalkerID and D.lover.nLoverType == 1 then
				-- 已是情缘发起修复
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'FIX2', {
					D.lover.nLoverTime,
					D.lover.nSendItem,
					D.lover.nReceiveItem,
				}})
			elseif D.lover.dwID ~= 0 and (D.lover.dwID ~= dwTalkerID or D.lover.nLoverType == 1) then
				-- 已有情缘直接拒绝
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_EXISTS'})
			else
				-- 询问意见
				X.Confirm(_L('[%s] want to mutual love with you, OK?', szTalkerName), function()
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_YES'})
				end, function()
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_NO'})
				end)
			end
		elseif szKey == 'FIX1' or szKey == 'FIX2' then
			if D.lover.dwID == 0 or (D.lover.dwID == dwTalkerID and D.lover.nLoverType ~= 1) then
				local aInfo = X.GetFriend(dwTalkerID)
				if aInfo then
					local szText = szKey == 'FIX1'
						and _L('[%s] want to repair love relation with you, OK?', szTalkerName)
						or _L('[%s] is already your lover, fix it now?', szTalkerName)
					X.Confirm(szText, function()
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
							X.Systopmsg(_L['Fix lover is a sensitive action, please unlock to continue.'])
							return false
						end
						X.UI.CloseFrame('MY_Love_SetLover')
						D.SaveLover(tonumber(data[1]), dwTalkerID, 1, data[3], data[2])
						X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
						X.Systopmsg(_L('Congratulations, love relation with [%s] has been fixed!', szTalkerName))
					end)
				end
			elseif szKey == 'FIX1' then
				if D.lover.dwID == dwTalkerID then
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_ALREADY'})
				else
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_EXISTS'})
				end
			end
		elseif szKey == 'LOVE_ANS_EXISTS' then
			local szMsg = _L['Unfortunately the other has lover, but you can still blind love him!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_ALREADY' then
			local szMsg = _L['The other is already your lover!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_NO' then
			local szMsg = _L['The other refused you without reason, but you can still blind love him!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_YES' then
			local nItem = D.nPendingItem
			local aUIID = nItem and D.tLoverItem[nItem] and D.tLoverItem[nItem].aUIID
			if X.IsEmpty(aUIID) then
				return
			end
			local aInfo = X.GetFriend(dwTalkerID)
			D.UseDoubleLoveItem(aInfo, aUIID, function(bSuccess)
				if bSuccess then
					D.SaveLover(GetCurrentTime(), dwTalkerID, 1, nItem, 0)
					X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
					X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_ANS_CONF', nItem})
					X.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
					X.UI.CloseFrame('MY_Love_SetLover')
				else
					X.Systopmsg(_L['Failed to attach love, light firework failed.'])
				end
			end)
		elseif szKey == 'LOVE_ANS_CONF' then
			local aInfo = X.GetFriend(dwTalkerID)
			if aInfo then
				D.SaveLover(GetCurrentTime(), dwTalkerID, 1, 0, data)
				X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
				X.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
			end
		elseif szKey == 'LOVE_FIREWORK' then
			local aInfo = X.GetFriend(dwTalkerID)
			if aInfo and D.lover.dwID == dwTalkerID then
				D.SaveLover(D.lover.nLoverTime, dwTalkerID, D.lover.nLoverType, D.lover.nSendItem, data)
			end
		elseif szKey == 'REPLY' then
			D.tOtherLover[dwTalkerID] = {
				dwID = data[1] or 0,
				szName = data[2] or '',
				dwAvatar = tonumber(data[3]) or 0,
				szSign = data[4] or '',
				dwForceID = tonumber(data[5]),
				nRoleType = tonumber(data[6]) or 1,
				nLoverType = tonumber(data[7]) or 0,
				nLoverTime = tonumber(data[8]) or 0,
				szLoverTitle = data[9] or '',
			}
			FireUIEvent('MY_LOVE_OTHER_UPDATE', dwTalkerID)
		elseif szKey == 'BACKUP' then
			if D.lover.dwID == dwTalkerID then
				X.Confirm(_L('[%s] want to backup lover relation with you, do you agree?', szTalkerName), function()
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						X.Systopmsg(_L['Backup lover is a sensitive action, please unlock to continue.'])
						return false
					end
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'BACKUP_ANS', X.GetPlayerGUID()})
				end)
			else
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'BACKUP_ANS_NOT_LOVER'})
			end
		elseif szKey == 'BACKUP_ANS' then
			D.BackupLover(szTalkerName, data)
		elseif szKey == 'BACKUP_ANS_NOT_LOVER' then
			X.Alert(_L['Peer is not your lover, please check, or do fix lover first.'])
		elseif szKey == 'RESTORE' then
			if data.szLoverUUID == X.GetPlayerGUID() then
				X.Confirm(_L('[%s] want to restore lover relation with you, do you agree?', szTalkerName), function()
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						X.Systopmsg(_L['Restore lover is a sensitive action, please unlock to continue.'])
						return false
					end
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'RESTORE_AGREE', data})
				end)
			else
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'RESTORE_NOT_ME', data})
			end
		elseif szKey == 'RESTORE_AGREE' then
			if X.GetPlayerGUID() == data.szUUID and not X.Schema.CheckSchema(data, BACKUP_DATA_SCHEMA) then
				D.SaveLover(data.nLoverTime, dwTalkerID, data.nLoverType, data.nSendItem, data.nReceiveItem)
				X.Alert(_L['Restore lover succeed!'])
			end
		elseif szKey == 'RESTORE_NOT_ME' then
			X.Alert(_L['Peer is not your lover in this backup, please check.'])
		elseif szKey == 'DATA_NOT_SYNC' then
			X.Alert(_L('[%s] disabled ui config sync, unable to read data.', szTalkerName))
		end
	end
end
X.RegisterBgMsg('MY_LOVE', OnBgTalk)
end

-- 情缘名字链接通知
function D.OutputLoverMsg(szMsg)
	X.SendChat(PLAYER_TALK_CHANNEL.LOCAL_SYS, szMsg)
end

-- 上线，下线通知：bOnLine, szName, bFoe
do
local function OnPlayerFellowshipLogin()
	if MY_Love.IsShielded() then
		return
	end
	if not arg2 and arg1 == D.lover.szName and D.lover.szName ~= '' then
		if arg0 then
			X.UI.CreateFloatText(_L('Love tip: %s is online now', D.lover.szName), 1500, {
				nFont = 19,
				fScale = 2.5,
				nR = 255,
				nG = 0,
				nB = 255,
				nOffsetY = 100,
				tKeyFrame = {
					[0] = {
						nOffsetY = 200,
						nAlpha = 0,
						fScale = 0.2,
					},
					[0.08] = {
						nOffsetY = 0,
						nAlpha = 255,
						fScale = 1,
					},
					[0.7] = {},
					[1] = {
						nAlpha = 0,
					},
				},
			})
			PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] online, hurry doing needy doing.'), D.lover))
		else
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] offline, hurry doing like doing.'), D.lover))
		end
		if not Station.Lookup('Normal/SocialPanel') then
			X.UI.OpenFrame('SocialPanel')
			X.UI.CloseFrame('SocialPanel')
		end
	end
end
X.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN', 'MY_Love', OnPlayerFellowshipLogin)
end

-- player enter
do
local function OnPlayerEnterScene()
	if D.bReady and O.bAutoFocus and arg0 == D.lover.dwID
	and MY_Focus and MY_Focus.SetFocusID and not X.IsInArenaMap() then
		MY_Focus.SetFocusID(TARGET.PLAYER, arg0)
	end
end
X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Love', OnPlayerEnterScene)
end

-- on init
do
local function OnInit()
	D.Init()
	D.UpdateLocalLover()
end
X.RegisterInit('MY_Love', OnInit)
end

-- protect data
do
function D.UpdateProtectData()
	D.aStorageData = {X.GetRemoteStorage('MY_Love')}
end
local function onSyncUserPreferencesEnd()
	if D.aStorageData then
		X.SetRemoteStorage('MY_Love', unpack(D.aStorageData))
	else
		D.UpdateProtectData()
	end
end
X.RegisterEvent('SYNC_USER_PREFERENCES_END', 'MY_Love', onSyncUserPreferencesEnd)
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_Love',
	exports = {
		{
			fields = {
				'nLoveAttraction',
				'nDoubleLoveAttraction',
				'IsShielded',
				'GetLover',
				'SetLover',
				'FixLover',
				'BackupLover',
				'RestoreLover',
				'RemoveLover',
				'FormatLoverString',
				'GetPlayerInfo',
				'RequestOtherLover',
				'GetOtherLover',
			},
			root = D,
		},
		{
			fields = {
				'bQuiet',
				'szNone',
				'szJabber',
				'szSign',
				'bAutoFocus',
				'bHookPlayerView',
				'bAutoReplyLover',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bQuiet',
				'szNone',
				'szJabber',
				'szSign',
				'bAutoFocus',
				'bHookPlayerView',
				'bAutoReplyLover',
			},
			triggers = {
				bAutoFocus = function(_, bAutoFocus)
					if bAutoFocus and D.lover.dwID ~= 0 and MY_Focus and MY_Focus.SetFocusID then
						MY_Focus.SetFocusID(TARGET.PLAYER, D.lover.dwID)
					elseif not bAutoFocus and D.lover.dwID ~= 0 and MY_Focus and MY_Focus.RemoveFocusID then
						MY_Focus.RemoveFocusID(TARGET.PLAYER, D.lover.dwID)
					end
				end,
				bHookPlayerView = function(_, bHookPlayerView)
					FireUIEvent('MY_LOVE_PV_HOOK', bHookPlayerView)
				end,
			},
			root = O,
		},
	},
}
MY_Love = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
