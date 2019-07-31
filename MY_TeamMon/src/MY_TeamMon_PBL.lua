--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队重要BUFF列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local GetBuff = LIB.GetBuff

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon_PBL', _L['MY_TeamMon_PBL'], 0x2013500) then
	return
end

-- 这个需要重写 构思已有 就是没时间。。
local D = {}
local O = {
	bHoverSelect = false,
	tAnchor = {},
}
RegisterCustomData('MY_TeamMon_PBL.bHoverSelect')
RegisterCustomData('MY_TeamMon_PBL.tAnchor')

local TEMP_TARGET_TYPE, TEMP_TARGET_ID
local CACHE_LIST = setmetatable({}, { __mode = 'v' })
local PBL_INI_FILE = PACKET_INFO.ROOT ..  'MY_TeamMon/ui/MY_TeamMon_PBL.ini'

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('TARGET_CHANGE')
	this:RegisterEvent('MY_TM_PARTY_BUFF_LIST')
	O.hItem = this:CreateItemData(PBL_INI_FILE, 'Handle_Item')
	O.frame = this
	O.handle = this:Lookup('', 'Handle_List')
	O.bg = this:Lookup('', 'Image_Bg')
	O.handle:Clear()
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TeamMon_PBL'])
	D.UpdateAnchor(this)
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'TARGET_CHANGE' then
		D.SwitchSelect()
	elseif event == 'MY_TM_PARTY_BUFF_LIST' then
		D.OnTableInsert(arg0, arg1, arg2, arg3)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' or event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['MY_TeamMon_PBL'])
		if event == 'ON_ENTER_CUSTOM_UI_MODE' then
			O.frame:Show()
		else
			D.SwitchPanel(O.handle:GetItemCount())
			O.frame:EnableDrag(true) -- 还是支持拖动的
			O.frame:SetDragArea(0, 0, 200, 30)
		end
	end
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then return end
	local dwKungfuID = UI_GetPlayerMountKungfuID()
	local DISTANCE = 20
	if dwKungfuID == 10080 then -- 奶秀修正
		DISTANCE = 22
	elseif dwKungfuID == 10028 then -- 奶花修正
		DISTANCE = 24
	end
	for i = O.handle:GetItemCount() -1, 0, -1 do
		local h = O.handle:Lookup(i)
		if h and h:IsValid() then
			local data = h.data
			local p, info = D.GetPlayer(data.dwID)
			local KBuff
			if p then
				KBuff = GetBuff(p, data.dwBuffID)
			end
			if p and info and KBuff then
				local nDistance = LIB.GetDistance(p)
				h:Lookup('Image_life'):SetPercentage(info.nCurrentLife / math.max(info.nMaxLife, 1))
				h:Lookup('Text_Name'):SetText(i + 1 .. ' ' .. info.szName)
				if nDistance > DISTANCE then
					h:Lookup('Image_life'):SetAlpha(150)
				else
					h:Lookup('Image_life'):SetAlpha(255)
				end
				local box = h:Lookup('Box_Icon')
				local nSec = LIB.GetEndTime(KBuff.GetEndTime())
				if nSec < 60 then
					box:SetOverText(1, LIB.FormatTimeCounter(min(nSec, 5999), 1))
				else
					box:SetOverText(1, '')
				end
				if KBuff.nStackNum > 1 then
					box:SetOverText(0, KBuff.nStackNum)
				end
			else
				O.handle:RemoveItem(h)
				O.handle:FormatAllItemPos()
				D.SwitchPanel(O.handle:GetItemCount())
			end
		end
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Style' then
		local menu = {
			{ szOption = _L['Mouse enter select'], bCheck = true, bChecked = O.bHoverSelect, fnAction = function()
				O.bHoverSelect = not O.bHoverSelect
			end }
		}
		PopupMenu(menu)
	elseif szName == 'Btn_Close' then
		O.handle:Clear()
		D.SwitchPanel(0)
	end
end

function D.OnItemLButtonDown()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
		end
	end
end

function D.OnItemMouseLeave()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect and TEMP_TARGET_TYPE and TEMP_TARGET_ID then
			LIB.SetTarget(TEMP_TARGET_TYPE, TEMP_TARGET_ID)
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
		end
	end
end

function D.OnItemMouseEnter()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = LIB.GetTarget()
			LIB.SetTarget(TARGET.PLAYER, this.data.dwID)
		end
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPCENTER')
end

function D.OpenPanel()
	local frame = O.frame or Wnd.OpenWindow(PBL_INI_FILE, 'MY_TeamMon_PBL')
	D.SwitchPanel(0)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 400, 0)
	end
end

function D.SwitchSelect()
	local dwType, dwID = Target_GetTargetData()
	for i = O.handle:GetItemCount() -1, 0, -1 do
		local h = O.handle:Lookup(i)
		if h and h:IsValid() then
			local sel = h:Lookup('Image_Select')
			if sel and sel:IsValid() then
				if dwID == h.data.dwID then
					sel:Show()
				else
					sel:Hide()
				end
			end
		end
	end
end

function D.SwitchPanel(nCount)
	local h = 40
	O.frame:SetH(h * nCount + 30)
	O.bg:SetH(h * nCount + 30)
	O.handle:SetH(h * nCount)
	if nCount == 0 then
		O.frame:Hide()
	else
		O.frame:Show()
	end
end

function D.ClosePanel()
	Wnd.CloseWindow(O.frame)
	O.frame = nil
end

function D.GetPlayer(dwID)
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local p, info
	if dwID == UI_GetClientPlayerID() then
		p = me
		info = {
			dwMountKungfuID = UI_GetPlayerMountKungfuID(),
			szName = me.szName,
			nMaxLife = me.nMaxLife,
			nCurrentLife = me.nCurrentLife,
		}
	else
		p = GetPlayer(dwID)
		info = team.GetMemberInfo(dwID)
	end
	return p, info
end

function D.OnTableInsert(dwID, dwBuffID, nLevel, nIcon)
	local team = GetClientTeam()
	local p, info = D.GetPlayer(dwID)
	if not p or not info then
		return
	end
	local key = dwID .. '_' .. dwBuffID .. '_' .. nLevel -- 主要担心窗口名称太长
	if CACHE_LIST[key] and CACHE_LIST[key]:IsValid() then
		return
	end
	local KBuff = GetBuff(p, dwBuffID)
	if not KBuff then
		return
	end
	local dwTargetType, dwTargetID = Target_GetTargetData()
	local data = { dwID = dwID, dwBuffID = dwBuffID, nLevel = nLevel }
	local h = O.handle:AppendItemFromData(O.hItem)
	local nCount = O.handle:GetItemCount()
	if dwTargetID == dwID then
		h:Lookup('Image_Select'):Show()
	end
	h:Lookup('Image_KungFu'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID) or 1435)
	h:Lookup('Text_Name'):SetText(nCount .. ' ' .. info.szName)
	h:Lookup('Image_life'):SetPercentage(info.nCurrentLife / math.max(info.nMaxLife, 1))
	local box = h:Lookup('Box_Icon')
	local _, icon = LIB.GetBuffName(dwBuffID, nLevel)
	if nIcon then
		icon = nIcon
	end
	box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
	box:SetObjectIcon(icon)
	box:SetObjectStaring(true)
	box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	box:SetOverTextFontScheme(1, 8)
	box:SetOverTextFontScheme(0, 7)
	local nSec = LIB.GetEndTime(KBuff.GetEndTime())
	if nSec < 60 then
		box:SetOverText(1, math.floor(nSec) .. '\'')
	end
	if KBuff.nStackNum > 1 then
		box:SetOverText(0, KBuff.nStackNum)
	end
	h.data = data
	h:Show()
	O.handle:FormatAllItemPos()
	D.SwitchPanel(nCount)
	CACHE_LIST[key] = h
end

LIB.RegisterInit('MY_TeamMon_PBL', D.OpenPanel)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				bHoverSelect = true,
				tAnchor      = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bHoverSelect = true,
				tAnchor      = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_PBL = LIB.GeneGlobalNS(settings)
end
