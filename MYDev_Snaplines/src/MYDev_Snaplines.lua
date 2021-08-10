--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 开发者工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local PLUGIN_NAME = 'MYDev_Snaplines'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_Snaplines'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------
-- 数据存储
--------------------------------------------------------------------------
local O = LIB.CreateUserSettingsModule('MYDev_Snaplines', {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bDetectBox = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowWndSnaplines = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowWndTip = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowItemTip = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowItemSnaplines = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTip = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowData = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	rgbWndSnaplines = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = {0, 0, 0},
	},
	rgbItemSnaplines = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = {0, 255, 0},
	},
	rgbTip = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = {255, 255, 0},
	},
	nTipFont = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Number,
		xDefaultValue = 40,
	},
	bAutoScale = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})

MYDev_Snaplines = {}
--------------------------------------------------------------------------
-- 本地函数
--------------------------------------------------------------------------
local function var2str(var, indent, level)
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == 'nil' then
			insert(t, 'nil')
		elseif szType == 'number' then
			insert(t, tostring(var))
		elseif szType == 'string' then
			insert(t, format('%q', var))
		-- elseif szType == 'function' then
			-- local s = dump(var)
			-- insert(t, 'loadstring('')
			-- -- 'string slice too long'
			-- for i = 1, #s, 2000 do
			--	 insert(t, concat({'', byte(s, i, i + 2000 - 1)}, '\\'))
			-- end
			-- insert(t, '')')
		elseif szType == 'boolean' then
			insert(t, tostring(var))
		elseif szType == 'table' then
			insert(t, '{')
			local s_tab_equ = ']='
			if indent then
				s_tab_equ = '] = '
				if not IsEmpty(var) then
					insert(t, '\n')
				end
			end
			for key, val in pairs(var) do
				if indent then
					insert(t, rep(indent, level + 1))
				end
				insert(t, '[')
				insert(t, table_r(key, level + 1, indent))
				insert(t, s_tab_equ) --'] = '
				insert(t, table_r(val, level + 1, indent))
				insert(t, ',')
				if indent then
					insert(t, '\n')
				end
			end
			if indent and not IsEmpty(var) then
				insert(t, rep(indent, level))
			end
			insert(t, '}')
		else --if (szType == 'userdata') then
			insert(t, '"')
			insert(t, tostring(var))
			insert(t, '"')
		end
		return concat(t)
	end
	return table_r(var, level or 0, indent)
end

local function InsertElementBasicTip(hElem, tTip)
	local X, Y = hElem:GetAbsPos()
	local x, y = hElem:GetRelPos()
	local w, h = hElem:GetSize()

	insert(tTip, _L('Name: %s', hElem:GetName()))
	insert(tTip, _L('Type: %s', hElem:GetType()))
	insert(tTip, _L('Path: %s', UI.GetTreePath(hElem)))
	insert(tTip, _L('X: %s, %s', x, X))
	insert(tTip, _L('Y: %s, %s', y, Y))
	insert(tTip, _L('W: %s', w))
	insert(tTip, _L('H: %s', h))
end

local function InsertElementDetailTip(hElem, tTip)
	local szType = hElem:GetType()
	if szType == 'Text' then
		insert(tTip, _L('FontScheme: %s', hElem:GetFontScheme()))
		insert(tTip, _L('Text: %s', hElem:GetText()))
		insert(tTip, _L('TextLen: %s', hElem:GetTextLen()))
		insert(tTip, _L('VAlign: %s', hElem:GetVAlign()))
		insert(tTip, _L('HAlign: %s', hElem:GetHAlign()))
		insert(tTip, _L('RowSpacing: %s', hElem:GetRowSpacing()))
		insert(tTip, _L('IsMultiLine: %s', tostring(hElem:IsMultiLine())))
		insert(tTip, _L('IsCenterEachLine: %s', tostring(hElem:IsCenterEachLine())))
		insert(tTip, _L('FontSpacing: %s', hElem:GetFontSpacing()))
		insert(tTip, _L('IsRichText: %s', tostring(hElem:IsRichText())))
		insert(tTip, _L('FontScale: %s', hElem:GetFontScale()))
		insert(tTip, _L('FontID: %s', hElem:GetFontID()))
		insert(tTip, _L('FontColor: %s', hElem:GetFontColor()))
		insert(tTip, _L('FontBoder: %s', hElem:GetFontBoder()))
		insert(tTip, _L('FontProjection: %s', hElem:GetFontProjection()))
		insert(tTip, _L('TextExtent: %s', hElem:GetTextExtent()))
		insert(tTip, _L('TextPosExtent: %s', hElem:GetTextPosExtent()))
		insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Image' then
		local szPath, nFrame = hElem:GetImagePath()
		insert(tTip, _L('Image: %s', szPath or ''))
		if nFrame then
			insert(tTip, _L('Frame: %s', nFrame))
		end
		insert(tTip, _L('ImageType: %s', hElem:GetImageType()))
		insert(tTip, _L('ImageID: %s', hElem:GetImageID()))
		insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Shadow' then
		insert(tTip, _L('ShadowColor: %s', hElem:GetShadowColor()))
		insert(tTip, _L('ColorRGB: %s, %s, %s', hElem:GetColorRGB()))
		insert(tTip, _L('IsTriangleFan: %s', tostring(hElem:IsTriangleFan())))
		insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Animate' then
		insert(tTip, _L('IsFinished: %s', tostring(hElem:IsFinished())))
		insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Box' then
		insert(tTip, _L('BoxIndex: %s', hElem:GetBoxIndex()))
		-- insert(tTip, _L('Object: %s', hElem:GetObject()))
		insert(tTip, _L('ObjectType: %s', hElem:GetObjectType()))
		insert(tTip, _L('ObjectData: %s', concat({hElem:GetObjectData()}, ', ')))
		insert(tTip, _L('IsEmpty: %s', tostring(hElem:IsEmpty())))
		if not hElem:IsEmpty() then
			insert(tTip, _L('IsObjectEnable: %s', tostring(hElem:IsObjectEnable())))
			insert(tTip, _L('IsObjectCoolDown: %s', tostring(hElem:IsObjectCoolDown())))
			insert(tTip, _L('IsObjectSelected: %s', tostring(hElem:IsObjectSelected())))
			insert(tTip, _L('IsObjectMouseOver: %s', tostring(hElem:IsObjectMouseOver())))
			insert(tTip, _L('IsObjectPressed: %s', tostring(hElem:IsObjectPressed())))
			insert(tTip, _L('CoolDownPercentage: %s', hElem:GetCoolDownPercentage()))
			insert(tTip, _L('ObjectIcon: %s', hElem:GetObjectIcon()))
			insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 0, hElem:GetOverTextFontScheme(0), hElem:GetOverTextPosition(0), hElem:GetOverText(0)))
			insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 1, hElem:GetOverTextFontScheme(1), hElem:GetOverTextPosition(1), hElem:GetOverText(1)))
			insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 2, hElem:GetOverTextFontScheme(2), hElem:GetOverTextPosition(2), hElem:GetOverText(2)))
			insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 3, hElem:GetOverTextFontScheme(3), hElem:GetOverTextPosition(3), hElem:GetOverText(3)))
			insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 4, hElem:GetOverTextFontScheme(4), hElem:GetOverTextPosition(4), hElem:GetOverText(4)))
		end
		insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'WndButton' then
		insert(tTip, _L('ImagePath: %s', hElem:GetAnimatePath()))
		insert(tTip, _L('Normal: %d', hElem:GetAnimateGroupNormal()))
		insert(tTip, _L('Over: %d', hElem:GetAnimateGroupMouseOver()))
		insert(tTip, _L('Down: %d', hElem:GetAnimateGroupMouseDown()))
		insert(tTip, _L('Disable: %d', hElem:GetAnimateGroupDisable()))
	end
end

local function InsertElementDataTip(hElem, tTip)
	local data = {}
	for k, v in pairs(hElem) do
		if type(v) ~= 'function' then
			data[k] = v
		end
	end
	insert(tTip, _L('data: %s', var2str(data, '  ')))
end

local function InsertElementTip(hElem, tTip)
	if O.bShowTip
	or O.bShowData then
		InsertElementBasicTip(hElem, tTip)
	end
	if O.bShowTip then
		InsertElementDetailTip(hElem, tTip)
	end
	if O.bShowData then
		InsertElementDataTip(hElem, tTip)
	end
end

--------------------------------------------------------------------------
-- 界面事件响应
--------------------------------------------------------------------------
function MYDev_Snaplines.OnFrameCreate()
	local W, H = Station.GetClientSize()
	-- Wnd辅助线
	if O.bShowWndSnaplines then
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndLeft'  ):SetColorRGB(unpack(O.rgbWndSnaplines))
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndRight' ):SetColorRGB(unpack(O.rgbWndSnaplines))
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndTop'   ):SetColorRGB(unpack(O.rgbWndSnaplines))
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndBottom'):SetColorRGB(unpack(O.rgbWndSnaplines))
	else
		this:Lookup('', 'Handle_Snaplines_Wnd'):Hide()
	end
	-- Item辅助线
	if O.bShowItemSnaplines then
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemLeft'  ):SetColorRGB(unpack(O.rgbItemSnaplines))
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemRight' ):SetColorRGB(unpack(O.rgbItemSnaplines))
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemTop'   ):SetColorRGB(unpack(O.rgbItemSnaplines))
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemBottom'):SetColorRGB(unpack(O.rgbItemSnaplines))
	else
		this:Lookup('', 'Handle_Snaplines_Item'):Hide()
	end
	-- 文字
	this:Lookup('', 'Handle_Tip/Text_HoverTip'):SetFontScheme(O.nTipFont)
	this:Lookup('', 'Handle_Tip/Text_HoverTip'):SetFontColor(unpack(O.rgbTip))

	MYDev_Snaplines.OnEvent('UI_SCALED')
end

function MYDev_Snaplines.OnFrameBreathe()
	local hWnd, hItem = Station.GetMouseOverWindow()
	if hWnd then
		-- Wnd
		local nClientW, nClientH = Station.GetClientSize()
		local nCursorX, nCursorY = Cursor.GetPos()
		local nWndX   , nWndY    = hWnd:GetAbsPos()
		local nWndW   , nWndH    = hWnd:GetSize()
		local hText = this:Lookup('', 'Handle_Tip/Text_HoverTip')
		-- Wnd信息
		local tTip = {}
		insert(tTip, _L('CursorX: %s', nCursorX))
		insert(tTip, _L('CursorY: %s', nCursorY))
		if O.bShowWndTip then
			InsertElementTip(hWnd, tTip)
		end
		-- Wnd辅助线位置
		if O.bShowWndSnaplines then
			this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndLeft'  ):SetAbsPos(nWndX - 2    , 0)
			this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndRight' ):SetAbsPos(nWndX + nWndW, 0)
			this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndTop'   ):SetAbsPos(0, nWndY - 2    )
			this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndBottom'):SetAbsPos(0, nWndY + nWndH)
		end
		-- 检测鼠标所在Box信息
		if O.bDetectBox and not (hItem and hItem:GetType() == 'Box') then
			UI(hWnd):Find('.Box'):Each(function()
				if this:PtInItem(nCursorX, nCursorY) then
					insert(tTip, '---------------------')
					InsertElementTip(this, tTip)
				end
			end)
		end
		-- Item
		if hItem then
			-- Item信息
			local nItemX, nItemY = hItem:GetAbsPos()
			local nItemW, nItemH = hItem:GetSize()
			insert(tTip, _L['-------------------'])
			if O.bShowItemTip then
				InsertElementTip(hItem, tTip)
			end
			-- Item辅助线位置
			if O.bShowItemSnaplines then
				this:Lookup('', 'Handle_Snaplines_Item'):Show()
				this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemLeft'  ):SetAbsPos(nItemX - 2     , 0)
				this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemRight' ):SetAbsPos(nItemX + nItemW, 0)
				this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemTop'   ):SetAbsPos(0, nItemY - 2     )
				this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemBottom'):SetAbsPos(0, nItemY + nItemH)
			end
		else
			this:Lookup('', 'Handle_Snaplines_Item'):Hide()
		end
		hText:SetText(concat(tTip, '\n'))

		-- 缩放
		if O.bAutoScale then
			-- hText:EnableScale(true)
			hText:SetFontScale(1)
			hText:AutoSize()
			local nTextW, nTextH = hText:GetSize()
			local fScale = min( nClientW / nTextW, nClientH / nTextH )
			if fScale < 1 then
				hText:SetFontScale(fScale)
				hText:AutoSize()
			end
		end

		-- 位置
		local nTextW, nTextH = hText:GetSize()
		local nTextX, nTextY
		nTextX = nWndX + 5
		if nTextX + nTextW > nClientW then
			nTextX = nClientW - nTextW
		elseif nTextX < 0 then
			nTextX = 0
		end

		local bReAdjustX
		if nWndY >= nTextH then -- 顶部可以显示的下
			nTextY = nWndY - nTextH
		elseif nWndY + nWndH + 1 + nTextH <= nClientH then -- 底部显示的下
			nTextY = nWndY + nWndH + 1
		elseif nWndY + nTextH <= nClientH then -- 中间开始显示的下
			nTextY = nWndY + 20
			bReAdjustX = true
		else
			nTextY = 5
			bReAdjustX = true
		end
		if bReAdjustX then
			if nWndX >= nTextW + 5 then -- 左侧显示的下
				nTextX = nWndX - nTextW - 5
			elseif nWndX + nWndW + nTextW + 5 <= nClientW then -- 右侧显示的下
				nTextX = nWndX + nWndW + 5
			end
		end
		hText:SetAbsPos(nTextX, nTextY)
	end
	this:BringToTop()
end

function MYDev_Snaplines.OnEvent(event)
	if event == 'UI_SCALED' then
		local W, H = Station.GetClientSize()
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndLeft'   ):SetSize(2, H)
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndRight'  ):SetSize(2, H)
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndTop'    ):SetSize(W, 2)
		this:Lookup('', 'Handle_Snaplines_Wnd/Shadow_HoverWndBottom' ):SetSize(W, 2)
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemLeft'  ):SetSize(2, H)
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemRight' ):SetSize(2, H)
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemTop'   ):SetSize(W, 2)
		this:Lookup('', 'Handle_Snaplines_Item/Shadow_HoverItemBottom'):SetSize(W, 2)
	end
end

--------------------------------------------------------------------------
-- 控制部分
--------------------------------------------------------------------------
-- 重载界面
MYDev_Snaplines.ReloadUI = function()
	Wnd.CloseWindow('MYDev_Snaplines')
	if O.bEnable then
		Wnd.OpenWindow(PACKET_INFO.ROOT .. 'MYDev_Snaplines/ui/MYDev_Snaplines.ini', 'MYDev_Snaplines')
	end
end
LIB.RegisterInit('MYDEV_SNAPLINES', MYDev_Snaplines.ReloadUI)

-- 注册面板
LIB.RegisterPanel(_L['Development'], 'Dev_Snaplines', _L['Snaplines'], 'ui/Image/UICommon/PlugIn.UITex|1', {
	IsRestricted = function()
		return not LIB.IsDebugClient('Dev_Snaplines')
	end,
	OnPanelActive = function(wnd)
		local ui = UI(wnd)
		local w, h = ui:Size()
		local x, y = 20, 20

		ui:Append('WndCheckBox', 'WndCheckBox_ShowTreePath')
		  :Pos(x, y):Width(300)
		  :Text(_L['enable tree path view']):Check(O.bEnable or false)
		  :Check(function(bCheck)
			O.bEnable = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		y = y + 40

		ui:Append('WndCheckBox', 'WndCheckBox_ShowTip')
		  :Pos(x, y):Width(200)
		  :Text(_L['show tip']):Check(O.bShowTip or false)
		  :Check(function(bCheck)
			O.bShowTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		x = x + 200
		ui:Append('Shadow', 'Shadow_TipColor'):Pos(x, y)
		  :Size(20, 20):Color(O.rgbTip or {255,255,255})
		  :Click(function()
			local me = this
			UI.OpenColorPicker(function(r, g, b)
				UI(me):Color(r, g, b)
				O.rgbTip = { r, g, b }
				MYDev_Snaplines.ReloadUI()
			end)
		  end)
		x = x + 40
		ui:Append('WndButton', 'WndButton_TipFont'):Pos(x, y)
		  :Width(50):Text(_L['font'])
		  :Click(function()
			UI.OpenFontPicker(function(f)
				O.nTipFont = f
				MYDev_Snaplines.ReloadUI()
			end)
		  end)
		x = 20
		y = y + 40
		ui:Append('WndCheckBox', 'WndCheckBox_ShowData')
		  :Pos(x, y):Width(200)
		  :Text(_L['show data']):Check(O.bShowData or false)
		  :Check(function(bCheck)
			O.bShowData = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		y = y + 40

		ui:Append('WndCheckBox', 'WndCheckBox_ShowWndTip')
		  :Pos(x, y):Width(200)
		  :Text(_L['show wnd tip']):Check(O.bShowWndTip or false)
		  :Check(function(bCheck)
			O.bShowWndTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		y = y + 40
		ui:Append('WndCheckBox', 'WndCheckBox_ShowItemTip')
		  :Pos(x, y):Width(200)
		  :Text(_L['show item tip']):Check(O.bShowItemTip or false)
		  :Check(function(bCheck)
			O.bShowItemTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		y = y + 40

		ui:Append('WndCheckBox', 'WndCheckBox_ShowWndSnaplines')
		  :Pos(x, y):Width(200)
		  :Text(_L['show wnd snaplines']):Check(O.bShowWndSnaplines or false)
		  :Check(function(bCheck)
			O.bShowWndSnaplines = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		x = x + 200
		ui:Append('Shadow', 'Shadow_WndSnaplinesColor'):Pos(x, y)
		  :Size(20, 20):Color(O.rgbWndSnaplines or {255,255,255})
		  :Click(function()
			local me = this
			UI.OpenColorPicker(function(r, g, b)
				UI(me):Color(r, g, b)
				O.rgbWndSnaplines = { r, g, b }
				MYDev_Snaplines.ReloadUI()
			end)
		  end)
		x = 20
		y = y + 40

		ui:Append('WndCheckBox', 'WndCheckBox_ShowItemSnaplines')
		  :Pos(x, y):Width(200)
		  :Text(_L['show item snaplines']):Check(O.bShowItemSnaplines or false)
		  :Check(function(bCheck)
			O.bShowItemSnaplines = bCheck
			MYDev_Snaplines.ReloadUI()
		end)
		x = x + 200
		ui:Append('Shadow', 'Shadow_ItemSnaplinesColor'):Pos(x, y)
		  :Size(20, 20):Color(O.rgbItemSnaplines or {255,255,255})
		  :Click(function()
			local me = this
			UI.OpenColorPicker(function(r, g, b)
				UI(me):Color(r, g, b)
				O.rgbItemSnaplines = { r, g, b }
				MYDev_Snaplines.ReloadUI()
			end)
		  end)
		x = 20
		y = y + 40

		ui:Append('WndCheckBox', 'WndCheckBox_AutoDetectBox')
		  :Pos(x, y):Width(200)
		  :Text(_L['auto detect box']):Check(O.bDetectBox or false)
		  :Check(function(bCheck)
			O.bDetectBox = bCheck
		end)
		y = y + 40

		ui:Append('WndCheckBox', {
			x = x, y = y, w = 200, text = _L['auto scale'], checked = O.bAutoScale,
			oncheck = function(bCheck) O.bAutoScale = bCheck end
		})
		y = y + 40

		ui:Append('Text', 'Text_SetHotkey'):Pos(w-140, 20):Color(255,255,0)
		  :Text(_L['>> set hotkey <<'])
		  :Click(function() LIB.SetHotKey() end)
	end
})
-- 注册快捷键
LIB.RegisterHotKey('MY_Dev_Snaplines'         , _L['Snaplines']           , function() O.bEnable   = not O.bEnable   MYDev_Snaplines.ReloadUI() end, nil)
LIB.RegisterHotKey('MY_Dev_Snaplines_ShowTip' , _L['Snaplines - ShowTip'] , function() O.bShowTip  = not O.bShowTip  MYDev_Snaplines.ReloadUI() end, nil)
LIB.RegisterHotKey('MY_Dev_Snaplines_ShowData', _L['Snaplines - ShowData'], function() O.bShowData = not O.bShowData MYDev_Snaplines.ReloadUI() end, nil)
-- For Debug
if IsDebugClient and IsDebugClient() then
	LIB.RegisterInit('Dev_Snaplines_Hotkey', function()
		LIB.SetHotKey('MY_Dev_Snaplines', 121)
		LIB.SetHotKey('MY_Dev_Snaplines_ShowTip', 122)
		LIB.SetHotKey('MY_Dev_Snaplines_ShowData', 123)
	end)
end
