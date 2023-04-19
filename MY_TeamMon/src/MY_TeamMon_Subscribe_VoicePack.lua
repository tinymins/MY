--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控订阅数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_Subscribe_VoicePack'
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

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_Subscribe_VoicePack.ini'
local D = X.SetmetaLazyload({}, {
	PW = function() return X.SECRET['FILE::TEAM_MON_DATA_PW'] end,
})

local MY_TEAM_MON_REMOTE_DATA_ROOT = MY_TeamMon.MY_TEAM_MON_REMOTE_DATA_ROOT

local DATA_PAGINATION = {
	nIndex = 1,
	nSize = 30,
	nTotal = 1,
}
local DATA_LIST = {}
local DATA_SELECTED_KEY
local DATA_DOWNLOADING = {}

-- 获取在线订阅列表
function D.FetchSubscribeList(nPage)
	return X.Promise:new(function(resolve, reject)
		X.Ajax({
			url = 'https://pull.j3cx.com/api/dbm/subscribe/all',
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
					X.Debug(_L['MY_TeamMon_Subscribe_VoicePack'], szErrmsg, X.DEBUG_LEVEL.WARNING)
					reject(X.Error:new(szErrmsg))
					return
				end
				local tPagination = {
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
				X.Debug(_L['MY_TeamMon_Subscribe_VoicePack'], 'ERROR Get MetaInfo: ' .. X.EncodeLUAData(status) .. '\n' .. (X.ConvertToAnsi(html) or ''), X.DEBUG_LEVEL.WARNING)
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
	local LUA_CONFIG = { passphrase = D.PW, crc = true, compress = true }
	local szMetaFilePath = MY_TEAM_MON_REMOTE_DATA_ROOT .. szUUID .. '.meta.jx3dat'
	local szDataFilePath = MY_TEAM_MON_REMOTE_DATA_ROOT .. szUUID .. '.jx3dat'
	local aType = bSilent and MY_TeamMon.GetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastType') or nil
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
			X.Debug(
				'MY_TeamMon_Subscribe_VoicePack',
				'Start download file. info: ' .. X.EncodeLUAData(info)
					.. ' silentType: ' .. X.EncodeLUAData(aType),
				X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			DATA_DOWNLOADING[info.szKey] = true
			FireUIEvent('MY_TEAM_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
			X.FetchLUAData(info.szDataURL, LUA_CONFIG)
				:Then(function(data)
					DATA_DOWNLOADING[info.szKey] = nil
					FireUIEvent('MY_TEAM_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
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
					FireUIEvent('MY_TEAM_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
					reject(error)
				end)
		end)
			:Then(function()
				--[[#DEBUG BEGIN]]
				X.Debug(
					'MY_TeamMon_Subscribe_VoicePack',
					'Load configure file ' .. szDataFilePath
						.. ' info: ' .. X.EncodeLUAData(info)
						.. ' silentType: ' .. X.EncodeLUAData(aType),
					X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				local function fnAction(bStatus, ...)
					if bStatus then
						local szFilePath, aType, szMode, tMeta = ...
						local me = X.GetClientPlayer()
						if not bSilent and me.IsInParty() then
							MY_TeamMon.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_Subscribe_VoicePack', {'LOAD', info.szTitle}, true)
						end
						MY_TeamMon.SetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastVersion', info.szVersion)
						MY_TeamMon.SetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastURL', D.GetShortURL(info.szURL) or info.szURL)
						MY_TeamMon.SetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastType', aType)
						MY_TeamMon.SetUserConfig('MY_TeamMon_Subscribe_VoicePack.DataNotModified', true)
						FireUIEvent('MY_TEAM_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')
					end
				end
				if bSilent then
					MY_TeamMon.ImportDataFromFile(szDataFilePath, aType, 'REPLACE', fnAction)
				else
					MY_TeamMon_UI.OpenImportPanel(szDataFilePath, info.szTitle .. ' - ' .. info.szAuthor, fnAction)
				end
			end)
			:Catch(function(error)
				if not bSilent then
					X.Topmsg(error.message)
				end
				reject(error)
			end)
	end)
end

function D.SyncTeam(info)
	local function CheckSharePerms()
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
		elseif not X.IsInParty() then
			X.Alert(_L['You are not in the team.'])
		elseif not X.IsLeader() and not X.IsDebugClient(true) then
			X.Alert(_L['You are not team leader.'])
		elseif not info then
			MY.Topmsg(_L['Please select one dataset first!'])
		else
			return true
		end
		return false
	end
	if CheckSharePerms() then
		X.Confirm(_L['Confirm?'], function()
			if CheckSharePerms() then
				MY_TeamMon.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamMon_Subscribe_VoicePack', {'SYNC', info})
			end
		end)
	end
end

function D.Init()
	local K = string.char(75, 69)
	local k = string.char(80, 87)
	if X.IsString(D[k]) then
		D[k] = X[K](D[k] .. string.char(77, 89))
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
		X.UI(wnd):Append('WndButton', {
			name = 'Btn_Download',
			x = 860, y = 1, w = 90, h = 30,
			buttonStyle = 'SKEUOMORPHISM',
			text = (DATA_DOWNLOADING[info.szKey] and _L['Downloading...'])
				or (bIsSubscripted and (
					bIsLatest
						and _L['Last select']
						or _L['Can update']))
				or _L['Download'],
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
	page:Lookup('Wnd_Total', 'Text_Page'):SetText(DATA_PAGINATION.nIndex .. ' / ' .. DATA_PAGINATION.nTotal)
end

function D.SwitchPage(nPage)
	D.FetchSubscribeList(nPage)
		:Then(function(res)
			DATA_LIST = res.aMetaInfo
			DATA_PAGINATION = res.tPagination
			FireUIEvent('MY_TEAM_MON__SUBSCRIBE_DATA__LIST_UPDATE')
		end)
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_Subscribe_VoicePack')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	wnd:SetRelPos(0, 0)
	Wnd.CloseWindow(frameTemp)

	wnd:Lookup('', 'Text_Break1'):SetText(_L['Author'])
	wnd:Lookup('', 'Text_Break2'):SetText(_L['Title'])
	wnd:Lookup('Btn_SyncTeam', 'Text_SyncTeam'):SetText(_L['Sync team'])
	wnd:Lookup('Btn_CheckUpdate', 'Text_CheckUpdate'):SetText(_L['Refresh list'])
	wnd:Lookup('Btn_PrevPage', 'Text_PrevPage'):SetText(_L['Prev page'])
	wnd:Lookup('Btn_NextPage', 'Text_NextPage'):SetText(_L['Next page'])

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_DATA__LIST_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')

	D.UpdateList(this)
	D.SwitchPage(1)
end

function D.OnActivePage()
end

function D.OnEvent(event)
	if event == 'MY_TEAM_MON__SUBSCRIBE_DATA__LIST_UPDATE'
	or event == 'MY_TEAM_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE'
	or event == 'MY_TEAM_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE' then
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
				MY_TeamMon_Subscribe_FavoriteData.Add(wnd.info)
				X.Systopmsg(_L['Add favorite success, you can switch to favorite page to see.'])
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
-- Module exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_Subscribe_VoicePack',
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
MY_TeamMon_Subscribe.RegisterModule('SubscribeData', _L['Subscribe list'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_Subscribe_VoicePack',
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
				'FetchSubscribeItem',
				'SyncTeam',
			},
		},
	},
}
MY_TeamMon_Subscribe_VoicePack = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterBgMsg('MY_TeamMon_Subscribe_VoicePack', function(_, data, _, _, szTalker, _)
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
		X.Sysmsg(_L('%s loaded %s', szTalker, data[2]))
	end
end)

X.RegisterInit(function()
	D.Init()
end)

X.RegisterInit('MY_TeamMon_Subscribe_VoicePack', function()
	if X.IsDebugServer() then
		return
	end
	-- 订阅数据自动更新
	X.DelayCall(8000, function()
		local szLastURL = MY_TeamMon.GetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastURL')
		local bDataNotModified = MY_TeamMon.GetUserConfig('MY_TeamMon_Subscribe_VoicePack.DataNotModified')
		local aType = MY_TeamMon.GetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastType')
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
		D.FetchSubscribeItem(
			szLastURL,
			function(info)
				local szPrimaryVersion = ParseVersion(info.szVersion)
				local szLastPrimaryVersion = ParseVersion(MY_TeamMon.GetUserConfig('MY_TeamMon_Subscribe_VoicePack.LastVersion'))
				if X.IsEmpty(szPrimaryVersion) or szPrimaryVersion == szLastPrimaryVersion then
					return
				end
				--[[#DEBUG BEGIN]]
				local nTime = GetTime()
				X.Debug(
					'MY_TeamMon_Subscribe_VoicePack',
					'Auto update confirmed: ' .. szLastPrimaryVersion
						.. ' -> ' .. szPrimaryVersion
						.. ' (' .. table.concat(aType, ',') .. ')',
					X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				D.Subscribe(info, true)
					:Then(function()
						--[[#DEBUG BEGIN]]
						X.Debug(
							'MY_TeamMon_Subscribe_VoicePack',
							'Auto update complete, cost time ' .. (GetTime() - nTime) .. 'ms',
							X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						X.Sysmsg(_L('Upgrade TeamMon data to latest: %s', info.szTitle))
					end)
			end)
	end)
end)

X.RegisterEvent('MY_TEAM_MON_DATA_MODIFY', 'MY_TeamMon_Subscribe_VoicePack', function()
	MY_TeamMon.SetUserConfig('MY_TeamMon_Subscribe_VoicePack.DataNotModified', false)
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
