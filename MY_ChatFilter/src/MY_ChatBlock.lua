--------------------------------------------
-- @Desc  : 聊天辅助
-- @Author: 茗伊 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2016-12-29 14:24:10
--------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatFilter'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatBlock'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
local TALK_CHANNEL_MSG_TYPE = {
	[PLAYER_TALK_CHANNEL.NEARBY       ] = 'MSG_NORMAL'        ,
	[PLAYER_TALK_CHANNEL.SENCE        ] = 'MSG_MAP'           ,
	[PLAYER_TALK_CHANNEL.WORLD        ] = 'MSG_WORLD'         ,
	[PLAYER_TALK_CHANNEL.TEAM         ] = 'MSG_PARTY'         ,
	[PLAYER_TALK_CHANNEL.RAID         ] = 'MSG_TEAM'          ,
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD ] = 'MSG_BATTLE_FILED'  ,
	[PLAYER_TALK_CHANNEL.TONG         ] = 'MSG_GUILD'         ,
	[PLAYER_TALK_CHANNEL.FORCE        ] = 'MSG_SCHOOL'        ,
	[PLAYER_TALK_CHANNEL.CAMP         ] = 'MSG_CAMP'          ,
	[PLAYER_TALK_CHANNEL.WHISPER      ] = 'MSG_WHISPER'       ,
	[PLAYER_TALK_CHANNEL.FRIENDS      ] = 'MSG_FRIEND'        ,
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = 'MSG_GUILD_ALLIANCE',
	[PLAYER_TALK_CHANNEL.LOCAL_SYS    ] = 'MSG_SYS'           ,
}
local MSG_TYPE_TALK_CHANNEL = LIB.FlipObjectKV(TALK_CHANNEL_MSG_TYPE)

local DEFAULT_KW_CONFIG = {
	szKeyword = '',
	tMsgType = {
		['MSG_NORMAL'        ] = true,
		['MSG_MAP'           ] = true,
		['MSG_WORLD'         ] = true,
		['MSG_SCHOOL'        ] = true,
		['MSG_CAMP'          ] = true,
		['MSG_WHISPER'       ] = true,
	},
	bIgnoreAcquaintance = true,
	bIgnoreCase = true, bIgnoreEnEm = true, bIgnoreSpace = true,
}

local D = {}
local O = {
	bBlockWords = true,
	aBlockWords = {},
}
RegisterCustomData('MY_ChatBlock.bBlockWords')

function D.SaveBlockWords()
	LIB.SaveLUAData(
		{'config/chatblockwords.jx3dat', PATH_TYPE.GLOBAL},
		{ aBlockWords = O.aBlockWords },
		{ passphrase = false })
	LIB.StorageData('MY_CHAT_BLOCKWORD', O.aBlockWords)
end

function D.LoadBlockWords()
	local aBlockWords = {}
	local data = LIB.LoadLUAData(
		{'config/chatblockwords.jx3dat', PATH_TYPE.GLOBAL},
		{ passphrase = false })
	or LIB.LoadLUAData({'config/chatblockwords.jx3dat', PATH_TYPE.GLOBAL})
	if data then
		if IsTable(data.aBlockWords) then
			aBlockWords = data.aBlockWords
		end
		-- 兼容旧版数据
		if data.blockwords then
			for i, bw in ipairs(data.blockwords) do
				if IsTable(bw) and IsTable(bw.channel) then
					if bw.keyword then
						local bwNew = {
							szKeyword = bw.keyword,
							tMsgType = {},
							bIgnoreAcquaintance = bw.ignoreAcquaintance,
							bIgnoreCase = bw.ignoreCase,
							bIgnoreEnEm = bw.ignoreEnEm,
							bIgnoreSpace = bw.ignoreSpace,
						}
						for k, v in pairs(bw.channel) do
							if k == 'SYSTEM' then
								k = 'LOCAL_SYS'
							end
							local k = PLAYER_TALK_CHANNEL[k] and TALK_CHANNEL_MSG_TYPE[PLAYER_TALK_CHANNEL[k]]
							if k then
								bwNew.tMsgType[k] = v
							end
						end
						insert(aBlockWords, bwNew)
					end
				end
			end
		end
	end
	O.aBlockWords = aBlockWords
	D.CheckEnable()
end

function D.IsBlockMsg(szText, szMsgType, dwTalkerID)
	local bAcquaintance = dwTalkerID
		and (LIB.GetFriend(dwTalkerID) or LIB.GetFoe(dwTalkerID) or LIB.GetTongMember(dwTalkerID))
		or false
	for _, bw in ipairs(O.aBlockWords) do
		if bw.tMsgType[szMsgType] and (not bAcquaintance or not bw.bIgnoreAcquaintance)
		and LIB.StringSimpleMatch(szText, bw.szKeyword, not bw.bIgnoreCase, not bw.bIgnoreEnEm, bw.bIgnoreSpace) then
			return true
		end
	end
	return false
end

function D.OnTalkFilter(nChannel, t, dwTalkerID, szName, bEcho, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
	local szType = TALK_CHANNEL_MSG_TYPE[nChannel]
	if not szType then
		return
	end
	local szText = ''
	for _, v in ipairs(t) do
		if v.text then
			szText = szText .. v.text
		end
	end
	if D.IsBlockMsg(szText, szType, dwTalkerID) then
		return true
	end
end

function D.OnMsgFilter(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName)
	if D.IsBlockMsg(bRich and GetPureText(szMsg) or szMsg, szType, dwTalkerID) then
		return true
	end
end

function D.CheckEnable()
	UnRegisterTalkFilter(D.OnTalkFilter)
	UnRegisterMsgFilter(D.OnMsgFilter)
	if not O.bBlockWords then
		return
	end
	local tChannel, tMsgType = {}, {}
	for _, bw in ipairs(O.aBlockWords) do
		for szType, bEnable in pairs(bw.tMsgType) do
			if bEnable then
				if MSG_TYPE_TALK_CHANNEL[szType] then
					tChannel[MSG_TYPE_TALK_CHANNEL[szType]] = true
				end
				tMsgType[szType] = true
			end
		end
	end
	local aChannel, aMsgType = {}, {}
	for k, _ in pairs(tChannel) do
		insert(aChannel, k)
	end
	for k, _ in pairs(tMsgType) do
		insert(aMsgType, k)
	end
	if not IsEmpty(aChannel) then
		RegisterTalkFilter(D.OnTalkFilter, aChannel)
	end
	if not IsEmpty(aMsgType) then
		RegisterMsgFilter(D.OnMsgFilter, aMsgType)
	end
end

LIB.RegisterEvent('MY_PRIVATE_STORAGE_UPDATE', function()
	if arg0 == 'MY_CHAT_BLOCKWORD' then
		O.aBlockWords = arg1
		D.CheckEnable()
	end
end)
LIB.RegisterInit('MY_ChatBlock', D.LoadBlockWords)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bBlockWords = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bBlockWords = true,
			},
			triggers = {
				bBlockWords = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_ChatBlock = LIB.GeneGlobalNS(settings)
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 0, 0
	D.LoadBlockWords()

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 70,
		text = _L['Enable'],
		checked = MY_ChatBlock.bBlockWords,
		oncheck = function(bCheck)
			MY_ChatBlock.bBlockWords = bCheck
		end,
	})
	x = x + 70

	local edit = ui:Append('WndEditBox', {
		name = 'WndEditBox_Keyword',
		x = x, y = y, w = w - 160 - x, h = 25,
		placeholder = _L['Type keyword, right click list to config.'],
	})
	x, y = 0, y + 30

	local list = ui:Append('WndListBox', { x = x, y = y, w = w, h = h - 30 })
	-- 初始化list控件
	for _, bw in ipairs(O.aBlockWords) do
		list:ListBox('insert', bw.szKeyword, bw.szKeyword, bw)
	end
	list:ListBox('onmenu', function(id, text, data)
		local menu = LIB.GetMsgTypeMenu(function(szType)
			if data.tMsgType[szType] then
				data.tMsgType[szType] = nil
			else
				data.tMsgType[szType] = true
			end
			D.CheckEnable()
			D.SaveBlockWords()
		end, data.tMsgType)
		insert(menu, 1, CONSTANT.MENU_DIVIDER)
		insert(menu, 1, {
			szOption = _L['Edit'],
			fnAction = function()
				GetUserInput(_L['Please input keyword:'], function(szText)
					szText = LIB.TrimString(szText)
					if IsEmpty(szText) then
						return
					end
					data.szKeyword = szText
					D.SaveBlockWords()
					list:ListBox('update', 'id', id, {'text'}, {szText})
				end, nil, nil, nil, data.szKeyword)
			end,
		})
		insert(menu, CONSTANT.MENU_DIVIDER)
		insert(menu, {
			szOption = _L['Ignore spaces'],
			bCheck = true, bChecked = data.bIgnoreSpace,
			fnAction = function()
				data.bIgnoreSpace = not data.bIgnoreSpace
				D.SaveBlockWords()
			end,
		})
		insert(menu, {
			szOption = _L['Ignore enem'],
			bCheck = true, bChecked = data.bIgnoreEnEm,
			fnAction = function()
				data.bIgnoreEnEm = not data.bIgnoreEnEm
				D.SaveBlockWords()
			end,
		})
		insert(menu, {
			szOption = _L['Ignore case'],
			bCheck = true, bChecked = data.bIgnoreCase,
			fnAction = function()
				data.bIgnoreCase = not data.bIgnoreCase
				D.SaveBlockWords()
			end,
		})
		insert(menu, {
			szOption = _L['Ignore acquaintance'],
			bCheck = true, bChecked = data.bIgnoreAcquaintance,
			fnAction = function()
				data.bIgnoreAcquaintance = not data.bIgnoreAcquaintance
				D.SaveBlockWords()
			end,
		})
		insert(menu, CONSTANT.MENU_DIVIDER)
		insert(menu, {
			szOption = _L['Delete'],
			fnAction = function()
				list:ListBox('delete', 'id', id)
				D.LoadBlockWords()
				for i = #O.aBlockWords, 1, -1 do
					if O.aBlockWords[i].szKeyword == id then
						remove(O.aBlockWords, i)
					end
				end
				D.SaveBlockWords()
				UI.ClosePopupMenu()
			end,
		})
		menu.szOption = _L['Channels']
		return menu
	end):ListBox('onlclick', function(id, text, data, selected)
		edit:Text(id)
	end)
	-- add
	ui:Append('WndButton', {
		x = w - 160, y=  0, w = 80,
		text = _L['Add'],
		onclick = function()
			local szText = LIB.TrimString(edit:Text())
			if IsEmpty(szText) then
				return
			end
			D.LoadBlockWords()
			-- 验证是否重复
			for i, bw in ipairs(O.aBlockWords) do
				if bw.szKeyword == szText then
					return
				end
			end
			-- 加入表
			local bw = Clone(DEFAULT_KW_CONFIG)
			bw.szKeyword = szText
			insert(O.aBlockWords, 1, bw)
			D.SaveBlockWords()
			-- 更新UI
			list:ListBox('insert', bw.szKeyword, bw.szKeyword, bw, 1)
		end,
	})
	-- del
	ui:Append('WndButton', {
		x = w - 80, y =  0, w = 80,
		text = _L['Delete'],
		onclick = function()
			for _, v in ipairs(list:ListBox('select', 'selected')) do
				list:ListBox('delete', 'id', v.id)
				D.LoadBlockWords()
				for i = #O.aBlockWords, 1, -1 do
					if O.aBlockWords[i].szKeyword == v.id then
						remove(O.aBlockWords, i)
					end
				end
				D.SaveBlockWords()
			end
		end,
	})
end
LIB.RegisterPanel(_L['Chat'], 'MY_ChatBlock', _L['MY_ChatBlock'], 'UI/Image/Common/Money.UITex|243', PS)
