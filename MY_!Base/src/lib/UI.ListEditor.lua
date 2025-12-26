--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ListEditor
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.ListEditor')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 打开文本列表编辑器
function X.UI.OpenListEditor(szFrameName, tTextList, OnAdd, OnDel)
	local muDel
	local AddListItem = function(muList, szText)
		local muItem = muList:Append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):Children():Last()
		local hHandle = muItem[1]
		hHandle.Value = szText
		local hText = muItem:Children('#Text_Default'):Pos(10, 2):Text(szText or '')[1]
		muItem:Children('#Image_Bg'):Image('UI/Image/Common/TextShadow.UITex',5):Alpha(0):Hover(function(bIn)
			if hHandle.Selected then return nil end
			if bIn then
				X.UI(this):FadeIn(100)
			else
				X.UI(this):FadeTo(500,0)
			end
		end):Click(function(nButton)
			if nButton == X.UI.MOUSE_BUTTON.RIGHT then
				hHandle.Selected = true
				X.UI.PopupMenu({{
					szOption = _L['Delete'],
					fnAction = function()
						muDel:Click()
					end,
				}})
			else
				hHandle.Selected = not hHandle.Selected
			end
			if hHandle.Selected then
				X.UI(this):Image('UI/Image/Common/TextShadow.UITex',2)
			else
				X.UI(this):Image('UI/Image/Common/TextShadow.UITex',5)
			end
		end)
	end
	local ui = X.UI.CreateFrame(szFrameName)
	ui:Append('Image', { x = -10, y = 25, w = 360, h = 10, image = 'UI/Image/UICommon/Commonpanel.UITex', imageFrame = 42 })
	local muEditBox = ui:Append('WndEditBox', { x = 0, y = 0, w = 170, h = 25 })
	local muList = ui:Append('WndScrollHandleBox', { handleStyle = 3, x = 0, y = 30, w = 340, h = 380 })
	-- add
	ui:Append('WndButton', {
		x = 180, y = 0, w = 80, text = _L['Add'],
		onClick = function()
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
		x = 260, y = 0, w = 80, text = _L['Delete'],
		onClick = function()
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
