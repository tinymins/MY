--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天栏姓名一键打码
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_Chat/lang/')
if not LIB.AssertVersion('MY_ChatMosaics', _L['MY_ChatMosaics'], 0x2011800) then
	return
end
MY_ChatMosaics = {}
local _C = {}
local MY_ChatMosaics = MY_ChatMosaics
MY_ChatMosaics.bEnabled = false            -- 启用状态
MY_ChatMosaics.szMosaics = _L.MOSAICS_CHAR -- 马赛克字符
MY_ChatMosaics.tIgnoreNames = {}           -- 忽略名单
MY_ChatMosaics.nMosaicsMode = 1            -- 局部打码模式
MY_ChatMosaics.bIgnoreOwnName = false      -- 不打码自己的名字
RegisterCustomData('MY_ChatMosaics.tIgnoreNames')
RegisterCustomData('MY_ChatMosaics.nMosaicsMode')
RegisterCustomData('MY_ChatMosaics.bIgnoreOwnName')

MY_ChatMosaics.ResetMosaics = function()
	-- re mosaics
	_C.bForceUpdate = true
	for i = 1, 10 do
		_C.Mosaics(Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message'))
	end
	_C.bForceUpdate = nil
	-- hook chat panel
	if MY_ChatMosaics.bEnabled then
		LIB.HookChatPanel('AFTER.MY_ChatMosaics', function(h, nIndex)
			_C.Mosaics(h, nIndex)
		end)
	else
		LIB.HookChatPanel('AFTER.MY_ChatMosaics', false)
	end
	FireUIEvent('ON_MY_MOSAICS_RESET')
end

_C.NameLink_GetText = function(h, ...)
	return h.__MY_szText or h.__MY_GetText(h, ...)
end

_C.Mosaics = function(h, nPos, nLen)
	if h then
		local nEndPos = (nLen and (nPos + nLen)) or (h:GetItemCount() - 1)
		for i = nPos or 0, nEndPos do
			local hItem = h:Lookup(i)
			if hItem and (hItem:GetName():sub(0, 9)) == 'namelink_' then
				if MY_ChatMosaics.bEnabled then
					-- re mosaics
					if _C.bForceUpdate and hItem.__MY_szText then
						hItem:SetText(hItem.__MY_szText)
						hItem.__MY_szText = nil
					end
					-- mosaics
					if not hItem.__MY_szText and (
						not MY_ChatMosaics.bIgnoreOwnName
						or hItem:GetText() ~= '[' .. GetClientPlayer().szName .. ']'
					) and not MY_ChatMosaics.tIgnoreNames[hItem:GetText():sub(2, -2)] then
						local szText = hItem.__MY_szText or hItem:GetText()
						hItem.__MY_szText = szText
						if not hItem.__MY_GetText then
							hItem.__MY_GetText = hItem.GetText
							hItem.GetText = _C.NameLink_GetText
						end
						szText = szText:sub(2, -2) -- 去掉[]括号
						local nLen = wstring.len(szText)
						if MY_ChatMosaics.nMosaicsMode == 1 and nLen > 2 then
							szText = wstring.sub(szText, 1, 1) .. string.rep(MY_ChatMosaics.szMosaics, nLen - 2) .. wstring.sub(szText, nLen, nLen)
						elseif MY_ChatMosaics.nMosaicsMode == 2 and nLen > 1 then
							szText = wstring.sub(szText, 1, 1) .. string.rep(MY_ChatMosaics.szMosaics, nLen - 1)
						elseif MY_ChatMosaics.nMosaicsMode == 3 and nLen > 1 then
							szText = string.rep(MY_ChatMosaics.szMosaics, nLen - 1) .. wstring.sub(szText, nLen, nLen)
						elseif MY_ChatMosaics.nMosaicsMode == 4 or nLen <= 1 then
							szText = string.rep(MY_ChatMosaics.szMosaics, nLen)
						else
							szText = wstring.sub(szText, 1, 1) .. string.rep(MY_ChatMosaics.szMosaics, nLen - 1)
						end
						hItem:SetText('[' .. szText .. ']')
						hItem:AutoSize()
					end
				elseif hItem.__MY_szText then
					hItem:SetText(hItem.__MY_szText)
					hItem.__MY_szText = nil
					hItem:AutoSize()
				end
			end
		end
		h:FormatAllItemPos()
	end
end
MY_ChatMosaics.Mosaics = _C.Mosaics

LIB.RegisterPanel('MY_Chat_ChatMosaics', _L['chat mosaics'], _L['Chat'],
'ui/Image/UICommon/yirong3.UITex|50', {
OnPanelActive = function(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	ui:append('WndCheckBox', {
		text = _L['chat mosaics (mosaics names in chat panel)'],
		x = x, y = y, w = 400,
		checked = MY_ChatMosaics.bEnabled,
		oncheck = function(bCheck)
			MY_ChatMosaics.bEnabled = bCheck
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		text = _L['no mosaics on my own name'],
		x = x, y = y, w = 400,
		checked = MY_ChatMosaics.bIgnoreOwnName,
		oncheck = function(bCheck)
			MY_ChatMosaics.bIgnoreOwnName = bCheck
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30

	ui:append('WndRadioBox', {
		text = _L['part mosaics A (mosaics except 1st and last character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = MY_ChatMosaics.nMosaicsMode == 1,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 1
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append('WndRadioBox', {
		text = _L['part mosaics B (mosaics except 1st character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = MY_ChatMosaics.nMosaicsMode == 2,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 2
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append('WndRadioBox', {
		text = _L['part mosaics C (mosaics except last character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = MY_ChatMosaics.nMosaicsMode == 3,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 3
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append('WndRadioBox', {
		text = _L['part mosaics D (mosaics all character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = MY_ChatMosaics.nMosaicsMode == 4,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 4
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append('WndEditBox', {
		placeholder = _L['mosaics character'],
		x = x, y = y, w = w - 2 * x, h = 25,
		text = MY_ChatMosaics.szMosaics,
		onchange = function(szText)
			if szText == '' then
				MY_ChatMosaics.szMosaics = _L.MOSAICS_CHAR
			else
				MY_ChatMosaics.szMosaics = szText
			end
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30

	ui:append('WndEditBox', {
		placeholder = _L['unmosaics names (split by comma)'],
		x = x, y = y, w = w - 2 * x, h = h - y - 50,
		text = (function()
			local t = {}
			for szName, _ in pairs(MY_ChatMosaics.tIgnoreNames) do
				table.insert(t, szName)
			end
			table.concat(t, ',')
		end)(),
		onchange = function(szText)
			MY_ChatMosaics.tIgnoreNames = {}
			for _, szName in ipairs(LIB.SplitString(szText, ',')) do
				MY_ChatMosaics.tIgnoreNames[szName] = true
			end
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30
end})
