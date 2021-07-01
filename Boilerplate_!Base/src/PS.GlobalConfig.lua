--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 全局杂项设置
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
local LIB = Boilerplate
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local W, H = ui:Size()
	local X, Y, LH = 20, 20, 30
	local nX, nY, nLFY = X, Y, Y

	ui:Append('Text', {
		x = X - 10, y = nY,
		text = _L['Distance type'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nX, nY = X, nY + 30

	for _, p in ipairs(LIB.GetDistanceTypeList()) do
		nX = nX + ui:Append('WndRadioBox', {
			x = nX, y = nY, w = 100, h = 25, group = 'distance type',
			text = p.szText,
			checked = LIB.GetGlobalDistanceType() == p.szType,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				LIB.SetGlobalDistanceType(p.szType)
			end,
		}):AutoWidth():Width() + 10
	end
	nX, nY = X, nY + 30
	nLFY = nY

	local Notify = _G[NSFormatString('{$NS}_Notify')]
	if Notify then
		nX, nY, nLFY = Notify.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	end

	local HoverEntry = _G[NSFormatString('{$NS}_HoverEntry')]
	if HoverEntry then
		nX, nY, nLFY = HoverEntry.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	end

	ui:Append('Text', {
		x = X - 10, y = nY,
		text = _L['User Settings'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nX, nY = X, nY + 30

	nX = nX + ui:Append('WndButtonBox', {
		x = nX, y = nY,
		text = _L['Export data'],
		onclick = function()
			LIB.OpenUserSettingsExportPanel()
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButtonBox', {
		x = nX, y = nY,
		text = _L['Import data'],
		onclick = function()
			LIB.OpenUserSettingsImportPanel()
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY,
		text = _L['Use preset user settings'],
		menu = function()
			local szCurrentID = LIB.GetUserSettingsPresetID()
			local szDefaultID = LIB.GetUserSettingsPresetID(true)
			local menu = {
				{
					szOption = _L['Role original user settings'],
					fnAction = function()
						LIB.SetUserSettingsPresetID('')
						UI.ClosePopupMenu()
						LIB.SwitchTab('GlobalConfig', true)
					end,
					bCheck = true, bChecked = szCurrentID == '',
					{
						szOption = _L['Set default preset'],
						fnAction = function()
							LIB.SetUserSettingsPresetID('', true)
							UI.ClosePopupMenu()
							LIB.SwitchTab('GlobalConfig', true)
						end,
						bCheck = true, bChecked = szDefaultID == '',
					},
				},
				CONSTANT.MENU_DIVIDER,
			}
			local aPresetID = LIB.GetUserSettingsPresetList()
			if not IsEmpty(aPresetID) then
				insert(menu, { szOption = _L['Preset list'], bDisable = true })
				for _, szID in ipairs(aPresetID) do
					local m = {
						szOption = szID,
						fnAction = function()
							LIB.SetUserSettingsPresetID(szID)
							UI.ClosePopupMenu()
							LIB.SwitchTab('GlobalConfig', true)
						end,
						bCheck = true, bChecked = szCurrentID == szID,
						{
							szOption = _L['Set default preset'],
							fnAction = function()
								LIB.SetUserSettingsPresetID(szID, true)
								UI.ClosePopupMenu()
								LIB.SwitchTab('GlobalConfig', true)
							end,
							bCheck = true, bChecked = szDefaultID == szID,
						},
					}
					if not m.bChecked then
						insert(m,
						{
							szOption = _L['Delete'],
							fnAction = function()
								LIB.RemoveUserSettingsPreset(szID)
								UI.ClosePopupMenu()
							end,
						})
					end
					insert(menu, m)
				end
				insert(menu, CONSTANT.MENU_DIVIDER)
			end
			insert(menu, {
				szOption = _L['* New *'],
				fnAction = function()
					GetUserInput(
						_L['Please input preset id:'],
						function(szText)
							local szErrmsg = LIB.SetUserSettingsPresetID(szText)
							if szErrmsg then
								LIB.Systopmsg(szErrmsg, CONSTANT.MSG_THEME.ERROR)
								LIB.Alert(szErrmsg)
							end
						end,
						nil, nil, nil, 'common')
				end,
			})
			return menu
		end,
	}):AutoWidth():Width() + 5
	nX, nY = X, nY + 30

	ui:Append('Text', {
		x = X - 10, y = nY,
		text = _L['System Info'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nY = nY + 30

	local uiMemory = ui:Append('Text', {
		x = nX, y = nY, w = 150,
		alpha = 150, font = 162,
	})
	nY = nY + 25

	local uiSize = ui:Append('Text', {
		x = nX, y = nY, w = 150,
		alpha = 150, font = 162,
	})
	nY = nY + 25

	local uiUIScale = ui:Append('Text', {
		x = nX, y = nY, w = 150,
		alpha = 150, font = 162,
	})
	nY = nY + 25

	local uiFontScale = ui:Append('Text', {
		x = nX, y = nY, w = 150,
		alpha = 150, font = 162,
	})
	nY = nY + 25

	local function onRefresh()
		uiMemory:Text(format('Memory: %.2fMB', collectgarbage('count') / 1024))
		uiSize:Text(format('UISize: %.2fx%.2f', Station.GetClientSize()))
		uiUIScale:Text(format('UIScale: %.2f (%.2f)', LIB.GetUIScale(), LIB.GetOriginUIScale()))
		uiFontScale:Text(format('FontScale: %.2f (%.2f)', LIB.GetFontScale(), Font.GetOffset()))
	end
	onRefresh()
	LIB.BreatheCall('GlobalConfig', onRefresh)
end

function PS.OnPanelDeactive()
	LIB.BreatheCall('GlobalConfig', false)
end

LIB.RegisterPanel(_L['System'], 'GlobalConfig', _L['GlobalConfig'], 'ui\\Image\\Minimap\\Minimap.UITex|181', PS)
