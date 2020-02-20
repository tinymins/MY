--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色统计框架
-- @author   : 茗伊 @双梦镇 @追风蹑影
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

function D.Open()
	Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics')
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

-- 注册子模块
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

-- 初始化主界面 绘制分页按钮
function D.InitPageSet(frame)
	local pageAct
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
		if not pageAct then
			pageAct = page
		end
	end
	if pageAct then
		local _this = this
		this = pageset
		Framework.OnActivePage()
		this = _this
	end
end

function Framework.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		D.Close()
	end
end

function Framework.OnActivePage()
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
end

-- 全局广播模块事件
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

-- 根据元素位置转发对应模块事件
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
LIB.RegisterAddonMenu('MY_BAGSTATISTICS_MENU', menu)
end
LIB.RegisterHotKey('MY_RoleStatistics', _L['Open/Close MY_RoleStatistics'], D.Toggle, nil)
