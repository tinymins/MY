--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板格子颜色
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2012800) then
	return
end
local CFG, PS = MY_Cataclysm.CFG, {}
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR, font = 27 }, true):Height()

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
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):AutoWidth():Width()

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Colored all the same'],
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.SAME_COLOR
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):AutoWidth():Width() + 5

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Colored according to the distance'],
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_DISTANCE,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.BY_DISTANCE
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):AutoWidth():Width() + 5

	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		group = 'BACK_COLOR', checked = CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_FORCE,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nBGColorMode = CTM_BG_COLOR_MODE.BY_FORCE
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):AutoWidth():Width() + 5

	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_DISTANCE,
		checked = CFG.bEnableDistance,
		oncheck = function(bCheck)
			CFG.bEnableDistance = bCheck
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			LIB.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):AutoWidth():Height() + 5

	-- 设置分段距离等级
	x = X + 10
	if CFG.bEnableDistance then
		y = y + ui:Append('WndButton3', {
			x = x, y = y, text = _L['Edit Distance Level'],
			onclick = function()
				GetUserInput(_L['distance, distance, ...'], function(szText)
					local t = LIB.SplitString(LIB.TrimString(szText), ',')
					local tt = {}
					for k, v in ipairs(t) do
						if not tonumber(v) then
							table.remove(t, k)
						else
							table.insert(tt, tonumber(v))
						end
					end
					if #t > 0 then
						local tDistanceCol = CFG.tDistanceCol
						local tDistanceAlpha = CFG.tDistanceAlpha
						CFG.tDistanceLevel = tt
						CFG.tDistanceCol = {}
						CFG.tDistanceAlpha = {}
						for i = 1, #t do
							table.insert(CFG.tDistanceCol, tDistanceCol[i] or { 255, 255, 255 })
							table.insert(CFG.tDistanceAlpha, tDistanceAlpha[i] or 255)
						end
						LIB.SwitchTab('MY_Cataclysm_GridColor', true)
					end
				end)
			end,
		}, true):Height()
	end

	-- 统一背景
	if not CFG.bEnableDistance
	or CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR then
		x = X + 20
		ui:Append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR }):AutoWidth()
		x = 280
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = CFG.tDistanceCol[1],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tDistanceCol[1] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):Color(r, g, b)
				end)
			end,
		}, true):Width() + 5
		y = y + 30
	end

	-- 分段距离背景
	if CFG.bEnableDistance then
		x = X + 20
		for i = 1, #CFG.tDistanceLevel do
			local n = CFG.tDistanceLevel[i - 1] or 0
			local text = n .. g_tStrings.STR_METER .. ' - '
				.. CFG.tDistanceLevel[i]
				.. g_tStrings.STR_METER .. g_tStrings.BACK_COLOR
			ui:Append('Text', { x = x, y = y, text = text }):AutoWidth()
			local x = 280
			if CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_DISTANCE then
				x = x + ui:Append('Shadow', {
					w = 22, h = 22, x = x, y = y + 3, color = CFG.tDistanceCol[i],
					onclick = function()
						local this = this
						UI.OpenColorPicker(function(r, g, b)
							CFG.tDistanceCol[i] = { r, g, b }
							if MY_Cataclysm.GetFrame() then
								MY_CataclysmParty:CallDrawHPMP(true, true)
							end
							UI(this):Color(r, g, b)
						end)
					end,
				}, true):Width() + 5
			else
				x = x + ui:Append('WndTrackbar', {
					x = x, y = y + 3, h = 22,
					range = {0, 255},
					value = CFG.tDistanceAlpha[i],
					trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
					onchange = function(val)
						CFG.tDistanceAlpha[i] = val
						if MY_Cataclysm.GetFrame() then
							MY_CataclysmParty:CallDrawHPMP(true, true)
						end
					end,
					textfmt = function(val) return _L('Alpha: %d.', val) end,
				}, true):Width() + 5
			end
			y = y + 30
		end
	end

	-- 出同步范围背景
	x = X + 20
	ui:Append('Text', {
		x = x, y = y,
		text = CFG.bEnableDistance
			and _L('More than %d meter', CFG.tDistanceLevel[#CFG.tDistanceLevel])
			or g_tStrings.STR_RAID_DISTANCE_M4,
	}):AutoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_FORCE
	and CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3,
			color = CFG.tOtherCol[3],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tOtherCol[3] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):Color(r, g, b)
				end)
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):Width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:Append('WndTrackbar', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = CFG.tOtherAlpha[3],
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val)
				CFG.tOtherAlpha[3] = val
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):Width() + 5
	end
	y = y + 30

	-- 离线背景
	x = X + 20
	ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_GUILD_OFFLINE .. g_tStrings.BACK_COLOR }, true):AutoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = CFG.tOtherCol[2],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tOtherCol[2] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):Color(r, g, b)
				end)
			end,
		}, true):Width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:Append('WndTrackbar', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = CFG.tOtherAlpha[2],
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val)
				CFG.tOtherAlpha[2] = val
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):Width() + 5
	end
	y = y + 30

	-- 内力
	x = X + 20
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_SKILL_MANA .. g_tStrings.BACK_COLOR }, true):AutoWidth()
		y = y + ui:Append('Shadow', {
			w = 22, h = 22, x = 280, y = y + 3, color = CFG.tManaColor,
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tManaColor = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):Color(r, g, b)
				end)
			end,
		}, true):Height() + 5
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
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}, true):AutoWidth():Width() + 5

		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, text = _L['ManaBar Gradient'],
			checked = CFG.bManaGradient,
			oncheck = function(bCheck)
				CFG.bManaGradient = bCheck
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}, true):AutoWidth():Width() + 5
	end
end
LIB.RegisterPanel('MY_Cataclysm_GridColor', _L['Grid Color'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|71', PS)
