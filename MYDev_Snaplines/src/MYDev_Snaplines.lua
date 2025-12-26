--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 开发者工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MYDev_Snaplines/MYDev_Snaplines'
local PLUGIN_NAME = 'MYDev_Snaplines'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_Snaplines'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
-- 数据存储
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MYDev_Snaplines', {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['enable tree path view'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bDetectBox = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['auto detect box'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowWndSnaplines = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show wnd snaplines'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowWndTip = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show wnd tip'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowItemTip = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show item tip'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowItemSnaplines = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show item snaplines'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTip = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show tip'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowData = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show data'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	rgbWndSnaplines = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show wnd snaplines'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = {0, 0, 0},
	},
	rgbItemSnaplines = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show item snaplines'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = {0, 255, 0},
	},
	rgbTip = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['show tip'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = {255, 255, 0},
	},
	nTipFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['font'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 40,
	},
	bAutoScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_Snaplines'],
		szDescription = X.MakeCaption({
			_L['auto scale'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})

MYDev_Snaplines = {}
--------------------------------------------------------------------------
-- 本地函数
--------------------------------------------------------------------------
local function var2str(var, indent, level)
	local exists = {}
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == 'nil' then
			table.insert(t, 'nil')
		elseif szType == 'number' then
			table.insert(t, tostring(var))
		elseif szType == 'string' then
			table.insert(t, string.format('%q', var))
		-- elseif szType == 'function' then
			-- local s = string.dump(var)
			-- table.insert(t, 'loadstring('')
			-- -- 'string slice too long'
			-- for i = 1, #s, 2000 do
			--	 table.insert(t, table.concat({'', string.byte(s, i, i + 2000 - 1)}, '\\'))
			-- end
			-- table.insert(t, '')')
		elseif szType == 'boolean' then
			table.insert(t, tostring(var))
		elseif szType == 'table' then
			if exists [var] then
				table.insert(t, '"[[recursive table]]"')
			else
				exists[var] = true
				table.insert(t, '{')
				local s_tab_equ = ']='
				if indent then
					s_tab_equ = '] = '
					if not X.IsEmpty(var) then
						table.insert(t, '\n')
					end
				end
				for key, val in pairs(var) do
					if indent then
						table.insert(t, string.rep(indent, level + 1))
					end
					table.insert(t, '[')
					table.insert(t, table_r(key, level + 1, indent))
					table.insert(t, s_tab_equ) --'] = '
					table.insert(t, table_r(val, level + 1, indent))
					table.insert(t, ',')
					if indent then
						table.insert(t, '\n')
					end
				end
				if indent and not X.IsEmpty(var) then
					table.insert(t, string.rep(indent, level))
				end
				table.insert(t, '}')
			end
		else --if (szType == 'userdata') then
			table.insert(t, '"')
			table.insert(t, tostring(var))
			table.insert(t, '"')
		end
		return table.concat(t)
	end
	return table_r(var, level or 0, indent)
end

local function InsertElementBasicTip(hElem, tTip)
	local nAbsX, nAbsY = hElem:GetAbsPos()
	local nRelX, nRelY = hElem:GetRelPos()
	local nW, nH = hElem:GetSize()

	table.insert(tTip, _L('Name: %s', hElem:GetName()))
	table.insert(tTip, _L('Type: %s', hElem:GetType()))
	table.insert(tTip, _L('Path: %s', X.UI.GetTreePath(hElem)))
	table.insert(tTip, _L('X: %s, %s', nRelX, nAbsX))
	table.insert(tTip, _L('Y: %s, %s', nRelY, nAbsY))
	table.insert(tTip, _L('W: %s', nW))
	table.insert(tTip, _L('H: %s', nH))
end

local function InsertElementDetailTip(hElem, tTip)
	local szType = hElem:GetType()
	if szType == 'Text' then
		table.insert(tTip, _L('FontScheme: %s', hElem:GetFontScheme()))
		table.insert(tTip, _L('Text: %s', hElem:GetText()))
		table.insert(tTip, _L('TextLen: %s', hElem:GetTextLen()))
		table.insert(tTip, _L('VAlign: %s', hElem:GetVAlign()))
		table.insert(tTip, _L('HAlign: %s', hElem:GetHAlign()))
		table.insert(tTip, _L('RowSpacing: %s', hElem:GetRowSpacing()))
		table.insert(tTip, _L('IsMultiLine: %s', tostring(hElem:IsMultiLine())))
		table.insert(tTip, _L('IsCenterEachLine: %s', tostring(hElem:IsCenterEachLine())))
		table.insert(tTip, _L('FontSpacing: %s', hElem:GetFontSpacing()))
		table.insert(tTip, _L('IsRichText: %s', tostring(hElem:IsRichText())))
		table.insert(tTip, _L('FontScale: %s', hElem:GetFontScale()))
		table.insert(tTip, _L('FontID: %s', hElem:GetFontID()))
		table.insert(tTip, _L('FontColor: %s', table.concat({ hElem:GetFontColor() }, ', ')))
		table.insert(tTip, _L('FontBoder: %s', hElem:GetFontBoder()))
		table.insert(tTip, _L('FontProjection: %s', hElem:GetFontProjection()))
		table.insert(tTip, _L('TextExtent: %s', hElem:GetTextExtent()))
		table.insert(tTip, _L('TextPosExtent: %s', hElem:GetTextPosExtent()))
		table.insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Image' then
		local szPath, nFrame = hElem:GetImagePath()
		table.insert(tTip, _L('Image: %s', szPath or ''))
		if nFrame then
			table.insert(tTip, _L('Frame: %s', nFrame))
		end
		table.insert(tTip, _L('ImageType: %s', hElem:GetImageType()))
		table.insert(tTip, _L('ImageID: %s', hElem:GetImageID()))
		table.insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Shadow' then
		table.insert(tTip, _L('ShadowColor: %s', table.concat({ hElem:GetShadowColor() }, ', ')))
		table.insert(tTip, _L('ColorRGB: %s', table.concat({ hElem:GetColorRGB() }, ', ')))
		table.insert(tTip, _L('IsTriangleFan: %s', tostring(hElem:IsTriangleFan())))
		table.insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Animate' then
		table.insert(tTip, _L('IsFinished: %s', tostring(hElem:IsFinished())))
		table.insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'Box' then
		table.insert(tTip, _L('BoxIndex: %s', hElem:GetBoxIndex()))
		-- table.insert(tTip, _L('Object: %s', hElem:GetObject()))
		table.insert(tTip, _L('ObjectType: %s', hElem:GetObjectType()))
		table.insert(tTip, _L('ObjectData: %s', table.concat({hElem:GetObjectData()}, ', ')))
		table.insert(tTip, _L('IsEmpty: %s', tostring(hElem:IsEmpty())))
		if not hElem:IsEmpty() then
			table.insert(tTip, _L('IsObjectEnable: %s', tostring(hElem:IsObjectEnable())))
			table.insert(tTip, _L('IsObjectCoolDown: %s', tostring(hElem:IsObjectCoolDown())))
			table.insert(tTip, _L('IsObjectSelected: %s', tostring(hElem:IsObjectSelected())))
			table.insert(tTip, _L('IsObjectMouseOver: %s', tostring(hElem:IsObjectMouseOver())))
			table.insert(tTip, _L('IsObjectPressed: %s', tostring(hElem:IsObjectPressed())))
			table.insert(tTip, _L('CoolDownPercentage: %s', hElem:GetCoolDownPercentage()))
			table.insert(tTip, _L('ObjectIcon: %s', hElem:GetObjectIcon()))
			table.insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 0, hElem:GetOverTextFontScheme(0), hElem:GetOverTextPosition(0), hElem:GetOverText(0)))
			table.insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 1, hElem:GetOverTextFontScheme(1), hElem:GetOverTextPosition(1), hElem:GetOverText(1)))
			table.insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 2, hElem:GetOverTextFontScheme(2), hElem:GetOverTextPosition(2), hElem:GetOverText(2)))
			table.insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 3, hElem:GetOverTextFontScheme(3), hElem:GetOverTextPosition(3), hElem:GetOverText(3)))
			table.insert(tTip, _L('OverText%s: [Font]%s [Pos]%s [Text]%s', 4, hElem:GetOverTextFontScheme(4), hElem:GetOverTextPosition(4), hElem:GetOverText(4)))
		end
		table.insert(tTip, _L('Index: %s', hElem:GetIndex()))
	elseif szType == 'WndButton' then
		table.insert(tTip, _L('ImagePath: %s', hElem:GetAnimatePath() or ''))
		table.insert(tTip, _L('Normal: %d', hElem:GetAnimateGroupNormal()))
		table.insert(tTip, _L('Over: %d', hElem:GetAnimateGroupMouseOver()))
		table.insert(tTip, _L('Down: %d', hElem:GetAnimateGroupMouseDown()))
		table.insert(tTip, _L('Disable: %d', hElem:GetAnimateGroupDisable()))
	end
end

local function InsertElementDataTip(hElem, tTip)
	local data = {}
	for k, v in pairs(hElem) do
		if type(v) ~= 'function' then
			data[k] = v
		end
	end
	table.insert(tTip, _L('data: %s', var2str(data, '  ')))
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
		table.insert(tTip, _L('CursorX: %s', nCursorX))
		table.insert(tTip, _L('CursorY: %s', nCursorY))
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
			X.UI(hWnd):Find('.Box'):Each(function()
				if this:PtInItem(nCursorX, nCursorY) then
					table.insert(tTip, '---------------------')
					InsertElementTip(this, tTip)
				end
			end)
		end
		-- Item
		if hItem then
			-- Item信息
			local nItemX, nItemY = hItem:GetAbsPos()
			local nItemW, nItemH = hItem:GetSize()
			table.insert(tTip, _L['-------------------'])
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
		hText:SetText(table.concat(tTip, '\n'))

		-- 缩放
		if O.bAutoScale then
			-- hText:EnableScale(true)
			hText:SetFontScale(1)
			hText:AutoSize()
			local nTextW, nTextH = hText:GetSize()
			local fScale = math.min( nClientW / nTextW, nClientH / nTextH )
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
	X.UI.CloseFrame('MYDev_Snaplines')
	if O.bEnable then
		X.UI.OpenFrame(X.PACKET_INFO.ROOT .. 'MYDev_Snaplines/ui/MYDev_Snaplines.ini', 'MYDev_Snaplines')
	end
end
X.RegisterInit('MYDEV_SNAPLINES', MYDev_Snaplines.ReloadUI)

local PS = {}

function PS.IsRestricted()
	return not X.IsDebugging('Dev_Snaplines')
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 300, h = 25,
		text = _L['enable tree path view'],
		checked = O.bEnable or false,
		onCheck = function(bCheck)
			O.bEnable = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show tip'],
		checked = O.bShowTip or false,
		onCheck = function(bCheck)
			O.bShowTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nX = nX + 200

	ui:Append('Shadow', {
		x = nX, y = nY + 3, w = 20, h = 20,
		color = O.rgbTip or {255, 255, 255},
		onClick = function()
			local me = this
			X.UI.OpenColorPicker(function(r, g, b)
				X.UI(me):Color(r, g, b)
				O.rgbTip = {r, g, b}
				MYDev_Snaplines.ReloadUI()
			end)
		end
	})
	nX = nX + 40

	ui:Append('WndButton', {
		x = nX, y = nY, h = 25,
		text = _L['font'],
		onClick = function()
			X.UI.OpenFontPicker(function(f)
				O.nTipFont = f
				MYDev_Snaplines.ReloadUI()
			end)
		end
	})
	nX = nPaddingX
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show data'],
		checked = O.bShowData or false,
		onCheck = function(bCheck)
			O.bShowData = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show wnd tip'],
		checked = O.bShowWndTip or false,
		onCheck = function(bCheck)
			O.bShowWndTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show item tip'],
		checked = O.bShowItemTip or false,
		onCheck = function(bCheck)
			O.bShowItemTip = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show wnd snaplines'],
		checked = O.bShowWndSnaplines or false,
		onCheck = function(bCheck)
			O.bShowWndSnaplines = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nX = nX + 200

	ui:Append('Shadow', {
		x = nX, y = nY + 3, w = 20, h = 20,
		color = O.rgbWndSnaplines or {255, 255, 255},
		onClick = function()
			local me = this
			X.UI.OpenColorPicker(function(r, g, b)
				X.UI(me):Color(r, g, b)
				O.rgbWndSnaplines = {r, g, b}
				MYDev_Snaplines.ReloadUI()
			end)
		end
	})
	nX = nPaddingX
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['show item snaplines'],
		checked = O.bShowItemSnaplines or false,
		onCheck = function(bCheck)
			O.bShowItemSnaplines = bCheck
			MYDev_Snaplines.ReloadUI()
		end
	})
	nX = nX + 200

	ui:Append('Shadow', {
		x = nX, y = nY + 3, w = 20, h = 20,
		color = O.rgbItemSnaplines or {255, 255, 255},
		onClick = function()
			local me = this
			X.UI.OpenColorPicker(function(r, g, b)
				X.UI(me):Color(r, g, b)
				O.rgbItemSnaplines = {r, g, b}
				MYDev_Snaplines.ReloadUI()
			end)
		end
	})
	nX = nPaddingX
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['auto detect box'],
		checked = O.bDetectBox or false,
		onCheck = function(bCheck)
			O.bDetectBox = bCheck
		end
	})
	nY = nY + 40

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['auto scale'],
		checked = O.bAutoScale,
		onCheck = function(bCheck)
			O.bAutoScale = bCheck
		end
	})
	nY = nY + 40

	ui:Append('Text', {
		x = nW - 140, y = 20, w = 140, h = 25,
		color = {255, 255, 0},
		text = _L['>> set hotkey <<'],
		onClick = function() X.SetHotKey() end
	})
end

-- 注册面板
X.Panel.Register(_L['Development'], 'Dev_Snaplines', _L['Snaplines'], 'ui/Image/UICommon/PlugIn.UITex|1', PS)

-- 注册快捷键
X.RegisterHotKey('MY_Dev_Snaplines'         , _L['Snaplines']           , function() O.bEnable   = not O.bEnable   MYDev_Snaplines.ReloadUI() end, nil)
X.RegisterHotKey('MY_Dev_Snaplines_ShowTip' , _L['Snaplines - ShowTip'] , function() O.bShowTip  = not O.bShowTip  MYDev_Snaplines.ReloadUI() end, nil)
X.RegisterHotKey('MY_Dev_Snaplines_ShowData', _L['Snaplines - ShowData'], function() O.bShowData = not O.bShowData MYDev_Snaplines.ReloadUI() end, nil)
-- For Debug
if IsDebugClient and IsDebugClient() then
	X.RegisterInit('Dev_Snaplines_Hotkey', function()
		X.SetHotKey('MY_Dev_Snaplines', 121)
		X.SetHotKey('MY_Dev_Snaplines_ShowTip', 122)
		X.SetHotKey('MY_Dev_Snaplines_ShowData', 123)
	end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
