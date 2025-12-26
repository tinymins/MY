--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 魔盒投票
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBEventVote'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local INI_PATH = PLUGIN_ROOT .. '/ui/MY_JBEventVote.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_JBEventVote__Mod.ini'
local D = {
	aEventList = {},
	tChangedEventID = {},
	tEventRankInfo = {},
	szEventSearch = '',
}

local Schema = X.Schema
local EVENT_LIST_SCHEMA = X.Schema.Record({
	data = X.Schema.Collection(X.Schema.Record({
		achieve_ids = X.Schema.String, -- 8548,8549..  一段以半角逗号分隔的成就ID字符串
		id = X.Schema.Number, -- 活动ID
		name = X.Schema.String, -- 活动名称，可用于显示
		vote_start = X.Schema.Number, -- 投票开启时间
		vote_end = X.Schema.Number, -- 投票结束时间
	}, true)),
}, true)
local RANK_DATA_SCHEMA = X.Schema.Record({
	data = X.Schema.Record({
		list = X.Schema.Collection(X.Schema.Record({
			id = X.Schema.Number, -- 团队ID
			event_id = X.Schema.Number, -- 活动ID
			count = X.Schema.Number, -- 票数
			name = X.Schema.String, -- 团队名称
			server = X.Schema.String, -- 团队服务器
			leader_name = X.Schema.String, -- 团长名字
			slogan = X.Schema.String, -- 参赛宣言，已由运营审核
			link = X.Schema.String, -- 团队主页（查看详情的链接地址）
			checked = X.Schema.Number, -- 默认为0，当为1时代表该用户已投票该队伍
		}, true)),
		record = X.Schema.Record({
			status = X.Schema.Number, -- 是否已投票
			team_id = X.Schema.Number, -- 已投票的团队ID
		}, true),
	}, true),
}, true)
local VOTE_SCHEMA = X.Schema.Record({
	msg = X.Schema.String,
}, true)

function D.FetchEventList(frame)
	X.Ajax({
		url = MY_RSS.PULL_BASE_URL .. '/event/list',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetClientPlayerGlobalID(),
		},
		signature = X.SECRET['J3CX::EVENT_LIST'],
		success = function(szHTML)
			local res, err = X.DecodeJSON(szHTML)
			if not res then
				X.Alert(_L['ERR: Decode eventlist content as json failed!'] .. err)
				X.UI.CloseFrame(frame)
				return
			end
			local errs = X.Schema.CheckSchema(res, EVENT_LIST_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				X.Alert(_L['ERR: Eventlist content is illegal!'] .. '\n\n' .. X.ReplaceSensitiveWord(table.concat(aErrmsgs, '\n')))
				X.UI.CloseFrame(frame)
				return
			end
			D.aEventList = res.data
			D.UpdateEventList(frame)
		end,
		error = function(html, status)
			if status == 404 then
				X.Alert(_L['ERR404: Eventlist address not found!'])
				X.UI.CloseFrame(frame)
				return
			end
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_JBEventVote'], 'ERROR Get Eventlist: ' .. status .. '\n' .. UTF8ToAnsi(html), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			X.UI.CloseFrame(frame)
		end,
	})
end

function D.UpdateEventList(frame)
	frame.bInitPageset = true
	local pageset = frame:Lookup('PageSet_All')
	for i, eve in ipairs(D.aEventList) do
		local frameMod = X.UI.OpenFrame(SZ_MOD_INI, 'MY_JBEventVote__Mod')
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
		X.UI.CloseFrame(frameMod)
		pageset:AddPage(page, checkbox)
		checkbox:Show()
		checkbox:Lookup('', 'Text_CheckEvent'):SetText(X.ReplaceSensitiveWord(eve.name))
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
	X.Ajax({
		url = MY_RSS.PULL_BASE_URL .. '/rank/list',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetClientPlayerGlobalID(),
			event_id = szEventID,
		},
		signature = X.SECRET['J3CX::RANK_LIST'],
		success = function(szHTML)
			local res, err = X.DecodeJSON(szHTML)
			if not res then
				X.Alert(_L['ERR: Decode rankdata content as json failed!'] ..err)
				return
			end
			local errs = X.Schema.CheckSchema(res, RANK_DATA_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				X.Alert(_L['ERR: Rankdata content is illegal!'] .. '\n\n' .. X.ReplaceSensitiveWord(table.concat(aErrmsgs, '\n')))
				return
			end
			D.tChangedEventID[szEventID] = true
			D.tEventRankInfo[szEventID] = res.data
			D.UpdateEvent(frame)
		end,
		error = function(html, status)
			if status == 404 then
				X.Alert(_L['ERR404: Rankdata address not found!'])
				return
			end
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_JBEventVote'], 'ERROR Get Rankdata: ' .. status .. '\n' .. UTF8ToAnsi(html), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
		end,
	})
end

function D.UpdateEvent(frame)
	local pageset = frame:Lookup('PageSet_All')
	local page = pageset:GetFirstChild()
	local szEventSearch = X.StringReplaceW(D.szEventSearch, ' ', ',')
	while page do
		if page:GetName() == 'Page_Event' and (D.tChangedEventID[page.eve.id] or D.tChangedEventID['*']) then
			local bInTime = page.eve.vote_start <= GetCurrentTime() and page.eve.vote_end >= GetCurrentTime()
			local bVoted = X.Get(D.tEventRankInfo, {page.eve.id, 'record', 'status'}, 0) ~= 0
			local nVotedTeamID = X.Get(D.tEventRankInfo, {page.eve.id, 'record', 'team_id'}, 0)
			local container = page:Lookup('Wnd_Event/WndScroll_Event/WndContainer_List')
			container:Clear()
			for i, team in ipairs(X.Get(D.tEventRankInfo, {page.eve.id, 'list'}, {})) do
				if X.IsEmpty(D.szEventSearch)
				or X.StringSimpleMatch(team.server .. ',' .. team.name, szEventSearch) then
					local wnd = container:AppendContentFromIni(SZ_MOD_INI, 'Wnd_Row')
					wnd:Lookup('', 'Text_ItemName'):SetText(X.ReplaceSensitiveWord(team.name))
					wnd:Lookup('', 'Text_ItemServer'):SetText(X.ReplaceSensitiveWord(team.server))
					wnd:Lookup('', 'Text_ItemLeader'):SetText(X.ReplaceSensitiveWord(team.leader_name))
					wnd:Lookup('', 'Text_ItemSlogan'):SetText(X.ReplaceSensitiveWord(team.slogan))
					wnd:Lookup('', 'Text_ItemCount'):SetText(X.ReplaceSensitiveWord(team.count))
					wnd:Lookup('', 'Image_RowBg'):SetVisible(i % 2 == 1)
					local ui = X.UI(wnd)
					ui:Append('WndButton', {
						name = 'Btn_Info',
						x = 860, y = 3, w = 100, h = 25,
						buttonStyle = 'LINK',
						text = _L['View Detail'],
					})
					local btn = ui:Append('WndButton', {
						name = 'Btn_Vote',
						x = 960, y = 3, w = 80, h = 25,
						buttonStyle = 'SKEUOMORPHISM',
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
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/rank/vote',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetClientPlayerGlobalID(),
			event_id = szEventID,
			team_id = szTeamID,
		},
		signature = X.SECRET['J3CX::RANK_VOTE'],
		success = function(szHTML)
			local res, err = X.DecodeJSON(szHTML)
			if not res then
				X.Alert(_L['ERR: Decode vote content as json failed!'] ..err)
				return
			end
			local errs = X.Schema.CheckSchema(res, VOTE_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				X.Alert(_L['ERR: Vote content is illegal!'] .. '\n\n' .. X.ReplaceSensitiveWord(table.concat(aErrmsgs, '\n')))
				return
			end
			X.Alert(X.ReplaceSensitiveWord(res.msg))
			D.FetchRankList(frame, szEventID)
		end,
		error = function(html, status)
			if status == 404 then
				X.Alert(_L['ERR404: Vote address not found!'])
				return
			end
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_JBEventVote'], 'ERROR Push Vote: ' .. status .. '\n' .. UTF8ToAnsi(html), X.DEBUG_LEVEL.WARNING)
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
		X.UI.CloseFrame(this:GetRoot())
	elseif name == 'Btn_Info' then
		X.OpenBrowser(this:GetParent().team.link)
	elseif name == 'Btn_Vote' then
		D.Vote(this:GetRoot(), this:GetParent().team.event_id, this:GetParent().team.id)
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'WndCheck_Event' then
		local aXml = {}
		table.insert(aXml, GetFormatText(this.eve.name, 82))
		table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(aXml, GetFormatText(_L['Finish achieves: '], 82))
		for _, szAcheveID in ipairs(X.SplitString(this.eve.achieve_ids, ',', true)) do
			table.insert(aXml, GetFormatText('[' .. X.Get(X.GetAchievement(szAcheveID), {'szName'}, '') .. ']', 82))
			if IsCtrlKeyDown() then
				table.insert(aXml, GetFormatText('(' .. szAcheveID .. ')', 102))
			end
		end
		table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(aXml, GetFormatText(_L['Start time: '], 82))
		table.insert(aXml, GetFormatText(X.FormatTime(this.eve.vote_start, '%yyyy/%MM/%dd %hh:%mm:%ss'), 82))
		table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(aXml, GetFormatText(_L['End time: '], 82))
		table.insert(aXml, GetFormatText(X.FormatTime(this.eve.vote_end, '%yyyy/%MM/%dd %hh:%mm:%ss'), 82))
		table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		if IsCtrlKeyDown() then
			table.insert(aXml, GetFormatText('ID: ' .. this.eve.id, 102))
		end
		X.OutputTip(this, table.concat(aXml), true, ALW.TOP_BOTTOM, 400)
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
		D.szEventSearch = X.TrimString(this:GetText())
		D.tChangedEventID['*'] = true
		X.DelayCall('MY_JBEventVote__Search', 300, function() D.UpdateEvent(frame) end)
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
	X.UI.OpenFrame(INI_PATH, 'MY_JBEventVote'):BringToTop()
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_JBEventVote')
end

function D.Close()
	X.UI.CloseFrame('MY_JBEventVote')
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	local me = X.GetClientPlayer()
	if me and me.nMaxLevel == me.nLevel then
		nX = nPaddingX
		nY = nLFY
		nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Dungeon Vote'], font = 27 }):Height() + 2

		nX = nPaddingX + 10
		nX = nX + ui:Append('WndButton', {
			x = nX, y = nY, w = 'auto',
			buttonStyle = 'FLAT',
			text = _L['MY_JBEventVote'],
			onClick = function()
				D.Open()
			end,
		}):Width() + 5

		nLFY = nY + nLH
	end
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
MY_JBEventVote = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
