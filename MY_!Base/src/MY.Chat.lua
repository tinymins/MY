-----------------------------------------------
-- @Desc  : �������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2017-05-22 17:14:37
-- @Ref: �����������Դ�� @haimanchajian.com
-----------------------------------------------
----------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack
local sub, len, char, rep = string.sub, string.len, string.char, string.rep
local byte, format, gsub = string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
----------------------------------------------------------------------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = MY or {}
MY.Chat = MY.Chat or {}
local _C, _L = {tPeekPlayer = {}}, MY.LoadLangPack()
local EMPTY_TABLE = SetmetaReadonly({})

-- ��������ٳ�����
-- ���츴�Ʋ�����
function MY.Chat.RepeatChatLine(hTime)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	MY.Chat.CopyChatLine(hTime)
	local tMsg = edit:GetTextStruct()
	if #tMsg == 0 then
		return
	end
	local nChannel, szName = EditBox_GetChannel()
	if MY.CanTalk(nChannel) then
		GetClientPlayer().Talk(nChannel, szName or "", tMsg)
		edit:ClearText()
	end
end
MY.RepeatChatLine = MY.Chat.RepeatChatLine

-- ����ɾ����
function MY.Chat.RemoveChatLine(hTime)
	local nIndex   = hTime:GetIndex()
	local hHandle  = hTime:GetParent()
	local nCount   = hHandle:GetItemCount()
	local bCurrent = true
	for i = nIndex, nCount - 1 do
		local hItem = hHandle:Lookup(nIndex)
		if hItem:GetType() == "Text" and
		(hItem:GetName() == 'timelink' or
		 hItem:GetName() == 'copylink' or
		 hItem:GetName() == 'copy') then
		-- timestrap found
			if not bCurrent then
			-- is not current timestrap
				break
			end
		else -- current timestrap ended
			bCurrent = false
		end -- remove until next timestrap
		hHandle:RemoveItem(hItem)
	end
	hHandle:FormatAllItemPos()
end
MY.RemoveChatLine = MY.Chat.RemoveChatLine

-- ��������ʼ��
_C.nMaxEmotionLen = 0
function _C.InitEmotion()
	if not _C.tEmotion then
		local t = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			local t1 = {
				nFrame = tLine.nFrame,
				dwID   = tLine.dwID or (10000 + i),
				szCmd  = tLine.szCommand,
				szType = tLine.szType,
				szImageFile = tLine.szImageFile or 'ui/Image/UICommon/Talk_face.UITex'
			}
			t[t1.dwID] = t1
			t[t1.szCmd] = t1
			t[t1.szImageFile..','..t1.nFrame..','..t1.szType] = t1
			_C.nMaxEmotionLen = math.max(_C.nMaxEmotionLen, wstring.len(t1.szCmd))
		end
		_C.tEmotion = t
	end
end

-- ��ȡ��������б�
-- typedef emo table
-- (emo[]) MY.Chat.GetEmotion()                             -- �������б����б�
-- (emo)   MY.Chat.GetEmotion(szCommand)                    -- ����ָ��Cmd�ı���
-- (emo)   MY.Chat.GetEmotion(szImageFile, nFrame, szType)  -- ����ָ��ͼ��ı���
function MY.Chat.GetEmotion(arg0, arg1, arg2)
	_C.InitEmotion()
	local t
	if not arg0 then
		t = _C.tEmotion
	elseif not arg1 then
		t = _C.tEmotion[arg0]
	elseif arg2 then
		arg0 = string.gsub(arg0, '\\\\', '\\')
		t = _C.tEmotion[arg0..','..arg1..','..arg2]
	end
	return clone(t)
end
MY.GetEmotion = MY.Chat.GetEmotion

-- ��ȡ����������Text
function MY.Chat.GetCopyLinkText(szText, rgbf)
	szText = szText or _L[' * ']
	rgbf   = rgbf   or { f = 10 }

	return GetFormatText(szText, rgbf.f, rgbf.r, rgbf.g, rgbf.b, 82691,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnCopyLClick\nthis.OnItemMButtonDown=MY.ChatLinkEventHandlers.OnCopyMClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnCopyRClick\nthis.OnItemMouseEnter=MY.ChatLinkEventHandlers.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.ChatLinkEventHandlers.OnCopyMouseLeave",
		"copylink")
end
MY.GetCopyLinkText = MY.Chat.GetCopyLinkText

-- ��ȡ����������Text
function MY.Chat.GetTimeLinkText(rgbfs, dwTime)
	if not dwTime then
		dwTime = GetCurrentTime()
	end
	rgbfs = rgbfs or { f = 10 }
	return GetFormatText(
		MY.FormatTime(rgbfs.s or '[hh:mm.ss]', dwTime),
		rgbfs.f, rgbfs.r, rgbfs.g, rgbfs.b, 82691,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnCopyLClick\nthis.OnItemMButtonDown=MY.ChatLinkEventHandlers.OnCopyMClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnCopyRClick\nthis.OnItemMouseEnter=MY.ChatLinkEventHandlers.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.ChatLinkEventHandlers.OnCopyMouseLeave",
		"timelink"
	)
end
MY.GetTimeLinkText = MY.Chat.GetTimeLinkText

-- ����������
function MY.Chat.CopyChatLine(hTime, bTextEditor)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if bTextEditor then
		edit = MY.UI.OpenTextEditor():find(".WndEdit")[1]
	end
	if not edit then
		return
	end
	Station.Lookup("Lowest2/EditBox"):Show()
	edit:ClearText()
	local h, i, bBegin, bContent = hTime:GetParent(), hTime:GetIndex(), nil, false
	-- loop
	for i = i + 1, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == "Text" then
			local szName = p:GetName()
			if szName ~= "timelink" and szName ~= "copylink" and szName ~= "msglink" and szName ~= "time" then
				local szText, bEnd = p:GetText(), false
				if not bTextEditor and StringFindW(szText, "\n") then
					szText = StringReplaceW(szText, "\n", "")
					bEnd = true
				end
				bContent = true
				if szName == "itemlink" then
					edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
				elseif szName == "iteminfolink" then
					edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
				elseif string.sub(szName, 1, 8) == "namelink" then
					if bBegin == nil then
						bBegin = false
					end
					edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
				elseif szName == "questlink" then
					edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
				elseif szName == "recipelink" then
					edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == "enchantlink" then
					edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == "skilllink" then
					local o = clone(p.skillKey)
					o.type, o.text = "skill", szText
					edit:InsertObj(szText, o)
				elseif szName =="skillrecipelink" then
					edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
				elseif szName =="booklink" then
					edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
				elseif szName =="achievementlink" then
					edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
				elseif szName =="designationlink" then
					edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
				elseif szName =="eventlink" then
					if szText and #szText > 0 then -- ���˲����Ϣ
						edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
					end
				else
					if bBegin == false then
						for _, v in ipairs({g_tStrings.STR_TALK_HEAD_WHISPER, g_tStrings.STR_TALK_HEAD_SAY, g_tStrings.STR_TALK_HEAD_SAY1, g_tStrings.STR_TALK_HEAD_SAY2 }) do
							local nB, nE = StringFindW(szText, v)
							if nB then
								szText, bBegin = string.sub(szText, nB + nE), true
								edit:ClearText()
							end
						end
					end
					if szText ~= "" and (table.getn(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
						edit:InsertText(szText)
					end
				end
				if bEnd then
					break
				end
			elseif bTextEditor and bContent and (szName == "timelink" or szName == "copylink" or szName == "msglink" or szName == "time") then
				break
			end
		elseif p:GetType() == "Image" or p:GetType() == "Animate" then
			local dwID = tonumber((p:GetName():gsub("^emotion_", "")))
			if dwID then
				local emo = MY.Chat.GetEmotion(dwID)
				if emo then
					edit:InsertObj(emo.szCmd, { type = "emotion", text = emo.szCmd, id = emo.dwID })
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end
MY.CopyChatLine = MY.Chat.CopyChatLine

do local ChatLinkEvents = {}
MY.RegisterEvent("PEEK_OTHER_PLAYER", function()
	if not _C.tPeekPlayer[arg1] then
		return
	end
	if arg0 == PEEK_OTHER_PLAYER_RESPOND.INVALID then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Invalid player ID!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.FAILED then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Peek other player failed!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.CAN_NOT_FIND_PLAYER then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Can not find player to peek!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.TOO_FAR then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Player is too far to peek!'])
	end
	_C.tPeekPlayer[arg1] = nil
end)
function ChatLinkEvents.OnNameLClick(element, link)
	if not link then
		link = element
	end
	if IsCtrlKeyDown() and IsAltKeyDown() then
		local menu = {}
		InsertInviteTeamMenu(menu, (MY.UI(link):text():gsub("[%[%]]", "")))
		menu[1].fnAction()
	elseif IsCtrlKeyDown() then
		MY.Chat.CopyChatItem(link)
	elseif IsShiftKeyDown() then
		MY.SetTarget(TARGET.PLAYER, MY.UI(link):text())
	elseif IsAltKeyDown() then
		if MY_Farbnamen and MY_Farbnamen.Get then
			local info = MY_Farbnamen.Get((MY.UI(link):text():gsub("[%[%]]", "")))
			if info then
				_C.tPeekPlayer[info.dwID] = true
				ViewInviteToPlayer(info.dwID)
			end
		end
	else
		MY.SwitchChat(MY.UI(link):text())
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		if edit then
			Station.SetFocusWindow(edit)
		end
	end
end
function ChatLinkEvents.OnNameRClick(element, link)
	if not link then
		link = element
	end
	PopupMenu(MY.Game.GetTargetContextMenu(TARGET.PLAYER, (MY.UI(link):text():gsub('[%[%]]', ''))))
end
function ChatLinkEvents.OnCopyLClick(element, link)
	if not link then
		link = element
	end
	MY.Chat.CopyChatLine(link, IsCtrlKeyDown())
end
function ChatLinkEvents.OnCopyMClick(element, link)
	if not link then
		link = element
	end
	MY.Chat.RemoveChatLine(link)
end
function ChatLinkEvents.OnCopyRClick(element, link)
	if not link then
		link = element
	end
	MY.Chat.RepeatChatLine(link)
end
function ChatLinkEvents.OnCopyMouseEnter(element, link)
	if not link then
		link = element
	end
	local x, y = element:GetAbsPos()
	local w, h = element:GetSize()
	local szText = GetFormatText(_L['LClick to copy to editbox.\nMClick to remove this line.\nRClick to repeat this line.'], 136)
	OutputTip(szText, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
end
function ChatLinkEvents.OnCopyMouseLeave(element, link)
	if not link then
		link = element
	end
	HideTip()
end
function ChatLinkEvents.OnItemLClick(element, link)
	if not link then
		link = element
	end
	OnItemLinkDown(link)
end
function ChatLinkEvents.OnItemRClick(element, link)
	if not link then
		link = element
	end
	if IsCtrlKeyDown() then
		MY.Chat.CopyChatItem(link)
	end
end
MY.ChatLinkEvents = ChatLinkEvents

local ChatLinkEventHandlers = {}
function ChatLinkEventHandlers.OnNameLClick() ChatLinkEvents.OnNameLClick(this) end
function ChatLinkEventHandlers.OnNameRClick() ChatLinkEvents.OnNameRClick(this) end
function ChatLinkEventHandlers.OnCopyLClick() ChatLinkEvents.OnCopyLClick(this) end
function ChatLinkEventHandlers.OnCopyMClick() ChatLinkEvents.OnCopyMClick(this) end
function ChatLinkEventHandlers.OnCopyRClick() ChatLinkEvents.OnCopyRClick(this) end
function ChatLinkEventHandlers.OnCopyMouseEnter() ChatLinkEvents.OnCopyMouseEnter(this) end
function ChatLinkEventHandlers.OnCopyMouseLeave() ChatLinkEvents.OnCopyMouseLeave(this) end
function ChatLinkEventHandlers.OnItemLClick() ChatLinkEvents.OnItemLClick(this) end
function ChatLinkEventHandlers.OnItemRClick() ChatLinkEvents.OnItemRClick(this) end
MY.ChatLinkEventHandlers = ChatLinkEventHandlers

-- ��link�¼���Ӧ
-- (userdata) MY.Chat.RenderLink(userdata link)                   ����link�ĸ����¼��� namelink��һ��������TextԪ��
-- (userdata) MY.Chat.RenderLink(userdata element, userdata link) ����element�ĸ����¼��� ����Դ��link
-- (string) MY.Chat.RenderLink(string szMsg)                      ��ʽ��szMsg ��������ĳ����� ����ʱ����Ӧ
-- link   : һ��������TextԪ��
-- element: һ�����Թ������Ϣ��Ӧ��UIԪ��
-- szMsg  : ��ʽ����UIXML��Ϣ
function MY.Chat.RenderLink(arg1, arg2)
	if type(arg1) == 'string' then -- szMsg
		local szMsg = arg1
		local xmls = MY.Xml.Decode(szMsg)
		if xmls then
			for i, xml in ipairs(xmls) do
				if xml and xml['.'] == "text" and xml[''] and xml[''].name then
					local name, script = xml[''].name, xml[''].script
					if script then
						script = script .. '\n'
					else
						script = ''
					end

					if name:sub(1, 8) == 'namelink' then
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnNameLClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnNameRClick'
					elseif name == 'copy' or name == 'copylink' or name == 'timelink' then
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnCopyLClick\nthis.OnItemMButtonDown=MY.ChatLinkEventHandlers.OnCopyMClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnCopyRClick\nthis.OnItemMouseEnter=MY.ChatLinkEventHandlers.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.ChatLinkEventHandlers.OnCopyMouseLeave'
					else
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnItemLClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnItemRClick'
					end

					if #script > 0 then
						xml[''].eventid = 82803
						xml[''].script = script
					end
				end
			end
			szMsg = MY.Xml.Encode(xmls)
		end
		return szMsg
	elseif type(arg1) == 'table' and type(arg1.GetName) == 'function' then
		local element = arg1
		local link = arg2 or arg1
		if element.bMyChatRendered then
			return
		end
		local ui = XGUI(element)
		local name = ui:name()
		if name:sub(1, 8) == 'namelink' then
			ui:lclick(function() ChatLinkEvents.OnNameLClick(element, link) end)
			ui:rclick(function() ChatLinkEvents.OnNameRClick(element, link) end)
		elseif name == 'copy' or name == 'copylink' then
			ui:lclick(function() ChatLinkEvents.OnCopyLClick(element, link) end)
			ui:rclick(function() ChatLinkEvents.OnCopyRClick(element, link) end)
			ui:mclick(function() ChatLinkEvents.OnCopyMClick(element, link) end)
		else
			ui:lclick(function() ChatLinkEvents.OnItemLClick(element, link) end)
			ui:rclick(function() ChatLinkEvents.OnItemRClick(element, link) end)
		end
		element.bMyChatRendered = true
		return element
	end
end
MY.RenderChatLink = MY.Chat.RenderLink
end

-- ����Item�������
function MY.Chat.CopyChatItem(p)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	if p:GetType() == "Text" then
		local szText, szName = p:GetText(), p:GetName()
		if szName == "itemlink" then
			edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
		elseif szName == "iteminfolink" then
			edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
		elseif string.sub(szName, 1, 8) == "namelink" then
			edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
		elseif szName == "questlink" then
			edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
		elseif szName == "recipelink" then
			edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == "enchantlink" then
			edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == "skilllink" then
			local o = clone(p.skillKey)
			o.type, o.text = "skill", szText
			edit:InsertObj(szText, o)
		elseif szName =="skillrecipelink" then
			edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
		elseif szName =="booklink" then
			edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
		elseif szName =="achievementlink" then
			edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
		elseif szName =="designationlink" then
			edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
		elseif szName =="eventlink" then
			edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
		end
		Station.SetFocusWindow(edit)
	end
end
MY.CopyChatItem = MY.Chat.CopyChatItem

--������Ϣ
function MY.Chat.FormatContent(szMsg)
	local t = MY.Xml.Decode(szMsg)
	-- Output(t)
	local t2 = {}
	for _, node in ipairs(t) do
		local ntype = MY.Xml.GetNodeType(node)
		local ndata = MY.Xml.GetNodeData(node)
		-- ��̬����
		if ntype == "image" then
			local emo = MY.Chat.GetEmotion(ndata.path, ndata.frame, 'image')
			if emo then
				table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
			end
		-- ��̬����
		elseif ntype == "animate" then
			local emo = MY.Chat.GetEmotion(ndata.path, ndata.group, 'animate')
			if emo then
				table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
			end
		-- ��������
		elseif ntype == "text" then
			local is_normaltext = false
			-- ��ͨ����
			if not ndata.name then
				is_normaltext = true
			-- ��Ʒ����
			elseif ndata.name == "itemlink" then
				table.insert(t2, {type = "item", text = ndata.text, innerText = ndata.text:sub(2, -2), item = ndata.userdata})
			-- ��Ʒ��Ϣ
			elseif ndata.name == "iteminfolink" then
				local version, tab, index = string.match(ndata.script, "this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)")
				table.insert(t2, {type = "iteminfo", text = ndata.text, innerText = ndata.text:sub(2, -2), version = version, tabtype = tab, index = index})
			-- ����
			elseif ndata.name:sub(1, 9) == "namelink_" then
				table.insert(t2, {type = "name", text = ndata.text, innerText = ndata.text, name = ndata.text:sub(2, -2)})
			-- ����
			elseif ndata.name == "questlink" then
				table.insert(t2, {type = "quest", text = ndata.text, innerText = ndata.text:sub(2, -2), questid = ndata.userdata})
			-- �����
			elseif ndata.name == "recipelink" then
				local craft, recipe = string.match(ndata.script, "this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "recipe", text = ndata.text, innerText = ndata.text:sub(2, -2), craftid = craft, recipeid = recipe})
			-- ����
			elseif ndata.name == "skilllink" then
				local skillinfo = string.match(ndata.script, "this.skillKey=%{(.-)%}")
				local skillKey = {}
				for w in string.gfind(skillinfo, "(.-)%,") do
					local k, v  = string.match(w, "(.-)=(%w+)")
					skillKey[k] = v
				end
				skillKey.text = ndata.text
				skillKey.innerText = ndata.text:sub(2, -2)
				table.insert(t2, skillKey)
			-- �ƺ�
			elseif ndata.name == "designationlink" then
				local id, fix = string.match(ndata.script, "this.dwID=(%d+)%s*this.bPrefix=(.-)")
				table.insert(t2, {type = "designation", text = ndata.text, innerText = ndata.text:sub(2, -2), id = id, prefix = fix})
			-- �����ؼ�
			elseif ndata.name == "skillrecipelink" then
				local id, level = string.match(ndata.script, "this.dwID=(%d+)%s*this.dwLevel=(%d+)")
				table.insert(t2, {type = "skillrecipe", text = ndata.text, innerText = ndata.text:sub(2, -2), id = id, level = level})
			-- �鼮
			elseif ndata.name == "booklink" then
				local version, tab, index, id = string.match(ndata.script, "this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)%s*this.nBookRecipeID=(%d+)")
				table.insert(t2, {type = "book", text = ndata.text, innerText = ndata.text:sub(2, -2), version = version, tabtype = tab, index = index, bookinfo = id})
			-- �ɾ�
			elseif ndata.name == "achievementlink" then
				local id = string.match(ndata.script, "this.dwID=(%d+)")
				table.insert(t2, {type = "achievement", text = ndata.text, innerText = ndata.text:sub(2, -2), id = id})
			-- ǿ��
			elseif ndata.name == "enchantlink" then
				local pro, craft, recipe = string.match(ndata.script, "this.dwProID=(%d+)%s*this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "enchant", text = ndata.text, innerText = ndata.text:sub(2, -2), proid = pro, craftid = craft, recipeid = recipe})
			-- �¼�
			elseif ndata.name == "eventlink" then
				local eventname, linkinfo = string.match(ndata.script, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"$')
				if not eventname then
					eventname, linkinfo = string.match(ndata.script, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"')
				end
				table.insert(t2, {type = "eventlink", text = ndata.text, innerText = ndata.text:sub(2, -2), name = eventname, linkinfo = linkinfo:gsub("\\(.)", "%1")})
			-- δ֪���͵��ַ���
			elseif ndata.text then
				is_normaltext = true
			end
			if is_normaltext then
				table.insert(t2, {type = "text", text = ndata.text, innerText = ndata.text})
			end
		end
	end
	return t2
end
MY.FormatChatContent = MY.Chat.FormatContent

-- �ַ�����һ������table�ṹ��
function MY.Chat.StringfyContent(t)
	local t1 = {}
	for _, v in ipairs(t) do
		table.insert(t1, v.text)
	end
	return table.concat(t1)
end
MY.StringfyChatContent = MY.Chat.StringfyContent

-- �ж�ĳ��Ƶ���ܷ���
-- (bool) MY.CanTalk(number nChannel)
function MY.Chat.CanTalk(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end
MY.CanTalk = MY.Chat.CanTalk

-- get channel header
_C.tTalkChannelHeader = {
	[PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
	[PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
	[PLAYER_TALK_CHANNEL.TEAM] = "/p ",
	[PLAYER_TALK_CHANNEL.RAID] = "/t ",
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
	[PLAYER_TALK_CHANNEL.TONG] = "/g ",
	[PLAYER_TALK_CHANNEL.SENCE] = "/y ",
	[PLAYER_TALK_CHANNEL.FORCE] = "/f ",
	[PLAYER_TALK_CHANNEL.CAMP] = "/c ",
	[PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
-- �л�����Ƶ��
-- (void) MY.SwitchChat(number nChannel)
-- (void) MY.SwitchChat(string szHeader)
-- (void) MY.SwitchChat(string szName)
function MY.Chat.SwitchChat(nChannel)
	local szHeader = _C.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		Station.Lookup("Lowest2/EditBox"):Show()
		Station.Lookup("Lowest2/EditBox/Edit_Input"):SetText("/w ")
		Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
	elseif type(nChannel) == "string" then
		if string.sub(nChannel, 1, 1) == "/" then
			if nChannel == '/cafk' or nChannel == '/catr' then
				SwitchChatChannel(nChannel)
				MY.Chat.Talk(nil, nChannel, nil, nil, nil, true)
				Station.Lookup("Lowest2/EditBox"):Show()
			else
				SwitchChatChannel(nChannel.." ")
			end
		else
			SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
		end
	end
end
MY.SwitchChat = MY.Chat.SwitchChat

-- ���������õ�������
function MY.Chat.FocusChatBox()
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
end
MY.FocusChatBox = MY.Chat.FocusChatBox

-- parse faceicon in talking message
function MY.Chat.ParseFaceIcon(t)
	_C.InitEmotion()
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "emotion" then
				v.type = "text"
			end
			table.insert(t2, v)
		else
			local szText = v.text
			local szLeft = ''
			while szText and #szText > 0 do
				local szFace, dwFaceID = nil, nil
				local nPos = StringFindW(szText, "#")
				if not nPos then
					szLeft = szLeft .. szText
					szText = ''
				else
					szLeft = szLeft .. string.sub(szText, 1, nPos - 1)
					szText = string.sub(szText, nPos)
					for i = math.min(_C.nMaxEmotionLen, wstring.len(szText)), 2, -1 do
						local szTest = wstring.sub(szText, 1, i)
						local emo = MY.Chat.GetEmotion(szTest)
						if emo then
							szFace, dwFaceID = szTest, emo.dwID
							szText = szText:sub(szFace:len() + 1)
							break
						end
					end
					if szFace then -- emotion cmd matched
						if #szLeft > 0 then
							table.insert(t2, { type = "text", text = szLeft })
							szLeft = ''
						end
						table.insert(t2, { type = "emotion", text = szFace, id = dwFaceID })
					elseif nPos then -- find '#' but not match emotion
						szLeft = szLeft .. szText:sub(1, 1)
						szText = szText:sub(2)
					end
				end
			end
			if #szLeft > 0 then
				table.insert(t2, { type = "text", text = szLeft })
				szLeft = ''
			end
		end
	end
	return t2
end
-- parse name in talking message
function MY.Chat.ParseName(t)
	local me = GetClientPlayer()
	local tar = MY.GetObject(me.GetTarget())
	for i, v in ipairs(t) do
		if v.type == "text" then
			v.text = string.gsub(v.text, "%$zj", '[' .. me.szName .. ']')
			if tar then
				v.text = string.gsub(v.text, "%$mb", '[' .. tar.szName .. ']')
			end
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "name" then
				v = { type = "text", text = "["..v.name.."]" }
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szName = nil
				local nPos1, nPos2 = string.find(v.text, '%[[^%[%]]+%]', nOff)
				if not nPos1 then
					nPos1 = nLen
				else
					szName = string.sub(v.text, nPos1 + 1, nPos2 - 1)
					nPos1 = nPos1 - 1
				end
				if nPos1 >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos1) })
					nOff = nPos1 + 1
				end
				if szName then
					table.insert(t2, { type = "name", text = '[' .. szName .. ']', name = szName })
					nOff = nPos2 + 1
				end
			end
		end
	end
	return t2
end
MY.Chat.tSensitiveWord = {
	'   ',
	'  ' .. g_tStrings.STR_ONE_CHINESE_SPACE,
	' '  .. g_tStrings.STR_ONE_CHINESE_SPACE:rep(2),
	g_tStrings.STR_ONE_CHINESE_SPACE:rep(3),
	g_tStrings.STR_ONE_CHINESE_SPACE:rep(2) .. ' ',
	g_tStrings.STR_ONE_CHINESE_SPACE .. '  ',
	' ' .. g_tStrings.STR_ONE_CHINESE_SPACE .. ' ',
	g_tStrings.STR_ONE_CHINESE_SPACE .. ' ' .. g_tStrings.STR_ONE_CHINESE_SPACE,
}
-- anti sensitive word shielding in talking message
function MY.Chat.ParseAntiSWS(t)
	local tSensitiveWord = MY.Chat.tSensitiveWord
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type == "text" then
			local szText = v.text
			while szText and #szText > 0 do
				local nSensitiveWordEndLen = 1 -- ���һ���ַ���Ҫ�ü������ַ�����С
				local nSensitiveWordEndPos = #szText + 1
				for _, szSensitiveWord in ipairs(tSensitiveWord) do
					local _, nEndPos = wstring.find(szText, szSensitiveWord)
					if nEndPos and nEndPos < nSensitiveWordEndPos then
						local nSensitiveWordLenW = wstring.len(szSensitiveWord)
						nSensitiveWordEndLen = string.len(wstring.sub(szSensitiveWord, nSensitiveWordLenW, nSensitiveWordLenW))
						nSensitiveWordEndPos = nEndPos
					end
				end

				table.insert(t2, {
					type = "text",
					text = string.sub(szText, 1, nSensitiveWordEndPos - nSensitiveWordEndLen)
				})
				szText = string.sub(szText, nSensitiveWordEndPos + 1 - nSensitiveWordEndLen)
			end
		else
			table.insert(t2, v)
		end
	end
	return t2
end

-- ������������
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape, [boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape[boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- szTarget       -- ���ĵ�Ŀ���ɫ��
-- szText         -- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel       -- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEscape      -- *��ѡ* ���������������еı���ͼƬ�����֣�Ĭ��Ϊ false
-- bSaveDeny      -- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- bPushToChatBox -- *��ѡ* �����͵������Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�
function MY.Chat.Talk(nChannel, szText, szUUID, bNoEscape, bSaveDeny, bPushToChatBox)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		return MY.Sysmsg({szText}, '')
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		tSay = {{ type = "text", text = szText}}
	end
	if not bNoEscape then
		tSay = MY.Chat.ParseFaceIcon(tSay)
		tSay = MY.Chat.ParseName(tSay)
	end
	tSay = MY.Chat.ParseAntiSWS(tSay)
	if MY.IsShieldedVersion() then
		local nLen = 0
		for i, v in ipairs(tSay) do
			if nLen <= 64 then
				nLen = nLen + MY.String.LenW(v.text or v.name or '')
				if nLen > 64 then
					if v.text then v.text = MY.String.SubW(v.text, 1, 64 - nLen ) end
					if v.name then v.name = MY.String.SubW(v.name, 1, 64 - nLen ) end
					for j=#tSay, i+1, -1 do
						table.remove(tSay, j)
					end
				end
			end
		end
	end
	if bPushToChatBox or (bSaveDeny and not MY.CanTalk(nChannel)) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			edit:InsertObj(v.text, v)
		end
		-- change to this channel
		MY.SwitchChat(nChannel)
		-- set focus
		Station.SetFocusWindow(edit)
	else
		if not tSay[1]
		or tSay[1].name ~= ""
		or tSay[1].type ~= "eventlink" then
			table.insert(tSay, 1, {
				type = "eventlink", name = "",
				linkinfo = MY.Json.Encode({
					via = "MY",
					uuid = szUUID and tostring(szUUID),
				})
			})
		end
		me.Talk(nChannel, szTarget, tSay)
	end
end
MY.Talk = MY.Chat.Talk

do
local SPACE = " "
local W_SPACE = g_tStrings.STR_ONE_CHINESE_SPACE
local metaAlignment = { __index = function() return "L" end }
local function MergeHW(s)
	return s:gsub(W_SPACE, "W"):gsub(" (W*) ", W_SPACE .. "%1"):gsub("W", W_SPACE)
end
function MY.TabTalk(nChannel, aTable, aAlignment)
	local aLenHW, aMaxLenHW = {}, {}
	for i, aText in ipairs(aTable) do
		aLenHW[i] = {}
		for j, szText in ipairs(aText) do
			aLenHW[i][j] = #szText
			aMaxLenHW[j] = max(aLenHW[i][j], aMaxLenHW[j] or 0)
		end
	end
	local aAlignment = setmetatable(aAlignment or {}, metaAlignment)
	for i, aText in ipairs(aTable) do
		local aTalk, szFixL, szFixR = {}
		local nFixLenFW, nFixLenHW
		for j, szText in ipairs(aText) do
			nFixLenFW = floor(max(0, aMaxLenHW[j] - aLenHW[i][j]) / 2)
			if nFixLenFW % 2 == 1 then
				nFixLenFW = nFixLenFW - 1
			end
			nFixLenHW = aMaxLenHW[j] - (aLenHW[i][j] + nFixLenFW * 2)
			szFixL = W_SPACE:rep(ceil(nFixLenFW / 2)) .. SPACE:rep(ceil(nFixLenHW / 2))
			szFixR = W_SPACE:rep(floor(nFixLenFW / 2)) .. SPACE:rep(floor(nFixLenHW / 2))
			if aAlignment[j] == "M" then
				aTalk[j] = szFixL .. szText .. szFixR
			elseif aAlignment[j] == "R" then
				aTalk[j] = MergeHW(szFixL .. szFixR) .. szText
			else
				aTalk[j] = szText .. MergeHW(szFixL .. szFixR)
			end
		end
		-- MY.Sysmsg({(concat(aTalk, "|"))})
		MY.Talk(nChannel, (concat(aTalk, " ")))
	end
end
end

local m_LevelUpData
local function GetRegisterChannelLimitTable()
	if not m_LevelUpData then
		local me = GetClientPlayer()
		if not me then
			return false
		end
		local path = ("settings\\LevelUpData\\%s.tab"):format(({
			[ROLE_TYPE.STANDARD_MALE  ] = "StandardMale"  ,
			[ROLE_TYPE.STANDARD_FEMALE] = "StandardFemale",
			[ROLE_TYPE.STRONG_MALE    ] = "StrongMale"    ,
			[ROLE_TYPE.SEXY_FEMALE    ] = "SexyFemale"    ,
			[ROLE_TYPE.LITTLE_BOY     ] = "LittleBoy"     ,
			[ROLE_TYPE.LITTLE_GIRL    ] = "LittleGirl"    ,
		})[me.nRoleType])
		local tTitle = {
			{f = "i", t = "Level"},
			{f = "i", t = "Experience"},
			{f = "i", t = "Strength"},
			{f = "i", t = "Agility"},
			{f = "i", t = "Vigor"},
			{f = "i", t = "Spirit"},
			{f = "i", t = "Spunk"},
			{f = "i", t = "MaxLife"},
			{f = "i", t = "MaxMana"},
			{f = "i", t = "MaxStamina"},
			{f = "i", t = "MaxThew"},
			{f = "i", t = "MaxAssistExp"},
			{f = "i", t = "MaxAssistTimes"},
			{f = "i", t = "RunSpeed"},
			{f = "i", t = "JumpSpeed"},
			{f = "i", t = "Height"},
			{f = "i", t = "LifeReplenish"},
			{f = "i", t = "LifeReplenishPercent"},
			{f = "i", t = "LifeReplenishExt"},
			{f = "i", t = "ManaReplenish"},
			{f = "i", t = "ManaReplenishPercent"},
			{f = "i", t = "ManaReplenishExt"},
			{f = "i", t = "HitBase"},
			{f = "i", t = "ParryBaseRate"},
			{f = "i", t = "PhysicsCriticalStrike"},
			{f = "i", t = "SolarCriticalStrike"},
			{f = "i", t = "NeutralCriticalStrike"},
			{f = "i", t = "LunarCriticalStrike"},
			{f = "i", t = "PoisonCriticalStrike"},
			{f = "i", t = "NoneWeaponAttackSpeedBase"},
			{f = "i", t = "MaxPhysicsDefence"},
			{f = "i", t = "WorldChannelDailyLimit"},
			{f = "i", t = "ForceChannelDailyLimit"},
			{f = "i", t = "CampChannelDailyLimit"},
			{f = "i", t = "MaxContribution"},
			{f = "i", t = "WhisperDailyLimit"},
			{f = "i", t = "IdentityChannelDailyLimit"},
			{f = "i", t = "SprintPowerMax"},
			{f = "i", t = "SprintPowerCost"},
			{f = "i", t = "SprintPowerRevive"},
			{f = "i", t = "SprintPowerCostOnWall"},
			{f = "i", t = "SprintPowerCostStandOnWall"},
			{f = "i", t = "SprintPowerCostRunOnWallExtra"},
			{f = "i", t = "HorseSprintPowerMax"},
			{f = "i", t = "HorseSprintPowerCost"},
			{f = "i", t = "HorseSprintPowerRevive"},
			{f = "i", t = "SceneChannelDailyLimit"},
			{f = "i", t = "NearbyChannelDailyLimit"},
			{f = "i", t = "WorldChannelDailyLimitByVIP"},
			{f = "i", t = "WorldChannelDailyLimitBySuperVIP"},
		}
		m_LevelUpData = KG_Table.Load(path, tTitle, FILE_OPEN_MODE.NORMAL)
	end
	return m_LevelUpData
end
local DAILY_LIMIT_TABLE_KEY = {
	[PLAYER_TALK_CHANNEL.WORLD  ] = "WorldChannelDailyLimit",
	[PLAYER_TALK_CHANNEL.FORCE  ] = "ForceChannelDailyLimit",
	[PLAYER_TALK_CHANNEL.CAMP   ] = "CampChannelDailyLimit",
	[PLAYER_TALK_CHANNEL.SENCE  ] = "SceneChannelDailyLimit",
	[PLAYER_TALK_CHANNEL.NEARBY ] = "NearbyChannelDailyLimit",
	[PLAYER_TALK_CHANNEL.WHISPER] = "WhisperDailyLimit",
}
function MY.Chat.GetChannelDailyLimit(nLevel, nChannel)
	local LevelUpData = GetRegisterChannelLimitTable()
	if not LevelUpData then
		return false
	end
	local szKey = DAILY_LIMIT_TABLE_KEY[nChannel]
	if not szKey then
		return -1
	end
	local tUpData = LevelUpData:Search(nLevel)
	if not tUpData then
		return false
	end
	return tUpData[szKey] or -1
end
MY.GetChannelDailyLimit = MY.Chat.GetChannelDailyLimit

_C.tMsgMonitorFun = {}
-- Register:   MY.Chat.RegisterMsgMonitor(string szKey, function fnAction, table tChannels)
--             MY.Chat.RegisterMsgMonitor(function fnAction, table tChannels)
-- Unregister: MY.Chat.RegisterMsgMonitor(string szKey)
function MY.Chat.RegisterMsgMonitor(arg0, arg1, arg2)
	local szKey, fnAction, tChannels
	local tp0, tp1, tp2 = type(arg0), type(arg1), type(arg2)
	if tp0 == 'string' and tp1 == 'function' and tp2 == 'table' then
		szKey, fnAction, tChannels = arg0, arg1, arg2
	elseif tp0 == 'function' and tp1 == 'table' then
		fnAction, tChannels = arg0, arg1
	elseif tp0 == 'string' and not arg1 then
		szKey = arg0
	end

	if szKey and _C.tMsgMonitorFun[szKey] then
		UnRegisterMsgMonitor(_C.tMsgMonitorFun[szKey].fn)
		_C.tMsgMonitorFun[szKey] = nil
	end
	if fnAction and tChannels then
		_C.tMsgMonitorFun[szKey] = { fn = function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
			-- filter addon comm.
			if StringFindW(szMsg, "eventlink") and StringFindW(szMsg, _L["Addon comm."]) then
				return
			end
			fnAction(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
		end, ch = tChannels }
		RegisterMsgMonitor(_C.tMsgMonitorFun[szKey].fn, _C.tMsgMonitorFun[szKey].ch)
	end
end
MY.RegisterMsgMonitor = MY.Chat.RegisterMsgMonitor

_C.tHookChat = {}
-- HOOK������
-- ע�����fnOnActive������û�м��������������ִ��fnBefore��fnAfter
--     ͬʱ���������л�ʱ�ᴥ��fnOnActive
function MY.Chat.HookChatPanel(szKey, fnBefore, fnAfter, fnOnActive)
	if type(szKey) == "function" then
		szKey, fnBefore, fnAfter, fnOnActive = GetTickCount(), szKey, fnBefore, fnAfter
		while _C.tHookChat[szKey] do
			szKey = szKey + 0.1
		end
	end
	if fnBefore or fnAfter or fnOnActive then
		_C.tHookChat[szKey] = {
			fnBefore = fnBefore, fnAfter = fnAfter, fnOnActive = fnOnActive
		}
	else
		_C.tHookChat[szKey] = nil
	end
end
MY.HookChatPanel = MY.Chat.HookChatPanel

function _C.OnChatPanelActive(h)
	for szKey, hc in pairs(_C.tHookChat) do
		if type(hc.fnOnActive) == "function" then
			local status, err = pcall(hc.fnOnActive, h)
			if not status then
				MY.Debug({err}, 'HookChatPanelOnActive#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

function _C.OnChatPanelNamelinkLButtonDown(...)
	this.__MY_OnItemLButtonDown(...)
	MY.ChatLinkEventHandlers.OnNameLClick(...)
end

function _C.OnChatPanelAppendItemFromString(h, szMsg, szChannel, dwTime, nR, nG, nB, ...)
	local bActived = h:GetRoot():Lookup('CheckBox_Title'):IsCheckBoxChecked()
	-- deal with fnBefore
	for szKey, hc in pairs(_C.tHookChat) do
		hc.param = EMPTY_TABLE
		-- if fnBefore exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnBefore) == "function" and (bActived or not hc.fnOnActive) then
			-- try to execute fnBefore and get return values
			local status, msg, ret = pcall(hc.fnBefore, h, szChannel, szMsg, dwTime, nR, nG, nB, ...)
			-- when fnBefore execute succeed
			if status then
				-- set msg if returned string
				if type(msg) == "string" then
					szMsg = msg
				end
				-- save fnAfter's param
				hc.param = ret
			else
				MY.Debug({msg}, 'HookChatPanel.Before#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
	local nIndex = h:GetItemCount()
	-- call ori append
	h:_AppendItemFromString_MY(szMsg, szChannel, dwTime, nR, nG, nB, ...)
	-- hook namelink lbutton down
	for i = h:GetItemCount() - 1, nIndex, -1 do
		local hItem = h:Lookup(i)
		if hItem:GetName():find("^namelink_%d+$") then
			hItem.bMyChatRendered = true
			if hItem.OnItemLButtonDown then
				hItem.__MY_OnItemLButtonDown = hItem.OnItemLButtonDown
				hItem.OnItemLButtonDown = _C.OnChatPanelNamelinkLButtonDown
			else
				hItem.OnItemLButtonDown = MY.ChatLinkEventHandlers.OnNameLClick
			end
		end
	end
	-- deal with fnAfter
	for szKey, hc in pairs(_C.tHookChat) do
		-- if fnAfter exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnAfter) == "function" and (bActived or not hc.fnOnActive) then
			local status, err = pcall(hc.fnAfter, h, hc.param, szChannel, szMsg, dwTime, nR, nG, nB, ...)
			if not status then
				MY.Debug({err}, 'HookChatPanel.After#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

do
local function Hook(i)
	local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
	-- local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
	-- if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
	if h and not h._AppendItemFromString_MY then
		h:GetRoot():Lookup('CheckBox_Title').OnCheckBoxCheck = function()
			_C.OnChatPanelActive(h)
		end
		h._AppendItemFromString_MY = h.AppendItemFromString
		h.AppendItemFromString = _C.OnChatPanelAppendItemFromString
	end
end

local function Unhook(i)
	local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
	if h and h._AppendItemFromString_MY then
		h.AppendItemFromString = _C._AppendItemFromString_MY
		h._AppendItemFromString_MY = nil
	end
end

local function HookAll()
	for i = 1, 10 do
		Hook(i)
	end
end
MY.RegisterEvent("CHAT_PANEL_INIT.ChatPanelHook", HookAll)
MY.RegisterEvent("CHAT_PANEL_OPEN.ChatPanelHook", function(event) Hook(arg0) end)
MY.RegisterEvent('RELOAD_UI_ADDON_END.ChatPanelHook', HookAll)

local function UnhookAll()
	for i = 1, 10 do
		Unhook(i)
	end
end
MY.RegisterExit("ChatPanelHook", UnhookAll)
MY.RegisterReload("ChatPanelHook", UnhookAll)
end