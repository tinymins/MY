--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控远程数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon', _L['MY_TeamMon'], 0x2013500) then
	return
end

local D = {}
local O = {}
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_RR.ini'
local MY_TM_DATA_ROOT = MY_TeamMon.MY_TM_DATA_ROOT
local MY_TM_DATA_PASSPHRASE = '89g45ynbtldnsryu98rbny9ps7468hb6npyusiryuxoldg7lbn894bn678b496746'
local RSS_DEFAULT = {{
	szAuthor = _L['Default'],
	szTitle = _L['Default monitor data'],
	szURL = 'https://code.aliyun.com/tinymins/JX3_MY_DATA/raw/master/MY_TeamMon/',
}}
local RSS_SEL_INFO, RSS_DOWNLOADER

function D.OpenPanel()
	Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_RR')
end

function D.ClosePanel()
	Wnd.CloseWindow('MY_TeamMon_RR')
end

function D.LoadRSSList()
	return LIB.LoadLUAData({'userdata/MY_TeamMon_RSS.jx3dat', PATH_TYPE.GLOBAL}) or {}
end

function D.SaveRSSList(aRss)
	LIB.SaveLUAData({'userdata/MY_TeamMon_RSS.jx3dat', PATH_TYPE.GLOBAL}, aRss)
end

function D.DownloadMeta(szURL, onSuccess, onError)
	if not wfind(szURL, '.') and not wfind(szURL, '/') then
		szURL = 'https://code.aliyun.com/'
			.. szURL .. '/JX3_MY_DATA/raw/master/MY_TeamMon/'
	end
	LIB.Ajax({
		url = LIB.ConcatPath(szURL, LIB.GetLang(), 'info.json'),
		success = function(szHTML)
			local szJson = UTF8ToAnsi(szHTML)
			local res = LIB.JsonDecode(szJson)
			if not res then
				return onError(_L['ERR: Info content is illegal!'])
			end
			local info = {
				szURL = szURL,
				szKey = LIB.GetUUID(),
				szAuthor = res.author or '',
				szTitle = res.name or '',
				szAbout = res.about or '',
				szVersion = res.version or '',
			}
			onSuccess(info)
		end,
		error = function(html, status)
			if status == 404 then
				return onError(_L['ERR404: Rss is empty!'])
			end
			onError()
		end,
	})
end

function D.LoadConfigureFile(szFile, info)
	MY_TeamMon_UI.OpenImportPanel(szFile, info.szTitle .. ' - ' .. info.szAuthor, function()
		local me = GetClientPlayer()
		if me.IsInParty() then
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_RR', 'LOAD', info.szTitle)
		end
	end)
end

function D.DownloadData(info)
	D.DownloadMeta(info.szURL, function(info)
		local szUUID = 'Remote-' .. MD5(info.szURL)
		local p = LoadLUAData(MY_TM_DATA_ROOT .. szUUID .. '.info.jx3dat')
		if p and p.szVersion == info.szVersion then
			return D.LoadConfigureFile(szUUID .. '.jx3dat', info)
		end
		if not RSS_DOWNLOADER and RSS_DOWNLOADER:IsValid() then
			return LIB.Topmsg(_L['Downloader is not ready!'])
		end
		if RSS_DOWNLOADER.bLock then
			return LIB.Topmsg(_L['Dowloading in progress, please wait...'])
		end
		RSS_DOWNLOADER.bLock = true
		RSS_DOWNLOADER.FromTextureFile = function(_, szPath)
			local data = LIB.LoadLUAData(szPath, { passphrase = MY_TM_DATA_PASSPHRASE })
			local szFile = szUUID .. '.jx3dat'
			if data then
				SaveLUAData(MY_TM_DATA_ROOT .. szUUID .. '.info.jx3dat', info)
				LIB.SaveLUAData(MY_TM_DATA_ROOT .. szFile, data, { passphrase = MY_TM_DATA_PASSPHRASE })
				D.LoadConfigureFile(szFile, info)
			else
				LIB.Topmsg(_L('Decode %s failed!', info.szTitle))
			end
			RSS_DOWNLOADER.bLock = false
		end
		RSS_DOWNLOADER:FromRemoteFile(info.szURL .. LIB.GetLang() .. '/data.jx3dat')
	end, function(szErrmsg)
		if szErrmsg then
			LIB.Alert(szErrmsg)
		end
	end)
end

function D.UpdateList(frame)
	if not frame and frame:IsValid() then
		return
	end
	local aRss = D.LoadRSSList()
	local container = frame:Lookup('PageSet_Menu/Page_FileDownload/WndScroll_FileDownload/WndContainer_FileDownload_List')
	container:Clear()
	for _, p in spairs(RSS_DEFAULT, aRss) do
		local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
		wnd:Lookup('', 'Text_Item_Author'):SetText(p.szAuthor)
		wnd:Lookup('', 'Text_Item_Title'):SetText(p.szTitle)
		wnd:Lookup('Btn_Info'):SetVisible(not IsEmpty(p.szAbout))
		wnd:Lookup('Btn_Info', 'Text_Info'):SetText(_L['See details'])
		wnd:Lookup('Btn_Download', 'Text_Download'):SetText(_L['Download'])
		wnd.info = p
	end
	container:FormatAllContentPos()
end

function D.OnFrameCreate()
	RSS_DOWNLOADER = this:Lookup('', 'Image_Downloader')
	this:Lookup('Btn_SyncTeam', 'Text_SyncTeam'):SetText(_L['Sync team'])
	this:Lookup('Btn_AddUrl', 'Text_AddUrl'):SetText(_L['Add url'])
	this:Lookup('Btn_RemoveUrl', 'Text_RemoveUrl'):SetText(_L['Remove url'])
	this:Lookup('PageSet_Menu/Page_FileDownload', 'Text_Record_Break1'):SetText(_L['Author'])
	this:Lookup('PageSet_Menu/Page_FileDownload', 'Text_Record_Break2'):SetText(_L['Title'])
	D.UpdateList(this)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Close' then
		D.ClosePanel()
	elseif name == 'Btn_Download' then
		D.DownloadData(this:GetParent().info)
	elseif name == 'Btn_AddUrl' then
		GetUserInput(_L['Please input rss address:'], function(szURL)
			D.DownloadMeta(szURL, function(info)
				local aRss = D.LoadRSSList()
				insert(aRss, {
					szAuthor = info.author or '',
					szTitle = info.name or '',
					szAbout = info.about or '',
					szURL = szURL,
					szKey = LIB.GetUUID(),
				})
				D.SaveRSSList(aRss)
				D.UpdateList(frame)
			end, function(szErrmsg)
				if szErrmsg then
					LIB.Alert(szErrmsg)
				end
			end)
		end)
	elseif name == 'Btn_RemoveUrl' then
		if not RSS_SEL_INFO then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		LIB.Confirm(_L['Confirm?'], function()
			local aRss = D.LoadRSSList()
			for i, p in ipairs_r(aRss) do
				if p.szKey == RSS_SEL_INFO.szKey then
					remove(aRss, i)
				end
			end
			D.SaveRSSList(aRss)
			D.UpdateList(frame)
		end)
	elseif name == 'Btn_Info' then
		LIB.OpenBrowser(this:GetParent().info.szAbout)
	elseif name == 'Btn_SyncTeam' then
		if not RSS_SEL_INFO then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		if not LIB.IsInParty() then
			return LIB.Alert(_L['You are not in the team.'])
		end
		if not LIB.IsLeader() and not LIB.IsDebugClient(true) then
			return LIB.Alert(_L['You are not team leader.'])
		end
		LIB.Confirm(_L['Confirm?'], function()
			if not RSS_SEL_INFO or not LIB.IsInParty() or (not LIB.IsLeader() and not LIB.IsDebugClient(true)) then
				return
			end
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_RR', 'SYNC', RSS_SEL_INFO)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local container = wnd:GetParent()
		for i = 0, container:GetAllContentCount() - 1 do
			local wnd = container:LookupContent(i)
			wnd:Lookup('', 'Image_Item_Sel'):Hide()
		end
		RSS_SEL_INFO = wnd.info
		wnd:Lookup('', 'Image_Item_Sel'):Show()
	end
end

LIB.RegisterBgMsg('MY_TeamMon_RR', function(_, _, _, szTalker, _, action, info)
	if action == 'SYNC' then
		LIB.Confirm(_L('%s request download: %s', szTalker, info.szTitle .. ' - ' .. info.szAuthor), function()
			D.DownloadData(info)
		end)
	elseif action == 'LOAD' then
		LIB.Sysmsg(_L('%s loaded %s', szTalker, info))
	end
end)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				OpenPanel       = D.OpenPanel,
				ClosePanel      = D.ClosePanel,
				IsOpened        = D.GetFrame,
				TogglePanel     = D.TogglePanel,
			},
		},
	},
}
MY_TeamMon_RR = LIB.GeneGlobalNS(settings)
end
