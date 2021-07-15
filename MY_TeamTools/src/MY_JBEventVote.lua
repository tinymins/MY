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
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PLUGIN_ROOT .. '/ui/MY_JBEventVote.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_JBEventVote__Mod.ini'
local D = {
	aEventList = {},
	tChangedEventID = {},
	tEventRankInfo = {},
	szEventSearch = '',
}

local Schema = LIB.Schema
local EVENT_LIST_SCHEMA = Schema.Record({
	data = Schema.Collection(Schema.Record({
		achieve_ids = Schema.String, -- 8548,8549..  一段以半角逗号分隔的成就ID字符串
		id = Schema.Number, -- 活动ID
		name = Schema.String, -- 活动名称，可用于显示
		vote_start = Schema.Number, -- 投票开启时间
		vote_end = Schema.Number, -- 投票结束时间
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
		}, true)),
		record = Schema.Record({
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
			D.aEventList = res.data
			D.UpdateEventList(frame)
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

function D.UpdateEventList(frame)
	frame.bInitPageset = true
	local pageset = frame:Lookup('PageSet_All')
	for i, eve in ipairs(D.aEventList) do
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
		checkbox.eve = eve
		page.eve = eve
	end
	if D.aEventList[1] then
		D.FetchRankList(frame, D.aEventList[1].id)
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
			D.tChangedEventID[szEventID] = true
			D.tEventRankInfo[szEventID] = res.data
			D.UpdateEvent(frame)
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

function D.UpdateEvent(frame)
	local pageset = frame:Lookup('PageSet_All')
	local page = pageset:GetFirstChild()
	local szEventSearch = wgsub(D.szEventSearch, ' ', ',')
	while page do
		if page:GetName() == 'Page_Event' and (D.tChangedEventID[page.eve.id] or D.tChangedEventID['*']) then
			local bInTime = page.eve.vote_start <= GetCurrentTime() and page.eve.vote_end >= GetCurrentTime()
			local bVoted = Get(D.tEventRankInfo, {page.eve.id, 'record', 'status'}, 0) ~= 0
			local nVotedTeamID = Get(D.tEventRankInfo, {page.eve.id, 'record', 'team_id'}, 0)
			local container = page:Lookup('Wnd_Event/WndScroll_Event/WndContainer_List')
			container:Clear()
			for i, team in ipairs(Get(D.tEventRankInfo, {page.eve.id, 'list'}, {})) do
				if IsEmpty(D.szEventSearch)
				or LIB.StringSimpleMatch(team.server .. ',' .. team.name, szEventSearch) then
					local wnd = container:AppendContentFromIni(SZ_MOD_INI, 'Wnd_Row')
					wnd:Lookup('', 'Text_ItemName'):SetText(LIB.ReplaceSensitiveWord(team.name))
					wnd:Lookup('', 'Text_ItemServer'):SetText(LIB.ReplaceSensitiveWord(team.server))
					wnd:Lookup('', 'Text_ItemLeader'):SetText(LIB.ReplaceSensitiveWord(team.leader_name))
					wnd:Lookup('', 'Text_ItemSlogan'):SetText(LIB.ReplaceSensitiveWord(team.slogan))
					wnd:Lookup('', 'Text_ItemCount'):SetText(LIB.ReplaceSensitiveWord(team.count))
					wnd:Lookup('', 'Image_RowBg'):SetVisible(i % 2 == 1)
					local ui = UI(wnd)
					ui:Append('WndButton', {
						name = 'Btn_Info',
						x = 860, y = 3, w = 100, h = 25,
						buttonstyle = 'LINK',
						text = _L['View Detail'],
					})
					local btn = ui:Append('WndButton', {
						name = 'Btn_Vote',
						x = 960, y = 3, w = 80, h = 25,
						buttonstyle = 'SKEUOMORPHISM',
					})
					if bInTime and not bVoted then
						btn:Text(_L['Vote'])
					elseif nVotedTeamID == team.id then
						btn:Text(_L['Voted'])
						btn:Enable(false)
					else
						btn:Hide()
					end
					wnd.team = team
				end
			end
			container:FormatAllContentPos()
		end
		page = page:GetNext()
	end
	D.tChangedEventID = {}
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
			}, 'e97919f4-1409-4995-9c3e-ff48fc07554b'))),
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
	this.bInitializing = true
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(_L['MY_JBEventVote'])
	this:Lookup('Wnd_Search/Edit_Search'):SetText(D.szEventSearch)
	D.tChangedEventID['*'] = true
	this.bInitializing = nil
	D.OnEvent('UI_SCALED')
	D.UpdateEventList(this)
	D.UpdateEvent(this)
	D.FetchEventList(this)
end

function D.OnEvent(event)
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Info' then
		LIB.OpenBrowser(this:GetParent().team.link)
	elseif name == 'Btn_Vote' then
		D.Vote(this:GetRoot(), this:GetParent().team.event_id, this:GetParent().team.id)
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'WndCheck_Event' then
		local aXml = {}
		insert(aXml, GetFormatText(this.eve.name, 82))
		insert(aXml, CONSTANT.XML_LINE_BREAKER)
		insert(aXml, GetFormatText(_L['Finish achieves: '], 82))
		for _, szAcheveID in ipairs(LIB.SplitString(this.eve.achieve_ids, ',', true)) do
			insert(aXml, GetFormatText('[' .. Get(LIB.GetAchievement(szAcheveID), {'szName'}, '') .. ']', 82))
			if IsCtrlKeyDown() then
				insert(aXml, GetFormatText('(' .. szAcheveID .. ')', 102))
			end
		end
		insert(aXml, CONSTANT.XML_LINE_BREAKER)
		insert(aXml, GetFormatText(_L['Start time: '], 82))
		insert(aXml, GetFormatText(LIB.FormatTime(this.eve.vote_start, '%yyyy/%MM/%dd %hh:%mm:%ss'), 82))
		insert(aXml, CONSTANT.XML_LINE_BREAKER)
		insert(aXml, GetFormatText(_L['End time: '], 82))
		insert(aXml, GetFormatText(LIB.FormatTime(this.eve.vote_end, '%yyyy/%MM/%dd %hh:%mm:%ss'), 82))
		insert(aXml, CONSTANT.XML_LINE_BREAKER)
		if IsCtrlKeyDown() then
			insert(aXml, GetFormatText('ID: ' .. this.eve.id, 102))
		end
		LIB.OutputTip(this, concat(aXml), true, ALW.TOP_BOTTOM, 400)
	end
end

function D.OnMouseLeave()
	local name = this:GetName()
	if name == 'WndCheck_Event' then
		HideTip()
	end
end

function D.OnEditChanged()
	local frame = this:GetRoot()
	if not frame or frame.bInitializing then
		return
	end
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Edit_Search' then
		D.szEventSearch = LIB.TrimString(this:GetText())
		D.tChangedEventID['*'] = true
		LIB.DelayCall('MY_JBEventVote__Search', 300, function() D.UpdateEvent(frame) end)
	end
end

function D.OnActivePage()
	local frame = this:GetRoot()
	if not frame or frame.bInitializing then
		return
	end
	if frame.bInitPageset then
		return
	end
	local name = this:GetName()
	if name == 'PageSet_All' then
		local page = this:GetActivePage()
		D.FetchRankList(frame, page.eve.id)
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

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	local me = GetClientPlayer()
	if me and me.nMaxLevel == me.nLevel then
		nX = X
		nY = nLFY
		nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Dungeon Vote'], font = 27 }):Height() + 2

		nX = X + 10
		nX = nX + ui:Append('WndButton', {
			x = nX, y = nY, w = 'auto',
			buttonstyle = 'FLAT',
			text = _L['MY_JBEventVote'],
			onclick = function()
				D.Open()
			end,
		}):Width() + 5

		nLFY = nY + LH
	end
	return nX, nY, nLFY
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_JBEventVote',
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
MY_JBEventVote = LIB.CreateModule(settings)
end
