--------------------------------------------
-- @File  : MY_ChatMosaics.lua
-- @Desc  : ����������һ������
-- @Author: ��һ�� (tinymins) @ derzh.com
-- @Date  : 2015-05-21 10:34:08
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-05-21 14:48:59
-- @Version: 1.0
-- @ChangeLog:
--  + v1.0 File founded. -- via��һ��
--------------------------------------------
MY_ChatMosaics = {}
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Chat/lang/")
local MY_ChatMosaics = MY_ChatMosaics
MY_ChatMosaics.bEnabled = false       -- ����״̬
MY_ChatMosaics.szMosaics = "*"        -- �������ַ�
MY_ChatMosaics.tIgnoreNames = {}      -- ��������
MY_ChatMosaics.nMosaicsMode = 1       -- �ֲ�����ģʽ
MY_ChatMosaics.bIgnoreOwnName = false -- �������Լ�������
RegisterCustomData("MY_ChatMosaics.tIgnoreNames")
RegisterCustomData("MY_ChatMosaics.nMosaicsMode")
RegisterCustomData("MY_ChatMosaics.bIgnoreOwnName")

MY_ChatMosaics.ResetMosaics = function()
	-- re mosaics
	_C.bForceUpdate = true
	for i = 1, 10 do
		_C.Mosaics(Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message"))
	end
	_C.bForceUpdate = nil
	-- hook chat panel
	if MY_ChatMosaics.bEnabled then
		MY.HookChatPanel("MY_ChatMosaics", function(h, szChannel, szMsg)
			return szMsg, h:GetItemCount()
		end, function(h, szChannel, szMsg, i)
			_C.Mosaics(h, i)
		end)
	else
		MY.HookChatPanel("MY_ChatMosaics")
	end
end

_C.NameLink_GetText = function(h)
	return h.__MY_szText or h.__MY_GetText()
end

_C.Mosaics = function(h, nPos)
	if h then
		for i = h:GetItemCount() - 1, nPos or 0, -1 do
			local hItem = h:Lookup(i)
			if hItem and (hItem:GetName():sub(0, 9)) == "namelink_" then
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
					) then
						local szText = hItem.__MY_szText or hItem:GetText()
						hItem.__MY_szText = szText
						if not hItem.__MY_GetText then
							hItem.__MY_GetText = hItem.GetText
							hItem.GetText = _C.NameLink_GetText
						end
						szText = szText:sub(2, -2) -- ȥ��[]����
						local nLen = wstring.len(szText)
						if MY_ChatMosaics.nMosaicsMode == 1 and nLen > 2 then
							szText = wstring.sub(szText, 1, 1) .. string.rep(MY_ChatMosaics.szMosaics, nLen - 2) .. wstring.sub(szText, nLen, nLen)
						elseif MY_ChatMosaics.nMosaicsMode == 2 and nLen > 1 then
							szText = wstring.sub(szText, 1, 1) .. string.rep(MY_ChatMosaics.szMosaics, nLen - 1)
						elseif MY_ChatMosaics.nMosaicsMode == 3 and nLen > 1 then
							szText = string.rep(MY_ChatMosaics.szMosaics, nLen - 1) .. wstring.sub(szText, nLen, nLen)
						else -- if MY_ChatMosaics.nMosaicsMode == 4 then
							szText = string.rep(MY_ChatMosaics.szMosaics, nLen)
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

MY.RegisterPanel("MY_Chat_ChatMosaics", _L["chat mosaics"], _L['Chat'],
"ui/Image/UICommon/yirong3.UITex|63", {255,255,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	ui:append("WndCheckBox", {
		text = _L['chat mosaics (mosaics names in chat panel)'],
		x = x, y = y, w = 400,
		checked = MY_ChatMosaics.bEnabled,
		oncheck = function(bCheck)
			MY_ChatMosaics.bEnabled = bCheck
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		text = _L['no mosaics on my own name'],
		x = x, y = y, w = 400,
		checked = MY_ChatMosaics.bIgnoreOwnName,
		oncheck = function(bCheck)
			MY_ChatMosaics.bIgnoreOwnName = bCheck
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30

	ui:append("WndRadioBox", {
		text = _L['part mosaics A (mosaics except 1st and last character)'],
		x = x, y = y, w = 400,
		group = "PART_MOSAICS",
		checked = MY_ChatMosaics.nMosaicsMode == 1,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 1
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append("WndRadioBox", {
		text = _L['part mosaics B (mosaics except 1st character)'],
		x = x, y = y, w = 400,
		group = "PART_MOSAICS",
		checked = MY_ChatMosaics.nMosaicsMode == 2,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 2
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append("WndRadioBox", {
		text = _L['part mosaics C (mosaics except last character)'],
		x = x, y = y, w = 400,
		group = "PART_MOSAICS",
		checked = MY_ChatMosaics.nMosaicsMode == 3,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 3
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append("WndRadioBox", {
		text = _L['part mosaics D (mosaics all character)'],
		x = x, y = y, w = 400,
		group = "PART_MOSAICS",
		checked = MY_ChatMosaics.nMosaicsMode == 4,
		oncheck = function(bCheck)
			if bCheck then
				MY_ChatMosaics.nMosaicsMode = 4
				MY_ChatMosaics.ResetMosaics()
			end
		end,
	})
	y = y + 30

	ui:append("WndEditBox", {
		placeholder = _L['mosaics character'],
		x = x, y = y, w = w - 2 * x, h = 25,
		onchange = function(szText)
			if szText == "" then
				MY_ChatMosaics.szMosaics = "*"
			else
				MY_ChatMosaics.szMosaics = szText
			end
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30
	
	ui:append("WndEditBox", {
		placeholder = _L['unmosaics names (split by comma)'],
		x = x, y = y, w = w - 2 * x, h = h - y - 50,
		onchange = function(szText)
			MY_ChatMosaics.tIgnoreNames = MY.String.Split(szText, ",")
			MY_ChatMosaics.ResetMosaics()
		end,
	})
	y = y + 30
end})
