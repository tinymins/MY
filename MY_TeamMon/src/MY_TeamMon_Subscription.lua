--------------------------------------------------------------------------------
-- v is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控订阅数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_Subscription'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^15.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = X.SetmetaLazyload({}, {
	PW = function() return X.SECRET['FILE::TEAM_MON_DATA_PW'] end,
})
local O = {}

local EDITION = X.ENVIRONMENT.GAME_EDITION
local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_Subscription.ini'
local MY_TM_REMOTE_DATA_ROOT = MY_TeamMon.MY_TM_REMOTE_DATA_ROOT
local META_DOWNLOADING, DATA_DOWNLOADING = {}, {}

local Schema = X.Schema
local META_LUA_SCHEMA = X.Schema.Record({
	szURL = X.Schema.Optional(X.Schema.String),
	szAboutURL = X.Schema.Optional(X.Schema.String),
	szAuthor = X.Schema.String,
	szDataURL = X.Schema.String,
	szKey = X.Schema.Optional(X.Schema.String),
	szTitle = X.Schema.String,
	szUpdateTime = X.Schema.Optional(X.Schema.String),
	szVersion = X.Schema.String,
}, true)
local META_JSON_SCHEMA = X.Schema.Record({
	about = X.Schema.Optional(X.Schema.String),
	author = X.Schema.String,
	data_url = X.Schema.String,
	key = X.Schema.Optional(X.Schema.String),
	name = X.Schema.String,
	update = X.Schema.Optional(X.Schema.String),
	version = X.Schema.String,
}, true)
local META_LIST_JSON_SCHEMA = X.Schema.Record({
	data = X.Schema.Collection(META_JSON_SCHEMA),
	page = X.Schema.Record({
		index = X.Schema.Number,
		size = X.Schema.Number,
		total = X.Schema.Number,
	}, true),
}, true)

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
		szRawURL = 'https://pull.j3cx.com/api/dbm/feed?key=%s',
		szRawURL_T = '^https://pull%.j3cx%.com/api/dbm/feed%?key%=(.+)$',
	},
}
local DEFAULT_PROVIDER = 'jx3box'
local DEFAULT_PROJECT = 'JX3_MY_DATA'
local DEFAULT_BRANCH = 'master'
local DEFAULT_PATH = 'MY_TeamMon/' .. EDITION .. '/meta.json'
local function GetURL(szURL, szType)
	local szSimple, szUser, szProvider, szProject, szBranch, szPath, nPos
	if X.StringFindW(szURL, '://') then
		for k, p in pairs(PROVIDER_PARAMS) do
			if p.bSimple then
				if X.IsTable(p.szRawURL_T) then
					for _, s in ipairs(p.szRawURL_T) do
						szSimple = szURL:match(s)
						if szSimple then
							break
						end
					end
				elseif X.IsString(p.szRawURL_T) then
					szSimple = szURL:match(p.szRawURL_T)
				end
				if szSimple then
					szProvider = k
					break
				end
			else
				if X.IsTable(p.szRawURL_T) then
					for _, s in ipairs(p.szRawURL_T) do
						szUser, szProject, szBranch, szPath = szURL:match(s)
						if szUser then
							break
						end
					end
				elseif X.IsString(p.szRawURL_T) then
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
		nPos = X.StringFindW(szUser, ':')
		if nPos then
			szPath = szUser:sub(nPos + 1):gsub('^/+', '')
			szUser = szUser:sub(1, nPos - 1)
			szSimple = ':' .. szPath .. szSimple
		else
			szPath = DEFAULT_PATH
		end
		nPos = X.StringFindW(szUser, '?')
		if nPos then
			szBranch = szUser:sub(nPos + 1)
			szUser = szUser:sub(1, nPos - 1)
			szSimple = '?' .. szBranch .. szSimple
		else
			szBranch = DEFAULT_BRANCH
		end
		nPos = X.StringFindW(szUser, '/')
		if nPos then
			szProject = szUser:sub(nPos + 1)
			szUser = szUser:sub(1, nPos - 1)
			szSimple = '/' .. szProject .. szSimple
		else
			szProject = DEFAULT_PROJECT
		end
		nPos = X.StringFindW(szUser, '@')
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
		szSimple = X.EncodeURIComponent(AnsiToUTF8(szSimple))
		szUser = X.EncodeURIComponent(AnsiToUTF8(szUser))
		szProject = X.EncodeURIComponent(AnsiToUTF8(szProject))
		szBranch = X.EncodeURIComponent(AnsiToUTF8(szBranch))
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
		szSimple = UTF8ToAnsi(X.DecodeURIComponent(szSimple))
		szUser = UTF8ToAnsi(X.DecodeURIComponent(szUser))
		szProject = UTF8ToAnsi(X.DecodeURIComponent(szProject))
		szBranch = UTF8ToAnsi(X.DecodeURIComponent(szBranch))
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
-- 将地址转化为 GIT 仓库浏览地址
function GetRawURL(szURL)
	return GetURL(szURL, 'RAW')
end
-- 将地址转化为 GIT 仓库源文件下载地址
function GetBlobURL(szURL)
	return GetURL(szURL, 'BLOB')
end
-- 将地址转化为短链接
function GetShortURL(szURL)
	return GetURL(szURL, 'SHORT')
end
-- 根据描述文件中的相对文件地址 计算绝对 GIT 仓库浏览地址
function GetAttachRawURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if X.IsURL(szAttach) then
		return szAttach
	end
	local szURL = GetRawURL(szURL)
	if not szURL then
		return
	end
	return X.NormalizePath(X.ConcatPath(X.GetParentPath(szURL), szAttach))
end
-- 根据描述文件中的相对文件地址 计算绝对 GIT 仓库源文件下载地址
function GetAttachBlobURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if X.IsURL(szAttach) then
		return szAttach
	end
	local szURL = GetBlobURL(szURL)
	if not szURL then
		return
	end
	return X.NormalizePath(X.ConcatPath(X.GetParentPath(szURL), szAttach))
end
end

local REPO_META_PAGE = {
	nIndex = 1,
	nSize = 30,
	nTotal = 1,
}
local REPO_META_LIST = {
	szKey = 'DEFAULT',
	szAuthor = _L['Default'],
	szTitle = _L['Default monitor data'],
	szUpdateTime = '',
	szDataUrl = './data.jx3dat',
	szURL = GetRawURL('tinymins@github'),
	szAboutURL = GetBlobURL('tinymins@github:MY_TeamMon/README.md'),
}

function D.GetFrame()
	return Station.SearchFrame('MY_TeamMon_Subscription')
end

function D.OpenPanel()
	local frame = D.GetFrame() or Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_Subscription')
	frame:Show()
	frame:BringToTop()
	return frame
end

function D.ClosePanel()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	frame:Hide()
end

function D.LoadFavMetaInfoList()
	return X.LoadLUAData({'userdata/team_mon/metalist.jx3dat', X.PATH_TYPE.GLOBAL}) or {}
end

function D.SaveFavMetaInfoList(aMetaInfo)
	X.SaveLUAData({'userdata/team_mon/metalist.jx3dat', X.PATH_TYPE.GLOBAL}, aMetaInfo)
	FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
end

function D.AddFavMetaInfo(info, szReplaceKey)
	local aMetaInfo = D.LoadFavMetaInfoList()
	local nIndex
	if szReplaceKey then
		for i, p in X.ipairs_r(aMetaInfo) do
			if p.szKey == szReplaceKey then
				table.remove(aMetaInfo, i)
				nIndex = i
			end
		end
	end
	for i, p in X.ipairs_r(aMetaInfo) do
		if p.szKey == info.szKey then
			table.remove(aMetaInfo, i)
			nIndex = i
		end
	end
	if nIndex then
		table.insert(aMetaInfo, nIndex, info)
	else
		table.insert(aMetaInfo, info)
	end
	D.SaveFavMetaInfoList(aMetaInfo)
	FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
end

-- 格式化描述内容
-- 进入该函数的数据必须为安全数据，即已经过 Schema 检测的数据。
function D.FormatMetaInfo(res)
	local szURL = res.szURL or res.url
	local info = {
		szURL = szURL,
		szDataURL = GetAttachRawURL(res.szDataURL or res.data_url or './data.jx3dat', szURL),
		szKey = GetShortURL(szURL) or ('H' .. GetStringCRC(szURL)),
		szAuthor = res.szAuthor or res.author or '',
		szTitle = res.szTitle or res.name or '',
		szUpdateTime = res.szUpdateTime or res.update or '',
		szAboutURL = GetAttachBlobURL(res.szAboutURL or res.about or '', szURL),
		szVersion = res.szVersion or res.version or '',
	}
	if X.IsEmpty(info.szURL) or X.IsEmpty(info.szTitle) or X.IsEmpty(info.szVersion) then
		return
	end
	return info
end

-- 根据描述文件地址，获取描述内容
function D.FetchMetaInfo(szURL, onSuccess, onError)
	local szURL = GetRawURL(szURL) or szURL
	X.Ajax({
		url = szURL,
		success = function(szHTML)
			local res, err = X.DecodeJSON(szHTML)
			if not res then
				X.SafeCall(onError, _L['ERR: Decode info content as json failed!'])
				return
			end
			local errs = X.Schema.CheckSchema(res, META_JSON_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				X.SafeCall(onError, _L['ERR: Info content is illegal!'] .. '\n\n' .. table.concat(aErrmsgs, '\n'))
				return
			end
			res.url = szURL
			local info = D.FormatMetaInfo(res)
			if not info then
				X.SafeCall(onError, _L['ERR: Info content is illegal!'])
				return
			end
			X.SafeCall(onSuccess, info)
		end,
		error = function(html, status)
			if status == 404 then
				X.SafeCall(onError, _L['ERR404: MetaInfo address not found!'])
				return
			end
			--[[#DEBUG BEGIN]]
			X.Debug(_L['MY_TeamMon_Subscription'], 'ERROR Get MetaInfo: ' .. X.EncodeLUAData(status) .. '\n' .. (X.ConvertToAnsi(html) or ''), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			X.SafeCall(onError)
		end,
	})
end

function D.FetchFavMetaInfoList()
	for _, info in ipairs(D.LoadFavMetaInfoList()) do
		META_DOWNLOADING[info.szKey] = true
		D.FetchMetaInfo(
			info.szURL,
			function(res)
				META_DOWNLOADING[info.szKey] = nil
				D.AddFavMetaInfo(res, info.szKey)
			end,
			function(err)
				META_DOWNLOADING[info.szKey] = nil
				X.Debug(
					_L['MY_TeamMon_Subscription'],
					err ..'\n' ..  info.szURL,
					X.DEBUG_LEVEL.WARNING)
				FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
			end)
	end
	FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
end

function D.FetchRepoMetaInfoList(nPage)
	X.Ajax({
		url = 'https://pull.j3cx.com/api/dbm/subscribe/all',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			page = nPage or REPO_META_PAGE.nIndex,
			pageSize = 15,
		},
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			local errs = X.Schema.CheckSchema(res, META_LIST_JSON_SCHEMA)
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, i .. '. ' .. err.message)
				end
				return X.Debug(_L['MY_TeamMon_Subscription'], _L['Fetch repo meta list failed.'] .. '\n' .. table.concat(aErrmsgs, '\n'), X.DEBUG_LEVEL.WARNING)
			end
			local tPage = {
				nIndex = res.page.index,
				nSize = res.page.size,
				nTotal = res.page.total,
			}
			local aMetaInfo = {}
			for _, info in ipairs(res.data) do
				info.url = 'https://pull.j3cx.com/api/dbm/feed?'
					.. X.EncodeQuerystring(X.ConvertToUTF8({
						l = X.ENVIRONMENT.GAME_LANG,
						L = X.ENVIRONMENT.GAME_EDITION,
						key = info.key,
					}))
				info = D.FormatMetaInfo(info)
				if info then
					info.bEmbedded = true
					table.insert(aMetaInfo, info)
				end
			end
			REPO_META_PAGE = tPage
			REPO_META_LIST = aMetaInfo
			FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
		end,
	})
end

function D.CheckUpdate()
	local szLastURL = MY_TeamMon.GetUserConfig('RR.LastURL')
	local bDataNotModified = MY_TeamMon.GetUserConfig('RR.DataNotModified')
	local aType = MY_TeamMon.GetUserConfig('RR.LastType')
	if X.IsEmpty(szLastURL)
	or not bDataNotModified
	or not X.IsTable(aType) or X.IsEmpty(aType) then
		return
	end
	local function ParseVersion(szVersion)
		if X.IsString(szVersion) then
			local nPos = X.StringFindW(szVersion, '.')
			if nPos then
				local szMajorVersion = szVersion:sub(1, nPos)
				local szMinorVersion = szVersion:sub(nPos + 1)
				return szMajorVersion, szMinorVersion
			end
			return szVersion, ''
		end
		return '', ''
	end
	D.FetchMetaInfo(
		szLastURL,
		function(info)
			local szPrimaryVersion = ParseVersion(info.szVersion)
			local szLastPrimaryVersion = ParseVersion(MY_TeamMon.GetUserConfig('RR.LastVersion'))
			if X.IsEmpty(szPrimaryVersion) or szPrimaryVersion == szLastPrimaryVersion then
				return
			end
			--[[#DEBUG BEGIN]]
			local nTime = GetTime()
			X.Debug(
				'MY_TeamMon_Subscription',
				'Hash matched, auto update confirmed: ' .. szLastPrimaryVersion
					.. ' -> ' .. szPrimaryVersion
					.. ' (' .. table.concat(aType, ',') .. ')',
				X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			D.DownloadData(
				info,
				function()
					FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
					--[[#DEBUG BEGIN]]
					X.Debug(
						'MY_TeamMon_Subscription',
						'Auto update complete, cost time ' .. (GetTime() - nTime) .. 'ms',
						X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.Sysmsg(_L('Upgrade TeamMon data to latest: %s', info.szTitle))
				end,
				aType)
			FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
		end)
end

function D.LoadConfigureFile(szFile, info, aSilentType)
	--[[#DEBUG BEGIN]]
	X.Debug(
		'MY_TeamMon_Subscription',
		'Load configure file ' .. szFile
			.. ' info: ' .. X.EncodeLUAData(info)
			.. ' silentType: ' .. X.EncodeLUAData(aSilentType),
		X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local function fnAction(bStatus, ...)
		if bStatus then
			local szFilePath, aType, szMode, tMeta = ...
			local me = X.GetClientPlayer()
			if not aSilentType and me.IsInParty() then
				MY_TeamMon.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_Subscription', {'LOAD', info.szTitle}, true)
			end
			MY_TeamMon.SetUserConfig('RR.LastVersion', info.szVersion)
			MY_TeamMon.SetUserConfig('RR.LastURL', GetShortURL(info.szURL) or info.szURL)
			MY_TeamMon.SetUserConfig('RR.LastType', aType)
			MY_TeamMon.SetUserConfig('RR.DataNotModified', true)
			FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
		end
	end
	if aSilentType then
		MY_TeamMon.ImportDataFromFile(szFile, aSilentType, 'REPLACE', fnAction)
	else
		MY_TeamMon_UI.OpenImportPanel(szFile, info.szTitle .. ' - ' .. info.szAuthor, fnAction)
	end
end

function D.DownloadData(info, callback, aSilentType)
	local szUUID = 'r-'
		.. ('%08x'):format(GetStringCRC(info.szDataURL))
		.. ('%08x'):format(GetStringCRC(info.szVersion))
	local LUA_CONFIG = { passphrase = D.PW, crc = true, compress = true }
	local p = X.LoadLUAData(MY_TM_REMOTE_DATA_ROOT .. szUUID .. '.meta.jx3dat', LUA_CONFIG)
	if p and p.szVersion == info.szVersion and IsLocalFileExist(MY_TM_REMOTE_DATA_ROOT .. szUUID .. '.jx3dat') then
		D.LoadConfigureFile(szUUID .. '.jx3dat', info, aSilentType)
		X.SafeCall(callback, true)
		return
	end
	if DATA_DOWNLOADING[info.szKey] then
		if not aSilentType then
			X.Topmsg(_L['Downloading in progress, please wait...'])
		end
		return
	end
	--[[#DEBUG BEGIN]]
	X.Debug(
		'MY_TeamMon_Subscription',
		'Start download file. info: ' .. X.EncodeLUAData(info)
			.. ' silentType: ' .. X.EncodeLUAData(aSilentType),
		X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	DATA_DOWNLOADING[info.szKey] = true
	X.FetchLUAData(info.szDataURL, LUA_CONFIG)
		:Then(function(data)
			DATA_DOWNLOADING[info.szKey] = nil
			if data then
				local szFile = szUUID .. '.jx3dat'
				X.SaveLUAData(MY_TM_REMOTE_DATA_ROOT .. szUUID .. '.meta.jx3dat', info, LUA_CONFIG)
				X.SaveLUAData(MY_TM_REMOTE_DATA_ROOT .. szFile, data, LUA_CONFIG)
				D.LoadConfigureFile(szFile, info, aSilentType)
			elseif not aSilentType then
				X.Topmsg(_L('Decode %s failed!', info.szTitle))
			end
			X.SafeCall(callback, true)
		end)
		:Catch(function(error)
			DATA_DOWNLOADING[info.szKey] = nil
			X.SafeCall(callback, false)
		end)
end

function D.ShareMetaInfoToRaid(info, bSure)
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
	end
	if not X.IsInParty() then
		return X.Alert(_L['You are not in the team.'])
	end
	if not X.IsLeader() and not X.IsDebugClient(true) then
		return X.Alert(_L['You are not team leader.'])
	end
	if not bSure then
		X.Confirm(_L['Confirm?'], function()
			D.ShareMetaInfoToRaid(info, true)
		end)
		return
	end
	MY_TeamMon.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_Subscription', {'SYNC', info})
end

function D.AppendMetaInfoItem(container, p, bSel)
	local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
	wnd:Lookup('', 'Text_Item_Author'):SetText(X.ReplaceSensitiveWord(p.szAuthor))
	wnd:Lookup('', 'Text_Item_Title'):SetText(X.ReplaceSensitiveWord(p.szTitle))
	wnd:Lookup('', 'Text_Item_Download'):SetText(X.ReplaceSensitiveWord(p.szUpdateTime))
	wnd:Lookup('', 'Image_Item_Sel'):SetVisible(bSel)
	if not X.IsEmpty(p.szAboutURL) then
		X.UI(wnd):Append('WndButton', {
			name = 'Btn_Info',
			x = 760, y = 1, w = 90, h = 30,
			buttonStyle = 'LINK',
			text = _L['See details'],
		})
	end
	X.UI(wnd):Append('WndButton', {
		name = 'Btn_Download',
		x = 860, y = 1, w = 90, h = 30,
		buttonStyle = 'SKEUOMORPHISM',
		text = (META_DOWNLOADING[p.szKey] and _L['Fetching...'])
			or (DATA_DOWNLOADING[p.szKey] and _L['Downloading...'])
			or ((GetShortURL(p.szURL) or p.szURL) == MY_TeamMon.GetUserConfig('RR.LastURL') and (
				p.szVersion == MY_TeamMon.GetUserConfig('RR.LastVersion')
					and _L['Last select']
					or _L['Can update']))
			or _L['Download'],
		enable = not META_DOWNLOADING[p.szKey] and not DATA_DOWNLOADING[p.szKey],
	})
	wnd.info = p
end

function D.UpdateRepoList(frame)
	if not frame and frame:IsValid() then
		return
	end
	-- 推荐
	local page = frame:Lookup('PageSet_Menu/Page_Repo')
	local szSel, bSel = page.szMetaInfoKeySel, false
	local container = page:Lookup('WndScroll_Repo/WndContainer_Repo_List')
	container:Clear()
	for _, p in ipairs(REPO_META_LIST) do
		local bS = szSel and p.szKey == szSel
		if bS then
			bSel = true
		end
		D.AppendMetaInfoItem(container, p, bS)
	end
	if not bSel then
		container:GetParent():GetParent().szMetaInfoKeySel = nil
	end
	container:FormatAllContentPos()
	-- 推荐页码
	local page = frame:Lookup('PageSet_Menu/Page_Repo')
	page:Lookup('Btn_RepoPrevPage'):Enable(REPO_META_PAGE.nIndex > 1)
	page:Lookup('Btn_RepoNextPage'):Enable(REPO_META_PAGE.nIndex < REPO_META_PAGE.nTotal)
	page:Lookup('', 'Text_Repo_Page'):SetText(REPO_META_PAGE.nIndex .. ' / ' .. REPO_META_PAGE.nTotal)
end

function D.UpdateFavList(frame)
	if not frame and frame:IsValid() then
		return
	end
	-- 收藏
	local page = frame:Lookup('PageSet_Menu/Page_Fav')
	local szSel, bSel = page.szMetaInfoKeySel, false
	local container = page:Lookup('WndScroll_Fav/WndContainer_Fav_List')
	container:Clear()
	for _, p in ipairs(D.LoadFavMetaInfoList()) do
		local bS = szSel and p.szKey == szSel
		if bS then
			bSel = true
		end
		D.AppendMetaInfoItem(container, p, bS)
	end
	if not bSel then
		container:GetParent():GetParent().szMetaInfoKeySel = nil
	end
	container:FormatAllContentPos()
end

function D.CheckPageInit(page)
	local p = page:GetActivePage()
	if p.bInit then
		return
	end
	if p:GetName() == 'Page_Repo' then
		D.UpdateRepoList(this:GetRoot())
		D.FetchRepoMetaInfoList()
	elseif p:GetName() == 'Page_Fav' then
		D.UpdateFavList(this:GetRoot())
		D.FetchFavMetaInfoList()
	end
	p.bInit = true
end

function D.GetFavMetaInfoSel(frame)
	local container = frame:Lookup('PageSet_Menu/Page_Fav/WndScroll_Fav/WndContainer_Fav_List')
	local szMetaInfoKeySel = container:GetParent():GetParent().szMetaInfoKeySel
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd.info.szKey == szMetaInfoKeySel then
			return wnd.info
		end
	end
end

function D.GetRepoMetaInfoSel(frame)
	local container = frame:Lookup('PageSet_Menu/Page_Repo/WndScroll_Repo/WndContainer_Repo_List')
	local szMetaInfoKeySel = container:GetParent():GetParent().szMetaInfoKeySel
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd.info.szKey == szMetaInfoKeySel then
			return wnd.info
		end
	end
end

function D.Init()
	local K = string.char(75, 69)
	local k = string.char(80, 87)
	if X.IsString(D[k]) then
		D[k] = X[K](D[k] .. string.char(77, 89))
	end
end

function D.OnFrameCreate()
	this:Lookup('', 'Text_Title'):SetText(_L['Subscribe list'])
	this:Lookup('PageSet_Menu/Page_Fav', 'Text_Fav_Break1'):SetText(_L['Author'])
	this:Lookup('PageSet_Menu/Page_Fav', 'Text_Fav_Break1'):SetText(_L['Author'])
	this:Lookup('PageSet_Menu/Page_Fav', 'Text_Fav_Break2'):SetText(_L['Title'])
	this:Lookup('PageSet_Menu/WndCheck_Fav', 'Text_FavCheck'):SetText(_L['Data Fav'])
	this:Lookup('PageSet_Menu/Page_Repo', 'Text_Repo_Break1'):SetText(_L['Author'])
	this:Lookup('PageSet_Menu/Page_Repo', 'Text_Repo_Break2'):SetText(_L['Title'])
	this:Lookup('PageSet_Menu/WndCheck_Repo', 'Text_RepoCheck'):SetText(_L['Repo Rank'])
	this:Lookup('PageSet_Menu/Page_Fav/Btn_FavSyncTeam', 'Text_FavSyncTeam'):SetText(_L['Sync team'])
	this:Lookup('PageSet_Menu/Page_Repo/Btn_RepoSyncTeam', 'Text_RepoSyncTeam'):SetText(_L['Sync team'])
	this:Lookup('PageSet_Menu/Page_Fav/Btn_FavCheckUpdate', 'Text_FavCheckUpdate'):SetText(_L['Check update'])
	this:Lookup('PageSet_Menu/Page_Repo/Btn_RepoCheckUpdate', 'Text_RepoCheckUpdate'):SetText(_L['Refresh list'])
	this:Lookup('PageSet_Menu/Page_Repo/Btn_RepoPrevPage', 'Text_RepoPrevPage'):SetText(_L['Prev page'])
	this:Lookup('PageSet_Menu/Page_Repo/Btn_RepoNextPage', 'Text_RepoNextPage'):SetText(_L['Next page'])
	this:Lookup('PageSet_Menu/Page_Fav/Btn_FavAddUrl', 'Text_FavAddUrl'):SetText(_L['Add url'])
	this:Lookup('PageSet_Menu/Page_Fav/Btn_FavRemoveUrl', 'Text_FavRemoveUrl'):SetText(_L['Remove url'])
	this:Lookup('PageSet_Menu/Page_Fav/Btn_FavExportUrl', 'Text_FavExportUrl'):SetText(_L['Export meta url'])
	this:RegisterEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
	this:RegisterEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	D.CheckPageInit(this:Lookup('PageSet_Menu'))
end

function D.OnEvent(event)
	if event == 'MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE' then
		D.UpdateRepoList(this)
	elseif event == 'MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE' then
		D.UpdateFavList(this)
	end
end

function D.OnActivePage()
	D.CheckPageInit(this)
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Close' then
		D.ClosePanel()
	elseif name == 'Btn_Download' then
		if this:GetParent():GetParent():GetParent():GetParent():GetName() == 'Page_Repo' then
			D.DownloadData(this:GetParent().info, function()
				FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
			end)
			FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__REPO_META_LIST_UPDATE')
		else
			local info = this:GetParent().info
			META_DOWNLOADING[info.szKey] = true
			D.FetchMetaInfo(
				info.szURL,
				function(info)
					META_DOWNLOADING[info.szKey] = nil
					D.DownloadData(info, function()
						FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
					end)
					FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
				end,
				function(szErrmsg)
					if szErrmsg then
						X.Alert(szErrmsg .. '\n' ..  info.szURL)
					end
					META_DOWNLOADING[info.szKey] = nil
					FireUIEvent('MY_TEAM_MON__SUBSCRIPTION__FAV_META_LIST_UPDATE')
				end)
		end
	elseif name == 'Btn_FavAddUrl' then
		GetUserInput(_L['Please input meta address:'], function(szText)
			local aURL = X.SplitString(szText, ';')
			local nPending = 0
			local aErrmsg = {}
			local function ProcessQueue()
				nPending = nPending + 1
				local szURL = aURL[nPending]
				if not szURL then
					if #aErrmsg > 0 then
						X.Alert(table.concat(aErrmsg, '\n'))
					end
					return
				end
				D.FetchMetaInfo(
					szURL,
					function(info)
						D.AddFavMetaInfo(info)
						ProcessQueue()
					end,
					function(szErrmsg)
						if szErrmsg then
							table.insert(aErrmsg, szErrmsg)
						end
						ProcessQueue()
					end)
			end
			ProcessQueue()
		end)
	elseif name == 'Btn_FavRemoveUrl' then
		local page = this:GetParent()
		local info = D.GetFavMetaInfoSel(this:GetRoot())
		if not info then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		if info.bEmbedded then
			return MY.Topmsg(_L['Embedded dataset cannot be removed!'])
		end
		X.Confirm(_L['Confirm?'], function()
			local aMetaInfo = D.LoadFavMetaInfoList()
			for i, p in X.ipairs_r(aMetaInfo) do
				if p.szKey == info.szKey then
					table.remove(aMetaInfo, i)
				end
			end
			if page and page.szMetaInfoKeySel == info.szKey then
				page.szMetaInfoKeySel = nil
			end
			D.SaveFavMetaInfoList(aMetaInfo)
			D.UpdateFavList(frame)
		end)
	elseif name == 'Btn_FavExportUrl' then
		local aMetaInfoURL = {}
		for _, info in ipairs(D.LoadFavMetaInfoList()) do
			table.insert(aMetaInfoURL, GetShortURL(info.szURL) or GetRawURL(info.szURL))
		end
		X.UI.OpenTextEditor(table.concat(aMetaInfoURL, ';'))
	elseif name == 'Btn_Info' then
		X.OpenBrowser(this:GetParent().info.szAboutURL)
	elseif name == 'Btn_FavSyncTeam' then
		local info = D.GetFavMetaInfoSel(this:GetRoot())
		if not info then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		D.ShareMetaInfoToRaid(info)
	elseif name == 'Btn_RepoSyncTeam' then
		local info = D.GetRepoMetaInfoSel(this:GetRoot())
		if not info then
			return MY.Topmsg(_L['Please select one dataset first!'])
		end
		D.ShareMetaInfoToRaid(info)
	elseif name == 'Btn_FavCheckUpdate' then
		D.FetchFavMetaInfoList()
	elseif name == 'Btn_RepoCheckUpdate' then
		D.FetchRepoMetaInfoList()
	elseif name == 'Btn_RepoPrevPage' then
		D.FetchRepoMetaInfoList(REPO_META_PAGE.nIndex - 1)
	elseif name == 'Btn_RepoNextPage' then
		D.FetchRepoMetaInfoList(REPO_META_PAGE.nIndex + 1)
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
		wnd:Lookup('', 'Image_Item_Sel'):Show()
		container:GetParent():GetParent().szMetaInfoKeySel = wnd.info.szKey
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local page = wnd:GetParent():GetParent():GetParent()
		local bFav = page:GetName() == 'Page_Fav'
		local t = {{
			szOption = _L['Copy meta url'],
			fnAction = function()
				X.UI.OpenTextEditor(wnd.info.szURL)
			end,
		}}
		local szShortURL = GetShortURL(wnd.info.szURL)
		if szShortURL then
			table.insert(t, {
				szOption = _L['Copy short meta url'],
				fnAction = function()
					X.UI.OpenTextEditor(szShortURL)
				end,
			})
		end
		table.insert(t, {
			szOption = _L['Sync team'],
			fnAction = function()
				D.ShareMetaInfoToRaid(wnd.info)
			end,
		})
		if not bFav then
			table.insert(t, {
				szOption = _L['Add fav'],
				fnAction = function()
					D.AddFavMetaInfo(wnd.info)
					X.Systopmsg(_L['Add fav success, you can switch to fav page to see.'])
				end,
			})
		end
		PopupMenu(t)
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local szTip = ''
		if not X.IsEmpty(wnd.info.szURL) then
			szTip = szTip .. _L('MetaInfo URL: %s', wnd.info.szURL)
		end
		local szShortURL = GetShortURL(wnd.info.szURL)
		if not X.IsEmpty(szShortURL) then
			szTip = szTip .. _L('(Short URL: %s)', szShortURL)
		end
		if IsCtrlKeyDown() then
			szTip = szTip .. '\n' .. X.EncodeLUAData(wnd.info, '  ')
		end
		if X.IsEmpty(szTip) then
			return
		end
		X.OutputTip(this, szTip)
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_Item' then
		HideTip()
	end
end

X.RegisterBgMsg('MY_TeamMon_Subscription', function(_, data, _, _, szTalker, _)
	local action = data[1]
	if action == 'SYNC' then
		local errs = X.Schema.CheckSchema(data[2], META_LUA_SCHEMA)
		if errs then
			return
		end
		local info = D.FormatMetaInfo(data[2])
		if info then
			X.Confirm(
				_L('%s request download:', szTalker)
					.. '\n' .. _L('Title: %s', info.szTitle)
					.. '\n' .. _L('Author: %s', info.szAuthor)
					.. (X.IsEmpty(info.szURL)
						and ''
						or '\n' .. _L('MetaInfo URL: %s', info.szURL))
					.. (X.IsEmpty(info.szUpdateTime)
						and ''
						or '\n' .. _L('Update time: %s', info.szUpdateTime)),
				function()
					D.AddFavMetaInfo(info)
					D.DownloadData(info)
				end)
		end
	elseif action == 'LOAD' then
		X.Sysmsg(_L('%s loaded %s', szTalker, data[2]))
	end
end)

X.RegisterInit(function()
	D.Init()
end)

X.RegisterInit('MY_TeamMon_Subscription', function()
	if X.IsDebugServer() then
		return
	end
	X.DelayCall(8000, function() D.CheckUpdate() end)
end)

X.RegisterEvent('MY_TM_DATA_MODIFY', 'MY_TeamMon_Subscription', function()
	MY_TeamMon.SetUserConfig('RR.DataNotModified', false)
end)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_Subscription',
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
MY_TeamMon_Subscription = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
