--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队面板格子样式
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Cataclysm/MY_CataclysmPS.GridStyle'
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 2 }

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY

	y = y + ui:Append('Text', { x = x, y = y, text = _L['Grid Style'], font = 27 }):Height()

	y = y + 5

	x = nPaddingX + 10
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show AllGrid'],
		checked = CFG.bShowAllGrid,
		onCheck = function(bCheck)
			CFG.bShowAllGrid = bCheck
			MY_CataclysmMain.ReloadCataclysmPanel()
		end,
	}):AutoWidth():Height() + 5

	x = nPaddingX
	y = y + 10

	-- 名字、图标、内力和血量显示方案
	x = nPaddingX
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Name/Icon/Mana/Life Display'], font = 27 }):Height()

	-- 名字
	x = nPaddingX + 10
	y = y + 5
	for _, p in ipairs({
		{ 1, _L['Name colored by force'] },
		{ 2, _L['Name colored by camp'] },
		{ 0, _L['Name without color'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namecolor', checked = CFG.nColoredName == p[1],
			onCheck = function()
				CFG.nColoredName = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, false, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true ,true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	y = y + ui:Append('WndSlider', {
		x = x, y = y - 1,
		value = CFG.fNameFontScale * 100,
		range = {1, 400},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		textFormatter = function(val) return _L('Scale %d%%', val) end,
		onChange = function(val)
			CFG.fNameFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallRefreshImages(nil, nil, nil, nil, true)
			end
		end,
	}):Height()

	x = nPaddingX + 10
	for _, p in ipairs({
		{ 0, _L['Top'] },
		{ 1, _L['Middle'] },
		{ 2, _L['Bottom'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namevali', checked = CFG.nNameVAlignment == p[1],
			onCheck = function()
				CFG.nNameVAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	for _, p in ipairs({
		{ 0, _L['Left'] },
		{ 1, _L['Center'] },
		{ 2, _L['Right'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namehali', checked = CFG.nNameHAlignment == p[1],
			onCheck = function()
				CFG.nNameHAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	-- 名字字体修改
	x = x + ui:Append('WndButton', {
		x = x, y = y, h = 24,
		text = _L['Name font'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				CFG.nNameFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, false, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
	}):AutoWidth():Width() + 5
	y = y + 25

	-- 血量显示方式
	x = nPaddingX + 10
	y = y + 10
	for _, p in ipairs({
		{ 2, g_tStrings.STR_RAID_LIFE_LEFT },
		{ 1, g_tStrings.STR_RAID_LIFE_LOSE },
		{ 0, g_tStrings.STR_RAID_LIFE_HIDE },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifemode', checked = CFG.nHPShownMode2 == p[1],
			onCheck = function()
				CFG.nHPShownMode2 = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	ui:Append('WndSlider', {
		x = x, y = y - 1,
		value = CFG.fLifeFontScale * 100,
		range = {1, 400},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		textFormatter = function(val) return _L('Scale %d%%', val) end,
		onChange = function(val)
			CFG.fLifeFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
		autoEnable = function() return CFG.nHPShownMode2 ~= 0 end,
	})
	y = y + 25

	-- 血量数值显示方案
	x = nPaddingX + 10
	for _, p in ipairs({
		{ 1, _L['Show Format value'] },
		{ 2, _L['Show Percentage value'] },
		{ 3, _L['Show full value'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifval', checked = CFG.nHPShownNumMode == p[1],
			autoEnable = function() return CFG.nHPShownMode2 ~= 0 end,
			onCheck = function()
				CFG.nHPShownNumMode = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Decimal'],
		checked = CFG.bShowHPDecimal,
		onCheck = function(bCheck)
			CFG.bShowHPDecimal = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5
	y = y + 25

	x = nPaddingX + 10
	for _, p in ipairs({
		{ 0, _L['Top'] },
		{ 1, _L['Middle'] },
		{ 2, _L['Bottom'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifvali', checked = CFG.nHPVAlignment == p[1],
			autoEnable = function() return CFG.nHPShownMode2 ~= 0 end,
			onCheck = function()
				CFG.nHPVAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	for _, p in ipairs({
		{ 0, _L['Left'] },
		{ 1, _L['Center'] },
		{ 2, _L['Right'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifhali', checked = CFG.nHPHAlignment == p[1],
			autoEnable = function() return CFG.nHPShownMode2 ~= 0 end,
			onCheck = function()
				CFG.nHPHAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	ui:Append('WndButton', {
		x = x, y = y, h = 24,
		text = _L['Life font'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				CFG.nLifeFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoEnable = function() return CFG.nHPShownMode2 ~= 0 end,
	}):AutoWidth()
	y = y + 25

	-- 图标显示方案
	x = nPaddingX + 10
	y = y + 10
	for _, p in ipairs({
		{ 1, _L['Show Force Icon'] },
		{ 2, g_tStrings.STR_SHOW_KUNGFU },
		{ 3, _L['Show Camp Icon'] },
		{ 4, _L['Show Text Force'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'icon', checked = CFG.nShowIcon == p[1],
			onCheck = function()
				CFG.nShowIcon = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end
	y = y + 25

	-- 内力显示
	x = nPaddingX + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show ManaCount'],
		checked = CFG.nShowMP,
		onCheck = function(bCheck)
			CFG.nShowMP = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndButton', {
		x = x, y = y, h = 24,
		text = g_tStrings.STR_SKILL_MANA .. g_tStrings.FONT,
		buttonStyle = 'FLAT',
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				CFG.nManaFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoEnable = function() return CFG.nShowMP end,
	}):Width() + 5

	ui:Append('WndSlider', {
		x = x, y = y - 1,
		value = CFG.fManaFontScale * 100,
		range = {1, 400},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		textFormatter = function(val) return _L('Scale %d%%', val) end,
		onChange = function(val)
			CFG.fManaFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
		autoEnable = function() return CFG.nShowMP end,
	})
	y = y + 25
end
X.Panel.Register(_L['Raid'], 'MY_Cataclysm_GridStyle', _L['Grid Style'], 'ui/Image/UICommon/RaidTotal.uitex|68', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
