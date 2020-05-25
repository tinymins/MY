--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ¼¼ÄÜÏÔÊ¾ - Õ½¶·¿ÉÊÓ»¯
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
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
local INI_PATH = PACKET_INFO.ROOT .. 'MY_ToolBox/ui/MY_VisualSkill.ini'
local DEFAULT_ANCHOR = { x = 0, y = -220, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' }
local D = {}
local O = {
	bEnable = false,
	bPenetrable = true,
	nVisualSkillBoxCount = 5,
	anchor = Clone(DEFAULT_ANCHOR),
}
RegisterCustomData('MY_VisualSkill.bEnable')
RegisterCustomData('MY_VisualSkill.bPenetrable')
RegisterCustomData('MY_VisualSkill.nVisualSkillBoxCount')
RegisterCustomData('MY_VisualSkill.anchor')

local BOX_WIDTH = 55
local BOX_ANIMATION_TIME = 450
local BOX_SLIDEOUT_DISTANCE = 200

-- local FORMATION_SKILL = {
-- 	[230  ] = true, -- (230)  Íò»¨ÉËº¦Õó·¨Ê©·Å  Æß¾øåÐÒ£Õó
-- 	[347  ] = true, -- (347)  ´¿ÑôÆø×ÚÕó·¨Ê©·Å  ¾Å¹¬°ËØÔÕó
-- 	[526  ] = true, -- (526)  ÆßÐãÖÎÁÆÕó·¨Ê©·Å  »¨ÔÂÁè·çÕó
-- 	[662  ] = true, -- (662)  Ìì²ß·ÀÓùÕó·¨ÊÍ·Å  ¾ÅÏåµØÐþÕó
-- 	[740  ] = true, -- (740)  ÉÙÁÖ·ÀÓùÕó·¨Ê©·Å  ½ð¸Õ·üÄ§Õó
-- 	[745  ] = true, -- (745)  ÉÙÁÖ¹¥»÷Õó·¨Ê©·Å  Ìì¹ÄÀ×ÒôÕó
-- 	[754  ] = true, -- (754)  Ìì²ß¹¥»÷Õó·¨ÊÍ·Å  ÎÀ¹«ÕÛ³åÕó
-- 	[778  ] = true, -- (778)  ´¿Ñô½£×ÚÕó·¨Ê©·Å  ±±¶·ÆßÐÇÕó
-- 	[781  ] = true, -- (781)  ÆßÐãÉËº¦Õó·¨Ê©·Å  ¾ÅÒô¾ªÏÒÕó
-- 	[1020 ] = true, -- (1020) Íò»¨ÖÎÁÆÕó·¨Ê©·Å  ÂäÐÇ¾ªºèÕó
-- 	[1866 ] = true, -- (1866) ²Ø½£Õó·¨ÊÍ·Å      ÒÀÉ½¹ÛÀ½Õó
-- 	[2481 ] = true, -- (2481) Îå¶¾ÖÎÁÆÕó·¨Ê©·Å  ÃîÊÖÖ¯ÌìÕó
-- 	[2487 ] = true, -- (2487) Îå¶¾¹¥»÷Õó·¨Ê©·Å  Íò¹ÆÊÉÐÄÕó
-- 	[3216 ] = true, -- (3216) ÌÆÃÅÍâ¹¦Õó·¨Ê©·Å  Á÷ÐÇ¸ÏÔÂÕó
-- 	[3217 ] = true, -- (3217) ÌÆÃÅÄÚ¹¦Õó·¨Ê©·Å  Ç§»ú°Ù±äÕó
-- 	[4674 ] = true, -- (4674) Ã÷½Ì¹¥»÷Õó·¨Ê©·Å  Ñ×ÍþÆÆÄ§Õó
-- 	[4687 ] = true, -- (4687) Ã÷½Ì·ÀÓùÕó·¨Ê©·Å  ÎÞÁ¿¹âÃ÷Õó
-- 	[5311 ] = true, -- (5311) Ø¤°ï¹¥»÷Õó·¨ÊÍ·Å  ½µÁú·ü»¢Õó
-- 	[13228] = true, -- (13228)  ÁÙ´¨ÁÐÉ½ÕóÊÍ·Å  ÁÙ´¨ÁÐÉ½Õó
-- 	[13275] = true, -- (13275)  ·æÁèºá¾øÕóÊ©·Å  ·æÁèºá¾øÕó
-- }
local COMMON_SKILL = {
	[10   ] = true, -- (10)    ºáÉ¨Ç§¾ü           ºáÉ¨Ç§¾ü
	[11   ] = true, -- (11)    ÆÕÍ¨¹¥»÷-¹÷¹¥»÷     ÁùºÏ¹÷
	[12   ] = true, -- (12)    ÆÕÍ¨¹¥»÷-Ç¹¹¥»÷     Ã·»¨Ç¹·¨
	[13   ] = true, -- (13)    ÆÕÍ¨¹¥»÷-½£¹¥»÷     Èý²ñ½£·¨
	[14   ] = true, -- (14)    ÆÕÍ¨¹¥»÷-È­Ì×¹¥»÷   ³¤È­
	[15   ] = true, -- (15)    ÆÕÍ¨¹¥»÷-Ë«±ø¹¥»÷   Á¬»·Ë«µ¶
	[16   ] = true, -- (16)    ÆÕÍ¨¹¥»÷-±Ê¹¥»÷     ÅÐ¹Ù±Ê·¨
	[1795 ] = true, -- (1795)  ÆÕÍ¨¹¥»÷-ÖØ½£¹¥»÷   ËÄ¼¾½£·¨
	[2183 ] = true, -- (2183)  ÆÕÍ¨¹¥»÷-³æµÑ¹¥»÷   ´ó»ÄµÑ·¨
	[3121 ] = true, -- (3121)  ÆÕÍ¨¹¥»÷-¹­¹¥»÷     î¸·çïÚ·¨
	[4326 ] = true, -- (4326)  ÆÕÍ¨¹¥»÷-Ë«µ¶¹¥»÷   ´óÄ®µ¶·¨
	[13039] = true, -- (13039) ÆÕÍ¨¹¥»÷_¶Üµ¶¹¥»÷   ¾íÑ©µ¶
	[14063] = true, -- (14063) ÆÕÍ¨¹¥»÷_ÇÙ¹¥»÷     ÎåÒôÁùÂÉ
	[16010] = true, -- (16010) ÆÕÍ¨¹¥»÷_°ÁËªµ¶¹¥»÷  Ëª·çµ¶·¨
	[19712] = true, -- (19712) ÆÕÍ¨¹¥»÷_ÅîÀ³É¡¹¥»÷  Æ®Ò£É¡»÷
	[17   ] = true, -- (17)    ½­ºþ-·ÀÉíÎäÒÕ-´ò×ø  ´ò×ø
	[18   ] = true, -- (18)    Ì¤ÔÆ               Ì¤ÔÆ
}

function D.UpdateAnchor(frame)
	local anchor = O.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	frame:CorrectPos()
end

function D.UpdateAnimation(frame, fPercentage)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nCount = hList:GetItemCount()

	local hItem = hList:LogicLookup(0)
	if not hItem.nStartX then
		hItem.nStartX = hItem:GetRelX()
	end
	hItem:SetAlpha((1 - fPercentage) * 255)
	hItem:SetRelX(hItem.nStartX - (hItem.nStartX + BOX_SLIDEOUT_DISTANCE) * fPercentage)

	local nRelX = 0
	for i = 1, nCount - 2 do
		local hItem = hList:LogicLookup(i)
		if not hItem.nStartX then
			hItem.nStartX = hItem:GetRelX()
		end
		hItem:SetAlpha(255)
		hItem:SetRelX(nRelX + (hItem.nStartX - nRelX) * (1 - fPercentage))
		nRelX = nRelX + hItem:GetW()
	end

	local hItem = hList:LogicLookup(nCount - 1)
	hItem:SetAlpha(fPercentage * 255)
	hItem:SetRelX(nRelX + BOX_SLIDEOUT_DISTANCE * (1 - fPercentage))

	hList:FormatAllItemPos()
end

function D.StartAnimation(frame, nStep)
	local hList = frame:Lookup('', 'Handle_Boxes')
	if nStep then
		hList.nIndexBase = (hList.nIndexBase + nStep) % hList:GetItemCount()
	end
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1 do
		local hItem = hList:Lookup(i)
		hItem.nStartX = hItem:GetRelX()
	end
	frame.nTickStart = GetTickCount()
end

-- »æÖÆÕýÈ·ÊýÁ¿µÄÁÐ±í
function D.CorrectBoxCount(frame)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nBoxCount = O.nVisualSkillBoxCount + 1
	local nBoxCountOffset = nBoxCount - hList:GetItemCount()
	if nBoxCountOffset == 0 then
		return
	end
	if nBoxCountOffset > 0 then
		for i = 1, nBoxCountOffset do
			hList:AppendItemFromIni(INI_PATH, 'Handle_Box'):Lookup('Box_Skill'):Hide()
			for i = hList:GetItemCount() - 1, hList.nIndexBase + 1 do
				hList:ExchangeItemIndex(i, i - 1)
			end
		end
	elseif nBoxCountOffset < 0 then
		for i = nBoxCountOffset, -1 do
			hList:LogicRemoveItem(0)
			hList.nIndexBase = hList.nIndexBase % hList:GetItemCount()
		end
	end
	local nBoxesW = BOX_WIDTH * O.nVisualSkillBoxCount
	frame:Lookup('', 'Handle_Bg/Image_Bg_11'):SetW(nBoxesW)
	frame:Lookup('', 'Handle_Bg'):FormatAllItemPos()
	frame:Lookup('', ''):FormatAllItemPos()
	frame:SetW(nBoxesW + 169)
	hList:SetW(nBoxesW)
	hList.nCount = nBoxCount
	D.UpdateAnimation(frame, 1)
end

function D.OnSkillCast(frame, dwSkillID, dwSkillLevel)
	-- »ñÈ¡¼¼ÄÜÐÅÏ¢
	local szSkillName, dwIconID = LIB.GetSkillName(dwSkillID, dwSkillLevel)
	if dwSkillID == 4097 then -- Æï³Ë
		dwIconID = 1899
	end
	-- ÎÞÃû¼¼ÄÜÆÁ±Î
	if not szSkillName or szSkillName == '' then
		return
	end
	-- ÆÕ¹¥ÆÁ±Î
	if COMMON_SKILL[dwSkillID] then
		return
	end
	-- ÌØÊâÍ¼±ê¼¼ÄÜÆÁ±Î
	if dwIconID == 1817 --[[±ÕÕó]] or dwIconID == 533 --[[´ò×ø]] or dwIconID == 13 --[[×Ó¼¼ÄÜ]] then
		return
	end
	-- Õó·¨ÊÍ·Å¼¼ÄÜÆÁ±Î
	if Table_IsSkillFormation(dwSkillID, dwSkillLevel) or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel) then
		return
	end
	-- äÖÈ¾½çÃæ´¥·¢¶¯»­
	local box = frame:Lookup('', 'Handle_Boxes')
		:LogicLookup(0):Lookup('Box_Skill')
	box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
	box:SetObjectIcon(dwIconID)
	box:Show()
	D.StartAnimation(frame, 1)
end

function D.OnFrameCreate()
	local hList = this:Lookup('', 'Handle_Boxes')
	hList.LogicLookup = function(el, i)
		return el:Lookup((i + el.nIndexBase) % el.nCount)
	end
	hList.LogicRemoveItem = function(el, i)
		return el:RemoveItem((i + el.nIndexBase) % el.nCount)
	end
	hList.nIndexBase = 0
	hList.nCount = 0
	D.CorrectBoxCount(this)
	this:RegisterEvent('RENDER_FRAME_UPDATE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('DO_SKILL_CAST')
	this:RegisterEvent('DO_SKILL_CHANNEL_PROGRESS')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT')
	D.OnEvent('UI_SCALED')
end

function D.OnEvent(event)
	if event == 'RENDER_FRAME_UPDATE' then
		if not this.nTickStart then
			return
		end
		local nTickDuring = GetTickCount() - this.nTickStart
		if nTickDuring > 600 then
			this.nTickStart = nil
		end
		D.UpdateAnimation(this, min(max(nTickDuring / BOX_ANIMATION_TIME, 0), 1))
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'DO_SKILL_CAST' then
		local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'DO_SKILL_CHANNEL_PROGRESS' then
		local dwID, dwSkillID, dwSkillLevel = arg3, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
		MY_VisualSkill.anchor = GetFrameAnchor(this)
	elseif event == 'CUSTOM_UI_MODE_SET_DEFAULT' then
		MY_VisualSkill.anchor = Clone(DEFAULT_ANCHOR)
		D.UpdateAnchor(this)
	end
end

function D.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_VisualSkill')
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_VisualSkill')
end

function D.Close()
	Wnd.CloseWindow('MY_VisualSkill')
end

function D.Reload()
	if O.bEnable then
		local frame = D.GetFrame()
		if frame then
			D.CorrectBoxCount(frame)
		else
			D.Open()
		end
	else
		D.Close()
	end
end
LIB.RegisterInit('MY_VISUALSKILL', D.Reload)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Visual skill'],
		checked = MY_VisualSkill.bEnable,
		oncheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
		end,
	}):Width() + 5

	ui:Append('WndTrackbar', {
		x = x, y = y,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L('Display %d skills.', MY_VisualSkill.nVisualSkillBoxCount),
		textfmt = function(val) return _L('Display %d skills.', val) end,
		onchange = function(val)
			MY_VisualSkill.nVisualSkillBoxCount = val
		end,
	})
	x = X
	y = y + 25
	return x, y
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				bEnable              = true,
				bPenetrable          = true,
				nVisualSkillBoxCount = true,
				anchor               = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable              = true,
				bPenetrable          = true,
				nVisualSkillBoxCount = true,
				anchor               = true,
			},
			triggers = {
				bEnable              = D.Reload,
				nVisualSkillBoxCount = D.Reload,
			},
			root = O,
		},
	},
}
MY_VisualSkill = LIB.GeneGlobalNS(settings)
end
