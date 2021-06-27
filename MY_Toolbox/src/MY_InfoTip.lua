--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 信息条显示
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_InfoTip'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {}

local CONFIG_FILE_PATH = {'config/infotip.jx3dat', PATH_TYPE.ROLE}
local INFO_TIP_LIST = {
	-- 网络延迟
	{
		id = 'Ping',
		i18n = {
			name = _L['Ping monitor'], prefix = _L['Ping: '], content = '%d',
		},
		configtpl = {
			bEnable = false, bShowBg = false, bShowTitle = false,
			rgb = { 95, 255, 95 }, nFont = 48,
			anchor = { x = -133, y = -111, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
		},
		cache = {},
		GetFormatString = function(data)
			return format(data.cache.formatString, GetPingValue() / 2)
		end,
	},
	-- 倍速显示（显示服务器有多卡……）
	{
		id = 'TimeMachine',
		i18n = {
			name = _L['Time machine'], prefix = _L['Rate: '], content = 'x%.2f',
		},
		configtpl = {
			bEnable = false, bShowBg = false, bShowTitle = true,
			rgb = { 31, 255, 31 },
			anchor = { x = -276, y = -111, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
		},
		cache = {
			tTimeMachineRec = {},
			nTimeMachineLFC = GetLogicFrameCount(),
		},
		GetFormatString = function(data)
			local s = 1
			if data.cache.nTimeMachineLFC ~= GetLogicFrameCount() then
				local tm = data.cache.tTimeMachineRec[GLOBAL.GAME_FPS] or {}
				tm.frame = GetLogicFrameCount()
				tm.tick  = GetTickCount()
				for i = GLOBAL.GAME_FPS, 1, -1 do
					data.cache.tTimeMachineRec[i] = data.cache.tTimeMachineRec[i - 1]
				end
				data.cache.tTimeMachineRec[1] = tm
				data.cache.nTimeMachineLFC = GetLogicFrameCount()
			end
			local tm = data.cache.tTimeMachineRec[GLOBAL.GAME_FPS]
			if tm then
				s = 1000 * (GetLogicFrameCount() - tm.frame) / GLOBAL.GAME_FPS / (GetTickCount() - tm.tick)
			end
			return format(data.cache.formatString, s)
		end,
	},
	-- 目标距离
	{
		id = 'Distance',
		i18n = {
			name = _L['Target distance'], prefix = _L['Distance: '], content = _L['%.1f Foot'],
		},
		configtpl = {
			bEnable = false, bShowBg = false, bShowTitle = false, bPlaceholder = true,
			rgb = { 255, 255, 0 }, nFont = 209,
			anchor = { x = 203, y = -106, s = 'CENTER', r = 'CENTER' },
		},
		cache = {},
		GetFormatString = function(data)
			local p, s = LIB.GetObject(LIB.GetTarget()), data.config.bPlaceholder and _L['No Target'] or ''
			if p then
				s = format(data.cache.formatString, LIB.GetDistance(p))
			end
			return s
		end,
	},
	-- 系统时间
	{
		id = 'SysTime',
		i18n = {
			name = _L['System time'], prefix = _L['Time: '], content = '%02d:%02d:%02d',
		},
		configtpl = {
			bEnable = false, bShowBg = true, bShowTitle = true,
			anchor = { x = 285, y = -18, s = 'BOTTOMLEFT', r = 'BOTTOMLEFT' },
		},
		cache = {},
		GetFormatString = function(data)
			local tDateTime = TimeToDate(GetCurrentTime())
			return format(data.cache.formatString, tDateTime.hour, tDateTime.minute, tDateTime.second)
		end,
	},
	-- 战斗计时
	{
		id = 'FightTime',
		i18n = {
			name = _L['Fight clock'], prefix = _L['Fight Clock: '], content = '',
		},
		configtpl = {
			bEnable = false, bShowBg = false, bShowTitle = false, bPlaceholder = true,
			rgb = { 255, 0, 128 }, nFont = 199,
			anchor = { x = 353, y = -117, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
		},
		cache = {},
		GetFormatString = function(data)
			if LIB.GetFightUUID() or LIB.GetLastFightUUID() then
				return data.cache.formatString .. LIB.GetFightTime('H:mm:ss')
			end
			return data.config.bPlaceholder and _L['Never Fight'] or ''
		end,
	},
	-- 莲花和藕倒计时
	{
		id = 'LotusTime',
		i18n = {
			name = _L['Lotus clock'], prefix = _L['Lotus Clock: '], content = '%d:%d:%d',
		},
		configtpl = {
			bEnable = false, bShowBg = true, bShowTitle = true,
			anchor = { x = -290, y = -38, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
		},
		cache = {},
		GetFormatString = function(data)
			local nTotal = 6 * 60 * 60 - GetLogicFrameCount() / 16 % (6 * 60 * 60)
			return format(data.cache.formatString, floor(nTotal / (60 * 60)), floor(nTotal / 60 % 60), floor(nTotal % 60))
		end,
	},
	-- 角色坐标
	{
		id = 'GPS',
		i18n = {
			name = _L['GPS'], prefix = _L['Location: '], content = '[%d]%d,%d,%d',
		},
		configtpl = {
			bEnable = false, bShowBg = true, bShowTitle = false,
			rgb = { 255, 255, 255 }, nFont = 0,
			anchor = { x = -21, y = 250, s = 'TOPRIGHT', r = 'TOPRIGHT' },
		},
		cache = {},
		GetFormatString = function(data)
			local player, text = GetClientPlayer(), ''
			if player then
				text = format(data.cache.formatString, player.GetMapID(), player.nX, player.nY, player.nZ)
			end
			return text
		end,
	},
	-- 角色速度
	{
		id = 'Speedometer',
		i18n = {
			name = _L['Speedometer'], prefix = _L['Speed: '], content = _L['%.2f f/s'],
		},
		configtpl = {
			bEnable = false, bShowBg = false, bShowTitle = false,
			rgb = { 255, 255, 255 }, nFont = 0,
			anchor = { x = -10, y = 210, s = 'TOPRIGHT', r = 'TOPRIGHT' },
		},
		cache = {
			tSpeedometerRec = {},
			nSpeedometerLFC = GetLogicFrameCount(),
		},
		GetFormatString = function(data)
			local s = 0
			local me = GetClientPlayer()
			if me and data.cache.nSpeedometerLFC ~= GetLogicFrameCount() then
				local sm = data.cache.tSpeedometerRec[GLOBAL.GAME_FPS] or {}
				sm.framecount = GetLogicFrameCount()
				sm.x, sm.y, sm.z = me.nX, me.nY, me.nZ
				for i = GLOBAL.GAME_FPS, 1, -1 do
					data.cache.tSpeedometerRec[i] = data.cache.tSpeedometerRec[i - 1]
				end
				data.cache.tSpeedometerRec[1] = sm
				data.cache.nSpeedometerLFC = GetLogicFrameCount()
			end
			local sm = data.cache.tSpeedometerRec[GLOBAL.GAME_FPS]
			if sm and me then
				s = sqrt(pow(me.nX - sm.x, 2) + pow(me.nY - sm.y, 2) + pow((me.nZ - sm.z) / 8, 2)) / 64
					/ (GetLogicFrameCount() - sm.framecount) * GLOBAL.GAME_FPS
			end
			return format(data.cache.formatString, s)
		end
	},
}

function D.SaveConfig()
	local tConfig = {}
	for _, v in ipairs(INFO_TIP_LIST) do
		if not v.config then
			return
		end
		tConfig[v.id] = v.config
	end
	LIB.SaveLUAData(CONFIG_FILE_PATH, tConfig)
end

function D.LoadConfig()
	local tConfig = LIB.LoadLUAData(CONFIG_FILE_PATH)
	if not IsTable(tConfig) then
		tConfig = {}
	end
	for _, v in ipairs(INFO_TIP_LIST) do
		v.config = LIB.FormatDataStructure(tConfig[v.id], v.configtpl)
	end
end

LIB.RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT', function()
	for _, v in ipairs(INFO_TIP_LIST) do
		if not v.config then
			return
		end
		v.config.anchor = Clone(v.configtpl.anchor)
	end
	D.ReinitUI()
	D.SaveConfig()
end)

-- 显示信息条
function D.ReinitUI()
	for _, data in ipairs(INFO_TIP_LIST) do
		if not data.config then
			return
		end
		local ui = UI('Normal/MY_InfoTip_' .. data.id)
		if data.config.bEnable then
			if ui:Count() == 0 then
				ui = UI.CreateFrame('MY_InfoTip_' .. data.id, { empty = true })
					:Size(220,30)
					:Event(
						'UI_SCALED',
						function()
							UI(this):Anchor(data.config.anchor)
						end)
					:CustomLayout(data.i18n.name)
					:CustomLayout(function(bEnter, anchor)
						if bEnter then
							UI(this):BringToTop()
						else
							data.config.anchor = anchor
							D.SaveConfig()
						end
					end)
					:Drag(0, 0, 0, 0)
					:Drag(false)
					:Penetrable(true)
				ui:Append('Image', {
					name = 'Image_Default',
					w = 220, h = 30,
					alpha = 180,
					image = 'UI/Image/UICommon/Commonpanel.UITex', imageframe = 86,
				})
				local txt = ui:Append('Text', {
					name = 'Text_Default',
					w = 220, h = 30,
					text = data.i18n.name,
					font = 2, valign = 1, halign = 1,
				})
				ui:Breathe(function() txt:Text(data.GetFormatString(data)) end)
			end
			data.cache.formatString = data.config.bShowTitle
				and data.i18n.prefix .. data.i18n.content
				or data.i18n.content
			ui:Fetch('Image_Default'):Visible(data.config.bShowBg)
			ui:Fetch('Text_Default')
				:Font(data.config.nFont or 0)
				:Color(data.config.rgb or { 255, 255, 255 })
			ui:Anchor(data.config.anchor)
		else
			ui:Remove()
		end
	end
end

-- 注册INIT事件
LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_INFOTIP', function()
	D.LoadConfig()
	D.ReinitUI()
end)

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 45, 40

	ui:Append('Text', {
		name = 'Text_InfoTip',
		x = x, y = y, w = 350,
		text = _L['Infomation tips'],
		color = {255, 255, 0},
	})
	y = y + 5

	for _, data in ipairs(INFO_TIP_LIST) do
		x, y = 60, y + 30

		ui:Append('WndCheckBox', {
			name = 'WndCheckBox_InfoTip_' .. data.id,
			x = x, y = y, w = 250,
			text = data.i18n.name,
			checked = data.config.bEnable or false,
			oncheck = function(bChecked)
				data.config.bEnable = bChecked
				D.ReinitUI()
				D.SaveConfig()
			end,
		})
		x = x + 220

		if IsBoolean(data.config.bPlaceholder) then
			ui:Append('WndCheckBox', {
				name = 'WndCheckBox_InfoTipPlaceholder_' .. data.id,
				x = x, y = y, w = 100,
				text = _L['Placeholder'],
				checked = data.config.bPlaceholder or false,
				oncheck = function(bChecked)
					data.config.bPlaceholder = bChecked
					D.ReinitUI()
					D.SaveConfig()
				end,
			})
		end
		x = x + 100

		ui:Append('WndCheckBox', {
			name = 'WndCheckBox_InfoTipTitle_' .. data.id,
			x = x, y = y, w = 60,
			text = _L['Title'],
			checked = data.config.bShowTitle or false,
			oncheck = function(bChecked)
				data.config.bShowTitle = bChecked
				D.ReinitUI()
				D.SaveConfig()
			end,
		})
		x = x + 70

		ui:Append('WndCheckBox', {
			name = 'WndCheckBox_InfoTipBg_' .. data.id,
			x = x, y = y, w = 60,
			text = _L['Background'],
			checked = data.config.bShowBg or false,
			oncheck = function(bChecked)
				data.config.bShowBg = bChecked
				D.ReinitUI()
				D.SaveConfig()
			end,
		})
		x = x + 70

		ui:Append('WndButton', {
			name = 'WndButton_InfoTipFont_' .. data.id,
			x = x, y = y, w = 50,
			text = _L['Font'],
			onclick = function()
				UI.OpenFontPicker(function(f)
					data.config.nFont = f
					D.ReinitUI()
					D.SaveConfig()
				end)
			end,
		})
		x = x + 60

		ui:Append('Shadow', {
			name = 'Shadow_InfoTipColor_' .. data.id,
			x = x, y = y, w = 20, h = 20,
			color = data.config.rgb or {255, 255, 255},
			onclick = function()
				local el = this
				UI.OpenColorPicker(function(r, g, b)
					UI(el):Color(r, g, b)
					data.config.rgb = { r, g, b }
					D.ReinitUI()
					D.SaveConfig()
				end)
			end,
		})
	end
end
LIB.RegisterPanel(_L['System'], 'MY_InfoTip', _L['MY_InfoTip'], 'ui/Image/UICommon/ActivePopularize2.UITex|22', PS)
