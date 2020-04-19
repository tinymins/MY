--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 茗伊插件集UI库
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()

-------------------------------------
-- UI object class
-------------------------------------
do
local function createInstance(c, ins, ...)
	if not ins then
		ins = c
	end
	if c.ctor then
		c.ctor(ins, ...)
	end
	return c
end
UI = setmetatable({}, {
	__index = {
		MOUSE_EVENT = LIB.SetmetaReadonly({
			LBUTTON = 1,
			MBUTTON = 0,
			RBUTTON = -1,
		}),
		TIP_POSITION = LIB.SetmetaReadonly({
			FOLLOW_MOUSE              = -1,
			CENTER                    = ALW.CENTER,
			LEFT_RIGHT                = ALW.LEFT_RIGHT,
			RIGHT_LEFT                = ALW.RIGHT_LEFT,
			TOP_BOTTOM                = ALW.TOP_BOTTOM,
			BOTTOM_TOP                = ALW.BOTTOM_TOP,
			RIGHT_LEFT_AND_BOTTOM_TOP = ALW.RIGHT_LEFT_AND_BOTTOM_TOP,
		}),
		TIP_HIDEWAY = LIB.SetmetaReadonly({
			NO_HIDE      = 100,
			HIDE         = 101,
			ANIMATE_HIDE = 102,
		}),
		TRACKBAR_STYLE = LIB.SetmetaReadonly({
			SHOW_VALUE    = false,
			SHOW_PERCENT  = true,
		}),
		WND_SIDE = LIB.SetmetaReadonly({
			TOP          = 0,
			BOTTOM       = 1,
			LEFT         = 2,
			RIGHT        = 3,
			TOPLEFT      = 4,
			TOPRIGHT     = 5,
			BOTTOMLEFT   = 6,
			BOTTOMRIGHT  = 7,
			CENTER       = 8,
			LEFTCENTER   = 9,
			RIGHTCENTER  = 1,
			TOPCENTER    = 1,
			BOTTOMCENTER = 1,
		}),
		EDIT_TYPE = LIB.SetmetaReadonly({
			NUMBER = 0, -- 数字
			ASCII = 1, -- 英文
			WIDE_CHAR = 2, -- 中英文
		}),
		LAYER_LIST = {'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2'},
		BUTTON_STYLE = {
			{
				nWidth = 100,
				nHeight = 26,
				szImage = 'ui/Image/UICommon/CommonPanel.UITex',
				nNormalGroup = 25,
				nMouseOverGroup = 26,
				nMouseDownGroup = 27,
				nDisableGroup = 28,
			},
			{
				nWidth = 100,
				nHeight = 25,
				szImage = 'ui/image/uicommon/logincommon.uitex',
				nNormalGroup = 54,
				nMouseOverGroup = 55,
				nMouseDownGroup = 56,
				nDisableGroup = 60,
			},
			{
				nWidth = 148,
				nHeight = 33,
				szImage = PACKET_INFO.UITEX_COMMON,
				nNormalGroup = 5,
				nMouseOverGroup = 6,
				nMouseDownGroup = 7,
				nDisableGroup = 8,
			},
			{
				nWidth = 148,
				nHeight = 33,
				szImage = PACKET_INFO.UITEX_COMMON,
				nNormalGroup = 1,
				nMouseOverGroup = 2,
				nMouseDownGroup = 3,
				nDisableGroup = 4,
			},
			OPTION = {
				nWidth = 22,
				nHeight = 24,
				szImage = 'ui/Image/UICommon/CommonPanel2.UITex',
				nNormalGroup = 57,
				nMouseOverGroup = 58,
				nMouseDownGroup = 59,
				nDisableGroup = 56,
			},
		},
	},
	__tostring = function(t) return PACKET_INFO.NAME_SPACE .. '_UI (class prototype)' end,
	__call = function (...)
		local store = {}
		return createInstance(setmetatable({}, {
			__index = function(t, k)
				if type(k) == 'number' then
					if k < 0 then
						k = #store.raws + k + 1
					end
					return store.raws[k]
				else
					return store[k] or UI[k]
				end
			end,
			__newindex = function(t, k, v)
				if type(k) == 'number' then
					assert(false, 'Elements are readonly!')
				else
					store[k] = v
				end
			end,
			__tostring = function(t) return PACKET_INFO.NAME_SPACE .. '_UI (class instance)' end,
		}), nil, ...)
	end,
})
end

-----------------------------------------------------------
-- my ui common functions
-----------------------------------------------------------
local function ApplyUIArguments(ui, arg)
	if ui and arg then
		-- properties
		if arg.x ~= nil or arg.y ~= nil  then ui:Pos             (arg.x, arg.y  ) end
		if arg.alpha              ~= nil then ui:Alpha          (arg.alpha      ) end
		if arg.font               ~= nil then ui:Font           (arg.font       ) end -- must before color
		if arg.fontscale          ~= nil then ui:FontScale      (arg.fontscale  ) end -- must before color
		if arg.color              ~= nil then ui:Color          (arg.color      ) end
		if arg.r or arg.g or arg.b       then ui:Color      (arg.r, arg.g, arg.b) end
		if arg.multiline          ~= nil then ui:Multiline      (arg.multiline  ) end -- must before :Text()
		if arg.trackbarstyle      ~= nil then ui:TrackbarStyle(arg.trackbarstyle) end -- must before :Text()
		if arg.textfmt            ~= nil then ui:Text           (arg.textfmt    ) end -- must before :Text()
		if arg.text               ~= nil then ui:Text           (arg.text       ) end
		if arg.placeholder        ~= nil then ui:Placeholder    (arg.placeholder) end
		if arg.oncomplete         ~= nil then ui:Complete       (arg.oncomplete ) end
		if arg.navigate           ~= nil then ui:Navigate       (arg.navigate   ) end
		if arg.group              ~= nil then ui:Group          (arg.group      ) end
		if arg.tip                ~= nil then ui:Tip(arg.tip, arg.tippostype, arg.tipoffset, arg.tiprichtext) end
		if arg.range              ~= nil then ui:Range        (unpack(arg.range)) end
		if arg.value              ~= nil then ui:Value          (arg.value      ) end
		if arg.menu               ~= nil then ui:Menu           (arg.menu       ) end
		if arg.lmenu              ~= nil then ui:LMenu          (arg.lmenu      ) end
		if arg.rmenu              ~= nil then ui:RMenu          (arg.rmenu      ) end
		if arg.limit              ~= nil then ui:Limit          (arg.limit      ) end
		if arg.scroll             ~= nil then ui:Scroll         (arg.scroll     ) end
		if arg.handlestyle        ~= nil then ui:HandleStyle    (arg.handlestyle) end
		if arg.buttonstyle        ~= nil then ui:ButtonStyle    (arg.buttonstyle) end -- must before :Size()
		if arg.edittype           ~= nil then ui:EditType       (arg.edittype   ) end
		if arg.visible            ~= nil then ui:Visible        (arg.visible    ) end
		if arg.autovisible        ~= nil then ui:Visible        (arg.autovisible) end
		if arg.enable             ~= nil then ui:Enable         (arg.enable     ) end
		if arg.autoenable         ~= nil then ui:Enable         (arg.autoenable ) end
		if arg.image              ~= nil then
			ui:Image(arg.image, arg.imageframe, arg.imageoverframe, arg.imagedownframe, arg.imagedisableframe)
		end
		if arg.icon               ~= nil then ui:Icon           (arg.icon       ) end
		if arg.name               ~= nil then ui:Name           (arg.name       ) end
		if arg.penetrable         ~= nil then ui:Penetrable     (arg.penetrable ) end
		if arg.dragable           ~= nil then ui:Drag           (arg.dragable   ) end
		if arg.dragarea           ~= nil then ui:Drag      (unpack(arg.dragarea)) end
		if arg.w ~= nil or arg.h ~= nil or arg.rw ~= nil or arg.rh ~= nil then ui:Size(arg.w, arg.h, arg.rw, arg.rh) end -- must after :Text() because w/h can be 'auto'
		if arg.halign or arg.valign      then ui:Align   (arg.halign, arg.valign) end -- must after :Size()
		if arg.anchor             ~= nil then ui:Anchor         (arg.anchor     ) end -- must after :Size() :Pos()
		-- event handlers
		if arg.onscroll           ~= nil then ui:Scroll         (arg.onscroll   ) end
		if arg.onhover            ~= nil then ui:Hover          (arg.onhover    ) end
		if arg.onfocus            ~= nil then ui:Focus          (arg.onfocus    ) end
		if arg.onblur             ~= nil then ui:Blur           (arg.onblur     ) end
		if arg.onclick            ~= nil then ui:Click          (arg.onclick    ) end
		if arg.onlclick           ~= nil then ui:LClick         (arg.onlclick   ) end
		if arg.onrclick           ~= nil then ui:RClick         (arg.onrclick   ) end
		if arg.checked            ~= nil then ui:Check          (arg.checked    ) end
		if arg.oncheck            ~= nil then ui:Check          (arg.oncheck    ) end
		if arg.onchange           ~= nil then ui:Change         (arg.onchange   ) end
		if arg.ondragging or arg.ondrag  then ui:Drag(arg.ondragging, arg.ondrag) end
		if arg.events             ~= nil then for _, v in ipairs(arg.events) do ui:Event(unpack(v)) end end
		if arg.uievents           ~= nil then for _, v in ipairs(arg.uievents) do ui:UIEvent(unpack(v)) end end
		if arg.listbox            ~= nil then for _, v in ipairs(arg.listbox) do ui:ListBox(unpack(v)) end end
		if arg.autocomplete       ~= nil then for _, v in ipairs(arg.autocomplete) do ui:Autocomplete(unpack(v)) end end
		-- auto size
		if arg.autosize                  then ui:AutoSize()                       end
		if arg.autowidth                 then ui:AutoWidth()                      end
		if arg.autoheight                then ui:AutoHeight()                     end
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

local function GetComponentElement(raw, elementType)
	local element
	local componentType = GetComponentType(raw)
	local componentBaseType = raw:GetBaseType()
	if elementType == 'ITEM' then
		if componentBaseType ~= 'Wnd' then
			element = raw
		end
	elseif elementType == 'WND' then
		if componentBaseType == 'Wnd' then
			element = raw
		end
	elseif elementType == 'MAIN_WINDOW' then
		if componentType == 'WndFrame' then
			element = raw:Lookup('Wnd_Total') or raw
		elseif componentBaseType == 'Wnd' then
			element = raw
		end
	elseif elementType == 'MAIN_HANDLE' then
		if componentType == 'WndScrollBox' then
			element = raw:Lookup('', 'Handle_Padding/Handle_Scroll')
		elseif componentType == 'WndFrame' then
			element = GetComponentElement(raw, 'MAIN_WINDOW'):Lookup('', '')
		elseif componentType == 'Handle' or componentType == 'CheckBox' then
			element = raw
		elseif componentBaseType == 'Wnd' then
			element = raw:Lookup('', '')
		end
	elseif elementType == 'CHECKBOX' then
		if componentType == 'WndCheckBox' or componentType == 'WndRadioBox' or componentType == 'CheckBox' then
			element = raw
		end
	elseif elementType == 'COMBOBOX' then
		if componentType == 'WndComboBox' or componentType == 'WndEditComboBox' or componentType == 'WndAutocomplete' then
			element = raw:Lookup('Btn_ComboBox')
		end
	elseif elementType == 'EDIT' then
		if componentType == 'WndEdit' then
			element = raw
		elseif componentType == 'WndEditBox' or componentType == 'WndEditComboBox' or componentType == 'WndAutocomplete' then
			element = raw:Lookup('WndEdit_Default')
		end
	elseif elementType == 'BUTTON' then
		if componentType == 'WndButton' then
			element = raw
		end
	elseif elementType == 'WEB' then
		if componentType == 'WndWebPage'
		or componentType == 'WndWebCef' then
			element = raw
		end
	elseif elementType == 'WEBPAGE' then
		if componentType == 'WndWebPage' then
			element = raw
		end
	elseif elementType == 'WEBCEF' then
		if componentType == 'WndWebCef' then
			element = raw
		end
	elseif elementType == 'TRACKBAR' then
		if componentType == 'WndTrackbar' then
			element = raw:Lookup('WndNewScrollBar_Default')
		end
	elseif elementType == 'TEXT' then
		if componentType == 'WndScrollBox' then
			element = raw:Lookup('', 'Handle_Padding/Handle_Scroll/Text_Default')
		elseif componentType == 'WndFrame' then
			element = raw:Lookup('', 'Text_Title') or raw:Lookup('', 'Text_Default')
		elseif componentBaseType == 'Wnd' then
			element = raw:Lookup('', 'Text_Default')
		elseif componentType == 'Handle' or componentType == 'CheckBox' then
			element = raw:Lookup('Text_Default')
		elseif componentType == 'Text' then
			element = raw
		end
	elseif elementType == 'IMAGE' then
		if componentType == 'WndEditBox' or componentType == 'WndComboBox' or componentType == 'WndEditComboBox'
		or componentType == 'WndAutocomplete' or componentType == 'WndScrollBox' then
			element = raw:Lookup('', 'Image_Default')
		elseif componentType == 'Handle' or componentType == 'CheckBox' then
			element = raw:Lookup('Image_Default')
		elseif componentType == 'Image' then
			element = raw
		end
	elseif elementType == 'SHADOW' then
		if componentType == 'Shadow' then
			element = raw
		end
	elseif elementType == 'BOX' then
		if componentType == 'Box' then
			element = raw
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
				return format('%.2f%%', value)
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
				nCurrentValue = floor((nCurrentValue * 100 / nMax) * 100) / 100
			end
			local szText = GetComponentProp(raw, 'FormatText')(nCurrentValue, bShowPercentage)
			raw:Lookup('', 'Text_Default'):SetText(szText)
			if not bOnlyUI then
				for _, fn in ipairs(GetComponentProp(raw, 'onChangeEvents')) do
					LIB.ExecuteWithThis(raw, fn, nCurrentValue)
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
			local szKey = GetKeyName(Station.GetMessageKey())
			if szKey == 'Esc' or (
				szKey == 'Enter' and not edt:IsMultiLine()
			) then
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
				LIB.DelayCall(opt.delay, function()
					UI(raw):Autocomplete('search')
					-- for compatible
					Station.SetFocusWindow(edt)
				end)
			else
				UI(raw):Autocomplete('close')
			end
		end
		edt.OnKillFocus = function()
			LIB.DelayCall(function()
				local wnd = Station.GetFocusWindow()
				local frame = wnd and wnd:GetRoot()
				if not frame or frame:GetName() ~= 'MY_PopupMenu' then
					UI.ClosePopupMenu()
				end
			end)
		end
		edt.OnEditSpecialKeyDown = function() -- TODO: MY_PopupMenu 适配
			local szKey = GetKeyName(Station.GetMessageKey())
			if IsPopupMenuOpened() and PopupMenu_ProcessHotkey then
				if szKey == 'Enter'
				or szKey == 'Up'
				or szKey == 'Down'
				or szKey == 'Left'
				or szKey == 'Right' then
					return PopupMenu_ProcessHotkey(szKey)
				end
			elseif szKey == 'Esc' or (
				szKey == 'Enter' and not edt:IsMultiLine()
			) then
				Station.SetFocusWindow(edt:GetRoot())
				return 1
			end
		end
		SetComponentProp(raw, 'autocompleteOptions', {
			beforeSearch = nil  , -- @param: raw, option
			beforePopup  = nil  , -- @param: menu, raw, option
			beforeDelete = nil  , -- @param: szOption, fnDoDelete, option
			afterDelete  = nil  , -- @param: szOption, option

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
			local onHover = GetComponentProp(raw, 'OnListItemHandleCustomHover')
			if onHover and onHover(this, true, data.text, data.id, data.data, not data.selected) == false then
				return
			end
			UI(this:Lookup('Image_Bg')):FadeIn(100)
		end)
		SetComponentProp(raw, 'OnListItemHandleMouseLeave', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onHover = GetComponentProp(raw, 'OnListItemHandleCustomHover')
			if onHover and onHover(this, false, data.text, data.id, data.data, not data.selected) == false then
				return
			end
			UI(this:Lookup('Image_Bg')):FadeTo(500,0)
		end)
		SetComponentProp(raw, 'OnListItemHandleLButtonClick', function()
			local data = GetComponentProp(this, 'listboxItemData')
			local onItemClick = GetComponentProp(raw, 'OnListItemHandleCustomLButtonClick')
			if onItemClick and onItemClick(this, data.text, data.id, data.data, not data.selected) == false then
				return
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
			local onItemClick = GetComponentProp(raw, 'OnListItemHandleCustomRButtonClick')
			if onItemClick and onItemClick(this, data.text, data.id, data.data, not data.selected) == false then
				return
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
				UI.PopupMenu(GetMenu(this, data.text, data.id, data.data, data.selected))
			end
		end)
		SetComponentProp(raw, 'listboxOptions', { multiSelect = false })
	elseif szType == 'CheckBox' then
		raw:RegisterEvent(831)
		local function UpdateCheckState(raw)
			if not IsElement(raw) then
				return
			end
			local img = raw:Lookup('Image_Default')
			if not IsElement(img) then
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
	end
end

-----------------------------------------------------------
-- my ui selectors -- same as jQuery -- by tinymins --
-----------------------------------------------------------
--
-- selt.raws[] : ui element list
--
-- ui object creator
-- same as jQuery.$()
function UI:ctor(super, mixed)
	self.raws = {}
	if IsTable(mixed) then
		if IsTable(mixed.raws) then
			for _, raw in ipairs(mixed.raws) do
				insert(self.raws, raw)
			end
		elseif IsElement(mixed) then
			insert(self.raws, mixed)
		else
			for _, raw in ipairs(mixed) do
				if IsElement(raw) then
					insert(self.raws, raw)
				end
			end
		end
	elseif IsString(mixed) then
		local raw = Station.Lookup(mixed)
		if IsElement(raw) then
			insert(self.raws, raw)
		end
	end
	return self
end

--  del bad raws
-- (self) _checksum()
function UI:_checksum()
	for i, raw in ipairs_r(self.raws) do
		if not IsElement(raw) then
			remove(self.raws, i)
		end
	end
	return self
end

-- add a element to object
-- same as jQuery.add()
function UI:Add(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		insert(raws, raw)
	end
	if IsString(mixed) then
		mixed = Station.Lookup(mixed)
	end
	if IsElement(mixed) then
		insert(raws, mixed)
	end
	if IsTable(mixed) and tostring(mixed) == PACKET_INFO.NAME_SPACE .. '_UI (class instance)' then
		for i = 1, mixed:Count() do
			insert(raws, mixed[i])
		end
	end
	return UI(raws)
end

-- delete elements from object
-- same as jQuery.not()
function UI:Del(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		insert(raws, raw)
	end
	if IsString(mixed) then
		-- delete raws those id/class fits filter: mixed
		if sub(mixed, 1, 1) == '#' then
			mixed = sub(mixed, 2)
			if sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in ipairs_r(raws) do
					if find(raw:GetName(), mixed) then
						remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in ipairs_r(raws) do
					if raw:GetName() == mixed then
						remove(raws, i)
					end
				end
			end
		elseif sub(mixed, 1, 1) == '.' then
			mixed = sub(mixed, 2)
			if sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in ipairs_r(raws) do
					if find(GetComponentType(raw), mixed) then
						remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in ipairs_r(raws) do
					if GetComponentType(raw) == mixed then
						remove(raws, i)
					end
				end
			end
		end
	elseif IsElement(mixed) then
		-- delete raws those treepath is the same as mixed
		mixed = concat({ mixed:GetTreePath() })
		for i, raw in ipairs_r(raws) do
			if concat({ raw:GetTreePath() }) == mixed then
				remove(raws, i)
			end
		end
	end
	return UI(raws)
end

-- filter elements from object
-- same as jQuery.filter()
function UI:Filter(mixed)
	self:_checksum()
	local raws = {}
	for i, raw in ipairs(self.raws) do
		insert(raws, raw)
	end
	if IsString(mixed) then
		-- delete raws those id/class not fits filter:mixed
		if sub(mixed, 1, 1) == '#' then
			mixed = sub(mixed, 2)
			if sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in ipairs_r(raws) do
					if not find(raw:GetName(), mixed) then
						remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in ipairs_r(raws) do
					if raw:GetName() ~= mixed then
						remove(raws, i)
					end
				end
			end
		elseif sub(mixed, 1, 1) == '.' then
			mixed = sub(mixed, 2)
			if sub(mixed, 1, 1) == '^' then
				-- regexp
				for i, raw in ipairs_r(raws) do
					if not find(GetComponentType(raw), mixed) then
						remove(raws, i)
					end
				end
			else
				-- normal
				for i, raw in ipairs_r(raws) do
					if GetComponentType(raw) ~= mixed then
						remove(raws, i)
					end
				end
			end
		end
	elseif IsElement(mixed) then
		-- delete raws those treepath is not the same as mixed
		mixed = concat({ mixed:GetTreePath() })
		for i, raw in ipairs_r(raws) do
			if concat({ raw:GetTreePath() }) ~= mixed then
				remove(raws, i)
			end
		end
	end
	return UI(raws)
end

-- get parent
-- same as jQuery.parent()
function UI:Parent()
	self:_checksum()
	local raws, hash, path, parent = {}, {}
	for _, raw in ipairs(self.raws) do
		parent = raw:GetParent()
		if parent then
			path = concat({ parent:GetTreePath() })
			if not hash[path] then
				insert(raws, parent)
				hash[path] = true
			end
		end
	end
	return UI(raws)
end

-- fetch children by name
function UI:Fetch(szName, szSubName)
	self:_checksum()
	local raws, parent, el = {}
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
			insert(raws, el)
		end
	end
	return UI(raws)
end

-- get children
-- same as jQuery.children()
function UI:Children(filter)
	self:_checksum()
	if IsString(filter) and sub(filter, 1, 1) == '#' and sub(filter, 2, 2) ~= '^' then
		local raws, hash, name, child, path = {}, {}, sub(filter, 2)
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'MAIN_WINDOW') or raw
			child = raw:Lookup(name)
			if child then
				path = concat({ child:GetTreePath() })
				if not hash[path] then
					insert(raws, child)
					hash[path] = true
				end
			end
			if raw:GetBaseType() == 'Wnd' then
				child = GetComponentElement(raw, 'MAIN_HANDLE')
				child = child and child:Lookup(name)
				if child then
					path = concat({ child:GetTreePath() })
					if not hash[path] then
						insert(raws, child)
						hash[path] = true
					end
				end
			end
		end
		return UI(raws)
	else
		local raws, hash, child, path = {}, {}
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'MAIN_WINDOW') or raw
			if raw:GetBaseType() == 'Wnd' then
				child = raw:GetFirstChild()
				while child do
					path = concat({ child:GetTreePath() })
					if not hash[path] then
						insert(raws, child)
						hash[path] = true
					end
					child = child:GetNext()
				end
				local h = GetComponentElement(raw, 'MAIN_HANDLE') or raw:Lookup('', '')
				if h then
					for i = 0, h:GetItemCount() - 1 do
						child = h:Lookup(i)
						path = concat({ child:GetTreePath() })
						if not hash[path] then
							insert(raws, child)
							hash[path] = true
						end
					end
				end
			elseif raw:GetType() == 'Handle' then
				for i = 0, raw:GetItemCount() - 1 do
					child = raw:Lookup(i)
					path = concat({ child:GetTreePath() })
					if not hash[path] then
						insert(raws, child)
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
function UI:Find(filter)
	self:_checksum()
	local top, raw, ruid, child
	local raws, hash, stack, children = {}, {}, {}, {}
	for _, root in ipairs(self.raws) do
		top = #raws
		insert(stack, root)
		while #stack > 0 do
			--### 弹出栈顶元素准备处理
			raw = remove(stack, #stack)
			ruid = tostring(raw)
			--### 判断不在结果集中则处理
			if not hash[ruid] then
				--## 将自身加入结果队列
				insert(raws, raw)
				hash[ruid] = true
				--## 计算所有子元素并将子元素压栈准备下次循环处理
				--## 注意要逆序压入栈中以保证最终结果是稳定排序的
				if raw:GetBaseType() == 'Wnd' then
					child = raw:Lookup('', '')
					if child then
						for i = 0, child:GetItemCount() - 1 do
							insert(children, child:Lookup(i))
						end
					end
					child = raw:GetFirstChild()
					while child do
						insert(children, child)
						child = child:GetNext()
					end
					repeat
						child = remove(children)
						insert(stack, child)
					until not child
				elseif raw:GetType() == 'Handle' then
					for i = 0, raw:GetItemCount() - 1 do
						insert(children, raw:Lookup(i))
					end
					repeat
						child = remove(children)
						insert(stack, child)
					until not child
				end
			end
		end
		-- 因为是求子元素 所以移除第一个压栈的元素（父元素）
		remove(raws, top + 1)
	end
	return UI(raws):Filter(filter)
end

function UI:Raw(nIndex)
	self:_checksum()
	return self.raws[nIndex or 1]
end

-- filter mouse in component
function UI:PtIn()
	self:_checksum()
	local raws = {}
	local cX, cY = Cursor.GetPos()
	for _, raw in pairs(self.raws) do
		if raw:GetBaseType() == 'Wnd' then
			if raw:PtInItem(cX, cY) then
				insert(raws, raw)
			end
		else
			if raw:PtInWindow(cX, cY) then
				insert(raws, raw)
			end
		end
	end
	return UI(raws)
end

-- each
-- same as jQuery.each(function(){})
-- :Each(UI each_self)  -- you can use 'this' to visit raw element likes jQuery
function UI:Each(fn)
	self:_checksum()
	for _, raw in pairs(self.raws) do
		LIB.ExecuteWithThis(raw, fn, UI(raw))
	end
	return self
end

-- slice -- index starts from 1
-- same as jQuery.slice(selector, pos)
function UI:Slice(startpos, endpos)
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
		insert(raws, self.raws[i])
	end
	return UI(raws)
end

-- eq
-- same as jQuery.eq(pos)
function UI:Eq(pos)
	if pos then
		return self:Slice(pos, pos)
	end
	return self
end

-- first
-- same as jQuery.first()
function UI:First()
	return self:Slice(1, 1)
end

-- last
-- same as jQuery.last()
function UI:Last()
	return self:Slice(-1, -1)
end

-- get count
function UI:Count()
	self:_checksum()
	return #self.raws
end

-----------------------------------------------------------
-- my ui opreation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
-- (void) Instance:Remove()
-- (self) Instance:Remove(function onRemove)
function UI:Remove(onRemove)
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
	if IsEmpty(szText) then
		return
	end

	local nDisLen = hText:GetTextPosExtent()
	local nLen = wlen(hText:GetText())
	if nDisLen == nLen then
		return
	end

	local nW = hText:GetW()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(GetFormatText(szText), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
end
local function OnCommonComponentMouseLeave() HideTip() end

-- xml string
local _tItemXML = {
	['Text'] = '<text>w=150 h=30 valign=1 font=162 eventid=371 </text>',
	['Image'] = '<image>w=100 h=100 </image>',
	['Box'] = '<box>w=48 h=48 eventid=525311 </box>',
	['Shadow'] = '<shadow>w=15 h=15 eventid=277 </shadow>',
	['Handle'] = '<handle>firstpostype=0 w=10 h=10</handle>',
	['CheckBox'] = '<handle>name="CheckBox" w=100 h=28 <image>name="Image_Default" w=28 h=28 path="ui\\Image\\button\\CommonButton_1.UITex" frame=5</image><text>name="Text_Default" valign=1 x=29 w=71 h=28</text></handle>',
}
local _nTempWndCount = 0
-- append
-- similar as jQuery.append()
-- Instance:Append(szXml)
-- Instance:Append(szType[, tArg | szName])
function UI:Append(arg0, arg1)
	assert(IsString(arg0))
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
		if IsTable(arg1) then
			tArg = arg1
		elseif IsString(arg1) then
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
			if find(szFile, '^[^<>?:]*%.ini:%w+$') then
				szType = gsub(szFile, '^[^<>?]*%.ini:', '')
				szFile = sub(szFile, 0, -#szType - 2)
				szComponent = szFile:gsub('$.*[/\\]', ''):gsub('^[^<>?]*[/\\]', ''):sub(0, -5)
			else
				szFile = PACKET_INFO.UICOMPONENT_ROOT .. szFile .. '.ini'
			end
			local frame = Wnd.OpenWindow(szFile, PACKET_INFO.NAME_SPACE .. '_TempWnd#' .. _nTempWndCount)
			if not frame then
				return LIB.Debug(PACKET_INFO.NAME_SPACE .. '#UI#Append', _L('Unable to open ini file [%s]', szFile), DEBUG_LEVEL.ERROR)
			end
			_nTempWndCount = _nTempWndCount + 1
			local raw = frame:Lookup(szComponent)
			if parentWnd and raw then -- KWndWindow
				InitComponent(raw, szType)
				raw:ChangeRelation(parentWnd, true, true)
			elseif parentHandle then
				raw = parentHandle:AppendItemFromIni(szFile, szComponent)
				if raw then -- KItemNull
					InitComponent(raw, szType)
					parentHandle:FormatAllItemPos()
				else
					LIB.Debug(PACKET_INFO.NAME_SPACE .. '#UI#Append', _L('Can not find wnd or item component [%s:%s]', szFile, szComponent), DEBUG_LEVEL.ERROR)
				end
			end
			if raw then
				ui = ui:Add(raw)
				UI(raw):Hover(OnCommonComponentMouseEnter, OnCommonComponentMouseLeave):Change(OnCommonComponentMouseEnter)
			end
			Wnd.CloseWindow(frame)
		end
	end
	return ApplyUIArguments(ui, tArg)
end

-- clear
-- clear handle
-- (self) Instance:Clear()
function UI:Clear()
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
function UI:RemoveItemUntilNewLine()
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
function UI:Data(key, value)
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
function UI:Show()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw:Show()
	end
	return self
end

-- hide
function UI:Hide()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		raw:Hide()
	end
	return self
end

-- visible
function UI:Visible(bVisible)
	self:_checksum()
	if IsBoolean(bVisible) then
		return self:Toggle(bVisible)
	elseif IsFunction(bVisible) then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'CHECKBOX') or GetComponentElement(raw, 'MAIN_WINDOW') or raw
			LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '_UI_VISIBLE_CHECK#' .. tostring(raw), function()
				if IsElement(raw) then
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
		if max(r, g, b) * ratio > 255 then
			ratio = 255 / max(r, g, b)
		end
		txt:SetFontColor(ceil(r * ratio), ceil(g * ratio), ceil(b * ratio))
	end
	-- make gray
	local sha = GetComponentElement(raw, 'SHADOW')
	if sha then
		local r, g, b = sha:GetColorRGB()
		local ratio = bEnable and 2.2 or (1 / 2.2)
		if max(r, g, b) * ratio > 255 then
			ratio = 255 / max(r, g, b)
		end
		sha:SetColorRGB(ceil(r * ratio), ceil(g * ratio), ceil(b * ratio))
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

function UI:Enable(...)
	self:_checksum()
	local argc = select('#', ...)
	if argc == 1 then
		local bEnable = select(1, ...)
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'CHECKBOX') or GetComponentElement(raw, 'MAIN_WINDOW') or raw
			if IsFunction(bEnable) then
				LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '_UI_ENABLE_CHECK#' .. tostring(raw), function()
					if IsElement(raw) then
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
function UI:Toggle(bShow)
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
function UI:Drag(...)
	self:_checksum()
	local argc = select('#', ...)
	local arg0, arg1, arg2, arg3 = ...
	if argc == 0 then
	elseif IsBoolean(arg0) then
		local bDrag = arg0
		for _, raw in ipairs(self.raws) do
			if raw.EnableDrag then
				raw:EnableDrag(bDrag)
			end
		end
		return self
	elseif IsNumber(arg0) or IsNumber(arg1) or IsNumber(arg2) or IsNumber(arg3) then
		local nX, nY, nW, nH = arg0 or 0, arg1 or 0, arg2, arg3
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				raw:SetDragArea(nX, nY, nW or raw:GetW(), nH or raw:GetH())
			end
		end
		return self
	elseif IsFunction(arg0) or IsFunction(arg1) then
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
function UI:Text(arg0, arg1)
	self:_checksum()
	if not IsNil(arg0) and not IsBoolean(arg0) then
		local componentType, element
		for _, raw in ipairs(self.raws) do
			componentType = GetComponentType(raw)
			if IsFunction(arg0) then
				if componentType == 'WndTrackbar' then
					SetComponentProp(raw, 'FormatText', arg0)
					GetComponentProp(raw, 'ResponseUpdateScroll')(true)
				end
			elseif IsTable(arg0) then
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
				if not IsString(arg0) then
					arg0 = tostring(arg0)
				end
				if componentType == 'WndScrollBox' then
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
function UI:Placeholder(szText)
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
function UI:Autocomplete(method, arg1, arg2)
	self:_checksum()
	if method == 'option' and (IsNil(arg1) or (IsString(arg1) and IsNil(arg2))) then -- get
		-- try to get its option
		local raw = self.raws[1]
		if raw then
			return Clone(GetComponentProp(raw, 'autocompleteOptions'))
		end
	else -- set
		if method == 'option' then
			if IsString(arg1) then
				arg1 = {
					[arg1] = arg2
				}
			end
			if IsTable(arg1) then
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
					if IsFunction(opt.beforeSearch) then
						opt.beforeSearch(raw, opt, text)
					end
					local needle = opt.ignoreCase and StringLowerW(text) or text
					local aSrc = {}
					-- get matched list
					for _, src in ipairs(opt.source) do
						local haystack = type(src) == 'table' and (src.keyword or tostring(src.text)) or tostring(src)
						if opt.ignoreCase then
							haystack = StringLowerW(haystack)
						end
						local pos = wfind(haystack, needle)
						if pos and (opt.anyMatch or pos == 0) then
							insert(aSrc, src)
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
									if IsFunction(opt.afterComplete) then
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
												remove(opt.source, i)
											end
										end
										UI(raw):Autocomplete('search')
									end
									if opt.beforeDelete then
										bSure = opt.beforeDelete(src, fnDoDelete, opt)
									end
									if bSure ~= false then
										fnDoDelete()
									end
									if opt.afterDelete then
										opt.afterDelete(src, opt)
									end
								end
							end
						end
						if t then
							insert(menu, t)
						end
					end
					local nX, nY = raw:GetAbsPos()
					local nW, nH = raw:GetSize()
					menu.szLayer = 'Topmost2'
					menu.nMiniWidth = nW
					menu.x, menu.y = nX, nY + nH
					menu.bDisableSound = true
					menu.bShowKillFocus = true
					menu.nMaxHeight = min(select(2, Station.GetClientSize()) - raw:GetAbsY() - raw:GetH(), 600)

					if IsFunction(opt.beforePopup) then
						opt.beforePopup(raw, opt, text, menu)
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
			if IsString(arg1) then
				arg1 = { arg1 }
			end
			if IsTable(arg1) then
				for _, src in ipairs(arg1) do
					if IsString(src) then
						for _, raw in ipairs(self.raws) do
							local opt = GetComponentProp(raw, 'autocompleteOptions')
							for i = #opt.source, 1, -1 do
								if opt.source[i] == src then
									remove(opt.source, i)
								end
							end
							insert(opt.source, src)
						end
					end
				end
			end
		elseif method == 'delete' then
			if IsString(arg1) then
				arg1 = { arg1 }
			end
			if IsTable(arg1) then
				for _, src in ipairs(arg1) do
					if IsString(src) then
						for _, raw in ipairs(self.raws) do
							local opt = GetComponentProp(raw, 'autocompleteOptions')
							for i=#opt.source, 1, -1 do
								if opt.source[i] == arg1 then
									remove(opt.source, i)
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

-- ui listbox interface
function UI:ListBox(method, arg1, arg2, arg3, arg4)
	self:_checksum()
	if method == 'option' and (IsNil(arg1) or (IsString(arg1) and IsNil(arg2))) then -- get
		-- try to get its option
		local raw = self.raws[1]
		if raw then
			return Clone(GetComponentProp(raw, 'listboxOptions'))
		end
	else -- set
		if method == 'option' then
			if IsString(arg1) then
				arg1 = {
					[arg1] = arg2
				}
			end
			if IsTable(arg1) then
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
							insert(tData, data)
						end
					end
				end
			end
			return tData
		elseif method == 'insert' then
			local text, id, data, pos, r, g, b = arg1, arg2, arg3
			if IsTable(arg4) then
				pos, r, g, b = arg4.pos, arg4.r, arg4.g, arg4.b
			else
				pos = tonumber(arg4)
			end
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
						})
						hItem:Lookup('Text_Default'):SetText(text)
						if r and g and b then
							hItem:Lookup('Text_Default'):SetFontColor(r, g, b)
						end
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
							for i, k in ipairs(argk) do
								if k == 'data' then
									data.data = argv[i]
								elseif k == 'text' then
									hItem:Lookup('Text_Default'):SetText(argv[i])
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
		elseif method == 'multiSelect' then
			self:ListBox('option', 'multiSelect', arg1)
		elseif method == 'onmenu' then
			if IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'GetListItemHandleMenu', arg1)
					end
				end
			end
		elseif method == 'onlclick' then
			if IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomLButtonClick', arg1)
					end
				end
			end
		elseif method == 'onrclick' then
			if IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomRButtonClick', arg1)
					end
				end
			end
		elseif method == 'onhover' then
			if IsFunction(arg1) then
				for _, raw in ipairs(self.raws) do
					if GetComponentType(raw) == 'WndListBox' then
						SetComponentProp(raw, 'OnListItemHandleCustomHover', arg1)
					end
				end
			end
		end
		return self
	end
end

-- get/set ui object name
function UI:Name(szText)
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
function UI:Group(szText)
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
function UI:Penetrable(bPenetrable)
	self:_checksum()
	if IsBoolean(bPenetrable) then -- set penetrable
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
function UI:Alpha(nAlpha)
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
function UI:FadeTo(nTime, nOpacity, callback)
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
			LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '_FADE_' .. tostring(ui[1]), function()
				ui:Show()
				local nCurrentAlpha = fnCurrent(nStartAlpha, nOpacity, nTime, GetTime() - nStartTime)
				ui:Alpha(nCurrentAlpha)
				--[[#DEBUG BEGIN]]
				-- LIB.Debug('fade', format('%d %d %d %d\n', nStartAlpha, nOpacity, nCurrentAlpha, (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity)), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				if (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity) <= 0 then
					ui:Alpha(nOpacity)
					if callback then
						Call(callback, ui)
					end
					return 0
				end
			end)
		end
	end
	return self
end

-- (self) Instance:FadeIn(nTime, callback)
function UI:FadeIn(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		self:Eq(i):FadeTo(nTime, GetComponentProp(raw, 'nOpacity') or 255, callback)
	end
	return self
end

-- (self) Instance:FadeOut(nTime, callback)
function UI:FadeOut(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		local ui = self:Eq(i)
		if ui:Alpha() > 0 then
			SetComponentProp(ui, 'nOpacity', ui:Alpha())
		end
	end
	self:FadeTo(nTime, 0, function(ui)
		ui:Toggle(false)
		if callback then
			Call(callback, ui)
		end
	end)
	return self
end

-- (self) Instance:SlideTo(nTime, nHeight, callback)
function UI:SlideTo(nTime, nHeight, callback)
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
			LIB.BreatheCall(function()
				ui:Show()
				local nCurrentValue = fnCurrent(nStartValue, nHeight, nTime, GetTime()-nStartTime)
				ui:Height(nCurrentValue)
				--[[#DEBUG BEGIN]]
				-- LIB.Debug('slide', format('%d %d %d %d\n', nStartValue, nHeight, nCurrentValue, (nStartValue - nCurrentValue)*(nCurrentValue - nHeight)), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				if (nStartValue - nCurrentValue)*(nCurrentValue - nHeight) <= 0 then
					ui:Height(nHeight):Toggle( nHeight ~= 0 )
					if callback then
						Call(callback)
					end
					return 0
				end
			end)
		end
	end
	return self
end

-- (self) Instance:SlideUp(nTime, callback)
function UI:SlideUp(nTime, callback)
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
function UI:SlideDown(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i, raw in ipairs(self.raws) do
		self:Eq(i):SlideTo(nTime, GetComponentProp(raw, 'nSlideTo'), callback)
	end
	return self
end

-- (number) Instance:Font()
-- (self) Instance:Font(number nFont)
function UI:Font(nFont)
	self:_checksum()
	if nFont then -- set name
		local element
		for _, raw in ipairs(self.raws) do
			element = GetComponentElement(raw, 'TEXT')
			if element then
				element:SetFontScheme(nFont)
			end
			element = GetComponentElement(raw, 'EDIT')
			if element then
				element:SetFontScheme(nFont)
				element:SetSelectFontScheme(nFont)
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
function UI:Color(r, g, b)
	self:_checksum()
	if IsTable(r) then
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
		local raw, element = self.raws[1]
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

function UI:DrawEclipse(nX, nY, nMajorAxis, nMinorAxis, nR, nG, nB, nA, dwRotate, dwPitch, dwRad, nAccuracy)
	nR, nG, nB, nA = nR or 255, nG or 255, nB or 255, nA or 255
	dwRotate, dwPitch, dwRad = dwRotate or 0, dwPitch or 0, dwRad or (2 * PI)
	nAccuracy = nAccuracy or 32
	local deltaRad = (2 * PI) / nAccuracy
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
				nDis = nMajorAxis * nMinorAxis / sqrt(pow(nMinorAxis * cos(dwRad1 - dwRotate), 2) + pow(nMajorAxis * sin(dwRad1 - dwRotate), 2))
				sha:AppendTriangleFanPoint(
					nX + nDis * cos(dwRad1),
					nY - nDis * sin(dwRad1),
					nR, nG, nB, nA
				)
				-- sha:AppendTriangleFanPoint(
				-- 	nX + (nMajorAxis * cos(dwRotate) * cos(dwRad1 - dwRotate) - nMinorAxis * sin(dwRotate) * sin(dwRad1 - dwRotate)),
				-- 	nY - (nMinorAxis * cos(dwRotate) * sin(dwRad1 - dwRotate) + nMajorAxis * sin(dwRotate) * cos(dwRad1 - dwRotate)),
				-- 	nR, nG, nB, nA
				-- )
				dwRad1 = (dwRad1 < dwRad2 and dwRad1 + deltaRad > dwRad2) and dwRad2 or (dwRad1 + deltaRad)
			until dwRad1 > dwRad2
		end
	end
	return self
end

function UI:DrawCircle(nX, nY, nRadius, nR, nG, nB, nA, dwPitch, dwRad, nAccuracy)
	nR, nG, nB, nA = nR or 255, nG or 255, nB or 255, nA or 255
	dwPitch, dwRad = dwPitch or 0, dwRad or (2 * PI)
	nAccuracy = nAccuracy or 32
	local deltaRad = (2 * PI) / nAccuracy
	local sha, nX1, nY1, nRadius1, dwRad1, dwRad2
	for _, raw in ipairs(self.raws) do
		sha = GetComponentElement(raw, 'SHADOW')
		if sha then
			dwRad1 = dwPitch
			dwRad2 = dwPitch + dwRad
			nX1 = nX or (sha:GetW() / 2)
			nY1 = nY or (sha:GetH() / 2)
			nRadius1 = nRadius or min(nX1, nY1)
			sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			sha:SetD3DPT(D3DPT.TRIANGLEFAN)
			sha:ClearTriangleFanPoint()
			sha:AppendTriangleFanPoint(nX1, nY1, nR, nG, nB, nA)
			sha:Show()
			repeat
				sha:AppendTriangleFanPoint(nX1 + cos(dwRad1) * nRadius1, nY1 - sin(dwRad1) * nRadius1, nR, nG, nB, nA)
				dwRad1 = (dwRad1 < dwRad2 and dwRad1 + deltaRad > dwRad2) and dwRad2 or (dwRad1 + deltaRad)
			until dwRad1 > dwRad2
		end
	end
	return self
end

function UI:DrawGwText(szText, nX ,nY, nZ, nR, nG, nB, nA, nFont, fFontScale, fSpacing, aDelta)
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

function UI:DrawGwCircle(nX, nY, nZ, nRadius, nR, nG, nB, nA, dwPitch, dwRad)
	nRadius, dwPitch, dwRad = nRadius or (64 * 3), dwPitch or 0, dwRad or (2 * PI)
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
				nSceneXD, nSceneZD = Scene_PlaneGameWorldPosToScene(nX + cos(dwRad1) * nRadius, nY + sin(dwRad1) * nRadius)
				sha:AppendTriangleFan3DPoint(nX ,nY, nZ, nR, nG, nB, nA, { nSceneXD - nSceneX, 0, nSceneZD - nSceneZ })
				dwRad1 = dwRad1 + PI / 16
			until dwRad1 > dwRad2
		end
	end
	return self
end

-- (number) Instance:Left()
-- (self) Instance:Left(number)
function UI:Left(nLeft)
	if nLeft then
		return self:Pos(nLeft, nil)
	else
		local l, t = self:Pos()
		return l
	end
end

-- (number) Instance:Top()
-- (self) Instance:Top(number)
function UI:Top(nTop)
	if nTop then
		return self:Pos(nil, nTop)
	else
		local l, t = self:Pos()
		return t
	end
end

-- (number, number) Instance:Pos()
-- (self) Instance:Pos(nLeft, nTop)
function UI:Pos(nLeft, nTop)
	self:_checksum()
	if IsNumber(nLeft) or IsNumber(nTop) then
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
		if IsString(nLeft) then
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
function UI:Shake(xrange, yrange, maxspeed, time)
	self:_checksum()
	if xrange and yrange and maxspeed and time then
		local starttime = GetTime()
		local xspeed, yspeed = maxspeed, - maxspeed
		local xhalfrange, yhalfrange = xrange / 2, yrange / 2
		for _, raw in ipairs(self.raws) do
			local ui = UI(raw)
			local xoffset, yoffset = 0, 0
			LIB.RenderCall(tostring(raw) .. ' shake', function()
				if ui:Count() == 0 then
					return 0
				elseif GetTime() - starttime < time then
					local x, y = ui:Pos()
					x, y = x - xoffset, y - yoffset

					xoffset = xoffset + random(xspeed > 0 and 0 or xspeed, xspeed > 0 and xspeed or 0)
					if xoffset < - xhalfrange then
						xoffset = min(- xrange - xoffset, xhalfrange)
						xspeed = - xspeed
					elseif xoffset > xhalfrange then
						xoffset = max(xrange - xoffset, - xhalfrange)
						xspeed = - xspeed
					end

					yoffset = yoffset + random(yspeed > 0 and 0 or yspeed, yspeed > 0 and yspeed or 0)
					if yoffset < - yhalfrange then
						yoffset =  min(- yrange - yoffset, yhalfrange)
						yspeed = - yspeed
					elseif yoffset > yhalfrange then
						yoffset = max(yrange - yoffset, - yhalfrange)
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
			LIB.RenderCall(tostring(raw) .. ' shake', false)
		end
	end
end

-- (anchor) Instance:Anchor()
-- (self) Instance:Anchor(anchor)
do
local CENTER = { s = 'CENTER', r = 'CENTER',  x = 0, y = 0 } -- szSide, szRelSide, fOffsetX, fOffsetY
function UI:Anchor(anchor)
	self:_checksum()
	if anchor == 'CENTER' then
		anchor = CENTER
	end
	if IsTable(anchor) then
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
-- (self) Instance:Width(number)
function UI:Width(nWidth, nRawWidth)
	if nWidth then
		return self:Size(nWidth, nil, nRawWidth, nil)
	else
		local w, h = self:Size()
		return w
	end
end

-- (number) Instance:Height()
-- (self) Instance:Height(number)
function UI:Height(nHeight, nRawHeight)
	if nHeight then
		return self:Size(nil, nHeight, nil, nRawHeight)
	else
		local w, h = self:Size()
		return h
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
			local nTFlexW = max(0, (nWidth - (nWidth >= 674 and 674 or 426)) / 2)
			imgBgTLFlex:SetSize(nTFlexW, nTH)
			imgBgTRFlex:SetSize(nTFlexW, nTH)
			local nTCenterW = nWidth >= 674 and (124 * fScale) or 0
			imgBgTLCenter:SetSize(nTCenterW, nTH)
			imgBgTRCenter:SetSize(nTCenterW, nTH)
			local nBLW, nBRW = ceil(124 * fScale), ceil(8 * fScale)
			local nBCW, nBH = nWidth - nBLW - nBRW + 1, 85 * fScale -- 不知道为什么差一像素 但是加上就好了
			imgBgBL:SetSize(nBLW, nBH)
			imgBgBC:SetSize(nBCW, nBH)
			imgBgBR:SetSize(nBRW, nBH)
			local nCEdgeW = ceil(8 * fScale)
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
		elseif GetComponentProp(raw, 'intact') or raw == LIB.GetFrame() then
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
	elseif componentType == 'WndComboBox' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local cmb = GetComponentElement(raw, 'COMBOBOX')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local txt = GetComponentElement(raw, 'TEXT')
		local img = GetComponentElement(raw, 'IMAGE')
		local w, h = cmb:GetSize()
		cmb:SetRelPos(nWidth-w-5, ceil((nHeight - h)/2))
		cmb:Lookup('', ''):SetAbsPos(hdl:GetAbsPos())
		cmb:Lookup('', ''):SetSize(nWidth, nHeight)
		wnd:SetSize(nWidth, nHeight)
		hdl:SetSize(nWidth, nHeight)
		img:SetSize(nWidth, nHeight)
		txt:SetSize(nWidth - w - 5 - 10, nHeight)
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
		wnd:SetSize(nWidth, nHeight)
		hdl:SetSize(nWidth, nHeight)
		img:SetSize(nWidth, nHeight)
		edt:SetSize(nWidth-8, nHeight-4)
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
	elseif componentType == 'WndScrollBox' then
		raw:SetSize(nWidth, nHeight)
		raw:Lookup('', ''):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Image_Default'):SetSize(nWidth, nHeight)
		raw:Lookup('', 'Handle_Padding'):SetSize(nWidth - 30, nHeight - 20)
		raw:Lookup('', 'Handle_Padding/Handle_Scroll'):SetSize(nWidth - 30, nHeight - 20)
		raw:Lookup('', 'Handle_Padding/Handle_Scroll'):FormatAllItemPos()
		raw:Lookup('WndScrollBar'):SetRelX(nWidth - 20)
		raw:Lookup('WndScrollBar'):SetH(nHeight - 20)
	elseif componentType == 'WndTrackbar' then
		local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
		local hdl = GetComponentElement(raw, 'MAIN_HANDLE')
		local sld = GetComponentElement(raw, 'TRACKBAR')
		local txt = GetComponentElement(raw, 'TEXT')
		local nWidth = nOuterWidth or max(nWidth, (nInnerWidth or 0) + 5)
		local nHeight = nOuterHeight or max(nHeight, (nInnerHeight or 0) + 5)
		local nRawWidth = min(nWidth, nInnerWidth or sld:GetW())
		local nRawHeight = min(nHeight, nInnerHeight or sld:GetH())
		wnd:SetSize(nWidth, nHeight)
		sld:SetSize(nRawWidth, nRawHeight)
		sld:Lookup('Btn_Track'):SetSize(min(34, nRawWidth * 0.6), nRawHeight)
		hdl:SetSize(nWidth, nHeight)
		hdl:Lookup('Image_BG'):SetSize(nRawWidth, nRawHeight - 2)
		txt:SetRelX(nRawWidth + 5)
		txt:SetSize(nWidth - nRawWidth - 5, nHeight)
		hdl:FormatAllItemPos()
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
	LIB.ExecuteWithThis(raw, raw.OnSizeChanged)
end

-- (number, number) Instance:Size(bInnerSize)
-- (self) Instance:Size(nLeft, nTop)
-- (self) Instance:Size(OnSizeChanged)
function UI:Size(arg0, arg1, arg2, arg3)
	self:_checksum()
	if arg0 == 'auto' and arg1 == 'auto' then
		return self:AutoSize()
	elseif arg0 == 'auto' then
		arg0 = nil
		self:AutoWidth()
	elseif arg1 == 'auto' then
		arg1 = nil
		self:AutoHeight()
	end
	if IsFunction(arg0) then
		for _, raw in ipairs(self.raws) do
			UI(raw):UIEvent('OnSizeChanged', arg0)
		end
		return self
	elseif IsNumber(arg0) or IsNumber(arg1) or IsNumber(arg2) or IsNumber(arg3) then
		for _, raw in ipairs(self.raws) do
			SetComponentSize(raw, arg0 or raw:GetW(), arg1 or raw:GetH(), arg2, arg3)
		end
		return self
	else
		local raw, w, h, rw, rh = self.raws[1]
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
			raw = GetComponentElement(raw, 'TRACKBAR')
			if raw then
				rw, rh = raw:GetSize()
			end
		end
		return w, h, rw, rh
	end
end

-- (self) Instance:MinSize() -- Get element min size
-- (self) Instance:MinSize(number nW, number nH) -- Set element min size
function UI:MinSize(nW, nH)
	self:_checksum()
	if IsNumber(nW) or IsNumber(nH) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minWidth', nW)
			SetComponentProp(raw, 'minHeight', nH)
		end
		return self
	elseif IsNumber(nW) then -- set
		for _, raw in ipairs(self.raws) do
			SetComponentProp(raw, 'minWidth', nW)
		end
		return self
	elseif IsNumber(nH) then -- set
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
function UI:MinWidth(nW)
	self:_checksum()
	if IsNumber(nW) then -- set
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
function UI:MinHeight(nH)
	self:_checksum()
	if IsNumber(nH) then -- set
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
		or componentType == 'WndTrackbar' then
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
					if RW then
						RW = RW + deltaW
					end
					W = W + deltaW
				end
				if bAutoHeight then
					if RH then
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
function UI:AutoWidth()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		AutoSize(raw, true, false)
	end
	return self
end

-- Auto set height of element by text
-- (self) Instance:AutoHeight()
function UI:AutoHeight()
	self:_checksum()
	for _, raw in ipairs(self.raws) do
		AutoSize(raw, false, true)
	end
	return self
end

-- (self) Instance:AutoSize() -- resize Text element by autoSize
-- (self) Instance:AutoSize(bool bAutoSize) -- set if Text is autoSize
function UI:AutoSize(arg0, arg1)
	self:_checksum()
	if IsNil(arg0) then
		for _, raw in ipairs(self.raws) do
			AutoSize(raw, true, true)
		end
	elseif IsBoolean(arg0) then
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
function UI:FontScale(nScale)
	self:_checksum()
	if IsNumber(nScale) then
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
function UI:Scroll(mixed)
	self:_checksum()
	if mixed then -- set
		if IsNumber(mixed) then
			for _, raw in ipairs(self.raws) do
				raw = raw:Lookup('WndScrollBar')
				if raw and raw.GetStepCount and raw.SetScrollPos then
					raw:SetScrollPos(raw:GetStepCount() * mixed / 100)
				end
			end
		elseif IsFunction(mixed) then
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
function UI:Range(nMin, nMax, nStep)
	self:_checksum()
	if IsNumber(nMin) and IsNumber(nMax) and nMax > nMin then
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
function UI:Value(nValue)
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
function UI:Multiline(bMultiLine)
	self:_checksum()
	if IsBoolean(bMultiLine) then
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
function UI:Image(szImage, nFrame, nOverFrame, nDownFrame, nDisableFrame)
	self:_checksum()
	if IsString(szImage) and IsNil(nFrame) then
		nFrame = tonumber((gsub(szImage, '.*%|(%d+)', '%1')))
		szImage = gsub(szImage, '%|.*', '')
	end
	if IsString(szImage) then
		szImage = wgsub(szImage, '/', '\\')
		if IsNumber(nFrame) and IsNumber(nOverFrame) and IsNumber(nDownFrame) and IsNumber(nDisableFrame) then
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
		elseif IsString(szImage) and IsNumber(nFrame) then
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
function UI:Frame(nFrame)
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
function UI:ItemInfo(...)
	local data = { ... }
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'BOX')
		if raw then
			if IsEmpty(data) then
				UpdataItemBoxObject(raw)
			else
				local KItemInfo = GetItemInfo(data[2], data[3])
				if KItemInfo.nGenre == ITEM_GENRE.BOOK and #data == 4 then -- 西山居BUG
					insert(data, 4, 99999)
				end
				local res, err, trace = XpCall(UpdataItemInfoBoxObject, raw, unpack(data)) -- 防止itemtab不一样
				if not res then
					FireUIEvent('CALL_LUA_ERROR', err .. '\n' .. PACKET_INFO.NAME_SPACE .. '#UI:ItemInfo\n' .. trace .. '\n')
				end
			end
		end
	end
	return self
end

-- (self) Instance:BoxInfo(nType, ...)
-- NOTICE：only for Box
function UI:BoxInfo(nType, ...)
	for _, raw in ipairs(self.raws) do
		raw = GetComponentElement(raw, 'BOX')
		if raw then
			if IsEmpty({ ... }) then
				UpdataItemBoxObject(raw)
			else
				local res, err, trace = XpCall(UpdateBoxObject, raw, nType, ...) -- 防止itemtab内外网不一样
				if not res then
					FireUIEvent('CALL_LUA_ERROR', err .. '\n' .. PACKET_INFO.NAME_SPACE .. '#UI:BoxInfo\n' .. trace .. '\n')
				end
			end
		end
	end
	return self
end

-- (self) Instance:Icon(dwIcon)
-- (number) Instance:Icon()
-- NOTICE：only for Box
function UI:Icon(dwIconID)
	self:_checksum()
	if IsNumber(dwIconID) then
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
function UI:HandleStyle(dwStyle)
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
function UI:ContainerType(dwType)
	self:_checksum()
	if dwType then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndContainer' then
				raw:SetContainerType(dwType)
			end
		end
	end
	return self
end

-- (self) Instance:EditType(dwType)
function UI:EditType(dwType)
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
function UI:Limit(nLimit)
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

-- (self) UI:Align(halign, valign)
function UI:Align(halign, valign)
	self:_checksum()
	if valign or halign then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'TEXT')
				or GetComponentElement(raw, 'MAIN_HANDLE')
			if raw then
				if halign and raw.SetHAlign then
					raw:SetHAlign(halign)
				end
				if valign and raw.SetVAlign then
					raw:SetVAlign(valign)
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
function UI:TrackbarStyle(nTrackbarStyle)
	self:_checksum()
	local bShowPercentage = nTrackbarStyle == UI.TRACKBAR_STYLE.SHOW_PERCENT
	for _, raw in ipairs(self.raws) do
		if GetComponentType(raw) == 'WndTrackbar' then
			SetComponentProp(raw, 'bShowPercentage', bShowPercentage)
		end
	end
	return self
end

-- (self) UI:ButtonStyle(nButtonStyle)
function UI:ButtonStyle(nButtonStyle)
	self:_checksum()
	local tStyle = UI.BUTTON_STYLE[nButtonStyle]
	if tStyle then
		for _, raw in ipairs(self.raws) do
			if GetComponentType(raw) == 'WndButton' then
				raw:SetAnimatePath((wgsub(tStyle.szImage, '/', '\\')))
				raw:SetAnimateGroupNormal(tStyle.nNormalGroup)
				raw:SetAnimateGroupMouseOver(tStyle.nMouseOverGroup)
				raw:SetAnimateGroupMouseDown(tStyle.nMouseDownGroup)
				raw:SetAnimateGroupDisable(tStyle.nDisableGroup)
				SetComponentSize(raw, tStyle.nWidth, tStyle.nHeight)
			end
		end
	end
	return self
end

-- (self) UI:FormatChildrenPos()
function UI:FormatChildrenPos()
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
function UI:BringToTop()
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
function UI:BringToBottom()
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
function UI:Event(szEvent, fnEvent)
	self:_checksum()
	if IsString(szEvent) then
		local nPos, szKey = (StringFindW(szEvent, '.'))
		if nPos then
			szKey = sub(szEvent, nPos + 1)
			szEvent = sub(szEvent, 1, nPos - 1)
		end
		if IsFunction(fnEvent) then
			for _, raw in ipairs(self.raws) do
				if raw:GetType() == 'WndFrame' then
					local events = GetComponentProp(raw, 'onEvents')
					if not events then
						events = {}
						local onEvent = IsFunction(raw.OnEvent) and raw.OnEvent
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
						for i, p in ipairs_r(events[szEvent]) do
							if p.id == szKey then
								remove(events[szEvent], i)
							end
						end
					end
					insert(events[szEvent], { id = szKey, fn = fnEvent })
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
							for i, p in ipairs_r(events[szEvent]) do
								if p.id == szKey then
									remove(events[szEvent], i)
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
function UI:UIEvent(szEvent, fnEvent)
	self:_checksum()
	if IsString(szEvent) then
		local nPos, szKey = (StringFindW(szEvent, '.'))
		if nPos then
			szKey = sub(szEvent, nPos + 1)
			szEvent = sub(szEvent, 1, nPos - 1)
		end
		if IsFunction(fnEvent) then
			for _, raw in ipairs(self.raws) do
				local uievents = GetComponentProp(raw, 'uievents')
				if not uievents then
					uievents = {}
					SetComponentProp(raw, 'uievents', uievents)
				end
				if not uievents[szEvent] then
					uievents[szEvent] = {}
					local onEvent = IsFunction(raw[szEvent]) and raw[szEvent]
					raw[szEvent] = function(...)
						if onEvent then
							onEvent(...)
						end
						local rets = {}
						for _, p in ipairs(uievents[szEvent]) do
							local res = { p.fn(...) }
							if #res > 0 then
								if #rets == 0 then
									rets = res
								--[[#DEBUG BEGIN]]
								else
									LIB.Debug(
										'UI:UIEvent#' .. szEvent .. ':' .. (p.id or 'Unnamed'),
										_L('Set return value failed, cause another hook has alreay take a returnval. [Path] %s', UI.GetTreePath(raw)),
										DEBUG_LEVEL.WARNING
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
				insert(uievents[szEvent], { id = szKey, fn = fnEvent })
			end
		else
			for _, raw in ipairs(self.raws) do
				local uievents = GetComponentProp(raw, 'uievents')
				if uievents then
					if not szKey then
						for e, _ in pairs(uievents) do
							uievents[e] = {}
						end
					elseif uievents[szEvent] then
						for i, p in ipairs_r(uievents[szEvent]) do
							if p.id == szKey then
								remove(uievents[szEvent], i)
							end
						end
					end
				end
			end
		end
	end
	return self
end

-- customMode 设置Frame的CustomMode
-- (self) Instance:CustomMode(string szTip, function fnOnEnterCustomMode, function fnOnLeaveCustomMode)
function UI:CustomMode(szTip, fnOnEnterCustomMode, fnOnLeaveCustomMode, szPoint)
	self:_checksum()
	if IsString(szTip) then
		self:Event('ON_ENTER_CUSTOM_UI_MODE', function()
			UpdateCustomModeWindow(this, szTip, GetComponentProp(this, 'bPenetrable'))
		end):Event('ON_LEAVE_CUSTOM_UI_MODE', function()
			UpdateCustomModeWindow(this, szTip, GetComponentProp(this, 'bPenetrable'))
		end)
		if IsFunction(fnOnEnterCustomMode) then
			self:Event('ON_ENTER_CUSTOM_UI_MODE', function()
				fnOnEnterCustomMode(GetFrameAnchor(this, szPoint))
			end)
		end
		if IsFunction(fnOnLeaveCustomMode) then
			self:Event('ON_LEAVE_CUSTOM_UI_MODE', function()
				fnOnLeaveCustomMode(GetFrameAnchor(this, szPoint))
			end)
		end
	end
	return self
end

-- breathe 设置Frame的breathe
-- (self) Instance:Breathe(function fnOnFrameBreathe)
function UI:Breathe(fnOnFrameBreathe)
	self:_checksum()
	if IsFunction(fnOnFrameBreathe) then
		for _, raw in ipairs(self.raws) do
			if raw:GetType() == 'WndFrame' then
				UI(raw):UIEvent('OnFrameBreathe', fnOnFrameBreathe)
			end
		end
	end
	return self
end

-- menu 弹出菜单
-- :Menu(table menu)  弹出菜单menu
-- :Menu(function fn)  弹出菜单function返回值table
function UI:Menu(lmenu, rmenu, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		rmenu = rmenu or lmenu
	end
	-- pop menu function
	local fnPopMenu = function(raw, menu)
		local h = raw:Lookup('', '') or raw
		local nX, nY = h:GetAbsPos()
		local nW, nH = h:GetSize()
		if IsFunction(menu) then
			menu = menu(raw)
		end
		if type(menu) ~= 'table' then
			return
		end
		menu.nMiniWidth = nW
		menu.x = nX
		menu.y = nY + nH
		menu.bVisibleWhenHideUI = true
		UI.PopupMenu(menu)
	end
	-- bind left click
	if lmenu then
		self:Each(function(eself)
			eself:LClick(function() fnPopMenu(eself[1], lmenu) end)
		end)
	end
	-- bind right click
	if rmenu then
		self:Each(function(eself)
			eself:RClick(function() fnPopMenu(eself[1], rmenu) end)
		end)
	end
	return self
end

-- lmenu 弹出左键菜单
-- :LMenu(table menu)  弹出菜单menu
-- :LMenu(function fn)  弹出菜单function返回值table
function UI:LMenu(menu)
	return self:Menu(menu, nil, true)
end

-- rmenu 弹出右键菜单
-- :LMenu(table menu)  弹出菜单menu
-- :LMenu(function fn)  弹出菜单function返回值table
function UI:RMenu(menu)
	return self:Menu(nil, menu, true)
end

-- click 鼠标单击事件
-- same as jQuery.click()
-- :Click(fnAction) 绑定
-- :Click()         触发
-- :Click(number n) 触发
-- n: 1    左键
--    0    中键
--   -1    右键
function UI:Click(fnLClick, fnRClick, fnMClick, bNoAutoBind)
	self:_checksum()
	if IsFunction(fnLClick) or IsFunction(fnMClick) or IsFunction(fnRClick) then
		if not bNoAutoBind then
			fnMClick = fnMClick or fnLClick
			fnRClick = fnRClick or fnLClick
		end
		for _, raw in ipairs(self.raws) do
			if IsFunction(fnLClick) then
				local fnAction = function()
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					LIB.ExecuteWithThis(raw, fnLClick, UI.MOUSE_EVENT.LBUTTON)
				end
				if GetComponentType(raw) == 'WndScrollBox' then
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
			if IsFunction(fnMClick) then

			end
			if IsFunction(fnRClick) then
				local fnAction = function()
					if GetComponentProp(raw, 'bEnable') == false then
						return
					end
					LIB.ExecuteWithThis(raw, fnRClick, UI.MOUSE_EVENT.RBUTTON)
				end
				if GetComponentType(raw) == 'WndScrollBox' then
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
		local nFlag = fnLClick or fnMClick or fnRClick or UI.MOUSE_EVENT.LBUTTON
		if nFlag == UI.MOUSE_EVENT.LBUTTON then
			for _, raw in ipairs(self.raws) do
				local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
				local itm = GetComponentElement(raw, 'ITEM')
				if wnd and wnd.OnLButtonClick then
					local _this = this
					this = wnd
					Call(wnd.OnLButtonClick)
					this = _this
				end
				if itm and itm.OnItemLButtonClick then
					local _this = this
					this = itm
					Call(itm.OnItemLButtonClick)
					this = _this
				end
			end
		elseif nFlag==UI.MOUSE_EVENT.MBUTTON then

		elseif nFlag==UI.MOUSE_EVENT.RBUTTON then
			for _, raw in ipairs(self.raws) do
				local wnd = GetComponentElement(raw, 'MAIN_WINDOW')
				local itm = GetComponentElement(raw, 'ITEM')
				if wnd and wnd.OnRButtonClick then
					local _this = this
					this = wnd
					Call(wnd.OnRButtonClick)
					this = _this
				end
				if itm and itm.OnItemRButtonClick then
					local _this = this
					this = itm
					Call(itm.OnItemRButtonClick)
					this = _this
				end
			end
		end
	end
	return self
end

-- lclick 鼠标左键单击事件
-- same as jQuery.lclick()
-- :LClick(fnAction) 绑定
-- :LClick()         触发
function UI:LClick(fnLClick)
	return self:Click(fnLClick or UI.MOUSE_EVENT.LBUTTON, nil, nil, true)
end

-- rclick 鼠标右键单击事件
-- same as jQuery.rclick()
-- :RClick(fnAction) 绑定
-- :RClick()         触发
function UI:RClick(fnRClick)
	return self:Click(nil, fnRClick or UI.MOUSE_EVENT.RBUTTON, nil, true)
end

-- mclick 鼠标右键单击事件
-- same as jQuery.mclick()
-- :MClick(fnAction) 绑定
-- :MClick()         触发
function UI:MClick(fnMClick)
	return self:Click(nil, nil, fnMClick or UI.MOUSE_EVENT.MBUTTON, true)
end

-- complete 加载完成事件
-- :Complete(fnOnComplete) 绑定
function UI:Complete(fnOnComplete)
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

-- hover 鼠标悬停事件
-- same as jQuery.hover()
-- :Hover(fnHover[, fnLeave]) 绑定
function UI:Hover(fnHover, fnLeave, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		fnLeave = fnLeave or fnHover
	end
	if fnHover then
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'EDIT') or GetComponentElement(raw, 'MAIN_WINDOW')
			local itm = GetComponentElement(raw, 'ITEM')
			if wnd then
				UI(wnd):UIEvent('OnMouseIn', function() fnHover(true) end)
			elseif itm then
				itm:RegisterEvent(256)
				UI(itm):UIEvent('OnItemMouseIn', function() fnHover(true) end)
			end
		end
	end
	if fnLeave then
		for _, raw in ipairs(self.raws) do
			local wnd = GetComponentElement(raw, 'EDIT') or GetComponentElement(raw, 'MAIN_WINDOW')
			local itm = GetComponentElement(raw, 'ITEM')
			if wnd then
				UI(wnd):UIEvent('OnMouseOut', function() fnLeave(false) end)
			elseif itm then
				itm:RegisterEvent(256)
				UI(itm):UIEvent('OnItemMouseOut', function() fnLeave(false) end)
			end
		end
	end
	return self
end

-- tip 鼠标悬停提示
-- (self) Instance:Tip( tip[, nPosType[, tOffset[, bNoEncode] ] ] ) 绑定tip事件
-- string|function tip:要提示的文字文本或序列化的DOM文本或返回前述文本的函数
-- number nPosType:    提示位置 有效值为UI.TIP_HIDEWAY.枚举
-- table tOffset:      提示框偏移量等附加信息{ x = x, y = y, hide = UI.TIP_HIDEWAY.Hide枚举, nFont = 字体, r, g, b = 字颜色 }
-- boolean bNoEncode:  当szTip为纯文本时保持这个参数为false 当szTip为格式化的DOM字符串时设置该参数为true
function UI:Tip(tip, nPosType, tOffset, bNoEncode)
	tOffset = tOffset or {}
	tOffset.x = tOffset.x or 0
	tOffset.y = tOffset.y or 0
	tOffset.w = tOffset.w or 450
	tOffset.hide = tOffset.hide or UI.TIP_HIDEWAY.HIDE
	tOffset.nFont = tOffset.nFont or 136
	nPosType = nPosType or UI.TIP_POSITION.FOLLOW_MOUSE
	return self:Hover(function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		if nPosType == UI.TIP_POSITION.FOLLOW_MOUSE then
			x, y = Cursor.GetPos()
			x, y = x - 0, y - 40
		end
		x, y = x + tOffset.x, y + tOffset.y
		local szTip = tip
		if IsFunction(szTip) then
			szTip = szTip(self)
		end
		if IsEmpty(szTip) then
			return
		end
		if not bNoEncode then
			szTip = GetFormatText(szTip, tOffset.nFont, tOffset.r, tOffset.g, tOffset.b)
		end
		OutputTip(szTip, tOffset.w, {x, y, w, h}, nPosType)
	end, function()
		if tOffset.hide == UI.TIP_HIDEWAY.HIDE then
			HideTip(false)
		elseif tOffset.hide == UI.TIP_HIDEWAY.ANIMATE_HIDE then
			HideTip(true)
		end
	end, true)
end

-- check 复选框状态变化
-- :Check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) 绑定
-- :Check()                返回是否已勾选
-- :Check(bool bChecked)   勾选/取消勾选
function UI:Check(fnCheck, fnUncheck, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		fnUncheck = fnUncheck or fnCheck
	end
	if IsFunction(fnCheck) or IsFunction(fnUncheck) then
		for _, raw in ipairs(self.raws) do
			local chk = GetComponentElement(raw, 'CHECKBOX')
			if chk then
				if IsFunction(fnCheck) then
					UI(chk):UIEvent('OnCheckBoxCheck', function() fnCheck(true) end)
				end
				if IsFunction(fnUncheck) then
					UI(chk):UIEvent('OnCheckBoxUncheck', function() fnUncheck(false) end)
				end
			end
		end
		return self
	elseif IsBoolean(fnCheck) then
		for _, raw in ipairs(self.raws) do
			local chk = GetComponentElement(raw, 'CHECKBOX')
			if chk then
				chk:Check(fnCheck)
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
		LIB.Debug('ERROR UI:Check', 'fnCheck:'..type(fnCheck)..' fnUncheck:'..type(fnUncheck), DEBUG_LEVEL.ERROR)
	--[[#DEBUG END]]
	end
end

-- change 输入框文字变化
-- :Change(fnOnChange) 绑定
-- :Change()   调用处理函数
function UI:Change(fnOnChange)
	self:_checksum()
	if IsFunction(fnOnChange) then
		for _, raw in ipairs(self.raws) do
			local edt = GetComponentElement(raw, 'EDIT')
			if edt then
				UI(edt):UIEvent('OnEditChanged', function() LIB.ExecuteWithThis(raw, fnOnChange, edt:GetText()) end)
			end
			if GetComponentType(raw) == 'WndTrackbar' then
				insert(GetComponentProp(raw, 'onChangeEvents'), fnOnChange)
			end
		end
		return self
	else
		for _, raw in ipairs(self.raws) do
			local edt = GetComponentElement(raw, 'EDIT')
			if edt and edt.OnEditChanged then
				local _this = this
				this = edt
				Call(edt.OnEditChanged, raw)
				this = _this
			end
			if GetComponentType(raw) == 'WndTrackbar' then
				local sld = GetComponentElement(raw, 'TRACKBAR')
				if sld and sld.OnScrollBarPosChanged then
					local _this = this
					this = sld
					Call(sld.OnScrollBarPosChanged, raw)
					this = _this
				end
			end
		end
		return self
	end
end

function UI:Navigate(szURL)
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
function UI:Focus(fnOnSetFocus)
	self:_checksum()
	if fnOnSetFocus then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				UI(raw):UIEvent('OnSetFocus', function()
					Call(fnOnSetFocus, self)
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
function UI:Blur(fnOnKillFocus)
	self:_checksum()
	if fnOnKillFocus then
		for _, raw in ipairs(self.raws) do
			raw = GetComponentElement(raw, 'EDIT')
			if raw then
				UI(raw):UIEvent('OnKillFocus', function() LIB.ExecuteWithThis(raw, fnOnKillFocus) end)
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

---------------------------------------------------------------------
-- 可重复利用的简易 Handle 元件缓存池
---------------------------------------------------------------------
local HandlePool = {}
HandlePool.__index = HandlePool
-- construct
function HandlePool:ctor(handle, xml)
	local oo = {}
	setmetatable(oo, self)
	oo.handle, oo.xml = handle, xml
	handle.nFreeCount = 0
	handle:Clear()
	return oo
end

-- clear
function HandlePool:Clear()
	self.handle:Clear()
	self.handle.nFreeCount = 0
end

-- new item
function HandlePool:New()
	local handle = self.handle
	local nCount = handle:GetItemCount()
	if handle.nFreeCount > 0 then
		for i = nCount - 1, 0, -1 do
			local item = handle:Lookup(i)
			if item.bFree then
				item.bFree = false
				handle.nFreeCount = handle.nFreeCount - 1
				return item
			end
		end
		handle.nFreeCount = 0
	else
		handle:AppendItemFromString(self.xml)
		local item = handle:Lookup(nCount)
		item.bFree = false
		return item
	end
end

-- remove item
function HandlePool:Remove(item)
	if item:IsValid() then
		self.handle:RemoveItem(item)
	end
end

-- free item
function HandlePool:Free(item)
	if item:IsValid() then
		self.handle.nFreeCount = self.handle.nFreeCount + 1
		item.bFree = true
		item:SetName('')
		item:Hide()
	end
end

function HandlePool:GetAllItem(bShow)
	local t = {}
	for i = self.handle:GetItemCount() - 1, 0, -1 do
		local item = self.handle:Lookup(i)
		if bShow and item:IsVisible() or not bShow then
			insert(t, item)
		end
	end
	return t
end
-- public api, create pool
-- (class) UI.HandlePool(userdata handle, string szXml)
UI.HandlePool = setmetatable({}, { __call = function(me, ...) return HandlePool:ctor( ... ) end, __metatable = true, __newindex = function() end })

---------------------------------------------------
-- create new frame
-- (ui) UI.CreateFrame(string szName, table opt)
-- @param string szName: the ID of frame
-- @param table  opt   : options
---------------------------------------------------
function  UI.CreateFrame(szName, opt)
	if not IsTable(opt) then
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
	local szIniFile = PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrame.ini'
	if opt.simple then
		szIniFile = PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrameSimple.ini'
	elseif opt.empty then
		szIniFile = PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrameEmpty.ini'
	end

	-- close and reopen exist frame
	local frm = Station.Lookup(opt.level .. '/' .. szName)
	if frm then
		Wnd.CloseWindow(frm)
	end
	frm = Wnd.OpenWindow(szIniFile, szName)
	frm:ChangeRelation(opt.level)
	frm:Show()
	local ui = UI(frm)
	-- init frame
	if opt.esc then
		LIB.RegisterEsc('Frame_Close_' .. szName, function()
			return true
		end, function()
			if frm.OnCloseButtonClick then
				local status, res = Call(frm.OnCloseButtonClick)
				if status and res then
					return
				end
			end
			Wnd.CloseWindow(frm)
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
			LIB.RegisterEsc('Frame_Close_' .. szName)
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
				if select(2, LIB.ExecuteWithThis(frm, frm.OnMinimize, frm:Lookup('Wnd_Total'))) then
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
				LIB.ExecuteWithThis(frm, frm.OnRestore, frm:Lookup('Wnd_Total'))
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
				if select(2, LIB.ExecuteWithThis(frm, frm.OnMaximize, frm:Lookup('Wnd_Total'))) then
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
				LIB.ExecuteWithThis(frm, frm.OnRestore, frm:Lookup('Wnd_Total'))
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
				local W, H = Station.GetClientSize()
				local X, Y = frm:GetRelPos()
				local w, h = x - X, y - Y
				w = min(w, W - X) -- frame size should not larger than client size
				h = min(h, H - Y)
				w = max(w, opt.minwidth) -- frame size must larger than setted min size
				h = max(h, opt.minheight)
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
				w = max(w + 16, opt.minwidth)
				h = max(h + 16, opt.minheight)
				UI(frm):Size(w, h)
				if frm.OnDragResize then
					local res, err, trace = XpCall(frm.OnDragResize, frm:Lookup('Wnd_Total'))
					if not res then
						FireUIEvent('CALL_LUA_ERROR', err .. '\n' .. PACKET_INFO.NAME_SPACE .. '#OnDragResize\n' .. trace .. '\n')
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

-- 打开取色板
function UI.OpenColorPicker(callback, t)
	if t then
		return OpenColorTablePanel(callback,nil,nil,t)
	end
	local ui = UI.CreateFrame(PACKET_INFO.NAME_SPACE .. '_ColorTable', { simple = true, close = true, esc = true })
	  :Size(900, 500):Text(_L['color picker']):Anchor({s='CENTER', r='CENTER', x=0, y=0})
	local fnHover = function(bHover, r, g, b)
		if bHover then
			this:SetAlpha(255)
			ui:Children('#Select'):Color(r, g, b)
			ui:Children('#Select_Text'):Text(format('r=%d, g=%d, b=%d', r, g, b))
		else
			this:SetAlpha(200)
			ui:Children('#Select'):Color(255, 255, 255)
			ui:Children('#Select_Text'):Text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if callback then callback( ... ) end
		if not IsCtrlKeyDown() then
			ui:Remove()
		end
	end
	for nRed = 1, 8 do
		for nGreen = 1, 8 do
			for nBlue = 1, 8 do
				local x = 20 + ((nRed - 1) % 4) * 220 + (nGreen - 1) * 25
				local y = 10 + modf((nRed - 1) / 4) * 220 + (nBlue - 1) * 25
				local r, g, b  = nRed * 32 - 1, nGreen * 32 - 1, nBlue * 32 - 1
				ui:Append('Shadow', {
					w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
					onhover = function(bHover)
						fnHover(bHover, r, g, b)
					end,
					onclick = function()
						fnClick(r, g, b)
					end,
				})
			end
		end
	end

	for i = 1, 16 do
		local x = 480 + (i - 1) * 25
		local y = 435
		local r, g, b  = i * 16 - 1, i * 16 - 1, i * 16 - 1
		ui:Append('Shadow', {
			w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
			onhover = function(bHover)
				fnHover(bHover, r, g, b)
			end,
			onclick = function()
				fnClick(r, g, b)
			end,
		})
	end
	ui:Append('Shadow', { name = 'Select', w = 25, h = 25, x = 20, y = 435 })
	ui:Append('Text', { name = 'Select_Text', x = 65, y = 435 })
	local GetRGBValue = function()
		local r, g, b  = tonumber(ui:Children('#R'):Text()), tonumber(ui:Children('#G'):Text()), tonumber(ui:Children('#B'):Text())
		if r and g and b and r <= 255 and g <= 255 and b <= 255 then
			return r, g, b
		end
	end
	local onChange = function()
		if GetRGBValue() then
			local r, g, b = GetRGBValue()
			fnHover(true, r, g, b)
		end
	end
	local x, y = 220, 435
	ui:Append('Text', { text = 'R', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'R', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'G', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'G', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'B', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'B', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('WndButton', { text = g_tStrings.STR_HOTKEY_SURE, x = x + 5, y = y + 3, w = 50, h = 30, onclick = function()
		if GetRGBValue() then
			fnClick(GetRGBValue())
		else
			LIB.Sysmsg(_L['RGB value error'])
		end
	end})
	x = x + 50
	ui:Append('WndButton', { text = _L['color picker ex'], x = x + 5, y = y + 3, w = 50, h = 30, onclick = function()
		UI.OpenColorPickerEx(callback):Pos(ui:Pos())
		ui:Remove()
	end})
	Station.SetFocusWindow(ui[1])
	-- OpenColorTablePanel(callback,nil,nil,t)
	--  or {
	--     { r = 0,   g = 255, b = 0  },
	--     { r = 0,   g = 255, b = 255},
	--     { r = 255, g = 0  , b = 0  },
	--     { r = 40,  g = 140, b = 218},
	--     { r = 211, g = 229, b = 37 },
	--     { r = 65,  g = 50 , b = 160},
	--     { r = 170, g = 65 , b = 180},
	-- }
	return ui
end

-- 调色板
local COLOR_HUE = 0
function UI.OpenColorPickerEx(fnAction)
	local fX, fY = Cursor.GetPos(true)
	local tUI = {}
	local function hsv2rgb(h, s, v)
		s = s / 100
		v = v / 100
		local r, g, b = 0, 0, 0
		local h = h / 60
		local i = floor(h)
		local f = h - i
		local p = v * (1 - s)
		local q = v * (1 - s * f)
		local t = v * (1 - s * (1 - f))
		if i == 0 or i == 6 then
			r, g, b = v, t, p
		elseif i == 1 then
			r, g, b = q, v, p
		elseif i == 2 then
			r, g, b = p, v, t
		elseif i == 3 then
			r, g, b = p, q, v
		elseif i == 4 then
			r, g, b = t, p, v
		elseif i == 5 then
			r, g, b = v, p, q
		end
		return floor(r * 255), floor(g * 255), floor(b * 255)
	end

	local wnd = UI.CreateFrame(PACKET_INFO.NAME_SPACE .. '_ColorPickerEx', { w = 346, h = 430, text = _L['color picker ex'], simple = true, close = true, esc = true, x = fX + 15, y = fY + 15 })
	local fnHover = function(bHover, r, g, b)
		if bHover then
			wnd:Children('#Select'):Color(r, g, b)
			wnd:Children('#Select_Text'):Text(format('r=%d, g=%d, b=%d', r, g, b))
		else
			wnd:Children('#Select'):Color(255, 255, 255)
			wnd:Children('#Select_Text'):Text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if fnAction then fnAction( ... ) end
		if not IsCtrlKeyDown() then wnd:Remove() end
	end
	local function SetColor()
		for v = 100, 0, -3 do
			tUI[v] = tUI[v] or {}
			for s = 0, 100, 3 do
				local x = 20 + s * 3
				local y = 80 + (100 - v) * 3
				local r, g, b = hsv2rgb(COLOR_HUE, s, v)
				if tUI[v][s] then
					tUI[v][s]:Color(r, g, b)
				else
					tUI[v][s] = wnd:Append('Shadow', {
						w = 9, h = 9, x = x, y = y, color = { r, g, b },
						onhover = function(bHover)
							wnd:Children('#Select_Image'):Pos(this:GetRelPos()):Toggle(bHover)
							local r, g, b = this:GetColorRGB()
							fnHover(bHover, r, g, b)
						end,
						onclick = function()
							fnClick(this:GetColorRGB())
						end,
					})
				end
			end
		end
	end
	SetColor()
	wnd:Append('Image', { name = 'Select_Image', w = 9, h = 9, x = 0, y = 0 }):Image('ui/Image/Common/Box.Uitex', 9):Toggle(false)
	wnd:Append('Shadow', { name = 'Select', w = 25, h = 25, x = 20, y = 10, color = { 255, 255, 255 } })
	wnd:Append('Text', { name = 'Select_Text', x = 50, y = 10, text = g_tStrings.STR_NONE })
	wnd:Append('WndTrackbar', {
		x = 20, y = 35, h = 25, w = 306, rw = 272,
		textfmt = function(val) return ('%d H'):format(val) end,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = COLOR_HUE, range = {0, 360},
		onchange = function(nVal)
			COLOR_HUE = nVal
			SetColor()
		end,
	})
	for i = 0, 360, 8 do
		wnd:Append('Shadow', { x = 20 + (0.74 * i), y = 60, h = 10, w = 6, color = { hsv2rgb(i, 100, 100) } })
	end
	Station.SetFocusWindow(wnd[1])
	return wnd
end

-- 打开字体选择
function UI.OpenFontPicker(callback, t)
	local ui, i = UI.CreateFrame(PACKET_INFO.NAME_SPACE .. '_Font_Picker', { simple = true, close = true, esc = true, text = _L['Font picker'] }), 0
	while 1 do
		local font = i
		local txt = ui:Append('Text', {
			w = 70, x = i % 10 * 80 + 20, y = floor(i / 10) * 25,
			font = font, alpha = 200, text = _L('Font %d', font),
			onclick = function()
				if callback then
					callback(font)
				end
				if not IsCtrlKeyDown() then
					ui:Remove()
				end
			end,
			onhover = function(bIn)
				UI(this):Alpha(bIn and 255 or 200)
			end,
		})
		-- remove unexist font
		if txt:Font() ~= font then
			txt:Remove()
			break
		end
		i = i + 1
	end
	return ui:Size(820, 70 + floor(i / 10) * 25):Anchor({ s = 'CENTER', r = 'CENTER', x = 0, y = 0 }):Focus()
end

do local ICON_PAGE, MAX_ICON
-- icon选择器
function UI.OpenIconPanel(fnAction)
	if not MAX_ICON then
		local szPath = 'ui\\Scheme\\Case\\icon.txt'
		local tTitle = {
			{ f = 'i', t = 'dwID'       },
			{ f = 's', t = 'szFileName' },
			{ f = 'i', t = 'nFrame'     },
			{ f = 's', t = 'szKind'     },
			{ f = 's', t = 'szSubKind'  },
			{ f = 's', t = 'szTag1'     },
			{ f = 's', t = 'szTag2'     },
		}
		local tInfo = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL)
		if tInfo then
			local nRowCount = tInfo:GetRowCount()
			local nMaxL = nRowCount - 256     -- 折半查找左端数值
			local nMaxR = nRowCount + 256     -- 折半查找右端数值
			local bMaxL = tInfo:Search(nMaxL) -- 折半查找左端结果
			local bMaxR = tInfo:Search(nMaxR) -- 折半查找右端结果
			local nCount, nMaxCount = 0, 1000 -- 折半次数统计 1000次折半查找还没找到多半是BUG了 判断上限防止死循环
			while true do
				if nMaxL < 1 then
					break
				elseif bMaxL and bMaxR then
					nMaxR = nMaxR * 2
					bMaxR = tInfo:Search(nMaxR)
				elseif not bMaxL and not bMaxR then
					nMaxL = floor(nMaxL / 2)
					bMaxL = tInfo:Search(nMaxL)
				else
					if bMaxL and not bMaxR then
						if nMaxL + 1 == nMaxR then
							MAX_ICON = nMaxL
							break
						else
							local nCur = floor(nMaxR - (nMaxR - nMaxL) / 2)
							local bCur = tInfo:Search(nCur)
							if bCur then
								nMaxL = nCur
							else
								nMaxR = nCur
							end
						end
					elseif not bMaxL and bMaxR then
						--[[#DEBUG BEGIN]]
						LIB.Debug('ERROR CALC MAX_ICON!', DEBUG_LEVEL.ERROR)
						--[[#DEBUG END]]
						break
					end
				end
				if nCount >= nMaxCount then
					break
				end
				nCount = nCount + 1
			end
		end
		MAX_ICON = MAX_ICON or 10000
	end
	local nMaxIcon, boxs, txts = MAX_ICON, {}, {}
	local ui = UI.CreateFrame(PACKET_INFO.NAME_SPACE .. '_IconPanel', { w = 920, h = 650, text = _L['Icon Picker'], simple = true, close = true, esc = true })
	local function GetPage(nPage, bInit)
		if nPage == ICON_PAGE and not bInit then
			return
		end
		ICON_PAGE = nPage
		local nStart = (nPage - 1) * 144
		for i = 1, 144 do
			local x = ((i - 1) % 18) * 50 + 10
			local y = floor((i - 1) / 18) * 70 + 10
			if boxs[i] then
				local nIcon = nStart + i
				if nIcon > nMaxIcon then
					boxs[i]:Toggle(false)
					txts[i]:Toggle(false)
				else
					boxs[i]:Icon(-1)
					txts[i]:Text(nIcon):Toggle(true)
					LIB.DelayCall(function()
						if ceil(nIcon / 144) == ICON_PAGE and boxs[i] then
							boxs[i]:Icon(nIcon):Toggle(true)
						end
					end)
				end
			else
				boxs[i] = ui:Append('Box', {
					w = 48, h = 48, x = x, y = y, icon = nStart + i,
					onhover = function(bHover)
						this:SetObjectMouseOver(bHover)
					end,
					onclick = function()
						if fnAction then
							fnAction(this:GetObjectIcon())
						end
						ui:Remove()
					end,
				})
				txts[i] = ui:Append('Text', { w = 48, h = 20, x = x, y = y + 48, text = nStart + i, align = 1 })
			end
		end
	end
	ui:Append('WndEditBox', { name = 'Icon', x = 730, y = 580, w = 50, h = 25, edittype = 0 })
	ui:Append('WndButton', {
		x = 800, y = 580,
		text = g_tStrings.STR_HOTKEY_SURE,
		buttonstyle = 2,
		onclick = function()
			local nIcon = tonumber(ui:Children('#Icon'):Text())
			if nIcon then
				if fnAction then
					fnAction(nIcon)
				end
				ui:Remove()
			end
		end,
	})
	ui:Append('WndTrackbar', {
		x = 10, y = 580, h = 25, w = 500, textfmt = ' Page: %d',
		range = {1, ceil(nMaxIcon / 144)}, value = ICON_PAGE or 21,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			LIB.DelayCall(function() GetPage(nVal) end)
		end,
	})
	GetPage(ICON_PAGE or 21, true)
end
end

-- 打开文本编辑器
function UI.OpenTextEditor(szText, szFrameName)
	if not szFrameName then
		szFrameName = PACKET_INFO.NAME_SPACE .. '_DefaultTextEditor'
	end
	local w, h, ui = 400, 300
	local function OnResize()
		ui:Children('.WndEditBox'):Size(ui:Size(true))
	end
	ui = UI.CreateFrame(szFrameName, {
		w = w, h = h, text = _L['text editor'], alpha = 180,
		anchor = { s='CENTER', r='CENTER', x=0, y=0 },
		simple = true, close = true, esc = true,
		dragresize = true, minimize = true, ondragresize = OnResize,
	})
	ui:Append('WndEditBox', { x = 0, y = 0, multiline = true, text = szText })
	ui:Focus()
	OnResize()
	return ui
end

-- 打开文本列表编辑器
function UI.OpenListEditor(szFrameName, tTextList, OnAdd, OnDel)
	local muDel
	local AddListItem = function(muList, szText)
		local muItem = muList:Append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):Children():Last()
		local hHandle = muItem[1]
		hHandle.Value = szText
		local hText = muItem:Children('#Text_Default'):Pos(10, 2):Text(szText or '')[1]
		muItem:Children('#Image_Bg'):Image('UI/Image/Common/TextShadow.UITex',5):Alpha(0):Hover(function(bIn)
			if hHandle.Selected then return nil end
			if bIn then
				UI(this):FadeIn(100)
			else
				UI(this):FadeTo(500,0)
			end
		end):Click(function(nButton)
			if nButton == UI.MOUSE_EVENT.RBUTTON then
				hHandle.Selected = true
				UI.PopupMenu({{
					szOption = _L['delete'],
					fnAction = function()
						muDel:Click()
					end,
				}})
			else
				hHandle.Selected = not hHandle.Selected
			end
			if hHandle.Selected then
				UI(this):Image('UI/Image/Common/TextShadow.UITex',2)
			else
				UI(this):Image('UI/Image/Common/TextShadow.UITex',5)
			end
		end)
	end
	local ui = UI.CreateFrame(szFrameName)
	ui:Append('Image', { x = -10, y = 25, w = 360, h = 10, image = 'UI/Image/UICommon/Commonpanel.UITex', imageframe = 42 })
	local muEditBox = ui:Append('WndEditBox', { x = 0, y = 0, w = 170, h = 25 })
	local muList = ui:Append('WndScrollBox', { handlestyle = 3, x = 0, y = 30, w = 340, h = 380 })
	-- add
	ui:Append('WndButton', {
		x = 180, y = 0, w = 80, text = _L['add'],
		onclick = function()
			local szText = muEditBox:Text()
			-- 加入表
			if OnAdd then
				if OnAdd(szText) ~= false then
					AddListItem(muList, szText)
				end
			else
				AddListItem(muList, szText)
			end
		end,
	})
	-- del
	muDel = ui:Append('WndButton', {
		x = 260, y = 0, w = 80, text = _L['delete'],
		onclick = function()
			muList:Children():Each(function(ui)
				if this.Selected then
					if OnDel then
						OnDel(this.Value)
					end
					ui:Remove()
				end
			end)
		end,
	})
	-- insert data to ui
	for i, v in ipairs(tTextList) do
		AddListItem(muList, v)
	end
	Station.SetFocusWindow(ui[1])
	return ui
end

-- 判断浏览器是否已开启
local function IsInternetExplorerOpened(nIndex)
	local frame = Station.Lookup('Topmost/IE'..nIndex)
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

-- 获取浏览器绝对位置
local function IE_GetNewIEFramePos()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup('Topmost/IE'..i)
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup('Topmost/IE'..nLastIndex)
		local x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

-- 打开浏览器
function UI.OpenIE(szAddr, bDisableSound, w, h)
	local nIndex, nLast = nil, nil
	for i = 1, 10, 1 do
		if not IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow('InternetExplorer', 'IE'..nIndex)
	frame.bIE = true
	frame.nIndex = nIndex

	if w and h then
		UI.ResizeIE(frame, w, h)
	end
	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup('WebPage_Page')
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end

function UI.ResizeIE(frame, w, h)
	if w < 400 then w = 400 end
	if h < 200 then h = 200 end
	local handle = frame:Lookup('', '')
	handle:SetSize(w, h)
	handle:Lookup('Image_Bg'):SetSize(w, h)
	handle:Lookup('Image_BgT'):SetSize(w - 6, 64)
	if not frame.bQuestionnaire then
		handle:Lookup('Image_Edit'):SetSize(w - 300, 25)
	end
	handle:Lookup('Text_Title'):SetSize(w - 168, 30)
	handle:FormatAllItemPos()

	local webPage = frame:Lookup('WebPage_Page')
	if frame.bQuestionnaire then
		webPage:SetSize(w - 20, h - 140)
	else
		webPage:SetSize(w - 12, h - 76)
		frame:Lookup('Edit_Input'):SetSize(w - 306, 20)
		frame:Lookup('Btn_GoTo'):SetRelPos(w - 110, 38)
	end

	frame:Lookup('Btn_Close'):SetRelPos(w - 40, 10)
	frame:Lookup('CheckBox_MaxSize'):SetRelPos(w - 70, 10)

	frame:Lookup('Btn_DL'):SetSize(10, h - 20)
	frame:Lookup('Btn_DT'):SetSize(w - 20, 10)
	frame:Lookup('Btn_DTR'):SetRelPos(w - 10, 0)
	frame:Lookup('Btn_DR'):SetRelPos(w - 10, 10)
	frame:Lookup('Btn_DR'):SetSize(10, h - 20)
	frame:Lookup('Btn_DRB'):SetRelPos(w - 10, h - 10)
	frame:Lookup('Btn_DB'):SetRelPos(10, h - 10)
	frame:Lookup('Btn_DB'):SetSize(w - 20, 10)
	frame:Lookup('Btn_DLB'):SetRelPos(0, h - 10)

	frame:SetSize(w, h)
	frame:SetDragArea(0, 0, w, 30)
end

function UI.PopupMenu(menu)
	return MY_PopupMenu.Open(menu)
end

function UI.ClosePopupMenu()
	return MY_PopupMenu.Close()
end

-- append an item to parent
-- UI.Append(hParent, szType,[ szName,] tArg)
-- hParent     -- an Window, Handle or UI object
-- szName      -- name of the object inserted
-- tArg        -- param like width, height, left, right, etc.
-- function UI.Append(hParent, szType, szName, tArg)
-- 	return UI(hParent):Append(szType, szName, tArg)
-- end

function UI.GetTreePath(raw)
	local tTreePath = {}
	if IsTable(raw) and raw.GetTreePath then
		insert(tTreePath, (raw:GetTreePath()):sub(1, -2))
		while(raw and raw:GetType():sub(1, 3) ~= 'Wnd') do
			local szName = raw:GetName()
			if not szName or szName == '' then
				insert(tTreePath, 2, raw:GetIndex())
			else
				insert(tTreePath, 2, szName)
			end
			raw = raw:GetParent()
		end
	else
		insert(tTreePath, tostring(raw))
	end
	return concat(tTreePath, '/')
end

MY_Shadows = {}
function MY_Shadows.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	this:RegisterEvent('ON_FRAME_CREATE')
	UI(this):BringToBottom()
end

do
local VISIBLE = true
function MY_Shadows.OnFrameBreathe()
	if Station.IsVisible() then
		if not VISIBLE then
			local h = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				h:Lookup(i):SetVisible(true)
			end
			VISIBLE = true
		end
	else
		if VISIBLE then
			local h, hh = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				hh = h:Lookup(i)
				hh:SetVisible(hh.bShowWhenUIHide or false)
			end
			VISIBLE = false
		end
	end
end
end

function MY_Shadows.OnEvent(event)
	if event == 'LOADING_END' then
		this:Show()
	elseif event == 'COINSHOP_ON_OPEN' or event == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif event == 'COINSHOP_ON_CLOSE' or event == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	elseif event == 'ON_FRAME_CREATE' then
		UI(this):BringToBottom()
	end
end

function UI.GetShadowHandle(szName)
	local frame = Station.Lookup('Lowest/MY_Shadows')
	if frame and not IsElement(frame) then -- 关闭无效的 frame 句柄
		Wnd.CloseWindow('MY_Shadows')
		frame = nil
	end
	if not frame then
		frame = Wnd.OpenWindow(PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_Shadows.ini', 'MY_Shadows')
	end
	local sh = frame:Lookup('', szName)
	if sh and not IsElement(sh) then -- 关闭无效的 sh 句柄
		frame:Lookup('', ''):Remove(sh)
		sh = nil
	end
	if not sh then
		frame:Lookup('', ''):AppendItemFromString(format('<handle> name="%s" </handle>', szName))
		--[[#DEBUG BEGIN]]
		LIB.Debug('UI', 'Create sh # ' .. szName, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		sh = frame:Lookup('', szName)
	end
	return sh
end

function UI.SetShadowHandleParam(szName, tParam)
	local sh = UI.GetShadowHandle(szName)
	for k, v in pairs(tParam) do
		sh[k] = v
	end
end

do local VISIBLES = {}
function UI.TempSetShadowHandleVisible(bVisible)
	local frame = Station.Lookup('Lowest/MY_Shadows')
	if not frame then
		return insert(VISIBLES, true)
	end
	insert(VISIBLES, frame:IsVisible() or false)
	frame:SetVisible(bVisible)
end

function UI.RevertShadowHandleVisible()
	if #VISIBLES == 0 then
		return
	end
	local bVisible = remove(VISIBLES)
	local frame = Station.Lookup('Lowest/MY_Shadows')
	if frame then
		frame:SetVisible(bVisible)
	end
end
end

do
local ui, cache
function UI.GetTempElement(szType)
	if not IsString(szType) then
		return
	end
	local szKey = nil
	local nPos = StringFindW(szType, '.')
	if nPos then
		szKey = sub(szType, nPos + 1)
		szType = sub(szType, 1, nPos - 1)
	end
	if not IsString(szKey) then
		szKey = 'Default'
	end
	if not cache or not ui or ui:Count() == 0 then
		cache = {}
		ui = UI.CreateFrame(PACKET_INFO.NAME_SPACE .. '#TempElement', { empty = true }):Hide()
	end
	local szName = szType .. '_' .. szKey
	local raw = cache[szName]
	if not raw then
		raw = ui:Append(szType, {
			name = szName,
		})[1]
		cache[szName] = raw
	end
	return raw
end
end

function UI.ScrollIntoView(el, scrollY, nOffsetY, scrollX, nOffsetX)
	local elParent, nParentW, nParentH = el:GetParent()
	local nX, nY = el:GetAbsX() - elParent:GetAbsX(), el:GetAbsY() - elParent:GetAbsY()
	if elParent:GetType() == 'WndContainer' then
		nParentW, nParentH = elParent:GetAllContentSize()
	else
		nParentW, nParentH = elParent:GetAllItemSize()
	end
	if nOffsetY then
		nY = nY + nOffsetY
	end
	if scrollY then
		scrollY:SetScrollPos(nY / nParentH * scrollY:GetStepCount())
	end
	if nOffsetX then
		nX = nX + nOffsetX
	end
	if scrollX then
		scrollX:SetScrollPos(nX / nParentW * scrollX:GetStepCount())
	end
end

function UI.LookupFrame(szName)
	for _, v in ipairs(UI.LAYER_LIST) do
		local frame = Station.Lookup(v .. '/' .. szName)
		if frame then
			return frame
		end
	end
end

UI.UpdateItemInfoBoxObject = _G.UpdateItemInfoBoxObject or UpdataItemInfoBoxObject

LIB.UI = UI
