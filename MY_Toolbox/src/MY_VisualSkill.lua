--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ¼¼ÄÜÏÔÊ¾ - Õ½¶·¿ÉÊÓ»¯
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
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
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MY_Toolbox/lang/')
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
	local percentage = math.min(math.max(during / ANI_TIME, 0), 1)
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
	if dwSkillID == 4097 then -- Æï³Ë
		dwIconID = 1899
	elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- Õó·¨¼¼ÄÜ
		or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- Õó·¨ÊÍ·Å¼¼ÄÜ
		-- or dwSkillID == 230     -- (230)  Íò»¨ÉËº¦Õó·¨Ê©·Å  Æß¾øåÐÒ£Õó
		-- or dwSkillID == 347     -- (347)  ´¿ÑôÆø×ÚÕó·¨Ê©·Å  ¾Å¹¬°ËØÔÕó
		-- or dwSkillID == 526     -- (526)  ÆßÐãÖÎÁÆÕó·¨Ê©·Å  »¨ÔÂÁè·çÕó
		-- or dwSkillID == 662     -- (662)  Ìì²ß·ÀÓùÕó·¨ÊÍ·Å  ¾ÅÏåµØÐþÕó
		-- or dwSkillID == 740     -- (740)  ÉÙÁÖ·ÀÓùÕó·¨Ê©·Å  ½ð¸Õ·üÄ§Õó
		-- or dwSkillID == 745     -- (745)  ÉÙÁÖ¹¥»÷Õó·¨Ê©·Å  Ìì¹ÄÀ×ÒôÕó
		-- or dwSkillID == 754     -- (754)  Ìì²ß¹¥»÷Õó·¨ÊÍ·Å  ÎÀ¹«ÕÛ³åÕó
		-- or dwSkillID == 778     -- (778)  ´¿Ñô½£×ÚÕó·¨Ê©·Å  ±±¶·ÆßÐÇÕó
		-- or dwSkillID == 781     -- (781)  ÆßÐãÉËº¦Õó·¨Ê©·Å  ¾ÅÒô¾ªÏÒÕó
		-- or dwSkillID == 1020    -- (1020) Íò»¨ÖÎÁÆÕó·¨Ê©·Å  ÂäÐÇ¾ªºèÕó
		-- or dwSkillID == 1866    -- (1866) ²Ø½£Õó·¨ÊÍ·Å      ÒÀÉ½¹ÛÀ½Õó
		-- or dwSkillID == 2481    -- (2481) Îå¶¾ÖÎÁÆÕó·¨Ê©·Å  ÃîÊÖÖ¯ÌìÕó
		-- or dwSkillID == 2487    -- (2487) Îå¶¾¹¥»÷Õó·¨Ê©·Å  Íò¹ÆÊÉÐÄÕó
		-- or dwSkillID == 3216    -- (3216) ÌÆÃÅÍâ¹¦Õó·¨Ê©·Å  Á÷ÐÇ¸ÏÔÂÕó
		-- or dwSkillID == 3217    -- (3217) ÌÆÃÅÄÚ¹¦Õó·¨Ê©·Å  Ç§»ú°Ù±äÕó
		-- or dwSkillID == 4674    -- (4674) Ã÷½Ì¹¥»÷Õó·¨Ê©·Å  Ñ×ÍþÆÆÄ§Õó
		-- or dwSkillID == 4687    -- (4687) Ã÷½Ì·ÀÓùÕó·¨Ê©·Å  ÎÞÁ¿¹âÃ÷Õó
		-- or dwSkillID == 5311    -- (5311) Ø¤°ï¹¥»÷Õó·¨ÊÍ·Å  ½µÁú·ü»¢Õó
		-- or dwSkillID == 13228   -- (13228)  ÁÙ´¨ÁÐÉ½ÕóÊÍ·Å  ÁÙ´¨ÁÐÉ½Õó
		-- or dwSkillID == 13275   -- (13275)  ·æÁèºá¾øÕóÊ©·Å  ·æÁèºá¾øÕó
		or dwSkillID == 10         -- (10)    ºáÉ¨Ç§¾ü           ºáÉ¨Ç§¾ü
		or dwSkillID == 11         -- (11)    ÆÕÍ¨¹¥»÷-¹÷¹¥»÷    ÁùºÏ¹÷
		or dwSkillID == 12         -- (12)    ÆÕÍ¨¹¥»÷-Ç¹¹¥»÷    Ã·»¨Ç¹·¨
		or dwSkillID == 13         -- (13)    ÆÕÍ¨¹¥»÷-½£¹¥»÷    Èý²ñ½£·¨
		or dwSkillID == 14         -- (14)    ÆÕÍ¨¹¥»÷-È­Ì×¹¥»÷  ³¤È­
		or dwSkillID == 15         -- (15)    ÆÕÍ¨¹¥»÷-Ë«±ø¹¥»÷  Á¬»·Ë«µ¶
		or dwSkillID == 16         -- (16)    ÆÕÍ¨¹¥»÷-±Ê¹¥»÷    ÅÐ¹Ù±Ê·¨
		or dwSkillID == 1795       -- (1795)  ÆÕÍ¨¹¥»÷-ÖØ½£¹¥»÷  ËÄ¼¾½£·¨
		or dwSkillID == 2183       -- (2183)  ÆÕÍ¨¹¥»÷-³æµÑ¹¥»÷  ´ó»ÄµÑ·¨
		or dwSkillID == 3121       -- (3121)  ÆÕÍ¨¹¥»÷-¹­¹¥»÷    î¸·çïÚ·¨
		or dwSkillID == 4326       -- (4326)  ÆÕÍ¨¹¥»÷-Ë«µ¶¹¥»÷  ´óÄ®µ¶·¨
		or dwSkillID == 13039      -- (13039) ÆÕÍ¨¹¥»÷_¶Üµ¶¹¥»÷  ¾íÑ©µ¶
		or dwSkillID == 14063      -- (14063) ÆÕÍ¨¹¥»÷_ÇÙ¹¥»÷  ÎåÒôÁùÂÉ
		or dwSkillID == 16010      -- (16010) ÆÕÍ¨¹¥»÷_°ÁËªµ¶¹¥»÷  Ëª·çµ¶·¨
		or dwSkillID == 19712      -- (19712) ÆÕÍ¨¹¥»÷_ÅîÀ³É¡¹¥»÷  Æ®Ò£É¡»÷
		or dwSkillID == 17         -- (17)    ½­ºþ-·ÀÉíÎäÒÕ-´ò×ø ´ò×ø
		or dwSkillID == 18         -- (18)    Ì¤ÔÆ Ì¤ÔÆ
		or dwIconID  == 1817       -- ±ÕÕó
		or dwIconID  == 533        -- ´ò×ø
		or dwIconID  == 13         -- ×Ó¼¼ÄÜ
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
		UpdateCustomModeWindow(this, szTip, MY_VisualSkill.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, szTip, MY_VisualSkill.bPenetrable)
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
