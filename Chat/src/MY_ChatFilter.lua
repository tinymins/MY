MY_ChatFilter = {}
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Chat/lang/")
local MY_ChatFilter = MY_ChatFilter
local MAX_CHAT_RECORD = 20
MY_ChatFilter.bFilterDuplicate           = true   -- �����ظ�����
MY_ChatFilter.bFilterDuplicateIgnoreID   = false  -- ��ͬ����ظ�����Ҳ����
MY_ChatFilter.bFilterDuplicateContinuous = true   -- �������������ظ�����
RegisterCustomData("MY_ChatFilter.bFilterDuplicate")
RegisterCustomData("MY_ChatFilter.bFilterDuplicateIgnoreID")
RegisterCustomData("MY_ChatFilter.bFilterDuplicateContinuous")

MY.HookChatPanel("MY_ChatFilter", function(h, szChannel, szMsg)
	-- �ظ�����ˢ�����Σ�ϵͳƵ�����⣩
	if MY_ChatFilter.bFilterDuplicate and szChannel ~= "MSG_SYS" then
		-- ������˼�¼
		local szText = GetPureText(szMsg)
		if MY_ChatFilter.bFilterDuplicateIgnoreID then
			local nCount = 1
			while nCount > 0 do
				szText, nCount = szText:gsub('^%[[^%[%]]+%]', '')
			end
		end
		-- �ж��Ƿ���Ҫ����
		if not h.MY_tDuplicateLog then
			h.MY_tDuplicateLog = {}
		elseif MY_ChatFilter.bFilterDuplicateContinuous then
			if h.MY_tDuplicateLog[1] == szText then
				return ''
			end
		else
			for i, szRecord in ipairs(h.MY_tDuplicateLog) do
				if szRecord == szText then
					Log('szRecord' .. szRecord)
					return ''
				end
			end
		end
		-- �����¼
		for i = #h.MY_tDuplicateLog, MAX_CHAT_RECORD - 2 do
			table.remove(h.MY_tDuplicateLog)
		end
		table.insert(h.MY_tDuplicateLog, 1, szText)
	end
end)

MY.RegisterPanel("MY_Duplicate_Chat_Filter", _L["duplicate chat filter"], _L['Chat'],
"UI/Image/Common/Money.UITex|243", {255,255,0,200}, {OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	ui:append("WndCheckBox", {
		text = _L['filter duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicate,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicate = bCheck
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		text = _L['filter duplicate chat ignore id'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateIgnoreID,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateIgnoreID = bCheck
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		text = _L['only filter continuous duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateContinuous,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateContinuous = bCheck
		end,
	})
	y = y + 30
end})
