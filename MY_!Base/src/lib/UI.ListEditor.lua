--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ListEditor
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

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
