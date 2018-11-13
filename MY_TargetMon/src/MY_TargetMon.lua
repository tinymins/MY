--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控设置
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

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/ui/MY_TargetMon.ini'
local ADDON_ROOT = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/'
local RES_ROOT = MY.GetAddonInfo().szRoot .. 'MY_Resource/'
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.ROLE}
local TEMPLATE_CONFIG_FILE = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat'
local EMBEDDED_CONFIG_ROOT = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/embedded/'
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.GLOBAL}
local CUSTOM_BOXBG_STYLES = {
	'UI/Image/Common/Box.UITex|0',
	'UI/Image/Common/Box.UITex|1',
	'UI/Image/Common/Box.UITex|2',
	'UI/Image/Common/Box.UITex|3',
	'UI/Image/Common/Box.UITex|4',
	'UI/Image/Common/Box.UITex|5',
	'UI/Image/Common/Box.UITex|6',
	'UI/Image/Common/Box.UITex|7',
	'UI/Image/Common/Box.UITex|8',
	'UI/Image/Common/Box.UITex|9',
	'UI/Image/Common/Box.UITex|10',
	'UI/Image/Common/Box.UITex|11',
	'UI/Image/Common/Box.UITex|12',
	'UI/Image/Common/Box.UITex|13',
	'UI/Image/Common/Box.UITex|14',
	'UI/Image/Common/Box.UITex|34',
	'UI/Image/Common/Box.UITex|35',
	'UI/Image/Common/Box.UITex|42',
	'UI/Image/Common/Box.UITex|43',
	'UI/Image/Common/Box.UITex|44',
	'UI/Image/Common/Box.UITex|45',
	'UI/Image/Common/Box.UITex|77',
	'UI/Image/Common/Box.UITex|78',
}
local CUSTOM_CDBAR_STYLES = {
	MY.GetAddonInfo().szUITexST .. '|' .. 0,
	MY.GetAddonInfo().szUITexST .. '|' .. 1,
	MY.GetAddonInfo().szUITexST .. '|' .. 2,
	MY.GetAddonInfo().szUITexST .. '|' .. 3,
	MY.GetAddonInfo().szUITexST .. '|' .. 4,
	MY.GetAddonInfo().szUITexST .. '|' .. 5,
	MY.GetAddonInfo().szUITexST .. '|' .. 6,
	MY.GetAddonInfo().szUITexST .. '|' .. 7,
	MY.GetAddonInfo().szUITexST .. '|' .. 8,
	'/ui/Image/Common/Money.UITex|168',
	'/ui/Image/Common/Money.UITex|203',
	'/ui/Image/Common/Money.UITex|204',
	'/ui/Image/Common/Money.UITex|205',
	'/ui/Image/Common/Money.UITex|206',
	'/ui/Image/Common/Money.UITex|207',
	'/ui/Image/Common/Money.UITex|208',
	'/ui/Image/Common/Money.UITex|209',
	'/ui/Image/Common/Money.UITex|210',
	'/ui/Image/Common/Money.UITex|211',
	'/ui/Image/Common/Money.UITex|212',
	'/ui/Image/Common/Money.UITex|213',
	'/ui/Image/Common/Money.UITex|214',
	'/ui/Image/Common/Money.UITex|215',
	'/ui/Image/Common/Money.UITex|216',
	'/ui/Image/Common/Money.UITex|217',
	'/ui/Image/Common/Money.UITex|218',
	'/ui/Image/Common/Money.UITex|219',
	'/ui/Image/Common/Money.UITex|220',
	'/ui/Image/Common/Money.UITex|228',
	'/ui/Image/Common/Money.UITex|232',
	'/ui/Image/Common/Money.UITex|233',
	'/ui/Image/Common/Money.UITex|234',
}
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	'TEAM_MARK_CLOUD',
	'TEAM_MARK_SWORD',
	'TEAM_MARK_AX'   ,
	'TEAM_MARK_HOOK' ,
	'TEAM_MARK_DRUM' ,
	'TEAM_MARK_SHEAR',
	'TEAM_MARK_STICK',
	'TEAM_MARK_JADE' ,
	'TEAM_MARK_DART' ,
	'TEAM_MARK_FAN'  ,
}
local SOUNDS = {
	{ dwID = 1, szName = _L['Default alert sound'], szPath = ADDON_ROOT .. 'audio/alert_sound.ogg' },
	{ dwID = 2, szName = _L.VOICE['voice-52001'], szPath = RES_ROOT .. 'audio/voice-52001.ogg' },
	{ dwID = 3, szName = _L.VOICE['voice-52002'], szPath = RES_ROOT .. 'audio/voice-52002.ogg' },
	{ dwID = 4, szName = _L.VOICE['voice-52003'], szPath = RES_ROOT .. 'audio/voice-52003.ogg' },
	{ dwID = 5, szName = _L.VOICE['voice-52004'], szPath = RES_ROOT .. 'audio/voice-52004.ogg' },
	{ dwID = 6, szName = _L.VOICE['voice-52005'], szPath = RES_ROOT .. 'audio/voice-52005.ogg' },
	{ dwID = 7, szName = _L.VOICE['voice-52006'], szPath = RES_ROOT .. 'audio/voice-52006.ogg' },
	{ dwID = 8, szName = _L.VOICE['voice-52007'], szPath = RES_ROOT .. 'audio/voice-52007.ogg' },
	{ dwID = 9, szName = _L.VOICE['voice-52008'], szPath = RES_ROOT .. 'audio/voice-52008.ogg' },
	{ dwID = 10, szName = _L.VOICE['voice-52009'], szPath = RES_ROOT .. 'audio/voice-52009.ogg' },
	{ dwID = 11, szName = _L.VOICE['voice-52010'], szPath = RES_ROOT .. 'audio/voice-52010.ogg' },
	{ dwID = 12, szName = _L.VOICE['voice-52011'], szPath = RES_ROOT .. 'audio/voice-52011.ogg' },
	{ dwID = 13, szName = _L.VOICE['voice-52012'], szPath = RES_ROOT .. 'audio/voice-52012.ogg' },
	{ dwID = 14, szName = _L.VOICE['voice-52013'], szPath = RES_ROOT .. 'audio/voice-52013.ogg' },
	{ dwID = 15, szName = _L.VOICE['voice-52014'], szPath = RES_ROOT .. 'audio/voice-52014.ogg' },
	{ dwID = 16, szName = _L.VOICE['voice-52015'], szPath = RES_ROOT .. 'audio/voice-52015.ogg' },
	{ dwID = 17, szName = _L.VOICE['voice-52016'], szPath = RES_ROOT .. 'audio/voice-52016.ogg' },
	{ dwID = 18, szName = _L.VOICE['voice-52017'], szPath = RES_ROOT .. 'audio/voice-52017.ogg' },
	{ dwID = 19, szName = _L.VOICE['voice-52018'], szPath = RES_ROOT .. 'audio/voice-52018.ogg' },
	{ dwID = 20, szName = _L.VOICE['voice-52019'], szPath = RES_ROOT .. 'audio/voice-52019.ogg' },
	{ dwID = 21, szName = _L.VOICE['voice-52020'], szPath = RES_ROOT .. 'audio/voice-52020.ogg' },
	{ dwID = 22, szName = _L.VOICE['voice-52021'], szPath = RES_ROOT .. 'audio/voice-52021.ogg' },
	{ dwID = 23, szName = _L.VOICE['voice-52023'], szPath = RES_ROOT .. 'audio/voice-52023.ogg' },
	{ dwID = 24, szName = _L.VOICE['voice-52024'], szPath = RES_ROOT .. 'audio/voice-52024.ogg' },
	{ dwID = 25, szName = _L.VOICE['voice-52025'], szPath = RES_ROOT .. 'audio/voice-52025.ogg' },
	{ dwID = 26, szName = _L.VOICE['voice-52026'], szPath = RES_ROOT .. 'audio/voice-52026.ogg' },
	{ dwID = 27, szName = _L.VOICE['voice-52027'], szPath = RES_ROOT .. 'audio/voice-52027.ogg' },
	{ dwID = 28, szName = _L.VOICE['voice-52028'], szPath = RES_ROOT .. 'audio/voice-52028.ogg' },
	{ dwID = 29, szName = _L.VOICE['voice-52029'], szPath = RES_ROOT .. 'audio/voice-52029.ogg' },
	{ dwID = 30, szName = _L.VOICE['voice-52030'], szPath = RES_ROOT .. 'audio/voice-52030.ogg' },
	{ dwID = 31, szName = _L.VOICE['voice-52031'], szPath = RES_ROOT .. 'audio/voice-52031.ogg' },
	{ dwID = 32, szName = _L.VOICE['voice-52032'], szPath = RES_ROOT .. 'audio/voice-52032.ogg' },
	{ dwID = 33, szName = _L.VOICE['voice-52033'], szPath = RES_ROOT .. 'audio/voice-52033.ogg' },
	{ dwID = 34, szName = _L.VOICE['voice-52034'], szPath = RES_ROOT .. 'audio/voice-52034.ogg' },
	{ dwID = 35, szName = _L.VOICE['voice-52035'], szPath = RES_ROOT .. 'audio/voice-52035.ogg' },
	{ dwID = 36, szName = _L.VOICE['voice-53001'], szPath = RES_ROOT .. 'audio/voice-53001.ogg' },
	{ dwID = 37, szName = _L.VOICE['voice-53002'], szPath = RES_ROOT .. 'audio/voice-53002.ogg' },
	{ dwID = 38, szName = _L.VOICE['voice-53003'], szPath = RES_ROOT .. 'audio/voice-53003.ogg' },
	{ dwID = 39, szName = _L.VOICE['voice-53004'], szPath = RES_ROOT .. 'audio/voice-53004.ogg' },
	{ dwID = 40, szName = _L.VOICE['voice-53005'], szPath = RES_ROOT .. 'audio/voice-53005.ogg' },
	{ dwID = 41, szName = _L.VOICE['voice-53006'], szPath = RES_ROOT .. 'audio/voice-53006.ogg' },
	{ dwID = 42, szName = _L.VOICE['voice-53007'], szPath = RES_ROOT .. 'audio/voice-53007.ogg' },
}
local Config, ConfigEmbedded, ConfigTemplate, ConfigDefault = {}, {}

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local D = {}

function D.GetFrame(config)
	return Station.Lookup('Normal/MY_TargetMon#' .. tostring(config):sub(8))
end

function D.OpenFrame(config)
	Wnd.OpenWindow(INI_PATH, 'MY_TargetMon#' .. tostring(config):sub(8))
end

function D.CloseFrame(config)
	if config == 'all' then
		for _, config in ipairs(Config) do
			D.CloseFrame(config)
		end
	else
		Wnd.CloseWindow('MY_TargetMon#' .. tostring(config):sub(8))
	end
end

function D.CheckFrame(config)
	if config.enable then
		if D.GetFrame(config) then
			FireUIEvent('MY_TARGET_MON_RELOAD', config)
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

do local CACHE = {}
function D.GetSound(dwID)
	if not CACHE[dwID] then
		for _, sound in ipairs(SOUNDS) do
			if sound.dwID == dwID then
				CACHE[dwID] = sound
				break
			end
		end
	end
	return CACHE[dwID]
end
end

do
local TEAM_MARK = {
	['TEAM_MARK_CLOUD'] = 1,
	['TEAM_MARK_SWORD'] = 2,
	['TEAM_MARK_AX'   ] = 3,
	['TEAM_MARK_HOOK' ] = 4,
	['TEAM_MARK_DRUM' ] = 5,
	['TEAM_MARK_SHEAR'] = 6,
	['TEAM_MARK_STICK'] = 7,
	['TEAM_MARK_JADE' ] = 8,
	['TEAM_MARK_DART' ] = 9,
	['TEAM_MARK_FAN'  ] = 10,
}
function D.GetTarget(eTarType, eMonType)
	if eMonType == 'SKILL' or eTarType == 'CONTROL_PLAYER' then
		return TARGET.PLAYER, GetControlPlayerID()
	elseif eTarType == 'CLIENT_PLAYER' then
		return TARGET.PLAYER, UI_GetClientPlayerID()
	elseif eTarType == 'TARGET' then
		return MY.GetTarget()
	elseif eTarType == 'TTARGET' then
		local KTarget = MY.GetObject(MY.GetTarget())
		if KTarget then
			return MY.GetTarget(KTarget)
		end
	elseif TEAM_MARK[eTarType] then
		local mark = GetClientTeam().GetTeamMark()
		if mark then
			for dwID, nMark in pairs(mark) do
				if TEAM_MARK[eTarType] == nMark then
					return TARGET[IsPlayer(dwID) and 'PLAYER' or 'NPC'], dwID
				end
			end
		end
	end
	return TARGET.NO_TARGET, 0
end
end

----------------------------------------------------------------------------------------------
-- 数据存储
----------------------------------------------------------------------------------------------
do
-- 新建数据时调用
function D.FormatMonItemLevelStructure(config)
	return MY.FormatDataStructure(config, ConfigTemplate.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__.levels.__CHILD_TEMPLATE__, true)
end

function D.FormatMonItemStructure(config)
	return MY.FormatDataStructure(config, ConfigTemplate.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__, true)
end

local function FormatMonitorData(mon)
	if mon.kungfus[0] then
		mon.kungfus[0] = nil
		mon.kungfus.all = true
	elseif mon.kungfus.all == nil then
		mon.kungfus.all = empty(mon.kungfus)
	end
	if mon.tarkungfus.all == nil then
		mon.tarkungfus.all = empty(mon.tarkungfus)
	end
	if not mon.uuid then
		mon.uuid = tostring(mon):sub(8)
	end
	return mon
end
function D.FormatMonStructure(mon)
	if not mon.uuid then
		mon.uuid = tostring(mon):sub(8)
	end
	if IsString(mon.soundAppear) then
		mon.soundAppear = {mon.soundAppear}
	end
	if IsString(mon.soundDisappear) then
		mon.soundDisappear = {mon.soundDisappear}
	end
	return FormatMonitorData(MY.FormatDataStructure(mon, ConfigTemplate.monitors.__CHILD_TEMPLATE__, true))
end

-- 新建数据和处理已有数据都会调用
local function FormatConfigData(config)
	for _, mon in ipairs(config.monitors) do
		FormatMonitorData(mon)
	end
	return config
end
function D.FormatConfigStructure(config)
	-- 处理用户修改的内建数据
	if config.delete then
		return
	end
	if config.monitors then
		if config.monitors.common then
			local monitors = {}
			for dwKungfuID, aMonList in pairs(config.monitors) do
				if dwKungfuID == 'common' then
					dwKungfuID = 'all'
				end
				for _, mon in ipairs(aMonList) do
					mon.kungfus = { [dwKungfuID] = true }
					insert(monitors, mon)
				end
			end
			config.monitors = monitors
		end
	else
		config.monitors = {}
	end
	for _, embedded in ipairs(ConfigEmbedded) do
		if embedded.uuid == config.uuid then
			-- 设置内嵌数据默认属性
			for k, v in pairs(embedded) do
				if k ~= 'monitors' and config[k] == nil then
					config[k] = v
				end
			end
			-- 设置内嵌数据删除项和自定义项
			for _, p in ipairs(embedded.monitors) do
				local exist = false
				for i, mon in ipairs_r(config.monitors) do
					if mon.uuid == p.uuid then
						if mon.delete then
							remove(config.monitors, i)
						elseif not mon.manually then
							config.monitors[i] = clone(p)
						end
						exist = true
						break
					end
				end
				if not exist then
					insert(config.monitors, clone(p))
				end
			end
			-- 删除上版本存在当前版本不存在的内嵌数据
			for i, mon in ipairs_r(config.monitors) do
				local exist = false
				for _, p in ipairs(embedded.monitors) do
					if mon.uuid == p.uuid then
						exist = true
						break
					end
				end
				if not exist and not mon.manually then
					remove(config.monitors, i)
				end
			end
		end
	end
	if not config.uuid then
		config.uuid = tostring(config):sub(8)
	end
	for _, mon in ipairs(config.monitors) do
		if mon.ids then
			for _, idmon in ipairs(mon.ids) do
				if IsString(idmon.soundAppear) then
					idmon.soundAppear = {idmon.soundAppear}
				end
				if IsTable(idmon.soundAppear) then
					for i, v in ipairs_r(idmon.soundAppear) do
						if v == '' then
							remove(idmon.soundAppear, i)
						end
					end
				end
				if IsString(idmon.soundDisappear) then
					idmon.soundDisappear = {idmon.soundDisappear}
				end
				if IsTable(idmon.soundDisappear) then
					for i, v in ipairs_r(idmon.soundDisappear) do
						if v == '' then
							remove(idmon.soundDisappear, i)
						end
					end
				end
			end
		end
		if IsString(mon.soundAppear) then
			mon.soundAppear = {mon.soundAppear}
		end
		if IsTable(mon.soundAppear) then
			for i, v in ipairs_r(mon.soundAppear) do
				if v == '' then
					remove(mon.soundAppear, i)
				end
			end
		end
		if IsString(mon.soundDisappear) then
			mon.soundDisappear = {mon.soundDisappear}
		end
		if IsTable(mon.soundDisappear) then
			for i, v in ipairs_r(mon.soundDisappear) do
				if v == '' then
					remove(mon.soundDisappear, i)
				end
			end
		end
	end
	return FormatConfigData(MY.FormatDataStructure(config, ConfigTemplate, true))
end

-- 保存数据时候会调用
function D.FormatSavingConfig(config)
	for _, embedded in ipairs(ConfigEmbedded) do
		if embedded.uuid == config.uuid then
			local cfg = { uuid = config.uuid, monitors = {} }
			-- 保存修改的全局属性
			for k, v in pairs(config) do
				if k ~= 'uuid' and k ~= 'monitors' and v ~= embedded[k] then
					cfg[k] = v
				end
			end
			-- 保存添加以及排序修改的部分
			for i, mon in ipairs(config.monitors) do
				if not mon.manually and mon.uuid then
					insert(cfg.monitors, { uuid = mon.uuid })
				else
					insert(cfg.monitors, mon)
				end
			end
			-- 保存删减的部分
			for _, p in ipairs(embedded.monitors) do
				local exist = false
				for _, mon in ipairs(config.monitors) do
					if mon.uuid == p.uuid then
						exist = true
						break
					end
				end
				if not exist then
					insert(cfg.monitors, { uuid = p.uuid, delete = true })
				end
			end
			return cfg
		end
	end
	return config
end

function D.FormatSavingConfigs(Config)
	local cfgs = {}
	for _, config in ipairs(Config) do
		insert(cfgs, D.FormatSavingConfig(config))
	end
	for _, embedded in ipairs_r(ConfigEmbedded) do
		local exist = false
		for _, config in ipairs(Config) do
			if config.uuid == embedded.uuid then
				exist = true
			end
		end
		if not exist then
			insert(cfgs, { uuid = embedded.uuid, delete = true })
		end
	end
	return cfgs
end
end

function D.LoadConfig(bDefault, bOriginal)
	D.CloseFrame('all')
	Config = not bDefault
		and MY.LoadLUAData(ROLE_CONFIG_FILE)
		or (not bOriginal and MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE) or {})
	-- 兼容旧数据
	local Embedded = Config.Embedded
	if Embedded then
		for _, config in ipairs(clone(ConfigEmbedded)) do
			for k, v in pairs(Embedded[config.caption] or {}) do
				if k ~= 'caption' and k ~= 'target' and k ~= 'monitors' then
					config[k] = v
				end
			end
			insert(Config, 1, config)
		end
		Config.Embedded = nil
	end
	-- 插入内建数据
	for _, embedded in ipairs_r(ConfigEmbedded) do
		local exist = false
		for _, config in ipairs(Config) do
			if config.uuid == embedded.uuid then
				exist = true
				break
			end
		end
		if not exist then
			insert(Config, 1, { uuid = embedded.uuid, monitors = {}, enable = false })
		end
	end
	-- 格式化数据
	for i, config in ipairs_r(Config) do
		if not D.FormatConfigStructure(config) then
			remove(Config, i)
		end
	end
	D.CheckAllFrame()
end

do
local function OnInit()
	ConfigTemplate = MY.LoadLUAData(TEMPLATE_CONFIG_FILE)
	ConfigEmbedded = {}
	for _, file in ipairs(CPath.GetFileList(EMBEDDED_CONFIG_ROOT)) do
		if wfind(file, MY.GetLang() .. '.jx3dat') then
			for _, config in ipairs(MY.LoadLUAData(EMBEDDED_CONFIG_ROOT .. file) or {}) do
				config.enable = false
				for _, mon in ipairs(config.monitors) do
					mon.manually = false
				end
				insert(ConfigEmbedded, config)
			end
		end
	end
	D.LoadConfig()
end
MY.RegisterInit('MY_TargetMon', OnInit)

local function OnExit()
	MY.SaveLUAData(ROLE_CONFIG_FILE, D.FormatSavingConfigs(Config))
end
MY.RegisterExit('MY_TargetMon', OnExit)
end

----------------------------------------------------------------------------------------------
-- 快捷键
----------------------------------------------------------------------------------------------
do
for i = 1, 5 do
	for j = 1, 10 do
		Hotkey.AddBinding(
			'MY_TargetMon_' .. i .. '_' .. j, _L('Cancel buff %d - %d', i, j),
			i == 1 and j == 1 and _L['MY Buff Monitor'] or '',
			function()
				if MY.IsShieldedVersion() and not MY.IsInDungeon() then
					if not IsDebugClient() then
						OutputMessage('MSG_ANNOUNCE_YELLOW', _L['Cancel buff is disabled outside dungeon.'])
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
				local hItem = frame:Lookup('', 'Handle_List'):Lookup(j - 1)
				if not hItem then
					return
				end
				local KTarget = MY.GetObject(D.GetTarget(config.target, config.type))
				if not KTarget then
					return
				end
				MY.CancelBuff(KTarget, hItem.dwID, hItem.nLevel)
			end, nil)
	end
end
end

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = {}
local function GenePS(ui, config, x, y, w, h, OpenConfig)
	ui:append('Text', {
		x = x, y = y - 3, w = 20,
		r = 255, g = 255, b = 0,
		text = _L['*'],
	})
	ui:append('WndEditBox', {
		x = x + 20, y = y, w = w - 290, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(val) config.caption = val end,
	})
	ui:append('WndButton2', {
		x = w - 180, y = y,
		w = 50, h = 25,
		text = _L['Move Up'],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i - 1] then
						Config[i], Config[i - 1] = Config[i - 1], Config[i]
						D.CheckFrame(Config[i])
						D.CheckFrame(Config[i - 1])
						return MY.SwitchTab('MY_TargetMon', true)
					end
				end
			end
		end,
	})
	ui:append('WndButton2', {
		x = w - 125, y = y,
		w = 50, h = 25,
		text = _L['Move Down'],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i + 1] then
						Config[i], Config[i + 1] = Config[i + 1], Config[i]
						D.CheckFrame(Config[i])
						D.CheckFrame(Config[i + 1])
						return MY.SwitchTab('MY_TargetMon', true)
					end
				end
			end
		end,
	})
	ui:append('WndButton2', {
		x = w - 70, y = y,
		w = 60, h = 25,
		text = _L['Delete'],
		onclick = function()
			for i, c in ipairs_r(Config) do
				if config == c then
					remove(Config, i)
				end
			end
			D.CloseFrame(config)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		x = x + 20, y = y,
		text = _L['Enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			config.enable = bChecked
			D.CheckFrame(config)
		end,
	})

	ui:append('WndCheckBox', {
		x = x + 110, y = y, w = 200,
		text = _L['Hide others buff'],
		tip = _L['Hide others buff TIP'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		checked = config.hideOthers,
		oncheck = function(bChecked)
			config.hideOthers = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function()
			return config.enable and config.type == 'BUFF'
		end,
	})

	ui:append('WndCheckBox', {
		x = x + 200, y = y, w = 180,
		text = _L['Hide void'],
		checked = config.hideVoid,
		oncheck = function(bChecked)
			config.hideVoid = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndComboBox', {
		x = w - 250, y = y, w = 135,
		text = _L['Set target'],
		menu = function()
			local t = {}
			for _, eType in ipairs(TARGET_TYPE_LIST) do
				insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (config.type == 'SKILL' and 'CONTROL_PLAYER' or config.target),
					fnDisable = function()
						return config.type == 'SKILL' and eType ~= 'CONTROL_PLAYER'
					end,
					fnAction = function()
						config.target = eType
						D.CheckFrame(config)
					end,
				})
			end
			insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.type,
					fnAction = function()
						config.type = eType
						D.CheckFrame(config)
					end,
				})
			end
			insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				insert(t, {
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
	ui:append('WndButton2', {
		x = w - 110, y = y, w = 102,
		text = _L['Set monitor'],
		onclick = function() OpenConfig(config) end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		x = x + 20, y = y, w = 90,
		text = _L['Penetrable'],
		checked = config.penetrable,
		oncheck = function(bChecked)
			config.penetrable = bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 110, y = y, w = 100,
		text = _L['Undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			config.dragable = not bChecked
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable and not config.penetrable end,
	})

	ui:append('WndCheckBox', {
		x = x + 200, y = y, w = 120,
		text = _L['Ignore system ui scale'],
		checked = config.ignoreSystemUIScale,
		oncheck = function(bCheck)
			config.ignoreSystemUIScale = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L('Display %d eachline.', val) end,
		onchange = function(val)
			config.maxLineCount = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		x = x + 20, y = y, w = 200,
		text = _L['Show cd circle'],
		checked = config.cdCircle,
		oncheck = function(bCheck)
			config.cdCircle = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 110, y = y, w = 200,
		text = _L['Show cd flash'],
		checked = config.cdFlash,
		oncheck = function(bCheck)
			config.cdFlash = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 200, y = y, w = 200,
		text = _L['Show cd ready spark'],
		checked = config.cdReadySpark,
		oncheck = function(bCheck)
			config.cdReadySpark = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L('Scale %d%%.', val) end,
		onchange = function(val)
			config.scale = val / 100
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		x = x + 20, y = y, w = 120,
		text = _L['Show cd bar'],
		checked = config.cdBar,
		oncheck = function(bCheck)
			config.cdBar = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 110, y = y, w = 120,
		text = _L['Show name'],
		checked = config.showName,
		oncheck = function(bCheck)
			config.showName = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 200, y = y, w = 120,
		text = _L['Show time'],
		checked = config.showTime,
		oncheck = function(bCheck)
			config.showTime = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {50, 1000},
		value = config.cdBarWidth,
		textfmt = function(val) return _L('CD width %dpx.', val) end,
		onchange = function(val)
			config.cdBarWidth = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		x = 40, y = y, w = 90,
		text = _L['Play sound'],
		checked = config.playSound,
		oncheck = function(bCheck)
			config.playSound = bCheck
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndComboBox', {
		x = 40 + 90, y = y, w = (w - 250 - 30 - 30 - 80) / 2,
		text = _L['Icon style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(text:split('|'))
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
					szLayer = 'ICON_RIGHTMOST',
				}
				if text == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
				end
				insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	ui:append('WndComboBox', {
		x = 40 + 90 + (w - 250 - 30 - 30 - 80) / 2, y = y, w = (w - 250 - 30 - 30 - 80) / 2,
		text = _L['Countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split('|'))
				subt = {
					szOption = text,
					fnAction = function()
						config.cdBarUITex = text
						D.CheckFrame(config)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = 'ICON_FILL',
				}
				if text == config.cdBarUITex then
					subt.rgb = {255, 255, 0}
				end
				insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {-1, 30},
		value = config.decimalTime,
		textfmt = function(val)
			if val == -1 then
				return _L['Always show decimal time.']
			elseif val == 0 then
				return _L['Never show decimal time.']
			else
				return _L('Show decimal time left in %ds.', val)
			end
		end,
		onchange = function(val)
			config.decimalTime = val
			D.CheckFrame(config)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 20
	local x, y = X, Y

	local OpenConfig
	do -- single config details
		local l_config, l_search
		local uiWrapper = ui:append('WndWindow', { name = 'WndWindow_Wrapper', x = 0, y = 0, w = w, h = h }, true)
		uiWrapper:append('Shadow', { x = 0, y = 0, w = w, h = h, r = 0, g = 0, b = 0, alpha = 150 })
		uiWrapper:append('Shadow', { x = 10, y = 10, w = w - 20, h = h - 20, r = 255, g = 255, b = 255, alpha = 40 })

		local x0, y0 = 20, 20
		local w0, h0 = w - 40, h - 30
		local w1, x1 = w0 - 5, x0
		local list = uiWrapper:append('WndListBox', { x = x1, y = y0 + 30, w = w1, h = h0 - 35 - 30 }, true)

		local function Search()
			list:listbox('clear')
			local aMonList = l_config.monitors or {}
			for i, mon in ipairs(aMonList) do
				if not l_search or l_search == ''
				or (mon.name and wfind(mon.name, l_search))
				or (mon.longAlias and wfind(mon.longAlias, l_search))
				or (mon.shortAlias and wfind(mon.shortAlias, l_search)) then
					list:listbox(
						'insert',
						mon.name or mon.id,
						mon,
						{ mon = mon, monlist = aMonList }
					)
				end
			end
		end

		local function InsertMonitor(index)
			GetUserInput(_L['Please input name:'], function(szVal)
				szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
				if szVal ~= '' then
					local aMonList = l_config.monitors
					local mon = MY_TargetMon.FormatMonStructure({
						name = szVal,
						manually = true,
						ignoreId = not tonumber(szVal),
					})
					if not mon.ignoreId then
						mon.ids[tonumber(szVal)] = MY_TargetMon.FormatMonItemStructure({
							enable = true,
						})
					end
					if not index then
						index = #aMonList + 1
					end
					insert(aMonList, index, mon)
					list:listbox(
						'insert',
						mon.name or mon.id,
						mon,
						{ mon = mon, monlist = aMonList },
						index
					)
					D.CheckFrame(l_config)
				end
			end, function() end, function() end, nil, '')
		end

		uiWrapper:append('WndEditBox', {
			x = x0, y = y0,
			w = 200, h = 30, placeholder = _L['Search'],
			onchange = function(text)
				l_search = text
				Search()
			end,
		})
		uiWrapper:append('WndButton2', {
			x = x1 + w1 - 60, y = y0 - 1, w = 60, h = 28,
			text = _L['Add'], onclick = function() InsertMonitor() end,
			autoenable = function() return not l_search or l_search == '' end,
		})

		-- 初始化list控件
		local function onMenu(hItem, szText, szID, data)
			local mon = data.mon
			local monlist = data.monlist
			local search = l_search and l_search ~= ''
			local t1 = {
				{
					szOption = _L['Enable'],
					bCheck = true, bChecked = mon.enable,
					fnAction = function()
						mon.enable = not mon.enable
						mon.manually = true
						D.CheckFrame(l_config)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L['Delete'],
					fnAction = function()
						list:listbox('delete', 'id', mon)
						for i, m in ipairs_r(monlist) do
							if m == mon then
								remove(monlist, i)
							end
						end
						Wnd.CloseWindow('PopupMenuPanel')
						D.CheckFrame(l_config)
					end,
				},
				{
					szOption = _L['Insert'],
					fnAction = function()
						local index = #monlist
						for i, m in ipairs_r(monlist) do
							if m == mon then
								index = i
							end
						end
						InsertMonitor(index)
					end,
					bDisable = search,
				},
				{
					szOption = _L['Move up'],
					fnAction = function()
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
					bDisable = search,
				},
				{
					szOption = _L['Move down'],
					fnAction = function()
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
					bDisable = search,
				},
				{
					szOption = _L['Rename'],
					fnAction = function()
						GetUserInput(_L['Please input name:'], function(szVal)
							szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
							if szVal ~= '' then
								list:listbox(
									'update',
									'id', mon,
									{ 'text' }, { szVal }
								)
								mon.name = szVal
								mon.manually = true
								D.CheckFrame(l_config)
							end
						end, function() end, function() end, nil, mon.name)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L('Long alias: %s', mon.longAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input long alias:'], function(szVal)
							szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
							mon.longAlias = szVal
							mon.manually = true
							D.CheckFrame(l_config)
						end, function() end, function() end, nil, mon.longAlias or mon.name)
					end,
					rgb = mon.rgbLongAlias,
					bColorTable = true,
					fnChangeColor = function(_, r, g, b)
						mon.rgbLongAlias = { r, g, b }
						mon.manually = true
						D.CheckFrame(l_config)
					end,
				},
				{
					szOption = _L('Short alias: %s', mon.shortAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input short alias:'], function(szVal)
							szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
							mon.shortAlias = szVal
							mon.manually = true
							D.CheckFrame(l_config)
						end, function() end, function() end, nil, mon.shortAlias or mon.name)
					end,
					rgb = mon.rgbShortAlias,
					bColorTable = true,
					fnChangeColor = function(_, r, g, b)
						mon.rgbShortAlias = { r, g, b }
						mon.manually = true
						D.CheckFrame(l_config)
					end,
				},
			}
			-- 自身心法
			local t2 = {
				szOption = _L['Self kungfu'],
				{
					szOption = _L['All kungfus'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = mon.kungfus.all,
					fnAction = function()
						mon.kungfus.all = not mon.kungfus.all
						mon.manually = true
						D.CheckFrame(l_config)
					end,
				},
			}
			for _, dwForceID in pairs_c(FORCE_TYPE) do
				for i, dwKungfuID in ipairs(ForceIDToKungfuIDs(dwForceID) or {}) do
					insert(t2, {
						szOption = MY.GetSkillName(dwKungfuID, 1),
						rgb = {MY.GetForceColor(dwForceID, 'foreground')},
						bCheck = true,
						bChecked = mon.kungfus[dwKungfuID],
						fnAction = function()
							mon.kungfus[dwKungfuID] = not mon.kungfus[dwKungfuID]
							mon.manually = true
							D.CheckFrame(l_config)
						end,
						fnDisable = function() return mon.kungfus.all end,
					})
				end
			end
			insert(t1, t2)
			-- 目标心法
			local t2 = {
				szOption = _L['Target kungfu'],
				{
					szOption = _L['All kungfus'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = mon.tarkungfus.all,
					fnAction = function()
						mon.tarkungfus.all = not mon.tarkungfus.all
						D.CheckFrame(l_config)
					end,
				},
				{
					szOption = _L['NPC'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = mon.tarkungfus.npc,
					fnAction = function()
						mon.tarkungfus.npc = not mon.tarkungfus.npc
						D.CheckFrame(l_config)
					end,
					fnDisable = function() return mon.tarkungfus.all end,
				},
			}
			for _, dwForceID in pairs_c(FORCE_TYPE) do
				for i, dwKungfuID in ipairs(ForceIDToKungfuIDs(dwForceID) or {}) do
					insert(t2, {
						szOption = MY.GetSkillName(dwKungfuID, 1),
						rgb = {MY.GetForceColor(dwForceID, 'foreground')},
						bCheck = true,
						bChecked = mon.tarkungfus[dwKungfuID],
						fnAction = function()
							mon.tarkungfus[dwKungfuID] = not mon.tarkungfus[dwKungfuID]
							D.CheckFrame(l_config)
						end,
						fnDisable = function() return mon.tarkungfus.all end,
					})
				end
			end
			insert(t1, t2)
			-- 出现声音
			local t2 = { szOption = _L['Play sound when appear'] }
			for _, sound in ipairs(SOUNDS) do
				local bChecked = false
				for _, v in ipairs(mon.soundAppear) do
					if v == sound.dwID then
						bChecked = true
						break
					end
				end
				insert(t2, {
					szOption = sound.szName,
					bCheck = true,
					bChecked = bChecked,
					fnAction = function()
						if bChecked then
							for i, v in ipairs_r(mon.soundAppear) do
								if v == sound.dwID then
									remove(mon.soundAppear, i)
								end
							end
						else
							insert(mon.soundAppear, sound.dwID)
						end
					end,
				})
			end
			insert(t1, t2)
			-- 消失声音
			local t2 = { szOption = _L['Play sound when disappear'] }
			for _, sound in ipairs(SOUNDS) do
				local bChecked = false
				for _, v in ipairs(mon.soundDisappear) do
					if v == sound.dwID then
						bChecked = true
						break
					end
				end
				insert(t2, {
					szOption = sound.szName,
					bCheck = true,
					bChecked = bChecked,
					fnAction = function()
						if bChecked then
							for i, v in ipairs_r(mon.soundDisappear) do
								if v == sound.dwID then
									remove(mon.soundDisappear, i)
								end
							end
						else
							insert(mon.soundDisappear, sound.dwID)
						end
					end,
				})
			end
			insert(t1, t2)
			-- ID设置
			if not empty(mon.ids) then
				insert(t1, { bDevide = true })
				insert(t1, { szOption = _L['Ids'], bDisable = true })
				insert(t1, {
					szOption = _L['All ids'],
					bCheck = true,
					bChecked = mon.ignoreId,
					fnAction = function()
						mon.ignoreId = not mon.ignoreId
						mon.manually = true
						D.CheckFrame(l_config)
					end,
					szIcon = 'fromiconid',
					nFrame = mon.iconid,
					nIconWidth = 22,
					nIconHeight = 22,
					szLayer = 'ICON_RIGHTMOST',
					fnClickIcon = function()
						UI.OpenIconPanel(function(dwIcon)
							mon.manually = true
							mon.iconid = dwIcon
						end)
						Wnd.CloseWindow('PopupMenuPanel')
					end,
				})
				for dwID, info in pairs(mon.ids) do
					local t2 = {
						szOption = dwID,
						bCheck = true,
						bChecked = info.enable,
						fnAction = function()
							info.enable = not info.enable
							mon.manually = true
							D.CheckFrame(l_config)
						end,
						fnDisable = function()
							return mon.ignoreId
						end,
						szIcon = 'fromiconid',
						nFrame = info.iconid,
						nIconWidth = 22,
						nIconHeight = 22,
						szLayer = 'ICON_RIGHTMOST',
						fnClickIcon = function()
							if mon.ignoreId then
								return
							end
							UI.OpenIconPanel(function(dwIcon)
								info.iconid = dwIcon
								mon.manually = true
								D.CheckFrame(l_config)
							end)
							Wnd.CloseWindow('PopupMenuPanel')
						end,
					}
					if not empty(info.levels) then
						insert(t2, { szOption = _L['Levels'], bDisable = true })
						insert(t2, MENU_DIVIDER)
						insert(t2, {
							szOption = _L['All levels'],
							bCheck = true,
							bChecked = info.ignoreLevel,
							fnAction = function()
								info.ignoreLevel = not info.ignoreLevel
								mon.manually = true
								D.CheckFrame(l_config)
							end,
							szIcon = 'fromiconid',
							nFrame = info.iconid,
							nIconWidth = 22,
							nIconHeight = 22,
							szLayer = 'ICON_RIGHTMOST',
							fnClickIcon = function()
								if mon.ignoreId or info.ignoreLevel then
									return
								end
								UI.OpenIconPanel(function(dwIcon)
									info.iconid = dwIcon
									mon.manually = true
								end)
								Wnd.CloseWindow('PopupMenuPanel')
							end,
						})
						local tLevels = {}
						for nLevel, infoLevel in pairs(info.levels) do
							insert(tLevels, {
								nLevel, {
									szOption = nLevel,
									bCheck = true,
									bChecked = infoLevel.enable,
									fnAction = function()
										infoLevel.enable = not infoLevel.enable
										mon.manually = true
										D.CheckFrame(l_config)
									end,
									fnDisable = function()
										return mon.ignoreId or info.ignoreLevel
									end,
									szIcon = 'fromiconid',
									nFrame = infoLevel.iconid,
									nIconWidth = 22,
									nIconHeight = 22,
									szLayer = 'ICON_RIGHTMOST',
									fnClickIcon = function()
										UI.OpenIconPanel(function(dwIcon)
											infoLevel.iconid = dwIcon
											mon.manually = true
											D.CheckFrame(l_config)
										end)
										Wnd.CloseWindow('PopupMenuPanel')
									end,
								}
							})
						end
						sort(tLevels, function(a, b) return a[1] < b[1] end)
						for _, p in ipairs(tLevels) do
							insert(t2, p[2])
						end
						insert(t2, MENU_DIVIDER)
					end
					insert(t2, {
						szOption = _L['Manual add level'],
						fnAction = function()
							GetUserInput(_L['Please input level:'], function(szVal)
								local nLevel = tonumber(string.gsub(szVal, '^%s*(.-)%s*$', '%1'), 10)
								if nLevel then
									if info.levels[nLevel] then
										return
									end
									local dwIconID = 13
									if l_config.type == 'SKILL' then
										dwIconID = Table_GetSkillIconID(dwID, nLevel) or dwIconID
									else
										dwIconID = Table_GetBuffIconID(dwID, nLevel) or dwIconID
									end
									info.levels[nLevel] = D.FormatMonItemLevelStructure({ iconid = dwIconID })
									mon.manually = true
									D.CheckFrame(l_config)
								end
							end, function() end, function() end, nil, nil)
						end,
					})
					insert(t2, {
						szOption = _L['Delete'],
						fnAction = function()
							mon.ids[dwID] = nil
							mon.manually = true
							D.CheckFrame(l_config)
						end,
					})
					insert(t1, t2)
				end
			end
			insert(t1, { bDevide = true })
			insert(t1, {
				szOption = _L['Auto capture by name'],
				bCheck = true, bChecked = mon.capture,
				fnAction = function()
					mon.capture = not mon.capture
					mon.manually = true
					D.CheckFrame(l_config)
				end,
			})
			insert(t1, {
				szOption = _L['Manual add id'],
				fnAction = function()
					GetUserInput(_L['Please input id:'], function(szVal)
						local dwID = tonumber(string.gsub(szVal, '^%s*(.-)%s*$', '%1'), 10)
						if dwID then
							if mon.ids[dwID] then
								return
							end
							local dwIconID = 13
							if l_config.type == 'SKILL' then
								local dwLevel = GetClientPlayer().GetSkillLevel(dwID) or 1
								dwIconID = Table_GetSkillIconID(dwID, dwLevel) or dwIconID
							else
								dwIconID = Table_GetBuffIconID(dwID, 1) or 13
							end
							mon.ids[dwID] = D.FormatMonItemStructure({ iconid = dwIconID })
							mon.manually = true
							D.CheckFrame(l_config)
						end
					end, function() end, function() end, nil, nil)
				end,
			})
			return t1
		end
		list:listbox('onmenu', onMenu)

		function OpenConfig(config)
			l_config = config
			Search()
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
		x, y = GenePS(ui, config, x, y, w, h, OpenConfig)
		y = y + 10
	end
	y = y + 10

	x = (w - 380) / 2
	ui:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Create'],
		onclick = function()
			local config = MY.FormatDataStructure(nil, ConfigTemplate)
			insert(Config, config)
			D.CheckFrame(config)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	x = x + 70
	ui:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Import'],
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
				if D.FormatConfigStructure(config) then
					for i, cfg in ipairs_r(Config) do
						if config.uuid and config.uuid == cfg.uuid then
							D.CloseFrame(cfg)
							remove(Config, i)
							replaceCount = replaceCount + 1
						end
					end
					insert(Config, config)
					importCount = importCount + 1
				end
			end
			D.CheckAllFrame()
			MY.SwitchTab('MY_TargetMon', true)
			MY.Sysmsg({ _L('Import successed, %d imported and %d replaced.', importCount, replaceCount) })
			OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Import successed, %d imported and %d replaced.', importCount, replaceCount))
		end,
	})
	x = x + 70
	ui:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Export'],
		menu = function()
			local configs = {}
			local menu = {}
			local indent = IsCtrlKeyDown() and '\t' or nil
			for _, config in ipairs(Config) do
				insert(menu, {
					bCheck = true,
					szOption = config.caption,
					fnAction = function()
						for i, cfg in ipairs_r(configs) do
							if cfg == config then
								remove(configs, i)
								return
							end
						end
						insert(configs, config)
					end,
				})
			end
			if #menu > 0 then
				insert(menu, MENU_DIVIDER)
			end
			insert(menu, {
				szOption = _L['Ensure export'],
				fnAction = function()
					local file = MY.FormatPath({
						'export/TargetMon/$name@$server@'
							.. MY.FormatTime('yyyyMMddhhmmss')
							.. '.jx3dat',
						MY_DATA_PATH.GLOBAL,
					})
					local cfgs = {}
					for i, config in ipairs(configs) do
						insert(cfgs, D.FormatSavingConfig(config))
					end
					MY.SaveLUAData(file, cfgs, indent)
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
	ui:append('WndButton2', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Save As Default'],
		onclick = function()
			MY.Confirm(_L['Sure to save as default?'], function()
				MY.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, D.FormatSavingConfigs(Config))
			end)
		end,
	})
	x = x + 90
	ui:append('WndButton2', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Reset Default'],
		tip = _L['Hold ctrl to reset original default.'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		onclick = function()
			local ctrl = IsCtrlKeyDown()
			MY.Confirm(_L[ctrl and 'Sure to reset original default?' or 'Sure to reset default?'], function()
				D.LoadConfig(true, ctrl)
				MY.SwitchTab('MY_TargetMon', true)
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
MY.RegisterPanel('MY_TargetMon', _L['Target monitor'], _L['Target'], 'ui/Image/ChannelsPanel/NewChannels.UITex|141', { 255, 255, 0, 200 }, PS)


local ui = {
	GetSound                     = D.GetSound,
	GetTarget                    = D.GetTarget,
	GetFrameData                 = D.GetFrameData,
	FormatConfigStructure        = D.FormatConfigStructure,
	FormatMonStructure           = D.FormatMonStructure,
	FormatMonItemStructure       = D.FormatMonItemStructure,
	FormatMonItemLevelStructure  = D.FormatMonItemLevelStructure,
}
MY_TargetMon = setmetatable({}, { __index = ui, __newindex = function() end, __metatable = true })
