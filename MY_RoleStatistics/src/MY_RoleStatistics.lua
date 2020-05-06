--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ɫͳ�ƿ��
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
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	aModule = {},
}
local Framework = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_RoleStatistics.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_RoleStatistics.Mod.ini'

function D.Open(szModule)
	local frame = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics')
	D.ActivePage(frame, szModule or 1, true)
end

function D.Close()
	Wnd.CloseWindow('MY_RoleStatistics')
end

function D.IsOpened()
	return Station.Lookup('Normal/MY_RoleStatistics')
end

function D.Toggle()
	if D.IsOpened() then
		D.Close()
	else
		D.Open()
	end
end

-- ע����ģ��
function D.RegisterModule(szID, szName, env)
	for i, v in ipairs_r(O.aModule) do
		if v.szID == szID then
			remove(O.aModule, i)
		end
	end
	if szName and env then
		insert(O.aModule, {
			szID = szID,
			szName = szName,
			env = env,
		})
	end
	if D.IsOpened() then
		D.Close()
		D.Open()
	end
end

-- ��ʼ�������� ���Ʒ�ҳ��ť
function D.InitPageSet(frame)
	frame.bInitPageset = true
	local pageset = frame:Lookup('PageSet_All')
	for i, m in ipairs(O.aModule) do
		local frameMod = Wnd.OpenWindow(SZ_MOD_INI, 'MY_RoleStatisticsMod')
		local checkbox = frameMod:Lookup('PageSet_Total/WndCheck_Default')
		local page = frameMod:Lookup('PageSet_Total/Page_Default')
		checkbox:ChangeRelation(pageset, true, true)
		page:ChangeRelation(pageset, true, true)
		Wnd.CloseWindow(frameMod)
		pageset:AddPage(page, checkbox)
		checkbox:Show()
		checkbox:Lookup('', 'Text_CheckDefault'):SetText(m.szName)
		checkbox:SetRelX(checkbox:GetRelX() + checkbox:GetW() * (i - 1))
		checkbox.nIndex = i
		page.nIndex = i
	end
	frame.bInitPageset = nil
end

function D.ActivePage(frame, szModule, bFirst)
	local pageset = frame:Lookup('PageSet_All')
	local pageActive = pageset:GetActivePage()
	local nActiveIndex, nToIndex = pageActive.nIndex, nil
	for i, m in ipairs(O.aModule) do
		if m.szID == szModule or i == szModule then
			nToIndex = i
		end
	end
	if bFirst and not nToIndex then
		nToIndex = 1
	end
	if nToIndex then
		if nToIndex == nActiveIndex then
			local _this = this
			this = pageset
			Framework.OnActivePage()
			this = _this
		else
			pageset:ActivePage(nToIndex - 1)
		end
	end
end

function Framework.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		D.Close()
	elseif name == 'Btn_Option' then
		local menu = {}
		local tFloatEntryMenu = { szOption = _L['Float panel'] }
		for _, m in ipairs(O.aModule) do
			if m and m.env.szFloatEntry then
				insert(tFloatEntryMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = Get(_G, m.env.szFloatEntry),
					fnAction = function()
						Set(_G, m.env.szFloatEntry, not Get(_G, m.env.szFloatEntry))
					end,
				})
			end
		end
		if #tFloatEntryMenu > 0 then
			insert(menu, tFloatEntryMenu)
		end
		local tSaveDBMenu = { szOption = _L['Save DB'] }
		for _, m in ipairs(O.aModule) do
			if m and m.env.szSaveDB then
				insert(tSaveDBMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = Get(_G, m.env.szSaveDB),
					fnAction = function()
						Set(_G, m.env.szSaveDB, not Get(_G, m.env.szSaveDB))
					end,
				})
			end
		end
		if #tSaveDBMenu > 0 then
			insert(menu, tSaveDBMenu)
		end
		if #menu > 0 then
			local nX, nY = this:GetAbsPos()
			local nW, nH = this:GetSize()
			menu.nMiniWidth = nW
			menu.x = nX
			menu.y = nY + nH
			UI.PopupMenu(menu)
		end
	end
end

function Framework.OnActivePage()
	if this:GetRoot().bInitPageset then
		return
	end
	local name = this:GetName()
	if name == 'PageSet_All' then
		local page = this:GetActivePage()
		if page.nIndex then
			local m = O.aModule[page.nIndex]
			if not page.bInit then
				if m and m.env.OnInitPage then
					local _this = this
					this = page
					m.env.OnInitPage()
					this = _this
				end
				page.bInit = true
			end
			if m and m.env.OnActivePage then
				local _this = this
				this = page
				m.env.OnActivePage()
				this = _this
			end
		end
	end
end

function Framework.OnFrameCreate()
	D.InitPageSet(this)
	this:BringToTop()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(PACKET_INFO.NAME .. ' - ' .. _L['MY_RoleStatistics'])
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function Framework.OnFrameDestroy()
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

-- ȫ�ֹ㲥ģ���¼�
for _, szEvent in ipairs({
	'OnFrameCreate',
	'OnFrameDestroy',
	'OnFrameBreathe',
	'OnFrameRender',
	'OnFrameDragEnd',
	'OnFrameDragSetPosEnd',
	'OnEvent',
}) do
	D[szEvent] = function(...)
		if Framework[szEvent] then
			Framework[szEvent](...)
		end
		local page = this:Lookup('PageSet_All'):GetFirstChild()
		while page do
			if page:GetName() == 'Page_Default' and page.bInit then
				local m = O.aModule[page.nIndex]
				if m and m.env[szEvent] then
					local _this = this
					this = page
					m.env[szEvent](...)
					this = _this
				end
			end
			page = page:GetNext()
		end
	end
end

-- ����Ԫ��λ��ת����Ӧģ���¼�
for _, szEvent in ipairs({
	'OnSetFocus',
	'OnKillFocus',
	'OnItemLButtonDown',
	'OnItemMButtonDown',
	'OnItemRButtonDown',
	'OnItemLButtonUp',
	'OnItemMButtonUp',
	'OnItemRButtonUp',
	'OnItemLButtonClick',
	'OnItemMButtonClick',
	'OnItemRButtonClick',
	'OnItemMouseEnter',
	'OnItemMouseLeave',
	'OnItemRefreshTip',
	'OnItemMouseWheel',
	'OnItemLButtonDrag',
	'OnItemLButtonDragEnd',
	'OnLButtonDown',
	'OnLButtonUp',
	'OnLButtonClick',
	'OnLButtonHold',
	'OnMButtonDown',
	'OnMButtonUp',
	'OnMButtonClick',
	'OnMButtonHold',
	'OnRButtonDown',
	'OnRButtonUp',
	'OnRButtonClick',
	'OnRButtonHold',
	'OnMouseEnter',
	'OnMouseLeave',
	'OnScrollBarPosChanged',
	'OnEditChanged',
	'OnEditSpecialKeyDown',
	'OnCheckBoxCheck',
	'OnCheckBoxUncheck',
	'OnActivePage',
}) do
	D[szEvent] = function(...)
		local szPrefix = 'Normal/MY_Statistics/PageSet_All/Page_Default'
		local page, nLimit = this, 50
		while page and page:GetName() ~= 'Page_Default' and page:GetTreePath() ~= szPrefix do
			if nLimit > 0 then
				page = page:GetParent()
				nLimit = nLimit - 1
			else
				page = nil
			end
		end
		if page and page ~= this then
			local m = O.aModule[page.nIndex]
			if m and m.env[szEvent] then
				return m.env[szEvent](...)
			end
		else
			if Framework[szEvent] then
				return Framework[szEvent](...)
			end
		end
	end
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
				IsOpened = D.IsOpened,
				Toggle = D.Toggle,
				RegisterModule = D.RegisterModule,
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_RoleStatistics = LIB.GeneGlobalNS(settings)
end

do
local menu = {
	szOption = _L['MY_RoleStatistics'],
	fnAction = function() D.Toggle() end,
}
LIB.RegisterAddonMenu('MY_RoleStatistics', menu)
end
LIB.RegisterHotKey('MY_RoleStatistics', _L['Open/Close MY_RoleStatistics'], D.Toggle, nil)