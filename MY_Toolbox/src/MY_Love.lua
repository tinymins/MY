--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 剑侠情缘
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
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

local D = {}
local O = {
	-- 导出设置
	bQuiet = false, -- 免打扰（拒绝其它人的查看请求）
	szNone = _L['Singleton'], -- 没情缘时显示的字
	szJabber = _L['Hi, I seem to meet you somewhere ago'], -- 搭讪用语
	szSign = '', -- 情缘宣言（个性签名）
	bAutoFocus = true, -- 自动焦点
	bHookPlayerView = false, -- 在查看装备界面上显示情缘
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
	lover = Clone(LOVER_DATA),
	tOtherLover = {}, -- 查看的情缘数据
	tViewer = {}, -- 等候查看您的玩家列表
	aLoverItem = { -- 可用于结缘的烟花信息
		{ nItem = 1, szName = LIB.GetItemNameByUIID(67291), szTitle = _L['FIREWORK_TITLE_67291'], aUIID = {67291} }, -- 真橙之心
		{ nItem = 2, szName = LIB.GetItemNameByUIID(151303), szTitle = _L['FIREWORK_TITLE_151303'], aUIID = {151303} }, -- 无间长情 真心人
		{ nItem = 3, szName = LIB.GetItemNameByUIID(151743), szTitle = _L['FIREWORK_TITLE_151743'], aUIID = {151743} }, -- 千衷不渝
		{ nItem = 4, szName = LIB.GetItemNameByUIID(152844), szTitle = _L['FIREWORK_TITLE_152844'], aUIID = {152844} }, -- 心不释手
		{ nItem = 5, szName = LIB.GetItemNameByUIID(154319), szTitle = _L['FIREWORK_TITLE_154319'], aUIID = {154319} }, -- 鸿福齐天 惜福人
		{ nItem = 6, szName = LIB.GetItemNameByUIID(154320), szTitle = _L['FIREWORK_TITLE_154320'], aUIID = {154320} }, -- 情人心 一心人
		{ nItem = 7, szName = LIB.GetItemNameByUIID(153641), szTitle = _L['FIREWORK_TITLE_153641'], aUIID = {153641} }, -- 素月流天
		{ nItem = 8, szName = LIB.GetItemNameByUIID(153642), szTitle = _L['FIREWORK_TITLE_153642'], aUIID = {153642} }, -- 万家灯火
		{ nItem = 9, szName = LIB.GetItemNameByUIID(156413), szTitle = _L['FIREWORK_TITLE_156413'], aUIID = {156413} }, -- 冰荷逢春 有福人
		{ nItem = 10, szName = LIB.GetItemNameByUIID(156446), szTitle = _L['FIREWORK_TITLE_156446'], aUIID = {156446, 154313} }, -- 荷渡鸾桥 同心人
		{ nItem = 11, szName = LIB.GetItemNameByUIID(157096), szTitle = _L['FIREWORK_TITLE_157096'], aUIID = {157096} }, -- 莲心并蒂 恒心人
		{ nItem = 12, szName = LIB.GetItemNameByUIID(157378), szTitle = _L['FIREWORK_TITLE_157378'], aUIID = {157378} }, -- 素心竹月 知心人
		{ nItem = 13, szName = LIB.GetItemNameByUIID(158339), szTitle = _L['FIREWORK_TITLE_158339'], aUIID = {158339} }, -- 流光绮梦 衷情人
		{ nItem = 14, szName = LIB.GetItemNameByUIID(159250), szTitle = _L['FIREWORK_TITLE_159250'], aUIID = {159250} }, -- 莲心问情 倾心人
		{ nItem = 15, szName = LIB.GetItemNameByUIID(160982), szTitle = _L['FIREWORK_TITLE_160982'], aUIID = {160982} }, -- 海誓山盟
		{ nItem = 16, szName = LIB.GetItemNameByUIID(160993), szTitle = _L['FIREWORK_TITLE_160993'], aUIID = {160993} }, -- 鹊桥引仙 相思人
		{ nItem = 17, szName = LIB.GetItemNameByUIID(161367), szTitle = _L['FIREWORK_TITLE_161367'], aUIID = {161367} }, -- 金缕诉情 深情人
		{ nItem = 18, szName = LIB.GetItemNameByUIID(161887), szTitle = _L['FIREWORK_TITLE_161887'], aUIID = {161887} }, -- 蝶梦剪窗 称心人
		{ nItem = 19, szName = LIB.GetItemNameByUIID(162307), szTitle = _L['FIREWORK_TITLE_162307'], aUIID = {162307} }, -- 花语相思 还愿人
		{ nItem = 20, szName = LIB.GetItemNameByUIID(162308), szTitle = _L['FIREWORK_TITLE_162308'], aUIID = {162308} }, -- 在吗
		{ nItem = 21, szName = LIB.GetItemNameByUIID(158577), szTitle = _L['FIREWORK_TITLE_158577'], aUIID = {158577} }, -- 金鸾喻情 玲珑心
		-- { nItem = 63, szName = LIB.GetItemNameByUIID(65625), szTitle = LIB.GetItemNameByUIID(65625), aUIID = {65625} }, -- 测试用 焰火棒
	},
	tLoverItem = {},
	nPendingItem = 0, -- 请求结缘烟花nItem序号缓存
}
for _, p in ipairs(O.aLoverItem) do
	assert(not O.tLoverItem[p.nItem], 'MY_Love item index conflict: ' .. p.nItem)
	O.tLoverItem[p.nItem] = p
end
RegisterCustomData('MY_Love.bQuiet')
RegisterCustomData('MY_Love.szNone')
RegisterCustomData('MY_Love.szJabber')
RegisterCustomData('MY_Love.szSign')
RegisterCustomData('MY_Love.bAutoFocus')
RegisterCustomData('MY_Love.bHookPlayerView')

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

-- 功能内测
function D.IsShielded()
	return false
end

-- 获取背包指定ID物品列表
function D.GetBagItemPos(aUIID)
	local me = GetClientPlayer()
	for dwBox = 1, LIB.GetBagPackageCount() do
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
	local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
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
		local tar = GetPlayer(aInfo.id)
		if aInfo.attraction >= O.nDoubleLoveAttraction and tar and LIB.IsParty(tar.dwID) and LIB.GetDistance(tar) <= 4 then
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
		LIB.BreatheCall(function()
			local me = GetClientPlayer()
			if not me then
				return 0
			end
			if me.GetSkillOTActionState() == 6 then -- otActionItemSkill
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
	local ui = UI.CreateFrame('MY_Love_SetLover', {
		w = nItemWidth * nCol + nMargin * 2 + nItemPadding * (nCol - 1),
		h = 50 + ceil(#O.aLoverItem / nCol) * nLineHeight + 30,
		text = _L['Select a firework'],
	})
	local nX, nY = nMargin, 50
	for i, p in ipairs(O.aLoverItem) do
		ui:Append('WndButton', {
			x = nX, y = nY + (nLineHeight - nItemHeight) / 2, w = nItemWidth, h = nItemHeight,
			text = p.szName,
			enable = not not D.GetBagItemPos(p.aUIID),
			onclick = function() callback(p) end,
			tip = p.szTitle,
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
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
	if not IsEmpty(szData) and IsString(szData) and len(szData) > 2 then
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
	local szKey, me = '#HM#LOVER#', GetClientPlayer()
	if not me then
		return
	end
	local dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem = LIB.GetStorage('MY_Love')
	local aGroup = me.GetFellowshipGroupInfo() or {}
	insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for i = #aFriend, 1, -1 do
			local info = aFriend[i]
			if nLoverTime == 0 then -- 时间为非0表示不是第一次了 拒绝加载海鳗数据
				local bMatch = sub(info.remark, 1, len(szKey)) == szKey
				-- fetch data
				-- 兼容海鳗：情缘信息从好友备注中提取数据
				if bMatch then
					local szData = D.DecodeHMString(sub(info.remark, len(szKey) + 1))
					if not IsEmpty(szData) then
						local data = LIB.SplitString(szData, '#')
						local nType = data[1] and tonumber(data[1])
						local nTime = data[2] and tonumber(data[2])
						if nType and nTime and (nType == 0 or nType == 1) and (nTime > 0 and nTime < GetCurrentTime()) then
							dwLoverID = info.id
							nLoverType = nType
							nLoverTime = nTime
							nSendItem = 0
							nReceiveItem = 0
							LIB.SetStorage('MY_Love', dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem)
						end
					end
					me.SetFellowshipRemark(info.id, '')
				end
			end
			-- 遍历到情缘，获取基础信息并返回
			if info.id == dwLoverID then
				local fellowClient = GetFellowshipCardClient()
				if fellowClient then
					local card = fellowClient.GetFellowshipCardInfo(info.id)
					if not card or card.dwMapID == 0 then
						fellowClient.ApplyFellowshipCard(255, {info.id})
					else
						return {
							dwID = dwLoverID,
							szName = info.name,
							szTitle = O.tLoverItem[O.lover.nSendItem] and O.tLoverItem[O.lover.nSendItem].szTitle or '',
							nSendItem = nSendItem,
							nReceiveItem = nReceiveItem,
							nLoverType = nLoverType,
							nLoverTime = nLoverTime,
							szLoverTitle = O.tLoverItem[O.lover.nReceiveItem] and O.tLoverItem[O.lover.nReceiveItem].szTitle or '',
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
		if O.lover[k] ~= lover[k] then
			O.lover[k] = lover[k]
			bDiff = true
		end
	end
	if bDiff then
		FireUIEvent('MY_LOVE_UPDATE')
	end
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
	if wfind(szPatt, '{$type}') then
		if lover.nLoverType == 1 then
			szPatt = wgsub(szPatt, '{$type}', _L['Mutual love'])
		else
			szPatt = wgsub(szPatt, '{$type}', _L['Blind love'])
		end
	end
	if wfind(szPatt, '{$time}') then
		szPatt = wgsub(szPatt, '{$time}', D.FormatTimeCounter(GetCurrentTime() - lover.nLoverTime))
	end
	if wfind(szPatt, '{$name}') then
		szPatt = wgsub(szPatt, '{$name}', lover.szName)
	end
	if wfind(szPatt, '{$map}') then
		szPatt = wgsub(szPatt, '{$map}', Table_GetMapName(lover.dwMapID))
	end
	return szPatt
end

-- 保存情缘
function D.SaveLover(nTime, dwID, nType, nSendItem, nReceiveItem)
	-- 设为无情缘时除dwID外其他改为1由于区别未设置
	if dwID == 0 then
		nTime, nType, nSendItem, nReceiveItem = 1, 1, 1, 1
	end
	LIB.SetStorage('MY_Love', dwID, nTime, nType, nSendItem, nReceiveItem)
	D.UpdateLocalLover()
end

-- 设置情缘
function D.SetLover(dwID, nType)
	local aInfo = LIB.GetFriend(dwID)
	if not aInfo or not aInfo.isonline then
		return LIB.Alert(_L['Lover must be a online friend'])
	end
	if nType == -1 then
		-- 重复放烟花刷新称号
		if dwID == O.lover.dwID then
			D.CreateFireworkSelect(function(p)
				if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
					return LIB.Systopmsg(_L['Light firework is a sensitive action, please unlock to continue.'])
				end
				D.UseDoubleLoveItem(aInfo, p.aUIID, function(bSuccess)
					if bSuccess then
						D.SaveLover(O.lover.nLoverTime, O.lover.dwID, O.lover.nLoverType, p.nItem, O.lover.nReceiveItem)
						LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE_FIREWORK', p.nItem)
						Wnd.CloseWindow('MY_Love_SetLover')
					else
						LIB.Systopmsg(_L['Failed to light firework.'])
					end
				end)
			end)
		end
	elseif nType == 0 then
		-- 设置成为情缘（在线好友）
		-- 单向情缘（简单）
		if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
			return LIB.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
		end
		LIB.Confirm(_L('Do you want to love with [%s]?', aInfo.name), function()
			local aInfo = LIB.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return LIB.Alert(_L['Lover must be a online friend'])
			end
			if aInfo.attraction < MY_Love.nLoveAttraction then
				return LIB.Alert(_L['Inadequate conditions, requiring Lv2 friend'])
			end
			D.SaveLover(GetCurrentTime(), dwID, nType, 0, 0)
			LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE0')
		end)
	else
		-- 设置成为情缘（在线好友）
		-- 双向情缘（在线，组队一起，并且在4尺内，发起方带有一个指定烟花）
		D.CreateFireworkSelect(function(p)
			if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
				return LIB.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
			end
			local aInfo = LIB.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return LIB.Alert(_L['Lover must be a online friend'])
			end
			LIB.Confirm(_L('Do you want to love with [%s]?', aInfo.name), function()
				if not D.GetDoubleLoveItem(aInfo, p.aUIID) then
					return LIB.Alert(_L('Inadequate conditions, requiring Lv6 friend/party/4-feet distance/%s', p.szName))
				end
				O.nPendingItem = p.nItem
				LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE_ASK')
				LIB.Systopmsg(_L('Love request has been sent to [%s], wait please', aInfo.name))
			end)
		end)
	end
end

-- 删除情缘
function D.RemoveLover()
	if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
		return LIB.Systopmsg(_L['Remove lover is a sensitive action, please unlock to continue.'])
	end
	local lover = Clone(O.lover)
	if lover.dwID ~= 0 then
		local nTime = GetCurrentTime() - lover.nLoverTime
		if nTime < 3600 then
			return LIB.Alert(_L('Love can not run a red-light, wait for %s left.', D.FormatTimeCounter(3600 - nTime)))
		end
		LIB.Confirm(_L('Are you sure to cut love with [%s]?', lover.szName), function()
			LIB.DelayCall(50, function()
				LIB.Confirm(_L['Past five hundred times looking back only in exchange for a chance encounter this life, you really decided?'], function()
					LIB.DelayCall(50, function()
						LIB.Confirm(_L['You do not really want to cut off love it, really sure?'], function()
							-- 取消情缘
							if lover.nLoverType == 1 then -- 双向则密聊提醒
								LIB.Talk(lover.szName, _L['Sorry, I decided to just a swordman, bye my plugin lover'])
							elseif lover.nLoverType == 0 then -- 单向只通知在线的
								local aInfo = LIB.GetFriend(lover.dwID)
								if aInfo and aInfo.isonline then
									LIB.SendBgMsg(lover.szName, 'MY_LOVE', 'REMOVE0')
								end
							end
							D.SaveLover(0, 0, 0, 0, 0)
							if lover.nLoverType == 1 then
								LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('A blade and cut, no longer meet with [%s].', lover.szName))
							end
							LIB.Sysmsg(_L['Congratulations, do not repeat the same mistakes ah.'])
						end)
					end)
				end)
			end)
		end)
	end
end

-- 修复双向情缘
function D.FixLover()
	if O.lover.nLoverType ~= 1 then
		return LIB.Alert(_L['Repair feature only supports mutual love!'])
	end
	if not LIB.IsParty(O.lover.dwID) then
		return LIB.Alert(_L['Both sides must in a team to be repaired!'])
	end
	LIB.SendBgMsg(O.lover.szName, 'MY_LOVE', 'FIX1', {
		O.lover.nLoverTime,
		O.lover.nSendItem,
		O.lover.nReceiveItem,
	})
	LIB.Systopmsg(_L['Repair request has been sent, wait please.'])
end

-- 获取查看目标
function D.GetPlayerInfo(dwID)
	local tar = GetPlayer(dwID)
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
	if nX == true or LIB.IsParty(dwID) then
		if not O.tOtherLover[dwID] then
			O.tOtherLover[dwID] = {}
		end
		FireUIEvent('MY_LOVE_OTHER_UPDATE', dwID)
		if tar.bFightState and not LIB.IsParty(tar.dwID) then
			FireUIEvent('MY_LOVE_PV_ACTIVE_CHANGE', tar.dwID, false)
			return LIB.Systopmsg(_L('[%s] is in fighting, no time for you.', tar.szName))
		end
		local me = GetClientPlayer()
		LIB.SendBgMsg(tar.szName, 'MY_LOVE', 'VIEW', PACKET_INFO.AUTHOR_ROLES[me.dwID] == me.szName and 'Author' or 'Player')
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
	return O.tOtherLover[dwID]
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
	and (O.lover.dwID ~= lover.dwID or O.lover.bOnline ~= lover.bOnline) then
		D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] is happy in [{$map}].'), lover))
	end
	-- 载入情缘
	D.UpdateLocalLover()
end
LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE.MY_Love', OnFellowshipUpdate)
LIB.RegisterEvent('FELLOWSHIP_CARD_CHANGE.MY_Love', OnFellowshipUpdate)
LIB.RegisterEvent('UPDATE_FELLOWSHIP_CARD.MY_Love', OnFellowshipUpdate)
end

-- 回复情缘信息
function D.ReplyLove(bCancel)
	local szName = O.lover.szName
	if O.lover.dwID == 0 then
		szName = '<' .. O.szNone .. '>'
	elseif bCancel then
		szName = _L['<Not tell you>']
	end
	for k, v in pairs(O.tViewer) do
		LIB.SendBgMsg(v, 'MY_LOVE', 'REPLY', {
			O.lover.dwID,
			szName,
			O.lover.dwAvatar or 0,
			O.szSign,
			O.lover.dwForceID or 0,
			O.lover.nRoleType or 0,
			O.lover.nLoverType,
			O.lover.nLoverTime,
			O.lover.szLoverTitle,
		})
	end
	O.tViewer = {}
end

-- 后台同步
do
local function OnBgTalk(_, nChannel, dwTalkerID, szTalkerName, bSelf, ...)
	if MY_Love.IsShielded() then
		return
	end
	if not bSelf then
		local szKey, data = ...
		if szKey == 'VIEW' then
			if LIB.IsParty(dwTalkerID) or data == 'Author' then
				O.tViewer[dwTalkerID] = szTalkerName
				D.ReplyLove()
			elseif not GetClientPlayer().bFightState and not O.bQuiet then
				O.tViewer[dwTalkerID] = szTalkerName
				LIB.Confirm(
					_L('[%s] want to see your lover info, OK?', szTalkerName),
					function() D.ReplyLove() end,
					function() D.ReplyLove(true) end
				)
			end
		elseif szKey == 'LOVE0' or szKey == 'REMOVE0' then
			local i = math.random(1, math.floor(table.getn(O.aAutoSay)/2)) * 2
			if szKey == 'LOVE0' then
				i = i - 1
			end
			OutputMessage('MSG_WHISPER', _L['[Mystery] quietly said:'] .. O.aAutoSay[i] .. '\n')
			PlaySound(SOUND.UI_SOUND,g_sound.Whisper)
		elseif szKey == 'LOVE_ASK' then
			-- 已有情缘直接拒绝
			if O.lover.dwID == dwTalkerID and O.lover.nLoverType == 1 then
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_ALREADY')
			elseif O.lover.dwID ~= 0 and (O.lover.dwID ~= dwTalkerID or O.lover.nLoverType == 1) then
				return LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_EXISTS')
			end
			-- 询问意见
			LIB.Confirm(_L('[%s] want to mutual love with you, OK?', szTalkerName), function()
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_YES')
			end, function()
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_NO')
			end)
		elseif szKey == 'FIX1' then
			if O.lover.dwID == 0 or (O.lover.dwID == dwTalkerID and O.lover.nLoverType ~= 1) then
				local aInfo = LIB.GetFriend(dwTalkerID)
				if aInfo then
					LIB.Confirm(_L('[%s] want to repair love relation with you, OK?', szTalkerName), function()
						if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
							LIB.Systopmsg(_L['Fix lover is a sensitive action, please unlock to continue.'])
							return false
						end
						D.SaveLover(tonumber(data[1]), dwTalkerID, 1, data[3], data[2])
						LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
						LIB.Systopmsg(_L('Congratulations, love relation with [%s] has been fixed!', szTalkerName))
					end)
				end
			elseif O.lover.dwID == dwTalkerID then
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_ALREADY')
			else
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS_EXISTS')
			end
		elseif szKey == 'LOVE_ANS_EXISTS' then
			local szMsg = _L['Unfortunately the other has lover, but you can still blind love him!']
			LIB.Sysmsg(szMsg)
			LIB.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_ALREADY' then
			local szMsg = _L['The other is already your lover!']
			LIB.Sysmsg(szMsg)
			LIB.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_NO' then
			local szMsg = _L['The other refused you without reason, but you can still blind love him!']
			LIB.Sysmsg(szMsg)
			LIB.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_YES' then
			local nItem = O.nPendingItem
			local aUIID = nItem and O.tLoverItem[nItem] and O.tLoverItem[nItem].aUIID
			if IsEmpty(aUIID) then
				return
			end
			local aInfo = LIB.GetFriend(dwTalkerID)
			D.UseDoubleLoveItem(aInfo, aUIID, function(bSuccess)
				if bSuccess then
					D.SaveLover(GetCurrentTime(), dwTalkerID, 1, nItem, 0)
					LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
					LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE_ANS_CONF', nItem)
					LIB.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
					Wnd.CloseWindow('MY_Love_SetLover')
				else
					LIB.Systopmsg(_L['Failed to attach love, light firework failed.'])
				end
			end)
		elseif szKey == 'LOVE_ANS_CONF' then
			local aInfo = LIB.GetFriend(dwTalkerID)
			if aInfo then
				D.SaveLover(GetCurrentTime(), dwTalkerID, 1, 0, data)
				LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
				LIB.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
			end
		elseif szKey == 'LOVE_FIREWORK' then
			local aInfo = LIB.GetFriend(dwTalkerID)
			if aInfo and O.lover.dwID == dwTalkerID then
				D.SaveLover(O.lover.nLoverTime, dwTalkerID, O.lover.nLoverType, O.lover.nSendItem, data)
			end
		elseif szKey == 'REPLY' then
			O.tOtherLover[dwTalkerID] = {
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
		end
	end
end
LIB.RegisterBgMsg('MY_LOVE', OnBgTalk)
end

-- 情缘名字链接通知
function D.OutputLoverMsg(szMsg)
	LIB.Talk(PLAYER_TALK_CHANNEL.LOCAL_SYS, szMsg)
end

-- 上线，下线通知：bOnLine, szName, bFoe
do
local function OnPlayerFellowshipLogin()
	if MY_Love.IsShielded() then
		return
	end
	if not arg2 and arg1 == O.lover.szName and O.lover.szName ~= '' then
		if arg0 then
			FireUIEvent('MY_COMBATTEXT_MSG', _L('Love tip: %s onlines now', O.lover.szName), true, { 255, 0, 255 })
			PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] online, hurry doing needy doing.'), O.lover))
		else
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] offline, hurry doing like doing.'), O.lover))
		end
		GetClientPlayer().UpdateFellowshipInfo()
	end
end
LIB.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN.MY_Love', OnPlayerFellowshipLogin)
end

-- player enter
do
local function OnPlayerEnterScene()
	if O.bAutoFocus and arg0 == O.lover.dwID
	and MY_Focus and MY_Focus.SetFocusID and not LIB.IsInArena() then
		MY_Focus.SetFocusID(TARGET.PLAYER, arg0)
	end
end
LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_Love', OnPlayerEnterScene)
end

-- on init
do
local function OnInit()
	D.UpdateLocalLover()
end
LIB.RegisterInit('MY_Love', OnInit)
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	exports = {
		{
			fields = {
				IsShielded = D.IsShielded,
				GetLover = D.GetLover,
				SetLover = D.SetLover,
				FixLover = D.FixLover,
				RemoveLover = D.RemoveLover,
				FormatLoverString = D.FormatLoverString,
				GetPlayerInfo = D.GetPlayerInfo,
				RequestOtherLover = D.RequestOtherLover,
				GetOtherLover = D.GetOtherLover,
			},
		},
		{
			fields = {
				bQuiet = true,
				szNone = true,
				szJabber = true,
				szSign = true,
				bAutoFocus = true,
				bHookPlayerView = true,
				nLoveAttraction = true,
				nDoubleLoveAttraction = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bQuiet = true,
				szNone = true,
				szJabber = true,
				szSign = true,
				bAutoFocus = true,
				bHookPlayerView = true,
			},
			triggers = {
				bAutoFocus = function(_, bAutoFocus)
					if bAutoFocus and O.lover.dwID ~= 0 and MY_Focus and MY_Focus.SetFocusID then
						MY_Focus.SetFocusID(TARGET.PLAYER, O.lover.dwID)
					elseif not bAutoFocus and O.lover.dwID ~= 0 and MY_Focus and MY_Focus.RemoveFocusID then
						MY_Focus.RemoveFocusID(TARGET.PLAYER, O.lover.dwID)
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
MY_Love = LIB.GeneGlobalNS(settings)
end
