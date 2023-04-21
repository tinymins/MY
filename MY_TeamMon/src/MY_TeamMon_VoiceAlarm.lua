--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÓïÒô±¨¾¯
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_VoiceAlarm'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_VoiceAlarm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^15.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_TeamMon_VoiceAlarm', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	dwOfficialVoicePacketID = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	szOfficialVoicePacketVersion = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	dwCustomVoicePacketID = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	szCustomVoicePacketVersion = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
})
local D = {}
local MY_TEAM_MON_VA_VOICE_ROOT = X.FormatPath({'userdata/team_mon/audio/', X.PATH_TYPE.GLOBAL})
local DOWNLOADER_CACHE = {}

CPath.MakeDir(MY_TEAM_MON_VA_VOICE_ROOT)

local VOICE_PACKET_LIST_JSON_SCHEMA = X.Schema.Record({
	list = X.Schema.Collection(X.Schema.Record({
		id = X.Schema.Number,
		title = X.Schema.String,
		version = X.Schema.Number,
		display_name = X.Schema.String,
	}, true)),
	page = X.Schema.Record({
		index = X.Schema.Number,
		pageSize = X.Schema.Number,
		total = X.Schema.Number,
		pageTotal = X.Schema.Number,
	}, true),
}, true)

local VOICE_LIST_JSON_SCHEMA = X.Schema.Record({
	data = X.Schema.Record({
		list = X.Schema.Collection(X.Schema.Record({
			id = X.Schema.Number,
			slug = X.Schema.String,
			filename = X.Schema.String,
			group = X.Schema.String,
			crc = X.Schema.Number,
		}, true)),
		vpk_id = X.Schema.Number,
		vpk_uuid = X.Schema.String,
		vpk_version = X.Schema.Number,
	}, true)
}, true)

local SLUG_LIST_JSON_SCHEMA = X.Schema.Record({
	data = X.Schema.Collection(X.Schema.Record({
		id = X.Schema.Number,
		group = X.Schema.String,
		group_name = X.Schema.String,
		slug = X.Schema.String,
		remark = X.Schema.String,
	}, true)),
}, true)

function D.FetchPacketList(szType, nPage)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	return X.Promise:new(function(resolve, reject)
		X.Ajax({
			url = 'https://pull.j3cx.com/api/dbm/game/vpk',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				is_official = szType == 'OFFICIAL' and 1 or 0,
				pageIndex = nPage,
				pageSize = 15,
			},
			success = function(szHTML)
				local res = X.DecodeJSON(szHTML)
				local res = X.IsTable(res) and res.data
				local errs = X.Schema.CheckSchema(res, VOICE_PACKET_LIST_JSON_SCHEMA)
				if errs then
					local aErrmsg = {}
					for i, err in ipairs(errs) do
						table.insert(aErrmsg, i .. '. ' .. err.message)
					end
					local szErrmsg = _L['Fetch repo meta list failed.'] .. '\n' .. table.concat(aErrmsg, '\n')
					X.Debug(_L['MY_TeamMon_VoiceAlarm'], szErrmsg, X.DEBUG_LEVEL.WARNING)
					reject(X.Error:new(szErrmsg))
					return
				end
				local tPagination = {
					nIndex = res.page.index,
					nSize = res.page.pageSize,
					nTotal = res.page.total,
					nPageTotal = res.page.pageTotal,
				}
				local aPacket = {}
				for _, info in ipairs(res.list) do
					table.insert(aPacket, {
						dwID = info.id,
						szTitle = info.title,
						szVersion = tostring(info.version),
						szAuthor = info.display_name,
						szUpdateTime = info.updated_at,
					})
				end
				resolve({ tPagination = tPagination, aPacket = aPacket })
			end,
		})
	end)
end

function D.SetCurrentPacketID(szType, dwID)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	if szType == 'OFFICIAL' then
		O.dwOfficialVoicePacketID = dwID
	else
		O.dwCustomVoicePacketID = dwID
	end
	D.DownloadPacket(szType)
	FireUIEvent('MY_TEAM_MON__VOICE_ALARM__CURRENT_PACKET_UPDATE', szType, dwID)
end

function D.GetCurrentPacketID(szType)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	if szType == 'OFFICIAL' then
		return O.dwOfficialVoicePacketID, O.szOfficialVoicePacketVersion
	else
		return O.dwCustomVoicePacketID, O.szCustomVoicePacketVersion
	end
end

function D.FetchSlugList()
	return X.Promise:new(function(resolve, reject)
		if D.aSlugGroup then
			resolve(D.aSlugGroup)
			return
		end
		X.Ajax({
			url = 'https://dbm.jx3box.com/api/dbm/game/vpk/slugs',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
			},
			success = function(szHTML)
				local res = X.DecodeJSON(szHTML)
				local errs = X.Schema.CheckSchema(res, SLUG_LIST_JSON_SCHEMA)
				if errs then
					local aErrmsg = {}
					for i, err in ipairs(errs) do
						table.insert(aErrmsg, i .. '. ' .. err.message)
					end
					local szErrmsg = _L['Fetch repo meta list failed.'] .. '\n' .. table.concat(aErrmsg, '\n')
					X.Debug(_L['MY_TeamMon_VoiceAlarm'], szErrmsg, X.DEBUG_LEVEL.WARNING)
					reject(X.Error:new(szErrmsg))
					return
				end
				local aSlugGroup, tSlugGroup = {}, {}
				for _, slug in ipairs(res.data) do
					if not tSlugGroup[slug.group] then
						tSlugGroup[slug.group] = {
							bOfficial = not slug.group:find('^jx3box') and not slug.group:find('^extend'),
							szGroupID = slug.group,
							szGroupName = slug.group_name,
						}
						table.insert(aSlugGroup, tSlugGroup[slug.group])
					end
					table.insert(tSlugGroup[slug.group], {
						dwID = slug.id,
						szSlug = slug.slug,
						szRemark = slug.remark,
					})
				end
				D.aSlugGroup = aSlugGroup
				resolve(aSlugGroup)
			end,
		})
	end)
end

function D.GetSlugList(szType)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	local aSlugGroup = {}
	for _, tSlugGroup in ipairs(D.aSlugGroup) do
		if (szType == 'OFFICIAL' and tSlugGroup.bOfficial)
		or szType == 'CUSTOM' then
			table.insert(aSlugGroup, X.Clone(tSlugGroup))
		end
	end
	return aSlugGroup
end

function D.FetchVoiceList(szType)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	return X.Promise:new(function(resolve, reject)
		if szType == 'OFFICIAL' and O.dwOfficialVoicePacketID == 0 then
			reject(X.Error:new(_L['No official voice packet selected.']))
			return
		end
		if szType == 'OFFICIAL' and D.tOfficialPacketInfo
		and D.tOfficialPacketInfo.dwID == O.dwOfficialVoicePacketID then
			resolve(X.Clone(D.tOfficialPacketInfo))
			return
		end
		if szType == 'CUSTOM' and O.dwCustomVoicePacketID == 0 then
			reject(X.Error:new(_L['No custom voice packet selected.']))
			return
		end
		if szType == 'CUSTOM' and D.tCustomPacketInfo
		and D.tCustomPacketInfo.dwID == O.dwCustomVoicePacketID then
			resolve(X.Clone(D.tCustomPacketInfo))
			return
		end
		local dwPacketID = szType == 'OFFICIAL' and O.dwOfficialVoicePacketID or O.dwCustomVoicePacketID
		X.Ajax({
			url = 'https://pull.j3cx.com/api/dbm/game/vpk/voices',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				id = dwPacketID,
			},
			success = function(szHTML)
				local res = X.DecodeJSON(szHTML)
				local errs = X.Schema.CheckSchema(res, VOICE_LIST_JSON_SCHEMA)
				if errs then
					local aErrmsg = {}
					for i, err in ipairs(errs) do
						table.insert(aErrmsg, i .. '. ' .. err.message)
					end
					local szErrmsg = _L['Fetch repo meta list failed.'] .. '\n' .. table.concat(aErrmsg, '\n')
					X.Debug(_L['MY_TeamMon_VoiceAlarm'], szErrmsg, X.DEBUG_LEVEL.WARNING)
					reject(X.Error:new(szErrmsg))
					return
				end
				local aVoice = {}
				for _, info in ipairs(res.data.list) do
					table.insert(aVoice, {
						dwID = info.id,
						szSlug = info.slug,
						szURL = info.filename,
						szGroup = info.group,
						dwCRC = info.crc,
					})
				end
				local tInfo = {
					dwID = res.data.vpk_id,
					szVersion = tostring(res.data.vpk_version),
					aVoice = aVoice,
				}
				local tVoiceCache = {}
				for _, info in ipairs(aVoice) do
					tVoiceCache[info.szSlug] = info
				end
				if szType == 'OFFICIAL' then
					D.tOfficialPacketInfo = tInfo
					D.tOfficialVoiceCache = tVoiceCache
				else
					D.tCustomPacketInfo = tInfo
					D.tCustomVoiceCache = tVoiceCache
				end
				resolve(X.Clone(tInfo))
			end,
			error = function(html, status)
				reject(X.Error:new('Fetch voice list failed: ' .. tostring(status) .. ' ' .. tostring(html)))
			end
		})
	end)
end

function D.DownloadPacket(szType)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	local dwPacketID = szType == 'OFFICIAL' and O.dwOfficialVoicePacketID or O.dwCustomVoicePacketID
	if DOWNLOADER_CACHE[dwPacketID] then
		return DOWNLOADER_CACHE[dwPacketID]
	end
	--[[#DEBUG BEGIN]]
	X.Debug('MY_TeamMon_VoiceAlarm', 'DownloadPacket ' .. szType .. ' ' .. dwPacketID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	DOWNLOADER_CACHE[dwPacketID] = X.ProgressPromise:new(function(resolve, reject, progress)
		D.FetchVoiceList(szType)
			:Then(function(tInfo)
				local aVoice = tInfo.aVoice
				local tProgress = {}
				for _, voice in ipairs(aVoice) do
					tProgress[voice.dwID] = 0
				end
				local function SetProgress(dwID, nProgress)
					tProgress[dwID] = nProgress
					local nTotal = 0
					local nAlready = 0
					for _, n in pairs(tProgress) do
						nTotal = nTotal + 1
						nAlready = nAlready + n
					end
					progress(nAlready / nTotal)
					FireUIEvent('MY_TEAM_MON__VOICE_ALARM__DOWNLOAD_PROGRESS', dwPacketID)
				end
				local szRoot = MY_TEAM_MON_VA_VOICE_ROOT .. dwPacketID .. '/'
				CPath.MakeDir(szRoot)

				--[[#DEBUG BEGIN]]
				X.Debug('MY_TeamMon_VoiceAlarm', 'DownloadPacket ' .. szType .. ' (ID' .. dwPacketID .. ') ' .. #aVoice .. ' voices', X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]

				local function FetchNext()
					local voice = table.remove(aVoice)
					if not voice then
						if szType == 'OFFICIAL' then
							O.szOfficialVoicePacketVersion = tInfo.szVersion
						else
							O.szCustomVoicePacketVersion = tInfo.szVersion
						end
						DOWNLOADER_CACHE[dwPacketID] = nil
						FireUIEvent('MY_TEAM_MON__VOICE_ALARM__DOWNLOAD_PROGRESS', dwPacketID)
						resolve()
						return
					end
					local szKey = voice.dwID
					local szURL = voice.szURL
					local szPath = szRoot .. szKey .. '.ogg'
					if IsLocalFileExist(szPath) and GetFileCRC(szPath) == voice.dwCRC then
						SetProgress(szKey, 1)
						FetchNext()
						return
					end
					--[[#DEBUG BEGIN]]
					X.Debug('MY_TeamMon_VoiceAlarm', 'DownloadPacket Voice ' .. szURL .. ' to ' .. szPath, X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.DownloadFile(szURL, szPath)
						:Then(function()
							SetProgress(szKey, 1)
							FetchNext()
						end)
						:Catch(function(err)
							reject(err)
						end)
						:Progress(function(nTotal, nAlready)
							SetProgress(szKey, nAlready / nTotal)
						end)
				end
				FetchNext()
			end)
			:Catch(function(error)
				--[[#DEBUG BEGIN]]
				X.Debug('MY_TeamMon_VoiceAlarm', 'DownloadPacket ERROR ' .. szType .. ' ' .. dwPacketID .. '\n' .. error.message, X.DEBUG_LEVEL.ERROR)
				--[[#DEBUG END]]
				return X.Promise.Reject(error)
			end)
	end)
	return DOWNLOADER_CACHE[dwPacketID]
end

function D.GetPacketDownloadProgress(dwID)
	local oPromise = DOWNLOADER_CACHE[dwID]
	if oPromise then
		return oPromise.progress or 0
	end
end

function D.PlayVoice(szType, szSlug)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	local tVoiceCache = szType == 'OFFICIAL' and D.tOfficialVoiceCache or D.tCustomVoiceCache
	local dwPacketID = szType == 'OFFICIAL' and O.dwOfficialVoicePacketID or O.dwCustomVoicePacketID
	local voice = tVoiceCache and tVoiceCache[szSlug]
	if not voice or dwPacketID == 0 then
		tVoiceCache = szType ~= 'OFFICIAL' and D.tOfficialVoiceCache or D.tCustomVoiceCache
		dwPacketID = szType ~= 'OFFICIAL' and O.dwOfficialVoicePacketID or O.dwCustomVoicePacketID
		voice = tVoiceCache and tVoiceCache[szSlug]
		if not voice or dwPacketID == 0 then
			--[[#DEBUG BEGIN]]
			X.Debug('MY_TeamMon_VoiceAlarm', 'PlayVoice ERROR ' .. szType .. ' ' .. szSlug .. ' ' .. ' voice not found', X.DEBUG_LEVEL.ERROR)
			--[[#DEBUG END]]
			return
		end
	end
	local szPath = MY_TEAM_MON_VA_VOICE_ROOT .. dwPacketID .. '/' .. voice.dwID .. '.ogg'
	local dwCRC = GetFileCRC(szPath)
	if dwCRC ~= voice.dwCRC then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_TeamMon_VoiceAlarm', 'PlayVoice ERROR ' .. szType .. ' ' .. szSlug .. ' ' .. szPath .. ' CRC mismatch ' .. dwCRC .. ' ~= ' .. voice.dwCRC, X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	X.PlaySound(szPath)
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_VoiceAlarm',
	exports = {
		{
			root = D,
			fields = {
				'FetchPacketList',
				'SetCurrentPacketID',
				'GetCurrentPacketID',
				'GetPacketDownloadProgress',
				'GetSlugList',
				'PlayVoice',
			},
			preset = 'UIEvent'
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_TeamMon_VoiceAlarm = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

X.RegisterInit('MY_TeamMon_VoiceAlarm', function()
	D.FetchSlugList()
	D.FetchVoiceList('OFFICIAL')
	D.FetchVoiceList('CUSTOM')
end)

X.RegisterEvent('MY_TEAM_MON__VOICE_ALARM', 'MY_TeamMon_VoiceAlarm', function()
	D.PlayVoice(arg0 and 'OFFICIAL' or 'CUSTOM', arg1)
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
