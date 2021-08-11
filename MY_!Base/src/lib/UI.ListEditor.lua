--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ListEditor
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
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

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
					szOption = _L['Delete'],
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
	local muList = ui:Append('WndScrollHandleBox', { handlestyle = 3, x = 0, y = 30, w = 340, h = 380 })
	-- add
	ui:Append('WndButton', {
		x = 180, y = 0, w = 80, text = _L['Add'],
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
		x = 260, y = 0, w = 80, text = _L['Delete'],
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
