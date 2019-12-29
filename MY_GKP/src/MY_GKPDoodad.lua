--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Doodad ��Ʒ�ɼ�ʰȡ����
-- @author   : ���� @˫���� @׷����Ӱ
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKPDoodad'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local O = {
	bOpenLoot = false, -- �Զ��򿪵���
	bOpenLootEvenFight = false, -- ս����Ҳ��
	bShowName = false, -- ��ʾ��Ʒ����
	tNameColor = { 196, 64, 255 }, -- ͷ��������ɫ
	bMiniFlag = false, -- ��ʾС��ͼ���
	bInteract = false, -- �Զ��ɼ�
	bInteractEvenFight = false, -- ս����Ҳ�ɼ�
	tCraft = {}, -- ��ҩ����ʯ�б�
	bQuestDoodad = false, -- ������Ʒ
	bAllDoodad = false, -- ����ȫ��
	bCustom = true, -- �����Զ���
	szCustom = '', -- �Զ����б�
}
RegisterCustomData('MY_GKPDoodad.bOpenLoot')
RegisterCustomData('MY_GKPDoodad.bOpenLootEvenFight')
RegisterCustomData('MY_GKPDoodad.bShowName')
RegisterCustomData('MY_GKPDoodad.tNameColor')
RegisterCustomData('MY_GKPDoodad.bMiniFlag')
RegisterCustomData('MY_GKPDoodad.bInteract')
RegisterCustomData('MY_GKPDoodad.bInteractEvenFight')
RegisterCustomData('MY_GKPDoodad.tCraft')
RegisterCustomData('MY_GKPDoodad.bQuestDoodad')
RegisterCustomData('MY_GKPDoodad.bAllDoodad')
RegisterCustomData('MY_GKPDoodad.bCustom')
RegisterCustomData('MY_GKPDoodad.szCustom')

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------
local INI_SHADOW = PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini'

local function GetDoodadTemplateName(dwID)
	return GetDoodadTemplate(dwID).szName
end

local function IsShielded()
	return LIB.IsInShieldedMap() and LIB.IsShieldedVersion()
end

local function IsAutoInteract()
	return O.bInteract and not IsShiftKeyDown() and not Station.Lookup('Normal/MY_GKP_Loot') and not LIB.IsShieldedVersion()
end

local D = {
	-- ��ҩ����ʯ�б�
	tCraft = {
		1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
		1010, 1011, 1012, 1015, 1016, 1017, 1018, 1019, 2641,
		2642, 2643, 3321, 3358, 3359, 3360, 3361, 4227, 4228,
		5659, 5660,
		0, -- switch
		1020, 1021, 1022, 1023, 1024, 1025, 1027, 2644, 2645,
		4229, 4230, 5661, 5662,
	},
	tCustom = {}, -- �Զ����б�
	tDoodad = {}, -- �������� doodad �б�
	nToLoot = 0,  -- ��ʰȡ���������������޸��жϣ�
}

-- try to add
function D.TryAdd(dwID, bDelay)
	local doodad = GetDoodad(dwID)
	if doodad then
		local data, me = nil, GetClientPlayer()
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			if bDelay then
				return LIB.DelayCall(500, function() D.TryAdd(dwID) end)
			end
			if O.bOpenLoot and doodad.CanLoot(me.dwID) then
				data = { loot = true }
			elseif O.bCustom and D.tCustom[doodad.szName]
				and GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING
			then
				data = { craft = true }
			end
		elseif O.bQuestDoodad and (doodad.dwTemplateID == 3713 or doodad.dwTemplateID == 3714) then
			data = { craft = true }
		elseif O.tCraft[doodad.szName] or (O.bCustom and D.tCustom[doodad.szName]) then
			data = { craft = true }
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
	D.RescanNearby()
end

LIB.RegisterInit('MY_GKPDoodad', function()
	-- ���ݶѣ�ɢ�����������Ӫ����ս��Ʒ��Ѻ�˽���
	if IsEmpty(O.szCustom) then
		local t = {}
		for _, v in ipairs({ 3874, 4255, 4315, 5622, 5732 }) do
			insert(t, GetDoodadTemplateName(v))
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
-- �¼�����
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
				sha:AppendDoodadID(tar.dwID, r, g, b, 255, 128, 40, szName, 0, 1)
			end
		end
	end
	sha:Show()
end

-- auto interact
function D.OnAutoDoodad()
	local me = GetClientPlayer()
	-- auto interact
	if not me or me.GetOTActionState() ~= 0
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		-- or IsDialoguePanelOpened()
	then
		return
	end
	for k, v in pairs(D.tDoodad) do
		local doodad, bKeep, bIntr = GetDoodad(k), false, false
		if not doodad or not doodad.CanDialog(me) then
			-- ������ȴ���ܶԻ�ֻ�򵥱���
			bKeep = doodad ~= nil
		elseif v.loot then -- ʬ��ֻ��һ��
			bKeep = true -- ���� opendoodad ��ɾ��
			bIntr = (not me.bFightState or O.bOpenLootEvenFight) and doodad.CanLoot(me.dwID)
			if bIntr then
				D.dwOpenID = k
			end
		elseif v.craft or v.other or doodad.HaveQuest(me.dwID) then -- �������ͨ���߳��� 5 ��
			bKeep = true
			bIntr = (not me.bFightState or O.bInteractEvenFight) and not me.bOnHorse and IsAutoInteract()
			-- ��ϯֻ�ܳԶ��ѵ�
			if doodad.dwOwnerID ~= 0 and IsPlayer(doodad.dwOwnerID) and not LIB.IsParty(doodad.dwOwnerID) then
				bIntr = false
			end
		end
		if not bKeep then
			D.Remove(k)
		end
		if bIntr then
			LIB.Debug(_L['MY_GKPDoodad'], 'auto interact [' .. doodad.szName .. ']', DEBUG_LEVEL.LOG)
			LIB.BreatheCall('AutoDoodad', 500)
			return InteractDoodad(k)
		end
	end
end

-- open doodad (loot)
function D.OnOpenDoodad(dwID)
	D.Remove(dwID) -- ���б�ɾ��
	local doodad = GetDoodad(dwID)
	if doodad then
		if IsAutoInteract() and O.bCustom
			and D.tCustom[doodad.szName] and GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == 3 --�Ҷ�
		then
			D.tDoodad[dwID] = { craft = true }
			D.bUpdateLabel = true
		end
	end
end

-- save manual doodad
function D.OnLootDoodad()
	if not O.bCustom then
		return
	end
	local doodad = GetDoodad(arg0)
	if not doodad or doodad.CanLoot(GetClientPlayer().dwID) then
		return
	end
	local t = GetDoodadTemplate(doodad.dwTemplateID)
	if (t.dwCraftID == CONSTANT.CRAFT_TYPE.MINING
		or t.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM
		or t.dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING)
	and not O.tCraft[doodad.szName] then
		for _, v in ipairs(D.tCraft) do
			if v == doodad.dwTemplateID then
				O.tCraft[doodad.szName] = true
				return
			end
		end
		D.tCustom[doodad.szName] = true
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
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.MINING then	-- �ɽ���
					nF1, nF2 = 16, 47
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM then	-- ��ũ��
					nF1 = 2
				end
				LIB.UpdateMiniFlag(dwType, tar, nF1, nF2)
			end
		end
	end
end

---------------------------------------------------------------------
-- ע���¼�����ʼ��
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
LIB.BreatheCall('AutoDoodad', D.OnAutoDoodad)
LIB.BreatheCall('UpdateMiniFlag', D.OnUpdateMiniFlag, 500)


-------------------------------------
-- ���ý���
-------------------------------------
local PS = {}

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 10, 10
	local nX, nY = X, Y

	-- loot
	ui:Append('Text', { text = _L['Pickup helper'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, Y + 28
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable auto pickup'],
		checked = MY_GKPDoodad.bOpenLoot,
		oncheck = function(bChecked)
			MY_GKPDoodad.bOpenLoot = bChecked
			ui:Fetch('Check_Fight'):Enable(bChecked)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		name = 'Check_Fight', x = nX, y = nY,
		text = _L['Pickup in fight'],
		checked = MY_GKPDoodad.bOpenLootEvenFight,
		enable = MY_GKPDoodad.bOpenLoot,
		oncheck = function(bChecked)
			MY_GKPDoodad.bOpenLootEvenFight = bChecked
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show 2nd kungfu fit icon'],
		checked = MY_GKP.bShow2ndKungfuLoot,
		oncheck = function()
			MY_GKP.bShow2ndKungfuLoot = not MY_GKP.bShow2ndKungfuLoot
			FireUIEvent('MY_GKP_LOOT_RELOAD')
		end,
		autoenable = function() return MY_GKP.bOn end,
	}):AutoWidth():Width() + 10

	nX, nY = X + 10, nY + 28
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable MY_GKP_Loot'],
		checked = MY_GKP.bOn,
		oncheck = function(bChecked)
			MY_GKP.bOn = bChecked
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Confirm when distribute'],
		lmenu = function()
			local t = {}
			insert(t, { szOption = _L['Category'], bDisable = true })
			for _, szKey in ipairs({
				'Huangbaba',
				'Book',
				'Pendant',
				'Outlook',
				'Pet',
				'Horse',
				'HorseEquip',
			}) do
				insert(t, {
					szOption = _L[szKey],
					bCheck = true,
					bChecked = MY_GKP_Loot.tConfirm[szKey],
					fnAction = function()
						MY_GKP_Loot.tConfirm[szKey] = not MY_GKP_Loot.tConfirm[szKey]
					end,
				})
			end
			insert(t, CONSTANT.MENU_DIVIDER)
			insert(t, { szOption = _L['Quality'], bDisable = true })
			for i, s in ipairs({
				[1] = g_tStrings.STR_WHITE,
				[2] = g_tStrings.STR_ROLLQUALITY_GREEN,
				[3] = g_tStrings.STR_ROLLQUALITY_BLUE,
				[4] = g_tStrings.STR_ROLLQUALITY_PURPLE,
				[5] = g_tStrings.STR_ROLLQUALITY_NACARAT,
			}) do
				insert(t, {
					szOption = _L('Reach %s', s),
					rgb = i == -1 and {255, 255, 255} or { GetItemFontColorByQuality(i) },
					bCheck = true, bMCheck = true,
					bChecked = i == MY_GKP_Loot.nConfirmQuality,
					fnAction = function()
						MY_GKP_Loot.nConfirmQuality = i
					end,
				})
			end
			return t
		end,
		autoenable = function() return MY_GKP.bOn end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Loot item filter'],
		menu = MY_GKP_Loot.GetFilterMenu,
		autoenable = function() return MY_GKP.bOn end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Auto pickup'],
		menu = MY_GKP_Loot.GetAutoPickupMenu,
		autoenable = function() return MY_GKP.bOn end,
	}):AutoWidth():Width() + 5

	-- doodad
	nX, nY = X, nY + 32
	ui:Append('Text', { text = _L['Craft assit'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, nY + 28
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show the head name'],
		checked = MY_GKPDoodad.bShowName,
		oncheck = function()
			MY_GKPDoodad.bShowName = not MY_GKPDoodad.bShowName
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')

	nX = ui:Append('Shadow', {
		name = 'Shadow_Color', x = nX + 2, y = nY + 4, w = 18, h = 18,
		color = MY_GKPDoodad.tNameColor,
		onclick = function()
			UI.OpenColorPicker(function(r, g, b)
				ui:Fetch('Shadow_Color'):Color(r, g, b)
				MY_GKPDoodad.tNameColor = { r, g, b }
			end)
		end,
		autoenable = function() return MY_GKPDoodad.bShowName end,
	}):Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		text = _L['Display minimap flag'],
		x = nX, y = nY,
		checked = MY_GKPDoodad.bMiniFlag,
		oncheck = function(bChecked)
			MY_GKPDoodad.bMiniFlag = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	if not LIB.IsShieldedVersion() then
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Auto craft'],
			checked = MY_GKPDoodad.bInteract,
			oncheck = function(bChecked)
				MY_GKPDoodad.bInteract = bChecked
				ui:Fetch('Check_Interact_Fight'):Enable(bChecked)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		nX = ui:Append('WndCheckBox', {
			name = 'Check_Interact_Fight', x = nX, y = nY,
			text = _L['Interact in fight'],
			checked = MY_GKPDoodad.bInteractEvenFight,
			enable = MY_GKPDoodad.bInteract,
			oncheck = function(bChecked)
				MY_GKPDoodad.bInteractEvenFight = bChecked
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- craft
	nX, nY = X + 10, nY + 32
	for _, v in ipairs(D.tCraft) do
		if v == 0 then
			nY = nY + 8
			if nX ~= 10 then
				nY = nY + 24
				nX = X + 10
			end
		else
			local k = GetDoodadTemplateName(v)
			ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = k,
				checked = MY_GKPDoodad.tCraft[k] ~= nil,
				oncheck = function(bChecked)
					if bChecked then
						MY_GKPDoodad.tCraft[k] = true
					else
						MY_GKPDoodad.tCraft[k] = nil
					end
					D.RescanNearby()
				end,
				autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
			})
			nX = nX + 90
			if nX > 500 then
				nX = X + 10
				nY = nY + 24
			end
		end
	end
	nY = nY + 8
	if nX ~= X + 10 then
		nY = nY + 24
	end

	nX = X + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Quest items'],
		checked = MY_GKPDoodad.bQuestDoodad,
		oncheck = function(bChecked)
			MY_GKPDoodad.bQuestDoodad = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All other'],
		checked = MY_GKPDoodad.bAllDoodad,
		oncheck = function(bChecked)
			MY_GKPDoodad.bAllDoodad = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	-- custom
	nX, nY = X + 10, nY + 32
	nX = ui:Append('WndCheckBox', {
		text = _L['Customs (split by | )'],
		x = nX, y = nY,
		checked = MY_GKPDoodad.bCustom,
		oncheck = function(bChecked)
			MY_GKPDoodad.bCustom = bChecked
			ui:Fetch('Edit_Custom'):Enable(bChecked)
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	ui:Append('WndEditBox', {
		name = 'Edit_Custom',
		x = nX, y = nY, w = 360, h = 27,
		limit = 1024, text = MY_GKPDoodad.szCustom,
		enable = MY_GKPDoodad.bCustom,
		onchange = function(szText)
			MY_GKPDoodad.szCustom = szText
		end,
		tip = _L['Tip: Enter the name of dead animals can be automatically Paoding!'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return (MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract) and MY_GKPDoodad.bCustom end,
	})
end
LIB.RegisterPanel('MY_GKPDoodad', _L['GKP Doodad helper'], _L['General'], 90, PS)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent',
		},
		{
			fields = {
				bOpenLoot = true,
				bOpenLootEvenFight = true,
				bShowName = true,
				tNameColor = true,
				bMiniFlag = true,
				bInteract = true,
				bInteractEvenFight = true,
				tCraft = true,
				bQuestDoodad = true,
				bAllDoodad = true,
				bCustom = true,
				szCustom = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bOpenLoot = true,
				bOpenLootEvenFight = true,
				bShowName = true,
				tNameColor = true,
				bMiniFlag = true,
				bInteract = true,
				bInteractEvenFight = true,
				tCraft = true,
				bQuestDoodad = true,
				bAllDoodad = true,
				bCustom = true,
				szCustom = true,
			},
			triggers = {
				bOpenLoot = D.RescanNearby,
				bOpenLootEvenFight = D.RescanNearby,
				bShowName = D.CheckShowName,
				tNameColor = D.RescanNearby,
				bMiniFlag = D.RescanNearby,
				bInteract = D.RescanNearby,
				bInteractEvenFight = D.RescanNearby,
				tCraft = D.RescanNearby,
				bQuestDoodad = D.RescanNearby,
				bAllDoodad = D.RescanNearby,
				bCustom = D.RescanNearby,
				szCustom = D.ReloadCustom,
			},
			root = O,
		},
	},
}
MY_GKPDoodad = LIB.GeneGlobalNS(settings)
end