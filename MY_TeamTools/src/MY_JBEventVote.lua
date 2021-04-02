--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 魔盒投票
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
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
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PACKET_INFO.ROOT .. 'MY_ToolBox/ui/MY_JBEventVote.ini'
local SZ_MOD_INI = PACKET_INFO.ROOT .. 'MY_ToolBox/ui/MY_JBEventVote__Mod.ini'
local D = {}

local Schema = LIB.Schema
local EVENT_LIST_SCHEMA = Schema.Record({
	data = Schema.Collection(Schema.Record({
		achieve_ids = Schema.String, -- 8548,8549..  一段以半角逗号分隔的成就ID字符串
		id = Schema.Number, -- 活动ID
		name = Schema.String, -- 活动名称，可用于显示
		vote_end = Schema.String, -- 投票结束时间
		vote_start = Schema.String, -- 投票开启时间
	}, true)),
}, true)
local RANK_DATA_SCHEMA = Schema.Record({
	data = Schema.Record({
		list = Schema.Collection(Schema.Record({
			id = Schema.Number, -- 团队ID
			event_id = Schema.Number, -- 活动ID
			count = Schema.Number, -- 票数
			name = Schema.String, -- 团队名称
			server = Schema.String, -- 团队服务器
			leader_name = Schema.String, -- 团长名字
			slogan = Schema.String, -- 参赛宣言，已由运营审核
			link = Schema.String, -- 团队主页（查看详情的链接地址）
			checked = Schema.Number, -- 默认为0，当为1时代表该用户已投票该队伍
		}, true),
		record = Schema.Collection(Schema.Record({
			status = Schema.Number, -- 是否已投票
			team_id = Schema.Number, -- 已投票的团队ID
		}, true),
	}, true),
}, true)
local VOTE_SCHEMA = Schema.Record({
	msg = Schema.String,
}, true)

function D.FetchEventList(frame)
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = 'https://pull.j3cx.com/event/list?'
			.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				jx3id = AnsiToUTF8(LIB.GetClientUUID()),
			}, '84cf7ba4-7fbb-4d59-9eb2-9b0ce89494ed'))),
		charset = 'utf8',
		success = function(szHTML)
			local res, err = LIB.JsonDecode(szHTML)
			if not res then
				LIB.Alert(_L['ERR: Decode eventlist content as json failed!'] .. err)
				Wnd.CloseWindow(frame)
				return
			end
			local errs = Schema.CheckSchema(res, EVENT_LIST_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				LIB.Alert(_L['ERR: Eventlist content is illegal!'] .. '\n\n' .. LIB.ReplaceSensitiveWord(concat(aErrmsgs, '\n')))
				Wnd.CloseWindow(frame)
				return
			end
			D.UpdateEventList(frame, res.data)
		end,
		error = function(html, status)
			if status == 404 then
				LIB.Alert(_L['ERR404: Eventlist address not found!'])
				Wnd.CloseWindow(frame)
				return
			end
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_JBEventVote'], 'ERROR Get Eventlist: ' .. status .. '\n' .. UTF8ToAnsi(html), DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			Wnd.CloseWindow(frame)
		end,
	})
end

function D.UpdateEventList(frame, aEventList)
	frame.bInitPageset = true
	local pageset = frame:Lookup('PageSet_All')
	for i, eve in ipairs(aEventList) do
		local frameMod = Wnd.OpenWindow(SZ_MOD_INI, 'MY_JBEventVote__Mod')
		local checkbox = frameMod:Lookup('PageSet_All/WndCheck_Event')
		local page = frameMod:Lookup('PageSet_All/Page_Event')
		page:Lookup('Wnd_Event/WndScroll_Event', 'Handle_EventColumns/Handle_EventColumn_Name/Handle_EventColumn_Name_Title/Text_EventColumn_Name_Title'):SetText(_L['Team Name'])
		page:Lookup('Wnd_Event/WndScroll_Event', 'Handle_EventColumns/Handle_EventColumn_Server/Handle_EventColumn_Server_Title/Text_EventColumn_Server_Title'):SetText(_L['Server'])
		page:Lookup('Wnd_Event/WndScroll_Event', 'Handle_EventColumns/Handle_EventColumn_Leader/Handle_EventColumn_Leader_Title/Text_EventColumn_Leader_Title'):SetText(_L['Leader'])
		page:Lookup('Wnd_Event/WndScroll_Event', 'Handle_EventColumns/Handle_EventColumn_Slogan/Handle_EventColumn_Slogan_Title/Text_EventColumn_Slogan_Title'):SetText(_L['Slogan'])
		page:Lookup('Wnd_Event/WndScroll_Event', 'Handle_EventColumns/Handle_EventColumn_Count/Handle_EventColumn_Count_Title/Text_EventColumn_Count_Title'):SetText(_L['Vote Count'])
		page:Lookup('Wnd_Event/WndScroll_Event/WndContainer_List'):Clear()
		checkbox:ChangeRelation(pageset, true, true)
		page:ChangeRelation(pageset, true, true)
		Wnd.CloseWindow(frameMod)
		pageset:AddPage(page, checkbox)
		checkbox:Show()
		checkbox:Lookup('', 'Text_CheckEvent'):SetText(LIB.ReplaceSensitiveWord(eve.name))
		checkbox:SetRelX(checkbox:GetRelX() + checkbox:GetW() * (i - 1))
		checkbox.szEventID = eve.id
		page.szEventID = eve.id
	end
	if aEventList[1] then
		D.FetchRankList(frame, aEventList[1].id)
	end
	frame.bInitPageset = nil
end

function D.FetchRankList(frame, szEventID)
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = 'https://pull.j3cx.com/rank/list?'
			.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				jx3id = AnsiToUTF8(LIB.GetClientUUID()),
				event_id = szEventID,
			}, '84cf7ba4-7fbb-4d59-9eb2-9b0ce89494ed'))),
		charset = 'utf8',
		success = function(szHTML)
			local res, err = LIB.JsonDecode(szHTML)
			if not res then
				LIB.Alert(_L['ERR: Decode rankdata content as json failed!'] ..err)
				return
			end
			local errs = Schema.CheckSchema(res, RANK_DATA_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				LIB.Alert(_L['ERR: Rankdata content is illegal!'] .. '\n\n' .. LIB.ReplaceSensitiveWord(concat(aErrmsgs, '\n')))
				return
			end
			D.UpdateEvent(frame, szEventID, res.data)
		end,
		error = function(html, status)
			if status == 404 then
				LIB.Alert(_L['ERR404: Rankdata address not found!'])
				return
			end
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_JBEventVote'], 'ERROR Get Rankdata: ' .. status .. '\n' .. UTF8ToAnsi(html), DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
		end,
	})
end

function D.UpdateEvent(frame, szEventID, aRankList)
	local pageset = frame:Lookup('PageSet_All')
	local page = pageset:GetFirstChild()
	while page do
		if page:GetName() == 'Page_Event' and page.szEventID == szEventID then
			local container = page:Lookup('Wnd_Event/WndScroll_Event/WndContainer_List')
			container:Clear()
			for i, eve in ipairs(aRankList) do
				local wnd = container:AppendContentFromIni(SZ_MOD_INI, 'Wnd_Row')
				wnd:Lookup('', 'Text_ItemName'):SetText(LIB.ReplaceSensitiveWord(eve.name))
				wnd:Lookup('', 'Text_ItemServer'):SetText(LIB.ReplaceSensitiveWord(eve.server))
				wnd:Lookup('', 'Text_ItemLeader'):SetText(LIB.ReplaceSensitiveWord(eve.leader_name))
				wnd:Lookup('', 'Text_ItemSlogan'):SetText(LIB.ReplaceSensitiveWord(eve.slogan))
				wnd:Lookup('', 'Text_ItemCount'):SetText(LIB.ReplaceSensitiveWord(eve.count))
				wnd:Lookup('', 'Image_RowBg'):SetVisible(i % 2 == 1)
				wnd:Lookup('Btn_Vote', 'Text_Vote'):SetText(_L['Vote'])
				wnd:Lookup('Btn_Info', 'Text_Info'):SetText(_L['View Detail'])
				wnd.eve = eve
			end
			container:FormatAllContentPos()
		end
		page = page:GetNext()
	end
end

function D.Vote(frame, szEventID, szTeamID)
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = 'https://push.j3cx.com/rank/vote?'
			.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				jx3id = AnsiToUTF8(LIB.GetClientUUID()),
				event_id = szEventID,
				team_id = szTeamID,
			}, '84cf7ba4-7fbb-4d59-9eb2-9b0ce89494ed'))),
		charset = 'utf8',
		success = function(szHTML)
			local res, err = LIB.JsonDecode(szHTML)
			if not res then
				LIB.Alert(_L['ERR: Decode vote content as json failed!'] ..err)
				return
			end
			local errs = Schema.CheckSchema(res, VOTE_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				LIB.Alert(_L['ERR: Vote content is illegal!'] .. '\n\n' .. LIB.ReplaceSensitiveWord(concat(aErrmsgs, '\n')))
				return
			end
			LIB.Alert(LIB.ReplaceSensitiveWord(res.msg))
			D.FetchRankList(frame, szEventID)
		end,
		error = function(html, status)
			if status == 404 then
				LIB.Alert(_L['ERR404: Vote address not found!'])
				return
			end
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_JBEventVote'], 'ERROR Push Vote: ' .. status .. '\n' .. UTF8ToAnsi(html), DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
		end,
	})
end

function D.OnFrameCreate()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(_L['MY_JBEventVote'])
	D.OnEvent('UI_SCALED')
	D.FetchEventList(this)
end

function D.OnEvent(event)
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Info' then
		LIB.OpenBrowser(this:GetParent().eve.link)
	elseif name == 'Btn_Vote' then
		D.Vote(this:GetRoot(), this:GetParent().eve.event_id, this:GetParent().eve.id)
	end
end

function D.OnActivePage()
	local frame = this:GetRoot()
	if frame.bInitPageset then
		return
	end
	local name = this:GetName()
	if name == 'PageSet_All' then
		local page = this:GetActivePage()
		D.FetchRankList(frame, page.szEventID)
	end
end

function D.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_JBEventVote'):BringToTop()
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_JBEventVote')
end

function D.Close()
	Wnd.CloseWindow('MY_JBEventVote')
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	local me = GetClientPlayer()
	if not me or me.nMaxLevel ~= me.nLevel then
		return
	end
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 'auto',
		buttonstyle = 2,
		text = _L['MY_JBEventVote'],
		onclick = function()
			D.Open()
		end,
	}):Width() + 5

	x = X
	return x, y
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
MY_JBEventVote = LIB.GeneGlobalNS(settings)
end
