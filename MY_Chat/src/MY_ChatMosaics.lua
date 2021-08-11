--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天栏姓名一键打码
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatMosaics'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule(MODULE_NAME, _L['Chat'], {
	tIgnoreNames = { -- 忽略名单
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMosaics'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
	nMosaicsMode = { -- 局部打码模式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMosaics'],
		xSchema = X.Schema.Number,
		xDefaultValue = 4,
	},
	bIgnoreOwnName = { -- 不打码自己的名字
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMosaics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	bEnabled = false,            -- 启用状态
	szMosaics = _L.MOSAICS_CHAR, -- 马赛克字符
}

function D.ResetMosaics()
	-- re mosaics
	D.bForceUpdate = true
	for i = 1, 10 do
		D.Mosaics(Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message'))
	end
	D.bForceUpdate = nil
	-- hook chat panel
	if D.bEnabled then
		X.HookChatPanel('AFTER', 'MY_ChatMosaics', function(h, nIndex)
			D.Mosaics(h, nIndex)
		end)
	else
		X.HookChatPanel('AFTER', 'MY_ChatMosaics', false)
	end
	FireUIEvent('ON_MY_MOSAICS_RESET')
end

function D.NameLink_GetText(h, ...)
	return h.__MY_ChatMosaics_szText or h.__MY_ChatMosaics_GetText(h, ...)
end

function D.MosaicsString(szText)
	if not D.bEnabled then
		return szText
	end
	local bQuote = szText:sub(1, 1) == '[' and szText:sub(-1, -1) == ']'
	if bQuote then
		szText = szText:sub(2, -2) -- 去掉[]括号
	end
	if (not O.bIgnoreOwnName or szText ~= GetClientPlayer().szName) and not O.tIgnoreNames[szText] then
		local nLen = wstring.len(szText)
		if O.nMosaicsMode == 3 and nLen > 2 then
			szText = wstring.sub(szText, 1, 1) .. string.rep(D.szMosaics, nLen - 2) .. wstring.sub(szText, nLen, nLen)
		elseif O.nMosaicsMode == 1 and nLen > 1 then
			szText = wstring.sub(szText, 1, 1) .. string.rep(D.szMosaics, nLen - 1)
		elseif O.nMosaicsMode == 2 and nLen > 1 then
			szText = string.rep(D.szMosaics, nLen - 1) .. wstring.sub(szText, nLen, nLen)
		elseif O.nMosaicsMode == 4 or nLen <= 1 then
			szText = string.rep(D.szMosaics, nLen)
		else
			szText = wstring.sub(szText, 1, 1) .. string.rep(D.szMosaics, nLen - 1)
		end
	end
	if bQuote then
		szText = '[' .. szText .. ']' -- 加回[]括号
	end
	return szText
end

function D.Mosaics(h, nPos, nLen)
	if not h then
		return
	end
	if h:GetType() == 'Text' then
		if D.bEnabled then
			if not h.__MY_ChatMosaics_szText or D.bForceUpdate then
				h.__MY_ChatMosaics_szText = h.__MY_ChatMosaics_szText or h:GetText()
				if not h.__MY_ChatMosaics_GetText then
					h.__MY_ChatMosaics_GetText = h.GetText
					h.GetText = D.NameLink_GetText
				end
				h:SetText(D.MosaicsString(h.__MY_ChatMosaics_szText))
				h:AutoSize()
			end
		else
			if h.__MY_ChatMosaics_GetText then
				h.GetText = h.__MY_ChatMosaics_GetText
				h.__MY_ChatMosaics_GetText = nil
			end
			if h.__MY_ChatMosaics_szText then
				h:SetText(h.__MY_ChatMosaics_szText)
				h.__MY_ChatMosaics_szText = nil
				h:AutoSize()
			end
		end
	elseif h:GetType() == 'Handle' then
		local nEndPos = (nLen and (nPos + nLen)) or (h:GetItemCount() - 1)
		for i = nPos or 0, nEndPos do
			local hItem = h:Lookup(i)
			if hItem and (hItem:GetName():sub(0, 9)) == 'namelink_' then
				D.Mosaics(hItem)
			end
		end
		h:FormatAllItemPos()
	end
end

-- Global exports
do
local settings = {
	name = 'MY_ChatMosaics',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Mosaics',
				'MosaicsString',
				'bEnabled',
			},
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'bEnabled',
			},
			triggers = {
				bEnabled = function ()
					D.ResetMosaics()
				end,
			},
			root = D,
		},
	},
}
MY_ChatMosaics = X.CreateModule(settings)
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 20, 30

	ui:Append('WndCheckBox', {
		text = _L['chat mosaics (mosaics names in chat panel)'],
		x = x, y = y, w = 400,
		checked = MY_ChatMosaics.bEnabled,
		oncheck = function(bCheck)
			MY_ChatMosaics.bEnabled = bCheck
			D.ResetMosaics()
		end,
	})
	y = y + 30

	ui:Append('WndCheckBox', {
		text = _L['no mosaics on my own name'],
		x = x, y = y, w = 400,
		checked = O.bIgnoreOwnName,
		oncheck = function(bCheck)
			O.bIgnoreOwnName = bCheck
			D.ResetMosaics()
		end,
	})
	y = y + 30

	ui:Append('WndRadioBox', {
		text = _L['part mosaics A (mosaics except 1st and last character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = O.nMosaicsMode == 1,
		oncheck = function(bCheck)
			if bCheck then
				O.nMosaicsMode = 1
				D.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:Append('WndRadioBox', {
		text = _L['part mosaics B (mosaics except 1st character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = O.nMosaicsMode == 2,
		oncheck = function(bCheck)
			if bCheck then
				O.nMosaicsMode = 2
				D.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:Append('WndRadioBox', {
		text = _L['part mosaics C (mosaics except last character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = O.nMosaicsMode == 3,
		oncheck = function(bCheck)
			if bCheck then
				O.nMosaicsMode = 3
				D.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:Append('WndRadioBox', {
		text = _L['part mosaics D (mosaics all character)'],
		x = x, y = y, w = 400,
		group = 'PART_MOSAICS',
		checked = O.nMosaicsMode == 4,
		oncheck = function(bCheck)
			if bCheck then
				O.nMosaicsMode = 4
				D.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:Append('WndEditBox', {
		placeholder = _L['mosaics character'],
		x = x, y = y, w = w - 2 * x, h = 25,
		text = D.szMosaics,
		onchange = function(szText)
			if szText == '' then
				D.szMosaics = _L.MOSAICS_CHAR
			else
				D.szMosaics = szText
			end
			D.ResetMosaics()
		end,
	})
	y = y + 30

	ui:Append('WndEditBox', {
		placeholder = _L['unmosaics names (split by comma)'],
		x = x, y = y, w = w - 2 * x, h = h - y - 50,
		text = (function()
			local t = {}
			for szName, _ in pairs(O.tIgnoreNames) do
				table.insert(t, szName)
			end
			table.concat(t, ',')
		end)(),
		onchange = function(szText)
			local tIgnoreNames = {}
			for _, szName in ipairs(X.SplitString(szText, ',')) do
				tIgnoreNames[szName] = true
			end
			O.tIgnoreNames = tIgnoreNames
			D.ResetMosaics()
		end,
	})
	y = y + 30
end

X.RegisterPanel(_L['Chat'], 'MY_Chat_ChatMosaics', _L['chat mosaics'], 'ui/Image/UICommon/yirong3.UITex|50', PS)
