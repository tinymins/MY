--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 请求处理弹框界面
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local LIB = Boilerplate
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local D = {}
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Request.ini'
local REQUEST_LIST = {}
local REQUEST_HANDLER = {}
local FRAME_NAME = NSFormatString('{$NS}_Request')

function D.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function D.Open()
	local frame = D.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, FRAME_NAME)
	end
	return frame
end

function D.Close(bCompulsory)
	local function fnAction()
		REQUEST_LIST = {}
		Wnd.CloseWindow(D.GetFrame())
		for _, v in pairs(REQUEST_HANDLER) do
			SafeCall(v.OnClear)
		end
	end
	if bCompulsory or IsEmpty(REQUEST_LIST) then
		fnAction()
	else
		LIB.Confirm(_L['Clear list and close?'], fnAction)
	end
end

function D.RegisterRequest(szType, tHandler)
	if REQUEST_HANDLER[szType] then
		return LIB.Debug(FRAME_NAME, szType .. ' type already registered!', DEBUG_LEVEL.ERROR)
	end
	REQUEST_HANDLER[szType] = {
		szIconUITex = tHandler.szIconUITex,
		nIconFrame = tHandler.nIconFrame,
		Drawer = tHandler.Drawer,
		GetTip = tHandler.GetTip,
		GetIcon = tHandler.GetIcon,
		GetMenu = tHandler.GetMenu,
		OnClear = tHandler.OnClear,
	}
end

function D.Replace(szType, szKey, data)
	if not REQUEST_HANDLER[szType] then
		return LIB.Debug(FRAME_NAME, szType .. ' type not registered yet!', DEBUG_LEVEL.ERROR)
	end
	local bExist
	for i, v in ipairs_r(REQUEST_LIST) do
		if v.szType == szType and v.szKey == szKey then
			bExist = true
			v.data = data
		end
	end
	if not bExist then
		insert(REQUEST_LIST, { szType = szType, szKey = szKey, data = data })
	end
	LIB.DelayCall(FRAME_NAME .. '_Update', 1, D.RedrawList)
end

function D.RemoveRequest(szType, szKey)
	local bExist
	for i, v in ipairs_r(REQUEST_LIST) do
		if v.szType == szType and v.szKey == szKey then
			bExist = true
			remove(REQUEST_LIST, i)
		end
	end
	if not bExist then
		return
	end
	LIB.DelayCall(FRAME_NAME .. '_Update', 1, D.RedrawList)
end

function D.RedrawList()
	local frame = #REQUEST_LIST > 0
		and D.Open()
		or D.Close(true)
	if not frame then
		return
	end
	local scroll = frame:Lookup('Scroll_Request')
	local scrollbar = scroll:Lookup('ScrolBar_Request')
	local container = scroll:Lookup('WndContainer_Request')
	local nSumH = 0
	container:Clear()
	for i, info in ipairs(REQUEST_LIST) do
		local wnd = container:AppendContentFromIni(INI_PATH, 'WndWindow_Item')
		local handler = REQUEST_HANDLER[info.szType]
		local inner, nH = handler.Drawer(wnd, info.data)
		if inner then
			inner:SetName('Wnd_Content')
			inner:SetRelPos(56, 0)
			nH = inner:GetH()
			wnd:Lookup('', 'Image_Hover'):SetH(nH)
			wnd:Lookup('', 'Image_TypeIcon'):SetRelY((nH - wnd:Lookup('', 'Image_TypeIcon'):GetH()) / 2)
			wnd:Lookup('', 'Image_Spliter'):SetRelY(nH - 8)
			wnd:Lookup('', ''):FormatAllItemPos()
			wnd:SetH(nH)
		else
			LIB.Debug(FRAME_NAME, info.szType .. '#' .. info.szKey .. ' drawer does not return a wnd!', DEBUG_LEVEL.ERROR)
		end
		local szIconUITex, nIconFrame = handler.szIconUITex, handler.nIconFrame
		if handler.GetIcon then
			szIconUITex, nIconFrame = handler.GetIcon(info.data, szIconUITex, nIconFrame)
		end
		if szIconUITex == 'FromIconID' then
			wnd:Lookup('', 'Image_TypeIcon'):FromIconID(nIconFrame)
		elseif szIconUITex and nIconFrame and nIconFrame >= 0 then
			wnd:Lookup('', 'Image_TypeIcon'):FromUITex(szIconUITex, nIconFrame)
		elseif szIconUITex then
			wnd:Lookup('', 'Image_TypeIcon'):FromTextureFile(szIconUITex)
		end
		wnd:Lookup('', 'Image_Spliter'):SetVisible(i ~= #REQUEST_LIST)
		wnd.info = info
		nSumH = nSumH + nH
	end
	nSumH = min(nSumH, 475)
	scroll:SetH(nSumH)
	scrollbar:SetH(nSumH - 2)
	container:SetH(nSumH)
	container:FormatAllContentPos()
	frame:Lookup('', 'Image_Bg'):SetH(nSumH + 4)
	frame:SetH(nSumH + 30 + 4)
end

function D.OnFrameCreate()
	this:SetPoint('CENTER', 0, -200, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(_L['Request list'])
	LIB.RegisterEsc(NSFormatString('{$NS}_PartyRequest'), D.GetFrame, D.Close)
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Image_TypeIcon' then
		local info = this:GetParent():GetParent().info
		local GetTip = REQUEST_HANDLER[info.szType].GetTip
		if GetTip then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szTip = GetTip(info.data)
			OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
		end
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Image_TypeIcon' then
		HideTip()
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		local menu = {}
		for _, v in pairs(REQUEST_HANDLER) do
			if v.GetMenu then
				insert(menu, v.GetMenu())
			end
		end
		if #menu > 0 then
			PopupMenu(menu)
		end
	elseif name == 'Btn_Close' then
		D.Close()
	end
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
_G[FRAME_NAME] = LIB.CreateModule(settings)
end

UI.OpenRequest = D.Open
UI.CloseRequest = D.Close
UI.RegisterRequest = D.RegisterRequest
UI.ReplaceRequest = D.Replace
UI.RemoveRequest = D.RemoveRequest
