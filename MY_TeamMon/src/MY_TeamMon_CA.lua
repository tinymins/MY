--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 中央报警
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_CA'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local CA_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_CA.ini'
local ANCHOR = { s = 'CENTER', r = 'CENTER', x = 0, y = 350 }
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
		UpdateCustomModeWindow(this, _L['Center alarm'])
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
	local a = IsEmpty(O.tAnchor) and ANCHOR or O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.Init()
	local frame = Wnd.OpenWindow(CA_INIFILE, 'MY_TeamMon_CA')
	frame:Hide()
end

LIB.RegisterInit('MY_TeamMon_CA', D.Init)


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
