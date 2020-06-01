--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控远程数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	szLastKey = '',
	szLastVersion = '',
}
RegisterCustomData('Global/MY_TeamMon_RR.szLastKey')
RegisterCustomData('Global/MY_TeamMon_RR.szLastVersion')

local LANG = LIB.GetLang()
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_RR.ini'
local MY_TM_META_ROOT = MY_TeamMon.MY_TM_META_ROOT
local MY_TM_DATA_ROOT = MY_TeamMon.MY_TM_DATA_ROOT
local MY_TM_DATA_PASSPHRASE = '89g45ynbtldnsryu98rbny9ps7468hb6npyusiryuxoldg7lbn894bn678b496746'
local EMBEDDED_SUBSCRIBE_URL = 'https://dbm.j3cx.com/subscribe'

-- 陆服环境下，以下缩写均对等
-- tinymins
-- tinymins?master
-- tinymins/JX3_MY_DATA
-- tinymins/JX3_MY_DATA?master
-- tinymins@github
-- tinymins@github?master
-- tinymins@github:/MY_TeamMon/zhcn/meta.json
-- tinymins@github/JX3_MY_DATA
-- tinymins@github/JX3_MY_DATA:/MY_TeamMon/zhcn/meta.json
-- tinymins@github/JX3_MY_DATA?master:/MY_TeamMon/zhcn/meta.json
local GetRawURL, GetBlobURL, GetShortURL, GetAttachRawURL, GetAttachBlobURL
do
local PROVIDER_PARAMS = {
	github = {
		szRawURL = 'https://cdn.jsdelivr.net/gh/%s/%s@%s/%s',
		szRawURL_T = {
			'^https://cdn.jsdelivr.net/gh/([^/]+)/([^/]+)@([^/]+)/(.+)$',
			'^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.+)$',
		},
		szBlobURL = 'https://github.com/%s/%s/blob/%s/%s',
		szBlobURL_T = '^https://github%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$',
	},
	aliyun = {
		szRawURL = 'https://code.aliyun.com/%s/%s/raw/%s/%s',
		szRawURL_T = '^https://code%.aliyun%.com/([^/]+)/([^/]+)/raw/([^/]+)/(.+)$',
		szBlobURL = 'https://code.aliyun.com/%s/%s/blob/%s/%s',
		szBlobURL_T = '^https://code%.aliyun%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$',
	},
	gitee = {
		szRawURL = 'https://gitee.com/%s/%s/raw/%s/%s',
		szRawURL_T = '^https://gitee%.com/([^/]+)/([^/]+)/raw/([^/]+)/(.+)$',
		szBlobURL = 'https://gitee.com/%s/%s/blob/%s/%s',
		szBlobURL_T = '^https://gitee%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$',
	},
	jx3box = {
		bSimple = true,
		szRawURL = 'https://git.jx3box.com/feed?key=%s',
		szRawURL_T = '^https://git%.jx3box%.com/feed%?key%=(.+)$',
	},
}
local DEFAULT_PROVIDER = 'jx3box'
local DEFAULT_PROJECT = 'JX3_MY_DATA'
local DEFAULT_BRANCH = 'master'
local DEFAULT_PATH = 'MY_TeamMon/' .. LANG .. '/meta.json'
local function GetURL(szURL, szType)
	local szSimple, szUser, szProvider, szProject, szBranch, szPath, nPos
	if wfind(szURL, '://') then
		for k, p in pairs(PROVIDER_PARAMS) do
			if p.bSimple then
				if IsTable(p.szRawURL_T) then
					for _, s in ipairs(p.szRawURL_T) do
						szSimple = szURL:match(s)
						if szSimple then
							break
						end
					end
				elseif IsString(p.szRawURL_T) then
					szSimple = szURL:match(p.szRawURL_T)
				end
				if szSimple then
					szProvider = k
					break
				end
			else
				if IsTable(p.szRawURL_T) then
					for _, s in ipairs(p.szRawURL_T) do
						szUser, szProject, szBranch, szPath = szURL:match(s)
						if szUser then
							break
						end
					end
				elseif IsString(p.szRawURL_T) then
					szUser, szProject, szBranch, szPath = szURL:match(p.szRawURL_T)
				end
				if not szUser and p.szBlobURL_T then
					szUser, szProject, szBranch, szPath = szURL:match(p.szBlobURL_T)
				end
				if szUser then
					szProvider = k
					break
				end
			end
		end
	else
		szUser, szSimple = szURL, ''
		nPos = wfind(szUser, ':')
		if nPos then
			szPath = szUser:sub(nPos + 1):gsub('^/+', '')
			szUser = szUser:sub(1, nPos - 1)
			szSimple = ':' .. szPath .. szSimple
		else
			szPath = DEFAULT_PATH
		end
		nPos = wfind(szUser, '?')
		if nPos then
			szBranch = szUser:sub(nPos + 1)
			szUser = szUser:sub(1, nPos - 1)
			szSimple = '?' .. szBranch .. szSimple
		else
			szBranch = DEFAULT_BRANCH
		end
		nPos = wfind(szUser, '/')
		if nPos then
			szProject = szUser:sub(nPos + 1)
			szUser = szUser:sub(1, nPos - 1)
			szSimple = '/' .. szProject .. szSimple
		else
			szProject = DEFAULT_PROJECT
		end
		nPos = wfind(szUser, '@')
		if nPos then
			szProvider = szUser:sub(nPos + 1)
			if PROVIDER_PARAMS[szProvider] then
				szUser = szUser:sub(1, nPos - 1)
			else
				szProvider = DEFAULT_PROVIDER
			end
		else
			szProvider = DEFAULT_PROVIDER
		end
		szSimple = szUser .. szSimple
		szSimple = LIB.UrlEncode(AnsiToUTF8(szSimple))
		szUser = LIB.UrlEncode(AnsiToUTF8(szUser))
		szProject = LIB.UrlEncode(AnsiToUTF8(szProject))
		szBranch = LIB.UrlEncode(AnsiToUTF8(szBranch))
	end
	local provider = szProvider and PROVIDER_PARAMS[szProvider]
	if not provider then
		return
	end
	if szType == 'RAW' then
		if provider.bSimple then
			return provider.szRawURL:format(szSimple)
		end
		return provider.szRawURL:format(szUser, szProject, szBranch, szPath)
	end
	if szType == 'BLOB' then
		if not provider.szBlobURL then
			return
		end
		return provider.szBlobURL:format(szUser, szProject, szBranch, szPath)
	end
	if szType == 'SHORT' then
		szSimple = UTF8ToAnsi(LIB.UrlDecode(szSimple))
		szUser = UTF8ToAnsi(LIB.UrlDecode(szUser))
		szProject = UTF8ToAnsi(LIB.UrlDecode(szProject))
		szBranch = UTF8ToAnsi(LIB.UrlDecode(szBranch))
		if provider.bSimple then
			if szProvider ~= DEFAULT_PROVIDER then
				szSimple = szSimple .. '@' .. szProvider
			end
			return szSimple
		end
		if szProvider ~= DEFAULT_PROVIDER then
			szUser = szUser .. '@' .. szProvider
		end
		if szProject ~= DEFAULT_PROJECT then
			szUser = szUser .. '/' .. szProject
		end
		if szBranch ~= DEFAULT_BRANCH then
			szUser = szUser .. '?' .. szBranch
		end
		if szPath ~= DEFAULT_PATH then
			szUser = szUser .. ':' .. szPath
		end
		return szUser
	end
end
function GetRawURL(szURL)
	return GetURL(szURL, 'RAW')
end
function GetBlobURL(szURL)
	return GetURL(szURL, 'BLOB')
end
function GetShortURL(szURL)
	return GetURL(szURL, 'SHORT')
end
function GetAttachRawURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if LIB.IsURL(szAttach) then
		return szAttach
	end
	local szURL = GetRawURL(szURL)
	if not szURL then
		return
	end
	return LIB.NormalizePath(LIB.ConcatPath(LIB.GetParentPath(szURL), szAttach))
end
function GetAttachBlobURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if LIB.IsURL(szAttach) then
		return szAttach
	end
	local szURL = GetBlobURL(szURL)
	if not szURL then
		return
	end
	return LIB.NormalizePath(LIB.ConcatPath(LIB.GetParentPath(szURL), szAttach))
end
end

local META_EMBEDDED_LIST = {{
	szKey = 'DEFAULT',
	szAuthor = _L['Default'],
	szTitle = _L['Default monitor data'],
	szDataUrl = './data.jx3dat',
	szURL = GetRawURL('tinymins@github'),
	szAboutURL = GetBlobURL('tinymins@github:MY_TeamMon/README.md'),
}}
local META_TEMPLATE = {
	szURL = '',
	szDataURL = './data.jx3dat',
	szKey = '',
	szVersion = '',
	szAuthor = '',
	szTitle = '',
	szAboutURL = '',
}
local META_SEL_INFO, DATA_DOWNLOADER
local META_DOWNLOADING_KEY = {}

local function SafeCall(f, ...)
	if not f then
		return
	end
	return Call(f, ...)
end

function D.OpenPanel()
	Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_RR')
end

function D.ClosePanel()
	Wnd.CloseWindow('MY_TeamMon_RR')
end

function D.LoadMetaList()
	return LIB.LoadLUAData({'userdata/TeamMon/MetaList.jx3dat', PATH_TYPE.GLOBAL}) or {}
end

function D.SaveMetaList(aMeta)
	LIB.SaveLUAData({'userdata/TeamMon/MetaList.jx3dat', PATH_TYPE.GLOBAL}, aMeta)
	FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
end

function D.AddMeta(info)
	local aMeta = D.LoadMetaList()
	for _, p in spairs(aMeta, META_EMBEDDED_LIST) do
		if p.szURL == info.szURL then
			return
		end
	end
	insert(aMeta, info)
	D.SaveMetaList(aMeta)
end

function D.DownloadMeta(info, onSuccess, onError)
	local szURL = GetRawURL(info.szURL) or info.szURL
	if info.szKey then
		META_DOWNLOADING_KEY[info.szKey] = true
		FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
	end
	LIB.Ajax({
		driver = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res, err = LIB.JsonDecode(szHTML)
			if not res then
				return SafeCall(onError, _L['ERR: Info content is illegal!'] .. '\n\n' .. err)
			end
			local info = {
				szURL = szURL,
				szDataURL = GetAttachRawURL(res.data_url or './data.jx3dat', szURL),
				szKey = info.szKey or LIB.GetUUID(),
				szAuthor = res.author or '',
				szTitle = res.name or '',
				szAboutURL = GetAttachBlobURL(res.about or '', szURL),
				szVersion = res.version or '',
			}
			local aMeta = D.LoadMetaList()
			for i, p in ipairs(aMeta) do
				if p.szKey == info.szKey then
					aMeta[i] = info
				end
			end
			D.SaveMetaList(aMeta)
			SafeCall(onSuccess, info)
		end,
		error = function(html, status)
			if status == 404 then
				return SafeCall(onError, _L['ERR404: Meta address not found!'])
			end
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_TeamMon_RR'], 'ERROR Get Meta: ' .. status .. '\n' .. UTF8ToAnsi(html), DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			SafeCall(onError)
		end,
		complete = function()
			if info.szKey then
				META_DOWNLOADING_KEY[info.szKey] = nil
			end
			FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
		end,
	})
end

function D.DownloadAllMeta()
	for _, info in ipairs(D.LoadMetaList()) do
		D.DownloadMeta(info)
	end
end

function D.RequestMetaEmbedded()
	LIB.Ajax({
		driver = 'auto', method = 'auto',
		url = EMBEDDED_SUBSCRIBE_URL,
		charset = 'utf8',
		success = function(szHTML)
			local res = LIB.JsonDecode(szHTML)
			if not IsTable(res) then
				return
			end
			local aMeta = {}
			for _, info in ipairs(res) do
				info = LIB.FormatDataStructure(info, META_TEMPLATE)
				info.bEmbedded = true
				insert(aMeta, info)
			end
			META_EMBEDDED_LIST = aMeta
			FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
		end,
	})
end

function D.LoadConfigureFile(szFile, info)
	MY_TeamMon_UI.OpenImportPanel(szFile, info.szTitle .. ' - ' .. info.szAuthor, function()
		local me = GetClientPlayer()
		if me.IsInParty() then
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_RR', {'LOAD', info.szTitle}, true)
		end
		O.szLastKey = info.szKey
		O.szLastVersion = info.szVersion
		FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
	end)
end

function D.DownloadData(info)
	D.DownloadMeta(info, function(info)
		local szUUID = 'Remote-' .. info.szDataURL:gsub('[^a-zA-Z0-9%%]', '_') .. '-' .. GetStringCRC(info.szURL) .. '-' .. GetStringCRC(info.szVersion)
		local LUA_CONFIG = { passphrase = MY_TM_DATA_PASSPHRASE, crc = true, compress = true }
		local p = LIB.LoadLUAData(MY_TM_META_ROOT .. szUUID .. '.jx3dat', LUA_CONFIG)
		if p and p.szVersion == info.szVersion and IsLocalFileExist(MY_TM_DATA_ROOT .. szUUID .. '.jx3dat') then
			return D.LoadConfigureFile(szUUID .. '.jx3dat', info)
		end
		if not (DATA_DOWNLOADER and DATA_DOWNLOADER:IsValid()) then
			return LIB.Topmsg(_L['Downloader is not ready!'])
		end
		if DATA_DOWNLOADER.szDownloadingKey then
			return LIB.Topmsg(_L['Dowloading in progress, please wait...'])
		end
		DATA_DOWNLOADER.szDownloadingKey = info.szKey
		DATA_DOWNLOADER.FromTextureFile = function(_, szPath)
			local data = LIB.LoadLUAData(szPath, LUA_CONFIG)
			if data then
				local szFile = szUUID .. '.jx3dat'
				LIB.SaveLUAData(MY_TM_META_ROOT .. szUUID .. '.jx3dat', info, LUA_CONFIG)
				LIB.SaveLUAData(MY_TM_DATA_ROOT .. szFile, data, LUA_CONFIG)
				D.LoadConfigureFile(szFile, info)
			else
				LIB.Topmsg(_L('Decode %s failed!', info.szTitle))
			end
			DATA_DOWNLOADER.szDownloadingKey = nil
			FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
		end
		DATA_DOWNLOADER:FromRemoteFile(info.szDataURL)
		FireUIEvent('MY_TM_RR_META_LIST_UPDATE')
	end, function(szErrmsg)
		if szErrmsg then
			LIB.Alert(szErrmsg)
		end
	end)
end

function D.ShareMetaToRaid(info, bSure)
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return LIB.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
	end
	if not LIB.IsInParty() then
		return LIB.Alert(_L['You are not in the team.'])
	end
	if not LIB.IsLeader() and not LIB.IsDebugClient(true) then
		return LIB.Alert(_L['You are not team leader.'])
	end
	if not bSure then
		LIB.Confirm(_L['Confirm?'], function()
			D.ShareMetaToRaid(info, true)
		end)
		return
	end
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_RR', {'SYNC', META_SEL_INFO})
end

function D.UpdateList(frame)
	if not frame and frame:IsValid() then
		return
	end
	local aMeta, tMetaID = D.LoadMetaList(), {}
	local container = frame:Lookup('PageSet_Menu/Page_Fav/WndScroll_Fav/WndContainer_Fav_List')
	container:Clear()
	for _, p in spairs(aMeta, META_EMBEDDED_LIST) do
		if not tMetaID[p.szKey] then
			local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
			wnd:Lookup('', 'Text_Item_Author'):SetText(LIB.ReplaceSensitiveWord(p.szAuthor))
			wnd:Lookup('', 'Text_Item_Title'):SetText(LIB.ReplaceSensitiveWord(p.szTitle))
			wnd:Lookup('Btn_Info'):SetVisible(not IsEmpty(p.szAboutURL))
			wnd:Lookup('Btn_Info', 'Text_Info'):SetText(_L['See details'])
			wnd:Lookup('Btn_Download', 'Text_Download'):SetText(
				(META_DOWNLOADING_KEY[p.szKey] and _L['Fetching...'])
				or (DATA_DOWNLOADER and DATA_DOWNLOADER.szDownloadingKey == p.szKey and _L['Downloading...'])
				or (p.szKey == O.szLastKey and (p.szVersion == O.szLastVersion and _L['Last select'] or _L['Can update']))
				or _L['Download']
			)
			wnd:Lookup('Btn_Download'):Enable(not META_DOWNLOADING_KEY[p.szKey] and (not DATA_DOWNLOADER or DATA_DOWNLOADER.szDownloadingKey ~= p.szKey))
			wnd.info = p
			tMetaID[p.szKey] = true
		end
	end
	container:FormatAllContentPos()
end

function D.OnFrameCreate()
	DATA_DOWNLOADER = this:Lookup('', 'Image_Downloader')
	this:Lookup('Btn_SyncTeam', 'Text_SyncTeam'):SetText(_L['Sync team'])
	this:Lookup('Btn_CheckUpdate', 'Text_CheckUpdate'):SetText(_L['Check update'])
	this:Lookup('Btn_AddUrl', 'Text_AddUrl'):SetText(_L['Add url'])
	this:Lookup('Btn_RemoveUrl', 'Text_RemoveUrl'):SetText(_L['Remove url'])
	this:Lookup('Btn_ExportUrl', 'Text_ExportUrl'):SetText(_L['Export meta url'])
	this:Lookup('PageSet_Menu/Page_Fav', 'Text_Fav_Break1'):SetText(_L['Author'])
	this:Lookup('PageSet_Menu/Page_Fav', 'Text_Fav_Break2'):SetText(_L['Title'])
	this:Lookup('PageSet_Menu/WndCheck_Fav', 'Text_FavCheck'):SetText(_L['Data download'])
	D.UpdateList(this)
	this:RegisterEvent('MY_TM_RR_META_LIST_UPDATE')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	if not O.bAutoDownloadAll then
		D.DownloadAllMeta()
		O.bAutoDownloadAll = true
	end
	D.RequestMetaEmbedded()
end

function D.OnEvent(event)
	if event == 'MY_TM_RR_META_LIST_UPDATE' then
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
		GetUserInput(_L['Please input meta address:'], function(szText)
			local aURL = LIB.SplitString(szText, ';')
			local nPending = 0
			local aErrmsg = {}
			local function ProcessQueue()
				nPending = nPending + 1
				local szURL = aURL[nPending]
				if not szURL then
					if #aErrmsg > 0 then
						LIB.Alert(concat(aErrmsg, '\n'))
					end
					return
				end
				D.DownloadMeta({ szURL = szURL }, function(info)
					D.AddMeta(info)
					D.UpdateList(frame)
					ProcessQueue()
				end, function(szErrmsg)
					if szErrmsg then
						insert(aErrmsg, szErrmsg)
					end
					ProcessQueue()
				end)
			end
			ProcessQueue()
		end)
	elseif name == 'Btn_RemoveUrl' then
		if not META_SEL_INFO then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		if META_SEL_INFO.bEmbedded then
			return MY.Topmsg(_L['Embedded dataset cannot be removed!'])
		end
		LIB.Confirm(_L['Confirm?'], function()
			local aMeta = D.LoadMetaList()
			for i, p in ipairs_r(aMeta) do
				if p.szKey == META_SEL_INFO.szKey then
					remove(aMeta, i)
				end
			end
			D.SaveMetaList(aMeta)
			D.UpdateList(frame)
		end)
	elseif name == 'Btn_ExportUrl' then
		local aMetaURL = {}
		for _, info in ipairs(D.LoadMetaList()) do
			insert(aMetaURL, GetShortURL(info.szURL) or GetRawURL(info.szURL))
		end
		UI.OpenTextEditor(concat(aMetaURL, ';'))
	elseif name == 'Btn_Info' then
		LIB.OpenBrowser(this:GetParent().info.szAboutURL)
	elseif name == 'Btn_SyncTeam' then
		if not META_SEL_INFO then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		D.ShareMetaToRaid(META_SEL_INFO)
	elseif name == 'Btn_CheckUpdate' then
		D.DownloadAllMeta()
		D.RequestMetaEmbedded()
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
		META_SEL_INFO = wnd.info
		wnd:Lookup('', 'Image_Item_Sel'):Show()
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local t = {{
			szOption = _L['Copy meta url'],
			fnAction = function()
				UI.OpenTextEditor(wnd.info.szURL)
			end,
		}}
		local szShortURL = GetShortURL(wnd.info.szURL)
		if szShortURL then
			insert(t, {
				szOption = _L['Copy short meta url'],
				fnAction = function()
					UI.OpenTextEditor(szShortURL)
				end,
			})
		end
		insert(t, {
			szOption = _L['Sync team'],
			fnAction = function()
				D.ShareMetaToRaid(wnd.info)
			end,
		})
		PopupMenu(t)
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local szTip = _L('Meta URL: %s', wnd.info.szURL)
		local szShortURL = GetShortURL(wnd.info.szURL)
		if szShortURL then
			szTip = szTip .. _L('(Short URL: %s)', szShortURL)
		end
		if IsCtrlKeyDown() then
			szTip = szTip .. '\n' .. EncodeLUAData(wnd.info, '  ')
		end
		LIB.OutputTip(this, szTip)
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_Item' then
		HideTip()
	end
end

LIB.RegisterBgMsg('MY_TeamMon_RR', function(_, data, _, _, szTalker, _)
	local action, info = data[1], data[2]
	if action == 'SYNC' then
		info = LIB.FormatDataStructure(info, META_TEMPLATE)
		if not IsEmpty(info.szURL) and not IsEmpty(info.szTitle) then
			LIB.Confirm(_L('%s request download:', szTalker) .. '\n'
				.. _L('Title: %s', info.szTitle) .. '\n'
				.. _L('Author: %s', info.szAuthor) .. '\n'
				.. _L('Meta URL: %s', info.szURL), function()
					D.OpenPanel()
					D.AddMeta(info)
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
				szLastVersion = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				szLastKey = true,
				szLastVersion = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_RR = LIB.GeneGlobalNS(settings)
end
