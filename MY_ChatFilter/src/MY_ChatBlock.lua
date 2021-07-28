--------------------------------------------
-- @Desc  : ÁÄÌì¸¨Öú
-- @Author: ÜøÒÁ @tinymins
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatFilter'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatBlock'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
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

local O = LIB.CreateUserSettingsModule('MY_ChatBlock', _L['Chat'], {
	bBlockWords = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatBlock'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	aBlockWords = {
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ChatBlock'],
		xSchema = Schema.Collection(Schema.Record({
			uuid = Schema.Optional(Schema.String),
			szKeyword = Schema.String,
			tMsgType = Schema.Map(Schema.String, Schema.Boolean),
			bIgnoreAcquaintance = Schema.Boolean,
			bIgnoreCase = Schema.Boolean,
			bIgnoreEnEm = Schema.Boolean,
			bIgnoreSpace = Schema.Boolean,
		})),
		xDefaultValue = {},
	},
})
local D = {}

function D.IsBlockMsg(szText, szMsgType, dwTalkerID)
	local bAcquaintance = dwTalkerID
		and (LIB.GetFriend(dwTalkerID) or LIB.GetFoe(dwTalkerID) or LIB.GetTongMember(dwTalkerID))
		or false
	for _, bw in ipairs(D.aBlockWords) do
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
	local szText = LIB.StringifyChatText(t)
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
	if not D.bReady or not D.aBlockWords or not O.bBlockWords then
		return
	end
	local tChannel, tMsgType = {}, {}
	for _, bw in ipairs(D.aBlockWords) do
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

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatBlock', function()
	D.bReady = true
	D.aBlockWords = O.aBlockWords
	D.CheckEnable()
end)
LIB.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_ChatBlock', function()
	D.bReady = false
	D.CheckEnable()
end)

-- Global exports
do
local settings = {
	name = 'MY_ChatBlock',
	exports = {
		{
			fields = {
				'bBlockWords',
			},
			root = O,
		},
	},
}
MY_ChatBlock = LIB.CreateModule(settings)
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 0, 0

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 70,
		text = _L['Enable'],
		checked = O.bBlockWords,
		oncheck = function(bCheck)
			O.bBlockWords = bCheck
			D.CheckEnable()
		end,
	})
	x = x + 70

	local edit = ui:Append('WndEditBox', {
		name = 'WndEditBox_Keyword',
		x = x, y = y, w = w - 160 - x, h = 25,
		placeholder = _L['Type keyword, right click list to config.'],
	})
	x, y = 0, y + 30

	local aBlockWords = O.aBlockWords
	local function SeekBlockWord(uuid)
		for i = #aBlockWords, 1, -1 do
			if aBlockWords[i].uuid == uuid then
				return aBlockWords[i]
			end
		end
	end

	local function RemoveBlockWord(uuid)
		for i = #aBlockWords, 1, -1 do
			if aBlockWords[i].uuid == uuid then
				remove(aBlockWords, i)
			end
		end
	end

	local list = ui:Append('WndListBox', { x = x, y = y, w = w, h = h - 30 })
	local function ReloadBlockWords()
		O('reload', {'aBlockWords'})
		aBlockWords = O.aBlockWords

		local bSave = false
		for _, bw in ipairs(aBlockWords) do
			if not bw.uuid then
				bw.uuid = LIB.GetUUID()
				bSave = true
			end
		end
		if bSave then
			O.aBlockWords = aBlockWords
		end
		aBlockWords = O.aBlockWords

		D.aBlockWords = aBlockWords
		D.CheckEnable()

		list:ListBox('clear')
		for _, bw in ipairs(aBlockWords) do
			list:ListBox('insert', { id = bw.uuid, text = bw.szKeyword, data = bw })
		end
	end
	ReloadBlockWords()

	local function SaveBlockWords()
		O.aBlockWords = aBlockWords
		ReloadBlockWords()
	end

	list:ListBox('onmenu', function(id, text, data)
		local menu = LIB.GetMsgTypeMenu(function(szType)
			local bw = SeekBlockWord(id)
			if bw then
				if bw.tMsgType[szType] then
					bw.tMsgType[szType] = nil
				else
					bw.tMsgType[szType] = true
				end
				SaveBlockWords()
			end
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
					local bw = SeekBlockWord(id)
					if bw then
						bw.szKeyword = szText
						SaveBlockWords()
					end
				end, nil, nil, nil, data.szKeyword)
			end,
		})
		insert(menu, CONSTANT.MENU_DIVIDER)
		insert(menu, {
			szOption = _L['Ignore spaces'],
			bCheck = true, bChecked = data.bIgnoreSpace,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreSpace = not bw.bIgnoreSpace
					SaveBlockWords()
				end
			end,
		})
		insert(menu, {
			szOption = _L['Ignore enem'],
			bCheck = true, bChecked = data.bIgnoreEnEm,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreEnEm = not bw.bIgnoreEnEm
					SaveBlockWords()
				end
			end,
		})
		insert(menu, {
			szOption = _L['Ignore case'],
			bCheck = true, bChecked = data.bIgnoreCase,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreCase = not bw.bIgnoreCase
					SaveBlockWords()
				end
			end,
		})
		insert(menu, {
			szOption = _L['Ignore acquaintance'],
			bCheck = true, bChecked = data.bIgnoreAcquaintance,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreAcquaintance = not bw.bIgnoreAcquaintance
					SaveBlockWords()
				end
			end,
		})
		insert(menu, CONSTANT.MENU_DIVIDER)
		insert(menu, {
			szOption = _L['Delete'],
			fnAction = function()
				RemoveBlockWord(id)
				SaveBlockWords()
				UI.ClosePopupMenu()
			end,
		})
		menu.szOption = _L['Channels']
		return menu
	end):ListBox('onlclick', function(id, text, data, selected)
		edit:Text(text)
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
			O('reload', {'aBlockWords'})
			local bw = Clone(DEFAULT_KW_CONFIG)
			bw.uuid = LIB.GetUUID()
			bw.szKeyword = szText
			insert(aBlockWords, 1, bw)
			SaveBlockWords()
		end,
	})
	-- del
	ui:Append('WndButton', {
		x = w - 80, y =  0, w = 80,
		text = _L['Delete'],
		onclick = function()
			O('reload', {'aBlockWords'})
			for _, v in ipairs(list:ListBox('select', 'selected')) do
				RemoveBlockWord(v.id)
			end
			SaveBlockWords()
		end,
	})
end
LIB.RegisterPanel(_L['Chat'], 'MY_ChatBlock', _L['MY_ChatBlock'], 'UI/Image/Common/Money.UITex|243', PS)
