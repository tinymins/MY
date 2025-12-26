--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控订阅数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon_Subscribe_Data'
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TargetMon/ui/MY_TargetMon_Subscribe_Data.ini'
local D = {}

local REMOTE_DATA_ROOT = MY_TargetMonConfig.REMOTE_DATA_ROOT

local DATA_PAGINATION = {
	nIndex = 1,
	nSize = 30,
	nTotal = 1,
	nPageTotal = 1,
}
local DATA_LIST = {}
local DATA_SELECTED_KEY
local DATA_DOWNLOADING = {}

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
local FEEDS_LIST_JSON_SCHEMA = X.Schema.Collection(META_JSON_SCHEMA)

-- 陆服环境下，以下缩写均对等
-- tinymins
-- tinymins?master
-- tinymins/JX3_MY_DATA
-- tinymins/JX3_MY_DATA?master
-- tinymins@github
-- tinymins@github?master
-- tinymins@github:/MY_TargetMon/zhcn/meta.json
-- tinymins@github/JX3_MY_DATA
-- tinymins@github/JX3_MY_DATA:/MY_TargetMon/zhcn/meta.json
-- tinymins@github/JX3_MY_DATA?master:/MY_TargetMon/zhcn/meta.json
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
		szRawURL = MY_RSS.PULL_BASE_URL .. '/api/addon/target-monitor/subscribe/feed?key=%s',
		szRawURL_T = {
			'^' .. X.EscapeString(MY_RSS.PULL_BASE_URL) .. '/api/addon/target-monitor/subscribe/feed%?.*&key%=([^&]+)&.*$',
			'^' .. X.EscapeString(MY_RSS.PULL_BASE_URL) .. '/api/addon/target-monitor/subscribe/feed%?key%=([^&]+)&.*$',
			'^' .. X.EscapeString(MY_RSS.PULL_BASE_URL) .. '/api/addon/target-monitor/subscribe/feed%?.*&key%=([^&]+)$',
			'^' .. X.EscapeString(MY_RSS.PULL_BASE_URL) .. '/api/addon/target-monitor/subscribe/feed%?key%=([^&]+)$',
		},
	},
}
local DEFAULT_PROVIDER = 'jx3box'
local DEFAULT_PROJECT = 'JX3_MY_DATA'
local DEFAULT_BRANCH = 'master'
local DEFAULT_PATH = 'MY_TargetMon/' .. X.ENVIRONMENT.GAME_EDITION .. '/meta.json'
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
function D.GetRawURL(szURL)
	return GetURL(szURL, 'RAW')
end
-- 将地址转化为 GIT 仓库源文件下载地址
function D.GetBlobURL(szURL)
	return GetURL(szURL, 'BLOB')
end
-- 将地址转化为短链接
function D.GetShortURL(szURL)
	return GetURL(szURL, 'SHORT')
end
-- 根据描述文件中的相对文件地址 计算绝对 GIT 仓库浏览地址
function D.GetAttachRawURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if X.IsURL(szAttach) then
		return szAttach
	end
	local szURL = D.GetRawURL(szURL)
	if not szURL then
		return
	end
	return X.NormalizeURI(X.ConcatURI(X.GetParentURI(szURL), szAttach))
end
-- 根据描述文件中的相对文件地址 计算绝对 GIT 仓库源文件下载地址
function D.GetAttachBlobURL(szAttach, szURL)
	if not szAttach then
		return
	end
	if X.IsURL(szAttach) then
		return szAttach
	end
	local szURL = D.GetBlobURL(szURL)
	if not szURL then
		return
	end
	return X.NormalizeURI(X.ConcatURI(X.GetParentURI(szURL), szAttach))
end
end

-- 格式化描述内容
-- 进入该函数的数据必须为安全数据，即已经过 Schema 检测的数据。
function D.FormatMetaInfo(res)
	local szURL = res.szURL or res.url
	local info = {
		szURL = szURL,
		szDataURL = D.GetAttachRawURL(res.szDataURL or res.data_url or './data.jx3dat', szURL),
		szKey = res.szKey or res.key or D.GetShortURL(szURL) or ('H' .. GetStringCRC(szURL)),
		szAuthor = res.szAuthor or res.author or '',
		szTitle = res.szTitle or res.name or '',
		szUpdateTime = res.szUpdateTime or res.update or '',
		szVersion = res.szVersion or res.version or '',
	}
	if X.IsEmpty(info.szURL) or X.IsEmpty(info.szTitle) or X.IsEmpty(info.szVersion) then
		return
	end
	return info
end

function D.IsDownloading(szKey)
	return DATA_DOWNLOADING[szKey]
end

function D.IsSubscripted(info)
	local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
	local tInfo = tSubscribed[D.GetShortURL(info.szURL) or info.szURL]
	if tInfo then
		return true, info.szVersion == tInfo.szVersion
	end
	return false, false
end

-- 获取在线订阅列表
function D.FetchSubscribeList(nPage)
	return X.Promise:new(function(resolve, reject)
		X.Ajax({
			url = MY_RSS.PULL_BASE_URL .. '/api/addon/target-monitor/subscribe/all',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				page = nPage,
				pageSize = 15,
			},
			success = function(szHTML)
				local res = X.DecodeJSON(szHTML)
				local errs = X.Schema.CheckSchema(res, META_LIST_JSON_SCHEMA)
				if errs then
					local aErrmsg = {}
					for i, err in ipairs(errs) do
						table.insert(aErrmsg, i .. '. ' .. err.message)
					end
					local szErrmsg = _L['Fetch repo meta list failed.'] .. '\n' .. table.concat(aErrmsg, '\n')
					X.OutputDebugMessage(_L['MY_TargetMon_Subscribe_Data'], szErrmsg, X.DEBUG_LEVEL.WARNING)
					reject(X.Error:new(szErrmsg))
					return
				end
				local tPagination = {
					nIndex = res.page.index,
					nSize = res.page.size,
					nTotal = res.page.total,
					nPageTotal = math.ceil(res.page.total / res.page.size),
				}
				local aMetaInfo = {}
				for _, info in ipairs(res.data) do
					info.url = MY_RSS.PULL_BASE_URL .. '/api/addon/target-monitor/subscribe/feed?'
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
				resolve({ tPagination = tPagination, aMetaInfo = aMetaInfo })
			end,
		})
	end)
end

-- 根据订阅文件地址，获取订阅文件内容
function D.FetchSubscribeItem(szURL)
	return X.Promise:new(function(resolve, reject)
		local szURL = D.GetRawURL(szURL) or szURL
		X.Ajax({
			url = szURL,
			success = function(szHTML)
				local res, err = X.DecodeJSON(szHTML)
				if not res then
					reject(X.Error:new(_L['ERR: Decode info content as json failed!']))
					return
				end
				local errs = X.Schema.CheckSchema(res, META_JSON_SCHEMA)
				if errs then
					local aErrmsg = {}
					for i, err in ipairs(errs) do
						table.insert(aErrmsg, '  ' .. i .. '. ' .. err.message)
					end
					reject(X.Error:new(_L['ERR: Info content is illegal!'] .. '\n\n' .. table.concat(aErrmsg, '\n')))
					return
				end
				res.url = szURL
				local info = D.FormatMetaInfo(res)
				if not info then
					reject(X.Error:new(_L['ERR: Info content is illegal!']))
					return
				end
				resolve(info)
			end,
			error = function(html, status)
				if status == 404 then
					reject(X.Error:new(_L['ERR404: MetaInfo address not found!']))
					return
				end
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_TargetMon_Subscribe_Data'], 'ERROR Get MetaInfo: ' .. X.EncodeLUAData(status) .. '\n' .. (X.ConvertToANSI(html) or ''), X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				reject(X.Error:new(_L['ERR: Get MetaInfo failed!']))
			end,
		})
	end)
end

function D.Subscribe(info, bSilent)
	local szUUID = 'r-'
		.. ('%08x'):format(GetStringCRC(info.szDataURL))
		.. ('%08x'):format(GetStringCRC(info.szVersion))
	local LUA_CONFIG = { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY'), crc = true, compress = true }
	local szMetaFilePath = REMOTE_DATA_ROOT .. szUUID .. '.meta.jx3dat'
	local szDataFilePath = REMOTE_DATA_ROOT .. szUUID .. '.jx3dat'
	local aUUID = nil
	local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
	local szURL = D.GetShortURL(info.szURL) or info.szURL
	local tLastInfo = tSubscribed[szURL]
	if tLastInfo then
		aUUID = {}
		for _, szUUID in ipairs(tLastInfo.aUUID) do
			if not tLastInfo.tUUIDModified[szUUID] then
				table.insert(aUUID, szUUID)
			end
		end
	end
	return X.Promise:new(function(resolve, reject)
		X.Promise:new(function(resolve, reject)
			local p = X.LoadLUAData(szMetaFilePath, LUA_CONFIG)
			if p and p.szVersion == info.szVersion and IsLocalFileExist(szDataFilePath) then
				resolve()
				return
			end
			if DATA_DOWNLOADING[info.szKey] then
				reject(X.Error:new(_L['Downloading in progress, please wait...']))
				return
			end
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(
				'MY_TargetMon_Subscribe_Data',
				'Start download file. info: ' .. X.EncodeLUAData(info)
					.. ' uuids: ' .. X.EncodeLUAData(aUUID),
				X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			DATA_DOWNLOADING[info.szKey] = true
			FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
			X.FetchLUAData(info.szDataURL, LUA_CONFIG)
				:Then(function(data)
					DATA_DOWNLOADING[info.szKey] = nil
					FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
					if data then
						X.SaveLUAData(szMetaFilePath, info, LUA_CONFIG)
						X.SaveLUAData(szDataFilePath, data, LUA_CONFIG)
						resolve()
					else
						reject(X.Error:new(_L('Decode %s failed!', info.szTitle)))
					end
				end)
				:Catch(function(error)
					DATA_DOWNLOADING[info.szKey] = nil
					FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
					reject(error)
				end)
		end)
			:Then(function()
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(
					'MY_TargetMon_Subscribe_Data',
					'Load configure file ' .. szDataFilePath
						.. ' info: ' .. X.EncodeLUAData(info)
						.. ' uuids: ' .. X.EncodeLUAData(aUUID),
					X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				MY_TargetMonConfig.ImportDatasetFile(szDataFilePath, {
					aUUID = aUUID,
					bConfirmed = bSilent,
					fnCallback = function(aDataset)
						local me = X.GetClientPlayer()
						if not bSilent and me.IsInParty() then
							MY_TargetMonConfig.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TargetMon_Subscribe_Data', {'LOAD', info.szTitle}, true)
						end
						local aUUID, tUUID = {}, {}
						for _, dataset in ipairs(aDataset) do
							tUUID[dataset.szUUID] = true
							table.insert(aUUID, dataset.szUUID)
						end
						local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
						local szURL = D.GetShortURL(info.szURL) or info.szURL
						local tInfo = tSubscribed[szURL]
						if tInfo then
							for _, szUUID in ipairs(tInfo.aUUID) do
								if not tUUID[szUUID] and not tInfo.tUUIDModified[szUUID] then
									MY_TargetMonConfig.DeleteDataset(szUUID)
								end
							end
						end
						tSubscribed[szURL] = {
							szKey = info.szKey,
							szVersion = info.szVersion,
							aUUID = aUUID,
							tUUIDModified = {},
						}
						MY_TargetMonConfig.SetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed', tSubscribed)
						FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')
					end,
				})
			end)
			:Catch(function(error)
				if not bSilent then
					X.OutputAnnounceMessage(error.message)
				end
				reject(error)
			end)
	end)
end

function D.Unsubscribe(info)
	local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
	local szURL = D.GetShortURL(info.szURL) or info.szURL
	local tInfo = tSubscribed[szURL]
	if tInfo then
		for _, szUUID in ipairs(tInfo.aUUID) do
			if not tInfo.tUUIDModified[szUUID] then
				MY_TargetMonConfig.DeleteDataset(szUUID)
			end
		end
	end
	tSubscribed[szURL] = nil
	MY_TargetMonConfig.SetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed', tSubscribed)
	FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')
end

function D.SyncTeam(info)
	local function CheckSharePerms()
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
		elseif not X.IsClientPlayerInParty() then
			X.Alert(_L['You are not in the team.'])
		elseif not X.IsClientPlayerTeamLeader() and not X.IsDebugging() then
			X.Alert(_L['You are not team leader.'])
		elseif not info then
			MY.OutputAnnounceMessage(_L['Please select one dataset first!'])
		else
			return true
		end
		return false
	end
	if CheckSharePerms() then
		X.Confirm(_L['Confirm?'], function()
			if CheckSharePerms() then
				MY_TargetMonConfig.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TargetMon_Subscribe_Data', {'SYNC', info})
			end
		end)
	end
end

function D.UpdateList(page)
	if not page or not page:IsValid() then
		return
	end
	local szSel, bExistSelect = DATA_SELECTED_KEY, false
	local container = page:Lookup('Wnd_Total/WndScroll_Subscribe/WndContainer_Subscribe')
	container:Clear()
	for _, info in ipairs(DATA_LIST) do
		local bSel = szSel and info.szKey == szSel
		if bSel then
			bExistSelect = true
		end
		local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
		wnd:Lookup('', 'Text_Item_Author'):SetText(X.ReplaceSensitiveWord(info.szAuthor))
		wnd:Lookup('', 'Text_Item_Title'):SetText(X.ReplaceSensitiveWord(info.szTitle))
		wnd:Lookup('', 'Text_Item_Download'):SetText(X.ReplaceSensitiveWord(info.szUpdateTime))
		wnd:Lookup('', 'Image_Item_Sel'):SetVisible(bSel)
		if not X.IsEmpty(info.szAboutURL) then
			X.UI(wnd):Append('WndButton', {
				name = 'Btn_Info',
				x = 760, y = 1, w = 90, h = 30,
				buttonStyle = 'LINK',
				text = _L['See details'],
			})
		end
		local bIsSubscripted, bIsLatest = D.IsSubscripted(info)
		if D.IsSubscripted(info) then
			X.UI(wnd):Append('WndButton', {
				name = 'Btn_Unsubscribe',
				x = 765, y = 1, w = 90, h = 30,
				buttonStyle = 'SKEUOMORPHISM',
				text = _L['Unsubscribe'],
				onClick = function() D.Unsubscribe(info) end,
			})
		end
		X.UI(wnd):Append('WndButton', {
			name = 'Btn_Download',
			x = 860, y = 1, w = 90, h = 30,
			buttonStyle = 'SKEUOMORPHISM',
			text = (DATA_DOWNLOADING[info.szKey] and _L['Downloading...'])
				or (bIsSubscripted and (
					bIsLatest
						and _L['Subscribed']
						or _L['Can update']))
				or _L['Subscribe'],
			enable = not DATA_DOWNLOADING[info.szKey],
			onClick = function() D.Subscribe(info) end,
		})
		wnd.info = info
	end
	if not bExistSelect then
		page.szMetaInfoKeySel = nil
	end
	container:FormatAllContentPos()
	-- 推荐页码
	page:Lookup('Wnd_Total/Btn_PrevPage'):Enable(DATA_PAGINATION.nIndex > 1)
	page:Lookup('Wnd_Total/Btn_NextPage'):Enable(DATA_PAGINATION.nIndex < DATA_PAGINATION.nTotal)
	page:Lookup('Wnd_Total', 'Text_Page'):SetText(DATA_PAGINATION.nIndex .. ' / ' .. DATA_PAGINATION.nPageTotal)
end

function D.SwitchPage(nPage)
	D.FetchSubscribeList(nPage)
		:Then(function(res)
			DATA_LIST = res.aMetaInfo
			DATA_PAGINATION = res.tPagination
			FireUIEvent('MY_TARGET_MON__SUBSCRIBE_DATA__LIST_UPDATE')
		end)
end

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(INI_PATH, 'MY_TargetMon_Subscribe_Data')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	wnd:SetRelPos(0, 0)
	X.UI.CloseFrame(frameTemp)
	X.UI.AdaptComponentAppearance(wnd:Lookup('WndScroll_Subscribe/Scroll_Subscribe'))

	wnd:Lookup('', 'Text_Break1'):SetText(_L['Author'])
	wnd:Lookup('', 'Text_Break2'):SetText(_L['Title'])
	wnd:Lookup('Btn_SyncTeam', 'Text_SyncTeam'):SetText(_L['Sync team'])
	wnd:Lookup('Btn_CheckUpdate', 'Text_CheckUpdate'):SetText(_L['Refresh list'])
	wnd:Lookup('Btn_PrevPage', 'Text_PrevPage'):SetText(_L['Prev page'])
	wnd:Lookup('Btn_NextPage', 'Text_NextPage'):SetText(_L['Next page'])

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_DATA__LIST_UPDATE')
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')

	D.UpdateList(this)
	D.SwitchPage(1)
end

function D.OnActivePage()
end

function D.OnEvent(event)
	if event == 'MY_TARGET_MON__SUBSCRIBE_DATA__LIST_UPDATE'
	or event == 'MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE'
	or event == 'MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE' then
		D.UpdateList(this)
	end
end

function D.OnFrameDestroy()
	DATA_SELECTED_KEY = nil
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_SyncTeam' then
		local info
		for _, v in ipairs(DATA_LIST) do
			if v.szKey == DATA_SELECTED_KEY then
				info = v
				break
			end
		end
		D.SyncTeam(info)
	elseif name == 'Btn_CheckUpdate' then
		D.SwitchPage(DATA_PAGINATION.nIndex)
	elseif name == 'Btn_PrevPage' then
		D.SwitchPage(DATA_PAGINATION.nIndex - 1)
	elseif name == 'Btn_NextPage' then
		D.SwitchPage(DATA_PAGINATION.nIndex + 1)
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
		DATA_SELECTED_KEY = wnd.info.szKey
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local t = {{
			szOption = _L['Copy meta url'],
			fnAction = function()
				X.UI.OpenTextEditor(wnd.info.szURL)
			end,
		}}
		local szShortURL = D.GetShortURL(wnd.info.szURL)
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
				D.SyncTeam(wnd.info)
			end,
		})
		table.insert(t, {
			szOption = _L['Add favorite'],
			fnAction = function()
				MY_TargetMon_Subscribe_FavoriteData.Add(wnd.info)
				X.OutputSystemAnnounceMessage(_L['Add favorite success, you can switch to favorite page to see.'])
			end,
		})
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
		local szShortURL = D.GetShortURL(wnd.info.szURL)
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

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMon_Subscribe_Data',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
			},
			root = D,
		},
	},
}
MY_TargetMon_Subscribe.RegisterModule('SubscribeData', _L['Subscribe list'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMon_Subscribe_Data',
	exports = {
		{
			root = D,
			fields = {
				'GetRawURL',
				'GetBlobURL',
				'GetShortURL',
				'GetAttachRawURL',
				'GetAttachBlobURL',
				'IsDownloading',
				'IsSubscripted',
				'Subscribe',
				'Unsubscribe',
				'FetchSubscribeItem',
				'SyncTeam',
			},
			preset = 'UIEvent',
		},
	},
}
MY_TargetMon_Subscribe_Data = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterBgMsg('MY_TargetMon_Subscribe_Data', function(_, data, _, _, szTalker, _)
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
					-- D.AddFavMetaInfo(info) TODO
					D.Subscribe(info)
				end)
		end
	elseif action == 'LOAD' then
		X.OutputSystemMessage(_L('%s loaded %s', szTalker, data[2]))
	end
end)

X.RegisterInit('MY_TargetMon_Subscribe_Data', function()
	if X.IsDebugServer() then
		return
	end
	-- 订阅数据自动更新
	X.DelayCall(8000, function()
		local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
		local aKey = {}
		for _, tInfo in pairs(tSubscribed) do
			table.insert(aKey, tInfo.szKey)
		end
		if X.IsEmpty(aKey) then
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
		X.Ajax({
			url = MY_RSS.PULL_BASE_URL .. '/api/addon/target-monitor/subscribe/feeds?',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				key = table.concat(aKey, '|'),
			},
			success = function(szHTML)
				local res = X.DecodeJSON(szHTML)
				local errs = X.Schema.CheckSchema(res, FEEDS_LIST_JSON_SCHEMA)
				if errs then
					return
				end
				local aUpdateInfo = {}
				for _, info in ipairs(res) do
					info.url = MY_RSS.PULL_BASE_URL .. '/api/addon/target-monitor/subscribe/feed?'
						.. X.EncodeQuerystring(X.ConvertToUTF8({
							l = X.ENVIRONMENT.GAME_LANG,
							L = X.ENVIRONMENT.GAME_EDITION,
							key = info.key,
						}))
					local tInfo = D.FormatMetaInfo(info)
					if tInfo then
						local tLastInfo = tSubscribed[D.GetShortURL(tInfo.szURL) or tInfo.szURL]
						local szPrimaryVersion = ParseVersion(tInfo.szVersion)
						local szLastPrimaryVersion = ParseVersion(tLastInfo.szVersion)
						if szPrimaryVersion ~= szLastPrimaryVersion then
							tInfo.bEmbedded = true
							table.insert(aUpdateInfo, tInfo)
						end
					end
				end
				--[[#DEBUG BEGIN]]
				local nTime = GetTime()
				local aUpdateLog = {}
				for _, tInfo in ipairs(aUpdateInfo) do
					local tLastInfo = tSubscribed[D.GetShortURL(tInfo.szURL) or tInfo.szURL]
					table.insert(aUpdateLog, tInfo.szKey .. '(' .. tLastInfo.szVersion .. '->' .. tInfo.szVersion .. ')')
				end
				X.OutputDebugMessage(
					'MY_TargetMon_Subscribe_Data',
					'Auto update confirmed: ' .. table.concat(aUpdateLog, '; '),
					X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				for _, tInfo in ipairs(aUpdateInfo) do
					D.Subscribe(tInfo, true)
						:Then(function()
							--[[#DEBUG BEGIN]]
							X.OutputDebugMessage(
								'MY_TargetMon_Subscribe_Data',
								'Auto update [' .. tInfo.szKey .. '] complete, cost time ' .. (GetTime() - nTime) .. 'ms',
								X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							X.OutputSystemMessage(_L('Upgrade TargetMon data to latest: %s', tInfo.szTitle))
						end)
				end
			end,
		})
	end)
end)

do
local function OnDatasetChange(szModifiedUUID)
	local tSubscribed = MY_TargetMonConfig.GetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed') or {}
	for _, tInfo in pairs(tSubscribed) do
		for _, szUUID in ipairs(tInfo.aUUID) do
			if szUUID == szModifiedUUID then
				tInfo.tUUIDModified[szUUID] = true
			end
		end
	end
	MY_TargetMonConfig.SetUserConfig('MY_TargetMon_Subscribe_Data.Subscribed', tSubscribed)
end
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', 'MY_TargetMon_Subscribe_Data', function()
	if arg1 == 'tMap' then
		OnDatasetChange(arg0)
	end
end)
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', 'MY_TargetMon_Subscribe_Data', function()
	OnDatasetChange(arg0)
end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
