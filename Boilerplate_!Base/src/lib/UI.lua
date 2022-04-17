--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

UI.MOUSE_BUTTON = X.SetmetaReadonly({
	LEFT   = 1,
	MIDDLE = 0,
	RIGHT  = -1,
})
UI.TIP_POSITION = X.SetmetaReadonly({
	FOLLOW_MOUSE              = -1,
	CENTER                    = ALW.CENTER,
	LEFT_RIGHT                = ALW.LEFT_RIGHT,
	RIGHT_LEFT                = ALW.RIGHT_LEFT,
	TOP_BOTTOM                = ALW.TOP_BOTTOM,
	BOTTOM_TOP                = ALW.BOTTOM_TOP,
	RIGHT_LEFT_AND_BOTTOM_TOP = ALW.RIGHT_LEFT_AND_BOTTOM_TOP,
})
UI.TIP_HIDE_WAY = X.SetmetaReadonly({
	NO_HIDE      = 100,
	HIDE         = 101,
	ANIMATE_HIDE = 102,
})
UI.TRACKBAR_STYLE = X.SetmetaReadonly({
	SHOW_VALUE    = false,
	SHOW_PERCENT  = true,
})
UI.WND_SIDE = X.SetmetaReadonly({
	TOP           = 0,
	BOTTOM        = 1,
	LEFT          = 2,
	RIGHT         = 3,
	TOP_LEFT      = 4,
	TOP_RIGHT     = 5,
	BOTTOM_LEFT   = 6,
	BOTTOM_RIGHT  = 7,
	CENTER        = 8,
	LEFT_CENTER   = 9,
	RIGHT_CENTER  = 1,
	TOP_CENTER    = 1,
	BOTTOM_CENTER = 1,
})
UI.EDIT_TYPE = X.SetmetaReadonly({
	NUMBER = 0, -- 数字
	ASCII = 1, -- 英文
	WIDE_CHAR = 2, -- 中英文
})
UI.WND_CONTAINER_STYLE = _G.WND_CONTAINER_STYLE or X.SetmetaReadonly({
	CUSTOM = 0,
	LEFT_TOP = 1,
	LEFT_BOTTOM = 2,
	RIGHT_TOP = 3,
	RIGHT_BOTTOM = 4,
})
UI.LAYER_LIST = {'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2'}

local BUTTON_STYLE_CONFIG = {
	DEFAULT = {
		nWidth = 100,
		nHeight = 26,
		nMarginBottom = -3,
		nPaddingBottom = 3,
		szImage = 'ui/Image/UICommon/CommonPanel.UITex',
		nNormalGroup = 25,
		nMouseOverGroup = 26,
		nMouseDownGroup = 27,
		nDisableGroup = 28,
	},
	FLAT_RADIUS = {
		nWidth = 44,
		nHeight = 23,
		nMarginBottom = 0,
		nPaddingBottom = 0,
		szImage = X.PACKET_INFO.FRAMEWORK_ROOT .. 'img/UIComponents.UITex',
		nNormalGroup = 0,
		nMouseOverGroup = 1,
		nMouseDownGroup = 2,
		nDisableGroup = 3,
	},
	LINK = X.SetmetaReadonly({
		nWidth = 60,
		nHeight = 25,
		szImage = 'ui/Image/UICommon/CommonPanel.UITex',
		nNormalGroup = -1,
		nMouseOverGroup = -1,
		nMouseDownGroup = -1,
		nDisableGroup = -1,
		nNormalFont = 162,
		nMouseOverFont = 0,
		nMouseDownFont = 162,
		nDisableFont = 161,
	}),
	OPTION = {
		nWidth = 22,
		nHeight = 24,
		szImage = 'ui/Image/UICommon/CommonPanel2.UITex',
		nNormalGroup = 57,
		nMouseOverGroup = 58,
		nMouseDownGroup = 59,
		nDisableGroup = 56,
	},
}
local function GetButtonStyleName(raw)
	local szImage = wstring.lower(raw:GetAnimatePath())
	local nNormalGroup = raw:GetAnimateGroupNormal()
	local GetStyleName = X.Get(_G, {X.NSFormatString('{$NS}_Resource'), 'GetWndButtonStyleName'})
	if X.IsFunction(GetStyleName) then
		local eStyle = GetStyleName(szImage, nNormalGroup)
		if eStyle then
			return eStyle
		end
	end
	for e, p in pairs(BUTTON_STYLE_CONFIG) do
		if wstring.lower(X.NormalizePath(p.szImage)) == szImage and p.nNormalGroup == nNormalGroup then
			return e
		end
	end
end
local function GetButtonStyleConfig(eButtonStyle)
	local GetStyleConfig = X.Get(_G, {X.NSFormatString('{$NS}_Resource'), 'GetWndButtonStyleConfig'})
	return X.IsFunction(GetStyleConfig)
		and GetStyleConfig(eButtonStyle)
		or BUTTON_STYLE_CONFIG[eButtonStyle]
end

local EDIT_BOX_APPEARANCE_CONFIG = {
	DEFAULT = {},
	SEARCH_LEFT = {
		szIconImage = X.PACKET_INFO.FRAMEWORK_ROOT .. 'img/UIComponents.UITex',
		nIconImageFrame = 4,
		nIconWidth = 32,
		nIconHeight = 32,
		nIconAlpha = 180,
		szIconAlign = 'LEFT',
	},
	SEARCH_RIGHT = {
		szIconImage = X.PACKET_INFO.FRAMEWORK_ROOT .. 'img/UIComponents.UITex',
		nIconImageFrame = 4,
		nIconWidth = 32,
		nIconHeight = 32,
		nIconAlpha = 180,
		szIconAlign = 'RIGHT',
	},
}

-----------------------------------------------------------
-- my ui common functions
-----------------------------------------------------------
local function ApplyUIArguments(ui, arg)
	if ui and arg then
		-- properties
		if arg.x ~= nil or arg.y  ~= nil then ui:Pos              (arg.x, arg.y                                    ) end
		if arg.alpha              ~= nil then ui:Alpha            (arg.alpha                                       ) end
		if arg.font               ~= nil then ui:Font             (arg.font                                        ) end -- must before color
		if arg.fontScale          ~= nil then ui:FontScale        (arg.fontScale                                   ) end -- must before color
		if arg.color              ~= nil then ui:Color            (arg.color                                       ) end
		if arg.r or arg.g or arg.b       then ui:Color            (arg.r, arg.g, arg.b                             ) end
		if arg.multiline          ~= nil then ui:Multiline        (arg.multiline                                   ) end -- must before :Text()
		if arg.trackbarStyle      ~= nil then ui:TrackbarStyle    (arg.trackbarStyle                               ) end -- must before :Text()
		if arg.textFormatter      ~= nil then ui:Text             (arg.textFormatter                               ) end -- must before :Text()
		if arg.text               ~= nil then ui:Text             (arg.text                                        ) end
		if arg.placeholder        ~= nil then ui:Placeholder      (arg.placeholder                                 ) end
		if arg.oncomplete         ~= nil then ui:Complete         (arg.oncomplete                                  ) end
		if arg.navigate           ~= nil then ui:Navigate         (arg.navigate                                    ) end
		if arg.group              ~= nil then ui:Group            (arg.group                                       ) end
		if arg.tip                ~= nil then ui:Tip              (arg.tip                                         ) end
		if arg.rowTip             ~= nil then ui:RowTip           (arg.rowTip                                      ) end
		if arg.range              ~= nil then ui:Range            (unpack(arg.range)                               ) end
		if arg.value              ~= nil then ui:Value            (arg.value                                       ) end
		if arg.menu               ~= nil then ui:Menu             (arg.menu                                        ) end
		if arg.menuLClick         ~= nil then ui:MenuLClick       (arg.menuLClick                                  ) end
		if arg.menuRClick         ~= nil then ui:MenuRClick       (arg.menuRClick                                  ) end
		if arg.rowMenu            ~= nil then ui:RowMenu          (arg.rowMenu                                     ) end
		if arg.rowMenuLClick      ~= nil then ui:RowMenuLClick    (arg.rowMenuLClick                               ) end
		if arg.rowMenuRClick      ~= nil then ui:RowMenuRClick    (arg.rowMenuRClick                               ) end
		if arg.limit              ~= nil then ui:Limit            (arg.limit                                       ) end
		if arg.scroll             ~= nil then ui:Scroll           (arg.scroll                                      ) end
		if arg.handleStyle        ~= nil then ui:HandleStyle      (arg.handleStyle                                 ) end
		if arg.containerType      ~= nil then ui:ContainerType    (arg.containerType                               ) end
		if arg.buttonStyle        ~= nil then ui:ButtonStyle      (arg.buttonStyle                                 ) end -- must before :Size()
		if arg.editType           ~= nil then ui:EditType         (arg.editType                                    ) end
		if arg.appearance         ~= nil then ui:Appearance       (arg.appearance                                  ) end
		if arg.visible            ~= nil then ui:Visible          (arg.visible                                     ) end
		if arg.autoVisible        ~= nil then ui:Visible          (arg.autoVisible                                 ) end
		if arg.enable             ~= nil then ui:Enable           (arg.enable                                      ) end
		if arg.autoEnable         ~= nil then ui:Enable           (arg.autoEnable                                  ) end
		if arg.image              ~= nil then
			ui:Image(arg.image, arg.imageFrame, arg.imageOverFrame, arg.imageDownFrame, arg.imageDisableFrame)
		end
		if arg.icon               ~= nil then ui:Icon             (arg.icon                                        ) end
		if arg.name               ~= nil then ui:Name             (arg.name                                        ) end
		if arg.penetrable         ~= nil then ui:Penetrable       (arg.penetrable                                  ) end
		if arg.draggable          ~= nil then ui:Drag             (arg.draggable                                   ) end
		if arg.dragArea           ~= nil then ui:Drag             (unpack(arg.dragArea)                            ) end
		if arg.w ~= nil or arg.h ~= nil or arg.rw ~= nil or arg.rh ~= nil then        -- must after :Text() because w/h can be 'auto'
			ui:Size(arg.w, arg.h, arg.rw, arg.rh)
		end
		if arg.alignHorizontal or arg.alignVertical then -- must after :Size()
			ui:Align(arg.alignHorizontal, arg.alignVertical)
		end
		if arg.anchor             ~= nil then ui:Anchor           (arg.anchor                                      ) end -- must after :Size() :Pos()
		-- event handlers
		if arg.onScroll           ~= nil then ui:Scroll           (arg.onScroll                                    ) end
		if arg.onHover            ~= nil then ui:Hover            (arg.onHover                                     ) end
		if arg.onRowHover         ~= nil then ui:RowHover         (arg.onRowHover                                  ) end
		if arg.onFocus            ~= nil then ui:Focus            (arg.onFocus                                     ) end
		if arg.onBlur             ~= nil then ui:Blur             (arg.onBlur                                      ) end
		if arg.onClick            ~= nil then ui:Click            (arg.onClick                                     ) end
		if arg.onLClick           ~= nil then ui:LClick           (arg.onLClick                                    ) end
		if arg.onMClick           ~= nil then ui:MClick           (arg.onMClick                                    ) end
		if arg.onRClick           ~= nil then ui:RClick           (arg.onRClick                                    ) end
		if arg.onRowClick         ~= nil then ui:RowClick         (arg.onRowClick                                  ) end
		if arg.onRowLClick        ~= nil then ui:RowLClick        (arg.onRowLClick                                 ) end
		if arg.onRowMClick        ~= nil then ui:RowMClick        (arg.onRowMClick                                 ) end
		if arg.onRowRClick        ~= nil then ui:RowRClick        (arg.onRowRClick                                 ) end
		if arg.onColorPick        ~= nil then ui:ColorPick        (arg.onColorPick                                 ) end
		if arg.checked            ~= nil then ui:Check            (arg.checked                                     ) end
		if arg.onCheck            ~= nil then ui:Check            (arg.onCheck                                     ) end
		if arg.onChange           ~= nil then ui:Change           (arg.onChange                                    ) end
		if arg.onSpecialKeyDown   ~= nil then ui:OnSpecialKeyDown (arg.onSpecialKeyDown                            ) end
		if arg.onDragging or arg.onDrag  then ui:Drag             (arg.onDragging, arg.onDrag                      ) end
		if arg.customLayout              then ui:CustomLayout     (arg.customLayout                                ) end
		if arg.onCustomLayout            then ui:CustomLayout     (arg.onCustomLayout, arg.customLayoutPoint       ) end
		if arg.columns                   then ui:Columns          (arg.columns                                     ) end
		if arg.dataSource                then ui:DataSource       (arg.dataSource                                  ) end
		if arg.summary                   then ui:Summary          (arg.summary                                     ) end
		if arg.sort or arg.sortOrder     then ui:Sort             (arg.sort, arg.sortOrder                         ) end
		if arg.onSortChange              then ui:Sort             (arg.onSortChange                                ) end
		if arg.events             ~= nil then for _, v in ipairs(arg.events      ) do ui:Event       (unpack(v)) end end
		if arg.uiEvents           ~= nil then for _, v in ipairs(arg.uiEvents    ) do ui:UIEvent     (unpack(v)) end end
		if arg.listBox            ~= nil then for _, v in ipairs(arg.listBox     ) do ui:ListBox     (unpack(v)) end end
		if arg.autocomplete       ~= nil then for _, v in ipairs(arg.autocomplete) do ui:Autocomplete(unpack(v)) end end
		-- auto size
		if arg.autoSize                  then ui:AutoSize         ()                                                 end
		if arg.autoWidth                 then ui:AutoWidth        ()                                                 end
		if arg.autoHeight                then ui:AutoHeight       ()                                                 end
	end
	return ui
end
UI.ApplyUIArguments = ApplyUIArguments

local GetComponentProp, SetComponentProp -- 组件私有属性 仅本文件内使用
do local l_prop = setmetatable({}, { __mode = 'k' })
	function GetComponentProp(raw, ...)
		if not raw or not l_prop[raw] then
			return
		end
		local prop = l_prop[raw]
		local k = { ... }
		local kc = select('#', ...)
		for i = 1, kc - 1, 1 do
			if not prop[k[i]] then
				return
			end
			prop = prop[k[i]]
		end
		return prop[k[kc]]
	end

	function SetComponentProp(raw, ...)
		if not raw then
			return
		end
		if not l_prop[raw] then
			l_prop[raw] = {}
		end
		local prop = l_prop[raw]
		local ks = { ... } -- { k1, k2, ..., kn, v }
		local kc = select('#', ...) - 1
		local v = ks[kc + 1]
		for i = 1, kc - 1, 1 do
			if not prop[ks[i]] then
				prop[ks[i]] = {}
			end
			prop = prop[ks[i]]
		end
		prop[ks[kc]] = v
	end
end

local GetComponentType, SetComponentType -- 组件名字记录
do local l_type = setmetatable({}, { __mode = 'k' })
	function GetComponentType(raw)
		if not raw then
			return
		end
		return l_type[raw] or raw:GetType()
	end
	function SetComponentType(raw, type)
		if not raw then
			return
		end
		l_type[raw] = type
	end
end

-- 通过组件根节点和目标功能区类型，获取功能UI实例对象。
-- 如：获取“按钮盒”的“按钮”实例、“文本”实例。
local function GetComponentElement(raw, elementType)
	local element
	local componentType = GetComponentType(raw)
	local componentBaseType = raw:GetBaseType()
	if elementType == 'ITEM' then -- 获取 Item 类UI实例
		if componentBaseType ~= 'Wnd' then
			element = raw
		end
	elseif elementType == 'WND' then -- 获取 Wnd 类UI实例
		if componentBaseType == 'Wnd' then
			element = raw
		end
	elseif elementType == 'MAIN_WINDOW' then -- 获取用于主要 Wnd 类功能区、子元素容器UI实例
		if componentType == 'WndFrame' then
			element = raw:Lookup('Wnd_Total') or raw
		elseif componentType == 'WndButtonBox' then
			element = raw:Lookup('WndButton')
		elseif componentType == 'WndScrollWindowBox' then
			element = raw:Lookup('WndContainer_Scroll')
		elseif componentBaseType == 'Wnd' then
			element = raw
		end
	elseif elementType == 'MAIN_HANDLE' then -- 获取用于主要 Item 类功能区、子元素容器UI实例
		if componentType == 'WndScrollHandleBox' then
			element = raw:Lookup('', 'Handle_Padding/Handle_Scroll')
		elseif componentType == 'Handle' or componentType == 'CheckBox' or componentType == 'ColorBox' then
			element = raw
		elseif componentBaseType == 'Wnd' then
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			if wnd then
				element = wnd:Lookup('', '')
			end
		end
	elseif elementType == 'CHECKBOX' then -- 获取复选框UI实例
		if componentType == 'WndCheckBox' or componentType == 'WndRadioBox' or componentType == 'CheckBox' then
			element = raw
		end
	elseif elementType == 'COMBOBOX' then -- 获取下拉框UI实例
		if componentType == 'WndComboBox' or componentType == 'WndEditComboBox' or componentType == 'WndAutocomplete' then
			element = raw:Lookup('Btn_ComboBox')
		end
	elseif elementType == 'CONTAINER' then -- 获取子元素容器UI实例
		if componentType == 'WndScrollWindowBox' then
			element = raw:Lookup('WndContainer_Scroll')
		elseif componentType == 'WndContainer' then
			element = raw
		end
	elseif elementType == 'EDIT' then -- 获取输入框UI实例
		if componentType == 'WndEdit' then
			element = raw
		elseif componentType == 'WndEditBox' or componentType == 'WndEditComboBox' or componentType == 'WndAutocomplete' then
			element = raw:Lookup('WndEdit_Default')
		end
	elseif elementType == 'BUTTON' then -- 获取按钮UI实例
		if componentType == 'WndButtonBox' then
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			if wnd then
				element = wnd
			end
		elseif componentType == 'WndButton' then
			element = raw
		end
	elseif elementType == 'WEB' then -- 获取浏览器UI实例
		if componentType == 'WndWebPage'
		or componentType == 'WndWebCef' then
			element = raw
		end
	elseif elementType == 'WEBPAGE' then -- 获取IE浏览器UI实例
		if componentType == 'WndWebPage' then
			element = raw
		end
	elseif elementType == 'WEBCEF' then -- 获取Chrome浏览器UI实例
		if componentType == 'WndWebCef' then
			element = raw
		end
	elseif elementType == 'TRACKBAR' then -- 获取拖动条UI实例
		if componentType == 'WndTrackbar' then
			element = raw:Lookup('WndNewScrollBar_Default')
		end
	elseif elementType == 'TEXT' then -- 获取文本UI实例
		if componentType == 'WndScrollHandleBox' then
			element = raw:Lookup('', 'Handle_Padding/Handle_Scroll/Text_Default')
		elseif componentType == 'WndFrame' then
			element = raw:Lookup('', 'Text_Title') or raw:Lookup('', 'Text_Default')
		elseif componentType == 'Handle' or componentType == 'CheckBox' or componentType == 'ColorBox' then
			element = raw:Lookup('Text_Default')
		elseif componentType == 'Text' then
			element = raw
		elseif componentBaseType == 'Wnd' then
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			if wnd then
				element = wnd:Lookup('', 'Text_Default')
			end
		end
	elseif elementType == 'PLACEHOLDER' then -- 获取占位文本UI实例
		if componentType == 'Handle' or componentType == 'CheckBox' or componentType == 'ColorBox' then
			element = raw:Lookup('Text_Placeholder')
		elseif componentBaseType == 'Wnd' then
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			if wnd then
				element = wnd:Lookup('', 'Text_Placeholder')
			end
		end
	elseif elementType == 'IMAGE' then -- 获取图片UI实例
		if componentType == 'WndEditBox' or componentType == 'WndComboBox' or componentType == 'WndEditComboBox'
		or componentType == 'WndAutocomplete' or componentType == 'WndScrollHandleBox' or componentType == 'WndScrollWindowBox' then
			element = raw:Lookup('', 'Image_Default')
		elseif componentType == 'Handle' or componentType == 'CheckBox' then
			element = raw:Lookup('Image_Default')
		elseif componentType == 'Image' then
			element = raw
		end
	elseif elementType == 'SHADOW' then -- 获取阴影UI实例
		if componentType == 'ColorBox' then
			element = raw:Lookup('Shadow_Default')
		end
		if componentType == 'Shadow' then
			element = raw
		end
	elseif elementType == 'BOX' then -- 获取游戏盒子UI实例
		if componentType == 'Box' then
			element = raw
		end
	elseif elementType == 'INNER_RAW' then -- 获取可设置内部大小的子组件
		if componentType == 'WndFrame' then
			element = GetComponentElement(raw, 'MAIN_WINDOW')
		elseif componentType == 'WndTrackbar' then
			element = raw:Lookup('WndNewScrollBar_Default')
		elseif componentType == 'CheckBox' then
			element = raw:Lookup('Image_Default')
		elseif componentType == 'ColorBox' then
			element = raw:Lookup('Shadow_Default')
		elseif componentType == 'WndScrollHandleBox' then
			element = GetComponentElement(raw, 'MAIN_HANDLE')
		elseif componentType == 'WndScrollWindowBox' then
			element = GetComponentElement(raw, 'CONTAINER')
		end
	end
	return element
end

local function InitComponent(raw, szType)
	SetComponentType(raw, szType)
	if szType == 'WndTrackbar' then
		local scroll = raw:Lookup('WndNewScrollBar_Default')
		SetComponentProp(raw, 'bShowPercentage', true)
		SetComponentProp(raw, 'nTrackbarMin', 0)
		SetComponentProp(raw, 'nTrackbarMax', 100)
		SetComponentProp(raw, 'nTrackbarStepVal', 1)
		SetComponentProp(raw, 'onChangeEvents', {})
		SetComponentProp(raw, 'FormatText', function(value, bPercentage)
			if bPercentage then
				return string.format('%.2f%%', value)
			else
				return value
			end
		end)
		SetComponentProp(raw, 'ResponseUpdateScroll', function(bOnlyUI)
			local _this = this
			this = raw
			local nScrollPos = scroll:GetScrollPos()
			local nStepCount = scroll:GetStepCount()
			local nMin = GetComponentProp(raw, 'nTrackbarMin')
			local nStepVal = GetComponentProp(raw, 'nTrackbarStepVal')
			local nCurrentValue = nScrollPos * nStepVal + nMin
			local bShowPercentage = GetComponentProp(raw, 'bShowPercentage')
			if bShowPercentage then
				local nMax = GetComponentProp(raw, 'nTrackbarMax')
				nCurrentValue = math.floor((nCurrentValue * 100 / nMax) * 100) / 100
			end
			local szText = GetComponentProp(raw, 'FormatText')(nCurrentValue, bShowPercentage)
			raw:Lookup('', 'Text_Default'):SetText(szText)
			if not bOnlyUI then
				for _, fn in ipairs(GetComponentProp(raw, 'onChangeEvents')) do
					X.ExecuteWithThis(raw, fn, nCurrentValue)
				end
			end
			this = _this
		end)
		scroll.OnScrollBarPosChanged = function()
			GetComponentProp(raw, 'ResponseUpdateScroll')()
		end
		scroll.OnMouseWheel = function()
			scroll:ScrollNext(-Station.GetMessageWheelDelta() * 2)
			return 1
		end
		scroll:Lookup('Btn_Track').OnMouseWheel = function()
			scroll:ScrollNext(-Station.GetMessageWheelDelta())
			return 1
		end
	elseif szType=='WndEditBox' then
		local edt = raw:Lookup('WndEdit_Default')
		edt.OnEditSpecialKeyDown = function()
			local nMessageKey = Station.GetMessageKey()
			local szKey = GetKeyName(nMessageKey)
			local OnSpecialKeyDown = GetComponentProp(raw, 'OnSpecialKeyDown')
			if X.IsFunction(OnSpecialKeyDown) then
				return OnSpecialKeyDown(nMessageKey, szKey)
			end
			if szKey == 'Esc'
			or (szKey == 'Enter' and not edt:IsMultiLine()) then
				Station.SetFocusWindow(edt:GetRoot())
				return 1
			end
		end
	elseif szType=='WndAutocomplete' then
		local edt = raw:Lookup('WndEdit_Default')
		edt.OnSetFocus = function()
			local opt = GetComponentProp(raw, 'autocompleteOptions')
			if opt.disabled or opt.disabledTmp then
				return
			end
			UI(raw):Autocomplete('search')
		end
		edt.OnEditChanged = function()
			local opt = GetComponentProp(raw, 'autocompleteOptions')
			if opt.disabled or opt.disabledTmp or Station.GetFocusWindow() ~= this then
				return
			end
			-- placeholder
			local len = this:GetText():len()
			-- min search length
			if len >= opt.minLength then
				-- delay search
				X.DelayCall(opt.delay, function()
					UI(raw):Autocomplete('search')
					-- for compatible
					Station.SetFocusWindow(edt)
				end)
			else
				UI(raw):Autocomplete('close')
			end
		end
		edt.OnKillFocus = function()
			X.DelayCall(function()
				local wnd = Station.GetFocusWindow()
				local frame = wnd and wnd:GetRoot()
				if not frame or frame:GetName() ~= X.NSFormatString('{$NS}_PopupMenu') then
					UI.ClosePopupMenu()
				end
			end)
		end
		edt.OnEditSpecialKeyDown = function() -- TODO: {$NS}_PopupMenu 适配
			local nMessageKey = Station.GetMessageKey()
			local szKey = GetKeyName(nMessageKey)
			if IsPopupMenuOpened() and PopupMenu_ProcessHotkey then
				if szKey == 'Enter'
				or szKey == 'Up'
				or szKey == 'Down'
				or szKey == 'Left'
				or szKey == 'Right' then
					return PopupMenu_ProcessHotkey(szKey)
				end
			else
				local OnSpecialKeyDown = GetComponentProp(raw, 'OnSpecialKeyDown')
				if X.IsFunction(OnSpecialKeyDown) then
					return OnSpecialKeyDown(nMessageKey, szKey)
				end
				if szKey == 'Esc'
				or (szKey == 'Enter' and not edt:IsMultiLine()) then
					Station.SetFocusWindow(edt:GetRoot())
					return 1
				end
			end
		end
		SetComponentProp(raw, 'autocompleteOptions', {
			beforeSearch = nil  , -- @param: text
			beforePopup  = nil  , -- @param: menu
			beforeDelete = nil  , -- @param: szOption
			afterDelete  = nil  , -- @param: szOption

			ignoreCase   = true ,  -- ignore case while matching
			anyMatch     = true ,  -- match any part of option list
			autoFill     = false,  -- auto fill edit with first match (conflict withanyMatch)
			delay        = 0    ,  -- delay time when edit changed
			disabled     = false,  -- disable autocomplete
			minLength    = 0    ,  -- the min length of the searching string
			maxOption    = 0    ,  -- the max number of displayed options (0 means no limitation)
			source       = {}   ,  -- option list
		})
	elseif szType == 'WndRadioBox' then
		UI(raw):UIEvent('OnLButtonUp', function()
			if not this:IsEnabled() then
				return
			end
			local group = GetComponentProp(raw, 'group')
			local p = raw:GetParent():GetFirstChild()
			while p do
				if p ~= raw and GetComponentType(p) == 'WndRadioBox' then
					local g = GetComponentProp(p, 'group')
					if g and g == group and p:IsCheckBoxChecked() then
						p:Check(false)
					end
				end
				p = p:GetNext()
			end
		end)
	elseif szType == 'WndListBox' then
		local scroll = raw:Lookup('', 'Handle_Scroll')
		SetComponentProp(raw, 'OnListItemHandleMouseEnter', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onHoverIn = GetComponentProp(raw, 'OnListItemHandleCustomHoverIn')
			if onHoverIn then
				local bStatus, bRet = X.CallWithThis(raw, onHoverIn, data.id, data.text, data.data, not data.selected)
				if bStatus and bRet == false then
					return
				end
			end
			UI(this:Lookup('Image_Bg')):FadeIn(100)
		end)
		SetComponentProp(raw, 'OnListItemHandleMouseLeave', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onHoverOut = GetComponentProp(raw, 'OnListItemHandleCustomHoverOut')
			if onHoverOut then
				local bStatus, bRet = X.CallWithThis(raw, onHoverOut, data.id, data.text, data.data, not data.selected)
				if bStatus and bRet == false then
					return
				end
			end
			UI(this:Lookup('Image_Bg')):FadeTo(500,0)
		end)
		SetComponentProp(raw, 'OnListItemHandleLButtonClick', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onItemLClick = GetComponentProp(raw, 'OnListItemHandleCustomLButtonClick')
			if onItemLClick then
				local bStatus, bRet = X.CallWithThis(raw, onItemLClick, data.id, data.text, data.data, not data.selected)
				if bStatus and bRet == false then
					return
				end
			end
			local opt = GetComponentProp(raw, 'listboxOptions')
			if not data.selected then
				if not opt.multiSelect then
					for i = scroll:GetItemCount() - 1, 0, -1 do
						local hItem = scroll:Lookup(i)
						local data = GetComponentProp(hItem, 'listboxItemData')
						if data.selected then
							hItem:Lookup('Image_Sel'):Hide()
							data.selected = false
						end
					end
				end
				this:Lookup('Image_Sel'):Show()
			else
				this:Lookup('Image_Sel'):Hide()
			end
			data.selected = not data.selected
		end)
		SetComponentProp(raw, 'OnListItemHandleRButtonClick', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onItemRClick = GetComponentProp(raw, 'OnListItemHandleCustomRButtonClick')
			if onItemRClick then
				local bStatus, bRet = X.CallWithThis(raw, onItemRClick, data.id, data.text, data.data, not data.selected)
				if bStatus and bRet == false then
					return
				end
			end
			if not data.selected then
				local opt = GetComponentProp(raw, 'listboxOptions')
				if not opt.multiSelect then
					for i = scroll:GetItemCount() - 1, 0, -1 do
						local hItem = scroll:Lookup(i)
						local data = GetComponentProp(hItem, 'listboxItemData')
						if data.selected then
							hItem:Lookup('Image_Sel'):Hide()
							data.selected = false
						end
					end
				end
				data.selected = true
				this:Lookup('Image_Sel'):Show()
			end
			local GetMenu = GetComponentProp(raw, 'GetListItemHandleMenu')
			if GetMenu then
				local status, menu = X.CallWithThis(raw, GetMenu, data.id, data.text, data.data, data.selected)
				if status and menu then
					UI.PopupMenu(menu)
				end
			end
		end)
		SetComponentProp(raw, 'listboxOptions', { multiSelect = false })
	elseif szType == 'WndTable' then
		-- 初始化变量
		SetComponentProp(raw, 'ScrollX', 'auto')
		SetComponentProp(raw, 'SortOrder', 'asc')
		SetComponentProp(raw, 'aFixedLColumns', {})
		SetComponentProp(raw, 'aFixedRColumns', {})
		SetComponentProp(raw, 'aScrollableColumns', {})
		SetComponentProp(raw, 'nFixedLColumnsWidth', 0)
		SetComponentProp(raw, 'nFixedRColumnsWidth', 0)
		SetComponentProp(raw, 'DataSource', {})
		-- 更新大小
		SetComponentProp(raw, 'UpdateTableRect', function()
			local nRawWidth, nRawHeight = raw:GetSize()
			local hTotal = raw:Lookup('', '')
			local nFixedLWidth = GetComponentProp(raw, 'nFixedLColumnsWidth')
			local nFixedRWidth = GetComponentProp(raw, 'nFixedRColumnsWidth')
			hTotal:SetSize(nRawWidth, nRawHeight)
			hTotal:Lookup('Image_Table_Border'):SetRelPos(-1, -1)
			hTotal:Lookup('Image_Table_Border'):SetSize(nRawWidth + 2, nRawHeight + 2)
			hTotal:Lookup('Image_Table_Background'):SetSize(nRawWidth - 4, nRawHeight - 30)
			hTotal:Lookup('Image_Table_TitleHr'):SetW(nRawWidth - 6)
			-- 左侧固定列
			hTotal:Lookup('Handle_Fixed_L_TableColumns'):SetSize(nFixedLWidth, nRawHeight)
			hTotal:Lookup('Handle_Fixed_L_Scroll_Y_Wrapper'):SetW(nFixedLWidth)
			hTotal:Lookup('Handle_Fixed_L_Scroll_Y_Wrapper'):SetH(nRawHeight - 60)
			hTotal:Lookup('Handle_Fixed_L_Summary'):SetRelX(nFixedLWidth)
			hTotal:Lookup('Handle_Fixed_L_Summary'):SetRelY(nRawHeight - 30)
			-- 右侧固定列
			hTotal:Lookup('Handle_Fixed_R_TableColumns'):SetSize(nFixedRWidth, nRawHeight)
			hTotal:Lookup('Handle_Fixed_R_TableColumns'):SetRelX(nRawWidth - nFixedRWidth)
			hTotal:Lookup('Handle_Fixed_R_Scroll_Y_Wrapper'):SetW(nFixedRWidth)
			hTotal:Lookup('Handle_Fixed_R_Scroll_Y_Wrapper'):SetRelX(nRawWidth - nFixedRWidth)
			hTotal:Lookup('Handle_Fixed_R_Scroll_Y_Wrapper'):SetH(nRawHeight - 60)
			hTotal:Lookup('Handle_Fixed_R_Summary'):SetRelX(nRawWidth - nFixedRWidth)
			hTotal:Lookup('Handle_Fixed_R_Summary'):SetRelY(nRawHeight - 30)
			-- 水平滚动列
			hTotal:Lookup('Handle_Scroll_X_Wrapper'):SetRelX(nFixedLWidth)
			hTotal:Lookup('Handle_Scroll_X_Wrapper'):SetSize(nRawWidth - nFixedLWidth - nFixedRWidth, nRawHeight)
			hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X'):SetH(nRawHeight)
			hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper'):SetH(nRawHeight - 60)
			hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary'):SetRelY(nRawHeight - 30)
			hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X'):FormatAllItemPos()
			hTotal:FormatAllItemPos()
			raw:Lookup('Scroll_X'):SetW(nRawWidth)
			raw:Lookup('Scroll_X'):SetRelY(nRawHeight - 10)
			raw:Lookup('Scroll_X/Btn_Scroll_X'):SetW(math.min(200, math.max(100, nRawWidth / 3)))
			raw:Lookup('Scroll_Y'):SetH(nRawHeight - 32)
			raw:Lookup('Scroll_Y'):SetRelX(nRawWidth - 12)
			raw:Lookup('Scroll_Y/Btn_Scroll_Y'):SetH(math.min(80, math.max(40, (nRawHeight - 10) / 3)))
			GetComponentProp(raw, 'UpdateSummaryVisible')()
			GetComponentProp(raw, 'UpdateTitleColumnsRect')()
			GetComponentProp(raw, 'UpdateContentColumnsWidth')()
			GetComponentProp(raw, 'UpdateSummaryColumnsWidth')()
			GetComponentProp(raw, 'UpdateScrollY')()
		end)
		-- 更新表格水平滚动条
		SetComponentProp(raw, 'UpdateScrollX', function()
			local hWrapper = raw:Lookup('', 'Handle_Scroll_X_Wrapper')
			local hScroll = hWrapper:Lookup('Handle_Scroll_X')
			local nStepCount = hScroll:GetW() - hWrapper:GetW()
			if nStepCount > 0 then
				raw:Lookup('Scroll_X'):Show()
				raw:Lookup('Scroll_X'):SetStepCount(nStepCount)
			else
				raw:Lookup('Scroll_X'):Hide()
			end
		end)
		-- 更新表格垂直滚动条
		SetComponentProp(raw, 'UpdateScrollY', function()
			-- 固定列与滚动列之间垂直方向应该是同步的，区滚动列的滚动高度即可
			local hWrapper = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper')
			local hScrollableContents = hWrapper:Lookup('Handle_Scroll_Y')
			local nStepCount = hScrollableContents:GetH() - hWrapper:GetH()
			if nStepCount > 0 then
				raw:Lookup('Scroll_Y'):Show()
				raw:Lookup('Scroll_Y'):SetStepCount(nStepCount)
			else
				raw:Lookup('Scroll_Y'):Hide()
			end
		end)
		-- 自适应表头宽高
		SetComponentProp(raw, 'UpdateTitleColumnsRect', function()
			local function UpdateTitleColumnRect(hCol, col, nWidth, nHeight)
				local hContentWrapper = hCol:Lookup('Handle_TableColumn_Content_Wrapper') -- 外部居中层
				local hContent = hContentWrapper:Lookup('Handle_TableColumn_Content') -- 内部文本布局层
				local imgAsc = hCol:Lookup('Image_TableColumn_Asc')
				local imgDesc = hCol:Lookup('Image_TableColumn_Desc')
				local imgBreak = hCol:Lookup('Image_TableColumn_Break')
				local nSortDelta = nWidth > 70 and 25 or 15
				hCol:SetW(nWidth)
				hContentWrapper:SetW(nWidth)
				hContent:SetW(99999)
				hContent:FormatAllItemPos()
				hContent:SetSizeByAllItemSize()
				if col.alignVertical == 'top' then
					hContent:SetRelY(0)
				elseif col.alignVertical == 'middle' or col.alignVertical == nil then
					hContent:SetRelY((hContentWrapper:GetH() - hContent:GetH()) / 2)
				elseif col.alignVertical == 'bottom' then
					hContent:SetRelY(hContentWrapper:GetH() - hContent:GetH())
				end
				if col.alignHorizontal == 'left' or col.alignHorizontal == nil then
					hContent:SetRelX(5)
				elseif col.alignHorizontal == 'center' then
					hContent:SetRelX((nWidth - hContent:GetW()) / 2)
				elseif col.alignHorizontal == 'right' then
					hContent:SetRelX(nWidth - hContent:GetW() - 5)
				end
				imgAsc:SetRelX(nWidth - nSortDelta)
				imgDesc:SetRelX(nWidth - nSortDelta)
				imgBreak:SetRelY(2)
				imgBreak:SetH(nHeight - 3)
				hContentWrapper:FormatAllItemPos()
				hCol:FormatAllItemPos()
			end
			local nRawWidth, nRawHeight = raw:GetSize()
			-- 左侧固定列
			local nX = 0
			local nFixedLWidth = GetComponentProp(raw, 'nFixedLColumnsWidth')
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			local hFixedLColumns = raw:Lookup('', 'Handle_Fixed_L_TableColumns')
			for i, col in ipairs(aFixedLColumns) do
				local hCol = hFixedLColumns:Lookup(i - 1)
				local nWidth = col.width
				hCol:SetRelX(nX)
				nX = nX + nWidth
				hCol:Lookup('Image_TableColumn_Break'):SetRelX(nWidth - 3)
				hCol:Lookup('Image_TableColumn_Break'):Show()
				UpdateTitleColumnRect(hCol, col, nWidth, nRawHeight)
			end
			hFixedLColumns:SetW(nFixedLWidth)
			hFixedLColumns:FormatAllItemPos()
			raw:Lookup('', 'Handle_Fixed_L_Summary'):SetW(nFixedLWidth)
			raw:Lookup('', 'Handle_Fixed_L_Scroll_Y_Wrapper'):SetW(nFixedLWidth)
			-- 右侧固定列
			local nX = 0
			local nFixedRWidth = GetComponentProp(raw, 'nFixedRColumnsWidth')
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			local hFixedRColumns = raw:Lookup('', 'Handle_Fixed_R_TableColumns')
			for i, col in ipairs(aFixedRColumns) do
				local hCol = hFixedRColumns:Lookup(i - 1)
				local nWidth = col.width
				hCol:SetRelX(nX)
				nX = nX + nWidth
				UpdateTitleColumnRect(hCol, col, nWidth, nRawHeight)
			end
			hFixedRColumns:SetRelX(nRawWidth - nFixedRWidth)
			hFixedRColumns:SetW(nFixedRWidth)
			hFixedRColumns:FormatAllItemPos()
			raw:Lookup('', 'Handle_Fixed_R_Summary'):SetRelX(nRawWidth - nFixedRWidth)
			raw:Lookup('', 'Handle_Fixed_R_Summary'):SetW(nFixedRWidth)
			raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper'):SetRelX(nRawWidth - nFixedRWidth)
			raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper'):SetW(nFixedRWidth)
			-- 水平滚动列
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			local hScrollableColumns = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_TableColumns')
			local nX = 0
			local nScrollX = GetComponentProp(raw, 'ScrollX')
			if not nScrollX or nScrollX == 'auto' then
				nScrollX = raw:GetW()
			end
			local nExtraWidth = nScrollX
			for i, col in ipairs(aScrollableColumns) do
				if col.minWidth then
					nExtraWidth = nExtraWidth - col.minWidth
				end
			end
			if nExtraWidth < 0 then
				nScrollX = nScrollX - nExtraWidth
				nExtraWidth = 0
			end
			for i, col in ipairs(aScrollableColumns) do
				local hCol = hScrollableColumns:Lookup(i - 1) -- 外部居中层
				local nMinWidth = col.minWidth or 0
				local nWidth = i == #aScrollableColumns
					and (nScrollX - nX)
					or math.min(nExtraWidth * nMinWidth / (nScrollX - nExtraWidth) + nMinWidth, col.maxWidth or math.huge)
				if i == 1 then
					hCol:Lookup('Image_TableColumn_Break'):Hide()
				end
				UpdateTitleColumnRect(hCol, col, nWidth, nRawHeight)
				hCol:SetRelX(nX)
				nX = nX + nWidth
			end
			hScrollableColumns:SetW(nX)
			hScrollableColumns:FormatAllItemPos()
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X'):SetW(nX)
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper'):SetW(nX)
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y'):SetW(nX)
			raw:Lookup('', 'Handle_Scroll_X_Wrapper'):SetRelX(nFixedLWidth)
			raw:Lookup('', 'Handle_Scroll_X_Wrapper'):SetSize(nRawWidth - nFixedLWidth - nFixedRWidth, nRawHeight)
			raw:Lookup('', ''):FormatAllItemPos()
			-- 汇总水平滚动区
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary'):SetW(nX)
			-- 更新水平滚动条
			GetComponentProp(raw, 'UpdateScrollX')()
		end)
		-- 更新排序函数与表头排序状态显示
		SetComponentProp(raw, 'UpdateSorterStatus', function()
			local szSortKey = GetComponentProp(raw, 'SortKey')
			local szSortOrder = GetComponentProp(raw, 'SortOrder')
			local function UpdateSortStatus(hCol, col)
				local imgAsc = hCol:Lookup('Image_TableColumn_Asc')
				local imgDesc = hCol:Lookup('Image_TableColumn_Desc')
				if szSortKey == col.key and col.sorter then
					local sorter = col.sorter
					if sorter == true then
						sorter = function(a, b)
							if a == b then
								return 0
							end
							return a > b and 1 or -1
						end
					end
					SetComponentProp(raw, 'Sorter', function(r1, r2)
						local v1, v2 = r1[col.key], r2[col.key]
						if szSortOrder == 'asc' then
							return sorter(v1, v2, r1, r2) < 0
						end
						return sorter(v1, v2, r1, r2) > 0
					end)
				end
				imgAsc:SetVisible(szSortKey == col.key and szSortOrder == 'asc')
				imgDesc:SetVisible(szSortKey == col.key and szSortOrder == 'desc')
			end
			SetComponentProp(raw, 'Sorter', nil)
			-- 左侧固定列
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			local hFixedLColumns = raw:Lookup('', 'Handle_Fixed_L_TableColumns')
			for i, col in ipairs(aFixedLColumns) do
				local hCol = hFixedLColumns:Lookup(i - 1)
				UpdateSortStatus(hCol, col)
			end
			-- 右侧固定列
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			local hFixedRColumns = raw:Lookup('', 'Handle_Fixed_R_TableColumns')
			for i, col in ipairs(aFixedRColumns) do
				local hCol = hFixedRColumns:Lookup(i - 1)
				UpdateSortStatus(hCol, col)
			end
			-- 水平滚动列
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			local hScrollableColumns = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_TableColumns')
			for i, col in ipairs(aScrollableColumns) do
				local hCol = hScrollableColumns:Lookup(i - 1)
				UpdateSortStatus(hCol, col)
			end
		end)
		-- 绘制表头内容
		SetComponentProp(raw, 'DrawColumnsTitle', function()
			local function DrawColumnTitle(hColumns, aColumns)
				hColumns:Clear()
				for i, col in ipairs(aColumns) do
					local hCol = hColumns:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndTable.ini', 'Handle_TableColumn')
					local hContentWrapper = hCol:Lookup('Handle_TableColumn_Content_Wrapper') -- 外部居中层
					local hContent = hContentWrapper:Lookup('Handle_TableColumn_Content') -- 内部文本布局层
					if i == 0 then
						hCol:Lookup('Image_TableColumn_Break'):Hide()
					end
					-- 标题
					local szTitle, bTitleRich = col.title, col.titleRich
					if X.IsFunction(col.title) then
						szTitle, bTitleRich = col.title(col)
					end
					if not bTitleRich then
						szTitle = GetFormatText(szTitle)
					end
					hContent:AppendItemFromString(szTitle)
					-- 标题 Tip
					if col.titleTip then
						hCol.OnItemMouseEnter = function()
							local szText, bRich = col.titleTip, col.titleTipRich
							if X.IsFunction(col.titleTip) then
								szText, bRich = col.titleTip(col)
							end
							if X.IsEmpty(szText) then
								return
							end
							if not bRich then
								szText = GetFormatText(szText, 162, 255, 255, 255)
							end
							local nX, nY = this:GetAbsPos()
							local nW, nH = this:GetSize()
							nX = math.max(nX, raw:GetAbsX())
							OutputTip(szText, 400, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
						end
						hCol.OnItemMouseLeave = function()
							HideTip()
						end
					end
					-- 排序
					hCol.OnItemLButtonClick = function()
						if not col.sorter then
							return
						end
						if GetComponentProp(raw, 'SortKey') == col.key then
							SetComponentProp(raw, 'SortOrder', GetComponentProp(raw, 'SortOrder') == 'asc' and 'desc' or 'asc')
						else
							SetComponentProp(raw, 'SortKey', col.key)
						end
						X.SafeCall(GetComponentProp(raw, 'OnSortChange'))
						GetComponentProp(raw, 'UpdateSorterStatus')()
						GetComponentProp(raw, 'DrawTableContent')()
					end
				end
			end
			-- 左侧固定列
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			local hFixedLColumns = raw:Lookup('', 'Handle_Fixed_L_TableColumns')
			DrawColumnTitle(hFixedLColumns, aFixedLColumns)
			-- 右侧固定列
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			local hFixedRColumns = raw:Lookup('', 'Handle_Fixed_R_TableColumns')
			DrawColumnTitle(hFixedRColumns, aFixedRColumns)
			-- 水平滚动列
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			local hScrollableColumns = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_TableColumns')
			DrawColumnTitle(hScrollableColumns, aScrollableColumns)
			-- 重新计算列宽高、排序状态
			GetComponentProp(raw, 'UpdateTitleColumnsRect')()
			GetComponentProp(raw, 'UpdateSorterStatus')()
		end)
		-- 更新数据行各列宽度（跟随表头）
		SetComponentProp(raw, 'UpdateContentColumnsWidth', function()
			local function UpdateContentColumnsWidth(hContents, hTitleColumns, aColumns)
				for nRowIndex = 0, hContents:GetItemCount() - 1 do
					local hRow = hContents:Lookup(nRowIndex)
					local hRowColumns = hRow:Lookup('Handle_RowColumns')
					local nX = 0
					for nColumnIndex, col in ipairs(aColumns) do
						local nWidth = hTitleColumns:Lookup(nColumnIndex - 1):GetW()
						local hItem = hRowColumns:Lookup(nColumnIndex - 1) -- 外部居中层
						local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
						hItemContent:SetW(99999)
						hItemContent:FormatAllItemPos()
						hItemContent:SetSizeByAllItemSize()
						hItem:SetRelX(nX)
						hItem:SetW(nWidth)
						if col.alignVertical == 'top' then
							hItemContent:SetRelY(0)
						elseif col.alignVertical == 'middle' or col.alignVertical == nil then
							hItemContent:SetRelY((hItem:GetH() - hItemContent:GetH()) / 2)
						elseif col.alignVertical == 'bottom' then
							hItemContent:SetRelY(hItem:GetH() - hItemContent:GetH())
						end
						if col.alignHorizontal == 'left' or col.alignHorizontal == nil then
							hItemContent:SetRelX(5)
						elseif col.alignHorizontal == 'center' then
							hItemContent:SetRelX((nWidth - hItemContent:GetW()) / 2)
						elseif col.alignHorizontal == 'right' then
							hItemContent:SetRelX(nWidth - hItemContent:GetW() - 5)
						end
						hItem:FormatAllItemPos()
						nX = nX + nWidth
					end
					hRowColumns:SetW(nX)
					hRowColumns:FormatAllItemPos()
					hRow:SetW(nX)
					hRow:Lookup('Image_RowBg'):SetW(nX)
					hRow:Lookup('Image_RowHover'):SetW(nX)
					hRow:Lookup('Image_RowSpliter'):SetW(nX)
					hRow:FormatAllItemPos()
				end
				hContents:SetW(hTitleColumns:GetW())
				hContents:FormatAllItemPos()
			end
			-- 左侧固定列
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			local hFixedLContents = raw:Lookup('', 'Handle_Fixed_L_Scroll_Y_Wrapper/Handle_Fixed_L_Scroll_Y')
			local hFixedLColumns = raw:Lookup('', 'Handle_Fixed_L_TableColumns')
			UpdateContentColumnsWidth(hFixedLContents, hFixedLColumns, aFixedLColumns)
			-- 右侧固定列
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			local hFixedRContents = raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper/Handle_Fixed_R_Scroll_Y')
			local hFixedRColumns = raw:Lookup('', 'Handle_Fixed_R_TableColumns')
			UpdateContentColumnsWidth(hFixedRContents, hFixedRColumns, aFixedRColumns)
			-- 水平滚动列
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			local hScrollableContents = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y')
			local hScrollableColumns = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_TableColumns')
			UpdateContentColumnsWidth(hScrollableContents, hScrollableColumns, aScrollableColumns)
		end)
		-- 绘制数据行
		SetComponentProp(raw, 'DrawTableContent', function()
			local function DrawContent(hContents, aColumns, aDataSource)
				hContents:Clear()
				for nRowIndex, rec in ipairs(aDataSource) do
					local hRow = hContents:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndTable.ini', 'Handle_Row')
					local hRowColumns = hRow:Lookup('Handle_RowColumns')
					hRowColumns:Clear()
					hRow:Lookup('Image_RowBg'):SetVisible(nRowIndex % 2 == 1)
					for nColumnIndex, col in ipairs(aColumns) do
						local hItem = hRowColumns:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndTable.ini', 'Handle_Item') -- 外部居中层
						local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
						local szXml
						if col.render then
							szXml = col.render(rec[col.key], rec, nRowIndex)
						else
							szXml = GetFormatText(rec[col.key])
						end
						hItemContent:AppendItemFromString(szXml)
					end
					hRow.OnItemMouseEnter = function()
						local nX, nY = raw:GetAbsX(), this:GetAbsY()
						local nW, nH = raw:GetW(), this:GetH()
						X.SafeCall(GetComponentProp(raw, 'OnRowHover'), true, rec, nRowIndex, { nX, nY, nW, nH })
					end
					hRow.OnItemMouseLeave = function()
						local nX, nY = raw:GetAbsX(), this:GetAbsY()
						local nW, nH = raw:GetW(), this:GetH()
						X.SafeCall(GetComponentProp(raw, 'OnRowHover'), false, rec, nRowIndex, { nX, nY, nW, nH })
					end
					hRow.OnItemMouseIn = function()
						for _, szPath in ipairs({
							'Handle_Fixed_L_Scroll_Y_Wrapper/Handle_Fixed_L_Scroll_Y',
							'Handle_Fixed_R_Scroll_Y_Wrapper/Handle_Fixed_R_Scroll_Y',
							'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y',
						}) do
							local hL = raw:Lookup('', szPath)
							for i = 0, hL:GetItemCount() - 1 do
								hL:Lookup(i):Lookup('Image_RowHover'):SetVisible(i + 1 == nRowIndex)
							end
						end
					end
					hRow.OnItemMouseOut = function()
						for _, szPath in ipairs({
							'Handle_Fixed_L_Scroll_Y_Wrapper/Handle_Fixed_L_Scroll_Y',
							'Handle_Fixed_R_Scroll_Y_Wrapper/Handle_Fixed_R_Scroll_Y',
							'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y',
						}) do
							local hL = raw:Lookup('', szPath)
							for i = 0, hL:GetItemCount() - 1 do
								hL:Lookup(i):Lookup('Image_RowHover'):Hide()
							end
						end
					end
					hRow.OnItemLButtonClick = function()
						X.SafeCall(GetComponentProp(raw, 'RowLClick'), rec, nRowIndex)
					end
					hRow.OnItemMButtonClick = function()
						X.SafeCall(GetComponentProp(raw, 'RowMClick'), rec, nRowIndex)
					end
					hRow.OnItemRButtonClick = function()
						X.SafeCall(GetComponentProp(raw, 'RowRClick'), rec, nRowIndex)
					end
				end
			end
			local aDataSource = GetComponentProp(raw, 'DataSource')
			local Sorter = GetComponentProp(raw, 'Sorter')
			if Sorter then
				local ds = {}
				for _, v in ipairs(aDataSource) do
					table.insert(ds, v)
				end
				table.sort(ds, Sorter)
				aDataSource = ds
			end
			-- 左侧固定列
			local hFixedLContents = raw:Lookup('', 'Handle_Fixed_L_Scroll_Y_Wrapper/Handle_Fixed_L_Scroll_Y')
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			DrawContent(hFixedLContents, aFixedLColumns, aDataSource)
			-- 右侧固定列
			local hFixedRContents = raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper/Handle_Fixed_R_Scroll_Y')
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			DrawContent(hFixedRContents, aFixedRColumns, aDataSource)
			-- 水平滚动列
			local hScrollableContents = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y')
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			DrawContent(hScrollableContents, aScrollableColumns, aDataSource)
			-- 更新列宽、垂直滚动条
			GetComponentProp(raw, 'UpdateContentColumnsWidth')()
			GetComponentProp(raw, 'UpdateScrollY')()
		end)
		-- 更新汇总行
		SetComponentProp(raw, 'UpdateSummaryVisible', function()
			local nHeight = raw:GetH()
			local hTotal = raw:Lookup('', '')
			local summary = GetComponentProp(raw, 'Summary')
			if summary then
				hTotal:Lookup('Handle_Fixed_L_Scroll_Y_Wrapper'):SetH(nHeight - 60)
				hTotal:Lookup('Handle_Fixed_R_Scroll_Y_Wrapper'):SetH(nHeight - 60)
				hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper'):SetH(nHeight - 60)
				hTotal:Lookup('Handle_Fixed_L_Summary'):Show()
				hTotal:Lookup('Handle_Fixed_R_Summary'):Show()
				hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary'):Show()
			else
				hTotal:Lookup('Handle_Fixed_L_Scroll_Y_Wrapper'):SetH(nHeight - 30)
				hTotal:Lookup('Handle_Fixed_R_Scroll_Y_Wrapper'):SetH(nHeight - 30)
				hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper'):SetH(nHeight - 30)
				hTotal:Lookup('Handle_Fixed_L_Summary'):Hide()
				hTotal:Lookup('Handle_Fixed_R_Summary'):Hide()
				hTotal:Lookup('Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary'):Hide()
			end
			GetComponentProp(raw, 'UpdateScrollY')()
		end)
		-- 更新汇总行各列宽度（跟随表头）
		SetComponentProp(raw, 'UpdateSummaryColumnsWidth', function()
			local function UpdateSummaryColumnWidth(hContents, hColumns, aColumns)
				for nRowIndex = 0, hContents:GetItemCount() - 1 do
					local hRow = hContents:Lookup(nRowIndex)
					local hRowColumns = hRow:Lookup('Handle_RowColumns')
					local nX = 0
					for nColumnIndex, col in ipairs(aColumns) do
						local nWidth = hColumns:Lookup(nColumnIndex - 1):GetW()
						local hItem = hRowColumns:Lookup(nColumnIndex - 1) -- 外部居中层
						local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
						hItemContent:SetW(99999)
						hItemContent:FormatAllItemPos()
						hItemContent:SetSizeByAllItemSize()
						hItem:SetRelX(nX)
						hItem:SetW(nWidth)
						if col.alignVertical == 'top' then
							hItemContent:SetRelY(0)
						elseif col.alignVertical == 'middle' or col.alignVertical == nil then
							hItemContent:SetRelY((hItem:GetH() - hItemContent:GetH()) / 2)
						elseif col.alignVertical == 'bottom' then
							hItemContent:SetRelY(hItem:GetH() - hItemContent:GetH())
						end
						if col.alignHorizontal == 'left' or col.alignHorizontal == nil then
							hItemContent:SetRelX(5)
						elseif col.alignHorizontal == 'center' then
							hItemContent:SetRelX((nWidth - hItemContent:GetW()) / 2)
						elseif col.alignHorizontal == 'right' then
							hItemContent:SetRelX(nWidth - hItemContent:GetW() - 5)
						end
						hItem:FormatAllItemPos()
						nX = nX + nWidth
					end
					hRowColumns:SetW(nX)
					hRowColumns:FormatAllItemPos()
					hRow:SetW(nX)
					hRow:Lookup('Image_RowBg'):SetW(nX)
					hRow:Lookup('Image_RowHover'):SetW(nX)
					hRow:Lookup('Image_RowSpliter'):SetW(nX)
					hRow:FormatAllItemPos()
				end
				hContents:FormatAllItemPos()
			end
			-- 左侧固定列
			local hFixedLContents = raw:Lookup('', 'Handle_Fixed_L_Summary')
			local hFixedLColumns = raw:Lookup('', 'Handle_Fixed_L_TableColumns')
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			UpdateSummaryColumnWidth(hFixedLContents, hFixedLColumns, aFixedLColumns)
			-- 右侧固定列
			local hFixedRContents = raw:Lookup('', 'Handle_Fixed_R_Summary')
			local hFixedRColumns = raw:Lookup('', 'Handle_Fixed_R_TableColumns')
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			UpdateSummaryColumnWidth(hFixedRContents, hFixedRColumns, aFixedRColumns)
			-- 水平滚动列
			local hScrollableContents = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary')
			local hScrollableColumns = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_TableColumns')
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			UpdateSummaryColumnWidth(hScrollableContents, hScrollableColumns, aScrollableColumns)
		end)
		-- 绘制汇总行
		SetComponentProp(raw, 'DrawTableSummary', function()
			local function DrawSummaryContents(hContents, aColumns)
				local rec = GetComponentProp(raw, 'Summary')
				hContents:Clear()
				local hRow = hContents:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndTable.ini', 'Handle_Row')
				local hRowColumns = hRow:Lookup('Handle_RowColumns')
				hRowColumns:Clear()
				for nColumnIndex, col in ipairs(aColumns) do
					local hItem = hRowColumns:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndTable.ini', 'Handle_Item') -- 外部居中层
					local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
					local szXml
					if X.IsTable(rec) then
						if col.render then
							szXml = col.render(rec[col.key], rec, -1)
						else
							szXml = GetFormatText(rec[col.key])
						end
						hItemContent:AppendItemFromString(szXml)
					end
				end
				hRow.OnItemMouseIn = function()
					for _, szPath in ipairs({
						'Handle_Fixed_L_Summary',
						'Handle_Fixed_R_Summary',
						'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary',
					}) do
						local hL = raw:Lookup('', szPath)
						for i = 0, hL:GetItemCount() - 1 do
							hL:Lookup(i):Lookup('Image_RowHover'):SetVisible(i + 1 == 1)
						end
					end
				end
				hRow.OnItemMouseOut = function()
					for _, szPath in ipairs({
						'Handle_Fixed_L_Summary',
						'Handle_Fixed_R_Summary',
						'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary',
					}) do
						local hL = raw:Lookup('', szPath)
						for i = 0, hL:GetItemCount() - 1 do
							hL:Lookup(i):Lookup('Image_RowHover'):Hide()
						end
					end
				end
			end
			-- 左侧固定列
			local hFixedLContents = raw:Lookup('', 'Handle_Fixed_L_Summary')
			local aFixedLColumns = GetComponentProp(raw, 'aFixedLColumns')
			DrawSummaryContents(hFixedLContents, aFixedLColumns)
			-- 右侧固定列
			local hFixedRContents = raw:Lookup('', 'Handle_Fixed_R_Summary')
			local aFixedRColumns = GetComponentProp(raw, 'aFixedRColumns')
			DrawSummaryContents(hFixedRContents, aFixedRColumns)
			-- 水平滚动列
			local hScrollableContents = raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Summary')
			local aScrollableColumns = GetComponentProp(raw, 'aScrollableColumns')
			DrawSummaryContents(hScrollableContents, aScrollableColumns)
			-- 更新列宽
			GetComponentProp(raw, 'UpdateSummaryColumnsWidth')()
		end)
		-- 水平滚动条事件绑定
		local scrollX = raw:Lookup('Scroll_X')
		scrollX.OnScrollBarPosChanged = function()
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X'):SetRelX(-this:GetScrollPos())
			raw:Lookup('', 'Handle_Scroll_X_Wrapper'):FormatAllItemPos()
		end
		scrollX.OnMouseWheel = function()
			scrollX:ScrollNext(-Station.GetMessageWheelDelta() * 2)
			return 1
		end
		scrollX:Lookup('Btn_Scroll_X').OnMouseWheel = function()
			scrollX:ScrollNext(-Station.GetMessageWheelDelta())
			return 1
		end
		-- 垂直滚动条事件绑定
		local scrollY = raw:Lookup('Scroll_Y')
		scrollY.OnScrollBarPosChanged = function()
			-- 左侧固定列
			raw:Lookup('', 'Handle_Fixed_L_Scroll_Y_Wrapper/Handle_Fixed_L_Scroll_Y'):SetRelY(-this:GetScrollPos())
			raw:Lookup('', 'Handle_Fixed_L_Scroll_Y_Wrapper'):FormatAllItemPos()
			-- 右侧固定列
			raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper/Handle_Fixed_R_Scroll_Y'):SetRelY(-this:GetScrollPos())
			raw:Lookup('', 'Handle_Fixed_R_Scroll_Y_Wrapper'):FormatAllItemPos()
			-- 水平滚动列
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper/Handle_Scroll_Y'):SetRelY(-this:GetScrollPos())
			raw:Lookup('', 'Handle_Scroll_X_Wrapper/Handle_Scroll_X/Handle_Scroll_Y_Wrapper'):FormatAllItemPos()
		end
		scrollY.OnMouseWheel = function()
			scrollY:ScrollNext(-Station.GetMessageWheelDelta() * 2)
			return 1
		end
		scrollY:Lookup('Btn_Scroll_Y').OnMouseWheel = function()
			scrollY:ScrollNext(-Station.GetMessageWheelDelta())
			return 1
		end
		raw.OnMouseWheel = function()
			if not scrollY:IsVisible() then
				return
			end
			scrollY:ScrollNext(Station.GetMessageWheelDelta() * 10)
			return 1
		end
	elseif szType == 'CheckBox' then
		raw:RegisterEvent(831)
		local function UpdateCheckState(raw)
			if not X.IsElement(raw) then
				return
			end
			local img = raw:Lookup('Image_Default')
			if not X.IsElement(img) then
				return
			end
			if GetComponentProp(raw, 'bDisabled') then
				img:SetFrame(GetComponentProp(raw, 'bChecked') and 91 or 90)
				raw:SetAlpha(255)
			elseif GetComponentProp(raw, 'bDown') then
				img:SetFrame(GetComponentProp(raw, 'bChecked') and 6 or 5)
				raw:SetAlpha(190)
			elseif GetComponentProp(raw, 'bIn') then
				img:SetFrame(GetComponentProp(raw, 'bChecked') and 7 or 98)
				raw:SetAlpha(255)
			else
				img:SetFrame(GetComponentProp(raw, 'bChecked') and 6 or 5)
				raw:SetAlpha(255)
			end
		end
		raw.OnItemMouseIn = function()
			SetComponentProp(raw, 'bIn', true)
			UpdateCheckState(raw)
		end
		raw.OnItemMouseOut = function()
			SetComponentProp(raw, 'bIn', false)
			UpdateCheckState(raw)
		end
		raw.OnItemLButtonDown = function()
			SetComponentProp(raw, 'bDown', true)
			UpdateCheckState(raw)
		end
		raw.OnItemLButtonUp = function()
			SetComponentProp(raw, 'bDown', false)
			UpdateCheckState(raw)
		end
		raw.OnItemLButtonClick = function()
			raw:Check(not GetComponentProp(raw, 'bChecked'))
		end
		raw.Check = function(_, bChecked, eFireType)
			SetComponentProp(raw, 'bChecked', bChecked)
			UpdateCheckState(raw)
			if eFireType == WNDEVENT_FIRETYPE.PREVENT then
				return
			end
			if bChecked then
				if raw.OnCheckBoxCheck then
					raw.OnCheckBoxCheck()
				end
			else
				if raw.OnCheckBoxUncheck then
					raw.OnCheckBoxUncheck()
				end
			end
		end
		raw.IsCheckBoxChecked = function()
			return GetComponentProp(raw, 'bChecked') or false
		end
		raw.Enable = function(_, bEnabled)
			SetComponentProp(raw, 'bDisabled', not bEnabled)
			UpdateCheckState(raw)
		end
		raw.IsEnabled = function()
			return not GetComponentProp(raw, 'bDisabled')
		end
	elseif szType == 'Shadow' or szType == 'ColorBox' then
		SetComponentProp(raw, 'OnColorPickCBs', {})
		raw:RegisterEvent(831)
		raw.OnItemLButtonClick = function()
			-- 兼容普通 Shadow 组件，无注册事件不弹框
			if szType == 'Shadow' and #GetComponentProp(raw, 'OnColorPickCBs') == 0 then
				return
			end
			-- 颜色组件，无论是否注册过都弹框
			UI.OpenColorPicker(function(r, g, b)
				for _, cb in ipairs(GetComponentProp(raw, 'OnColorPickCBs')) do
					X.CallWithThis(raw, cb, r, g, b)
				end
				UI(raw):Color(r, g, b)
			end)
		end
		raw.Enable = function(_, bEnabled)
			SetComponentProp(raw, 'bDisabled', not bEnabled)
		end
		raw.IsEnabled = function()
			return not GetComponentProp(raw, 'bDisabled')
		end
	end
end

-----------------------------------------------------------
-- my ui selectors -- same as jQuery -- by tinymins --
-----------------------------------------------------------
local OO = {}
--
-- self.raws[] : ui element list
--
-- ui object creator
-- same as jQuery.$()
function OO:ctor(mixed)
	local raws = {}
	local oo = {}
	if X.IsTable(mixed) then
		if X.IsTable(mixed.raws) then
			for _, raw in ipairs(mixed.raws) do
				table.insert(raws, raw)
			end
		elseif X.IsElement(mixed) then
			table.insert(raws, mixed)
		else
			for _, raw in ipairs(mixed) do
				if X.IsElement(raw) then
					table.insert(raws, raw)
				end
			end
		end
	elseif X.IsString(mixed) then
		local raw = Station.Lookup(mixed)
		if X.IsElement(raw) then
			table.insert(raws, raw)
		end
	end
	return setmetatable(oo, {
		__index = function(t, k)
			if k == 'raws' then
				return raws
			elseif X.IsNumber(k) then
				if k < 0 then
					k = #raws + k + 1
				end
				return raws[k]
			else
				return OO[k]
			end
		end,
		__newindex = function(t, k, v)
			if X.IsNumber(k) then
				assert(false, 'Elements are readonly!')
			else
				assert(false, X.NSFormatString('{$NS}_UI (class instance) is readonly!'))
			end
		end,
		__tostring = function(t) return X.NSFormatString('{$NS}_UI (class instance)') end,
	})
end

--  del bad raws
-- (self) _checksum()
function OO:_checksum()
	for i, raw in X.ipairs_r(self.raws) do
		if not X.IsElement(raw) then
			table.remove(self.raws, i)
		end
	end
	return self
end

-- add a element to object
-- same as jQuery.add()
function OO:Add(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		table.insert(raws, raw)
	end
	if X.IsString(mixed) then
		mixed = Station.Lookup(mixed)
	end
	if X.IsElement(mixed) then
		table.insert(raws, mixed)
	end
	if X.IsTable(mixed) and tostring(mixed) == X.NSFormatString('{$NS}_UI (class instance)') then
		for i = 1, mixed:Count() do
			table.insert(raws, mixed[i])
		end
	end
	return UI(raws)
end

-- delete elements from object
-- same as jQuery.not()
function OO:Del(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		table.insert(raws, raw)
	end
	if X.IsString(mixed) then
		-- delete raws those id/class fits filter: mixed
		if string.sub(mixed, 1, 1) == '#' then
			mixed = string.sub(mixed, 2)
			if string.sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in X.ipairs_r(raws) do
					if string.find(raw:GetName(), mixed) then
						table.remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in X.ipairs_r(raws) do
					if raw:GetName() == mixed then
						table.remove(raws, i)
					end
				end
			end
		elseif string.sub(mixed, 1, 1) == '.' then
			mixed = string.sub(mixed, 2)
			if string.sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in X.ipairs_r(raws) do
					if string.find(GetComponentType(raw), mixed) then
						table.remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in X.ipairs_r(raws) do
					if GetComponentType(raw) == mixed then
						table.remove(raws, i)
					end
				end
			end
		end
	elseif X.IsElement(mixed) then
		-- delete raws those treepath is the same as mixed
		mixed = table.concat({ mixed:GetTreePath() })
		for i, raw in X.ipairs_r(raws) do
			if table.concat({ raw:GetTreePath() }) == mixed then
				table.remove(raws, i)
			end
		end
	end
	return UI(raws)
end

-- filter elements from object
-- same as jQuery.filter()
function OO:Filter(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		table.insert(raws, raw)
	end
	if X.IsString(mixed) then
		-- delete raws those id/class not fits filter:mixed
		if string.sub(mixed, 1, 1) == '#' then
			mixed = string.sub(mixed, 2)
			if string.sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in X.ipairs_r(raws) do
					if not string.find(raw:GetName(), mixed) then
						table.remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in X.ipairs_r(raws) do
					if raw:GetName() ~= mixed then
						table.remove(raws, i)
					end
				end
			end
		elseif string.sub(mixed, 1, 1) == '.' then
			mixed = string.sub(mixed, 2)
			if string.sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in X.ipairs_r(raws) do
					if not string.find(GetComponentType(raw), mixed) then
						table.remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in X.ipairs_r(raws) do
					if GetComponentType(raw) ~= mixed then
						table.remove(raws, i)
					end
				end
			end
		end
	elseif X.IsElement(mixed) then
		-- delete raws those treepath is not the same as mixed
		mixed = table.concat({ mixed:GetTreePath() })
		for i, raw in X.ipairs_r(raws) do
			if table.concat({ raw:GetTreePath() }) ~= mixed then
				table.remove(raws, i)
			end
		end
	end
	return UI(raws)
end

-- get parent
-- same as jQuery.parent()
function OO:Parent()
	self:_checksum()
	local raws, hash, path, parent = {}, {}, nil, nil
	for _, raw in ipairs(self.raws) do
		parent = raw:GetParent()
		if parent then
			path = table.concat({ parent:GetTreePath() })
			if not hash[path] then
				table.insert(raws, parent)
				hash[path] = true
			end
		end
	end
	return UI(raws)
end

-- fetch children by name
function OO:Fetch(szName, szSubName)
	self:_checksum()
	local raws, parent, el = {}, nil, nil
	for _, raw in ipairs(self.raws) do
		parent = GetComponentElement(raw, 'MAIN_WINDOW')
		el = parent and parent:Lookup(szName)
		if szSubName then
			if el then
				parent = GetComponentElement(el, 'MAIN_HANDLE')
				el = parent and parent:Lookup(szSubName)
			end
		else
			if not el then
				parent = GetComponentElement(raw, 'MAIN_HANDLE')
				el = parent and parent:Lookup(szName)
			end
		end
		if el then
			table.insert(raws, el)
		end
	end
	return UI(raws)
end

-- get children
-- same as jQuery.children()
function OO:Children(filter)
	self:_checksum()
	if X.IsString(filter) and string.sub(filter, 1, 1) == '#' and string.sub(filter, 2, 2) ~= '^' then
		local raws, hash, name, child, path = {}, {}, string.sub(filter, 2)
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'MAIN_WINDOW') or raw
			child = raw:Lookup(name)
			if child then
				path = table.concat({ child:GetTreePath() })
				if not hash[path] then
					table.insert(raws, child)
					hash[path] = true
				end
			end
			if raw:GetBaseType() == 'Wnd' then
				child = GetComponentElement(raw, 'MAIN_HANDLE')
				child = child and child:Lookup(name)
				if child then
					path = table.concat({ child:GetTreePath() })
					if not hash[path] then
						table.insert(raws, child)
						hash[path] = true
					end
				end
			end
		end
		return UI(raws)
	else
		local raws, hash, child, path = {}, {}, nil, nil
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'MAIN_WINDOW') or raw
			if raw:GetBaseType() == 'Wnd' then
				child = raw:GetFirstChild()
				while child do
					path = table.concat({ child:GetTreePath() })
					if not hash[path] then
						table.insert(raws, child)
						hash[path] = true
					end
					child = child:GetNext()
				end
				local h = GetComponentElement(raw, 'MAIN_HANDLE') or raw:Lookup('', '')
				if h then
					for i = 0, h:GetItemCount() - 1 do
						child = h:Lookup(i)
						path = table.concat({ child:GetTreePath() })
						if not hash[path] then
							table.insert(raws, child)
							hash[path] = true
						end
					end
				end
			elseif raw:GetType() == 'Handle' then
				for i = 0, raw:GetItemCount() - 1 do
					child = raw:Lookup(i)
					path = table.concat({ child:GetTreePath() })
					if not hash[path] then
						table.insert(raws, child)
						hash[path] = true
					end
				end
			end
		end
		return UI(raws):Filter(filter)
	end
end

-- find element
-- same as jQuery.find()
function OO:Find(filter)
	self:_checksum()
	local top, raw, ruid, child
	local raws, hash, stack, children = {}, {}, {}, {}
	for _, root in ipairs(self.raws) do
		top = #raws
		table.insert(stack, root)
		while #stack > 0 do
			--### 弹出栈顶元素准备处理
			raw = table.remove(stack, #stack)
			ruid = tostring(raw)
			--### 判断不在结果集中则处理
			if not hash[ruid] then
				--## 将自身加入结果队列
				table.insert(raws, raw)
				hash[ruid] = true
				--## 计算所有子元素并将子元素压栈准备下次循环处理
				--## 注意要逆序压入栈中以保证最终结果是稳定排序的
				if raw:GetBaseType() == 'Wnd' then
					child = raw:Lookup('', '')
					if child then
						for i = 0, child:GetItemCount() - 1 do
							table.insert(children, child:Lookup(i))
						end
					end
					child = raw:GetFirstChild()
					while child do
						table.insert(children, child)
						child = child:GetNext()
					end
					repeat
						child = table.remove(children)
						table.insert(stack, child)
					until not child
				elseif raw:GetType() == 'Handle' then
					for i = 0, raw:GetItemCount() - 1 do
						table.insert(children, raw:Lookup(i))
					end
					repeat
						child = table.remove(children)
						table.insert(stack, child)
					until not child
				end
			end
		end
		-- 因为是求子元素 所以移除第一个压栈的元素（父元素）
		table.remove(raws, top + 1)
	end
	return UI(raws):Filter(filter)
end

function OO:Raw(nIndex)
	self:_checksum()
	return self.raws[nIndex or 1]
end

-- filter mouse in component
function OO:PtIn()
	self:_checksum()
	local raws = {}
	local cX, cY = Cursor.GetPos()
	for _, raw in pairs(self.raws) do
		if raw:GetBaseType() == 'Wnd' then
			if raw:PtInItem(cX, cY) then
				table.insert(raws, raw)
			end
		else
			if raw:PtInWindow(cX, cY) then
				table.insert(raws, raw)
			end
		end
	end
	return UI(raws)
end

-- each
-- same as jQuery.each(function(){})
-- :Each(UI each_self)  -- you can use 'this' to visit raw element likes jQuery
function OO:Each(fn)
	self:_checksum()
	for _, raw in pairs(self.raws) do
		X.ExecuteWithThis(raw, fn, UI(raw))
	end
	return self
end

-- slice -- index starts from 1
-- same as jQuery.slice(selector, pos)
function OO:Slice(startpos, endpos)
	self:_checksum()
	startpos = startpos or 1
	if startpos < 0 then
		startpos = #self.raws + startpos + 1
	end
	endpos = endpos or #self.raws
	if endpos < 0 then
		endpos = #self.raws + endpos + 1
	end
	local raws = {}
	for i = startpos, endpos, 1 do
		table.insert(raws, self.raws[i])
	end
	return UI(raws)
end

-- eq
-- same as jQuery.eq(pos)
function OO:Eq(pos)
	if pos then
		return self:Slice(pos, pos)
	end
	return self
end

-- first
-- same as jQuery.first()
function OO:First()
	return self:Slice(1, 1)
end

-- last
-- same as jQuery.last()
function OO:Last()
	return self:Slice(-1, -1)
end

-- get count
function OO:Count()
	self:_checksum()
	return #self.raws
end

-----------------------------------------------------------
-- my ui operation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
-- (void) Instance:Remove()
-- (self) Instance:Remove(function onRemove)
function OO:Remove(onRemove)
	self:_checksum()
	if onRemove then
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'onRemove', onRemove)
		end
	else
		for _, raw in ipairs(self.raws) do
			local onRemove = GetComponentProp(raw, 'onRemove')
			if not onRemove or not onRemove(raw) then
				if raw:GetType() == 'WndFrame' then
					Wnd.CloseWindow(raw)
				elseif raw:GetBaseType() == 'Wnd' then
					raw:Destroy()
				else
					local h = raw:GetParent()
					if h and h:GetType() == 'Handle' then
						h:RemoveItem(raw)
						h:FormatAllItemPos()
					end
				end
			end
		end
		self:_checksum()
	end
	return self
end

local function OnCommonComponentMouseEnter()
	if not this:IsMouseIn() then
		return
	end
	local hText = GetComponentElement(this, 'TEXT')
	if not hText then
		return
	end

	local szText = hText:GetText()
	if X.IsEmpty(szText) then
		return
	end

	local nDisLen = hText:GetTextPosExtent()
	local nLen = wstring.len(hText:GetText())
	if nDisLen == nLen then
		return
	end

	local nW = hText:GetW()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(GetFormatText(szText), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
end
local function OnCommonComponentHover(bIn)
	if bIn then
		OnCommonComponentMouseEnter()
	else
		HideTip()
	end
end

-- xml string
local _tItemXML = {
	['Text'] = '<text>w=150 h=30 valign=1 font=162 eventid=371 </text>',
	['Image'] = '<image>w=100 h=100 </image>',
	['Box'] = '<box>w=48 h=48 eventid=525311 </box>',
	['Shadow'] = '<shadow>w=15 h=15 eventid=277 </shadow>',
	['Handle'] = '<handle>firstpostype=0 w=10 h=10 </handle>',
	['CheckBox'] = '<handle>name="CheckBox" firstpostype=0 w=100 h=28 <image>name="Image_Default" w=28 h=28 path="ui\\Image\\button\\CommonButton_1.UITex" frame=5 </image><text>name="Text_Default" font=162 valign=1 showall=0 x=29 w=71 h=28 </text></handle>',
	['ColorBox'] = '<handle>name="ColorBox" firstpostype=0 w=100 h=28 eventid=277 <shadow>name="Shadow_Default" w=28 h=28 </shadow><text>name="Text_Default" font=162 valign=1 showall=0 x=29 w=71 h=28 </text></handle>',
}
local _nTempWndCount = 0
-- append
-- similar as jQuery.append()
-- Instance:Append(szXml)
-- Instance:Append(szType[, tArg | szName])
function OO:Append(arg0, arg1)
	assert(X.IsString(arg0))
	if #arg0 == 0 then
		return
	end
	self:_checksum()

	local ui, szXml, szType, tArg = UI()
	if arg0:find('%<') then
		szXml = arg0
	else
		szType = arg0
		szXml = _tItemXML[szType]
		if X.IsTable(arg1) then
			tArg = arg1
		elseif X.IsString(arg1) then
			tArg = { name = arg1 }
		end
	end
	if szXml then -- append from xml
		local startIndex, el
		for _, raw in ipairs(self.raws) do
			local h = GetComponentElement(raw, 'MAIN_HANDLE')
			if h then
				startIndex = h:GetItemCount()
				h:AppendItemFromString(szXml)
				h:FormatAllItemPos()
				for i = startIndex, h:GetItemCount() - 1 do
					el = h:Lookup(i)
					if szType then
						InitComponent(el, szType)
					end
					ui = ui:Add(el)
				end
			end
		end
	elseif szType then -- append from ini file
		for _, raw in ipairs(self.raws) do
			local parentWnd = GetComponentElement(raw, 'MAIN_WINDOW')
			local parentHandle = GetComponentElement(raw, 'MAIN_HANDLE')
			local szFile, szComponent = szType, szType
			if string.find(szFile, '^[^<>?:]*%.ini:%w+$') then
				szType = string.gsub(szFile, '^[^<>?]*%.ini:', '')
				szFile = string.sub(szFile, 0, -#szType - 2)
				szComponent = szFile:gsub('$.*[/\\]', ''):gsub('^[^<>?]*[/\\]', ''):sub(0, -5)
			else
				szFile = X.PACKET_INFO.UICOMPONENT_ROOT .. szFile .. '.ini'
			end
			local frame = Wnd.OpenWindow(szFile, X.NSFormatString('{$NS}_TempWnd#') .. _nTempWndCount)
			if not frame then
				return X.Debug(X.NSFormatString('{$NS}#UI#Append'), _L('Unable to open ini file [%s]', szFile), X.DEBUG_LEVEL.ERROR)
			end
			_nTempWndCount = _nTempWndCount + 1
			-- start ui append
			raw = nil
			if szType:sub(1, 3) == 'Wnd' then
				if parentWnd then -- KWndWindow
					raw = frame:Lookup(szComponent)
					if raw then
						InitComponent(raw, szType)
						raw:ChangeRelation(parentWnd, true, true)
						if parentWnd:GetType() == 'WndContainer' then
							parentWnd:FormatAllContentPos()
						end
					end
				end
			else
				if parentHandle then
					raw = parentHandle:AppendItemFromIni(szFile, szComponent)
					if raw then -- KItemNull
						InitComponent(raw, szType)
						parentHandle:FormatAllItemPos()
					end
				end
			end
			if raw then
				ui = ui:Add(raw)
				UI(raw):Hover(OnCommonComponentHover):Change(OnCommonComponentMouseEnter)
			else
				X.Debug(X.NSFormatString('{$NS}#UI#Append'), _L('Can not find wnd or item component [%s:%s]', szFile, szComponent), X.DEBUG_LEVEL.ERROR)
			end
			Wnd.CloseWindow(frame)
		end
	end
	return ApplyUIArguments(ui, tArg)
end

-- clear
-- clear handle
-- (self) Instance:Clear()
function OO:Clear()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		if raw.Clear then
			raw:Clear()
		end
		raw = GetComponentElement(raw, 'MAIN_HANDLE')
		if raw then
			raw:Clear()
			raw:FormatAllItemPos()
		end
	end
	return self
end

-- remove child item until new line
-- (self) Instance:RemoveItemUntilNewLine()
function OO:RemoveItemUntilNewLine()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		if raw.Clear then
			raw:Clear()
		end
		raw = GetComponentElement(raw, 'MAIN_HANDLE')
		if raw then
			raw:RemoveItemUntilNewLine()
			raw:FormatAllItemPos()
		end
	end
	return self
end

-----------------------------------------------------------
-- my ui property visitors
-----------------------------------------------------------

-- data set/get
do local l_data = setmetatable({}, { __mode = 'k' })
function OO:Data(key, value)
	self:_checksum()
	if key and value then -- set
		for _, raw in ipairs(self.raws) do
			if not l_data[raw] then
				l_data[raw] = {}
			end
			l_data[raw][key] = value
		end
		return self
	elseif key then -- get
		local raw = self.raws[1]
		if raw then
			return l_data[raw] and l_data[raw][key]
		end
	end
end
end

-- show
function OO:Show()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw:Show()
	end
	return self
end

-- hide
function OO:Hide()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw:Hide()
	end
	return self
end

-- visible
function OO:Visible(bVisible)
	self:_checksum()
	if X.IsBoolean(bVisible) then
		return self:Toggle(bVisible)
	elseif X.IsFunction(bVisible) then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'CHECKBOX') or GetComponentElement(raw, 'MAIN_WINDOW') or raw
			X.BreatheCall(X.NSFormatString('{$NS}_UI_VISIBLE_CHECK#') .. tostring(raw), function()
				if X.IsElement(raw) then
					raw:SetVisible(bVisible())
				else
					return 0
				end
			end)
			raw:SetVisible(bVisible())
		end
	else
		local raw = self.raws[1]
		if raw and raw.IsVisible then
			return raw:IsVisible()
		end
	end
end

-- enable or disable elements
do
local function SetComponentEnable(raw, bEnable)
	-- check if set value equals with current status
	local bEnable = bEnable and true or false
	local bEnabled = GetComponentProp(raw, 'bEnable')
	if bEnabled == nil then
		if raw.IsEnabled then
			bEnabled = raw:IsEnabled()
		else
			bEnabled = true
		end
	end
	if bEnabled == bEnable then
		return
	end
	-- make gray
	local txt = GetComponentElement(raw, 'TEXT')
	if txt then
		local r, g, b = txt:GetFontColor()
		local ratio = bEnable and 2.2 or (1 / 2.2)
		if math.max(r, g, b) * ratio > 255 then
			ratio = 255 / math.max(r, g, b)
		end
		txt:SetFontColor(math.ceil(r * ratio), math.ceil(g * ratio), math.ceil(b * ratio))
	end
	-- make gray
	local sha = GetComponentElement(raw, 'SHADOW')
	if sha then
		local r, g, b = sha:GetColorRGB()
		local ratio = bEnable and 2.2 or (1 / 2.2)
		if math.max(r, g, b) * ratio > 255 then
			ratio = 255 / math.max(r, g, b)
		end
		sha:SetColorRGB(math.ceil(r * ratio), math.ceil(g * ratio), math.ceil(b * ratio))
	end
	-- set sub elements enable
	local combo = GetComponentElement(raw, 'COMBOBOX')
	if combo then
		combo:Enable(bEnable)
	end
	local trackbar = GetComponentElement(raw, 'TRACKBAR')
	if trackbar then
		trackbar:Enable(bEnable)
	end
	local edit = GetComponentElement(raw, 'EDIT')
	if edit then
		edit:Enable(bEnable)
	end
	-- set enable
	if raw.Enable then
		raw:Enable(bEnable)
	end
	SetComponentProp(raw, 'bEnable', bEnable)
end

function OO:Enable(...)
	self:_checksum()
	local argc = select('#', ...)
	if argc == 1 then
		local bEnable = select(1, ...)
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'CHECKBOX') or GetComponentElement(raw, 'MAIN_WINDOW') or raw
			if X.IsFunction(bEnable) then
				X.BreatheCall(X.NSFormatString('{$NS}_UI_ENABLE_CHECK#') .. tostring(raw), function()
					if X.IsElement(raw) then
						SetComponentEnable(raw, bEnable())
					else
						return 0
					end
				end)
				SetComponentEnable(raw, bEnable())
			else
				SetComponentEnable(raw, bEnable)
			end
		end
		return self
	else
		local raw = self.raws[1]
		local bEnable = GetComponentProp(raw, 'bEnable')
		if bEnable ~= nil then
			return bEnable
		end
		if raw and raw.IsEnabled then
			return raw:IsEnabled()
		end
	end
end
end

-- show/hide raws
function OO:Toggle(bShow)
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		if bShow == false or (bShow == nil and raw:IsVisible()) then
			raw:Hide()
		else
			raw:Show()
		end
	end
	return self
end

-- drag area
-- (self) drag(boolean bEnableDrag) -- enable/disable drag
-- (self) drag(number nX, number y, number w, number h) -- set drag positon and area
-- (self) drag(function fnOnDrag, function fnOnDragEnd)-- bind frame/item frag event handle
function OO:Drag(...)
	self:_checksum()
	local argc = select('#', ...)
	local arg0, arg1, arg2, arg3 = ...
	if argc == 0 then
	elseif X.IsBoolean(arg0) then
		local bDrag = arg0
		for _, raw in ipairs(self.raws) do
			if raw.EnableDrag then
				raw:EnableDrag(bDrag)
			end
		end
		return self
	elseif X.IsNumber(arg0) or X.IsNumber(arg1) or X.IsNumber(arg2) or X.IsNumber(arg3) then
		local nX, nY, nW, nH = arg0 or 0, arg1 or 0, arg2, arg3
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				raw:SetDragArea(nX, nY, nW or raw:GetW(), nH or raw:GetH())
			end
		end
		return self
	elseif X.IsFunction(arg0) or X.IsFunction(arg1) then
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				if arg0 then
					UI(raw):UIEvent('OnFrameDragSetPosEnd', arg0)
				end
				if arg1 then
					UI(raw):UIEvent('OnFrameDragEnd', arg1)
				end
			elseif raw:GetBaseType() == 'Item' then
				if arg0 then
					UI(raw):UIEvent('OnItemLButtonDrag', arg0)
				end
				if arg1 then
					UI(raw):UIEvent('OnItemLButtonDragEnd', arg1)
				end
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw and raw:GetType() == 'WndFrame' then
			return raw:IsDragable()
		end
	end
end

-- get/set ui object text
function OO:Text(arg0, arg1)
	self:_checksum()
	if not X.IsNil(arg0) and not X.IsBoolean(arg0) then
		local componentType, element
		for _, raw in ipairs(self.raws) do
			componentType = GetComponentType(raw)
			if X.IsFunction(arg0) then
				if componentType == 'WndTrackbar' then
					SetComponentProp(raw, 'FormatText', arg0)
					GetComponentProp(raw, 'ResponseUpdateScroll')(true)
				end
			elseif X.IsTable(arg0) then
				if componentType == 'WndEditBox' or componentType == 'WndAutocomplete' then
					element = GetComponentElement(raw, 'EDIT')
					SetComponentProp(element, 'WNDEVENT_FIRETYPE', arg1)
					for k, v in ipairs(arg0) do
						if v.type == 'text' then
							element:InsertText(v.text)
						else
							element:InsertObj(v.text, v)
						end
					end
				end
			else
				if not X.IsString(arg0) then
					arg0 = tostring(arg0)
				end
				if componentType == 'WndScrollHandleBox' then
					element = GetComponentElement(raw, 'MAIN_HANDLE')
					element:Clear()
					element:AppendItemFromString(GetFormatText(arg0))
					element:FormatAllItemPos()
				elseif componentType == 'Text' then
					raw:SetText(arg0)
					if GetComponentProp(raw, 'bAutoSize') then
						raw:AutoSize()
						raw:GetParent():FormatAllItemPos()
					end
				else
					element = GetComponentElement(raw, 'TEXT')
					if element then
						element:SetText(arg0)
					end
					element = GetComponentElement(raw, 'EDIT')
					if element then
						SetComponentProp(element, 'WNDEVENT_FIRETYPE', arg1)
						element:SetText(arg0)
					end
				end
			end
		end
		return self
	else -- arg0: bStruct
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'TEXT') or GetComponentElement(raw, 'EDIT') or raw
			if raw then
				if arg0 then
					if raw.GetTextStruct then
						return raw:GetTextStruct()
					elseif raw.GetText then
						return { type = 'text', text = raw:GetText() }
					end
				elseif raw.GetText then
					return raw:GetText()
				end
			end
		end
	end
end

-- get/set ui object text
function OO:Placeholder(szText)
	self:_checksum()
	if szText then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				raw:SetPlaceholderText(szText)
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				return raw:GetPlaceholderText()
			end
		end
	end
end

-- ui autocomplete interface
function OO:Autocomplete(method, arg1, arg2)
	self:_checksum()
	if method == 'option' and (X.IsNil(arg1) or (X.IsString(arg1) and X.IsNil(arg2))) then -- get
		-- try to get its option
		local raw = self.raws[1]
		if raw then
			return X.Clone(GetComponentProp(raw, 'autocompleteOptions'))
		end
	else -- set
		if method == 'option' then
			if X.IsString(arg1) then
				arg1 = {
					[arg1] = arg2
				}
			end
			if X.IsTable(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndAutocomplete' then
						for k, v in pairs(arg1) do
							SetComponentProp(raw, 'autocompleteOptions', k, v)
						end
					end
				end
			end
		elseif method == 'close' then
			UI.ClosePopupMenu()
		elseif method == 'destroy' then
			for _, raw in ipairs(self.raws) do
				raw:Lookup('WndEdit_Default').OnSetFocus = nil
				raw:Lookup('WndEdit_Default').OnKillFocus = nil
			end
		elseif method == 'disable' then
			self:Autocomplete('option', 'disable', true)
		elseif method == 'enable' then
			self:Autocomplete('option', 'disable', false)
		elseif method == 'search' then
			for _, raw in ipairs(self.raws) do
				local opt = GetComponentProp(raw, 'autocompleteOptions')
				if opt then
					local text = arg1 or raw:Lookup('WndEdit_Default'):GetText()
					if X.IsFunction(opt.beforeSearch) then
						X.ExecuteWithThis(raw, opt.beforeSearch, text)
					end
					local needle = opt.ignoreCase and StringLowerW(text) or text
					local aSrc = {}
					-- get matched list
					for _, src in ipairs(opt.source) do
						local haystack = type(src) == 'table' and (src.keyword or tostring(src.text)) or tostring(src)
						if opt.ignoreCase then
							haystack = StringLowerW(haystack)
						end
						local pos = wstring.find(haystack, needle)
						if pos and pos > 0 and not opt.anyMatch then
							pos = nil
						end
						if not pos then
							local aPinyin, aPinyinConsonant = X.Han2Pinyin(haystack)
							if not pos then
								for _, s in ipairs(aPinyin) do
									pos = wstring.find(s, needle)
									if pos and pos > 0 and not opt.anyMatch then
										pos = nil
									end
									if pos then
										break
									end
								end
							end
							if not pos then
								for _, s in ipairs(aPinyinConsonant) do
									pos = wstring.find(s, needle)
									if pos and pos > 0 and not opt.anyMatch then
										pos = nil
									end
									if pos then
										break
									end
								end
							end
						end
						if pos then
							table.insert(aSrc, src)
						end
					end

					-- create menu
					local menu = {}
					for _, src in ipairs(aSrc) do
						local szText, szDisplay, szOption, bDivide, bRichText
						if type(src) == 'table' then
							szText = src.text
							szDisplay = src.display or szText
							bDivide = src.divide or false
							bRichText = src.richtext or false
						else
							szText = tostring(src)
							szDisplay = szText
							bDivide = false
							bRichText = false
						end
						-- max opt limit
						if opt.maxOption > 0 and #menu >= opt.maxOption then
							break
						end
						-- create new opt
						local t
						if bDivide then
							if #menu == 0 or not menu[#menu].bDevide then
								t = CONSTANT.MENU_DIVIDER
							end
						else
							t = {
								szOption = szDisplay,
								bRichText = bRichText,
								fnAction = function()
									opt.disabledTmp = true
									raw:Lookup('WndEdit_Default'):SetText(szText)
									if X.IsFunction(opt.afterComplete) then
										opt.afterComplete(raw, opt, text, src)
									end
									UI.ClosePopupMenu()
									opt.disabledTmp = nil
								end,
							}
							if opt.beforeDelete or opt.afterDelete then
								t.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
								t.nFrame = 49
								t.nMouseOverFrame = 51
								t.nIconWidth = 17
								t.nIconHeight = 17
								t.szLayer = 'ICON_RIGHTMOST'
								t.fnClickIcon = function()
									local bSure = true
									local fnDoDelete = function()
										for i = #opt.source, 1, -1 do
											if opt.source[i] == src then
												table.remove(opt.source, i)
											end
										end
										UI(raw):Autocomplete('search')
									end
									if opt.beforeDelete then
										local bSuccess
										bSuccess, bSure = X.ExecuteWithThis(raw, opt.beforeDelete, src)
										if not bSuccess then
											bSure = false
										end
									end
									if bSure ~= false then
										fnDoDelete()
									end
									if opt.afterDelete then
										X.ExecuteWithThis(raw, opt.afterDelete, src)
									end
								end
							end
						end
						if t then
							table.insert(menu, t)
						end
					end
					local nX, nY = raw:GetAbsPos()
					local nW, nH = raw:GetSize()
					menu.szLayer = 'Topmost2'
					menu.nMiniWidth = nW
					menu.nWidth = nW
					menu.x, menu.y = nX, nY + nH
					menu.bDisableSound = true
					menu.bShowKillFocus = true
					menu.nMaxHeight = math.min(select(2, Station.GetClientSize()) - raw:GetAbsY() - raw:GetH(), 600)

					if X.IsFunction(opt.beforePopup) then
						X.ExecuteWithThis(raw, opt.beforePopup, menu)
					end
					-- popup menu
					if #menu > 0 then
						opt.disabledTmp = true
						UI.PopupMenu(menu)
						Station.SetFocusWindow(raw:Lookup('WndEdit_Default'))
						opt.disabledTmp = nil
					else
						UI.ClosePopupMenu()
					end
				end
			end
		elseif method == 'insert' then
			if X.IsString(arg1) then
				arg1 = { arg1 }
			end
			if X.IsTable(arg1) then
				for _, src in ipairs(arg1) do
					if X.IsString(src) then
						for _, raw in ipairs(self.raws) do
							local opt = GetComponentProp(raw, 'autocompleteOptions')
							for i = #opt.source, 1, -1 do
								if opt.source[i] == src then
									table.remove(opt.source, i)
								end
							end
							table.insert(opt.source, src)
						end
					end
				end
			end
		elseif method == 'delete' then
			if X.IsString(arg1) then
				arg1 = { arg1 }
			end
			if X.IsTable(arg1) then
				for _, src in ipairs(arg1) do
					if X.IsString(src) then
						for _, raw in ipairs(self.raws) do
							local opt = GetComponentProp(raw, 'autocompleteOptions')
							for i=#opt.source, 1, -1 do
								if opt.source[i] == arg1 then
									table.remove(opt.source, i)
								end
							end
						end
					end
				end
			end
		end
		return self
	end
end

-- ui list box interface
-- (get) list:ListBox('option')
-- (set) list:ListBox('option', k, v)
-- (set) list:ListBox('option', {k1=v1, k2=v2})
-- (set) list:ListBox('select', 'all'|'unselected'|'selected')
-- (set) list:ListBox('insert', { id=id, text=text, data=data, index=index, r=r, g=g, b=b })
-- (set) list:ListBox('exchange', 'id'|'index', k1, k2)
-- (set) list:ListBox('update', 'id'|'text', k, { text=szText, data=oData })
-- (set) list:ListBox('update', 'id'|'text', k, {'text', 'data'}, {szText, oData})
-- (set) list:ListBox('delete', 'id'|'text', k)
-- (set) list:ListBox('clear')
-- (set) list:ListBox('onmenu', function(id, text, data, selected) end)
-- (set) list:ListBox('onlclick', function(id, text, data, selected) end)
-- (set) list:ListBox('onrclick', function(id, text, data, selected) end)
-- (set) list:ListBox('onhover', function(id, text, data, selected) end, function(id, text, data, selected) end)
function OO:ListBox(method, arg1, arg2, arg3, arg4)
	self:_checksum()
	if method == 'option' and (X.IsNil(arg1) or (X.IsString(arg1) and X.IsNil(arg2))) then -- get
		-- try to get its option
		local raw = self.raws[1]
		if raw then
			return X.Clone(GetComponentProp(raw, 'listboxOptions'))
		end
	else -- set
		if method == 'option' then
			if X.IsString(arg1) then
				arg1 = {
					[arg1] = arg2
				}
			end
			if X.IsTable(arg1) then
				for _, raw in ipairs(self.raws) do
					for k, v in pairs(arg1) do
						SetComponentProp(raw, 'listboxOptions', k, v)
					end
				end
			end
		elseif method == 'select' then
			local tData = {}
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					local hList = raw:Lookup('', 'Handle_Scroll')
					for i = 0, hList:GetItemCount() - 1, 1 do
						local data = GetComponentProp(hList:Lookup(i), 'listboxItemData')
						if arg1 == 'all'
						or (arg1 == 'unselected' and not data.selected)
						or (arg1 == 'selected' and data.selected) then
							table.insert(tData, data)
						end
					end
				end
			end
			return tData
		elseif method == 'insert' then
			local id, text, data, pos, r, g, b, selected = arg1.id, arg1.text, arg1.data, arg1.index, arg1.r, arg1.g, arg1.b, arg1.selected or false
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					local hList = raw:Lookup('', 'Handle_Scroll')
					local bExist
					if id then
						for i = hList:GetItemCount() - 1, 0, -1 do
							if hList:Lookup(i).id == id then
								bExist = true
							end
						end
					end
					if not bExist then
						local w, h = hList:GetSize()
						local xml = '<handle>eventid=371 pixelscroll=1 <image>w='..w..' h=25 path="UI/Image/Common/TextShadow.UITex" frame=5 alpha=0 name="Image_Bg" </image><image>w='..w..' h=25 path="UI/Image/Common/TextShadow.UITex" lockshowhide=1 frame=2 name="Image_Sel" </image><text>w='..w..' h=25 valign=1 name="Text_Default" </text></handle>'
						local hItem
						if pos then
							pos = pos - 1 -- C++ count from zero but lua count from one.
							hList:InsertItemFromString(pos, false, xml)
							hItem = hList:Lookup(pos)
						else
							hList:AppendItemFromString(xml)
							hItem = hList:Lookup(hList:GetItemCount() - 1)
						end
						SetComponentProp(hItem, 'listboxItemData', {
							id = id,
							text = text,
							data = data,
							selected = selected,
						})
						hItem:Lookup('Text_Default'):SetText(text)
						if r and g and b then
							hItem:Lookup('Text_Default'):SetFontColor(r, g, b)
						end
						hItem:Lookup('Image_Sel'):SetVisible(selected)
						hItem.OnItemMouseEnter = GetComponentProp(raw, 'OnListItemHandleMouseEnter')
						hItem.OnItemMouseLeave = GetComponentProp(raw, 'OnListItemHandleMouseLeave')
						hItem.OnItemLButtonClick = GetComponentProp(raw, 'OnListItemHandleLButtonClick')
						hItem.OnItemRButtonClick = GetComponentProp(raw, 'OnListItemHandleRButtonClick')
						hList:FormatAllItemPos()
					end
				end
			end
		elseif method == 'exchange' then
			local mode, key1, key2 = arg1, arg2, arg3
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					local hList = raw:Lookup('', 'Handle_Scroll')
					local index1, index2
					if mode == 'id' then
						for i = hList:GetItemCount() - 1, 0, -1 do
							if hList:Lookup(i).id == key1 then
								index1 = i
							elseif hList:Lookup(i).id == key2 then
								index2 = i
							end
						end
					elseif mode == 'index' then
						if key1 > 0 and key1 < hList:GetItemCount() + 1 then
							index1 = key1 - 1 -- C++ count from zero but lua count from one.
						end
						if key2 >= 0 and key2 < hList:GetItemCount() + 1 then
							index2 = key2 - 1 -- C++ count from zero but lua count from one.
						end
					end
					if index1 and index2 then
						hList:ExchangeItemIndex(index1, index2)
						hList:FormatAllItemPos()
					end
				end
			end
		elseif method == 'update' then
			local mode, search, argk, argv = arg1, arg2, arg3, arg4
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					local hList = raw:Lookup('', 'Handle_Scroll')
					for i = hList:GetItemCount() - 1, 0, -1 do
						local hItem = hList:Lookup(i)
						local data = GetComponentProp(hItem, 'listboxItemData')
						if (mode == 'id' and data.id == search)
						or (mode == 'text' and data.text == search) then
							if argv then
								for i, k in ipairs(argk) do
									if k == 'text' then
										hItem:Lookup('Text_Default'):SetText(argv[i])
									end
									data[k] = argv[i]
								end
							else
								for k, v in ipairs(argk) do
									if k == 'text' then
										hItem:Lookup('Text_Default'):SetText(v)
									end
									data[k] = v
								end
							end
						end
					end
				end
			end
		elseif method == 'delete' then
			local mode, search = arg1, arg2
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					local hList = raw:Lookup('', 'Handle_Scroll')
					for i = hList:GetItemCount() - 1, 0, -1 do
						local data = GetComponentProp(hList:Lookup(i), 'listboxItemData')
						if (mode == 'id' and data.id == search)
						or (mode == 'text' and data.text == search) then
							hList:RemoveItem(i)
						end
					end
					hList:FormatAllItemPos()
				end
			end
		elseif method == 'clear' then
			for _, raw in ipairs(self.raws) do
				if GetComponentType(raw) == 'WndListBox' then
					raw:Lookup('', 'Handle_Scroll'):Clear()
				end
			end
		elseif method == 'onmenu' then
			if X.IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'GetListItemHandleMenu', arg1)
					end
				end
			end
		elseif method == 'onlclick' then
			if X.IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomLButtonClick', arg1)
					end
				end
			end
		elseif method == 'onrclick' then
			if X.IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomRButtonClick', arg1)
					end
				end
			end
		elseif method == 'onhover' then
			if X.IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomHoverIn', arg1)
					end
				end
			end
			if X.IsFunction(arg2) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomHoverOut', arg2)
					end
				end
			end
		end
		return self
	end
end

-- get/set table columns
function OO:Columns(aColumns)
	self:_checksum()
	if aColumns then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				local aFixedLColumns, aFixedRColumns, aScrollableColumns = {}, {}, {}
				local nFixedLColumnsWidth, nFixedRColumnsWidth = 0, 0
				for _, col in ipairs(aColumns) do
					if col.fixed == true or col.fixed == 'left' then
						assert(X.IsNumber(col.width), 'fixed column width is required')
						nFixedLColumnsWidth = nFixedLColumnsWidth + col.width
						table.insert(aFixedLColumns, col)
					else
						break
					end
				end
				for _, col in X.ipairs_r(aColumns) do
					if col.fixed == 'right' then
						assert(X.IsNumber(col.width), 'fixed column width is required')
						nFixedRColumnsWidth = nFixedRColumnsWidth + col.width
						table.insert(aFixedRColumns, col)
					else
						break
					end
				end
				for i = #aFixedLColumns + 1, #aColumns - #aFixedRColumns do
					table.insert(aScrollableColumns, aColumns[i])
				end
				SetComponentProp(raw, 'aFixedLColumns', aFixedLColumns)
				SetComponentProp(raw, 'aFixedRColumns', aFixedRColumns)
				SetComponentProp(raw, 'aScrollableColumns', aScrollableColumns)
				SetComponentProp(raw, 'nFixedLColumnsWidth', nFixedLColumnsWidth)
				SetComponentProp(raw, 'nFixedRColumnsWidth', nFixedRColumnsWidth)
				GetComponentProp(raw, 'DrawColumnsTitle')()
				GetComponentProp(raw, 'DrawTableContent')()
				GetComponentProp(raw, 'DrawTableSummary')()
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			if GetComponentType(raw) == 'WndTable' then
				local aColumns = {}
				for _, v in ipairs(GetComponentProp(raw, 'aFixedLColumns')) do
					table.insert(aColumns, v)
				end
				for _, v in ipairs(GetComponentProp(raw, 'aScrollableColumns')) do
					table.insert(aColumns, v)
				end
				for _, v in ipairs(GetComponentProp(raw, 'aFixedRColumns')) do
					table.insert(aColumns, v)
				end
				return aColumns
			end
		end
	end
end

-- get/set table data source
function OO:DataSource(aDataSource)
	self:_checksum()
	if aDataSource then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				SetComponentProp(raw, 'DataSource', aDataSource)
				GetComponentProp(raw, 'DrawTableContent')()
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			if GetComponentType(raw) == 'WndTable' then
				return GetComponentProp(raw, 'DataSource')
			end
		end
	end
end

-- get/set table summary
function OO:Summary(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local summary = ...
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				SetComponentProp(raw, 'Summary', summary)
				GetComponentProp(raw, 'DrawTableSummary')()
				GetComponentProp(raw, 'UpdateSummaryVisible')()
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			if GetComponentType(raw) == 'WndTable' then
				return GetComponentProp(raw, 'Summary')
			end
		end
	end
end

-- get/set table sort
function OO:Sort(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local szSortKey, szSortOrder = ...
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				if X.IsFunction(szSortKey) then
					SetComponentProp(raw, 'OnSortChange', function()
						X.ExecuteWithThis(raw, szSortKey, GetComponentProp(raw, 'SortKey'), GetComponentProp(raw, 'SortOrder'))
					end)
				elseif szSortKey ~= GetComponentProp(raw, 'SortKey') or szSortOrder ~= GetComponentProp(raw, 'SortOrder') then
					SetComponentProp(raw, 'SortKey', szSortKey)
					SetComponentProp(raw, 'SortOrder', szSortOrder)
					GetComponentProp(raw, 'UpdateSorterStatus')()
					GetComponentProp(raw, 'DrawTableContent')()
					X.SafeCall(GetComponentProp(raw, 'OnSortChange'))
				end
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			if GetComponentType(raw) == 'WndTable' then
				return GetComponentProp(raw, 'SortKey'), GetComponentProp(raw, 'SortOrder')
			end
		end
	end
end

-- get/set ui object name
function OO:Name(szText)
	self:_checksum()
	if szText then -- set name
		for _, raw in ipairs(self.raws) do
			raw:SetName(szText)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw and raw.GetName then
			return raw:GetName()
		end
	end
end

-- get/set ui object group
function OO:Group(szText)
	self:_checksum()
	if szText then -- set group
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'group', szText)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'group')
		end
	end
end

-- set ui penetrable
function OO:Penetrable(bPenetrable)
	self:_checksum()
	if X.IsBoolean(bPenetrable) then -- set penetrable
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'bPenetrable', bPenetrable)
			if raw.SetMousePenetrable then
				raw:SetMousePenetrable(bPenetrable)
			end
		end
	else
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'bPenetrable')
		end
	end
	return self
end

-- get/set ui alpha
function OO:Alpha(nAlpha)
	self:_checksum()
	if nAlpha then -- set name
		for _, raw in ipairs(self.raws) do
			raw:SetAlpha(nAlpha)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw and raw.GetAlpha then
			return raw:GetAlpha()
		end
	end
end

-- (self) Instance:FadeTo(nTime, nOpacity, callback)
function OO:FadeTo(nTime, nOpacity, callback)
	self:_checksum()
	if nTime and nOpacity then
		for i, raw in ipairs(self.raws) do
			local ui = self:Eq(i)
			local nStartAlpha = ui:Alpha()
			local nStartTime = GetTime()
			local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
				return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- 线性模型
			end
			if not ui:Visible() then
				ui:Alpha(0):Toggle(true)
			end
			X.BreatheCall(X.NSFormatString('{$NS}_FADE_') .. tostring(ui[1]), function()
				ui:Show()
				local nCurrentAlpha = fnCurrent(nStartAlpha, nOpacity, nTime, GetTime() - nStartTime)
				ui:Alpha(nCurrentAlpha)
				--[[#DEBUG BEGIN]]
				-- X.Debug('fade', string.format('%d %d %d %d\n', nStartAlpha, nOpacity, nCurrentAlpha, (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity)), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				if (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity) <= 0 then
					ui:Alpha(nOpacity)
					if callback then
						X.CallWithThis(raw, callback, ui)
					end
					return 0
				end
			end)
		end
	end
	return self
end

-- (self) Instance:FadeIn(nTime, callback)
function OO:FadeIn(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		self:Eq(i):FadeTo(nTime, GetComponentProp(raw, 'nOpacity') or 255, callback)
	end
	return self
end

-- (self) Instance:FadeOut(nTime, callback)
function OO:FadeOut(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		local ui = self:Eq(i)
		if ui:Alpha() > 0 then
			SetComponentProp(ui, 'nOpacity', ui:Alpha())
		end
	end
	self:FadeTo(nTime, 0, function()
		local ui = UI(this)
		ui:Toggle(false)
		if callback then
			X.CallWithThis(this, callback)
		end
	end)
	return self
end

-- (self) Instance:SlideTo(nTime, nHeight, callback)
function OO:SlideTo(nTime, nHeight, callback)
	self:_checksum()
	if nTime and nHeight then
		for i, raw in ipairs(self.raws) do
			local ui = self:Eq(i)
			local nStartValue = ui:Height()
			local nStartTime = GetTime()
			local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
				return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- 线性模型
			end
			if not ui:Visible() then
				ui:Height(0):Toggle(true)
			end
			X.BreatheCall(function()
				ui:Show()
				local nCurrentValue = fnCurrent(nStartValue, nHeight, nTime, GetTime()-nStartTime)
				ui:Height(nCurrentValue)
				--[[#DEBUG BEGIN]]
				-- X.Debug('slide', string.format('%d %d %d %d\n', nStartValue, nHeight, nCurrentValue, (nStartValue - nCurrentValue)*(nCurrentValue - nHeight)), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				if (nStartValue - nCurrentValue)*(nCurrentValue - nHeight) <= 0 then
					ui:Height(nHeight):Toggle( nHeight ~= 0 )
					if callback then
						X.CallWithThis(raw, callback)
					end
					return 0
				end
			end)
		end
	end
	return self
end

-- (self) Instance:SlideUp(nTime, callback)
function OO:SlideUp(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		local ui = self:Eq(i)
		if ui:Height() > 0 then
			SetComponentProp(ui, 'nSlideTo', ui:Height())
		end
	end
	self:SlideTo(nTime, 0, callback)
	return self
end

-- (self) Instance:SlideDown(nTime, callback)
function OO:SlideDown(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		self:Eq(i):SlideTo(nTime, GetComponentProp(raw, 'nSlideTo'), callback)
	end
	return self
end

-- (number) Instance:Font()
-- (self) Instance:Font(number nFont)
function OO:Font(nFont)
	self:_checksum()
	if nFont then -- set name
		local element
		for _, raw in ipairs(self.raws) do
			element = GetComponentElement(raw, 'TEXT')
			if element then
				element:SetFontScheme(nFont)
			end
			element = GetComponentElement(raw, 'PLACEHOLDER')
			if element then
				local r, g, b = element:GetFontColor()
				element:SetFontScheme(nFont)
				element:SetFontColor(r, g, b)
			end
			element = GetComponentElement(raw, 'EDIT')
			if element then
				element:SetFontScheme(nFont)
				element:SetSelectFontScheme(nFont)
				local r, g, b = element:GetPlaceholderFontColor()
				element:SetPlaceholderFontScheme(nFont)
				element:SetPlaceholderFontColor(r, g, b)
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw and raw.GetFontScheme then
			return raw:GetFontScheme()
		end
	end
end

-- (number, number, number) Instance:Color()
-- (self) Instance:Color(number r, number g, number b)
function OO:Color(r, g, b)
	self:_checksum()
	if X.IsTable(r) then
		r, g, b = unpack(r)
	end
	if b then
		local element
		for _, raw in ipairs(self.raws) do
			element = GetComponentElement(raw, 'SHADOW')
			if element then
				element:SetColorRGB(r, g, b)
			end
			element = GetComponentElement(raw, 'EDIT') or GetComponentElement(raw, 'TEXT')
			if element then
				if raw.IsEnabled and not raw:IsEnabled() then
					element:SetFontColor(r / 2.2, g / 2.2, b / 2.2)
				else
					element:SetFontColor(r, g, b)
				end
			end
		end
		return self
	else
		local raw, element = self.raws[1], nil
		if raw then
			element = GetComponentElement(raw, 'SHADOW')
			if element then
				return element:GetColorRGB()
			end
			element = --[[GetComponentElement(raw, 'EDIT') or ]]GetComponentElement(raw, 'TEXT')
			if element then
				return element:GetFontColor()
			end
		end
	end
end

-- (self) Instance:ColorPick((r: number r, g: number, b: number) => void)
function OO:ColorPick(cb)
	self:_checksum()
	if X.IsFunction(cb) then
		local element
		for _, raw in ipairs(self.raws) do
			local aOnColorPickCBs = GetComponentProp(raw, 'OnColorPickCBs')
			if aOnColorPickCBs then
				table.insert(aOnColorPickCBs, cb)
			end
		end
	else
		self:LClick()
	end
	return self
end

function OO:DrawEclipse(nX, nY, nMajorAxis, nMinorAxis, nR, nG, nB, nA, dwRotate, dwPitch, dwRad, nAccuracy)
	nR, nG, nB, nA = nR or 255, nG or 255, nB or 255, nA or 255
	dwRotate, dwPitch, dwRad = dwRotate or 0, dwPitch or 0, dwRad or (2 * math.pi)
	nAccuracy = nAccuracy or 32
	local deltaRad = (2 * math.pi) / nAccuracy
	local sha, nX1, nY1, nMajorAxis1, nMinorAxis1, dwRad1, dwRad2, nDis
	for _, raw in ipairs(self.raws) do
		sha = GetComponentElement(raw, 'SHADOW')
		if sha then
			dwRad1 = dwPitch
			dwRad2 = dwPitch + dwRad
			nX1 = nX or (sha:GetW() / 2)
			nY1 = nY or (sha:GetH() / 2)
			nMajorAxis1 = nMajorAxis or nX1
			nMinorAxis1 = nMinorAxis or nY1
			sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			sha:SetD3DPT(D3DPT.TRIANGLEFAN)
			sha:ClearTriangleFanPoint()
			sha:AppendTriangleFanPoint(nX ,nY, nR, nG, nB, nA)
			sha:Show()
			repeat
				nDis = nMajorAxis * nMinorAxis / math.sqrt(math.pow(nMinorAxis * math.cos(dwRad1 - dwRotate), 2) + math.pow(nMajorAxis * math.sin(dwRad1 - dwRotate), 2))
				sha:AppendTriangleFanPoint(
					nX + nDis * math.cos(dwRad1),
					nY - nDis * math.sin(dwRad1),
					nR, nG, nB, nA
				)
				-- sha:AppendTriangleFanPoint(
				-- 	nX + (nMajorAxis * math.cos(dwRotate) * math.cos(dwRad1 - dwRotate) - nMinorAxis * math.sin(dwRotate) * math.sin(dwRad1 - dwRotate)),
				-- 	nY - (nMinorAxis * math.cos(dwRotate) * math.sin(dwRad1 - dwRotate) + nMajorAxis * math.sin(dwRotate) * math.cos(dwRad1 - dwRotate)),
				-- 	nR, nG, nB, nA
				-- )
				dwRad1 = (dwRad1 < dwRad2 and dwRad1 + deltaRad > dwRad2) and dwRad2 or (dwRad1 + deltaRad)
			until dwRad1 > dwRad2
		end
	end
	return self
end

function OO:DrawCircle(nX, nY, nRadius, nR, nG, nB, nA, dwPitch, dwRad, nAccuracy)
	nR, nG, nB, nA = nR or 255, nG or 255, nB or 255, nA or 255
	dwPitch, dwRad = dwPitch or 0, dwRad or (2 * math.pi)
	nAccuracy = nAccuracy or 32
	local deltaRad = (2 * math.pi) / nAccuracy
	local sha, nX1, nY1, nRadius1, dwRad1, dwRad2
	for _, raw in ipairs(self.raws) do
		sha = GetComponentElement(raw, 'SHADOW')
		if sha then
			dwRad1 = dwPitch
			dwRad2 = dwPitch + dwRad
			nX1 = nX or (sha:GetW() / 2)
			nY1 = nY or (sha:GetH() / 2)
			nRadius1 = nRadius or math.min(nX1, nY1)
			sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			sha:SetD3DPT(D3DPT.TRIANGLEFAN)
			sha:ClearTriangleFanPoint()
			sha:AppendTriangleFanPoint(nX1, nY1, nR, nG, nB, nA)
			sha:Show()
			repeat
				sha:AppendTriangleFanPoint(nX1 + math.cos(dwRad1) * nRadius1, nY1 - math.sin(dwRad1) * nRadius1, nR, nG, nB, nA)
				dwRad1 = (dwRad1 < dwRad2 and dwRad1 + deltaRad > dwRad2) and dwRad2 or (dwRad1 + deltaRad)
			until dwRad1 > dwRad2
		end
	end
	return self
end

function OO:DrawGwText(szText, nX ,nY, nZ, nR, nG, nB, nA, nFont, fFontScale, fSpacing, aDelta)
	local sha
	for _, raw in ipairs(self.raws) do
		sha = GetComponentElement(raw, 'SHADOW')
		if sha then
			sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
			sha:ClearTriangleFanPoint()
			sha:AppendTriangleFan3DPoint(
				nX ,nY, nZ,
				nR or 255, nG or 255, nB or 255, nA or 255,
				aDelta or 0, -- fYDelta | {fXDelta, fYDelta, fZDelta, fScreenXDelta, fScreenYDelta}
				nFont or 40,
				szText,
				fSpacing or 0,
				fFontScale or 1
			)
			sha:Show()
		end
	end
	return self
end

function OO:DrawGwCircle(nX, nY, nZ, nRadius, nR, nG, nB, nA, dwPitch, dwRad)
	nRadius, dwPitch, dwRad = nRadius or (64 * 3), dwPitch or 0, dwRad or (2 * math.pi)
	nR, nG, nB, nA = nR or 255, nG or 255, nB or 255, nA or 120
	local sha, dwRad1, dwRad2, nSceneX, nSceneZ, nSceneXD, nSceneZD
	for _, raw in ipairs(self.raws) do
		sha = GetComponentElement(raw, 'SHADOW')
		if sha then
			dwRad1, dwRad2 = dwPitch, dwPitch + dwRad * 1.05 -- 稍微大点 不然整个圈的时候会有个缝
			sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			sha:SetD3DPT(D3DPT.TRIANGLEFAN)
			sha:ClearTriangleFanPoint()
			sha:AppendTriangleFan3DPoint(nX ,nY, nZ, nR, nG, nB, nA)
			sha:Show()
			nSceneX, nSceneZ, nSceneXD, nSceneZD = Scene_PlaneGameWorldPosToScene(nX, nY)
			repeat
				nSceneXD, nSceneZD = Scene_PlaneGameWorldPosToScene(nX + math.cos(dwRad1) * nRadius, nY + math.sin(dwRad1) * nRadius)
				sha:AppendTriangleFan3DPoint(nX ,nY, nZ, nR, nG, nB, nA, { nSceneXD - nSceneX, 0, nSceneZD - nSceneZ })
				dwRad1 = dwRad1 + math.pi / 16
			until dwRad1 > dwRad2
		end
	end
	return self
end

-- (number) Instance:Left()
-- (self) Instance:Left(number)
function OO:Left(nLeft)
	if nLeft then
		return self:Pos(nLeft, nil)
	else
		local l, t = self:Pos()
		return l
	end
end

-- (number) Instance:Top()
-- (self) Instance:Top(number)
function OO:Top(nTop)
	if nTop then
		return self:Pos(nil, nTop)
	else
		local l, t = self:Pos()
		return t
	end
end

-- (number, number) Instance:Pos()
-- (self) Instance:Pos(nLeft, nTop)
function OO:Pos(nLeft, nTop)
	self:_checksum()
	if X.IsNumber(nLeft) or X.IsNumber(nTop) then
		for _, raw in ipairs(self.raws) do
			local nLeft, nTop = nLeft or raw:GetRelX(), nTop or raw:GetRelY()
			raw:SetRelPos(nLeft, nTop)
			if raw:GetBaseType() == 'Item' then
				raw = raw:GetParent()
				if raw and raw:GetType() == 'Handle' then
					raw:FormatAllItemPos()
				end
			end
		end
		return self
	else
		local szType = 'TOPLEFT'
		if X.IsString(nLeft) then
			szType = nLeft
		end
		local raw = self.raws[1]
		if raw and raw.GetRelPos then
			local nX, nY = raw:GetRelPos()
			if szType == 'TOPRIGHT' or szType == 'BOTTOMRIGHT' then
				nX = nX + self:Width()
			end
			if szType == 'BOTTOMLEFT' or szType == 'BOTTOMRIGHT' then
				nY = nY + self:Height()
			end
			return nX, nY
		end
	end
end

-- (self) Instance:Shake(xrange, yrange, maxspeed, time)
function OO:Shake(xrange, yrange, maxspeed, time)
	self:_checksum()
	if xrange and yrange and maxspeed and time then
		local starttime = GetTime()
		local xspeed, yspeed = maxspeed, - maxspeed
		local xhalfrange, yhalfrange = xrange / 2, yrange / 2
		for _, raw in ipairs(self.raws) do
			local ui = UI(raw)
			local xoffset, yoffset = 0, 0
			X.RenderCall(tostring(raw) .. ' shake', function()
				if ui:Count() == 0 then
					return 0
				elseif GetTime() - starttime < time then
					local x, y = ui:Pos()
					x, y = x - xoffset, y - yoffset

					xoffset = xoffset + math.random(xspeed > 0 and 0 or xspeed, xspeed > 0 and xspeed or 0)
					if xoffset < - xhalfrange then
						xoffset = math.min(- xrange - xoffset, xhalfrange)
						xspeed = - xspeed
					elseif xoffset > xhalfrange then
						xoffset = math.max(xrange - xoffset, - xhalfrange)
						xspeed = - xspeed
					end

					yoffset = yoffset + math.random(yspeed > 0 and 0 or yspeed, yspeed > 0 and yspeed or 0)
					if yoffset < - yhalfrange then
						yoffset =  math.min(- yrange - yoffset, yhalfrange)
						yspeed = - yspeed
					elseif yoffset > yhalfrange then
						yoffset = math.max(yrange - yoffset, - yhalfrange)
						yspeed = - yspeed
					end

					ui:Pos(x + xoffset, y + yoffset)
				else
					local x, y = ui:Pos()
					ui:Pos(x - xoffset, y - yoffset)
					return 0
				end
			end)
		end
	else
		for _, raw in ipairs(self.raws) do
			X.RenderCall(tostring(raw) .. ' shake', false)
		end
	end
end

-- (anchor) Instance:Anchor()
-- (self) Instance:Anchor(anchor)
do
local CENTER = { s = 'CENTER', r = 'CENTER',  x = 0, y = 0 } -- szSide, szRelSide, fOffsetX, fOffsetY
function OO:Anchor(anchor)
	self:_checksum()
	if anchor == 'CENTER' then
		anchor = CENTER
	end
	if X.IsTable(anchor) then
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				raw:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
				raw:CorrectPos()
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw and raw:GetType() == 'WndFrame' then
			return GetFrameAnchor(raw, anchor)
		end
	end
end
end

-- (number) Instance:Width()
-- (self) Instance:Width(number[, number])
function OO:Width(nWidth, nRawWidth)
	if nWidth then
		return self:Size(nWidth, nil, nRawWidth, nil)
	else
		local w, h, rw, rh = self:Size()
		return w, rw
	end
end

-- (number) Instance:Height()
-- (self) Instance:Height(number[, number])
function OO:Height(nHeight, nRawHeight)
	if nHeight then
		return self:Size(nil, nHeight, nil, nRawHeight)
	else
		local w, h, rw, rh = self:Size()
		return h, rh
	end
end

local function SetComponentSize(raw, nOuterWidth, nOuterHeight, nInnerWidth, nInnerHeight)
	local nWidth, nHeight = nOuterWidth, nOuterHeight
	local nMinWidth = GetComponentProp(raw, 'minWidth')
	local nMinHeight = GetComponentProp(raw, 'minHeight')
	if nMinWidth and nWidth < nMinWidth then
		nWidth = nMinWidth
	end
	if nMinHeight and nHeight < nMinHeight then
		nHeight = nMinHeight
	end
	local componentType = GetComponentType(raw)
	if componentType == 'WndFrame' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hnd = raw:Lookup('', '')
		-- 处理窗口背景自适应缩放
		local imgBgTLConner = hnd:Lookup('Image_BgTL_Conner')
		local imgBgTRConner = hnd:Lookup('Image_BgTR_Conner')
		local imgBgTLFlex = hnd:Lookup('Image_BgTL_Flex')
		local imgBgTRFlex = hnd:Lookup('Image_BgTR_Flex')
		local imgBgTLCenter = hnd:Lookup('Image_BgTL_Center')
		local imgBgTRCenter = hnd:Lookup('Image_BgTR_Center')
		local imgBgBL = hnd:Lookup('Image_BgBL')
		local imgBgBC = hnd:Lookup('Image_BgBC')
		local imgBgBR = hnd:Lookup('Image_BgBR')
		local imgBgCL = hnd:Lookup('Image_BgCL')
		local imgBgCC = hnd:Lookup('Image_BgCC')
		local imgBgCR = hnd:Lookup('Image_BgCR')
		if imgBgTLConner and imgBgTLFlex and imgBgTLCenter
		and imgBgTRConner and imgBgTRFlex and imgBgTRCenter
		and imgBgBL and imgBgBC and imgBgBR and imgBgCL and imgBgCC and imgBgCR then
			local fScale = nWidth < 426 and (nWidth / 426) or 1
			local nTH = 70 * fScale
			local nTConnerW = 213 * fScale
			imgBgTLConner:SetSize(nTConnerW, nTH)
			imgBgTRConner:SetSize(nTConnerW, nTH)
			local nTFlexW = math.max(0, (nWidth - (nWidth >= 674 and 674 or 426)) / 2)
			imgBgTLFlex:SetSize(nTFlexW, nTH)
			imgBgTRFlex:SetSize(nTFlexW, nTH)
			local nTCenterW = nWidth >= 674 and (124 * fScale) or 0
			imgBgTLCenter:SetSize(nTCenterW, nTH)
			imgBgTRCenter:SetSize(nTCenterW, nTH)
			local nBLW, nBRW = math.ceil(124 * fScale), math.ceil(8 * fScale)
			local nBCW, nBH = nWidth - nBLW - nBRW + 1, 85 * fScale -- 不知道为什么差一像素 但是加上就好了
			imgBgBL:SetSize(nBLW, nBH)
			imgBgBC:SetSize(nBCW, nBH)
			imgBgBR:SetSize(nBRW, nBH)
			local nCEdgeW = math.ceil(8 * fScale)
			local nCCW, nCH = nWidth - 2 * nCEdgeW + 1, nHeight - nTH - nBH -- 不知道为什么差一像素 但是加上就好了
			imgBgCL:SetSize(nCEdgeW, nCH)
			imgBgCC:SetSize(nCCW, nCH)
			imgBgCR:SetSize(nCEdgeW, nCH)
			imgBgCL:SetRelY(nTH)
			imgBgBL:SetRelY(nTH + nCH)
			hnd:FormatAllItemPos()
		end
		-- 按分类处理其他
		if GetComponentProp(raw, 'simple') then
			local nWidthTitleBtnR = 0
			local p = raw:Lookup('WndContainer_TitleBtnR'):GetFirstChild()
			while p do
				nWidthTitleBtnR = nWidthTitleBtnR + (p:GetSize())
				p = p:GetNext()
			end
			raw:Lookup('', 'Text_Title'):SetSize(nWidth - nWidthTitleBtnR, 30)
			raw:Lookup('', 'Image_Title'):SetSize(nWidth, 30)
			raw:Lookup('', 'Shadow_Bg'):SetSize(nWidth, nHeight)
			raw:Lookup('WndContainer_TitleBtnR'):SetSize(nWidth, 30)
			raw:Lookup('WndContainer_TitleBtnR'):FormatAllContentPos()
			raw:Lookup('Btn_Drag'):SetRelPos(nWidth - 16, nHeight - 16)
			raw:SetSize(nWidth, nHeight)
			raw:SetDragArea(0, 0, nWidth, 30)
			hnd:SetSize(nWidth, nHeight)
			wnd:SetSize(nWidth, nHeight - 30)
		elseif GetComponentProp(raw, 'intact') or raw == X.GetFrame() then
			hnd:SetSize(nWidth, nHeight)
			hnd:Lookup('Text_Title'):SetW(nWidth - 90)
			hnd:Lookup('Text_Author'):SetW(nWidth - 31)
			hnd:Lookup('Text_Author'):SetRelY(nHeight - 41)
			-- 处理窗口其它组件
			local btnClose = raw:Lookup('Btn_Close')
			if btnClose then
				btnClose:SetRelPos(nWidth - 35, 15)
			end
			local btnDrag = raw:Lookup('Btn_Drag')
			if btnDrag then
				btnDrag:SetRelPos(nWidth - 18, nHeight - 20)
			end
			local btnMax = raw:Lookup('CheckBox_Maximize')
			if btnMax then
				btnMax:SetRelPos(nWidth - 63, 15)
			end
			if wnd then
				wnd:SetSize(nWidth, nHeight)
				wnd:Lookup('', ''):SetSize(nWidth, nHeight)
			end
			raw:SetSize(nWidth, nHeight)
			raw:SetDragArea(0, 0, nWidth, 55)
			-- reset position
			local an = GetFrameAnchor(raw)
			raw:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
		else
			raw:SetSize(nWidth, nHeight)
			hnd:SetSize(nWidth, nHeight)
		end
	elseif componentType == 'WndButton' or componentType == 'WndButtonBox' then
		local btn = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		local nMarginTop, nMarginRight, nMarginBottom, nMarginLeft = 0, 0, 0, 0 -- 按钮外部边距
		local nPaddingTop, nPaddingRight, nPaddingBottom, nPaddingLeft = 0, 0, 0, 0 -- 按钮内部边距
		local eStyle = GetButtonStyleName(btn)
		local tStyle = GetButtonStyleConfig(eStyle)
		if tStyle then
			nMarginTop = tStyle.nMarginTop or 0
			nMarginRight = tStyle.nMarginRight or 0
			nMarginBottom = tStyle.nMarginBottom or 0
			nMarginLeft = tStyle.nMarginLeft or 0
			nPaddingTop = tStyle.nPaddingTop or 0
			nPaddingRight = tStyle.nPaddingRight or 0
			nPaddingBottom = tStyle.nPaddingBottom or 0
			nPaddingLeft = tStyle.nPaddingLeft or 0
			local fScaleX = nWidth / (tStyle.nWidth + nMarginRight + nMarginLeft + nPaddingRight + nPaddingLeft)
			local fScaleY = nHeight / (tStyle.nHeight + nMarginTop + nMarginBottom + nPaddingTop + nPaddingBottom)
			nMarginTop = nMarginTop * fScaleY
			nMarginRight = nMarginRight * fScaleX
			nMarginBottom = nMarginBottom * fScaleY
			nMarginLeft = nMarginLeft * fScaleX
			nPaddingTop = nPaddingTop * fScaleY
			nPaddingRight = nPaddingRight * fScaleX
			nPaddingBottom = nPaddingBottom * fScaleY
			nPaddingLeft = nPaddingLeft * fScaleX
		end
		if componentType == 'WndButtonBox' then
			raw:SetSize(nWidth, nHeight)
			btn:SetRelPos(nMarginLeft, nMarginTop)
		end
		btn:SetSize(nWidth - nMarginLeft - nMarginRight, nHeight - nMarginTop - nMarginBottom)
		if hdl then
			if not txt then
				for i = 0, hdl:GetItemCount() - 1 do
					txt = hdl:Lookup(i)
					if txt:GetType() == 'Text' then
						break
					end
					txt = nil
				end
			end
			hdl:SetRelPos(-nMarginLeft, -nMarginTop)
			hdl:SetAbsPos(btn:GetAbsX() - nMarginLeft, btn:GetAbsY() - nMarginTop) -- 这个 Wnd 的直接 Handle 坐标不刷新问题两年前就报了，没人修，妈的。
			hdl:SetSize(nWidth, nHeight)
			hdl:FormatAllItemPos()
		end
		if txt then
			txt:SetRelPos(nMarginLeft + nPaddingLeft, nMarginTop + nPaddingTop)
			txt:SetSize(nWidth - nMarginLeft - nPaddingLeft - nMarginRight - nPaddingRight, nHeight - nMarginTop - nPaddingTop - nMarginBottom - nPaddingBottom)
			txt:GetParent():FormatAllItemPos()
		end
	elseif componentType == 'WndCheckBox' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		wnd:SetSize(nHeight, nHeight)
		txt:SetSize(nWidth - nHeight - 1, nHeight)
		txt:SetRelPos(nHeight + 1, 0)
		hdl:SetSize(nWidth, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'CheckBox' then
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local img = GetComponentElement(raw, 'IMAGE')
		local txt = GetComponentElement(raw, 'TEXT')
		img:SetSize(nHeight, nHeight)
		txt:SetSize(nWidth - nHeight - 1, nHeight)
		txt:SetRelPos(nHeight + 1, 0)
		hdl:SetSize(nWidth, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'ColorBox' then
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local sha = GetComponentElement(raw, 'SHADOW')
		local txt = GetComponentElement(raw, 'TEXT')
		local inner = GetComponentElement(raw, 'INNER_RAW')
		if not nInnerWidth then
			nInnerWidth = nHeight
		end
		if not nInnerHeight then
			nInnerHeight = nHeight
		end
		local nGap = math.min(nInnerWidth * 0.3, 8)
		nWidth = math.max(nWidth, nInnerWidth + nGap)
		sha:SetSize(nInnerWidth, nInnerHeight)
		sha:SetRelPos(0, (nHeight - nInnerHeight) / 2)
		txt:SetSize(nWidth - nInnerWidth - nGap, nHeight)
		txt:SetRelPos(nInnerWidth + nGap, 0)
		hdl:SetSize(nWidth, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'WndComboBox' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local cmb = GetComponentElement(raw, 'COMBOBOX')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		local img = GetComponentElement(raw, 'IMAGE')
		local W, H = wnd:GetSize()
		local nDeltaW, nDeltaH = nWidth - W, nHeight - H
		local w, h = cmb:GetSize()
		cmb:SetRelPos(cmb:GetRelX() + nDeltaW, cmb:GetRelY() + nDeltaH / 2)
		cmb:Lookup('', ''):SetAbsPos(hdl:GetAbsPos())
		cmb:Lookup('', ''):SetSize(nWidth, nHeight)
		wnd:SetSize(nWidth, nHeight)
		hdl:SetSize(nWidth, nHeight)
		img:SetSize(nWidth, nHeight)
		txt:SetSize(txt:GetW() + nDeltaW, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'WndEditComboBox' or componentType == 'WndAutocomplete' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local cmb = GetComponentElement(raw, 'COMBOBOX')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local img = GetComponentElement(raw, 'IMAGE')
		local edt = GetComponentElement(raw, 'EDIT')
		wnd:SetSize(nWidth, nHeight)
		hdl:SetSize(nWidth, nHeight)
		img:SetSize(nWidth, nHeight)
		hdl:FormatAllItemPos()
		local w, h = cmb:GetSize()
		edt:SetSize(nWidth - 10 - w, nHeight - 4)
		cmb:SetRelPos(nWidth - w - 5, (nHeight - h - 1) / 2 + 1)
	elseif componentType == 'WndRadioBox' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		wnd:SetSize(nHeight, nHeight)
		txt:SetSize(nWidth - nHeight - 1, nHeight)
		txt:SetRelPos(nHeight + 1, 0)
		hdl:SetSize(nWidth, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'WndEditBox' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local img = GetComponentElement(raw, 'IMAGE')
		local edt = GetComponentElement(raw, 'EDIT')
		local szStyle = GetComponentProp(raw, 'szAppearance')
		local tStyle = EDIT_BOX_APPEARANCE_CONFIG[szStyle] or EDIT_BOX_APPEARANCE_CONFIG['DEFAULT']
		local ico = hdl:Lookup('Image_Icon')
		wnd:SetSize(nWidth, nHeight)
		hdl:SetSize(nWidth, nHeight)
		img:SetSize(nWidth, nHeight)
		if tStyle.szIconImage then
			local nIconW, nIconH = tStyle.nIconWidth, tStyle.nIconHeight
			if nIconH > nHeight then
				nIconW = nIconW * nHeight / nIconH
				nIconH = nHeight
			end
			ico:Show()
			ico:FromUITex(tStyle.szIconImage, tStyle.nIconImageFrame)
			ico:SetAlpha(tStyle.nIconAlpha or 255)
			ico:SetSize(nIconW, nIconH)
			if tStyle.szIconAlign == 'LEFT' then
				ico:SetRelX(0)
				edt:SetRelX(nIconW)
			else
				ico:SetRelX(nWidth - nIconW)
				edt:SetRelX(4)
			end
			ico:SetRelY((nHeight - nIconH) / 2)
			edt:SetSize(nWidth - 4 - nIconW, nHeight - 4)
		else
			ico:Hide()
			edt:SetRelX(4)
			edt:SetSize(nWidth - 8, nHeight - 4)
		end
		hdl:FormatAllItemPos()
	elseif componentType == 'Text' then
		local txt = GetComponentElement(raw, 'TEXT')
		txt:SetSize(nWidth, nHeight)
		txt:GetParent():FormatAllItemPos()
		SetComponentProp(raw, 'bAutoSize', false)
	elseif componentType == 'WndListBox' then
		raw:SetSize(nWidth, nHeight)
		raw:Lookup('Scroll_Default'):SetRelPos(nWidth - 15, 10)
		raw:Lookup('Scroll_Default'):SetSize(15, nHeight - 20)
		raw:Lookup('', ''):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Image_Default'):SetSize(nWidth, nHeight)
		local hList = raw:Lookup('', 'Handle_Scroll')
		hList:SetSize(nWidth - 20, nHeight - 20)
		for i = hList:GetItemCount() - 1, 0, -1 do
			local hItem = hList:Lookup(i)
			hItem:Lookup('Image_Bg'):SetSize(nWidth - 20, 25)
			hItem:Lookup('Image_Sel'):SetSize(nWidth - 20, 25)
			hItem:Lookup('Text_Default'):SetSize(nWidth - 20, 25)
			hItem:FormatAllItemPos()
		end
		hList:FormatAllItemPos()
	elseif componentType == 'WndScrollHandleBox' then
		raw:SetSize(nWidth, nHeight)
		raw:Lookup('', ''):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Image_Default'):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Handle_Padding'):SetSize(nWidth - 30, nHeight - 20)
		raw:Lookup('', 'Handle_Padding/Handle_Scroll'):SetSize(nWidth - 30, nHeight - 20)
		raw:Lookup('', 'Handle_Padding/Handle_Scroll'):FormatAllItemPos()
		raw:Lookup('WndScrollBar'):SetRelX(nWidth - 20)
		raw:Lookup('WndScrollBar'):SetH(nHeight - 20)
	elseif componentType == 'WndScrollWindowBox' then
		raw:SetSize(nWidth, nHeight)
		raw:Lookup('', ''):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Image_Default'):SetSize(nWidth, nHeight)
		raw:Lookup('WndContainer_Scroll'):SetSize(nWidth - 30, nHeight - 20)
		raw:Lookup('WndContainer_Scroll'):FormatAllContentPos()
		raw:Lookup('WndScrollBar'):SetRelX(nWidth - 20)
		raw:Lookup('WndScrollBar'):SetH(nHeight - 20)
	elseif componentType == 'WndTrackbar' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local sld = GetComponentElement(raw, 'TRACKBAR')
		local txt = GetComponentElement(raw, 'TEXT')
		local nWidth = nOuterWidth or math.max(nWidth, (nInnerWidth or 0) + 5)
		local nHeight = nOuterHeight or math.max(nHeight, (nInnerHeight or 0) + 5)
		local nRawWidth = math.min(nWidth, nInnerWidth or sld:GetW())
		local nRawHeight = math.min(nHeight, nInnerHeight or sld:GetH())
		wnd:SetSize(nWidth, nHeight)
		sld:SetSize(nRawWidth, nRawHeight)
		local nBtnWidth = math.min(34, nRawWidth * 0.6)
		sld:Lookup('Btn_Track'):SetSize(nBtnWidth, nRawHeight)
		sld:Lookup('Btn_Track'):SetRelX((nRawWidth - nBtnWidth) * sld:GetScrollPos() / sld:GetStepCount())
		hdl:SetSize(nWidth, nHeight)
		hdl:Lookup('Image_BG'):SetSize(nRawWidth, nRawHeight - 2)
		txt:SetRelX(nRawWidth + 5)
		txt:SetSize(nWidth - nRawWidth - 5, nHeight)
		hdl:FormatAllItemPos()
	elseif componentType == 'WndTable' then
		raw:SetSize(nWidth, nHeight)
		GetComponentProp(raw, 'UpdateTableRect')()
	elseif raw:GetBaseType() == 'Wnd' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		local img = GetComponentElement(raw, 'IMAGE')
		local edt = GetComponentElement(raw, 'EDIT')
		if wnd then wnd:SetSize(nWidth, nHeight) end
		if hdl then hdl:SetSize(nWidth, nHeight) end
		if txt then txt:SetSize(nWidth, nHeight) end
		if img then img:SetSize(nWidth, nHeight) end
		if edt then edt:SetSize(nWidth - 8, nHeight - 4) end
		if hdl then hdl:FormatAllItemPos() end
	else
		local itm = GetComponentElement(raw, 'ITEM') or raw
		itm:SetSize(nWidth, nHeight)
		local h = itm:GetParent()
		if h and h:GetType() == 'Handle' then
			h:FormatAllItemPos()
		end
	end
	X.ExecuteWithThis(raw, raw.OnSizeChanged)
end

-- (number, number) Instance:Size(bInnerSize)
-- (self) Instance:Size(nLeft, nTop)
-- (self) Instance:Size(OnSizeChanged)
function OO:Size(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local arg0, arg1, arg2, arg3 = ...
		if X.IsFunction(arg0) then
			for _, raw in ipairs(self.raws) do
				UI(raw):UIEvent('OnSizeChanged', arg0)
			end
		else
			local nWidth, nHeight = arg0, arg1
			local nRawWidth, nRawHeight = arg2, arg3
			local bAutoWidth = nWidth == 'auto'
			local bAutoHeight = nHeight == 'auto'
			if bAutoWidth then
				nWidth = nil
			end
			if bAutoHeight then
				nHeight = nil
			end
			if X.IsNumber(nWidth) or X.IsNumber(nHeight) or X.IsNumber(nRawWidth) or X.IsNumber(nRawHeight) then
				for _, raw in ipairs(self.raws) do
					SetComponentSize(raw, nWidth or raw:GetW(), nHeight or raw:GetH(), nRawWidth, nRawHeight)
				end
			end
			if bAutoWidth and bAutoHeight then
				self:AutoSize()
			elseif bAutoWidth then
				self:AutoWidth()
			elseif bAutoHeight then
				self:AutoHeight()
			end
		end
		return self
	else
		local raw, w, h, rw, rh = self.raws[1], nil, nil, nil, nil
		if raw then
			if arg0 == true then
				raw = GetComponentElement(raw, 'MAIN_WINDOW') or raw
			end
			if raw.IsDummyWnd and raw:IsDummyWnd() then
				raw = raw:Lookup('', '') or raw
			end
			if raw.GetSize then
				w, h = raw:GetSize()
			end
			raw = GetComponentElement(raw, 'INNER_RAW')
			if raw then
				rw, rh = raw:GetSize()
			end
		end
		return w, h, rw, rh
	end
end

-- (self) Instance:MinSize() -- Get element min size
-- (self) Instance:MinSize(number nW, number nH) -- Set element min size
function OO:MinSize(nW, nH)
	self:_checksum()
	if X.IsNumber(nW) or X.IsNumber(nH) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minWidth', nW)
			SetComponentProp(raw, 'minHeight', nH)
		end
		return self
	elseif X.IsNumber(nW) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minWidth', nW)
		end
		return self
	elseif X.IsNumber(nH) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minHeight', nH)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'minWidth'), GetComponentProp(raw, 'minHeight')
		end
	end
end

-- (self) Instance:MinWidth() -- Get element min width
-- (self) Instance:MinWidth(number nW) -- Set element min width
function OO:MinWidth(nW)
	self:_checksum()
	if X.IsNumber(nW) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minWidth', nW)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'minWidth')
		end
	end
end

-- (self) Instance:MinHeight() -- Get element min height
-- (self) Instance:MinHeight(number nH) -- Set element min height
function OO:MinHeight(nH)
	self:_checksum()
	if X.IsNumber(nH) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minHeight', nH)
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'minHeight')
		end
	end
end

do
local function AutoSize(raw, bAutoWidth, bAutoHeight)
	if GetComponentType(raw) == 'Text' then
		local w, h = raw:GetSize()
		raw:AutoSize()
		if not bAutoWidth then
			raw:SetW(w)
		end
		if not bAutoHeight then
			raw:SetH(h)
		end
	else
		local componentType = GetComponentType(raw)
		if componentType == 'WndCheckBox'
		or componentType == 'WndRadioBox'
		or componentType == 'WndComboBox'
		or componentType == 'WndTrackbar'
		or componentType == 'CheckBox'
		or componentType == 'ColorBox' then
			local bWillAffectRaw = componentType == 'WndCheckBox'
				or componentType == 'WndRadioBox'
				or componentType == 'WndComboBox'
			local txt = GetComponentElement(raw, 'TEXT')
			if txt then
				local ui = UI(raw)
				local W, H, RW, RH = ui:Size()
				local oW, oH = txt:GetSize()
				txt:SetSize(1000, 1000)
				txt:AutoSize()
				local deltaW = txt:GetW() - oW
				local deltaH = txt:GetH() - oH
				if bAutoWidth then
					if RW and bWillAffectRaw then
						RW = RW + deltaW
					end
					W = W + deltaW
				end
				if bAutoHeight then
					if RH and bWillAffectRaw then
						RH = RH + deltaH
					end
					H = H + deltaH
				end
				txt:SetSize(oW, oH)
				ui:Size(W, H, RW, RH)
			end
		end
	end
end

-- Auto set width of element by text
-- (self) Instance:AutoWidth()
function OO:AutoWidth()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		AutoSize(raw, true, false)
	end
	return self
end

-- Auto set height of element by text
-- (self) Instance:AutoHeight()
function OO:AutoHeight()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		AutoSize(raw, false, true)
	end
	return self
end

-- (self) Instance:AutoSize() -- resize Text element by autoSize
-- (self) Instance:AutoSize(bool bAutoSize) -- set if Text is autoSize
function OO:AutoSize(arg0, arg1)
	self:_checksum()
	if X.IsNil(arg0) then
		for _, raw in ipairs(self.raws) do
			AutoSize(raw, true, true)
		end
	elseif X.IsBoolean(arg0) then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'Text' then
				raw.bAutoSize = arg0
			end
		end
	end
	return self
end
end

-- (number) Instance:FontScale()
-- (self) Instance:FontScale(bool nScale)
function OO:FontScale(nScale)
	self:_checksum()
	if X.IsNumber(nScale) then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'TEXT')
			if raw then
				raw:SetFontScale(nScale)
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'TEXT')
			if raw then
				return raw:GetFontScale()
			end
		end
	end
end

-- (number) Instance:Scroll() -- get current scroll percentage (none scroll will return -1)
-- (self) Instance:Scroll(number nPercentage) -- set scroll percentage
-- (self) Instance:Scroll(function OnScrollBarPosChanged) -- bind scroll event handle
function OO:Scroll(mixed)
	self:_checksum()
	if mixed then -- set
		if X.IsNumber(mixed) then
			for _, raw in ipairs(self.raws) do
				raw = raw:Lookup('WndScrollBar')
				if raw and raw.GetStepCount and raw.SetScrollPos then
					raw:SetScrollPos(raw:GetStepCount() * mixed / 100)
				end
			end
		elseif X.IsFunction(mixed) then
			for _, raw in ipairs(self.raws) do
				local raw = raw:Lookup('WndScrollBar')
				if raw then
					UI(raw):UIEvent('OnScrollBarPosChanged', function()
						local nDistance = Station.GetMessageWheelDelta()
						local nScrollPos = raw:GetScrollPos()
						local nStepCount = raw:GetStepCount()
						if nStepCount == 0 then
							mixed(-1, nDistance)
						else
							mixed(nScrollPos * 100 / nStepCount, nDistance)
						end
					end)
				end
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			raw = raw:Lookup('WndScrollBar')
			if raw and raw.GetStepCount and raw.GetScrollPos then
				if raw:GetStepCount() == 0 then
					return -1
				else
					return raw:GetScrollPos() * 100 / raw:GetStepCount()
				end
			end
		end
	end
end

-- (number, number) Instance:Range()
-- (self) Instance:Range(nMin, nMax, nStep)
function OO:Range(nMin, nMax, nStep)
	self:_checksum()
	if X.IsNumber(nMin) and X.IsNumber(nMax) and nMax > nMin then
		nStep = nStep or nMax - nMin
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTrackbar' then
				SetComponentProp(raw, 'nTrackbarMin', nMin)
				SetComponentProp(raw, 'nTrackbarMax', nMax)
				SetComponentProp(raw, 'nTrackbarStep', nStep)
				SetComponentProp(raw, 'nTrackbarStepVal', (nMax - nMin) / nStep)
				GetComponentElement(raw, 'TRACKBAR'):SetStepCount(nStep)
				GetComponentProp(raw, 'ResponseUpdateScroll')(true)
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw and GetComponentType(raw) == 'WndTrackbar' then
			nMin = GetComponentProp(raw, 'nTrackbarMin')
			nMax = GetComponentProp(raw, 'nTrackbarMax')
			return nMin, nMax
		end
	end
end

-- (number, number) Instance:Value()
-- (self) Instance:Value(nValue)
function OO:Value(nValue)
	self:_checksum()
	if nValue then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTrackbar' then
				local nMin = GetComponentProp(raw, 'nTrackbarMin')
				local nStepVal = GetComponentProp(raw, 'nTrackbarStepVal')
				GetComponentElement(raw, 'TRACKBAR'):SetScrollPos((nValue - nMin) / nStepVal)
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw and GetComponentType(raw) == 'WndTrackbar' then
			local nMin = GetComponentProp(raw, 'nTrackbarMin')
			local nStepVal = GetComponentProp(raw, 'nTrackbarStepVal')
			return nMin + GetComponentElement(raw, 'TRACKBAR'):GetScrollPos() * nStepVal
		end
	end
end


-- (boolean) Instance:Multiline()
-- (self) Instance:Multiline(bMultiLine)
function OO:Multiline(bMultiLine)
	self:_checksum()
	if X.IsBoolean(bMultiLine) then
		local element
		for _, raw in ipairs(self.raws) do
			element = GetComponentElement(raw, 'EDIT')
			if element then
				element:SetMultiLine(bMultiLine)
			end
			element = GetComponentElement(raw, 'TEXT')
			if element then
				element:SetMultiLine(bMultiLine)
				element:GetParent():FormatAllItemPos()
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'EDIT') or GetComponentElement(raw, 'TEXT')
			if raw then
				return raw:IsMultiLine()
			end
		end
	end
end

-- (self) Instance:Image(szImageAndFrame)
-- (self) Instance:Image(szImage, nFrame)
function OO:Image(szImage, nFrame, nOverFrame, nDownFrame, nDisableFrame)
	self:_checksum()
	if X.IsString(szImage) and X.IsNil(nFrame) then
		nFrame = tonumber((string.gsub(szImage, '.*%|(%d+)', '%1')))
		szImage = string.gsub(szImage, '%|.*', '')
	end
	if X.IsString(szImage) then
		szImage = wstring.gsub(szImage, '/', '\\')
		if X.IsNumber(nFrame) and X.IsNumber(nOverFrame) and X.IsNumber(nDownFrame) and X.IsNumber(nDisableFrame) then
			for _, raw in ipairs(self.raws) do
				raw = GetComponentElement(raw, 'BUTTON')
				if raw then
					raw:SetAnimatePath(szImage)
					raw:SetAnimateGroupNormal(nFrame)
					raw:SetAnimateGroupMouseOver(nOverFrame)
					raw:SetAnimateGroupMouseDown(nDownFrame)
					raw:SetAnimateGroupDisable(nDisableFrame)
				end
			end
		elseif X.IsString(szImage) and X.IsNumber(nFrame) then
			for _, raw in ipairs(self.raws) do
				local el = GetComponentElement(raw, 'IMAGE')
				if el then
					el:FromUITex(szImage, nFrame)
					el:GetParent():FormatAllItemPos()
				end
				el = GetComponentElement(raw, 'BOX')
				if el then
					el:SetExtentImage(szImage, nFrame)
				end
			end
		else
			for _, raw in ipairs(self.raws) do
				raw = GetComponentElement(raw, 'IMAGE')
				if raw then
					raw:FromTextureFile(szImage)
					raw:GetParent():FormatAllItemPos()
				end
			end
		end
	end
	return self
end

-- (self) Instance:Frame(nFrame)
-- (number) Instance:Frame()
function OO:Frame(nFrame)
	self:_checksum()
	if nFrame then
		nFrame = tonumber(nFrame)
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'IMAGE')
			if raw then
				raw:SetFrame(nFrame)
				raw:GetParent():FormatAllItemPos()
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw and GetComponentType(raw) == 'Image' then
			return raw:GetFrame()
		end
	end
end

-- (self) Instance:ItemInfo(...)
-- NOTICE：only for Box
function OO:ItemInfo(...)
	local data = { ... }
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'BOX')
		if raw then
			if X.IsEmpty(data) then
				UpdataItemBoxObject(raw)
			else
				local KItemInfo = GetItemInfo(data[2], data[3])
				if KItemInfo and KItemInfo.nGenre == ITEM_GENRE.BOOK and #data == 4 then -- 西山居BUG
					table.insert(data, 4, 99999)
				end
				local res, err, trace = X.XpCall(UpdataItemInfoBoxObject, raw, unpack(data)) -- 防止itemtab不一样
				if not res then
					X.ErrorLog(err, X.NSFormatString('{$NS}#UI:ItemInfo'), trace)
				end
			end
		end
	end
	return self
end

-- (self) Instance:BoxInfo(nType, ...)
-- NOTICE：only for Box
function OO:BoxInfo(nType, ...)
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'BOX')
		if raw then
			if X.IsEmpty({ ... }) then
				UpdataItemBoxObject(raw)
			else
				local res, err, trace = X.XpCall(UpdateBoxObject, raw, nType, ...) -- 防止itemtab内外网不一样
				if not res then
					X.ErrorLog(err, X.NSFormatString('{$NS}#UI:BoxInfo'), trace)
				end
			end
		end
	end
	return self
end

-- (self) Instance:Icon(dwIcon)
-- (number) Instance:Icon()
-- NOTICE：only for Box
function OO:Icon(dwIconID)
	self:_checksum()
	if X.IsNumber(dwIconID) then
		local element
		for _, raw in ipairs(self.raws) do
			element = GetComponentElement(raw, 'BOX')
			if element then
				element:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
				element:SetObjectIcon(dwIconID)
			end
			element = GetComponentElement(raw, 'IMAGE')
			if element then
				element:FromIconID(dwIconID)
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'BOX')
			if raw then
				return raw:GetObjectIcon()
			end
		end
	end
end

-- (self) Instance:HandleStyle(dwStyle)
function OO:HandleStyle(dwStyle)
	self:_checksum()
	if dwStyle then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'MAIN_HANDLE')
			if raw then
				raw:SetHandleStyle(dwStyle)
			end
		end
	end
	return self
end

-- (self) Instance:ContainerType(dwType)
function OO:ContainerType(dwType)
	self:_checksum()
	if dwType then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'CONTAINER')
			if raw then
				raw:SetContainerType(dwType)
			end
		end
	end
	return self
end

-- (self) Instance:EditType(dwType)
function OO:EditType(dwType)
	self:_checksum()
	if dwType then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				raw:SetType(dwType)
			end
		end
	end
	return self
end

-- (self) UI:Limit(nLimit)
function OO:Limit(nLimit)
	self:_checksum()
	if nLimit then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				raw:SetLimit(nLimit)
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				return raw:GetLimit()
			end
		end
	end
end

-- (self) UI:Align(alignHorizontal, alignVertical)
function OO:Align(alignHorizontal, alignVertical)
	self:_checksum()
	if alignVertical or alignHorizontal then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'TEXT')
				or GetComponentElement(raw, 'MAIN_HANDLE')
			if raw then
				if alignHorizontal and raw.SetHAlign then
					raw:SetHAlign(alignHorizontal)
				end
				if alignVertical and raw.SetVAlign then
					raw:SetVAlign(alignVertical)
				end
				if raw.FormatTextForDraw then
					raw:FormatTextForDraw()
				end
			end
		end
		return self
	else -- get
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'TEXT')
			if raw and raw.GetVAlign and raw.GetHAlign then
				return raw:GetVAlign(), raw:GetHAlign()
			end
		end
	end
end

-- (self) UI:TrackbarStyle(nTrackbarStyle)
function OO:TrackbarStyle(nTrackbarStyle)
	self:_checksum()
	local bShowPercentage = nTrackbarStyle == UI.TRACKBAR_STYLE.SHOW_PERCENT
	for _, raw in ipairs(self.raws) do
		if GetComponentType(raw) == 'WndTrackbar' then
			SetComponentProp(raw, 'bShowPercentage', bShowPercentage)
		end
	end
	return self
end

-- (self) UI:ButtonStyle(eButtonStyle)
function OO:ButtonStyle(...)
	self:_checksum()
	if select('#', ...) == 0 then
		local raw = self.raws[1]
		if raw then
			raw = GetComponentElement(raw, 'BUTTON')
			if raw and raw.GetAnimatePath and raw.GetAnimateGroupNormal then
				return GetButtonStyleName(raw)
			end
		end
	else
		local eButtonStyle = ...
		local tStyle = GetButtonStyleConfig(eButtonStyle) or BUTTON_STYLE_CONFIG.DEFAULT
		local function UpdateButtonBoxFont(raw)
			local btn = GetComponentElement(raw, 'BUTTON')
			local txt = GetComponentElement(raw, 'TEXT')
			if not btn or not txt then
				return
			end
			local nFont = nil
			local r, g, b = txt:GetFontColor()
			if not btn:IsEnabled() then
				nFont = tStyle.nDisableFont
			elseif GetComponentProp(raw, 'bDown') then
				nFont = tStyle.nMouseDownFont
			elseif GetComponentProp(raw, 'bIn') then
				nFont = tStyle.nMouseOverFont
			else
				nFont = tStyle.nNormalFont
			end
			if nFont then
				txt:SetFontScheme(nFont)
				txt:SetFontColor(r, g, b)
			end
		end
		for _, raw in ipairs(self.raws) do
			local btn = GetComponentElement(raw, 'BUTTON')
			if btn then
				btn:SetAnimatePath((wstring.gsub(tStyle.szImage, '/', '\\')))
				btn:SetAnimateGroupNormal(tStyle.nNormalGroup)
				btn:SetAnimateGroupMouseOver(tStyle.nMouseOverGroup)
				btn:SetAnimateGroupMouseDown(tStyle.nMouseDownGroup)
				btn:SetAnimateGroupDisable(tStyle.nDisableGroup)
				UI(btn)
					:UIEvent(X.NSFormatString('OnMouseIn.{$NS}_UI_BUTTON_EVENT'), function()
						SetComponentProp(raw, 'bIn', true)
						UpdateButtonBoxFont(raw)
					end)
					:UIEvent(X.NSFormatString('OnMouseOut.{$NS}_UI_BUTTON_EVENT'), function()
						SetComponentProp(raw, 'bIn', false)
						UpdateButtonBoxFont(raw)
					end)
					:UIEvent(X.NSFormatString('OnLButtonDown.{$NS}_UI_BUTTON_EVENT'), function()
						SetComponentProp(raw, 'bDown', true)
						UpdateButtonBoxFont(raw)
					end)
					:UIEvent(X.NSFormatString('OnLButtonUp.{$NS}_UI_BUTTON_EVENT'), function()
						SetComponentProp(raw, 'bDown', false)
						UpdateButtonBoxFont(raw)
					end)
				SetComponentSize(raw, tStyle.nWidth, tStyle.nHeight)
			end
		end
		return self
	end
end

-- 设置组件外观样式类型
-- @param {string} szAppearance 样式
function OO:Appearance(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local szAppearance = ...
		if X.IsString(szAppearance) then
			for _, raw in ipairs(self.raws) do
				SetComponentProp(raw, 'szAppearance', szAppearance)
				if GetComponentType(raw) == 'WndEditBox' then
					local nW, nH = raw:GetSize()
					SetComponentSize(raw, nW, nH)
				end
			end
		end
		return self
	else
		local raw = self.raws[1]
		if raw then
			return GetComponentProp(raw, 'szAppearance') or 'DEFAULT'
		end
	end
end

-- (self) UI:FormatChildrenPos()
function OO:FormatChildrenPos()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		if GetComponentType(raw) == 'Handle' then
			raw:FormatAllItemPos()
		elseif GetComponentType(raw) == 'WndContainer' then
			raw:FormatAllContentPos()
		end
	end
	return self
end

-- (self) Instance:BringToTop()
function OO:BringToTop()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'MAIN_WINDOW')
		if raw then
			raw:BringToTop()
		end
	end
	return self
end

-- (self) Instance:BringToBottom()
function OO:BringToBottom()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'MAIN_WINDOW')
		if raw then
			local parent = raw:GetParent()
			if parent then
				local child = parent:GetFirstChild()
				if child then
					raw:ChangeRelation(child, true, false)
				end
			end
		end
	end
	return self
end

-----------------------------------------------------------
-- my ui events handle
-----------------------------------------------------------

-- 绑定Frame的事件
function OO:Event(szEvent, fnEvent)
	self:_checksum()
	if X.IsString(szEvent) then
		local nPos, szKey = (StringFindW(szEvent, '.')), nil
		if nPos then
			szKey = string.sub(szEvent, nPos + 1)
			szEvent = string.sub(szEvent, 1, nPos - 1)
		end
		if X.IsFunction(fnEvent) then
			for _, raw in ipairs(self.raws) do
				if raw:GetType() == 'WndFrame' then
					local events = GetComponentProp(raw, 'onEvents')
					if not events then
						events = {}
						local onEvent = X.IsFunction(raw.OnEvent) and raw.OnEvent
						raw.OnEvent = function(e, ...)
							if onEvent then
								onEvent(e, ...)
							end
							if events[e] then
								for _, p in ipairs(events[e]) do
									p.fn(e, ...)
								end
							end
						end
						SetComponentProp(raw, 'events', events)
					end
					if not events[szEvent] then
						raw:RegisterEvent(szEvent)
						events[szEvent] = {}
					end
					if szKey then
						for i, p in X.ipairs_r(events[szEvent]) do
							if p.id == szKey then
								table.remove(events[szEvent], i)
							end
						end
					end
					table.insert(events[szEvent], { id = szKey, fn = fnEvent })
				end
			end
		else
			for _, raw in ipairs(self.raws) do
				if raw:GetType() == 'WndFrame' then
					local events = GetComponentProp(raw, 'events')
					if events then
						if not szKey then
							for e, _ in pairs(events) do
								events[e] = {}
							end
						elseif events[szEvent] then
							for i, p in X.ipairs_r(events[szEvent]) do
								if p.id == szKey then
									table.remove(events[szEvent], i)
								end
							end
						end
					end
				end
			end
		end
	end
	return self
end

-- 绑定ele的UI事件
function OO:UIEvent(szEvent, fnEvent)
	self:_checksum()
	if X.IsString(szEvent) then
		local nPos, szKey = (StringFindW(szEvent, '.')), nil
		if nPos then
			szKey = string.sub(szEvent, nPos + 1)
			szEvent = string.sub(szEvent, 1, nPos - 1)
		end
		if X.IsFunction(fnEvent) then
			for _, raw in ipairs(self.raws) do
				local uiEvents = GetComponentProp(raw, 'uiEvents')
				if not uiEvents then
					uiEvents = {}
					SetComponentProp(raw, 'uiEvents', uiEvents)
				end
				if not uiEvents[szEvent] then
					uiEvents[szEvent] = {}
					local onEvent = X.IsFunction(raw[szEvent]) and raw[szEvent]
					raw[szEvent] = function(...)
						if onEvent then
							onEvent(...)
						end
						local rets = {}
						for _, p in ipairs(uiEvents[szEvent]) do
							local res = { p.fn(...) }
							if #res > 0 then
								if #rets == 0 then
									rets = res
								--[[#DEBUG BEGIN]]
								else
									X.Debug(
										'UI:UIEvent#' .. szEvent .. ':' .. (p.id or 'Unnamed'),
										_L('Set return value failed, cause another hook has alreay take a returnval. [Path] %s', UI.GetTreePath(raw)),
										X.DEBUG_LEVEL.WARNING
									)
								--[[#DEBUG END]]
								end
							end
						end
						return unpack(rets)
					end
					-- 特殊控件的一些HOOK
					if szEvent == 'OnEditChanged' and raw.GetText then
						local fnHookEvent = raw[szEvent]
						raw[szEvent] = function(...)
							local nFireType = GetComponentProp(raw, 'WNDEVENT_FIRETYPE') or WNDEVENT_FIRETYPE.AUTO
							local szText = raw:GetText()
							local szLastText = GetComponentProp(raw, 'LAST_TEXT')
							SetComponentProp(raw, 'WNDEVENT_FIRETYPE', nil)
							SetComponentProp(raw, 'LAST_TEXT', szText)
							if nFireType == WNDEVENT_FIRETYPE.PREVENT or (nFireType == WNDEVENT_FIRETYPE.AUTO and szText == szLastText) then
								return
							end
							return fnHookEvent(...)
						end
					end
				end
				table.insert(uiEvents[szEvent], { id = szKey, fn = fnEvent })
			end
		else
			for _, raw in ipairs(self.raws) do
				local uiEvents = GetComponentProp(raw, 'uiEvents')
				if uiEvents then
					if not szKey then
						for e, _ in pairs(uiEvents) do
							uiEvents[e] = {}
						end
					elseif uiEvents[szEvent] then
						for i, p in X.ipairs_r(uiEvents[szEvent]) do
							if p.id == szKey then
								table.remove(uiEvents[szEvent], i)
							end
						end
					end
				end
			end
		end
	end
	return self
end

-- 设置 Frame 的 CustomMode 事件
-- (self) Instance:CustomLayout(string szTip)
-- (self) Instance:CustomLayout(function fnOnCustomLayout, string szPointType)
function OO:CustomLayout(arg0, arg1)
	self:_checksum()
	if X.IsString(arg0) then
		self:Filter('.WndFrame')
			:Event('ON_ENTER_CUSTOM_UI_MODE', function() UpdateCustomModeWindow(this, arg0, GetComponentProp(this, 'bPenetrable')) end)
			:Event('ON_LEAVE_CUSTOM_UI_MODE', function() UpdateCustomModeWindow(this, arg0, GetComponentProp(this, 'bPenetrable')) end)
	end
	if X.IsFunction(arg0) then
		self:Filter('.WndFrame')
			:Event('ON_ENTER_CUSTOM_UI_MODE', function() arg0(true , GetFrameAnchor(this, arg1)) end)
			:Event('ON_LEAVE_CUSTOM_UI_MODE', function() arg0(false, GetFrameAnchor(this, arg1)) end)
	end
	return self
end

-- breathe 设置Frame的breathe
-- (self) Instance:Breathe(function fnOnFrameBreathe)
function OO:Breathe(fnOnFrameBreathe)
	self:_checksum()
	if X.IsFunction(fnOnFrameBreathe) then
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				UI(raw):UIEvent('OnFrameBreathe', fnOnFrameBreathe)
			end
		end
	end
	return self
end

-- 弹出菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:Menu(menu)
	self:Click(function()
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m()
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 弹出左键菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:MenuLClick(menu)
	self:LClick(function()
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m()
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 弹出右键菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:MenuRClick(menu)
	self:RClick(function()
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m()
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 绑定鼠标单击事件，无参数或传入鼠标按键枚举值调用表示触发单击事件
-- same as jQuery.click()
-- @param {function(eButton: UI.MOUSE_BUTTON)} fnAction 鼠标单击事件回调函数
function OO:Click(fnClick)
	if X.IsFunction(fnClick) then
		self:LClick(fnClick)
		self:MClick(fnClick)
		self:RClick(fnClick)
	else
		local eButton = fnClick or UI.MOUSE_BUTTON.LEFT
		if eButton == UI.MOUSE_BUTTON.LEFT then
			self:LClick()
		elseif eButton == UI.MOUSE_BUTTON.MIDDLE then
			self:MClick()
		elseif eButton == UI.MOUSE_BUTTON.RIGHT then
			self:RClick()
		end
	end
	return self
end

-- 鼠标左键单击事件，无参数调用表示触发单击事件
-- same as jQuery.lclick()
-- @param {function(eButton: UI.MOUSE_BUTTON)} fnAction 鼠标单击事件回调函数
function OO:LClick(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local fnClick = ...
		if X.IsFunction(fnClick) then
			for _, raw in ipairs(self.raws) do
				local fnAction = function()
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.LEFT)
				end
				if GetComponentType(raw) == 'WndScrollHandleBox' then
					UI(GetComponentElement(raw, 'MAIN_HANDLE')):UIEvent('OnItemLButtonClick', fnAction)
				else
					local cmb = GetComponentElement(raw, 'COMBOBOX')
					local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
					local itm = GetComponentElement(raw, 'ITEM')
					local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
					if cmb then
						UI(cmb):UIEvent('OnLButtonClick', fnAction)
					elseif wnd then
						UI(wnd):UIEvent('OnLButtonClick', fnAction)
					elseif itm then
						itm:RegisterEvent(16)
						UI(itm):UIEvent('OnItemLButtonClick', fnAction)
					elseif hdl then
						hdl:RegisterEvent(16)
						UI(hdl):UIEvent('OnItemLButtonClick', fnAction)
					end
				end
			end
		end
	else
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			local itm = GetComponentElement(raw, 'ITEM')
			if wnd and wnd.OnLButtonClick then
				X.CallWithThis(wnd, wnd.OnLButtonClick)
			end
			if itm and itm.OnItemLButtonClick then
				X.CallWithThis(itm, itm.OnItemLButtonClick)
			end
		end
	end
	return self
end

-- 鼠标右键单击事件，无参数调用表示触发单击事件
-- same as jQuery.mclick()
-- @param {function(eButton: UI.MOUSE_BUTTON)} fnAction 鼠标单击事件回调函数
	function OO:MClick(...)
		self:_checksum()
		if select('#', ...) > 0 then
			local fnClick = ...
			if X.IsFunction(fnClick) then
				for _, raw in ipairs(self.raws) do
					local fnAction = function()
						if GetComponentProp(raw, 'bEnable') == false then
							return
						end
						X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.MIDDLE)
					end
					if GetComponentType(raw) == 'WndScrollHandleBox' then
						UI(GetComponentElement(raw, 'MAIN_HANDLE')):UIEvent('OnItemMButtonClick', fnAction)
					else
						local cmb = GetComponentElement(raw, 'COMBOBOX')
						local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
						local itm = GetComponentElement(raw, 'ITEM')
						local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
						if cmb then
							UI(cmb):UIEvent('OnMButtonClick', fnAction)
						elseif wnd then
							UI(wnd):UIEvent('OnMButtonClick', fnAction)
						elseif itm then
							itm:RegisterEvent(16)
							UI(itm):UIEvent('OnItemMButtonClick', fnAction)
						elseif hdl then
							hdl:RegisterEvent(16)
							UI(hdl):UIEvent('OnItemMButtonClick', fnAction)
						end
					end
				end
			end
		else
			for _, raw in ipairs(self.raws) do
				local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
				local itm = GetComponentElement(raw, 'ITEM')
				if wnd and wnd.OnMButtonClick then
					X.CallWithThis(wnd, wnd.OnMButtonClick)
				end
				if itm and itm.OnItemMButtonClick then
					X.CallWithThis(itm, itm.OnItemMButtonClick)
				end
			end
		end
		return self
	end

-- 鼠标右键单击事件，无参数调用表示触发单击事件
-- same as jQuery.rclick()
-- @param {function(eButton: UI.MOUSE_BUTTON)} fnAction 鼠标单击事件回调函数
function OO:RClick(...)
	self:_checksum()
	if select('#', ...) > 0 then
		local fnClick = ...
		if X.IsFunction(fnClick) then
			for _, raw in ipairs(self.raws) do
				local fnAction = function()
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.RIGHT)
				end
				if GetComponentType(raw) == 'WndScrollHandleBox' then
					UI(GetComponentElement(raw, 'MAIN_HANDLE')):UIEvent('OnItemRButtonClick', fnAction)
				else
					local cmb = GetComponentElement(raw, 'COMBOBOX')
					local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
					local itm = GetComponentElement(raw, 'ITEM')
					local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
					if cmb then
						UI(cmb):UIEvent('OnRButtonClick', fnAction)
					elseif wnd then
						UI(wnd):UIEvent('OnRButtonClick', fnAction)
					elseif itm then
						itm:RegisterEvent(32)
						UI(itm):UIEvent('OnItemRButtonClick', fnAction)
					elseif hdl then
						hdl:RegisterEvent(32)
						UI(hdl):UIEvent('OnItemRButtonClick', fnAction)
					end
				end
			end
		end
	else
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
			local itm = GetComponentElement(raw, 'ITEM')
			if wnd and wnd.OnRButtonClick then
				X.CallWithThis(wnd, wnd.OnRButtonClick)
			end
			if itm and itm.OnItemRButtonClick then
				X.CallWithThis(itm, itm.OnItemRButtonClick)
			end
		end
	end
	return self
end

-- 行弹出菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:RowMenu(menu)
	self:RowClick(function(...)
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m(...)
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 行弹出左键菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:RowMenuLClick(menu)
	self:RowLClick(function(...)
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m(...)
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 行弹出右键菜单
-- @param {table|function} menu 菜单或返回菜单的函数
function OO:RowMenuRClick(menu)
	self:RowRClick(function(...)
		local h = this:Lookup('', '') or this
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		local m = menu
		if X.IsFunction(m) then
			m = m(...)
		end
		if not X.IsTable(m) then
			return
		end
		m.x = nX
		m.y = nY + nH
		m.nMiniWidth = nW
		if m.bAlignWidth then
			m.nWidth = nW
		end
		m.bVisibleWhenHideUI = true
		UI.PopupMenu(m)
	end)
	return self
end

-- 行绑定鼠标单击事件
-- @param {function(eButton: UI.MOUSE_BUTTON, record: table, index: number)} fnAction 鼠标单击事件回调函数
function OO:RowClick(fnClick)
	if X.IsFunction(fnClick) then
		self:RowLClick(fnClick)
		self:RowMClick(fnClick)
		self:RowRClick(fnClick)
	end
	return self
end

-- 行鼠标左键单击事件
-- @param {function(eButton: UI.MOUSE_BUTTON, record: table, index: number)} fnAction 鼠标单击事件回调函数
function OO:RowLClick(fnClick)
	self:_checksum()
	if X.IsFunction(fnClick) then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				local fnAction = function(...)
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.LEFT, ...)
				end
				SetComponentProp(raw, 'RowLClick', fnAction)
			end
		end
	end
	return self
end

-- 行鼠标中键单击事件
-- @param {function(eButton: UI.MOUSE_BUTTON, record: table, index: number)} fnAction 鼠标单击事件回调函数
function OO:RowMClick(fnClick)
	self:_checksum()
	if X.IsFunction(fnClick) then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				local fnAction = function(...)
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.MIDDLE, ...)
				end
				SetComponentProp(raw, 'RowMClick', fnAction)
			end
		end
	end
	return self
end

-- 行鼠标右键单击事件
-- @param {function(eButton: UI.MOUSE_BUTTON, record: table, index: number)} fnAction 鼠标单击事件回调函数
function OO:RowRClick(fnClick)
	self:_checksum()
	if X.IsFunction(fnClick) then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				local fnAction = function(...)
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					X.ExecuteWithThis(raw, fnClick, UI.MOUSE_BUTTON.RIGHT, ...)
				end
				SetComponentProp(raw, 'RowRClick', fnAction)
			end
		end
	end
	return self
end

-- complete 加载完成事件
-- :Complete(fnOnComplete) 绑定
function OO:Complete(fnOnComplete)
	self:_checksum()
	if fnOnComplete then
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'WEBPAGE')
			if wnd then
				UI(wnd):UIEvent('OnDocumentComplete', fnOnComplete)
			end
			local wnd = GetComponentElement(raw, 'WEBCEF')
			if wnd then
				UI(wnd):UIEvent('OnWebLoadEnd', fnOnComplete)
			end
		end
	end
	return self
end

-- 鼠标悬停事件
-- same as jQuery.hover()
-- @param {function(bIn: boolean): void} fnAction 鼠标悬停事件响应函数
function OO:Hover(fnAction)
	self:_checksum()
	if fnAction then
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'EDIT') or GetComponentElement(raw, 'MAIN_WINDOW')
			local itm = GetComponentElement(raw, 'ITEM')
			if wnd then
				UI(wnd):UIEvent('OnMouseIn', function() fnAction(true) end)
				UI(wnd):UIEvent('OnMouseOut', function() fnAction(false) end)
			elseif itm then
				itm:RegisterEvent(256)
				UI(itm):UIEvent('OnItemMouseIn', function() fnAction(true) end)
				UI(itm):UIEvent('OnItemMouseOut', function() fnAction(false) end)
			end
		end
	end
	return self
end

-- 行鼠标悬停事件
-- @param {function(bIn: boolean): void} fnAction 行鼠标悬停事件响应函数
function OO:RowHover(fnAction)
	self:_checksum()
	if fnAction then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndTable' then
				SetComponentProp(raw, 'OnRowHover', fnAction)
			end
		end
	end
	return self
end

-- 鼠标悬停提示
-- @param {object} props 配置项
-- @param {string|function} props.render 要提示的纯文字或富文本，或返回前述内容的函数
-- @param {number} props.w 提示框宽度
-- @param {{ x: number; y: number }} props.offset 提示框触发区域偏移量
-- @param {UI.TIP_HIDE_WAY} props.position 提示框相对于触发区域的位置
-- @param {boolean} props.rich 提示框内容是否为富文本（当 render 为函数时取函数第二返回值）
-- @param {number} props.font 提示框字体（仅在非富文本下有效）
-- @param {number} props.r 提示框文字r（仅在非富文本下有效）
-- @param {number} props.g 提示框文字g（仅在非富文本下有效）
-- @param {number} props.b 提示框文字b（仅在非富文本下有效）
-- @param {UI.TIP_HIDE_WAY} props.hide 提示框消失方式
function OO:Tip(props)
	if not X.IsTable(props) then
		props = { render = props }
	end
	local nWidth = props.w or 450
	local tOffset = props.offset or {}
	local nOffsetX = tOffset.x or 0
	local nOffsetY = tOffset.y or 0
	local ePosition = props.position or UI.TIP_POSITION.FOLLOW_MOUSE
	local eHide = props.hide or UI.TIP_HIDE_WAY.HIDE
	local bRichText = props.rich
	return self:Hover(
		function(bIn)
			if not bIn then
				if eHide == UI.TIP_HIDE_WAY.HIDE then
					HideTip(false)
				elseif eHide == UI.TIP_HIDE_WAY.ANIMATE_HIDE then
					HideTip(true)
				end
				return
			end
			local nX, nY, nW, nH
			if ePosition == UI.TIP_POSITION.FOLLOW_MOUSE then
				nX, nY = Cursor.GetPos()
				nX, nY = nX - 0, nY - 40
				nW, nH = 40, 40
			else
				nX, nY = this:GetAbsPos()
				nW, nH = this:GetSize()
			end
			nX, nY = nX + nOffsetX, nY + nOffsetY
			local szText = props.render
			if X.IsFunction(szText) then
				local bSuccess
				bSuccess, szText, bRichText = X.ExecuteWithThis(this, szText)
				if not bSuccess then
					return
				end
			end
			if X.IsEmpty(szText) then
				return
			end
			if not bRichText then
				szText = GetFormatText(szText, props.font or 136, props.r, props.g, props.b)
			end
			OutputTip(szText, nWidth, {nX, nY, nW, nH}, ePosition)
		end
	)
end

-- 行鼠标悬停提示
-- @param {object} props 配置项
-- @param {string|function} props.render 要提示的纯文字或富文本，或返回前述内容的函数
-- @param {number} props.w 提示框宽度
-- @param {{ x: number; y: number }} props.offset 提示框触发区域偏移量
-- @param {UI.TIP_HIDE_WAY} props.position 提示框相对于触发区域的位置
-- @param {boolean} props.rich 提示框内容是否为富文本（当 render 为函数时取函数第二返回值）
-- @param {number} props.font 提示框字体（仅在非富文本下有效）
-- @param {number} props.r 提示框文字r（仅在非富文本下有效）
-- @param {number} props.g 提示框文字g（仅在非富文本下有效）
-- @param {number} props.b 提示框文字b（仅在非富文本下有效）
-- @param {UI.TIP_HIDE_WAY} props.hide 提示框消失方式
function OO:RowTip(props)
	if not X.IsTable(props) then
		props = { render = props }
	end
	local nWidth = props.w or 450
	local tOffset = props.offset or {}
	local nOffsetX = tOffset.x or 0
	local nOffsetY = tOffset.y or 0
	local ePosition = props.position or UI.TIP_POSITION.FOLLOW_MOUSE
	local eHide = props.hide or UI.TIP_HIDE_WAY.HIDE
	local bRichText = props.rich
	return self:RowHover(
		function(bIn, rec, nIndex, Rect)
			if not bIn then
				if eHide == UI.TIP_HIDE_WAY.HIDE then
					HideTip(false)
				elseif eHide == UI.TIP_HIDE_WAY.ANIMATE_HIDE then
					HideTip(true)
				end
				return
			end
			local nX, nY, nW, nH
			if ePosition == UI.TIP_POSITION.FOLLOW_MOUSE then
				nX, nY = Cursor.GetPos()
				nX, nY = nX - 0, nY - 40
				nW, nH = 40, 40
			else
				nX, nY = Rect[1], Rect[2]
				nW, nH = Rect[3], Rect[4]
			end
			nX, nY = nX + nOffsetX, nY + nOffsetY
			local szText = props.render
			if X.IsFunction(szText) then
				local bSuccess
				bSuccess, szText, bRichText = X.ExecuteWithThis(this, szText, rec, nIndex)
				if not bSuccess then
					return
				end
			end
			if X.IsEmpty(szText) then
				return
			end
			if not bRichText then
				szText = GetFormatText(szText, props.font or 136, props.r, props.g, props.b)
			end
			OutputTip(szText, nWidth, {nX, nY, nW, nH}, ePosition)
		end
	)
end

-- check 复选框状态变化
-- :Check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) 绑定
-- :Check()                返回是否已勾选
-- :Check(bool bChecked)   勾选/取消勾选
function OO:Check(fnCheck, fnUncheck, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		fnUncheck = fnUncheck or fnCheck
	end
	if X.IsFunction(fnCheck) or X.IsFunction(fnUncheck) then
		for _, raw in ipairs(self.raws) do
			local chk = GetComponentElement(raw, 'CHECKBOX')
			if chk then
				if X.IsFunction(fnCheck) then
					UI(chk):UIEvent('OnCheckBoxCheck', function() fnCheck(true) end)
				end
				if X.IsFunction(fnUncheck) then
					UI(chk):UIEvent('OnCheckBoxUncheck', function() fnUncheck(false) end)
				end
			end
		end
		return self
	elseif X.IsBoolean(fnCheck) then
		for _, raw in ipairs(self.raws) do
			local chk = GetComponentElement(raw, 'CHECKBOX')
			if chk then
				if fnUncheck then
					chk:Check(fnCheck, fnUncheck)
				else
					chk:Check(fnCheck)
				end
			end
		end
		return self
	elseif not fnCheck then
		local raw = self.raws[1]
		if raw then
			local chk = GetComponentElement(raw, 'CHECKBOX')
			if chk then
				return chk:IsCheckBoxChecked()
			end
		end
	--[[#DEBUG BEGIN]]
	else
		X.Debug('ERROR UI:Check', 'fnCheck:'..type(fnCheck)..' fnUncheck:'..type(fnUncheck), X.DEBUG_LEVEL.ERROR)
	--[[#DEBUG END]]
	end
end

-- change 输入框文字变化
-- :Change(fnOnChange) 绑定
-- :Change()   调用处理函数
function OO:Change(fnOnChange)
	self:_checksum()
	if X.IsFunction(fnOnChange) then
		for _, raw in ipairs(self.raws) do
			local edt = GetComponentElement(raw, 'EDIT')
			if edt then
				UI(edt):UIEvent('OnEditChanged', function() X.ExecuteWithThis(raw, fnOnChange, edt:GetText()) end)
			end
			if GetComponentType(raw) == 'WndTrackbar' then
				table.insert(GetComponentProp(raw, 'onChangeEvents'), fnOnChange)
			end
		end
		return self
	else
		for _, raw in ipairs(self.raws) do
			local edt = GetComponentElement(raw, 'EDIT')
			if edt and edt.OnEditChanged then
				X.CallWithThis(edt, edt.OnEditChanged, raw)
			end
			if GetComponentType(raw) == 'WndTrackbar' then
				local sld = GetComponentElement(raw, 'TRACKBAR')
				if sld and sld.OnScrollBarPosChanged then
					X.CallWithThis(sld, sld.OnScrollBarPosChanged, raw)
				end
			end
		end
		return self
	end
end

-- 输入框特殊键按下
-- @param {function(nMessageKey: number, szKey: string): number|void} fnOnSpecialKeyDown 绑定的处理函数
function OO:OnSpecialKeyDown(...)
	self:_checksum()
	if select('#', ...) > 0 then
		if not X.IsFunction(fnOnSpecialKeyDown) then
			fnOnSpecialKeyDown = nil
		end
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'OnSpecialKeyDown', fnOnSpecialKeyDown)
		end
	end
	return self
end

function OO:Navigate(szURL)
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'WEB')
		if raw then
			raw:Navigate(szURL)
		end
	end
	return self
end

-- focus （输入框）获得焦点 -- 好像只有输入框能获得焦点
-- :Focus(fnOnSetFocus) 绑定
-- :Focus()   使获得焦点
function OO:Focus(fnOnSetFocus)
	self:_checksum()
	if fnOnSetFocus then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				UI(raw):UIEvent('OnSetFocus', function()
					X.CallWithThis(raw, fnOnSetFocus)
				end)
			end
		end
		return self
	else
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				Station.SetFocusWindow(raw)
				break
			end
		end
		return self
	end
end

-- blur （输入框）失去焦点
-- :Blur(fnOnKillFocus) 绑定
-- :Blur()   使获得焦点
function OO:Blur(fnOnKillFocus)
	self:_checksum()
	if fnOnKillFocus then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				UI(raw):UIEvent('OnKillFocus', function() X.ExecuteWithThis(raw, fnOnKillFocus) end)
			end
		end
		return self
	else
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				Station.SetFocusWindow()
				break
			end
		end
		return self
	end
end

-------------------------------------
-- UI object class
-------------------------------------
setmetatable(UI, {
	__call = function (t, ...) return OO:ctor(...) end,
	__tostring = function(t) return X.NSFormatString('{$NS}_UI (class prototype)') end,
})
X.RegisterEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'), function()
	local PROXY = {}
	for k, v in pairs(UI) do
		PROXY[k] = v
		UI[k] = nil
	end
	setmetatable(UI, {
		__metatable = true,
		__call = function (t, ...) return OO:ctor(...) end,
		__index = PROXY,
		__newindex = function() assert(false, X.NSFormatString('DO NOT modify {$NS}.UI after initialized!!!')) end,
		__tostring = function(t) return X.NSFormatString('{$NS}_UI (class prototype)') end,
	})
end)

---------------------------------------------------
-- create new frame
-- (ui) UI.CreateFrame(string szName, table opt)
-- @param string szName: the ID of frame
-- @param table  opt   : options
---------------------------------------------------
function UI.CreateFrame(szName, opt)
	if not X.IsTable(opt) then
		opt = {}
	end
	if not (
		opt.level == 'Normal'  or opt.level == 'Lowest'  or opt.level == 'Topmost'  or
		opt.level == 'Normal1' or opt.level == 'Lowest1' or opt.level == 'Topmost1' or
		opt.level == 'Normal2' or opt.level == 'Lowest2' or opt.level == 'Topmost2'
	) then
		opt.level = 'Normal'
	end
	-- calc ini file path
	local szIniFile = X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrame.ini'
	if opt.simple then
		szIniFile = X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrameSimple.ini'
	elseif opt.empty then
		szIniFile = X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrameEmpty.ini'
	end

	-- close and reopen exist frame
	local frm = Station.Lookup(opt.level .. '/' .. szName)
	if frm then
		Wnd.CloseWindow(frm)
	end
	frm = Wnd.OpenWindow(szIniFile, szName)
	if not opt.simple and not opt.empty then
		frm:Lookup('', 'Image_Icon'):FromUITex(X.PACKET_INFO.LOGO_UITEX, X.PACKET_INFO.LOGO_MAIN_FRAME)
	end
	frm:ChangeRelation(opt.level)
	frm:Show()
	local ui = UI(frm)
	-- init frame
	if opt.esc then
		X.RegisterEsc('Frame_Close_' .. szName, function()
			return true
		end, function()
			if frm.OnCloseButtonClick then
				local status, res = X.CallWithThis(frm, frm.OnCloseButtonClick)
				if status and res then
					return
				end
			end
			Wnd.CloseWindow(frm)
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
			X.RegisterEsc('Frame_Close_' .. szName)
		end)
	end
	if opt.simple then
		SetComponentProp(frm, 'simple', true)
		-- top right buttons
		if not opt.close then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Close'):Destroy()
		else
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Close/Btn_Close').OnLButtonClick = function()
				if UI(frm):Remove():Count() == 0 then
					PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
				end
			end
		end
		if not opt.setting then
			frm:Lookup('WndContainer_TitleBtnL/Wnd_Setting'):Destroy()
		else
			frm:Lookup('WndContainer_TitleBtnL/Wnd_Setting/Btn_Setting').OnLButtonClick = opt.setting
		end
		if opt.onrestore then
			UI(frm):UIEvent('OnRestore', opt.onrestore)
		end
		if not opt.minimize then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Minimize'):Destroy()
		else
			if opt.onminimize then
				UI(frm):UIEvent('OnMinimize', opt.onminimize)
			end
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize').OnCheckBoxCheck = function()
				if frm.bMaximize then
					frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize'):Check(false)
				else
					frm.w, frm.h = frm:GetSize()
				end
				frm:Lookup('Wnd_Total'):Hide()
				frm:Lookup('', 'Shadow_Bg'):Hide()
				frm:SetSize(frm.w, 30)
				local chkMax = frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize')
				if chkMax then
					chkMax:Enable(false)
				end
				if select(2, X.ExecuteWithThis(frm, frm.OnMinimize, frm:Lookup('Wnd_Total'))) then
					return
				end
				if opt.dragresize then
					frm:Lookup('Btn_Drag'):Hide()
				end
				frm.bMinimize = true
			end
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize').OnCheckBoxUncheck = function()
				frm:Lookup('Wnd_Total'):Show()
				frm:Lookup('', 'Shadow_Bg'):Show()
				frm:SetSize(frm.w, frm.h)
				local chkMax = frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize')
				if chkMax then
					chkMax:Enable(true)
				end
				if opt.dragresize then
					frm:Lookup('Btn_Drag'):Show()
				end
				frm.bMinimize = false
				X.ExecuteWithThis(frm, frm.OnRestore, frm:Lookup('Wnd_Total'))
			end
		end
		if not opt.maximize then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize'):Destroy()
		else
			if opt.onmaximize then
				UI(frm):UIEvent('OnMaximize', opt.onmaximize)
			end
			frm:Lookup('WndContainer_TitleBtnR').OnLButtonDBClick = function()
				frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize'):ToggleCheck()
			end
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize').OnCheckBoxCheck = function()
				if frm.bMinimize then
					frm:Lookup('WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize'):Check(false)
				else
					frm.anchor = GetFrameAnchor(frm)
					frm.w, frm.h = frm:GetSize()
				end
				local w, h = Station.GetClientSize()
				UI(frm):Pos(0, 0):Drag(false):Size(w, h):Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
					local w, h = Station.GetClientSize()
					UI(frm):Pos(0, 0):Size(w, h)
				end)
				if select(2, X.ExecuteWithThis(frm, frm.OnMaximize, frm:Lookup('Wnd_Total'))) then
					return
				end
				if opt.dragresize then
					frm:Lookup('Btn_Drag'):Hide()
				end
				frm.bMaximize = true
			end
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize').OnCheckBoxUncheck = function()
				UI(frm)
				  :Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
				  :Size(frm.w, frm.h)
				  :Anchor(frm.anchor)
				  :Drag(true)
				  if opt.dragresize then
					frm:Lookup('Btn_Drag'):Show()
				end
				frm.bMaximize = false
				X.ExecuteWithThis(frm, frm.OnRestore, frm:Lookup('Wnd_Total'))
			end
		end
		-- drag resize button
		opt.minwidth  = opt.minwidth or 100
		opt.minheight = opt.minheight or 50
		if not opt.dragresize then
			frm:Lookup('Btn_Drag'):Hide()
		else
			if opt.ondragresize then
				UI(frm):UIEvent('OnDragResize', opt.ondragresize)
			end
			frm:Lookup('Btn_Drag').OnDragButton = function()
				local x, y = Station.GetMessagePos()
				local nClientW, nClientH = Station.GetClientSize()
				local nFrameX, nFrameY = frm:GetRelPos()
				local w, h = x - nFrameX, y - nFrameY
				w = math.min(w, nClientW - nFrameX) -- frame size should not larger than client size
				h = math.min(h, nClientH - nFrameY)
				w = math.max(w, opt.minwidth) -- frame size must larger than setted min size
				h = math.max(h, opt.minheight)
				frm:Lookup('Btn_Drag'):SetRelPos(w - 16, h - 16)
				frm:Lookup('', 'Shadow_Bg'):SetSize(w, h)
			end
			frm:Lookup('Btn_Drag').OnDragButtonBegin = function()
				frm:Lookup('', 'Image_Title'):Hide()
				frm:Lookup('', 'Text_Title'):Hide()
				frm:Lookup('Wnd_Total'):Hide()
				frm:Lookup('WndContainer_TitleBtnL'):Hide()
				frm:Lookup('WndContainer_TitleBtnR'):Hide()
			end
			frm:Lookup('Btn_Drag').OnDragButtonEnd = function()
				frm:Lookup('', 'Image_Title'):Show()
				frm:Lookup('', 'Text_Title'):Show()
				frm:Lookup('Wnd_Total'):Show()
				frm:Lookup('WndContainer_TitleBtnL'):Show()
				frm:Lookup('WndContainer_TitleBtnR'):Show()
				local w, h = this:GetRelPos()
				w = math.max(w + 16, opt.minwidth)
				h = math.max(h + 16, opt.minheight)
				UI(frm):Size(w, h)
				if frm.OnDragResize then
					local res, err, trace = X.XpCall(frm.OnDragResize, frm:Lookup('Wnd_Total'))
					if not res then
						X.ErrorLog(err, X.NSFormatString('{$NS}#UI:CreateFrame#OnDragResize'), trace)
					end
				end
			end
			frm:Lookup('Btn_Drag'):RegisterLButtonDrag()
		end
		-- frame properties
		if opt.alpha then
			frm:Lookup('', 'Image_Title'):SetAlpha(opt.alpha * 1.4)
			frm:Lookup('', 'Shadow_Bg'):SetAlpha(opt.alpha /255 * 200)
		end
	elseif not opt.empty then
		SetComponentProp(frm, 'intact', true)
		SetComponentProp(frm, 'minWidth', 128)
		SetComponentProp(frm, 'minHeight', 160)
		frm:Lookup('Btn_Close').OnLButtonClick = function()
			UI(frm):Remove()
		end
	end
	if not opt.anchor then
		opt.anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
	end
	return ApplyUIArguments(ui, opt)
end
