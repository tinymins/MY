--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板格子颜色
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 3 }
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	local tDistanceLevel = CFG.tDistanceLevel
	local tDistanceCol = CFG.tDistanceCol
	local tDistanceAlpha = CFG.tDistanceAlpha
	local tOtherCol = CFG.tOtherCol
	local tOtherAlpha = CFG.tOtherAlpha
	local tManaColor = CFG.tManaColor

	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR, font = 27 }):Height()

	x = x + 10
	y = y + 5
	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Colored as official team frame'],
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.OFFICIAL,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.OFFICIAL
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Width()

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Colored all the same'],
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.SAME_COLOR
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Colored according to the distance'],
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_DISTANCE,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.BY_DISTANCE
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_FORCE,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.BY_FORCE
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Width() + 5

	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_DISTANCE,
		checked = CFG.bEnableDistance,
		oncheck = function(bCheck)
			CFG.bEnableDistance = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Height() + 5

	-- 设置分段距离等级
	x = X + 10
	if CFG.bEnableDistance then
		y = y + ui:Append('WndButton', {
			x = x, y = y, w = 150, h = 35,
			text = _L['Edit Distance Level'],
			buttonstyle = 'SKEUOMORPHISM_LACE_BORDER',
			onclick = function()
				GetUserInput(_L['distance, distance, ...'], function(szText)
					local t = LIB.SplitString(LIB.TrimString(szText), ',')
					local tt = {}
					for k, v in ipairs(t) do
						if not tonumber(v) then
							remove(t, k)
						else
							insert(tt, tonumber(v))
						end
					end
					if #t > 0 then
						tDistanceLevel = tt
						for i = 1, #t do
							insert(tDistanceCol, CFG.tDistanceCol[i] or { 255, 255, 255 })
							insert(tDistanceAlpha, CFG.tDistanceAlpha[i] or 255)
						end
						CFG.tDistanceLevel = tDistanceLevel
						CFG.tDistanceCol = tDistanceCol
						CFG.tDistanceAlpha = tDistanceAlpha
						LIB.SwitchTab('MY_Cataclysm_GridColor', true)
					end
				end)
			end,
		}):Height()
	end

	-- 统一背景
	if not CFG.bEnableDistance
	or CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR then
		x = X + 20
		ui:Append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR }):AutoWidth()
		x = 280
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = tDistanceCol[1],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					tDistanceCol[1] = { r, g, b }
					if MY_CataclysmMain.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					CFG.tDistanceCol = tDistanceCol
					UI(this):Color(r, g, b)
				end)
			end,
		}):Width() + 5
		y = y + 30
	end

	-- 分段距离背景
	if CFG.bEnableDistance then
		x = X + 20
		for i = 1, #tDistanceLevel do
			local n = tDistanceLevel[i - 1] or 0
			local text = n .. g_tStrings.STR_METER .. ' - '
				.. tDistanceLevel[i]
				.. g_tStrings.STR_METER .. g_tStrings.BACK_COLOR
			ui:Append('Text', { x = x, y = y, text = text }):AutoWidth()
			local x = 280
			if CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_DISTANCE then
				x = x + ui:Append('Shadow', {
					w = 22, h = 22, x = x, y = y + 3, color = tDistanceCol[i],
					onclick = function()
						local this = this
						UI.OpenColorPicker(function(r, g, b)
							tDistanceCol[i] = { r, g, b }
							if MY_CataclysmMain.GetFrame() then
								MY_CataclysmParty:CallDrawHPMP(true, true)
							end
							CFG.tDistanceCol = tDistanceCol
							UI(this):Color(r, g, b)
						end)
					end,
				}):Width() + 5
			else
				x = x + ui:Append('WndTrackbar', {
					x = x, y = y + 3, h = 22,
					range = {0, 255},
					value = tDistanceAlpha[i],
					trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
					onchange = function(val)
						tDistanceAlpha[i] = val
						if MY_CataclysmMain.GetFrame() then
							MY_CataclysmParty:CallDrawHPMP(true, true)
						end
						CFG.tDistanceAlpha = tDistanceAlpha
					end,
					textfmt = function(val) return _L('Alpha: %d.', val) end,
				}):Width() + 5
			end
			y = y + 30
		end
	end

	-- 出同步范围背景
	x = X + 20
	ui:Append('Text', {
		x = x, y = y,
		text = CFG.bEnableDistance
			and _L('More than %d meter', tDistanceLevel[#tDistanceLevel])
			or g_tStrings.STR_RAID_DISTANCE_M4,
	}):AutoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_FORCE
	and CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3,
			color = tOtherCol[3],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					tOtherCol[3] = { r, g, b }
					if MY_CataclysmMain.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					CFG.tOtherCol = tOtherCol
					UI(this):Color(r, g, b)
				end)
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}):Width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:Append('WndTrackbar', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = tOtherAlpha[3],
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val)
				tOtherAlpha[3] = val
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
				CFG.tOtherAlpha = tOtherAlpha
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}):Width() + 5
	end
	y = y + 30

	-- 离线背景
	x = X + 20
	ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_GUILD_OFFLINE .. g_tStrings.BACK_COLOR }):AutoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = tOtherCol[2],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					tOtherCol[2] = { r, g, b }
					if MY_CataclysmMain.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					CFG.tOtherCol = tOtherCol
					UI(this):Color(r, g, b)
				end)
			end,
		}):Width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:Append('WndTrackbar', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = tOtherAlpha[2],
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val)
				tOtherAlpha[2] = val
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
				CFG.tOtherAlpha = tOtherAlpha
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}):Width() + 5
	end
	y = y + 30

	-- 内力
	x = X + 20
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_SKILL_MANA .. g_tStrings.BACK_COLOR }):AutoWidth()
		y = y + ui:Append('Shadow', {
			w = 22, h = 22, x = 280, y = y + 3, color = tManaColor,
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					tManaColor = { r, g, b }
					if MY_CataclysmMain.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					CFG.tManaColor = tManaColor
					UI(this):Color(r, g, b)
				end)
			end,
		}):Height() + 5
	end

	-- 血条蓝条渐变色
	x = X + 10
	y = y + 5
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, text = _L['LifeBar Gradient'],
			checked = CFG.bLifeGradient,
			oncheck = function(bCheck)
				CFG.bLifeGradient = bCheck
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5

		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, text = _L['ManaBar Gradient'],
			checked = CFG.bManaGradient,
			oncheck = function(bCheck)
				CFG.bManaGradient = bCheck
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end
end
LIB.RegisterPanel(_L['Raid'], 'MY_Cataclysm_GridColor', _L['Grid Color'], 'ui/Image/UICommon/RaidTotal.uitex|71', PS)
