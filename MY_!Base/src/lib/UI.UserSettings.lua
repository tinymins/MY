--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 用户设置导入导出界面
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local D = {}
local FRAME_NAME = NSFormatString('{$NS}_UserSettings')

function D.Open(bImport)
	local tSettings = {}
	if bImport then
		local szRoot = LIB.FormatPath({'export/settings', PATH_TYPE.GLOBAL})
		local szPath = GetOpenFileName(_L['Please select import user settings file.'], 'User Settings File(*.us.jx3dat)\0*.us.jx3dat\0\0', szRoot)
		if IsEmpty(szPath) then
			return
		end
		tSettings = LIB.LoadLUAData(szPath, { passphrase = false }) or {}
	end
	Wnd.CloseWindow(FRAME_NAME)
	local W, H = 400, 600
	local uiFrame = UI.CreateFrame(FRAME_NAME, {
		w = W, h = H,
		text = bImport
			and _L['Import User Settings']
			or _L['Export User Settings'],
		esc = true,
	})
	local uiContainer = uiFrame:Append('WndScrollWindowBox', {
		x = 10, y = 50,
		w = W - 20, h = H - 60 - 40,
		containertype = UI.WND_CONTAINER_STYLE.LEFT_TOP,
	})
	local nW = select(2, uiContainer:Width())
	local aGroup, tItemAll = {}, {}
	for _, us in ipairs(LIB.GetRegisterUserSettingsList()) do
		if us.szGroup and us.szLabel and (not bImport or tSettings[us.szKey]) then
			local tGroup = lodash.find(aGroup, function(p) return p.szGroup == us.szGroup end)
			if not tGroup then
				tGroup = {
					szGroup = us.szGroup,
					aItem = {},
				}
				insert(aGroup, tGroup)
			end
			local tItem = lodash.find(tGroup.aItem, function(p) return p.szLabel == us.szLabel end)
			if not tItem then
				tItem = {
					szID = wgsub(LIB.GetUUID(), '-', ''),
					szLabel = us.szLabel,
					aKey = {},
				}
				insert(tGroup.aItem, tItem)
				tItemAll[tItem.szID] = tItem
			end
			insert(tItem.aKey, us.szKey)
		end
	end
	-- 排序
	local tGroupRank = {}
	for i, category in ipairs(LIB.GetPanelCategoryList()) do
		tGroupRank[category.szName] = i
	end
	sort(aGroup, function(g1, g2) return (tGroupRank[g1.szGroup] or HUGE) < (tGroupRank[g2.szGroup] or HUGE) end)
	-- 绘制
	local tItemChecked = {}
	for _, tGroup in ipairs(aGroup) do
		local uiGroupChk, tUiItemChk = nil, {}
		local function UpdateCheckboxState()
			local bCheckAll = true
			for _, tItem in ipairs(tGroup.aItem) do
				local bCheck = tItemChecked[tItem.szID]
				if not bCheck then
					bCheckAll = false
				end
				tUiItemChk[tItem.szID]:Check(bCheck, WNDEVENT_FIRETYPE.PREVENT)
			end
			uiGroupChk:Check(bCheckAll, WNDEVENT_FIRETYPE.PREVENT)
		end
		uiGroupChk = uiContainer:Append('WndWindow', { w = nW, h = 30 })
			:Append('WndCheckBox', {
				w = nW,
				text = tGroup.szGroup,
				color = {255, 255, 0},
				checked = true,
				oncheck = function (bCheck)
					for _, tItem in ipairs(tGroup.aItem) do
						tItemChecked[tItem.szID] = bCheck
					end
					UpdateCheckboxState()
				end,
			})
		for _, tItem in ipairs(tGroup.aItem) do
			tUiItemChk[tItem.szID] = uiContainer:Append('WndWindow', { w = nW / 3, h = 30 })
				:Append('WndCheckBox', {
					x = 0, w = nW / 3,
					text = tItem.szLabel,
					checked = true,
					oncheck = function(bCheck)
						tItemChecked[tItem.szID] = bCheck
						UpdateCheckboxState()
					end,
				})
			tItemChecked[tItem.szID] = true
		end
		uiContainer:Append('WndWindow', { w = nW, h = 10 })
	end
	uiFrame:Append('WndButtonBox', {
		x = (W - 200) / 2, y = H - 40,
		w = 200, h = 25,
		buttonstyle = 'FLAT',
		text = bImport and _L['Import'] or _L['Export'],
		onclick = function()
			local aKey, tKvp = {}, {}
			for szID, bCheck in pairs(tItemChecked) do
				if bCheck then
					local tItem = tItemAll[szID]
					for _, szKey in ipairs(tItem.aKey) do
						insert(aKey, szKey)
						tKvp[szKey] = tSettings[szKey]
					end
				end
			end
			if bImport then
				local nSuccess = LIB.ImportUserSettings(tKvp)
				LIB.Systopmsg(_L('%d settings imported.', nSuccess))
			else
				if #aKey == 0 then
					LIB.Systopmsg(_L['No custom setting selected, nothing to export.'], CONSTANT.MSG_THEME.ERROR)
					return
				end
				tKvp = LIB.ExportUserSettings(aKey)
				local nExport = lodash.size(tKvp)
				if nExport == 0 then
					LIB.Systopmsg(_L['No custom setting found, nothing to export.'], CONSTANT.MSG_THEME.ERROR)
					return
				end
				local szPath = LIB.FormatPath({'export/settings/' .. LIB.GetUserRoleName() .. '_' .. LIB.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss') .. '.us.jx3dat', PATH_TYPE.GLOBAL})
				LIB.SaveLUAData(szPath, tKvp, { compress = false, crc = false, passphrase = false })
				LIB.Systopmsg(_L('%d settings exported, file saved in %s.', nExport, szPath))
			end
			uiFrame:Remove()
		end,
	})
	uiFrame:Anchor('CENTER')
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Open',
			},
			root = D,
		},
	},
}
_G[FRAME_NAME] = LIB.CreateModule(settings)
end

function LIB.OpenUserSettingsExportPanel()
	D.Open()
end

function LIB.OpenUserSettingsImportPanel()
	D.Open(true)
end
