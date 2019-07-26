--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : È«ÆÁ·º¹â
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
if not LIB.AssertVersion('MY_TeamMon', _L['MY_TeamMon'], 0x2013500) then
	return
end

local D = {}
local FS = {}
FS.__index = FS

local FS_HANDLE, FS_FRAME
local FS_CACHE   = setmetatable({}, { __mode = 'v' })
local FS_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_FS.ini'

-- FireUIEvent('MY_TM_FS_CREATE', Random(50, 255), { col = { Random(50, 255), Random(50, 255), Random(50, 255) }, bFlash = true})
local function CreateFullScreen(szKey, tArgs)
	if LIB.IsShieldedVersion() then
		return
	end
	assert(type(tArgs) == 'table', 'CreateFullScreen failed!')
	tArgs.nTime = tArgs.nTime or 3
	if tArgs.tBindBuff then
		FS:ctor(szKey, tArgs):DrawEdge()
	else
		FS:ctor(szKey, tArgs)
	end
end

local function Init()
	Wnd.OpenWindow(FS_INIFILE, 'MY_TeamMon_FS'):Hide()
end

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('MY_TM_FS_CREATE')

	this.hItem = this:CreateItemData(FS_INIFILE, 'Handle_Item')
	FS_FRAME   = this
	FS_HANDLE  = this:Lookup('', '')
	FS_HANDLE:Clear()
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_FS_CREATE' then
		CreateFullScreen(arg0, arg1)
	elseif szEvent == 'UI_SCALED' then
		for k, v in pairs(FS_CACHE) do
			if v.tBindBuff then
				v.obj:DrawEdge()
			end
		end
	elseif szEvent == 'LOADING_END' then
		FS_HANDLE:Clear()
	end
end

function D.OnFrameRender()
	local nNow = GetTime()
	for k, v in pairs(FS_CACHE) do
		if v:IsValid() then
			local nTime = ((nNow - v.nCreate) / 1000)
			local nLeft  = v.nTime - nTime
			if nLeft > 0 then
				if v.bFlash then
					local nTimeLeft = nTime * 1000 % 750
					local nAlpha = 150 * nTimeLeft / 750
					if floor(nTime / 0.75) % 2 == 1 then
						nAlpha = 150 - nAlpha
					end
					v.obj:DrawFullScreen(floor(nAlpha))
				else
					local nAlpha = 150 - 150 * nTime / v.nTime
					v.obj:DrawFullScreen(nAlpha)
				end
			else
				if v.sha1:IsValid() then
					if v.tBindBuff then
						v.obj:RemoveFullScreen()
					else
						v.obj:RemoveItem()
					end
				end
			end
			if v.tBindBuff then
				local dwID, nLevel = unpack(v.tBindBuff)
				local KBuff = GetBuff(dwID)
				if not KBuff then
					v.obj:RemoveItem()
				end
			end
		end
	end
end

function FS:ctor(szKey, tArgs)
	local el = FS_CACHE[szKey]
	local nTime = GetTime()
	local oo = {}
	setmetatable(oo, self)
	oo.key = szKey
	if not el or el and not el:IsValid() then
		el = FS_HANDLE:AppendItemFromData(FS_FRAME.hItem)
	end
	if el.sha1 and el.sha1:IsValid() then
		el.sha1 = el.sha1
	else
		el.sha1 = el:AppendItemFromIni(PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini', 'Shadow')
		el.sha1:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		el.sha1:SetD3DPT(D3DPT.TRIANGLESTRIP)
	end
	el.bFlash  = tArgs.bFlash
	el.nTime   = tArgs.nTime
	el.nCreate = nTime
	el.col     = tArgs.col or { 255, 128, 0 }
	if tArgs.tBindBuff then
		if el.sha2 and el.sha2:IsValid() then
			el.sha2 = el.sha2
		else
			el.sha2 = el:AppendItemFromIni(PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini', 'Shadow')
			el.sha2:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			el.sha2:SetD3DPT(D3DPT.TRIANGLESTRIP)
		end
		el.tBindBuff = tArgs.tBindBuff
	end
	oo.el = el
	oo.el.obj = oo
	FS_CACHE[szKey] = oo.el
	FS_FRAME:Show()
	return oo
end

function FS:DrawFullScreen( ... )
	self:DrawShadow(self.el.sha1, ...)
	return self
end

function FS:DrawEdge()
	self:DrawShadow(self.el.sha2, 220, 15, 15)
	return self
end

function FS:DrawShadow(sha, nAlpha, fScreenX, fScreenY)
	local r, g, b = unpack(self.el.col)
	local w, h = Station.GetClientSize()
	local bW, bH = fScreenX or w * 0.10, fScreenY or h * 0.10
	if sha:IsValid() then
		sha:ClearTriangleFanPoint()
		sha:AppendTriangleFanPoint(0, 0, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(0, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, h - bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(bW, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(w - bW, h - bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(w, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(w - bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(w, 0, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(0, 0, r, g, b, nAlpha)
	end
	return self
end

function FS:RemoveFullScreen()
	self.el:RemoveItem(self.el.sha1)
	return self
end

function FS:RemoveItem()
	FS_HANDLE:RemoveItem(self.el)
	if FS_HANDLE:GetItemCount() == 0 then
		FS_FRAME:Hide()
	end
end

LIB.RegisterEvent('LOGIN_GAME', Init)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_TeamMon_FS = LIB.GeneGlobalNS(settings)
end
