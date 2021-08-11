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
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 3 }
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY

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
			X.SwitchTab('MY_Cataclysm_GridColor', true)
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
			X.SwitchTab('MY_Cataclysm_GridColor', true)
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
			X.SwitchTab('MY_Cataclysm_GridColor', true)
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
			X.SwitchTab('MY_Cataclysm_GridColor', true)
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
			X.SwitchTab('MY_Cataclysm_GridColor', true)
		end,
	}):AutoWidth():Height() + 5

	-- 设置分段距离等级
	x = nPaddingX + 10
	if CFG.bEnableDistance then
		y = y + ui:Append('WndButton', {
			x = x, y = y, w = 150, h = 35,
			text = _L['Edit Distance Level'],
			buttonstyle = 'SKEUOMORPHISM_LACE_BORDER',
			onclick = function()
				GetUserInput(_L['distance, distance, ...'], function(szText)
					local t = X.SplitString(X.TrimString(szText), ',')
					local tt = {}
					for k, v in ipairs(t) do
						if not tonumber(v) then
							table.remove(t, k)
						else
							table.insert(tt, tonumber(v))
						end
					end
					if #t > 0 then
						tDistanceLevel = tt
						for i = 1, #t do
							table.insert(tDistanceCol, CFG.tDistanceCol[i] or { 255, 255, 255 })
							table.insert(tDistanceAlpha, CFG.tDistanceAlpha[i] or 255)
						end
						CFG.tDistanceLevel = tDistanceLevel
						CFG.tDistanceCol = tDistanceCol
						CFG.tDistanceAlpha = tDistanceAlpha
						X.SwitchTab('MY_Cataclysm_GridColor', true)
					end
				end)
			end,
		}):Height()
	end

	-- 统一背景
	if not CFG.bEnableDistance
	or CFG.nBGColorMode == CTM_BG_COLOR_MODE.SAME_COLOR then
		x = nPaddingX + 20
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
		x = nPaddingX + 20
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
	x = nPaddingX + 20
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
	x = nPaddingX + 20
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
	x = nPaddingX + 20
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
	x = nPaddingX + 10
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
X.RegisterPanel(_L['Raid'], 'MY_Cataclysm_GridColor', _L['Grid Color'], 'ui/Image/UICommon/RaidTotal.uitex|71', PS)
