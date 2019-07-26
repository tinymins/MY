--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 中央报警
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

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon_CA', _L['MY_TeamMon_CA'], 0x2013500) then
	return
end

local CA_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_CA.ini'
local D = {}
local O = {
	tAnchor = {}
}
RegisterCustomData('MY_TeamMon_CA.tAnchor')

-- FireUIEvent('MY_TM_CA_CREATE', 'test', 3)
local function CreateCentralAlert(szMsg, nTime, bXml)
	local msg = O.msg
	nTime = nTime or 3
	msg:Clear()
	if not bXml then
		szMsg = GetFormatText(szMsg, 44, 255, 255, 255)
	end
	msg:AppendItemFromString(szMsg)
	msg:FormatAllItemPos()
	local w, h = msg:GetAllItemSize()
	msg:SetRelPos((480 - w) / 2, (45 - h) / 2 - 1)
	O.handle:FormatAllItemPos()
	msg.nTime   = nTime
	msg.nCreate = GetTime()
	O.frame:SetAlpha(255)
	O.frame:Show()
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TM_CA_CREATE')
	O.frame  = this
	O.handle = this:Lookup('', '')
	O.msg    = this:Lookup('', 'MessageBox')
	D.UpdateAnchor(this)
end

function D.OnFrameRender()
	local nNow = GetTime()
	if O.msg.nCreate then
		local nTime = ((nNow - O.msg.nCreate) / 1000)
		local nLeft  = O.msg.nTime - nTime
		if nLeft < 0 then
			O.msg.nCreate = nil
			O.frame:Hide()
		else
			local nTimeLeft = nTime * 1000 % 750
			local nAlpha = 50 * nTimeLeft / 750
			if floor(nTime / 0.75) % 2 == 1 then
				nAlpha = 50 - nAlpha
			end
			O.frame:SetAlpha(255 - nAlpha)
		end
	end
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_CA_CREATE' then
		CreateCentralAlert(arg0, arg1, arg2)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Center Alarm'])
		if szEvent == 'ON_ENTER_CUSTOM_UI_MODE' then
			this:Show()
		else
			this:Hide()
		end
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, -150)
	end
end

function D.Init()
	local frame =  Wnd.OpenWindow(CA_INIFILE, 'MY_TeamMon_CA')
	frame:Hide()
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
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				tAnchor = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_CA = LIB.GeneGlobalNS(settings)
end
