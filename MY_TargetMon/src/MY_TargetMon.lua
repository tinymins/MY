---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------

------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local insert, remove, concat = table.insert, table.remove, table.concat
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_TargetMon/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_TargetMon/ui/MY_TargetMon.ini"
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.ROLE}
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_TargetMon/data/$lang.jx3dat"
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.GLOBAL}
local CUSTOM_BOXBG_STYLES = {
	"UI/Image/Common/Box.UITex|0",
	"UI/Image/Common/Box.UITex|1",
	"UI/Image/Common/Box.UITex|2",
	"UI/Image/Common/Box.UITex|3",
	"UI/Image/Common/Box.UITex|4",
	"UI/Image/Common/Box.UITex|5",
	"UI/Image/Common/Box.UITex|6",
	"UI/Image/Common/Box.UITex|7",
	"UI/Image/Common/Box.UITex|8",
	"UI/Image/Common/Box.UITex|9",
	"UI/Image/Common/Box.UITex|10",
	"UI/Image/Common/Box.UITex|11",
	"UI/Image/Common/Box.UITex|12",
	"UI/Image/Common/Box.UITex|13",
	"UI/Image/Common/Box.UITex|14",
	"UI/Image/Common/Box.UITex|34",
	"UI/Image/Common/Box.UITex|35",
	"UI/Image/Common/Box.UITex|42",
	"UI/Image/Common/Box.UITex|43",
	"UI/Image/Common/Box.UITex|44",
	"UI/Image/Common/Box.UITex|45",
	"UI/Image/Common/Box.UITex|77",
	"UI/Image/Common/Box.UITex|78",
}
local CUSTOM_CDBAR_STYLES = {
	MY.GetAddonInfo().szUITexST .. "|" .. 0,
	MY.GetAddonInfo().szUITexST .. "|" .. 1,
	MY.GetAddonInfo().szUITexST .. "|" .. 2,
	MY.GetAddonInfo().szUITexST .. "|" .. 3,
	MY.GetAddonInfo().szUITexST .. "|" .. 4,
	MY.GetAddonInfo().szUITexST .. "|" .. 5,
	MY.GetAddonInfo().szUITexST .. "|" .. 6,
	MY.GetAddonInfo().szUITexST .. "|" .. 7,
	MY.GetAddonInfo().szUITexST .. "|" .. 8,
	"/ui/Image/Common/Money.UITex|168",
	"/ui/Image/Common/Money.UITex|203",
	"/ui/Image/Common/Money.UITex|204",
	"/ui/Image/Common/Money.UITex|205",
	"/ui/Image/Common/Money.UITex|206",
	"/ui/Image/Common/Money.UITex|207",
	"/ui/Image/Common/Money.UITex|208",
	"/ui/Image/Common/Money.UITex|209",
	"/ui/Image/Common/Money.UITex|210",
	"/ui/Image/Common/Money.UITex|211",
	"/ui/Image/Common/Money.UITex|212",
	"/ui/Image/Common/Money.UITex|213",
	"/ui/Image/Common/Money.UITex|214",
	"/ui/Image/Common/Money.UITex|215",
	"/ui/Image/Common/Money.UITex|216",
	"/ui/Image/Common/Money.UITex|217",
	"/ui/Image/Common/Money.UITex|218",
	"/ui/Image/Common/Money.UITex|219",
	"/ui/Image/Common/Money.UITex|220",
	"/ui/Image/Common/Money.UITex|228",
	"/ui/Image/Common/Money.UITex|232",
	"/ui/Image/Common/Money.UITex|233",
	"/ui/Image/Common/Money.UITex|234",
}
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	"TEAM_MARK_CLOUD",
	"TEAM_MARK_SWORD",
	"TEAM_MARK_AX"   ,
	"TEAM_MARK_HOOK" ,
	"TEAM_MARK_DRUM" ,
	"TEAM_MARK_SHEAR",
	"TEAM_MARK_STICK",
	"TEAM_MARK_JADE" ,
	"TEAM_MARK_DART" ,
	"TEAM_MARK_FAN"  ,
}
local Config, ConfigTemplate, ConfigDefault = {}

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local D = {}

function D.GetFrame(config)
	return Station.Lookup("Normal/MY_TargetMon#" .. tostring(config):sub(8))
end

function D.OpenFrame(config)
	Wnd.OpenWindow(INI_PATH, "MY_TargetMon#" .. tostring(config):sub(8))
end

function D.CloseFrame(config)
	if config == 'all' then
		for _, config in ipairs(Config) do
			D.CloseFrame(config)
		end
	else
		Wnd.CloseWindow("MY_TargetMon#" .. tostring(config):sub(8))
	end
end

function D.CheckFrame(config)
	if config.enable then
		if D.GetFrame(config) then
			FireUIEvent("MY_TARGET_MON_RELOAD", config)
		else
			D.OpenFrame(config)
		end
	else
		D.CloseFrame(config)
	end
end

function D.CheckAllFrame(reload)
	for i, config in ipairs(Config) do
		D.CheckFrame(config)
	end
end

function D.GetFrameData(id)
	for index, config in ipairs(Config) do
		if tostring(config):sub(8) == id then
			return config, index
		end
	end
end

----------------------------------------------------------------------------------------------
-- 数据存储
----------------------------------------------------------------------------------------------
local function UpdateConfigCalcProps(config)
	for _, monitors in pairs(config.monitors) do
		for _, mon in ipairs(monitors) do
			if not mon.ids then
				mon.ids = {}
			end
			for k, _ in pairs(mon.ids) do
				if not tonumber(k) then
					mon.ids[k] = nil
				end
			end
		end
	end
	MY.FormatDataStructure(config, ConfigTemplate, true)
end

function D.LoadConfig(bDefault, bOriginal)
	D.CloseFrame('all')
	Config = not bDefault
		and MY.LoadLUAData(ROLE_CONFIG_FILE)
		or (not bOriginal and MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE) or ConfigDefault)
	for _, config in pairs(Config) do
		UpdateConfigCalcProps(config)
	end
	D.CheckAllFrame()
end

do
local function OnInit()
	local data = MY.LoadLUAData(DEFAULT_CONFIG_FILE)
	ConfigDefault = data.default
	ConfigTemplate = data.template
	D.LoadConfig()
end
MY.RegisterInit("MY_TargetMon", OnInit)

local function OnExit()
	MY.SaveLUAData(ROLE_CONFIG_FILE, Config)
end
MY.RegisterExit("MY_TargetMon", OnExit)
end

----------------------------------------------------------------------------------------------
-- 快捷键
----------------------------------------------------------------------------------------------
do
for i = 1, 5 do
	for j = 1, 10 do
		Hotkey.AddBinding(
			"MY_TargetMon_" .. i .. "_" .. j, _L("Cancel buff %d - %d", i, j),
			i == 0 and j == 0 and _L["MY Buff Monitor"] or "",
			function()
				if MY.IsShieldedVersion() and not MY.IsInDungeon(true) then
					if not IsDebugClient() then
						OutputMessage("MSG_ANNOUNCE_YELLOW", _L['Cancel buff is disabled outside dungeon.'])
					end
					return
				end
				local config = Config[i]
				if not config then
					return
				end
				local frame = D.GetFrame(config)
				if not frame then
					return
				end
				local hItem = frame:Lookup("", "Handle_List"):Lookup(j - 1)
				if not hItem then
					return
				end
				ExecuteWithThis(hItem:Lookup("Box_Default"), MY_TargetMon_Base.OnItemRButtonClick)
			end, nil)
	end
end
end

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = {}
local function GenePS(ui, config, x, y, w, h, OpenConfig, Add)
	ui:append("Text", {text = (function()
		for i = 1, #Config do
			if Config[i] == config then
				return i
			end
		end
		return "X"
	end)() .. ".", x = x, y = y - 3, w = 20, r = 255, g = 255, b = 0})
	ui:append("WndEditBox", {
		x = x + 20, y = y, w = w - 290, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(raw, val) config.caption = val end,
	})
	ui:append("WndButton2", {
		x = w - 180, y = y,
		w = 50, h = 30,
		text = _L["Move Up"],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i - 1] then
						Config[i], Config[i - 1] = Config[i - 1], Config[i]
						D.CheckFrame(Config[i])
						D.CheckFrame(Config[i - 1])
						return MY.SwitchTab("MY_TargetMon", true)
					end
				end
			end
		end,
	})
	ui:append("WndButton2", {
		x = w - 125, y = y,
		w = 50, h = 30,
		text = _L["Move Down"],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i + 1] then
						Config[i], Config[i + 1] = Config[i + 1], Config[i]
						D.CheckFrame(Config[i])
						D.CheckFrame(Config[i + 1])
						return MY.SwitchTab("MY_TargetMon", true)
					end
				end
			end
		end,
	})
	ui:append("WndButton2", {
		x = w - 70, y = y,
		w = 60, h = 30,
		text = _L["Delete"],
		onclick = function()
			for i, c in ipairs_r(Config) do
				if config == c then
					table.remove(Config, i)
				end
			end
			D.CloseFrame(config)
			MY.SwitchTab("MY_TargetMon", true)
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['Enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			config.enable = bChecked
			D.CheckFrame(config)
		end,
	})

	ui:append("WndCheckBox", {
		x = x + 110, y = y, w = 200,
		text = _L['Hide others buff'],
		checked = config.hideOthers,
		oncheck = function(bChecked)
			config.hideOthers = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function()
			return config.enable and config.type == 'BUFF'
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y, w = 135,
		text = _L['Set target'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {}
			for _, eType in ipairs(TARGET_TYPE_LIST) do
				table.insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (config.type == "SKILL" and "CONTROL_PLAYER" or config.target),
					fnDisable = function()
						return config.type == "SKILL" and eType ~= "CONTROL_PLAYER"
					end,
					fnAction = function()
						config.target = eType
						D.CheckFrame(config)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				table.insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.type,
					fnAction = function()
						config.type = eType
						D.CheckFrame(config)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				table.insert(t, {
					szOption = _L.ALIGNMENT[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.alignment,
					fnAction = function()
						config.alignment = eType
						D.CheckFrame(config)
					end,
				})
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	ui:append("WndButton2", {
		x = w - 110, y = y, w = 102,
		text = _L['Set monitor'],
		onclick = function() OpenConfig(config) end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 90,
		text = _L['Penetrable'],
		checked = config.penetrable,
		oncheck = function(bChecked)
			config.penetrable = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndCheckBox", {
		x = x + 110, y = y, w = 100,
		text = _L['Undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			config.dragable = not bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable and not config.penetrable end,
	})

	ui:append("WndCheckBox", {
		x = x + 200, y = y, w = 180,
		text = _L['Hide void'],
		checked = config.hideVoid,
		oncheck = function(bChecked)
			config.hideVoid = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L("Display %d eachline.", val) end,
		onchange = function(raw, val)
			config.maxLineCount = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 200,
		text = _L['Show cd circle'],
		checked = config.cdCircle,
		oncheck = function(bCheck)
			config.cdCircle = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndCheckBox", {
		x = x + 110, y = y, w = 200,
		text = _L['Show cd flash'],
		checked = config.cdFlash,
		oncheck = function(bCheck)
			config.cdFlash = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndCheckBox", {
		x = x + 200, y = y, w = 200,
		text = _L['Show cd ready spark'],
		checked = config.cdReadySpark,
		oncheck = function(bCheck)
			config.cdReadySpark = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L("Scale %d%%.", val) end,
		onchange = function(raw, val)
			config.scale = val / 100
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 120,
		text = _L['Show cd bar'],
		checked = config.cdBar,
		oncheck = function(bCheck)
			config.cdBar = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndCheckBox", {
		x = x + 110, y = y, w = 120,
		text = _L['Show name'],
		checked = config.showName,
		oncheck = function(bCheck)
			config.showName = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {50, 1000},
		value = config.cdBarWidth,
		textfmt = function(val) return _L("CD width %dpx.", val) end,
		onchange = function(raw, val)
			config.cdBarWidth = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append("WndComboBox", {
		x = 40, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select background style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.boxBgUITex = text
						D.CheckFrame(config)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = "ICON_RIGHTMOST",
				}
				if text == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	ui:append("WndComboBox", {
		x = 40 + (w - 250 - 30 - 30 - 10) / 2 + 10, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.cdBarUITex = text
						D.CheckFrame(config)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = "ICON_FILL",
				}
				if text == config.cdBarUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {-1, 30},
		value = config.decimalTime,
		textfmt = function(val)
			if val == -1 then
				return _L['Always show decimal time.']
			elseif val == 0 then
				return _L['Never show decimal time.']
			else
				return _L("Show decimal time left in %ds.", val)
			end
		end,
		onchange = function(raw, val)
			config.decimalTime = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 30
	local x, y = X, Y

	local OpenConfig
	do -- single config details
		local l_config
		local uiWrapper = ui:append('WndWindow', { name = 'WndWindow_Wrapper', x = 0, y = 0, w = w, h = h }, true)
		uiWrapper:append('Shadow', { x = 0, y = 0, w = w, h = h, r = 0, g = 0, b = 0, alpha = 150 })
		uiWrapper:append('Shadow', { x = 10, y = 10, w = w - 20, h = h - 20, r = 255, g = 255, b = 255, alpha = 40 })

		local x0, y0 = 20, 20
		local w0, h0 = w - 40, h - 30
		local w1, w2 = w0 / 2 - 5, w0 / 2 - 5
		local x1, x2 = x0, x0 + w1 + 10

		local listCommon = uiWrapper:append("WndListBox", { x = x1, y = y0 + 25, w = w1, h = h0 - 30 - 30 }, true)
		local listKungfu = uiWrapper:append("WndListBox", { x = x2, y = y0 + 25, w = w2, h = h0 - 30 - 30 }, true)

		local function Add(kungfuid, index)
			if kungfuid == 'current' then
				kungfuid = GetClientPlayer().GetKungfuMount().dwSkillID
			end
			GetUserInput(_L['Please input name:'], function(szVal)
				szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
				if szVal ~= "" then
					if not l_config.monitors[kungfuid] then
						l_config.monitors[kungfuid] = {}
					end
					local aMonList = l_config.monitors[kungfuid]
					local mon = {
						enable = true,
						iconid = 13,
						id = tonumber(szVal) or 'common',
						ids = {},
						name = not tonumber(szVal) and szVal or nil,
					}
					if not index then
						index = #aMonList + 1
					end
					table.insert(aMonList, index, mon)
					local list = kungfuid == 'common' and listCommon or listKungfu
					list:listbox(
						'insert',
						mon.name or mon.id,
						mon,
						{ mon = mon, monlist = aMonList },
						index
					)
					D.CheckFrame(l_config)
				end
			end, function() end, function() end, nil, "" )
		end
		uiWrapper:append("Text", { x = x1 + 5, y = y0, w = w1 - 60 - 5,  h = 25, text = _L['Common monitor'] })
		uiWrapper:append("WndButton2", { x = x1 + w1 - 60, y = y0 - 1, w = 60, h = 28, text = _L['Add'], onclick = function() Add('common') end })
		uiWrapper:append("Text", { x = x2 + 5, y = y0, w = w2 - 60 - 5,  h = 25, text = _L['Current kungfu monitor'] })
		uiWrapper:append("WndButton2", { x = x2 + w2 - 60, y = y0 - 1, w = 60, h = 28, text = _L['Add'], onclick = function() Add('current') end })

		-- 初始化list控件
		local function onMenu(hItem, szText, szID, data)
			local mon = data.mon
			local monlist = data.monlist
			local t1 = {
				{
					szOption = _L['Enable'],
					bCheck = true, bChecked = mon.enable,
					fnAction = function()
						mon.enable = not mon.enable
						D.CheckFrame(l_config)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L['Delete'],
					fnAction = function()
						local list = monlist == l_config.monitors.common and listCommon or listKungfu
						list:listbox('delete', 'id', mon)
						for i, m in ipairs_r(monlist) do
							if m == mon then
								table.remove(monlist, i)
							end
						end
						Wnd.CloseWindow("PopupMenuPanel")
						D.CheckFrame(l_config)
					end,
				},
				{
					szOption = _L['Insert'],
					fnAction = function()
						local mode = monlist == l_config.monitors.common and 'common' or 'current'
						local index = #monlist
						for i, m in ipairs_r(monlist) do
							if m == mon then
								index = i
							end
						end
						Add(mode, index)
					end,
				},
				{
					szOption = _L['Move up'],
					fnAction = function()
						local mode = monlist == l_config.monitors.common and 'common' or 'current'
						local list = monlist == l_config.monitors.common and listCommon or listKungfu
						local index = #monlist
						for i, m in ipairs_r(monlist) do
							if m == mon then
								index = i
							end
						end
						if index < 2 then
							return
						end
						insert(monlist, index - 1, remove(monlist, index))
						list:listbox('exchange', 'index', index - 1, index)
					end,
				},
				{
					szOption = _L['Move down'],
					fnAction = function()
						local mode = monlist == l_config.monitors.common and 'common' or 'current'
						local list = monlist == l_config.monitors.common and listCommon or listKungfu
						local index = #monlist
						for i, m in ipairs_r(monlist) do
							if m == mon then
								index = i
							end
						end
						if index == #monlist then
							return
						end
						insert(monlist, index + 1, remove(monlist, index))
						list:listbox('exchange', 'index', index + 1, index)
					end,
				},
				{
					szOption = _L['Rename'],
					fnAction = function()
						GetUserInput(_L['Please input name:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							if szVal ~= "" then
								mon.name = szVal
								D.CheckFrame(l_config)
							end
						end, function() end, function() end, nil, mon.name)
					end,
				},
				{
					szOption = _L['Manual add id'],
					fnAction = function()
						GetUserInput(_L['Please input id:'], function(szVal)
							local nVal = tonumber(string.gsub(szVal, "^%s*(.-)%s*$", "%1"), 10)
							if nVal then
								for id, _ in pairs(mon.ids) do
									if id == nVal then
										return
									end
								end
								local dwIconID = 13
								if l_config.type == "SKILL" then
									local dwLevel = GetClientPlayer().GetSkillLevel(nVal) or 1
									dwIconID = Table_GetSkillIconID(nVal, dwLevel) or dwIconID
								else
									dwIconID = Table_GetBuffIconID(nVal, 1) or 13
								end
								mon.ids[nVal] = { iconid = dwIconID }
								D.CheckFrame(l_config)
							end
						end, function() end, function() end, nil, nil)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L('Long alias: %s', mon.longAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input long alias:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							mon.longAlias = szVal
							D.CheckFrame(l_config)
						end, function() end, function() end, nil, mon.longAlias or mon.name)
					end,
				},
				{
					szOption = _L('Short alias: %s', mon.shortAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input short alias:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							mon.shortAlias = szVal
							D.CheckFrame(l_config)
						end, function() end, function() end, nil, mon.shortAlias or mon.name)
					end,
				},
			}
			if not empty(mon.ids) then
				table.insert(t1, { bDevide = true })
				local function InsertMenuID(dwID, dwIcon)
					local t2 = {
						szOption = dwID == "common" and _L['All ids'] or dwID,
						bCheck = true, bMCheck = true,
						bChecked = dwID == mon.id or (dwID == "common" and mon.id == nil),
						fnAction = function()
							mon.iconid = dwIcon
							mon.id = dwID
							D.CheckFrame(l_config)
						end,
						szIcon = "fromiconid",
						nFrame = dwIcon or 13,
						nIconWidth = 22,
						nIconHeight = 22,
						szLayer = "ICON_RIGHTMOST",
						fnClickIcon = function()
							XGUI.OpenIconPanel(function(dwIcon)
								if dwID == "common" then
									mon.iconid = dwIcon
								else
									if mon.id == dwID then
										mon.iconid = dwIcon
									end
									mon.ids[dwID].iconid = dwIcon
								end
								if mon.id == dwID then
									D.CheckFrame(l_config)
								end
							end)
							Wnd.CloseWindow("PopupMenuPanel")
						end,
					}
					if dwID ~= 'common' then
						table.insert(t2, {
							szOption = _L['Delete'],
							fnAction = function()
								mon.ids[dwID] = nil
								D.CheckFrame(l_config)
							end,
						})
					end
					table.insert(t1, t2)
				end
				InsertMenuID('common', mon.ids.common or mon.iconid or 13)
				for dwID, info in pairs(mon.ids) do
					if dwID ~= "common" then
						InsertMenuID(dwID, info.iconid)
					end
				end
			end
			return t1
		end
		listCommon:listbox('onmenu', onMenu)
		listKungfu:listbox('onmenu', onMenu)

		function OpenConfig(config)
			l_config = config
			listCommon:listbox('clear')
			do local aMonList = config.monitors.common
				if aMonList and #aMonList > 0 then
					for i, mon in ipairs(aMonList) do
						listCommon:listbox(
							'insert',
							mon.name or mon.id,
							mon,
							{ mon = mon, monlist = aMonList }
						)
					end
				end
			end
			listKungfu:listbox('clear')
			do local aMonList = config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID]
				if aMonList and #aMonList > 0 then
					for i, mon in ipairs(aMonList) do
						listKungfu:listbox(
							'insert',
							mon.name or mon.id,
							mon,
							{ mon = mon, monlist = aMonList }
						)
					end
				end
			end
			uiWrapper:show()
			uiWrapper:bringToTop()
		end

		uiWrapper:append('WndButton2', {
			x = x0 + w0 / 2 - 50, y = y0 + h0 - 30,
			w = 100, h = 30, text = _L['Close'],
			onclick = function()
				l_config = nil
				uiWrapper:hide()
			end,
		})
		uiWrapper:hide()
	end

	for _, config in ipairs(Config) do
		x, y = GenePS(ui, config, x, y, w, h, OpenConfig, Add)
		y = y + 20
	end
	y = y + 10

	x = (w - 380) / 2
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Create"],
		onclick = function()
			local config = MY.FormatDataStructure(nil, ConfigTemplate)
			table.insert(Config, config)
			D.CheckFrame(config)
			MY.SwitchTab("MY_TargetMon", true)
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Import"],
		onclick = function()
			local file = GetOpenFileName(
				_L['Please select import target monitor data file.'],
				'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
				MY.FormatPath({ 'export/TargetMon', MY_DATA_PATH.GLOBAL })
			)
			if file == '' then
				return
			end
			local configs = MY.LoadLUAData(file)
			if not configs then
				return
			end
			local importCount = 0
			local replaceCount = 0
			for _, config in ipairs(configs) do
				for i, cfg in ipairs_r(Config) do
					if cfg.caption == config.caption then
						D.CloseFrame(cfg)
						table.remove(Config, i)
						replaceCount = replaceCount + 1
					end
				end
				table.insert(Config, config)
				importCount = importCount + 1
			end
			D.CheckAllFrame()
			MY.SwitchTab("MY_TargetMon", true)
			MY.Sysmsg({ _L('Import successed, %d imported and %d replaced.', importCount, replaceCount) })
			OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Import successed, %d imported and %d replaced.', importCount, replaceCount))
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Export"],
		menu = function()
			local configs = {}
			local menu = {}
			for _, config in ipairs(Config) do
				table.insert(menu, {
					bCheck = true,
					szOption = config.caption,
					fnAction = function()
						for i, cfg in ipairs_r(configs) do
							if cfg == config then
								table.remove(configs, i)
								return
							end
						end
						table.insert(configs, config)
					end,
				})
			end
			if #menu > 0 then
				table.insert(menu, MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = _L['Ensure export'],
				fnAction = function()
					local file = MY.FormatPath({
						"export/TargetMon/$name@$server@"
							.. MY.FormatTime("yyyyMMddhhmmss")
							.. ".jx3dat",
						MY_DATA_PATH.GLOBAL,
					})
					MY.SaveLUAData(file, configs)
					MY.Sysmsg({ _L('Data exported, file saved at %s.', file) })
					OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Data exported, file saved at %s.', file))
				end,
				fnDisable = function()
					return not next(configs)
				end,
			})
			return menu
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 80, h = 30,
		text = _L["Save As Default"],
		onclick = function()
			MY.Confirm(_L['Sure to save as default?'], function()
				MY.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, Config)
			end)
		end,
	})
	x = x + 90
	ui:append("WndButton2", {
		x = x, y = y,
		w = 80, h = 30,
		text = _L["Reset Default"],
		tip = _L['Hold ctrl to reset original default.'],
		tippostype = MY.Const.UI.Tip.POS_TOP,
		onclick = function()
			local ctrl = IsCtrlKeyDown()
			MY.Confirm(_L[ctrl and 'Sure to reset original default?' or 'Sure to reset default?'], function()
				D.LoadConfig(true, ctrl)
				MY.SwitchTab("MY_TargetMon", true)
			end)
		end,
	})
	x = x + 90

	x = X
	y = y + 30
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
MY.RegisterPanel("MY_TargetMon", _L["Target monitor"], _L['Target'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)


local ui = {
	GetFrameData = D.GetFrameData,
}
MY_TargetMon = setmetatable({}, { __index = ui, __newindex = function() end, __metatable = true })
