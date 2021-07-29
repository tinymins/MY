--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Doodad 物品采集拾取助手
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKPDoodad'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_GKPDoodad', _L['General'], {
	bOpenLoot = { -- 自动打开掉落
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bOpenLootEvenFight = { -- 战斗中也打开
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowName = { -- 显示物品名称
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tNameColor = { -- 头顶名称颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 196, 64, 255 },
	},
	nNameFont = { -- 头顶名称字体
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Number,
		xDefaultValue = 40,
	},
	fNameScale = { -- 头顶名称缩放
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	bMiniFlag = { -- 显示小地图标记
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bInteract = { -- 自动采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bInteractEvenFight = { -- 战斗中也采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tCraft = { -- 草药、矿石列表
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Map(Schema.Number, Schema.Boolean),
		xDefaultValue = {},
	},
	bQuestDoodad = { -- 任务物品
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAllDoodad = { -- 其它全部
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bCustom = { -- 启用自定义
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	szCustom = { -- 自定义列表
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
	bRecent = { -- 启用自动最近5分钟采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})
local O2 = {}
RegisterCustomData('MY_GKPDoodad.tNameColor')
RegisterCustomData('MY_GKPDoodad.tCraft')
RegisterCustomData('MY_GKPDoodad.szCustom')

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local INI_SHADOW = PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini'

local function GetDoodadTemplateName(dwID)
	local doodad = GetDoodadTemplate(dwID)
	if not doodad then
		return
	end
	return doodad.szName
end

local function IsShielded()
	return LIB.IsInShieldedMap() and LIB.IsShieldedVersion('TARGET')
end

local function IsAutoInteract()
	return O.bInteract and not IsShiftKeyDown() and not Station.Lookup('Normal/MY_GKPLoot') and not LIB.IsShieldedVersion('MY_GKPDoodad')
end

local D = {
	-- 草药、矿石列表
	tCraft = {
		1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
		1010, 1011, 1012, 1015, 1016, 1017, 1018, 1019, 2641,
		2642, 2643, 3321, 3358, 3359, 3360, 3361, 4227, 4228,
		5659, 5660,
		0, -- switch
		1020, 1021, 1022, 1023, 1024, 1025, 1027, 2644, 2645,
		4229, 4230, 5661, 5662,
	},
	tCustom = {}, -- 自定义列表
	tRecent = {}, -- 最近采集的东西、自动继续采集
	tDoodad = {}, -- 待处理的 doodad 列表
	nToLoot = 0,  -- 待拾取处理数量（用于修复判断）
}

function D.IsCustomDoodad(doodad)
	if O.bCustom and D.tCustom[doodad.szName] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			return GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

function D.IsRecentDoodad(doodad)
	if O.bRecent and D.tRecent[doodad.dwTemplateID] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			return GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

-- try to add
function D.TryAdd(dwID, bDelay)
	if bDelay then
		return LIB.DelayCall('MY_GKPDoodad__DelayTryAdd' .. dwID, 500, function() D.TryAdd(dwID) end)
	end
	local doodad = GetDoodad(dwID)
	if doodad then
		local data, me = nil, GetClientPlayer()
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			if O.bOpenLoot and doodad.CanLoot(me.dwID) then
				data = { loot = true }
			elseif D.IsCustomDoodad(doodad) then
				data = { craft = true }
			elseif D.IsRecentDoodad(doodad) then
				data = { recent = true }
			end
		elseif O.bQuestDoodad and (doodad.dwTemplateID == 3713 or doodad.dwTemplateID == 3714) then
			data = { craft = true }
		elseif O.tCraft[doodad.dwTemplateID] then
			data = { craft = true }
		elseif D.IsCustomDoodad(doodad) then
			data = { craft = true }
		elseif D.IsRecentDoodad(doodad) then
			data = { recent = true }
		elseif doodad.HaveQuest(me.dwID) then
			if O.bQuestDoodad then
				data = { quest = true }
			end
		elseif doodad.dwTemplateID == 4733 or doodad.dwTemplateID == 4734 and O.bQuestDoodad then
			data = { craft = true }
		elseif O.bAllDoodad and CanSelectDoodad(doodad.dwID) then
			data = { other = true }
		end
		if data then
			D.tDoodad[dwID] = data
			D.bUpdateLabel = true
		end
	end
end

-- remove doodad
function D.Remove(dwID)
	local data = D.tDoodad[dwID]
	if data then
		D.tDoodad[dwID] = nil
		D.bUpdateLabel = true
	end
end

-- reload doodad
function D.RescanNearby()
	D.tDoodad = {}
	for _, k in ipairs(LIB.GetNearDoodadID()) do
		D.TryAdd(k)
	end
	D.bUpdateLabel = true
end

function D.ReloadCustom()
	local t = {}
	local szText = StringReplaceW(O.szCustom, _L['|'], '|')
	for _, v in ipairs(LIB.SplitString(szText, '|')) do
		v = LIB.TrimString(v)
		if v ~= '' then
			t[v] = true
		end
	end
	D.tCustom = t
	D.tRecent = {}
	D.RescanNearby()
end

LIB.RegisterInit('MY_GKPDoodad', function()
	for _, k in ipairs({'tNameColor', 'tCraft', 'szCustom'}) do
		if O2[k] then
			SafeCall(Set, O, k, O2[k])
			O2[k] = nil
		end
	end
	-- 粮草堆，散落的镖银，阵营首领战利品、押运奖赏
	if IsEmpty(O.szCustom) then
		local t = {}
		for _, v in ipairs({ 3874, 4255, 4315, 5622, 5732 }) do
			local szName = GetDoodadTemplateName(v)
			if szName then
				insert(t, szName)
			end
		end
		O.szCustom = concat(t, '|')
		D.ReloadCustom()
	end
end)

-- switch name
function D.CheckShowName()
	local hName = UI.GetShadowHandle('MY_GKPDoodad')
	local bShowName = O.bShowName and not IsShielded()
	if bShowName and not D.pLabel then
		D.pLabel = hName:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Name')
		LIB.BreatheCall('MY_GKPDoodad#HeadName', function()
			if D.bUpdateLabel then
				D.bUpdateLabel = false
				D.OnUpdateHeadName()
			end
		end)
		D.bUpdateLabel = true
	elseif not bShowName and D.pLabel then
		hName:Clear()
		D.pLabel = nil
		LIB.BreatheCall('MY_GKPDoodad#HeadName', false)
	end
end

-- find & get opened dooad ID
function D.GetOpenDoodadID()
	local dwID = D.dwOpenID
	if dwID then
		D.dwOpenID = nil
	end
	return dwID
end

-------------------------------------
-- 事件处理
-------------------------------------
-- head name
function D.OnUpdateHeadName()
	local sha = D.pLabel
	if not sha then
		return
	end
	local r, g, b = unpack(O.tNameColor)
	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()
	for k, v in pairs(D.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(GetClientPlayer().dwID)) then
				D.Remove(k)
			else
				local szName = tar.szName
				if tar.dwTemplateID == 3713 or tar.dwTemplateID == 3714 then
					szName = Table_GetNpcTemplateName(1622)
				end
				local nR, nG, nB = r, g, b
				if v.other then
					nR = nR * 0.85
					nG = nG * 0.85
					nB = nB * 0.85
				end
				sha:AppendDoodadID(tar.dwID, nR, nG, nB, 255, 128, O.nNameFont, szName, 0, O.fNameScale)
			end
		end
	end
	sha:Show()
end

-- auto interact
function D.OnAutoDoodad()
	local me = GetClientPlayer()
	-- auto interact
	if not me or LIB.GetOTActionState(me) ~= CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_IDLE
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		-- or IsDialoguePanelOpened()
	then
		return
	end
	for k, v in pairs(D.tDoodad) do
		local doodad, bIntr, bOpen = GetDoodad(k), false, false
		if not doodad then
			D.Remove(k)
		elseif doodad.CanDialog(me) then -- 若存在却不能对话只简单保留
			if v.loot then -- 尸体只摸一次
				bOpen = (not me.bFightState or O.bOpenLootEvenFight) and doodad.CanLoot(me.dwID)
				if bOpen then
					D.dwOpenID = k
				end
			elseif v.craft or doodad.HaveQuest(me.dwID) then -- 任务和普通道具尝试 5 次
				bIntr = (not me.bFightState or O.bInteractEvenFight) and not me.bOnHorse and IsAutoInteract()
				-- 宴席只能吃队友的
				if doodad.dwOwnerID ~= 0 and IsPlayer(doodad.dwOwnerID) and not LIB.IsParty(doodad.dwOwnerID) then
					bIntr = false
				end
			elseif v.recent then -- 最近采集的
				bIntr = true
				-- 从最近采集移除、意味着如果玩家打断这次采集就不会自动继续采集
				D.tRecent[doodad.dwTemplateID] = nil
				for dwID, _ in pairs(D.tDoodad) do
					local d = GetDoodad(dwID)
					if d and d.dwTemplateID == doodad.dwTemplateID then
						D.TryAdd(dwID, true)
						D.tDoodad[dwID] = nil
					end
				end
				D.bUpdateLabel = true
			end
		end
		if bOpen then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto open [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			LIB.BreatheCall('AutoDoodad', 500)
			return LIB.OpenDoodad(me, doodad)
		end
		if bIntr then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto interact [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			LIB.BreatheCall('AutoDoodad', 500)
			return LIB.InteractDoodad(k)
		end
	end
end

function D.CloseLootWindow()
	local me = GetClientPlayer()
	if me and LIB.GetOTActionState(me) == CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_PICKING then
		me.OnCloseLootWindow()
	end
end

-- open doodad (loot)
function D.OnOpenDoodad(dwID)
	-- 摸尸体且开了插件拾取框 可以安全的起身
	if D.tDoodad[dwID] and D.tDoodad[dwID].loot and MY_GKPLoot.IsEnabled() then
		LIB.DelayCall('MY_GKPDoodad__OnOpenDoodad', 150, D.CloseLootWindow)
	end
	D.Remove(dwID) -- 从列表删除
	local doodad = GetDoodad(dwID)
	if doodad then
		if D.IsCustomDoodad(doodad) then --庖丁
			D.tDoodad[dwID] = { craft = true }
			D.bUpdateLabel = true
		elseif D.IsRecentDoodad(doodad) then
			D.tDoodad[dwID] = { recent = true }
			D.bUpdateLabel = true
		end
	end
	LIB.Debug(_L['MY_GKPDoodad'], 'OnOpenDoodad [' .. (doodad and doodad.szName or dwID) .. ']', DEBUG_LEVEL.LOG)
end

-- save manual doodad
function D.OnLootDoodad()
	if not O.bRecent then
		return
	end
	local doodad = GetDoodad(arg0)
	if not doodad then
		return
	end
	local t = GetDoodadTemplate(doodad.dwTemplateID)
	if t.dwCraftID == CONSTANT.CRAFT_TYPE.MINING
	or t.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM
	or t.dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING then
		D.tRecent[doodad.dwTemplateID] = true -- 加入最近采集列表
		for _, d in ipairs(LIB.GetNearDoodad()) do
			if d.dwTemplateID == doodad.dwTemplateID then
				D.TryAdd(d.dwID)
			end
		end
		D.bUpdateLabel = true
	end
end

-- mini flag
function D.OnUpdateMiniFlag()
	if not O.bMiniFlag or IsShielded() then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	for k, v in pairs(D.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(me.dwID)) then
				D.Remove(k)
			else
				local dwType, nF1, nF2 = 5, 169, 48
				local tpl = GetDoodadTemplate(tar.dwTemplateID)
				if v.quest then
					nF1 = 114
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.MINING then	-- 采金类
					nF1, nF2 = 16, 47
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM then	-- 神农类
					nF1 = 2
				end
				LIB.UpdateMiniFlag(dwType, tar, nF1, nF2)
			end
		end
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
LIB.RegisterEvent('LOADING_ENDING', D.CheckShowName)
LIB.RegisterEvent('DOODAD_ENTER_SCENE', function() D.TryAdd(arg0, true) end)
LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function() D.Remove(arg0) end)
LIB.RegisterEvent('OPEN_DOODAD', D.OnLootDoodad)
LIB.RegisterEvent('HELP_EVENT', function()
	if arg0 == 'OnOpenpanel' and arg1 == 'LOOT' and O.bOpenLoot then
		local dwOpenID =  D.GetOpenDoodadID()
		if dwOpenID then
			D.OnOpenDoodad(dwOpenID)
		end
	end
end)
LIB.RegisterEvent('QUEST_ACCEPTED', function()
	if O.bQuestDoodad then
		D.RescanNearby()
	end
end)
LIB.RegisterInit('MY_GKPDoodad__BC', function()
	LIB.BreatheCall('MY_GKPDoodad__AutoDoodad', D.OnAutoDoodad)
	LIB.BreatheCall('MY_GKPDoodad__UpdateMiniFlag', D.OnUpdateMiniFlag, 500)
end)
LIB.RegisterExit('MY_GKPDoodad__BC', function()
	LIB.BreatheCall('MY_GKPDoodad__AutoDoodad', false)
	LIB.BreatheCall('MY_GKPDoodad__UpdateMiniFlag', false)
end)


-------------------------------------
-- 设置界面
-------------------------------------
local PS = { nPriority = 2.1 }

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local W, H = ui:Size()
	local X, Y = 40, 20
	local nX, nY, nLFY = X, Y, Y
	local nLineHeightS, nLineHeightM, nLineHeightL = 22, 28, 32

	-- loot
	ui:Append('Text', { text = _L['Pickup helper'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, Y + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable auto pickup'],
		checked = O.bOpenLoot,
		oncheck = function(bChecked)
			O.bOpenLoot = bChecked
			D.RescanNearby()
			ui:Fetch('Check_Fight'):Enable(bChecked)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		name = 'Check_Fight', x = nX, y = nY,
		text = _L['Pickup in fight'],
		checked = O.bOpenLootEvenFight,
		enable = O.bOpenLoot,
		oncheck = function(bChecked)
			O.bOpenLootEvenFight = bChecked
			D.RescanNearby()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX, nY = X + 10, nY + nLineHeightM
	nLFY = nY

	nX, nY, nLFY = MY_GKPLoot.OnPanelActivePartial(ui, X, Y, W, H, nLineHeightM, nX, nY, nLFY)

	-- doodad
	nX, nY = X, nY + nLineHeightL
	ui:Append('Text', { text = _L['Craft assit'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show the head name'],
		checked = O.bShowName,
		oncheck = function()
			O.bShowName = not O.bShowName
			D.CheckShowName()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	nX = ui:Append('Shadow', {
		name = 'Shadow_Color', x = nX + 2, y = nY + 4, w = 18, h = 18,
		color = O.tNameColor,
		onclick = function()
			UI.OpenColorPicker(function(r, g, b)
				ui:Fetch('Shadow_Color'):Color(r, g, b)
				O.tNameColor = { r, g, b }
				D.RescanNearby()
			end)
		end,
		autoenable = function() return O.bShowName end,
	}):Pos('BOTTOMRIGHT') + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 65,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				O.nNameFont = nFont
				D.bUpdateLabel = true
			end)
		end,
		autoenable = function() return O.bShowName end,
	}):Width() + 5

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 150,
		textfmt = function(val) return _L('Font scale is %d%%.', val) end,
		range = {10, 500},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.fNameScale * 100,
		onchange = function(val)
			O.fNameScale = val / 100
			D.bUpdateLabel = true
		end,
		autoenable = function() return O.bShowName end,
	}):Width() + 5

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		text = _L['Display minimap flag'],
		x = nX, y = nY,
		checked = O.bMiniFlag,
		oncheck = function(bChecked)
			O.bMiniFlag = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	if not LIB.IsShieldedVersion('MY_GKPDoodad') then
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Auto craft'],
			checked = O.bInteract,
			oncheck = function(bChecked)
				O.bInteract = bChecked
				D.RescanNearby()
				ui:Fetch('Check_Interact_Fight'):Enable(bChecked)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		nX = ui:Append('WndCheckBox', {
			name = 'Check_Interact_Fight', x = nX, y = nY,
			text = _L['Interact in fight'],
			checked = O.bInteractEvenFight,
			enable = O.bInteract,
			oncheck = function(bChecked)
				O.bInteractEvenFight = bChecked
				D.RescanNearby()
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- craft
	nX, nY = X + 10, nY + nLineHeightM
	for _, v in ipairs(D.tCraft) do
		if v == 0 then
			nY = nY + 8
			if nX ~= 10 then
				nY = nY + nLineHeightS
				nX = X + 10
			end
		else
			local szName = GetDoodadTemplateName(v)
			if szName then
				ui:Append('WndCheckBox', {
					x = nX, y = nY,
					text = szName,
					checked = O.tCraft[v],
					oncheck = function(bChecked)
						if bChecked then
							O.tCraft[v] = true
						else
							O.tCraft[v] = nil
						end
						O.tCraft = O.tCraft
						D.RescanNearby()
					end,
					autoenable = function() return O.bShowName or O.bInteract end,
				})
				nX = nX + 90
				if nX > 500 then
					nX = X + 10
					nY = nY + nLineHeightS
				end
			end
		end
	end
	if nX == X + 10 then
		nY = nY - nLineHeightS + nLineHeightM
	else
		nY = nY + nLineHeightM
	end

	nX = X + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Quest items'],
		checked = O.bQuestDoodad,
		oncheck = function(bChecked)
			O.bQuestDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Recent items'],
		checked = O.bRecent,
		oncheck = function(bChecked)
			O.bRecent = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All other'],
		checked = O.bAllDoodad,
		oncheck = function(bChecked)
			O.bAllDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	-- custom
	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		text = _L['Customs (split by | )'],
		x = nX, y = nY,
		checked = O.bCustom,
		oncheck = function(bChecked)
			O.bCustom = bChecked
			D.RescanNearby()
			ui:Fetch('Edit_Custom'):Enable(bChecked)
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	ui:Append('WndEditBox', {
		name = 'Edit_Custom',
		x = nX, y = nY, w = 360, h = 27,
		limit = 1024, text = O.szCustom,
		enable = O.bCustom,
		onchange = function(szText)
			O.szCustom = szText
			D.ReloadCustom()
		end,
		tip = function()
			if LIB.IsShieldedVersion('MY_GKPDoodad') then
				return
			end
			return _L['Tip: Enter the name of dead animals can be automatically Paoding!']
		end,
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return (O.bShowName or O.bInteract) and O.bCustom end,
	})
end
LIB.RegisterPanel(_L['General'], 'MY_GKPDoodad', _L['MY_GKPLoot'], 90, PS)

-- Global exports
do
local settings = {
	name = 'MY_GKPDoodad',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'tNameColor',
				'tCraft',
				'szCustom',
			},
			root = O2,
		},
	},
}
MY_GKPDoodad = LIB.CreateModule(settings)
end
