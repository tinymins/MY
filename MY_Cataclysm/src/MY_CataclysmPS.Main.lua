
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random = math.huge, math.pi, math.random
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local IsNil, IsBoolean, IsEmpty, RandomChild = MY.IsNil, MY.IsBoolean, MY.IsEmpty, MY.RandomChild
local IsNumber, IsString, IsTable, IsFunction = MY.IsNumber, MY.IsString, MY.IsTable, MY.IsFunction
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Cataclysm/lang/')
local CFG, PS = MY_Cataclysm.CFG, {}

function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	x = X
	y = y + ui:append('Text', { x = x, y = y, text = _L['configure'], font = 27 }, true):height()

	x = X + 10
	x = x + ui:append('Text', { x = x, y = y, text = _L['Configuration name'] }, true):autoWidth():width() + 5

	x = x + ui:append('WndEditBox', {
		x = x, y = y + 3, w = 200, h = 25,
		text = MY_Cataclysm.szConfigName,
		onchange = function(txt)
			MY_Cataclysm.SetConfigureName(txt)
		end,
		onblur = function()
			MY_Cataclysm.CheckEnableTeamPanel()
			MY.SwitchTab('MY_Cataclysm', true)
		end,
	}, true):width() + 5

	-- 恢复默认
	y = y + ui:append('WndButton2', {
		x = x, y = y + 3, text = _L['Restore default'],
		onclick = function()
			MY_Cataclysm.ConfirmRestoreConfig()
		end,
	}, true):height() + 20

	x = X
	y = y + ui:append('Text', { x = x, y = y, text = _L['Cataclysm Team Panel'], font = 27 }, true):autoWidth():height()

	x = x + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Enable Cataclysm Team Panel'],
		oncheck = MY_Cataclysm.ToggleTeamPanel, checked = MY_Cataclysm.bEnable,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Only in team'],
		checked = CFG.bShowInRaid,
		oncheck = function(bCheck)
			CFG.bShowInRaid = bCheck
			if MY_Cataclysm.CheckCataclysmEnable() then
				MY_Cataclysm.ReloadCataclysmPanel()
			end
			local me = GetClientPlayer()
			if me.IsInParty() and not me.IsInRaid() then
				FireUIEvent('CTM_PANEL_TEAMATE', CFG.bShowInRaid)
			end
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.WINDOW_LOCK,
		checked = not CFG.bDrag,
		oncheck = function(bCheck)
			CFG.bDrag = not bCheck
			if MY_Cataclysm.GetFrame() then
				MY_Cataclysm.GetFrame():EnableDrag(not bCheck)
			end
		end,
	}, true):autoWidth():height() + 5

	-- 提醒框
	x = X
	y = y + ui:append('Text', { x = x, y = y, text = g_tStrings.STR_RAID_TIP_IMAGE, font = 27 }, true):height()

	x = X + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show attention shadow'],
		checked = CFG.bShowAttention,
		oncheck = function(bCheck)
			CFG.bShowAttention = bCheck
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show caution animate'],
		checked = CFG.bShowCaution,
		oncheck = function(bCheck)
			CFG.bShowCaution = bCheck
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show screen head'],
		checked = CFG.bShowScreenHead,
		oncheck = function(bCheck)
			CFG.bShowScreenHead = bCheck
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
	}, true):autoWidth():width() + 5

	x = X + 10
	y = y + 25
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Attack Warning'],
		checked = CFG.bHPHitAlert,
		oncheck = function(bCheck)
			CFG.bHPHitAlert = bCheck
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show distance'],
		checked = CFG.bShowDistance,
		oncheck = function(bCheck)
			CFG.bShowDistance = bCheck
		end,
	}, true):autoWidth():width() + 5

	local me = GetClientPlayer()
	if me.dwForceID == FORCE_TYPE.WU_DU then
		x = x + ui:append('WndCheckBox', {
			x = x, y = y, text = _L['ZuiWu Effect'],
			color = { MY.GetForceColor(6) },
			checked = CFG.bShowEffect,
			oncheck = function(bCheck)
				CFG.bShowEffect = bCheck
			end,
		}, true):autoWidth():width() + 5
	end

	x = X + 10
	y = y + 25
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show target\'s target'],
		checked = CFG.bShowTargetTargetAni,
		oncheck = function(bCheck)
			CFG.bShowTargetTargetAni = bCheck
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:RefreshTTarget()
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Boss target'],
		checked = CFG.bShowBossTarget,
		oncheck = function(bCheck)
			CFG.bShowBossTarget = bCheck
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Boss focus'],
		checked = CFG.bShowBossFocus,
		oncheck = function(bCheck)
			CFG.bShowBossFocus = bCheck
		end,
	}, true):autoWidth():height()

	-- 其他
	x = X
	y = y + 4
	y = y + ui:append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }, true):height()

	x = X + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Don\'t show Tip in fight'],
		checked = CFG.bHideTipInFight,
		oncheck = function(bCheck)
			CFG.bHideTipInFight = bCheck
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_TARGET_ASSIST,
		checked = CFG.bTempTargetEnable,
		oncheck = function(bCheck)
			CFG.bTempTargetEnable = bCheck
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndSliderBox', {
		x = x, y = y - 1,
		value = CFG.nTempTargetDelay / 75,
		range = {0, 8},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(val)
			CFG.nTempTargetDelay = val * 75
		end,
		textfmt = function(val)
			return val == 0
				and _L['Target assist no delay.']
				or _L('Target assist delay %dms.', val * 75)
		end,
	}):autoWidth():width()

	x = X + 10
	y = y + 25
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Alt view player'],
		checked = CFG.bAltView,
		oncheck = function(bCheck)
			CFG.bAltView = bCheck
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Disable in fight'],
		checked = not CFG.bAltViewInFight,
		oncheck = function(bCheck)
			CFG.bAltViewInFight = not bCheck
		end,
	}, true):autoWidth():width() + 5
	-- y = y + ui:append('WndCheckBox', { x = 10, y = nY, text = _L['Faster Refresh HP(Greater performance loss)'], checked = CFG.bFasterHP, enable = false })
	-- :Click(function(bCheck)
	-- 	CFG.bFasterHP = bCheck
	-- 	if MY_Cataclysm.GetFrame() then
	-- 		if bCheck then
	-- 			MY_Cataclysm.GetFrame():RegisterEvent('RENDER_FRAME_UPDATE')
	-- 		else
	-- 			MY_Cataclysm.GetFrame():UnRegisterEvent('RENDER_FRAME_UPDATE')
	-- 		end
	-- 	end
	-- end, true):Pos_()
	y = y + 25
end
MY.RegisterPanel('MY_Cataclysm', _L['Cataclysm'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|62', {255, 255, 0}, PS)
