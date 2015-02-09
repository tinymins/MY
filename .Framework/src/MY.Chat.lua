-----------------------------------------------
-- @Desc  : �������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-02-09 15:37:11
-- @Ref: �����������Դ�� @haimanchajian.com
-----------------------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = MY or {}
MY.Chat = MY.Chat or {}
local _C, _L = {}, MY.LoadLangPack()

-- ��������ٳ�����
-- ���츴�Ʋ�����
MY.Chat.RepeatChatLine = function(hTime)
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

-- ��������ʼ��
_C.nMaxEmotionLen = 0
_C.InitEmotion = function()
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

--[[ ��ȡ��������б�
	typedef emo table
	(emo[]) MY.Chat.GetEmotion()                             -- �������б����б�
	(emo)   MY.Chat.GetEmotion(szCommand)                    -- ����ָ��Cmd�ı���
	(emo)   MY.Chat.GetEmotion(szImageFile, nFrame, szType)  -- ����ָ��ͼ��ı���
]]
MY.Chat.GetEmotion = function(arg0, arg1, arg2)
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

-- ��ȡ����������Text
MY.Chat.GetCopyLinkText = function(szText, rgbf)
	szText = szText or _L[' * ']
	rgbf   = rgbf   or { f = 10 }
	
	return GetFormatText(szText, rgbf.f, rgbf.r, rgbf.g, rgbf.b, 515,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end",
		"copylink")
end

-- ��ȡ����������Text
MY.Chat.GetTimeLinkText = function(rgbfs)
	rgbfs = rgbfs or { f = 10 }
	return GetFormatText(
		MY.Sys.FormatTime(rgbfs.s or '[hh:mm.ss]', GetCurrentTime()),
		rgbfs.f, rgbfs.r, rgbfs.g, rgbfs.b, 515,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end",
		"timelink"
	)
end

-- ����������
MY.Chat.CopyChatLine = function(hTime)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	Station.Lookup("Lowest2/EditBox"):Show()
	edit:ClearText()
	local h, i, bBegin = hTime:GetParent(), hTime:GetIndex(), nil
	-- loop
	for i = i + 1, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == "Text" then
			local szName = p:GetName()
			if szName ~= "timelink" and szName ~= "copylink" and szName ~= "msglink" and szName ~= "time" then
				local szText, bEnd = p:GetText(), false
				if StringFindW(szText, "\n") then
					szText = StringReplaceW(szText, "\n", "")
					bEnd = true
				end
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
					edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
				else
					-- NPC �������⴦��
					if bBegin == nil then
						local r, g, b = p:GetFontColor()
						if r == 255 and g == 150 and b == 0 then
							bBegin = false
						end
					end
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
			end
		elseif p:GetType() == "Image" or p:GetType() == "Animate" then
			local dwID = tonumber(p:GetName())
			if dwID then
				local emo = MY.Chat.GetEmotion(dwID)
				if emo then
					if MY.Sys.GetLang() ~= 'vivn' then
						edit:InsertObj(emo.szCmd, { type = "emotion", text = emo.szCmd, id = emo.dwID })
					else
						edit:InsertObj(emo.szCmd, { type = "text", text = emo.szCmd })
					end
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end

MY.Chat.LinkEventHandler = {
	OnNameLClick = function(hT)
		if not hT then
			hT = this
		end
		if IsCtrlKeyDown() then
			MY.Chat.CopyChatItem(hT)
		else
			MY.SwitchChat(MY.UI(hT):text())
			local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
			if edit then
				Station.SetFocusWindow(edit)
			end
		end
	end,
	OnNameRClick = function(hT)
		if not hT then
			hT = this
		end
		PopupMenu((function()
			return MY.Game.GetTargetContextMenu(TARGET.PLAYER, (MY.UI(hT):text():gsub('[%[%]]', '')))
		end)())
	end,
	OnCopyLClick = function(hT)
		MY.Chat.CopyChatLine(hT or this)
	end,
	OnCopyRClick = function(hT)
		MY.Chat.RepeatChatLine(hT or this)
	end,
	OnItemLClick = function(hT)
		OnItemLinkDown(hT or this)
	end,
	OnItemRClick = function(hT)
		if IsCtrlKeyDown() then
			MY.Chat.CopyChatItem(hT or this)
		end
	end,
}
--[[ ��link�¼���Ӧ
	(userdata) MY.Chat.RenderLink(userdata link)                   ����link�ĸ����¼��� namelink��һ��������TextԪ��
	(userdata) MY.Chat.RenderLink(userdata element, userdata link) ����element�ĸ����¼��� ����Դ��link
	(string) MY.Chat.RenderLink(string szMsg)                      ��ʽ��szMsg ��������ĳ����� ���ʱ����Ӧ
	link   : һ��������TextԪ��
	element: һ�����Թ������Ϣ��Ӧ��UIԪ��
	szMsg  : ��ʽ����UIXML��Ϣ
]]
MY.Chat.RenderLink = function(argv, argv2)
	if type(argv) == 'string' then
		local szMsg = argv
		szMsg = string.gsub(szMsg, "(<text>.-</text>)", function (html)
			local xml = MY.Xml.Decode(html)
			if not (xml and xml[1] and xml[1][''] and xml[1][''].name) then
				return
			end
			
			local name, script = xml[1][''].name, xml[1][''].script
			if script then
				script = script .. '\n'
			else
				script = ''
			end
			
			if name:sub(1, 8) == 'namelink' then
				script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.LinkEventHandler.OnNameLClick(this) end\nthis.OnItemRButtonDown=function() MY.Chat.LinkEventHandler.OnNameRClick(this) end'
			elseif name == 'copy' or name == 'copylink' or name == 'timelink' then
				script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end'
			else
				script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.LinkEventHandler.OnItemLClick(this) end\nthis.OnItemRButtonDown=function() MY.Chat.LinkEventHandler.OnItemRClick(this) end'
			end
			
			if #script > 0 then
				xml[1][''].eventid = 883
				xml[1][''].script = script
			end
			html = MY.Xml.Encode(xml)
			
			return html
		end)
		argv = szMsg
	elseif type(argv) == 'table' and type(argv.GetName) == 'function' then
		if argv.bMyChatRendered then
			return
		end
		local link = MY.UI(argv)
		local name = link:name()
		if name:sub(1, 8) == 'namelink' then
			link:click(function() MY.Chat.LinkEventHandler.OnNameLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnNameRClick(argv2) end)
		elseif name == 'copy' or name == 'copylink' then
			link:click(function() MY.Chat.LinkEventHandler.OnCopyLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnCopyRClick(argv2) end)
		else
			link:click(function() MY.Chat.LinkEventHandler.OnItemLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnItemRClick(argv2) end)
		end
		argv.bMyChatRendered = true
	end
	
	return argv
end

-- ����Item�������
MY.Chat.CopyChatItem = function(p)
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

--������Ϣ
MY.Chat.FormatContent = function(szMsg)
	local t = {}
	for n, w in string.gfind(szMsg, "<(%w+)>(.-)</%1>") do
		if w then
			table.insert(t, w)
		end
	end
	-- Output(t)
	local t2 = {}
	for k, v in pairs(t) do
		if not string.find(v, "name=") then
			if string.find(v, "frame=") then
				local n = string.match(v, "frame=(%d+)")
				local p = string.match(v, 'path="(.-)"')
				local emo = MY.Chat.GetEmotion(p, n, 'image')
				if emo then
					table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			elseif string.find(v, "group=") then
				local n = string.match(v, "group=(%d+)")
				local p = string.match(v, 'path="(.-)"')
				local emo = MY.Chat.GetEmotion(p, n, 'animate')
				if emo then
					table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			else
				--��ͨ����
				local s = string.match(v, "\"(.*)\"")
				table.insert(t2, {type= "text", text = s, innerText = s})
			end
		else
			--��Ʒ����
			if string.find(v, "name=\"itemlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {type = "item", text = "["..name.."]", innerText = name, item = userdata})
			--��Ʒ��Ϣ
			elseif string.find(v, "name=\"iteminfolink\"") then
				local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)")
				table.insert(t2, {type = "iteminfo", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index})
			--����
			elseif string.find(v, "name=\"namelink_%d+\"") then
				local name = string.match(v,"%[(.-)%]")
				table.insert(t2, {type = "name", text = "["..name.."]", innerText = "["..name.."]", name = name})
			--����
			elseif string.find(v, "name=\"questlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {type = "quest", text = "["..name.."]", innerText = name, questid = userdata})
			--�����
			elseif string.find(v, "name=\"recipelink\"") then
				local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "recipe", text = "["..name.."]", innerText = name, craftid = craft, recipeid = recipe})
			--����
			elseif string.find(v, "name=\"skilllink\"") then
				local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
				local skillKey = {}
				for w in string.gfind(skillinfo, "(.-)%,") do
					local k, v  = string.match(w, "(.-)=(%w+)")
					skillKey[k] = v
				end
				skillKey.text = "["..name.."]"
				skillKey.innerText = "["..name.."]"
				table.insert(t2, skillKey)
			--�ƺ�
			elseif string.find(v, "name=\"designationlink\"") then
				local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.bPrefix=(.-)")
				table.insert(t2, {type = "designation", text = "["..name.."]", innerText = name, id = id, prefix = fix})
			--�����ؼ�
			elseif string.find(v, "name=\"skillrecipelink\"") then
				local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.dwLevel=(%d+)")
				table.insert(t2, {type = "skillrecipe", text = "["..name.."]", innerText = name, id = id, level = level})
			--�鼮
			elseif string.find(v, "name=\"booklink\"") then
				local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)\\%s*this.nBookRecipeID=(%d+)")
				table.insert(t2, {type = "book", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index, bookinfo = id})
			--�ɾ�
			elseif string.find(v, "name=\"achievementlink\"") then
				local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
				table.insert(t2, {type = "achievement", text = "["..name.."]", innerText = name, id = id})
			--ǿ��
			elseif string.find(v, "name=\"enchantlink\"") then
				local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\%s*this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "enchant", text = "["..name.."]", innerText = name, proid = pro, craftid = craft, recipeid = recipe})
			--�¼�
			elseif string.find(v, "name=\"eventlink\"") then
				local name, na, info = string.match(v,'text="(.-)".-script="this.szName=\\"(.-)\\"\\%s*this.szLinkInfo=\\"(.-)\\"')
				table.insert(t2, {type = "eventlink", text = name, innerText = name, name = na, linkinfo = info or ""})
			end
		end
	end
	return t2
end

--[[ �ж�ĳ��Ƶ���ܷ���
-- (bool) MY.CanTalk(number nChannel)]]
MY.Chat.CanTalk = function(nChannel)
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
--[[ �л�����Ƶ��
	(void) MY.SwitchChat(number nChannel)
	(void) MY.SwitchChat(string szHeader)
	(void) MY.SwitchChat(string szName)
]]
MY.Chat.SwitchChat = function(nChannel)
	local szHeader = _C.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		if string.sub(nChannel, 1, 1) == "/" then
			if nChannel == '/cafk' or nChannel == '/catr' then
				SwitchChatChannel(nChannel)
				MY.Chat.Talk(nil, nChannel, nil, nil, true)
				Station.Lookup("Lowest2/EditBox"):Show()
				Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
			else
				SwitchChatChannel(nChannel.." ")
			end
		else
			SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
		end
	end
end
MY.SwitchChat = MY.Chat.SwitchChat


-- parse faceicon in talking message
MY.Chat.ParseFaceIcon = function(t)
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
						if MY.Sys.GetLang() ~= 'vivn' then
							table.insert(t2, { type = "emotion", text = szFace, id = dwFaceID })
						else
							table.insert(t2, { type = "text", text = szFace })
						end
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
MY.Chat.ParseName = function(t)
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
	' '  .. g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE,
	'  ' .. g_tStrings.STR_ONE_CHINESE_SPACE,
	g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE,
	g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE .. ' ',
	g_tStrings.STR_ONE_CHINESE_SPACE .. '  ',
}
-- anti sensitive word shielding in talking message
MY.Chat.ParseAntiSWS = function(t)
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

--[[ ������������
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape, [boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape[boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- szTarget       -- ���ĵ�Ŀ���ɫ��
-- szText         -- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel       -- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEscape      -- *��ѡ* ���������������еı���ͼƬ�����֣�Ĭ��Ϊ false
-- bSaveDeny      -- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- bPushToChatBox -- *��ѡ* �����͵������Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�]]
MY.Chat.Talk = function(nChannel, szText, bNoEscape, bSaveDeny, bPushToChatBox)
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
		local tar = MY.GetObject(me.GetTarget())
		szText = string.gsub(szText, "%$zj", '['..me.szName..']')
		if tar then
			szText = string.gsub(szText, "%$mb", '['..tar.szName..']')
		end
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
		me.Talk(nChannel, szTarget, tSay)
	end
end
MY.Talk = MY.Chat.Talk

_C.tHookChatFun = {}
--[[ HOOK������ ]]
MY.Chat.HookChatPanel = function(arg0, arg1, arg2)
	local fnBefore, fnAfter, id
	if type(arg0)=="string" then
		id, fnBefore, fnAfter = arg0, arg1, arg2
	elseif type(arg1)=="string" then
		id, fnBefore, fnAfter = arg1, arg0, arg2
	elseif type(arg2)=="string" then
		id, fnBefore, fnAfter = arg2, arg0, arg1
	else
		id, fnBefore, fnAfter = nil, arg0, arg1
	end
	if type(fnBefore)~="function" and type(fnAfter)~="function" then
		return nil
	end
	if id then
		for i=#_C.tHookChatFun, 1, -1 do
			if _C.tHookChatFun[i].id == id then
				table.remove(_C.tHookChatFun, i)
			end
		end
	end
	if fnBefore then
		table.insert(_C.tHookChatFun, {fnBefore = fnBefore, fnAfter = fnAfter, id = id})
	end
end
MY.HookChatPanel = MY.Chat.HookChatPanel

_C.HookChatPanelHandle = function(h, szMsg)
	-- add name to emotion icon
	szMsg = string.gsub(szMsg, "<animate>.-path=\"(.-)\"(.-)group=(%d+).-</animate>", function (szImagePath, szExtra, szGroup)
		local emo = MY.Chat.GetEmotion(szImagePath, szGroup, 'animate')
		if emo then
			return '<animate>path="'..szImagePath..'"'..szExtra..'group='..szGroup..' name="'..emo.dwID..'"</animate>'
		end
	end)
	szMsg = string.gsub(szMsg, "<image>.-path=\"(.-)\"(.-)frame=(%d+).-</image>", function (szImagePath, szExtra, szFrame)
		local emo = MY.Chat.GetEmotion(szImagePath, szFrame, 'image')
		if emo then
			return '<image>path="'..szImagePath..'"'..szExtra..'frame='..szFrame..' name="'..emo.dwID..'"</image>'
		end
	end)
	-- deal with fnBefore
	for i,handle in ipairs(_C.tHookChatFun) do
		-- try to execute fnBefore and get return values
		local result = { pcall(handle.fnBefore, h, szMsg) }
		-- when fnBefore execute succeed
		if result[1] then
			-- remove execute status flag
			table.remove(result, 1)
			if type(result[1])=="string" then
				szMsg = result[1]
			end
			-- remove returned szMsg
			table.remove(result, 1)
		end
		-- the rest is fnAfter param
		_C.tHookChatFun[i].param = result
	end
	-- call ori append
	h:_AppendItemFromString_MY(szMsg)
	-- deal with fnAfter
	for i,handle in ipairs(_C.tHookChatFun) do
		pcall(handle.fnAfter, h, szMsg, unpack(handle.param))
	end
end
MY.RegisterEvent("CHAT_PANEL_INIT", function ()
	for i = 1, 10 do
		local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
		local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
		if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
			h._AppendItemFromString_MY = h._AppendItemFromString_MY or h.AppendItemFromString
			h.AppendItemFromString = _C.HookChatPanelHandle
		end
	end
end)
