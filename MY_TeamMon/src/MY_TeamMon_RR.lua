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
local O = {
	szLastKey = '',
}
RegisterCustomData('Global/MY_TeamMon_RR.szLastKey')

local LANG = LIB.GetLang()
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_RR.ini'
local MY_TM_META_ROOT = MY_TeamMon.MY_TM_META_ROOT
local MY_TM_DATA_ROOT = MY_TeamMon.MY_TM_DATA_ROOT
local MY_TM_DATA_PASSPHRASE = '89g45ynbtldnsryu98rbny9ps7468hb6npyusiryuxoldg7lbn894bn678b496746'
local RSS_DEFAULT = {{
	szKey = 'DEFAULT',
	szAuthor = _L['Default'],
	szTitle = _L['Default monitor data'],
	szURL = 'https://code.aliyun.com/tinymins/JX3_MY_DATA/raw/master/MY_TeamMon/' .. LANG .. '/meta.json',
	szDataUrl = './data.jx3dat',
	szAbout = 'https://code.aliyun.com/tinymins/JX3_MY_DATA/blob/master/MY_TeamMon/README.md',
}}
local RSS_TEMPLATE = {
	szURL = '',
	szDataURL = './data.jx3dat',
	szKey = '',
	szAuthor = '',
	szTitle = '',
	szAbout = '',
	szVersion = '',
}
local RSS_SEL_INFO, RSS_DOWNLOADER

function D.OpenPanel()
	Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_RR')
end

function D.ClosePanel()
	Wnd.CloseWindow('MY_TeamMon_RR')
end

function D.LoadRssList()
	return LIB.LoadLUAData({'userdata/TeamMon/Rss.jx3dat', PATH_TYPE.GLOBAL}) or {}
end

function D.SaveRssList(aRss)
	LIB.SaveLUAData({'userdata/TeamMon/Rss.jx3dat', PATH_TYPE.GLOBAL}, aRss)
	FireUIEvent('MY_TM_RR_RSS_UPDATE')
end

function D.AddRssMeta(info)
	local aRss = D.LoadRssList()
	for _, p in spairs(RSS_DEFAULT, aRss) do
		if p.szURL == info.szURL then
			return
		end
	end
	insert(aRss, info)
	D.SaveRssList(aRss)
end

function D.DownloadRssMeta(info, onSuccess, onError)
	local szURL = info.szURL
	if not wfind(szURL, '.') and not wfind(szURL, '/') then
		szURL = 'https://code.aliyun.com/'
			.. szURL .. '/JX3_MY_DATA/raw/master/MY_TeamMon/'
			.. LANG .. '/meta.json'
		-- szURL = 'https://dev.tencent.com/u/'
		-- 	.. szURL .. '/p/JX3_MY_DATA/git/raw/master/MY_TeamMon/'
		-- 	.. LANG .. '/meta.json'
		-- szURL = 'https://gitee.com/'
		-- 	.. szURL .. '/JX3_MY_DATA/raw/master/MY_TeamMon/'
		-- 	.. LANG .. '/meta.json'
	end
	LIB.Ajax({
		url = szURL,
		success = function(szHTML)
			local szJson = UTF8ToAnsi(szHTML)
			local res = LIB.JsonDecode(szJson)
			if not res then
				return onError(_L['ERR: Info content is illegal!'])
			end
			local szDataURL = res.data_url or './data.jx3dat'
			if szDataURL:sub(1, 2) == './' then
				szDataURL = szDataURL:sub(3)
				szDataURL = szURL:gsub('/[^/]*$', '/data.jx3dat')
			end
			local info = {
				szURL = szURL,
				szDataURL = szDataURL,
				szKey = info.szKey or LIB.GetUUID(),
				szAuthor = res.author or '',
				szTitle = res.name or '',
				szAbout = res.about or '',
				szVersion = res.version or '',
			}
			local aRss = D.LoadRssList()
			for i, p in ipairs(aRss) do
				if p.szKey == info.szKey then
					aRss[i] = info
				end
			end
			D.SaveRssList(aRss)
			onSuccess(info)
		end,
		error = function(html, status)
			if status == 404 then
				return onError(_L['ERR404: Rss is empty!'])
			end
			--[[DEBUG BEGIN]]
			LIB.Debug('ERROR MY_TeamMon_RR Get Meta: ' .. status .. '\n' .. UTF8ToAnsi(html))
			--[[DEBUG END]]
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
		O.szLastKey = info.szKey
		FireUIEvent('MY_TM_RR_RSS_UPDATE')
	end)
end

function D.DownloadData(info)
	D.DownloadRssMeta(info, function(info)
		local szUUID = 'Remote-' .. MD5(info.szURL)
		local LUA_CONFIG = { passphrase = MY_TM_DATA_PASSPHRASE }
		local p = LIB.LoadLUAData(MY_TM_META_ROOT .. szUUID .. '.jx3dat', LUA_CONFIG)
		if p and p.szVersion == info.szVersion
		and IsLocalFileExist(MY_TM_DATA_ROOT .. szUUID .. '.jx3dat') then
			return D.LoadConfigureFile(szUUID .. '.jx3dat', info)
		end
		if not RSS_DOWNLOADER and RSS_DOWNLOADER:IsValid() then
			return LIB.Topmsg(_L['Downloader is not ready!'])
		end
		if RSS_DOWNLOADER.szDownloadingKey then
			return LIB.Topmsg(_L['Dowloading in progress, please wait...'])
		end
		RSS_DOWNLOADER.szDownloadingKey = info.szKey
		RSS_DOWNLOADER.FromTextureFile = function(_, szPath)
			local data = LIB.LoadLUAData(szPath, LUA_CONFIG)
			if data then
				local szFile = szUUID .. '.jx3dat'
				LIB.SaveLUAData(MY_TM_META_ROOT .. szUUID .. '.jx3dat', info, LUA_CONFIG)
				LIB.SaveLUAData(MY_TM_DATA_ROOT .. szFile, data, LUA_CONFIG)
				D.LoadConfigureFile(szFile, info)
			else
				LIB.Topmsg(_L('Decode %s failed!', info.szTitle))
			end
			RSS_DOWNLOADER.szDownloadingKey = nil
			FireUIEvent('MY_TM_RR_RSS_UPDATE')
		end
		RSS_DOWNLOADER:FromRemoteFile(info.szDataURL)
		FireUIEvent('MY_TM_RR_RSS_UPDATE')
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
	local aRss = D.LoadRssList()
	local container = frame:Lookup('PageSet_Menu/Page_FileDownload/WndScroll_FileDownload/WndContainer_FileDownload_List')
	container:Clear()
	for _, p in spairs(RSS_DEFAULT, aRss) do
		local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
		wnd:Lookup('', 'Text_Item_Author'):SetText(p.szAuthor)
		wnd:Lookup('', 'Text_Item_Title'):SetText(p.szTitle)
		wnd:Lookup('Btn_Info'):SetVisible(not IsEmpty(p.szAbout))
		wnd:Lookup('Btn_Info', 'Text_Info'):SetText(_L['See details'])
		wnd:Lookup('Btn_Download', 'Text_Download'):SetText(
			(RSS_DOWNLOADER and RSS_DOWNLOADER.szDownloadingKey == p.szKey and _L['Downloading...'])
			or (p.szKey == O.szLastKey and _L['Last select'])
			or _L['Download']
		)
		wnd:Lookup('Btn_Download'):Enable(not RSS_DOWNLOADER or RSS_DOWNLOADER.szDownloadingKey ~= p.szKey)
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
	this:RegisterEvent('MY_TM_RR_RSS_UPDATE')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
end

function D.OnEvent(event)
	if event == 'MY_TM_RR_RSS_UPDATE' then
		D.UpdateList(this)
	end
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
			D.DownloadRssMeta({ szURL = szURL }, function(info)
				D.AddRssMeta(info)
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
		if RSS_SEL_INFO.szKey == 'DEFAULT' then
			return MY.Topmsg(_L['Default dataset cannot be removed!'])
		end
		LIB.Confirm(_L['Confirm?'], function()
			local aRss = D.LoadRssList()
			for i, p in ipairs_r(aRss) do
				if p.szKey == RSS_SEL_INFO.szKey then
					remove(aRss, i)
				end
			end
			D.SaveRssList(aRss)
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
		info = LIB.FormatDataStructure(info, RSS_TEMPLATE)
		if not IsEmpty(info.szURL) and not IsEmpty(info.szTitle) then
			LIB.Confirm(_L('%s request download: %s', szTalker, info.szTitle .. ' - ' .. info.szAuthor), function()
				D.AddRssMeta(info)
				D.DownloadData(info)
			end)
		end
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
		{
			fields = {
				szLastKey = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				szLastKey = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_RR = LIB.GeneGlobalNS(settings)
end
