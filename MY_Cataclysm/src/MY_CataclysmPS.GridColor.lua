--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板格子颜色
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Cataclysm/lang/')
local CFG, PS = MY_Cataclysm.CFG, {}
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR, font = 27 }, true):height()

	x = x + 10
	y = y + 5
	x = x + ui:append('WndRadioBox', {
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
			MY.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):autoWidth():width()

	x = x + ui:append('WndRadioBox', {
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
			MY.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndRadioBox', {
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
			MY.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndRadioBox', {
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
			MY.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_DISTANCE,
		checked = CFG.bEnableDistance,
		oncheck = function(bCheck)
			CFG.bEnableDistance = bCheck
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
			MY.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}, true):autoWidth():height() + 5

	-- 设置分段距离等级
	x = X + 10
	if CFG.bEnableDistance then
		y = y + ui:append('WndButton3', {
			x = x, y = y, text = _L['Edit Distance Level'],
			onclick = function()
				GetUserInput(_L['distance, distance, ...'], function(szText)
					local t = MY.SplitString(MY.TrimString(szText), ',')
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
						MY.SwitchTab('MY_Cataclysm_GridColor', true)
					end
				end)
			end,
		}, true):height()
	end

	-- 统一背景
	if not CFG.bEnableDistance
	or CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR then
		x = X + 20
		ui:append('Text', { x = x, y = y, text = g_tStrings.BACK_COLOR }):autoWidth()
		x = 280
		x = x + ui:append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = CFG.tDistanceCol[1],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tDistanceCol[1] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):color(r, g, b)
				end)
			end,
		}, true):width() + 5
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
			ui:append('Text', { x = x, y = y, text = text }):autoWidth()
			local x = 280
			if CFG.nBGColorMode == CTM_BG_COLOR_MODE.BY_DISTANCE then
				x = x + ui:append('Shadow', {
					w = 22, h = 22, x = x, y = y + 3, color = CFG.tDistanceCol[i],
					onclick = function()
						local this = this
						UI.OpenColorPicker(function(r, g, b)
							CFG.tDistanceCol[i] = { r, g, b }
							if MY_Cataclysm.GetFrame() then
								MY_CataclysmParty:CallDrawHPMP(true, true)
							end
							UI(this):color(r, g, b)
						end)
					end,
				}, true):width() + 5
			else
				x = x + ui:append('WndSliderBox', {
					x = x, y = y + 3, h = 22,
					range = {0, 255},
					value = CFG.tDistanceAlpha[i],
					sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
					onchange = function(val)
						CFG.tDistanceAlpha[i] = val
						if MY_Cataclysm.GetFrame() then
							MY_CataclysmParty:CallDrawHPMP(true, true)
						end
					end,
					textfmt = function(val) return _L('Alpha: %d.', val) end,
				}, true):width() + 5
			end
			y = y + 30
		end
	end

	-- 出同步范围背景
	x = X + 20
	ui:append('Text', {
		x = x, y = y,
		text = CFG.bEnableDistance
			and _L('More than %d meter', CFG.tDistanceLevel[#CFG.tDistanceLevel])
			or g_tStrings.STR_RAID_DISTANCE_M4,
	}):autoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_FORCE
	and CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3,
			color = CFG.tOtherCol[3],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tOtherCol[3] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):color(r, g, b)
				end)
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:append('WndSliderBox', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = CFG.tOtherAlpha[3],
			sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
			onchange = function(val)
				CFG.tOtherAlpha[3] = val
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):width() + 5
	end
	y = y + 30

	-- 离线背景
	x = X + 20
	ui:append('Text', { x = x, y = y, text = g_tStrings.STR_GUILD_OFFLINE .. g_tStrings.BACK_COLOR }, true):autoWidth()
	x = 280
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:append('Shadow', {
			w = 22, h = 22, x = x, y = y + 3, color = CFG.tOtherCol[2],
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tOtherCol[2] = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):color(r, g, b)
				end)
			end,
		}, true):width() + 5
	end
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.BY_DISTANCE then
		x = x + ui:append('WndSliderBox', {
			x = x, y = y + 3, h = 22,
			range = {0, 255},
			value = CFG.tOtherAlpha[2],
			sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
			onchange = function(val)
				CFG.tOtherAlpha[2] = val
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
			textfmt = function(val) return _L('Alpha: %d.', val) end,
		}, true):width() + 5
	end
	y = y + 30

	-- 内力
	x = X + 20
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		ui:append('Text', { x = x, y = y, text = g_tStrings.STR_SKILL_MANA .. g_tStrings.BACK_COLOR }, true):autoWidth()
		y = y + ui:append('Shadow', {
			w = 22, h = 22, x = 280, y = y + 3, color = CFG.tManaColor,
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					CFG.tManaColor = { r, g, b }
					if MY_Cataclysm.GetFrame() then
						MY_CataclysmParty:CallDrawHPMP(true, true)
					end
					UI(this):color(r, g, b)
				end)
			end,
		}, true):height() + 5
	end

	-- 血条蓝条渐变色
	x = X + 10
	y = y + 5
	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:append('WndCheckBox', {
			x = x, y = y, text = _L['LifeBar Gradient'],
			checked = CFG.bLifeGradient,
			oncheck = function(bCheck)
				CFG.bLifeGradient = bCheck
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}, true):autoWidth():width() + 5

		x = x + ui:append('WndCheckBox', {
			x = x, y = y, text = _L['ManaBar Gradient'],
			checked = CFG.bManaGradient,
			oncheck = function(bCheck)
				CFG.bManaGradient = bCheck
				if MY_Cataclysm.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}, true):autoWidth():width() + 5
	end
end
MY.RegisterPanel('MY_Cataclysm_GridColor', _L['Grid Color'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|71', {255, 255, 0}, PS)
