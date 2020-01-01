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
	dwAvatar = 0, -- 情缘头像
	dwForceID = 0, -- 门派
	nRoleType = 0, -- 情缘体型（0：无情缘）
	nLoverType = 0, -- 情缘类型（单向：0，双向：1）
	nLoverTime = 0, -- 情缘开始时间（单位：秒）
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
	-- 本地变量
	aAutoSay = { -- 神秘表白语（单数：表白，双数：取消单恋通知）
		_L['Some people fancy you'],
		_L['Other side terminate love you'],
		_L['Some people fall in love with you'],
		_L['Other side gave up love you'],
	},
	lover = Clone(LOVER_DATA),
	tOtherLover = {}, -- 查看的情缘数据
	tViewer = {}, -- 等候查看您的玩家列表
}
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
	if GetCurrentTime() < 1579795200 and LIB.IsShieldedVersion() and not IsLocalFileExist('interface/MY#DATA/tester.jx3dat') then -- 除夕
		return true
	end
	return false
end

-- 获取背包指定名称物品
function D.GetBagItemPos(szName)
	local me = GetClientPlayer()
	for dwBox = 1, LIB.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it and GetItemNameByItem(it) == szName then
				return dwBox, dwX
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
function D.GetDoubleLoveItem(aInfo)
	if aInfo then
		local tar = GetPlayer(aInfo.id)
		if aInfo.attraction >= 800 and tar and LIB.IsParty(tar.dwID) and LIB.GetDistance(tar) <= 4 then
			return D.GetBagItemPos(LIB.GetItemNameByUIID(67291))
		end
	end
end

-- 保存好友数据
function D.SaveFellowRemark(id, remark)
	if not remark or remark == '' then
		remark = ' '
	end
	GetClientPlayer().SetFellowshipRemark(id, remark)
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
function D.DecodeString(szData)
	if string.len(szData) > 2 then
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
	local dwLoverID, nLoverTime, nLoverType = LIB.GetStorage('MY_Love')
	local aGroup = me.GetFellowshipGroupInfo() or {}
	insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for i = #aFriend, 1, -1 do
			local info = aFriend[i]
			local bMatch = sub(info.remark, 1, len(szKey)) == szKey
			-- fetch data
			-- 兼容海鳗：情缘信息从好友备注中提取数据
			if bMatch then
				local szData = sub(info.remark, len(szKey) + 1)
				szData = D.DecodeString(szData)
				local data = LIB.SplitString(szData, '#')
				dwLoverID = info.id
				nLoverType = tonumber(data[1]) or 0
				nLoverTime = tonumber(data[2]) or GetCurrentTime()
				LIB.SetStorage('MY_Love', dwLoverID, nLoverTime, nLoverType)
				D.SaveFellowRemark(info.id, '')
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
							nLoverType = nLoverType,
							nLoverTime = nLoverTime,
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

-- 获取情缘类型
function D.GetLoverType(nType)
	nType = nType or O.lover.nLoverType
	if nType == 1 then
		return _L['Mutual love']
	else
		return _L['Blind love']
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

-- 获取情缘时长
function D.GetLoverTime(nTime)
	if not nTime then
		nTime = O.lover.nLoverTime
	end
	return D.FormatTimeCounter(GetCurrentTime() - nTime)
end

-- 保存情缘
function D.SaveLover(szName, dwID, nType, nTime)
	if not nTime then
		nTime = GetCurrentTime()
	end
	LIB.SetStorage('MY_Love', dwID, nTime, nType)
	if not IsEmpty(szName) then
		LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szName))
	end
	D.UpdateLocalLover()
end

-- 设置情缘
function D.SetLover(dwID, nType)
	if LIB.IsTradeLocked() or LIB.IsTalkLocked() then
		return LIB.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
	end
	local aInfo = LIB.GetFriend(dwID)
	if not aInfo or not aInfo.isonline then
		return LIB.Alert(_L['Lover must be a online friend'])
	end
	LIB.Confirm(_L('Do you want to love with [%s]?', aInfo.name), function()
		-- 设置成为情缘（在线好友）
		if nType == 0 then
			-- 单向情缘（简单）
			D.SaveLover(aInfo.name, dwID, nType)
			LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE0')
		else
			-- 双向情缘（在线，组队一起，并且在4尺内，发起方带有一个真橙之心）
			if not D.GetDoubleLoveItem(aInfo) then
				return LIB.Alert(_L('Inadequate conditions, requiring Lv6 friend/party/4-feet distance/%s', LIB.GetItemNameByUIID(67291)))
			end
			LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE_ASK')
			LIB.Systopmsg(_L('Love request has been sent to [%s], wait please', aInfo.name))
		end
	end)
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
							D.SaveLover('', 0, 0, 0)
							LIB.Talk(PLAYER_TALK_CHANNEL.TONG, _L('A blade and cut, no longer meet with [%s].', lover.szName))
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
	LIB.SendBgMsg(O.lover.szName, 'MY_LOVE', 'FIX1', O.lover.nLoverTime)
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
		D.OutputLoverMsg(_L('Warm tip: Your %s Lover [%s] is happy in [%s].', D.GetLoverType(), lover.szName, Table_GetMapName(lover.dwMapID)))
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
			if O.lover.dwID ~= 0 and (O.lover.dwID ~= dwTalkerID or O.lover.nLoverType == 1) then
				return LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS', 'EXISTS')
			end
			-- 询问意见
			LIB.Confirm(_L('[%s] want to mutual love with you, OK?', szTalkerName), function()
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS', 'YES')
			end, function()
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS', 'NO')
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
						D.SaveLover(szTalkerName, dwTalkerID, 1, tonumber(data))
						LIB.Systopmsg(_L('Congratulations, love relation with [%s] has been fixed!', szTalkerName))
					end)
				end
			elseif O.lover.dwID == dwTalkerID then
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS', 'ALREADY')
			else
				LIB.SendBgMsg(szTalkerName, 'MY_LOVE', 'LOVE_ANS', 'EXISTS')
			end
		elseif szKey == 'LOVE_ANS' then
			if data == 'EXISTS' then
				local szMsg = _L['Unfortunately the other has lover, but you can still blind love him!']
				LIB.Sysmsg(szMsg)
				LIB.Alert(szMsg)
			elseif data == 'ALREADY' then
				local szMsg = _L['The other is already your lover!']
				LIB.Sysmsg(szMsg)
				LIB.Alert(szMsg)
			elseif data == 'NO' then
				local szMsg = _L['The other refused you without reason, but you can still blind love him!']
				LIB.Sysmsg(szMsg)
				LIB.Alert(szMsg)
			elseif data == 'YES' then
				local aInfo = LIB.GetFriend(dwTalkerID)
				local dwBox, dwX = D.GetDoubleLoveItem(aInfo)
				if dwBox then
					local nNum = D.GetBagItemNum(dwBox, dwX)
					SetTarget(TARGET.PLAYER, aInfo.id)
					OnUseItem(dwBox, dwX)
					LIB.DelayCall(500, function()
						if D.GetBagItemNum(dwBox, dwX) ~= nNum then
							D.SaveLover(szTalkerName, dwTalkerID, 1)
							LIB.SendBgMsg(aInfo.name, 'MY_LOVE', 'LOVE_ANS', 'CONF')
							LIB.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
						end
					end)
				end
			elseif data == 'CONF' then
				local aInfo = LIB.GetFriend(dwTalkerID)
				if aInfo then
					D.SaveLover(szTalkerName, dwTalkerID, 1)
					LIB.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
				end
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
			FireUIEvent('MY_COMBATTEXT_MSG', _L('Love Tip: %s onlines now', O.lover.szName), true, { 255, 0, 255 })
			PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
			D.OutputLoverMsg(_L('Warm tip: Your %s Lover %s online, hurry doing needy doing.', D.GetLoverType(), O.lover.szName))
		else
			D.OutputLoverMsg(_L('Warm tip: Your %s Lover %s offline, hurry doing like doing.', D.GetLoverType(), O.lover.szName))
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
				GetLoverType = D.GetLoverType,
				GetLoverTime = D.GetLoverTime,
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
