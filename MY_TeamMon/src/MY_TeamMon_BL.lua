--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : BUFF列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_BL'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local GetBuff = LIB.GetBuff
local FilterCustomText = MY_TeamMon.FilterCustomText

local BL_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_BL.ini'
local O = LIB.CreateUserSettingsModule('MY_TeamMon_BL', _L['Raid'], {
	tAnchor = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = Schema.FrameAnchor,
		xDefaultValue = { s = 'TOPLEFT', r = 'CENTER', x = 300, y = -200 },
	},
	nCount = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = Schema.Number,
		xDefaultValue = 8,
	},
	fScale = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
})
local D = {
	fScale = 1,
}

-- FireUIEvent('MY_TM_BL_CREATE', 103, 1, { 255, 0, 0 })
local function CreateBuffList(dwID, nLevel, col, tArgs, szSender, szReceiver)
	local key = tostring(dwID) -- .. '.' .. nLevel
	col = col or { 255, 255, 0 }
	tArgs = tArgs or {}
	local level = tArgs.bCheckLevel and nLevel or nil
	local buff = GetBuff(GetClientPlayer(), dwID, level)
	if buff then
		local ui, bScale
		if D.handle:Lookup(key) then
			ui = D.handle:Lookup(key)
		else
			if D.handle:GetItemCount() >= O.nCount then
				return
			end
			ui = D.handle:AppendItemFromData(D.hItem, key)
			bScale = true
		end
		local szName, nIcon = LIB.GetBuffName(dwID, nLevel)
		ui.dwID = dwID
		ui.nLevel = level
		ui:Lookup('Text_Name'):SetText(FilterCustomText(tArgs.szName, szSender, szReceiver) or szName)
		ui:Lookup('Text_Name'):SetFontColor(unpack(col))
		local box = ui:Lookup('Box')
		box:SetObjectIcon(tArgs.nIcon or nIcon)
		box:SetObjectSparking(true)
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		if buff.nStackNum > 1 then
			box:SetOverText(0, buff.nStackNum)
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
		D.handle:FormatAllItemPos()
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TM_BL_CREATE')
	D.hItem = this:CreateItemData(BL_INIFILE, 'Handle_Item')
	D.handle = this:Lookup('', '')
	D.handle:Clear()
	D.ReSize()
	D.UpdateAnchor(this)
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_BL_CREATE' then
		CreateBuffList(arg0, arg1, arg2, arg3, arg4, arg5)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Buff list'])
	end
end
function D.OnItemMouseEnter()
	local h = this:GetParent()
	local buff = GetBuff(GetClientPlayer(), h.dwID, h.nLevel)
	if buff then
		this:SetObjectMouseOver(true)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		LIB.OutputBuffTip({ x, y, w, h }, buff.dwID, buff.nLevel, LIB.GetEndTime(buff.nEndFrame))
	end
end

function D.OnItemRButtonClick()
	local h = this:GetParent()
	LIB.CancelBuff(GetClientPlayer(), h.dwID, h.nLevel)
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
	for i = D.handle:GetItemCount() -1, 0, -1 do
		local h = D.handle:Lookup(i)
		if h and h:IsValid() then
			if h.bDelete then
				local nAlpha = h:GetAlpha()
				if nAlpha == 0 then
					D.handle:RemoveItem(h)
					D.handle:FormatAllItemPos()
				else
					h:SetAlpha(max(0, nAlpha - 30))
					h:Lookup('Animate_Update'):SetAlpha(0)
				end
			else
				local buff = GetBuff(me, h.dwID, h.nLevel)
				if buff then
					local nSec = LIB.GetEndTime(buff.nEndFrame)
					if nSec > 24 * 60 * 60 then
						h:Lookup('Text_Time'):SetText('')
					else
						h:Lookup('Text_Time'):SetText(LIB.FormatTimeCounter(nSec, 1))
					end
					local nAlpha = h:Lookup('Animate_Update'):GetAlpha()
					if nAlpha > 0 then
						h:Lookup('Animate_Update'):SetAlpha(max(0, nAlpha - 8))
					end
					if buff.nStackNum > 1 then
						h:Lookup('Box'):SetOverText(0, buff.nStackNum)
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

function D.ReSize()
	if D.fScale ~= O.fScale then
		local fNewScale = O.fScale / D.fScale
		this:Scale(fNewScale, fNewScale)
		D.fScale = O.fScale
	end
	this:SetSize(O.nCount * 55 * O.fScale, 90 * O.fScale)
	D.handle:SetSize(O.nCount * 55 * O.fScale, 90 * O.fScale)
	D.handle:FormatAllItemPos()
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.Init()
	Wnd.CloseWindow('MY_TeamMon_BL')
	Wnd.OpenWindow(BL_INIFILE, 'MY_TeamMon_BL')
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_TeamMon_BL', D.Init)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_BL',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'tAnchor',
				'nCount',
				'fScale',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'tAnchor',
				'nCount',
				'fScale',
			},
			triggers = {
				nCount = D.ReSize,
				fScale = D.ReSize,
			},
			root = O,
		},
	},
}
MY_TeamMon_BL = LIB.CreateModule(settings)
end
