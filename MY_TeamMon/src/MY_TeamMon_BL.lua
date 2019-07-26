--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : BUFF列表
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
if not LIB.AssertVersion('MY_TeamMon_BL', _L['MY_TeamMon_BL'], 0x2013500) then
	return
end

local BL_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_BL.ini'
local D = {}
local O = {
	tAnchor = {},
	nCount = 8,
	fScale = 1,
}
RegisterCustomData('MY_TeamMon_BL.tAnchor')
RegisterCustomData('MY_TeamMon_BL.nCount')
RegisterCustomData('MY_TeamMon_BL.fScale')

-- FireUIEvent('MY_TM_BL_CREATE', 103, 1, { 255, 0, 0 })
local function CreateBuffList(dwID, nLevel, col, tArgs)
	local key = tostring(dwID) -- .. '.' .. nLevel
	col = col or { 255, 255, 0 }
	tArgs = tArgs or {}
	local level = tArgs.bCheckLevel and nLevel or nil
	local KBuff = GetBuff(dwID, level)
	if KBuff then
		local ui, bScale
		if O.handle:Lookup(key) then
			ui = O.handle:Lookup(key)
		else
			if O.handle:GetItemCount() >= O.nCount then
				return
			end
			ui =  O.handle:AppendItemFromData(O.hItem, key)
			bScale = true
		end
		local szName, nIcon = LIB.GetBuffName(dwID, nLevel)
		ui.dwID = dwID
		ui.nLevel = level
		ui:Lookup('Text_Name'):SetText(tArgs.szName or szName)
		ui:Lookup('Text_Name'):SetFontColor(unpack(col))
		local box = ui:Lookup('Box')
		box:SetObjectIcon(tArgs.nIcon or nIcon)
		box:SetObjectSparking(true)
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		if KBuff.nStackNum > 1 then
			box:SetOverText(0, KBuff.nStackNum)
		else
			box:SetOverText(0, '')
		end
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, dwID, nLevel)
		ui:Lookup('Text_Time'):SetFontColor(unpack(col))
		if bScale then
			ui:Scale(O.fScale, O.fScale)
		end
		ui.bDelete = nil
		ui:SetAlpha(255)
		O.handle:FormatAllItemPos()
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TM_BL_CREATE')
	this:RegisterEvent('MY_TM_BL_RESIZE')
	O.hItem = this:CreateItemData(BL_INIFILE, 'Handle_Item')
	O.handle = this:Lookup('', '')
	O.handle:Clear()
	D.ReSize(O.fScale, O.nCount)
	D.UpdateAnchor(this)
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_BL_CREATE' then
		CreateBuffList(arg0, arg1, arg2, arg3)
	elseif szEvent == 'MY_TM_BL_RESIZE' then
		D.ReSize(arg0, arg1)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Buff List'])
	end
end
function D.OnItemMouseEnter()
	local h = this:GetParent()
	local KBuff = GetBuff(h.dwID, h.nLevel)
	if KBuff then
		this:SetObjectMouseOver(true)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		LIB.OutputBuffTip(KBuff.dwID, KBuff.nLevel, { x, y, w, h }, LIB.GetEndTime(KBuff.GetEndTime()))
	end
end

function D.OnItemRButtonClick()
	local h = this:GetParent()
	LIB.CancelBuff(h.dwID, h.nLevel)
end

function D.OnItemMouseLeave()
	if this:IsValid() then
		this:SetObjectMouseOver(false)
		HideTip()
	end
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then return end
	for i = O.handle:GetItemCount() -1, 0, -1 do
		local h = O.handle:Lookup(i)
		if h and h:IsValid() then
			if h.bDelete then
				local nAlpha = h:GetAlpha()
				if nAlpha == 0 then
					O.handle:RemoveItem(h)
					O.handle:FormatAllItemPos()
				else
					h:SetAlpha(math.max(0, nAlpha - 30))
					h:Lookup('Animate_Update'):SetAlpha(0)
				end
			else
				local KBuff = GetBuff(h.dwID, h.nLevel)
				if KBuff then
					local nSec = LIB.GetEndTime(KBuff.GetEndTime())
					if nSec > 24 * 60 * 60 then
						h:Lookup('Text_Time'):SetText('')
					else
						h:Lookup('Text_Time'):SetText(LIB.FormatTimeCounter(nSec, 1))
					end
					local nAlpha = h:Lookup('Animate_Update'):GetAlpha()
					if nAlpha > 0 then
						h:Lookup('Animate_Update'):SetAlpha(math.max(0, nAlpha - 8))
					end
					if KBuff.nStackNum > 1 then
						h:Lookup('Box'):SetOverText(0, KBuff.nStackNum)
					else
						h:Lookup('Box'):SetOverText(0, '')
					end
				else
					h.bDelete = true
				end
			end
		end
	end
	if not LIB.IsInCustomUIMode() then
		this:SetMousePenetrable(not IsCtrlKeyDown())
	else
		this:SetMousePenetrable(false)
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
end

function D.ReSize(fScale, nCount)
	if fScale then
		local fNewScale = fScale / O.fScale
		this:Scale(fNewScale, fNewScale)
		O.fScale = fScale
	end
	nCount = nCount or O.nCount
	this:SetSize(nCount * 55 * O.fScale, 90 * O.fScale)
	O.handle:SetSize(nCount * 55 * O.fScale, 90 * O.fScale)
	O.nCount = nCount
	O.handle:FormatAllItemPos()
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, -350)
	end
end

function D.Init()
	local frame =  Wnd.OpenWindow(BL_INIFILE, 'MY_TeamMon_BL')
end

LIB.RegisterEvent('LOGIN_GAME', D.Init)

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
				tAnchor = true,
				nCount  = true,
				fScale  = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				tAnchor = true,
				nCount  = true,
				fScale  = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_BL = LIB.GeneGlobalNS(settings)
end
