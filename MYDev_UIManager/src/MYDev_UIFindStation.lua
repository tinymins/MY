--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI查看器
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-- 来源于海鳗
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
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
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
local PLUGIN_NAME = 'MYDev_UIManager'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UIFindStation'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local O = {
	bButton = false,
	szQuery = '',
	szResult = '',
	tLayer = { 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' },
}
local D = {}

do
local function fnApply(wnd)
	if wnd and wnd:IsVisible() then
		-- update mouse tips
		if wnd:GetType() == 'WndButton' or wnd:GetType() == 'WndCheckBox' then
			if O.bButton then
				wnd._OnMouseEnter = wnd.OnMouseEnter
				wnd.OnMouseEnter = function()
					local nX, nY = wnd:GetAbsPos()
					local nW, nH = wnd:GetSize()
					local szTip = GetFormatText(_L['<Component Path>'] .. '\n', 101)
					szTip = szTip .. GetFormatText(sub(wnd:GetTreePath(), 1, -2), 106)
					OutputTip(szTip, 400, { nX, nY, nW, nH })
				end
			else
				wnd.OnMouseEnter = wnd._OnMouseEnter
				wnd._OnMouseEnter = nil
			end
		end
		-- update childs
		local cld = wnd:GetFirstChild()
		while cld ~= nil do
			fnApply(cld)
			cld = cld:GetNext()
		end
	end
end
function D.UpdateButton()
	O.bButton = not O.bButton
	for _, v in ipairs(O.tLayer) do
		fnApply(Station.Lookup(v))
	end
end
end

do
local function fnApply(wnd)
	if wnd and wnd:IsVisible() then
		-- update mouse tips
		if wnd:GetType() == 'Box' then
			if O.bBox then
				wnd._OnItemMouseEnter = wnd.OnItemMouseEnter
				wnd.OnItemMouseEnter = function()
					local nX, nY = wnd:GetAbsPos()
					local nW, nH = wnd:GetSize()
					local szTip = GetFormatText(_L['<Component Path>'] .. '\n', 101)
					szTip = szTip .. GetFormatText(sub(wnd:GetTreePath(), 1, -2), 106)
					OutputTip(szTip, 400, { nX, nY, nW, nH })
				end
			else
				wnd.OnItemMouseEnter = wnd._OnItemMouseEnter
				wnd._OnItemMouseEnter = nil
			end
		elseif wnd:GetType() == 'Handle' then
			-- handle traverse
			for i = 0, wnd:GetItemCount() - 1, 1 do
				fnApply(wnd:Lookup(i))
			end
		elseif wnd:GetType() == 'WndFrame' or wnd:GetType() == 'WndWindow' then
			-- main handle
			fnApply(wnd:Lookup('', ''))
			-- update childs
			local cld = wnd:GetFirstChild()
			while cld ~= nil do
				fnApply(cld)
				cld = cld:GetNext()
			end
		end
	end
end
function D.UpdateBox()
	O.bBox = not O.bBox
	for _, v in ipairs(O.tLayer) do
		fnApply(Station.Lookup(v))
	end
end
end

do
local function fnSearch(wnd, szText, tResult)
	if not wnd or not wnd:IsVisible() then
		return
	end
	local hnd = wnd
	if wnd:GetType() ~= 'Handle' and wnd:GetType() ~= 'TreeLeaf' then
		hnd = wnd:Lookup('', '')
	end
	if hnd then
		for i = 0, hnd:GetItemCount() - 1, 1 do
			local hT = hnd:Lookup(i)
			if hT:GetType() == 'Handle' or hT:GetType() == 'TreeLeaf' then
				fnSearch(hT, szText, tResult)
			elseif hT:GetType() == 'Text' and hT:IsVisible() and find(hT:GetText(), szText) then
				local p1, p2 = hT:GetTreePath()
				insert(tResult, { p1 = sub(p1, 1, -2), p2 = p2, txt = hT:GetText() })
			end
		end
	end
	if hnd ~= wnd then
		local cld = wnd:GetFirstChild()
		while cld ~= nil do
			fnSearch(cld, szText, tResult)
			cld = cld:GetNext()
		end
	end
end
function D.SearchText(szText)
	local tResult = {}
	-- lookup
	if szText ~= '' then
		for _, v in ipairs(O.tLayer) do
			fnSearch(Station.Lookup(v), szText, tResult)
		end
	end
	-- concat result
	local szResult = ''
	for _, v in ipairs(tResult) do
		szResult = szResult .. v.p1 .. ', ' .. v.p2 .. ': ' .. v.txt .. '\n'
	end
	if szResult == '' then
		szResult = 'NO-RESULT'
	end
	return szResult
end
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
local PS = {}

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y
	local w, h = ui:Size()

	ui:Append('Text', { x = x, y = y, text = _L['Find component'], font = 27 })
	ui:Append('WndCheckBox', {
		x = x + 10, y = y + 28,
		text = _L['Enable button search, mouseover it will show its path'],
		checked = O.bButton, oncheck = D.UpdateButton,
	}):AutoWidth()
	ui:Append('WndCheckBox', {
		x = x + 10, y = y + 56,
		text = _L['Enable box search, mouseover it will show its path'],
		checked = O.bBox, oncheck = D.UpdateBox,
	}):AutoWidth()
	ui:Append('Text', { x = x + 0, y = y + 92, text = _L['Find by text'], font = 27 })

	local nX = X + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = y + 120,
		text = _L['Keyword: '],
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndEditBox', {
		name = 'Edit_Query',
		x = nX, y = y + 120, w = 200, h = 27,
		limit = 256,
		text = O.szQuery,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = y + 120,
		text = _L['Search'],
		onclick = function()
			ui:Children('#Edit_Result'):Text(_L['Searching, please wait...'])
			O.szQuery = ui:Children('#Edit_Query'):Text()
			O.szResult = D.SearchText(O.szQuery)
			ui:Children('#Edit_Result'):Text(O.szResult)
		end,
	}):Width() + 5
	ui:Append('Text', { x = nX, y = y + 120, text = _L['(Supports Lua regex)'] })
	ui:Append('WndEditBox', { name = 'Edit_Result', x = x + 10, y = y + 150, limit = 9999, w = 480, h = 200, multiline = true, text = O.szResult })
end

LIB.RegisterPanel('MYDev_UIFindStation', _L['MYDev_UIFindStation'], _L['Development'], 2791, PS)
