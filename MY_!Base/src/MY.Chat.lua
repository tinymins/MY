--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天相关模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
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
-- 本地函数和变量
-----------------------------------------------
local _L = MY.LoadLangPack()
local EMPTY_TABLE = SetmetaReadonly({})

-- 海鳗里面抠出来的
-- 聊天复制并发布
function MY.RepeatChatLine(hTime)
	local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
	if not edit then
		return
	end
	MY.CopyChatLine(hTime)
	local tMsg = edit:GetTextStruct()
	if #tMsg == 0 then
		return
	end
	local nChannel, szName = EditBox_GetChannel()
	if MY.CanTalk(nChannel) then
		GetClientPlayer().Talk(nChannel, szName or '', tMsg)
		edit:ClearText()
	end
end

-- 聊天删除行
function MY.RemoveChatLine(hTime)
	local nIndex   = hTime:GetIndex()
	local hHandle  = hTime:GetParent()
	local nCount   = hHandle:GetItemCount()
	local bCurrent = true
	for i = nIndex, nCount - 1 do
		local hItem = hHandle:Lookup(nIndex)
		if hItem:GetType() == 'Text' and
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

-- 获取复制聊天行Text
function MY.GetCopyLinkText(szText, rgbf)
	szText = szText or _L[' * ']
	rgbf   = rgbf   or { f = 10 }

	return GetFormatText(szText, rgbf.f, rgbf.r, rgbf.g, rgbf.b, 82691,
		'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnCopyLClick\nthis.OnItemMButtonDown=MY.ChatLinkEventHandlers.OnCopyMClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnCopyRClick\nthis.OnItemMouseEnter=MY.ChatLinkEventHandlers.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.ChatLinkEventHandlers.OnCopyMouseLeave',
		'copylink')
end

-- 获取复制聊天行Text
function MY.GetTimeLinkText(rgbfs, dwTime)
	if not dwTime then
		dwTime = GetCurrentTime()
	end
	rgbfs = rgbfs or { f = 10 }
	return GetFormatText(
		MY.FormatTime(rgbfs.s or '[hh:mm.ss]', dwTime),
		rgbfs.f, rgbfs.r, rgbfs.g, rgbfs.b, 82691,
		'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.ChatLinkEventHandlers.OnCopyLClick\nthis.OnItemMButtonDown=MY.ChatLinkEventHandlers.OnCopyMClick\nthis.OnItemRButtonDown=MY.ChatLinkEventHandlers.OnCopyRClick\nthis.OnItemMouseEnter=MY.ChatLinkEventHandlers.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.ChatLinkEventHandlers.OnCopyMouseLeave',
		'timelink'
	)
end

-- 复制聊天行
function MY.CopyChatLine(hTime, bTextEditor)
	local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
	if bTextEditor then
		edit = MY.UI.OpenTextEditor():find('.WndEdit')[1]
	end
	if not edit then
		return
	end
	Station.Lookup('Lowest2/EditBox'):Show()
	edit:ClearText()
	local h, i, bBegin, bContent = hTime:GetParent(), hTime:GetIndex(), nil, false
	-- loop
	for i = i + 1, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == 'Text' then
			local szName = p:GetName()
			if szName ~= 'timelink' and szName ~= 'copylink' and szName ~= 'msglink' and szName ~= 'time' then
				local szText, bEnd = p:GetText(), false
				if not bTextEditor and StringFindW(szText, '\n') then
					szText = StringReplaceW(szText, '\n', '')
					bEnd = true
				end
				bContent = true
				if szName == 'itemlink' then
					edit:InsertObj(szText, { type = 'item', text = szText, item = p:GetUserData() })
				elseif szName == 'iteminfolink' then
					edit:InsertObj(szText, { type = 'iteminfo', text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
				elseif string.sub(szName, 1, 8) == 'namelink' then
					if bBegin == nil then
						bBegin = false
					end
					edit:InsertObj(szText, { type = 'name', text = szText, name = string.match(szText, '%[(.*)%]') })
				elseif szName == 'questlink' then
					edit:InsertObj(szText, { type = 'quest', text = szText, questid = p:GetUserData() })
				elseif szName == 'recipelink' then
					edit:InsertObj(szText, { type = 'recipe', text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == 'enchantlink' then
					edit:InsertObj(szText, { type = 'enchant', text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == 'skilllink' then
					local o = clone(p.skillKey)
					o.type, o.text = 'skill', szText
					edit:InsertObj(szText, o)
				elseif szName =='skillrecipelink' then
					edit:InsertObj(szText, { type = 'skillrecipe', text = szText, id = p.dwID, level = p.dwLevelD })
				elseif szName =='booklink' then
					edit:InsertObj(szText, { type = 'book', text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
				elseif szName =='achievementlink' then
					edit:InsertObj(szText, { type = 'achievement', text = szText, id = p.dwID })
				elseif szName =='designationlink' then
					edit:InsertObj(szText, { type = 'designation', text = szText, id = p.dwID, prefix = p.bPrefix })
				elseif szName =='eventlink' then
					if szText and #szText > 0 then -- 过滤插件消息
						edit:InsertObj(szText, { type = 'eventlink', text = szText, name = p.szName, linkinfo = p.szLinkInfo })
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
					if szText ~= '' and (table.getn(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
						edit:InsertText(szText)
					end
				end
				if bEnd then
					break
				end
			elseif bTextEditor and bContent and (szName == 'timelink' or szName == 'copylink' or szName == 'msglink' or szName == 'time') then
				break
			end
		elseif p:GetType() == 'Image' or p:GetType() == 'Animate' then
			local dwID = tonumber((p:GetName():gsub('^emotion_', '')))
			if dwID then
				local emo = MY.GetChatEmotion(dwID)
				if emo then
					edit:InsertObj(emo.szCmd, { type = 'emotion', text = emo.szCmd, id = emo.dwID })
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end

do local ChatLinkEvents, PEEK_PLAYER = {}, {}
MY.RegisterEvent('PEEK_OTHER_PLAYER', function()
	if not PEEK_PLAYER[arg1] then
		return
	end
	if arg0 == PEEK_OTHER_PLAYER_RESPOND.INVALID then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Invalid player ID!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.FAILED then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Peek other player failed!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.CAN_NOT_FIND_PLAYER then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Can not find player to peek!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.TOO_FAR then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Player is too far to peek!'])
	end
	PEEK_PLAYER[arg1] = nil
end)
function ChatLinkEvents.OnNameLClick(element, link)
	if not link then
		link = element
	end
	if IsCtrlKeyDown() and IsAltKeyDown() then
		local menu = {}
		InsertInviteTeamMenu(menu, (MY.UI(link):text():gsub('[%[%]]', '')))
		menu[1].fnAction()
	elseif IsCtrlKeyDown() then
		MY.CopyChatItem(link)
	elseif IsShiftKeyDown() then
		MY.SetTarget(TARGET.PLAYER, MY.UI(link):text())
	elseif IsAltKeyDown() then
		if MY_Farbnamen and MY_Farbnamen.Get then
			local info = MY_Farbnamen.Get((MY.UI(link):text():gsub('[%[%]]', '')))
			if info then
				PEEK_PLAYER[info.dwID] = true
				ViewInviteToPlayer(info.dwID)
			end
		end
	else
		MY.SwitchChat(MY.UI(link):text())
		local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
		if edit then
			Station.SetFocusWindow(edit)
		end
	end
end
function ChatLinkEvents.OnNameRClick(element, link)
	if not link then
		link = element
	end
	PopupMenu(MY.GetTargetContextMenu(TARGET.PLAYER, (MY.UI(link):text():gsub('[%[%]]', ''))))
end
function ChatLinkEvents.OnCopyLClick(element, link)
	if not link then
		link = element
	end
	MY.CopyChatLine(link, IsCtrlKeyDown())
end
function ChatLinkEvents.OnCopyMClick(element, link)
	if not link then
		link = element
	end
	MY.RemoveChatLine(link)
end
function ChatLinkEvents.OnCopyRClick(element, link)
	if not link then
		link = element
	end
	MY.RepeatChatLine(link)
end
function ChatLinkEvents.OnCopyMouseEnter(element, link)
	if not link then
		link = element
	end
	local x, y = element:GetAbsPos()
	local w, h = element:GetSize()
	local szText = GetFormatText(_L['LClick to copy to editbox.\nMClick to remove this line.\nRClick to repeat this line.'], 136)
	OutputTip(szText, 450, {x, y, w, h}, MY_TIP_POSTYPE.TOP_BOTTOM)
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
		MY.CopyChatItem(link)
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

-- 绑定link事件响应
-- (userdata) MY.RenderChatLink(userdata link)                   处理link的各种事件绑定 namelink是一个超链接Text元素
-- (userdata) MY.RenderChatLink(userdata element, userdata link) 处理element的各种事件绑定 数据源是link
-- (string) MY.RenderChatLink(string szMsg)                      格式化szMsg 处理里面的超链接 添加时间相应
-- link   : 一个超链接Text元素
-- element: 一个可以挂鼠标消息响应的UI元素
-- szMsg  : 格式化的UIXML消息
function MY.RenderChatLink(arg1, arg2)
	if type(arg1) == 'string' then -- szMsg
		local szMsg = arg1
		local xmls = MY.Xml.Decode(szMsg)
		if xmls then
			for i, xml in ipairs(xmls) do
				if xml and xml['.'] == 'text' and xml[''] and xml[''].name then
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
end

-- 复制Item到输入框
function MY.CopyChatItem(p)
	local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
	if not edit then
		return
	end
	if p:GetType() == 'Text' then
		local szText, szName = p:GetText(), p:GetName()
		if szName == 'itemlink' then
			edit:InsertObj(szText, { type = 'item', text = szText, item = p:GetUserData() })
		elseif szName == 'iteminfolink' then
			edit:InsertObj(szText, { type = 'iteminfo', text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
		elseif string.sub(szName, 1, 8) == 'namelink' then
			edit:InsertObj(szText, { type = 'name', text = szText, name = string.match(szText, '%[(.*)%]') })
		elseif szName == 'questlink' then
			edit:InsertObj(szText, { type = 'quest', text = szText, questid = p:GetUserData() })
		elseif szName == 'recipelink' then
			edit:InsertObj(szText, { type = 'recipe', text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == 'enchantlink' then
			edit:InsertObj(szText, { type = 'enchant', text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == 'skilllink' then
			local o = clone(p.skillKey)
			o.type, o.text = 'skill', szText
			edit:InsertObj(szText, o)
		elseif szName =='skillrecipelink' then
			edit:InsertObj(szText, { type = 'skillrecipe', text = szText, id = p.dwID, level = p.dwLevelD })
		elseif szName =='booklink' then
			edit:InsertObj(szText, { type = 'book', text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
		elseif szName =='achievementlink' then
			edit:InsertObj(szText, { type = 'achievement', text = szText, id = p.dwID })
		elseif szName =='designationlink' then
			edit:InsertObj(szText, { type = 'designation', text = szText, id = p.dwID, prefix = p.bPrefix })
		elseif szName =='eventlink' then
			edit:InsertObj(szText, { type = 'eventlink', text = szText, name = p.szName, linkinfo = p.szLinkInfo })
		end
		Station.SetFocusWindow(edit)
	end
end

--解析消息
function MY.FormatChatContent(szMsg)
	local t = MY.Xml.Decode(szMsg)
	-- Output(t)
	local t2 = {}
	for _, node in ipairs(t) do
		local ntype = MY.Xml.GetNodeType(node)
		local ndata = MY.Xml.GetNodeData(node)
		-- 静态表情
		if ntype == 'image' then
			local emo = MY.GetChatEmotion(ndata.path, ndata.frame, 'image')
			if emo then
				table.insert(t2, {type = 'emotion', text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
			end
		-- 动态表情
		elseif ntype == 'animate' then
			local emo = MY.GetChatEmotion(ndata.path, ndata.group, 'animate')
			if emo then
				table.insert(t2, {type = 'emotion', text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
			end
		-- 文字内容
		elseif ntype == 'text' then
			local is_normaltext = false
			-- 普通文字
			if not ndata.name then
				is_normaltext = true
			-- 物品链接
			elseif ndata.name == 'itemlink' then
				table.insert(t2, {type = 'item', text = ndata.text, innerText = ndata.text:sub(2, -2), item = ndata.userdata})
			-- 物品信息
			elseif ndata.name == 'iteminfolink' then
				local version, tab, index = string.match(ndata.script, 'this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)')
				table.insert(t2, {type = 'iteminfo', text = ndata.text, innerText = ndata.text:sub(2, -2), version = version, tabtype = tab, index = index})
			-- 姓名
			elseif ndata.name:sub(1, 9) == 'namelink_' then
				table.insert(t2, {type = 'name', text = ndata.text, innerText = ndata.text, name = ndata.text:sub(2, -2)})
			-- 任务
			elseif ndata.name == 'questlink' then
				table.insert(t2, {type = 'quest', text = ndata.text, innerText = ndata.text:sub(2, -2), questid = ndata.userdata})
			-- 生活技艺
			elseif ndata.name == 'recipelink' then
				local craft, recipe = string.match(ndata.script, 'this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)')
				table.insert(t2, {type = 'recipe', text = ndata.text, innerText = ndata.text:sub(2, -2), craftid = craft, recipeid = recipe})
			-- 技能
			elseif ndata.name == 'skilllink' then
				local skillinfo = string.match(ndata.script, 'this.skillKey=%{(.-)%}')
				local skillKey = {}
				for w in string.gfind(skillinfo, '(.-)%,') do
					local k, v  = string.match(w, '(.-)=(%w+)')
					skillKey[k] = v
				end
				skillKey.text = ndata.text
				skillKey.innerText = ndata.text:sub(2, -2)
				table.insert(t2, skillKey)
			-- 称号
			elseif ndata.name == 'designationlink' then
				local id, fix = string.match(ndata.script, 'this.dwID=(%d+)%s*this.bPrefix=(.-)')
				table.insert(t2, {type = 'designation', text = ndata.text, innerText = ndata.text:sub(2, -2), id = id, prefix = fix})
			-- 技能秘籍
			elseif ndata.name == 'skillrecipelink' then
				local id, level = string.match(ndata.script, 'this.dwID=(%d+)%s*this.dwLevel=(%d+)')
				table.insert(t2, {type = 'skillrecipe', text = ndata.text, innerText = ndata.text:sub(2, -2), id = id, level = level})
			-- 书籍
			elseif ndata.name == 'booklink' then
				local version, tab, index, id = string.match(ndata.script, 'this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)%s*this.nBookRecipeID=(%d+)')
				table.insert(t2, {type = 'book', text = ndata.text, innerText = ndata.text:sub(2, -2), version = version, tabtype = tab, index = index, bookinfo = id})
			-- 成就
			elseif ndata.name == 'achievementlink' then
				local id = string.match(ndata.script, 'this.dwID=(%d+)')
				table.insert(t2, {type = 'achievement', text = ndata.text, innerText = ndata.text:sub(2, -2), id = id})
			-- 强化
			elseif ndata.name == 'enchantlink' then
				local pro, craft, recipe = string.match(ndata.script, 'this.dwProID=(%d+)%s*this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)')
				table.insert(t2, {type = 'enchant', text = ndata.text, innerText = ndata.text:sub(2, -2), proid = pro, craftid = craft, recipeid = recipe})
			-- 事件
			elseif ndata.name == 'eventlink' then
				local eventname, linkinfo = string.match(ndata.script, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"$')
				if not eventname then
					eventname, linkinfo = string.match(ndata.script, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"')
				end
				table.insert(t2, {type = 'eventlink', text = ndata.text, innerText = ndata.text:sub(2, -2), name = eventname, linkinfo = linkinfo:gsub('\\(.)', '%1')})
			-- 未知类型的字符串
			elseif ndata.text then
				is_normaltext = true
			end
			if is_normaltext then
				table.insert(t2, {type = 'text', text = ndata.text, innerText = ndata.text})
			end
		end
	end
	return t2
end

-- 字符串化一个聊天table结构体
function MY.StringfyChatContent(t)
	local t1 = {}
	for _, v in ipairs(t) do
		table.insert(t1, v.text)
	end
	return table.concat(t1)
end

-- 判断某个频道能否发言
-- (bool) MY.CanTalk(number nChannel)
function MY.CanTalk(nChannel)
	for _, v in ipairs({'WHISPER', 'TEAM', 'RAID', 'BATTLE_FIELD', 'NEARBY', 'TONG', 'TONG_ALLIANCE' }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end

do
-- get channel header
local TALK_CHANNEL_HEADER = {
	[PLAYER_TALK_CHANNEL.NEARBY] = '/s ',
	[PLAYER_TALK_CHANNEL.FRIENDS] = '/o ',
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = '/a ',
	[PLAYER_TALK_CHANNEL.TEAM] = '/p ',
	[PLAYER_TALK_CHANNEL.RAID] = '/t ',
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = '/b ',
	[PLAYER_TALK_CHANNEL.TONG] = '/g ',
	[PLAYER_TALK_CHANNEL.SENCE] = '/y ',
	[PLAYER_TALK_CHANNEL.FORCE] = '/f ',
	[PLAYER_TALK_CHANNEL.CAMP] = '/c ',
	[PLAYER_TALK_CHANNEL.WORLD] = '/h ',
}
-- 切换聊天频道
-- (void) MY.SwitchChat(number nChannel)
-- (void) MY.SwitchChat(string szHeader)
-- (void) MY.SwitchChat(string szName)
function MY.SwitchChat(nChannel)
	local szHeader = TALK_CHANNEL_HEADER[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		Station.Lookup('Lowest2/EditBox'):Show()
		Station.Lookup('Lowest2/EditBox/Edit_Input'):SetText('/w ')
		Station.SetFocusWindow('Lowest2/EditBox/Edit_Input')
	elseif type(nChannel) == 'string' then
		if string.sub(nChannel, 1, 1) == '/' then
			if nChannel == '/cafk' or nChannel == '/catr' then
				SwitchChatChannel(nChannel)
				MY.Talk(nil, nChannel, nil, nil, nil, true)
				Station.Lookup('Lowest2/EditBox'):Show()
			else
				SwitchChatChannel(nChannel..' ')
			end
		else
			SwitchChatChannel('/w ' .. string.gsub(nChannel,'[%[%]]','') .. ' ')
		end
	end
end
end

-- 将焦点设置到聊天栏
function MY.FocusChatBox()
	Station.SetFocusWindow('Lowest2/EditBox/Edit_Input')
end

do
-- 聊天表情初始化
local MAX_EMOTION_LEN, EMOTION_CACHE = 0
local function InitEmotion()
	if not EMOTION_CACHE then
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
			MAX_EMOTION_LEN = math.max(MAX_EMOTION_LEN, wstring.len(t1.szCmd))
		end
		EMOTION_CACHE = t
	end
end

-- 获取聊天表情列表
-- typedef emo table
-- (emo[]) MY.GetChatEmotion()                             -- 返回所有表情列表
-- (emo)   MY.GetChatEmotion(szCommand)                    -- 返回指定Cmd的表情
-- (emo)   MY.GetChatEmotion(szImageFile, nFrame, szType)  -- 返回指定图标的表情
function MY.GetChatEmotion(arg0, arg1, arg2)
	InitEmotion()
	local t
	if not arg0 then
		t = EMOTION_CACHE
	elseif not arg1 then
		t = EMOTION_CACHE[arg0]
	elseif arg2 then
		arg0 = string.gsub(arg0, '\\\\', '\\')
		t = EMOTION_CACHE[arg0..','..arg1..','..arg2]
	end
	return clone(t)
end

-- parse faceicon in talking message
local function ParseFaceIcon(t)
	InitEmotion()
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= 'text' then
			if v.type == 'emotion' then
				v.type = 'text'
			end
			table.insert(t2, v)
		else
			local szText = v.text
			local szLeft = ''
			while szText and #szText > 0 do
				local szFace, dwFaceID = nil, nil
				local nPos = StringFindW(szText, '#')
				if not nPos then
					szLeft = szLeft .. szText
					szText = ''
				else
					szLeft = szLeft .. string.sub(szText, 1, nPos - 1)
					szText = string.sub(szText, nPos)
					for i = math.min(MAX_EMOTION_LEN, wstring.len(szText)), 2, -1 do
						local szTest = wstring.sub(szText, 1, i)
						local emo = MY.GetChatEmotion(szTest)
						if emo then
							szFace, dwFaceID = szTest, emo.dwID
							szText = szText:sub(szFace:len() + 1)
							break
						end
					end
					if szFace then -- emotion cmd matched
						if #szLeft > 0 then
							table.insert(t2, { type = 'text', text = szLeft })
							szLeft = ''
						end
						table.insert(t2, { type = 'emotion', text = szFace, id = dwFaceID })
					elseif nPos then -- find '#' but not match emotion
						szLeft = szLeft .. szText:sub(1, 1)
						szText = szText:sub(2)
					end
				end
			end
			if #szLeft > 0 then
				table.insert(t2, { type = 'text', text = szLeft })
				szLeft = ''
			end
		end
	end
	return t2
end
-- parse name in talking message
local function ParseName(t)
	local me = GetClientPlayer()
	local tar = MY.GetObject(me.GetTarget())
	for i, v in ipairs(t) do
		if v.type == 'text' then
			v.text = string.gsub(v.text, '%$zj', '[' .. me.szName .. ']')
			if tar then
				v.text = string.gsub(v.text, '%$mb', '[' .. tar.szName .. ']')
			end
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= 'text' then
			if v.type == 'name' then
				v = { type = 'text', text = '['..v.name..']' }
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
					table.insert(t2, { type = 'text', text = string.sub(v.text, nOff, nPos1) })
					nOff = nPos1 + 1
				end
				if szName then
					table.insert(t2, { type = 'name', text = '[' .. szName .. ']', name = szName })
					nOff = nPos2 + 1
				end
			end
		end
	end
	return t2
end
local SENSITIVE_WORD = {
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
local function ParseAntiSWS(t)
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type == 'text' then
			local szText = v.text
			while szText and #szText > 0 do
				local nSensitiveWordEndLen = 1 -- 最后一个字符（要裁剪掉的字符）大小
				local nSensitiveWordEndPos = #szText + 1
				for _, szSensitiveWord in ipairs(SENSITIVE_WORD) do
					local _, nEndPos = wstring.find(szText, szSensitiveWord)
					if nEndPos and nEndPos < nSensitiveWordEndPos then
						local nSensitiveWordLenW = wstring.len(szSensitiveWord)
						nSensitiveWordEndLen = string.len(wstring.sub(szSensitiveWord, nSensitiveWordLenW, nSensitiveWordLenW))
						nSensitiveWordEndPos = nEndPos
					end
				end

				table.insert(t2, {
					type = 'text',
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

-- 发布聊天内容
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape, [boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape[boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- szTarget       -- 密聊的目标角色名
-- szText         -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- nChannel       -- *可选* 聊天频道，PLAYER_TALK_CHANNLE.*，默认为近聊
-- bNoEscape      -- *可选* 不解析聊天内容中的表情图片和名字，默认为 false
-- bSaveDeny      -- *可选* 在聊天输入栏保留不可发言的频道内容，默认为 false
-- bPushToChatBox -- *可选* 仅推送到聊天框，默认为 false
-- 特别注意：nChannel, szText 两者的参数顺序可以调换，战场/团队聊天频道智能切换
function MY.Talk(nChannel, szText, szUUID, bNoEscape, bSaveDeny, bPushToChatBox)
	local szTarget, me = '', GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == 'string' then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == 'number' then
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
	if type(szText) == 'table' then
		tSay = szText
	else
		tSay = {{ type = 'text', text = szText}}
	end
	if not bNoEscape then
		tSay = ParseFaceIcon(tSay)
		tSay = ParseName(tSay)
	end
	tSay = ParseAntiSWS(tSay)
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
		local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
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
		or tSay[1].name ~= ''
		or tSay[1].type ~= 'eventlink' then
			table.insert(tSay, 1, {
				type = 'eventlink', name = '',
				linkinfo = MY.JsonEncode({
					via = 'MY',
					uuid = szUUID and tostring(szUUID),
				})
			})
		end
		me.Talk(nChannel, szTarget, tSay)
	end
end
end

do
local SPACE = ' '
local W_SPACE = g_tStrings.STR_ONE_CHINESE_SPACE
local metaAlignment = { __index = function() return 'L' end }
local function MergeHW(s)
	return s:gsub(W_SPACE, 'W'):gsub(' (W*) ', W_SPACE .. '%1'):gsub('W', W_SPACE)
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
			if aAlignment[j] == 'M' then
				aTalk[j] = szFixL .. szText .. szFixR
			elseif aAlignment[j] == 'R' then
				aTalk[j] = MergeHW(szFixL .. szFixR) .. szText
			else
				aTalk[j] = szText .. MergeHW(szFixL .. szFixR)
			end
		end
		-- MY.Sysmsg({(concat(aTalk, '|'))})
		MY.Talk(nChannel, (concat(aTalk, ' ')))
	end
end
end

do
local m_LevelUpData
local function GetRegisterChannelLimitTable()
	if not m_LevelUpData then
		local me = GetClientPlayer()
		if not me then
			return false
		end
		local path = ('settings\\LevelUpData\\%s.tab'):format(({
			[ROLE_TYPE.STANDARD_MALE  ] = 'StandardMale'  ,
			[ROLE_TYPE.STANDARD_FEMALE] = 'StandardFemale',
			[ROLE_TYPE.STRONG_MALE    ] = 'StrongMale'    ,
			[ROLE_TYPE.SEXY_FEMALE    ] = 'SexyFemale'    ,
			[ROLE_TYPE.LITTLE_BOY     ] = 'LittleBoy'     ,
			[ROLE_TYPE.LITTLE_GIRL    ] = 'LittleGirl'    ,
		})[me.nRoleType])
		local tTitle = {
			{f = 'i', t = 'Level'},
			{f = 'i', t = 'Experience'},
			{f = 'i', t = 'Strength'},
			{f = 'i', t = 'Agility'},
			{f = 'i', t = 'Vigor'},
			{f = 'i', t = 'Spirit'},
			{f = 'i', t = 'Spunk'},
			{f = 'i', t = 'MaxLife'},
			{f = 'i', t = 'MaxMana'},
			{f = 'i', t = 'MaxStamina'},
			{f = 'i', t = 'MaxThew'},
			{f = 'i', t = 'MaxAssistExp'},
			{f = 'i', t = 'MaxAssistTimes'},
			{f = 'i', t = 'RunSpeed'},
			{f = 'i', t = 'JumpSpeed'},
			{f = 'i', t = 'Height'},
			{f = 'i', t = 'LifeReplenish'},
			{f = 'i', t = 'LifeReplenishPercent'},
			{f = 'i', t = 'LifeReplenishExt'},
			{f = 'i', t = 'ManaReplenish'},
			{f = 'i', t = 'ManaReplenishPercent'},
			{f = 'i', t = 'ManaReplenishExt'},
			{f = 'i', t = 'HitBase'},
			{f = 'i', t = 'ParryBaseRate'},
			{f = 'i', t = 'PhysicsCriticalStrike'},
			{f = 'i', t = 'SolarCriticalStrike'},
			{f = 'i', t = 'NeutralCriticalStrike'},
			{f = 'i', t = 'LunarCriticalStrike'},
			{f = 'i', t = 'PoisonCriticalStrike'},
			{f = 'i', t = 'NoneWeaponAttackSpeedBase'},
			{f = 'i', t = 'MaxPhysicsDefence'},
			{f = 'i', t = 'WorldChannelDailyLimit'},
			{f = 'i', t = 'ForceChannelDailyLimit'},
			{f = 'i', t = 'CampChannelDailyLimit'},
			{f = 'i', t = 'MaxContribution'},
			{f = 'i', t = 'WhisperDailyLimit'},
			{f = 'i', t = 'IdentityChannelDailyLimit'},
			{f = 'i', t = 'SprintPowerMax'},
			{f = 'i', t = 'SprintPowerCost'},
			{f = 'i', t = 'SprintPowerRevive'},
			{f = 'i', t = 'SprintPowerCostOnWall'},
			{f = 'i', t = 'SprintPowerCostStandOnWall'},
			{f = 'i', t = 'SprintPowerCostRunOnWallExtra'},
			{f = 'i', t = 'HorseSprintPowerMax'},
			{f = 'i', t = 'HorseSprintPowerCost'},
			{f = 'i', t = 'HorseSprintPowerRevive'},
			{f = 'i', t = 'SceneChannelDailyLimit'},
			{f = 'i', t = 'NearbyChannelDailyLimit'},
			{f = 'i', t = 'WorldChannelDailyLimitByVIP'},
			{f = 'i', t = 'WorldChannelDailyLimitBySuperVIP'},
		}
		m_LevelUpData = KG_Table.Load(path, tTitle, FILE_OPEN_MODE.NORMAL)
	end
	return m_LevelUpData
end
local DAILY_LIMIT_TABLE_KEY = {
	[PLAYER_TALK_CHANNEL.WORLD  ] = 'WorldChannelDailyLimit',
	[PLAYER_TALK_CHANNEL.FORCE  ] = 'ForceChannelDailyLimit',
	[PLAYER_TALK_CHANNEL.CAMP   ] = 'CampChannelDailyLimit',
	[PLAYER_TALK_CHANNEL.SENCE  ] = 'SceneChannelDailyLimit',
	[PLAYER_TALK_CHANNEL.NEARBY ] = 'NearbyChannelDailyLimit',
	[PLAYER_TALK_CHANNEL.WHISPER] = 'WhisperDailyLimit',
}
function MY.GetChannelDailyLimit(nLevel, nChannel)
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
end

-- Register:   MY.RegisterMsgMonitor(string szKey, function fnAction, table tChannels)
--             MY.RegisterMsgMonitor(function fnAction, table tChannels)
-- Unregister: MY.RegisterMsgMonitor(string szKey)
do local MSG_MONITOR_FUNC = {}
function MY.RegisterMsgMonitor(arg0, arg1, arg2)
	local szKey, fnAction, tChannels
	local tp0, tp1, tp2 = type(arg0), type(arg1), type(arg2)
	if tp0 == 'string' and tp1 == 'function' and tp2 == 'table' then
		szKey, fnAction, tChannels = arg0, arg1, arg2
	elseif tp0 == 'function' and tp1 == 'table' then
		fnAction, tChannels = arg0, arg1
	elseif tp0 == 'string' and not arg1 then
		szKey = arg0
	end

	if szKey and MSG_MONITOR_FUNC[szKey] then
		UnRegisterMsgMonitor(MSG_MONITOR_FUNC[szKey].fn)
		MSG_MONITOR_FUNC[szKey] = nil
	end
	if fnAction and tChannels then
		MSG_MONITOR_FUNC[szKey] = { fn = function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
			-- filter addon comm.
			if StringFindW(szMsg, 'eventlink') and StringFindW(szMsg, _L['Addon comm.']) then
				return
			end
			fnAction(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
		end, ch = tChannels }
		RegisterMsgMonitor(MSG_MONITOR_FUNC[szKey].fn, MSG_MONITOR_FUNC[szKey].ch)
	end
end
end

do
local CHAT_HOOK = {}
-- HOOK聊天栏
-- 注：如果fnOnActive存在则没有激活的聊天栏不会执行fnBefore、fnAfter
--     同时在聊天栏切换时会触发fnOnActive
function MY.HookChatPanel(szKey, fnBefore, fnAfter, fnOnActive)
	if type(szKey) == 'function' then
		szKey, fnBefore, fnAfter, fnOnActive = GetTickCount(), szKey, fnBefore, fnAfter
		while CHAT_HOOK[szKey] do
			szKey = szKey + 0.1
		end
	end
	if fnBefore or fnAfter or fnOnActive then
		CHAT_HOOK[szKey] = {
			fnBefore = fnBefore, fnAfter = fnAfter, fnOnActive = fnOnActive
		}
	else
		CHAT_HOOK[szKey] = nil
	end
end

local function OnChatPanelActive(h)
	for szKey, hc in pairs(CHAT_HOOK) do
		if type(hc.fnOnActive) == 'function' then
			local status, err = pcall(hc.fnOnActive, h)
			if not status then
				MY.Debug({err}, 'HookChatPanelOnActive#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

local function OnChatPanelNamelinkLButtonDown(...)
	this.__MY_OnItemLButtonDown(...)
	MY.ChatLinkEventHandlers.OnNameLClick(...)
end

local function OnChatPanelAppendItemFromString(h, szMsg, szChannel, dwTime, nR, nG, nB, ...)
	local bActived = h:GetRoot():Lookup('CheckBox_Title'):IsCheckBoxChecked()
	-- deal with fnBefore
	for szKey, hc in pairs(CHAT_HOOK) do
		hc.param = EMPTY_TABLE
		-- if fnBefore exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnBefore) == 'function' and (bActived or not hc.fnOnActive) then
			-- try to execute fnBefore and get return values
			local status, msg, ret = pcall(hc.fnBefore, h, szChannel, szMsg, dwTime, nR, nG, nB, ...)
			-- when fnBefore execute succeed
			if status then
				-- set msg if returned string
				if type(msg) == 'string' then
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
		if hItem:GetName():find('^namelink_%d+$') then
			hItem.bMyChatRendered = true
			if hItem.OnItemLButtonDown then
				hItem.__MY_OnItemLButtonDown = hItem.OnItemLButtonDown
				hItem.OnItemLButtonDown = OnChatPanelNamelinkLButtonDown
			else
				hItem.OnItemLButtonDown = MY.ChatLinkEventHandlers.OnNameLClick
			end
		end
	end
	-- deal with fnAfter
	for szKey, hc in pairs(CHAT_HOOK) do
		-- if fnAfter exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnAfter) == 'function' and (bActived or not hc.fnOnActive) then
			local status, err = pcall(hc.fnAfter, h, hc.param, szChannel, szMsg, dwTime, nR, nG, nB, ...)
			if not status then
				MY.Debug({err}, 'HookChatPanel.After#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

local function Hook(i)
	local h = Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
	-- local ttl = Station.Lookup('Lowest2/ChatPanel' .. i .. '/CheckBox_Title', 'Text_TitleName')
	-- if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
	if h and not h._AppendItemFromString_MY then
		h:GetRoot():Lookup('CheckBox_Title').OnCheckBoxCheck = function()
			OnChatPanelActive(h)
		end
		h._AppendItemFromString_MY = h.AppendItemFromString
		h.AppendItemFromString = OnChatPanelAppendItemFromString
	end
end

local function Unhook(i)
	local h = Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
	if h and h._AppendItemFromString_MY then
		h.AppendItemFromString = h._AppendItemFromString_MY
		h._AppendItemFromString_MY = nil
	end
end

local function HookAll()
	for i = 1, 10 do
		Hook(i)
	end
end
MY.RegisterEvent('CHAT_PANEL_INIT.ChatPanelHook', HookAll)
MY.RegisterEvent('CHAT_PANEL_OPEN.ChatPanelHook', function(event) Hook(arg0) end)
MY.RegisterEvent('RELOAD_UI_ADDON_END.ChatPanelHook', HookAll)

local function UnhookAll()
	for i = 1, 10 do
		Unhook(i)
	end
end
MY.RegisterExit('ChatPanelHook', UnhookAll)
MY.RegisterReload('ChatPanelHook', UnhookAll)
end
