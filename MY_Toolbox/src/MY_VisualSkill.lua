--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������ʾ - ս�����ӻ�
-- @author   : ���� @˫���� @׷����Ӱ
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan = math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local _C = {}
local INI_PATH = PACKET_INFO.ROOT .. 'MY_ToolBox/ui/MY_VisualSkill.ini'
local BOX_W = 55
local ANI_TIME = 450
local OUT_DISTANCE = 200
local defaultAnchor = {x = 0, y = -220, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER'}
MY_VisualSkill = {}
MY_VisualSkill.bEnable = false
MY_VisualSkill.bPenetrable = true
MY_VisualSkill.anchor = defaultAnchor
MY_VisualSkill.nVisualSkillBoxCount = 5
RegisterCustomData('MY_VisualSkill.bEnable')
RegisterCustomData('MY_VisualSkill.bPenetrable')
RegisterCustomData('MY_VisualSkill.anchor')
RegisterCustomData('MY_VisualSkill.nVisualSkillBoxCount')

local function ApplyAnchor(frame)
	local anchor = MY_VisualSkill.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	frame:CorrectPos()
end

local function GetRealIndex(nIndex, nIndexBase, nCount)
	return (nIndex + nIndexBase) % nCount
end

local function UpdateUI(frame, during)
	local percentage = min(max(during / ANI_TIME, 0), 1)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nCount = hList:GetItemCount()

	local hItem = hList:Lookup(GetRealIndex(0, frame.nIndexBase, nCount))
	if not hItem.nStartX then
		hItem.nStartX = hItem:GetRelX()
	end
	hItem:SetAlpha((1 - percentage) * 255)
	hItem:SetRelX(hItem.nStartX - (hItem.nStartX + OUT_DISTANCE) * percentage)

	local nRelX = 0
	for i = 1, nCount - 2 do
		local hItem = hList:Lookup(GetRealIndex(i, frame.nIndexBase, nCount))
		if not hItem.nStartX then
			hItem.nStartX = hItem:GetRelX()
		end
		hItem:SetAlpha(255)
		hItem:SetRelX(nRelX + (hItem.nStartX - nRelX) * (1 - percentage))
		nRelX = nRelX + hItem:GetW()
	end

	local hItem = hList:Lookup(GetRealIndex(nCount - 1, frame.nIndexBase, nCount))
	hItem:SetAlpha(percentage * 255)
	hItem:SetRelX(nRelX + OUT_DISTANCE * (1 - percentage))

	hList:FormatAllItemPos()
end

local function StartAnimation(frame)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1 do
		local hItem = hList:Lookup(i)
		hItem.nStartX = hItem:GetRelX()
	end
	frame.nTickStart = GetTickCount()
end

local function DrawUI(frame)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nOffset = MY_VisualSkill.nVisualSkillBoxCount - hList:GetItemCount() + 1
	if nOffset == 0 then
		return
	elseif nOffset > 0 then
		for i = 1, nOffset do
			hList:AppendItemFromIni(INI_PATH, 'Handle_Box'):Lookup('Box_Skill'):Hide()
			for i = hList:GetItemCount() - 1, frame.nIndexBase + 1 do
				hList:ExchangeItemIndex(i, i - 1)
			end
		end
	elseif nOffset < 0 then
		for i = nOffset, -1 do
			hList:RemoveItem(GetRealIndex(0, frame.nIndexBase, hList:GetItemCount()))
			frame.nIndexBase = frame.nIndexBase % hList:GetItemCount()
		end
	end
	local nBoxesW = BOX_W * MY_VisualSkill.nVisualSkillBoxCount
	frame:Lookup('', 'Handle_Bg/Image_Bg_11'):SetW(nBoxesW - 34)
	frame:Lookup('', 'Handle_Bg'):FormatAllItemPos()
	frame:Lookup('', ''):FormatAllItemPos()
	frame:SetW(nBoxesW + 176)
	hList:SetW(nBoxesW)
	UpdateUI(frame, ANI_TIME)
end

local function OnSkillCast(frame, dwSkillID, dwSkillLevel)
	-- get name
	local szSkillName, dwIconID = LIB.GetSkillName(dwSkillID, dwSkillLevel)
	if dwSkillID == 4097 then -- ���
		dwIconID = 1899
	elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- �󷨼���
		or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- ���ͷż���
		-- or dwSkillID == 230     -- (230)  ���˺���ʩ��  �߾���ң��
		-- or dwSkillID == 347     -- (347)  ����������ʩ��  �Ź�������
		-- or dwSkillID == 526     -- (526)  ����������ʩ��  ���������
		-- or dwSkillID == 662     -- (662)  ��߷������ͷ�  ���������
		-- or dwSkillID == 740     -- (740)  ���ַ�����ʩ��  ��շ�ħ��
		-- or dwSkillID == 745     -- (745)  ���ֹ�����ʩ��  ���������
		-- or dwSkillID == 754     -- (754)  ��߹������ͷ�  �����۳���
		-- or dwSkillID == 778     -- (778)  ����������ʩ��  ����������
		-- or dwSkillID == 781     -- (781)  �����˺���ʩ��  ����������
		-- or dwSkillID == 1020    -- (1020) ��������ʩ��  ���Ǿ�����
		-- or dwSkillID == 1866    -- (1866) �ؽ����ͷ�      ��ɽ������
		-- or dwSkillID == 2481    -- (2481) �嶾������ʩ��  ����֯����
		-- or dwSkillID == 2487    -- (2487) �嶾������ʩ��  ���������
		-- or dwSkillID == 3216    -- (3216) �����⹦��ʩ��  ���Ǹ�����
		-- or dwSkillID == 3217    -- (3217) �����ڹ���ʩ��  ǧ���ٱ���
		-- or dwSkillID == 4674    -- (4674) ���̹�����ʩ��  ������ħ��
		-- or dwSkillID == 4687    -- (4687) ���̷�����ʩ��  ����������
		-- or dwSkillID == 5311    -- (5311) ؤ�﹥�����ͷ�  ����������
		-- or dwSkillID == 13228   -- (13228)  �ٴ���ɽ���ͷ�  �ٴ���ɽ��
		-- or dwSkillID == 13275   -- (13275)  ��������ʩ��  ��������
		or dwSkillID == 10         -- (10)    ��ɨǧ��           ��ɨǧ��
		or dwSkillID == 11         -- (11)    ��ͨ����-������    ���Ϲ�
		or dwSkillID == 12         -- (12)    ��ͨ����-ǹ����    ÷��ǹ��
		or dwSkillID == 13         -- (13)    ��ͨ����-������    ���񽣷�
		or dwSkillID == 14         -- (14)    ��ͨ����-ȭ�׹���  ��ȭ
		or dwSkillID == 15         -- (15)    ��ͨ����-˫������  ����˫��
		or dwSkillID == 16         -- (16)    ��ͨ����-�ʹ���    �йٱʷ�
		or dwSkillID == 1795       -- (1795)  ��ͨ����-�ؽ�����  �ļ�����
		or dwSkillID == 2183       -- (2183)  ��ͨ����-��ѹ���  ��ĵѷ�
		or dwSkillID == 3121       -- (3121)  ��ͨ����-������    ��ڷ�
		or dwSkillID == 4326       -- (4326)  ��ͨ����-˫������  ��Į����
		or dwSkillID == 13039      -- (13039) ��ͨ����_�ܵ�����  ��ѩ��
		or dwSkillID == 14063      -- (14063) ��ͨ����_�ٹ���  ��������
		or dwSkillID == 16010      -- (16010) ��ͨ����_��˪������  ˪�絶��
		or dwSkillID == 19712      -- (19712) ��ͨ����_����ɡ����  Ʈңɡ��
		or dwSkillID == 17         -- (17)    ����-��������-���� ����
		or dwSkillID == 18         -- (18)    ̤�� ̤��
		or dwIconID  == 1817       -- ����
		or dwIconID  == 533        -- ����
		or dwIconID  == 13         -- �Ӽ���
		or not szSkillName
		or szSkillName == ''
	then
		return
	end

	local hList = frame:Lookup('', 'Handle_Boxes')
	local hItem = hList:Lookup(frame.nIndexBase)
	frame.nIndexBase = (frame.nIndexBase + 1) % hList:GetItemCount()

	local box = hItem:Lookup('Box_Skill')
	box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
	box:SetObjectIcon(dwIconID)
	box:Show()

	StartAnimation(frame)
end

function MY_VisualSkill.OnFrameCreate()
	this.nIndexBase = 0
	DrawUI(this)
	this:RegisterEvent('RENDER_FRAME_UPDATE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('DO_SKILL_CAST')
	this:RegisterEvent('DO_SKILL_CHANNEL_PROGRESS')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT')
	MY_VisualSkill.OnEvent('UI_SCALED')
end

function MY_VisualSkill.OnEvent(event)
	if event == 'RENDER_FRAME_UPDATE' then
		if not this.nTickStart then
			return
		end
		local nTickDuring = GetTickCount() - this.nTickStart
		if nTickDuring > 600 then
			this.nTickStart = nil
		end
		UpdateUI(this, nTickDuring)
	elseif event == 'UI_SCALED' then
		ApplyAnchor(this)
	elseif event == 'DO_SKILL_CAST' then
		local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'DO_SKILL_CHANNEL_PROGRESS' then
		local dwID, dwSkillID, dwSkillLevel = arg3, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['visual skill'], MY_VisualSkill.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['visual skill'], MY_VisualSkill.bPenetrable)
		MY_VisualSkill.anchor = GetFrameAnchor(this)
	elseif event == 'CUSTOM_UI_MODE_SET_DEFAULT' then
		MY_VisualSkill.anchor = defaultAnchor
		ApplyAnchor(this)
	end
end

function MY_VisualSkill.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_VisualSkill')
end

function MY_VisualSkill.GetFrame()
	return Station.Lookup('Normal/MY_VisualSkill')
end

function MY_VisualSkill.Close()
	Wnd.CloseWindow('MY_VisualSkill')
end

function MY_VisualSkill.Reload()
	if MY_VisualSkill.bEnable then
		local frame = MY_VisualSkill.GetFrame()
		if frame then
			DrawUI(frame)
		else
			MY_VisualSkill.Open()
		end
	else
		MY_VisualSkill.Close()
	end
end
LIB.RegisterInit('MY_VISUALSKILL', MY_VisualSkill.Reload)

function MY_VisualSkill.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['visual skill'],
		checked = MY_VisualSkill.bEnable,
		oncheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
			MY_VisualSkill.Reload()
		end,
	}):Width() + 5

	ui:Append('WndTrackbar', {
		x = x, y = y,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L('display %d skills.', MY_VisualSkill.nVisualSkillBoxCount),
		textfmt = function(val) return _L('display %d skills.', val) end,
		onchange = function(val)
			MY_VisualSkill.nVisualSkillBoxCount = val
			MY_VisualSkill.Reload()
		end,
	})
	x = X
	y = y + 25
	return x, y
end
