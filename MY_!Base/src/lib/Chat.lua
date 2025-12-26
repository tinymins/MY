--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 聊天相关模块
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Chat')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local RENDERED_FLAG_KEY = X.NSFormatString('b{$NS}ChatRendered')

-- 获取聊天输入框
-- (WndEdit?) X.GetChatInput()
function X.GetChatInput()
	local frame = Station.SearchFrame('EditBox')
	return frame and frame:Lookup('Edit_Input')
end

function X.GetChatPanel(k)
	return Station.SearchFrame('ChatPanel' .. k)
		or Station.SearchFrame('ChatPanel_Normal' .. k)
end

-- 聊天复制并发布
function X.RepeatChatLine(hTime)
	local edit = X.GetChatInput()
	if not edit then
		return
	end
	X.CopyChatLine(hTime)
	local tMsg = edit:GetTextStruct()
	if #tMsg == 0 then
		return
	end
	local nChannel, szName = EditBox_GetChannel()
	if X.CanUseChatChannel(nChannel) then
		X.GetClientPlayer().Talk(nChannel, szName or '', tMsg)
		edit:ClearText()
	end
end

-- 聊天删除行
function X.RemoveChatLine(hTime)
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

local function GetCopyLinkScript(opt)
	local handlerEntry = X.NSFormatString('{$NS}.ChatLinkEventHandlers')
	local szScript = X.NSFormatString('this[\'b{$NS}ChatRendered\']=true;this.OnItemMouseEnter=')
		.. handlerEntry .. '.OnCopyMouseEnter;this.OnItemMouseLeave=' .. handlerEntry .. '.OnCopyMouseLeave;'
	if opt.lclick ~= false then
		szScript = szScript .. 'this.bLButton=true;this.OnItemLButtonDown='.. handlerEntry .. '.OnCopyLClick;'
		if opt.richtext and not X.ContainsEchoMsgHeader(opt.richtext) then
			local RichTexts = X.ChatLinkEventHandlers.RichTexts
			if RichTexts[RichTexts.nIndex] then
				RichTexts[RichTexts[RichTexts.nIndex]] = nil
			end
			local szRichTextUUID = X.GetUUID()
			RichTexts[RichTexts.nIndex] = szRichTextUUID
			RichTexts[szRichTextUUID] = opt.richtext or ''
			RichTexts.nIndex = RichTexts.nIndex + 1
			if RichTexts.nIndex > 800 then
				RichTexts.nIndex = 1
			end
			szScript = szScript .. 'this.szRichText=' .. handlerEntry .. '.RichTexts["' .. szRichTextUUID .. '"] or ""' .. ';'
		end
	end
	if opt.mclick then
		szScript = szScript .. 'this.bMButton=true;this.OnItemMButtonDown='.. handlerEntry .. '.OnCopyMClick;'
	end
	if opt.rclick ~= false then
		szScript = szScript .. 'this.bRButton=true;this.OnItemRButtonDown='.. handlerEntry .. '.OnCopyRClick;'
	end
	return szScript
end

-- 获取复制聊天行字符串
-- (string) X.GetChatCopyXML(szText: string, opt?: table)
function X.GetChatCopyXML(szText, opt)
	if not X.IsString(szText) then
		szText = _L[' * ']
	end
	if not X.IsTable(opt) then
		opt = { f = 10 }
	end
	return GetFormatText(szText, opt.f, opt.r, opt.g, opt.b, 82691, GetCopyLinkScript(opt), 'copylink')
end

-- 获取复制聊天行时间串
-- (string) X.GetChatTimeXML(szText: string, opt?: table)
function X.GetChatTimeXML(dwTime, opt)
	if not X.IsTable(opt) then
		opt = { f = 10 }
	end
	local szText = X.FormatTime(dwTime, opt.s or '[%hh:%mm:%ss]')
	return GetFormatText(szText, opt.f, opt.r, opt.g, opt.b, 82691, GetCopyLinkScript(opt), 'timelink')
end

-- 将焦点设置到聊天栏
-- (void) X.FocusChatInput()
function X.FocusChatInput()
	local edit = X.GetChatInput()
	if edit then
		Station.SetFocusWindow(edit)
	end
end

-- 清空聊天栏
-- (void) X.ClearChatInput()
function X.ClearChatInput()
	local edit = X.GetChatInput()
	if not edit then
		return
	end
	edit:ClearText()
end

-- X.InsertChatInput(szType, ...data)
function X.InsertChatInput(szType, ...)
	local edit = X.GetChatInput()
	if not edit then
		return
	end
	local szText, data
	if szType == 'achievement' then
		local dwAchieve = ...
		local achi = X.GetAchievement(dwAchieve)
		if not achi then
			return
		end
		szText = '[' .. achi.szName .. ']'
		data = {
			type = 'achievement',
			text = szText,
			id = achi.dwID,
		}
	elseif szType == 'iteminfo' then
		local dwTabType, dwIndex, nBookInfo, nVersion = ...
		local itemInfo = GetItemInfo(dwTabType, dwIndex)
		if itemInfo then
			if not nVersion then
				nVersion = X.ENVIRONMENT.CURRENT_ITEM_VERSION
			end
			if itemInfo.nGenre == ITEM_GENRE.BOOK then
				if nBookInfo then
					local nBookID, nSegmentID = X.RecipeToSegmentID(nBookInfo)
					if nBookID then
						szText = '[' .. Table_GetSegmentName(nBookID, nSegmentID) .. ']'
						data = {
							type = 'book',
							text = szText,
							version = nVersion,
							tabtype = dwTabType,
							index = dwIndex,
							bookinfo = nBookInfo,
						}
					end
				end
			else
				szText = '[' .. X.GetItemNameByItemInfo(itemInfo) .. ']'
				data = {
					type = 'iteminfo',
					text = szText,
					version = nVersion,
					tabtype = dwTabType,
					index = dwIndex,
				}
			end
		end
	end
	if not szText or not data then
		return false
	end
	edit:GetRoot():Show()
	edit:InsertObj(szText, data)
	return true
end

-- 复制聊天行
function X.CopyChatLine(hTime, bTextEditor, bRichText)
	local edit = X.GetChatInput()
	if bTextEditor then
		edit = X.UI.OpenTextEditor():Find('.WndEdit')[1]
	end
	if not edit then
		return
	end
	edit:GetRoot():Show()
	edit:ClearText()
	if bRichText then
		edit:InsertText(hTime.szRichText)
	else
		local h, i, bBegin, bContent = hTime:GetParent(), hTime:GetIndex(), nil, false
		-- loop
		for i = i + 1, h:GetItemCount() - 1 do
			local p = h:Lookup(i)
			if p:GetType() == 'Text' then
				local szName = p:GetName()
				if szName ~= 'timelink' and szName ~= 'copylink' and szName ~= 'msglink' and szName ~= 'time' then
					local szText, bEnd = p:GetText(), false
					if not bTextEditor and X.StringFindW(szText, '\n') then
						szText = X.StringReplaceW(szText, '\n', '')
						bEnd = true
					end
					bContent = true
					if szName == 'itemlink' then
						edit:InsertObj(szText, { type = 'item', text = szText, item = p:GetUserData() })
					elseif szName == 'iteminfolink' then
						edit:InsertObj(szText, { type = 'iteminfo', text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
					elseif szName == 'namelink' or string.sub(szName, 1, 9) == 'namelink_' then
						if bBegin == nil then
							bBegin = false
						end
						local szName = string.match(szText, '%[(.*)%]')
						-- 过滤换行符
						if X.IsRestricted('X.CHAT_CRLF') then
							szName = X.StringReplaceW(szName, '\n', '')
							szText = X.StringReplaceW(szText, '\n', '')
						end
						edit:InsertObj(szText, { type = 'name', text = szText, name = szName })
					elseif szName == 'questlink' then
						edit:InsertObj(szText, { type = 'quest', text = szText, questid = p:GetUserData() })
					elseif szName == 'recipelink' then
						edit:InsertObj(szText, { type = 'recipe', text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
					elseif szName == 'enchantlink' then
						edit:InsertObj(szText, { type = 'enchant', text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
					elseif szName == 'skilllink' then
						local o = X.Clone(p.skillKey)
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
							local szName = p.szName
							-- 过滤换行符
							if X.IsRestricted('X.CHAT_CRLF') then
								szName = X.StringReplaceW(szName, '\n', '')
							end
							edit:InsertObj(szText, { type = 'eventlink', name = szName, linkinfo = p.szLinkInfo })
						end
					else
						if bBegin == false then
							for _, v in ipairs({g_tStrings.STR_TALK_HEAD_WHISPER, g_tStrings.STR_TALK_HEAD_SAY, g_tStrings.STR_TALK_HEAD_SAY1, g_tStrings.STR_TALK_HEAD_SAY2 }) do
								local nB, nE = X.StringFindW(szText, v)
								if nB then
									szText, bBegin = string.sub(szText, nB + nE), true
									edit:ClearText()
								end
							end
						end
						if szText ~= '' and (X.Len(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
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
					local emo = X.GetChatEmotion(dwID)
					if emo then
						edit:InsertObj(emo.szCmd, { type = 'emotion', text = emo.szCmd, id = emo.dwID })
					end
				else
					local szImg, nFrame = p:GetImagePath()
					if X.IsString(szImg) then
						szImg = X.StringLowerW(X.NormalizePath(szImg))
					end
					if szImg == 'ui\\image\\common\\money.uitex' and nFrame == 0 then
						edit:InsertText(_L['Gold'])
					elseif szImg == 'ui\\image\\common\\money.uitex' and nFrame == 2 then
						edit:InsertText(_L['Silver'])
					elseif szImg == 'ui\\image\\common\\money.uitex' and nFrame == 1 then
						edit:InsertText(_L['Copper'])
					elseif szImg == 'ui\\image\\common\\money.uitex' and (nFrame == 31 or nFrame == 32 or nFrame == 33 or nFrame == 34) then
						edit:InsertText(_L['Brics'])
					end
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end

-- 聊天界面元素通用事件绑定函数
local ChatLinkEvents = {
	OnNameLClick = function(element, link)
		if not link then
			link = element
		end
		if IsCtrlKeyDown() and IsAltKeyDown() then
			local menu = {}
			InsertInviteTeamMenu(menu, (X.UI(link):Text():gsub('[%[%]]', '')))
			menu[1].fnAction()
		elseif IsCtrlKeyDown() then
			X.CopyChatItem(link)
		elseif IsShiftKeyDown() then
			local dwID
			local szName = X.UI(link):Text():gsub('[%[%]]', '')
			for _, p in ipairs(X.GetNearPlayer()) do
				if szName == p.szName then
					dwID = p.dwID
					break
				end
			end
			if dwID then
				X.SetClientPlayerTarget(TARGET.PLAYER, dwID)
			end
		elseif IsAltKeyDown() then
			if _G.MY_Farbnamen and _G.MY_Farbnamen.Get then
				local info = _G.MY_Farbnamen.Get((X.UI(link):Text():gsub('[%[%]]', '')))
				if info then
					local dwServerID = info.szServerName and X.GetServerIDByName(info.szServerName)
					local function OnPeekOtherPlayerResult(xKey, eState)
						if eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.INVALID then
							OutputMessage('MSG_ANNOUNCE_RED', _L['Invalid player ID!'])
						elseif eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED then
							OutputMessage('MSG_ANNOUNCE_RED', _L['Peek other player failed!'])
						elseif eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.CAN_NOT_FIND_PLAYER then
							OutputMessage('MSG_ANNOUNCE_RED', _L['Can not find player to peek!'])
						elseif eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.TOO_FAR then
							OutputMessage('MSG_ANNOUNCE_RED', _L['Player is too far to peek!'])
						end
					end
					if info.szServerName == X.GetServerOriginName() and info.dwID then
						X.ViewOtherPlayerByID(info.dwID, OnPeekOtherPlayerResult)
					elseif info.szGlobalID and dwServerID then
						X.ViewOtherPlayerByGlobalID(dwServerID, info.szGlobalID, OnPeekOtherPlayerResult)
					end
				end
			end
		else
			X.SwitchChatChannel(X.UI(link):Text())
			local edit = X.GetChatInput()
			if edit then
				Station.SetFocusWindow(edit)
			end
		end
	end,
	OnNameRClick = function(element, link)
		if not link then
			link = element
		end
		PopupMenu(X.InsertPlayerContextMenu({}, (X.UI(link):Text():gsub('[%[%]]', ''))))
	end,
	OnCopyLClick = function(element, link)
		if not link then
			link = element
		end
		X.CopyChatLine(link, IsCtrlKeyDown(), IsCtrlKeyDown() and IsShiftKeyDown())
	end,
	OnCopyMClick = function(element, link)
		if not link then
			link = element
		end
		X.RemoveChatLine(link)
	end,
	OnCopyRClick = function(element, link)
		if not link then
			link = element
		end
		X.RepeatChatLine(link)
	end,
	OnCopyMouseEnter = function(el, link)
		if not link then
			link = el
		end
		local x, y = el:GetAbsPos()
		local w, h = el:GetSize()
		local s = ''
		if el.bLButton then
			s = s .. _L['LClick to copy to editbox.\n']
		end
		if el.bMButton then
			s = s .. _L['MClick to remove this line.\n']
		end
		if el.bRButton then
			s = s .. _L['RClick to repeat this line.\n']
		end
		local szText = GetFormatText(s:sub(1, -2), 136)
		OutputTip(szText, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
	end,
	OnCopyMouseLeave = function(element, link)
		if not link then
			link = element
		end
		HideTip()
	end,
	OnItemLClick = function(element, link)
		if not link then
			link = element
		end
		OnItemLinkDown(link)
	end,
	OnItemRClick = function(element, link)
		if not link then
			link = element
		end
		if IsCtrlKeyDown() then
			X.CopyChatItem(link)
		end
	end,
}
X.ChatLinkEvents = X.FreezeTable(ChatLinkEvents)

-- 聊天界面元素通用事件绑定函数（this）
X.ChatLinkEventHandlers = {
	RichTexts = {
		nIndex = 1,
	},
}
for k, f in pairs(ChatLinkEvents) do
	X.ChatLinkEventHandlers[k] = function()
		f(this)
	end
end
X.NSLock(X.ChatLinkEventHandlers)

-- 绑定link事件响应
-- (userdata) X.RenderChatLink(userdata link)                   处理link的各种事件绑定 namelink是一个超链接Text元素
-- (userdata) X.RenderChatLink(userdata element, userdata link) 处理element的各种事件绑定 数据源是link
-- (string) X.RenderChatLink(string szMsg)                      格式化szMsg 处理里面的超链接 添加时间相应
-- link   : 一个超链接Text元素
-- element: 一个可以挂鼠标消息响应的UI元素
-- szMsg  : 格式化的UIXML消息
function X.RenderChatLink(arg1, arg2)
	if X.IsString(arg1) then -- szMsg
		local szMsg = arg1
		local aXMLNode = X.XMLDecode(szMsg)
		if aXMLNode then
			for _, node in ipairs(aXMLNode) do
				if X.XMLIsNode(node) and X.XMLGetNodeType(node) == 'text' and X.XMLGetNodeData(node, 'name') then
					local name, script = X.XMLGetNodeData(node, 'name'), X.XMLGetNodeData(node, 'script')
					if script then
						script = script .. '\n'
					else
						script = ''
					end

					local handlerEntry = X.NSFormatString('{$NS}.ChatLinkEventHandlers')
					if name == 'namelink' or name:sub(1, 9) == 'namelink_' then
						script = script .. 'this.' .. RENDERED_FLAG_KEY .. '=true;this.OnItemLButtonDown='
							.. handlerEntry .. '.OnNameLClick;this.OnItemRButtonDown='
							.. handlerEntry .. '.OnNameRClick'
					elseif name == 'copy' or name == 'copylink' or name == 'timelink' then
						script = script .. 'this.' .. RENDERED_FLAG_KEY .. '=true;this.OnItemLButtonDown='
							.. handlerEntry .. '.OnCopyLClick;this.OnItemMButtonDown='
							.. handlerEntry .. '.OnCopyMClick;this.OnItemRButtonDown='
							.. handlerEntry .. '.OnCopyRClick;this.OnItemMouseEnter='
							.. handlerEntry .. '.OnCopyMouseEnter;this.OnItemMouseLeave='
							.. handlerEntry .. '.OnCopyMouseLeave'
					else
						script = script .. 'this.' .. RENDERED_FLAG_KEY .. '=true;this.OnItemLButtonDown='
							.. handlerEntry .. '.OnItemLClick;this.OnItemRButtonDown='
							.. handlerEntry .. '.OnItemRClick'
					end

					if #script > 0 then
						X.XMLSetNodeData(node, 'eventid', 82803)
						X.XMLSetNodeData(node, 'script', script)
					end
				end
			end
			szMsg = X.XMLEncode(aXMLNode)
		end
		return szMsg
	elseif X.IsElement(arg1) then
		local element = arg1
		local link = arg2 or arg1
		if element[RENDERED_FLAG_KEY] then
			return
		end
		local ui = X.UI(element)
		local name = ui:Name()
		if name == 'namelink' or name:sub(1, 9) == 'namelink_' then
			ui:LClick(function() ChatLinkEvents.OnNameLClick(element, link) end)
			ui:RClick(function() ChatLinkEvents.OnNameRClick(element, link) end)
		elseif name == 'copy' or name == 'copylink' then
			ui:LClick(function() ChatLinkEvents.OnCopyLClick(element, link) end)
			ui:RClick(function() ChatLinkEvents.OnCopyRClick(element, link) end)
			ui:MClick(function() ChatLinkEvents.OnCopyMClick(element, link) end)
		else
			ui:LClick(function() ChatLinkEvents.OnItemLClick(element, link) end)
			ui:RClick(function() ChatLinkEvents.OnItemRClick(element, link) end)
		end
		element[RENDERED_FLAG_KEY] = true
		return element
	end
end

-- 复制Item到输入框
function X.CopyChatItem(p)
	local edit = X.GetChatInput()
	if not edit then
		return
	end
	if p:GetType() == 'Text' then
		local szText, szName = p:GetText(), p:GetName()
		if szName == 'itemlink' then
			edit:InsertObj(szText, { type = 'item', text = szText, item = p:GetUserData() })
		elseif szName == 'iteminfolink' then
			edit:InsertObj(szText, { type = 'iteminfo', text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
		elseif szName == 'namelink' or string.sub(szName, 1, 9) == 'namelink_' then
			-- 过滤换行符
			if X.IsRestricted('X.CHAT_CRLF') then
				szText = X.StringReplaceW(szText, '\n', '')
			end
			edit:InsertObj(szText, { type = 'name', text = szText, name = string.match(szText, '%[(.*)%]') })
		elseif szName == 'questlink' then
			edit:InsertObj(szText, { type = 'quest', text = szText, questid = p:GetUserData() })
		elseif szName == 'recipelink' then
			edit:InsertObj(szText, { type = 'recipe', text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == 'enchantlink' then
			edit:InsertObj(szText, { type = 'enchant', text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == 'skilllink' then
			local o = X.Clone(p.skillKey)
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

-- 从界面聊天元素解析原始聊天消息数据
-- (aSay: table) X.ParseChatData(oData: Element, tOption: table)
-- (aSay: table) X.ParseChatData(oData: XMLString, tOption: table)
-- (aSay: table) X.ParseChatData(oData: XMLNode, tOption: table)
do
local function ParseChatData(oData, tOption, aContent, bIgnoreRange)
	if X.IsString(oData) then
		local aXMLNode = X.XMLDecode(oData)
		if aXMLNode then
			for _, node in ipairs(aXMLNode) do
				ParseChatData(node, tOption, aContent, true)
			end
		end
	elseif X.XMLIsNode(oData) then
		local node = oData
		local nodeType = X.XMLGetNodeType(node)
		local nodeName = X.XMLGetNodeData(node, 'name') or ''
		local nodeText = X.XMLGetNodeData(node, 'text')
		local nodeScript = X.XMLGetNodeData(node, 'script')
		local nodeUserdata = X.XMLGetNodeData(node, 'userdata')
		if nodeType == 'handle' then -- 子元素递归
			local children = X.XMLGetNodeChildren(node)
			local nStartIndex = not bIgnoreRange and tOption.nStartIndex or 0
			local nEndIndex = not bIgnoreRange and tOption.nEndIndex or (#children - 1)
			for nIndex = nStartIndex, nEndIndex do
				ParseChatData(children[nIndex + 1], tOption, aContent, true)
			end
		elseif nodeType == 'text' then -- 文字内容
			if nodeName == 'itemlink' then -- 物品链接
				table.insert(aContent, {
					type = 'item',
					text = nodeText, innerText = nodeText:sub(2, -2), item = nodeUserdata,
				})
			elseif nodeName == 'iteminfolink' then -- 物品信息
				local version, tab, index = string.match(nodeScript, 'this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)')
				table.insert(aContent, {
					type = 'iteminfo',
					text = nodeText, innerText = nodeText:sub(2, -2),
					version = version, tabtype = tab, index = index,
				})
			elseif nodeName:sub(1, 9) == 'namelink_' then -- 姓名
				table.insert(aContent, {
					type = 'name',
					text = nodeText, innerText = nodeText,
					name = nodeText:sub(2, -2), id = nodeName:sub(10),
				})
			elseif nodeName == 'questlink' then -- 任务
				table.insert(aContent, {
					type = 'quest',
					text = nodeText, innerText = nodeText:sub(2, -2), questid = nodeUserdata,
				})
			elseif nodeName == 'recipelink' then -- 生活技艺
				local craft, recipe = string.match(nodeScript, 'this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)')
				table.insert(aContent, {
					type = 'recipe',
					text = nodeText, innerText = nodeText:sub(2, -2),
					craftid = craft, recipeid = recipe,
				})
			elseif nodeName == 'skilllink' then -- 技能
				local skillinfo = string.match(nodeScript, 'this.skillKey=%{(.-)%}')
				local skillKey = {}
				for w in string.gmatch(skillinfo, '(.-)%,') do
					local k, v  = string.match(w, '(.-)=(%w+)')
					skillKey[k] = v
				end
				skillKey.type = 'skill'
				skillKey.text = nodeText
				skillKey.innerText = nodeText:sub(2, -2)
				table.insert(aContent, skillKey)
			elseif nodeName == 'designationlink' then -- 称号
				local id, fix = string.match(nodeScript, 'this.dwID=(%d+)%s*this.bPrefix=(.-)')
				table.insert(aContent, {
					type = 'designation',
					text = nodeText, innerText = nodeText:sub(2, -2), id = id, prefix = fix,
				})
			elseif nodeName == 'skillrecipelink' then -- 技能秘籍
				local id, level = string.match(nodeScript, 'this.dwID=(%d+)%s*this.dwLevel=(%d+)')
				table.insert(aContent, {
					type = 'skillrecipe',
					text = nodeText, innerText = nodeText:sub(2, -2), id = id, level = level,
				})
			elseif nodeName == 'booklink' then -- 书籍
				local version, tab, index, id = string.match(nodeScript, 'this.nVersion=(%d+)%s*this.dwTabType=(%d+)%s*this.dwIndex=(%d+)%s*this.nBookRecipeID=(%d+)')
				table.insert(aContent, {
					type = 'book',
					text = nodeText, innerText = nodeText:sub(2, -2),
					version = version, tabtype = tab, index = index, bookinfo = id,
				})
			elseif nodeName == 'achievementlink' then -- 成就
				local id = string.match(nodeScript, 'this.dwID=(%d+)')
				table.insert(aContent, {
					type = 'achievement',
					text = nodeText, innerText = nodeText:sub(2, -2), id = id,
				})
			elseif nodeName == 'enchantlink' then -- 强化
				local pro, craft, recipe = string.match(nodeScript, 'this.dwProID=(%d+)%s*this.dwCraftID=(%d+)%s*this.dwRecipeID=(%d+)')
				table.insert(aContent, {
					type = 'enchant',
					text = nodeText, innerText = nodeText:sub(2, -2),
					proid = pro, craftid = craft, recipeid = recipe,
				})
			elseif nodeName == 'eventlink' then -- 事件
				local eventname, linkinfo = string.match(nodeScript, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"$')
				if not eventname then
					eventname, linkinfo = string.match(nodeScript, 'this.szName="(.-)"%s*this.szLinkInfo="(.-)"')
				end
				table.insert(aContent, {
					type = 'eventlink',
					text = nodeText, innerText = nodeText:sub(2, -2),
					name = eventname, linkinfo = linkinfo:gsub('\\(.)', '%1'),
				})
			elseif not X.IsEmpty(nodeText) then -- 未知类型的字符串、普通文本
				table.insert(aContent, {
					type = 'text',
					text = nodeText, innerText = nodeText,
				})
			end
		elseif nodeType == 'image' or nodeType == 'animate' then -- 表情
			if string.sub(nodeName, 1, 8) == 'emotion_' then -- 表情
				local dwID = tonumber((nodeName:sub(9)))
				if dwID then
					local emo = X.GetChatEmotion(dwID)
					if emo then
						table.insert(aContent, {
							type = 'emotion',
							text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID,
						})
					end
				end
			else -- 货币单位
				local path = X.XMLGetNodeData(node, 'path')
				local frame = X.XMLGetNodeData(node, 'frame')
				if X.IsString(path) then
					path = X.StringLowerW(X.NormalizePath(path))
				end
				if path == 'ui\\image\\common\\money.uitex' and frame == 0 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Gold'], innerText = _L['Gold'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and frame == 2 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Silver'], innerText = _L['Silver'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and frame == 1 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Copper'], innerText = _L['Copper'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and (frame == 31 or frame == 32 or frame == 33 or frame == 34) then
					table.insert(aContent, {
						type = 'text',
						text = _L['Brics'], innerText = _L['Brics'],
					})
				end
			end
		end
	elseif X.IsElement(oData) then
		local elem = oData
		local elemType = elem:GetType()
		local elemName = elem:GetName()
		if elemType == 'Handle' then -- 子元素递归
			local nStartIndex = not bIgnoreRange and tOption.nStartIndex or 0
			local nEndIndex = not bIgnoreRange and tOption.nEndIndex or (elem:GetItemCount() - 1)
			for nIndex = nStartIndex, nEndIndex do
				ParseChatData(elem:Lookup(nIndex), tOption, aContent, true)
			end
		elseif elemType == 'Text' then -- 文字内容
			local elemText = elem:GetText()
			local elemUserdata = elem:GetUserData()
			if elemName == 'itemlink' then -- 物品链接
				table.insert(aContent, {
					type = 'item',
					text = elemText, innerText = elemText:sub(2, -2), item = elemUserdata,
				})
			elseif elemName == 'iteminfolink' then -- 物品信息
				table.insert(aContent, {
					type = 'iteminfo',
					text = elemText, innerText = elemText:sub(2, -2),
					version = elem.nVersion, tabtype = elem.dwTabType, index = elem.dwIndex,
				})
			elseif string.sub(elemName, 1, 9) == 'namelink_' then -- 姓名
				table.insert(aContent, {
					type = 'name',
					text = elemText, innerText = elemText,
					name = string.match(elemText, '%[(.*)%]'), id = elemName:sub(10),
				})
			elseif elemName == 'questlink' then -- 任务
				table.insert(aContent, {
					type = 'quest',
					text = elemText, innerText = elemText:sub(2, -2), questid = elemUserdata,
				})
			elseif elemName == 'recipelink' then -- 生活技艺
				table.insert(aContent, {
					type = 'recipe',
					text = elemText, innerText = elemText:sub(2, -2),
					craftid = elem.dwCraftID, recipeid = elem.dwRecipeID,
				})
			elseif elemName == 'skilllink' then -- 技能
				local skillKey = X.Clone(elem.skillKey)
				skillKey.type = 'skill'
				skillKey.text = elemText
				skillKey.innerText = elemText:sub(2, -2)
				table.insert(aContent, skillKey)
			elseif elemName =='designationlink' then -- 称号
				table.insert(aContent, {
					type = 'designation',
					text = elemText, innerText = elemText:sub(2, -2), id = elem.dwID, prefix = elem.bPrefix,
				})
			elseif elemName =='skillrecipelink' then -- 技能秘籍
				table.insert(aContent, {
					type = 'skillrecipe',
					text = elemText, innerText = elemText:sub(2, -2), id = elem.dwID, level = elem.dwLevelD,
				})
			elseif elemName =='booklink' then -- 书籍
				table.insert(aContent, {
					type = 'book',
					text = elemText, innerText = elemText:sub(2, -2),
					version = elem.nVersion, tabtype = elem.dwTabType, index = elem.dwIndex, bookinfo = elem.nBookRecipeID,
				})
			elseif elemName =='achievementlink' then -- 成就
				table.insert(aContent, {
					type = 'achievement',
					text = elemText, innerText = elemText:sub(2, -2), id = elem.dwID,
				})
			elseif elemName == 'enchantlink' then -- 强化
				table.insert(aContent, {
					type = 'enchant',
					text = elemText, innerText = elemText:sub(2, -2),
					proid = elem.dwProID, craftid = elem.dwCraftID, recipeid = elem.dwRecipeID,
				})
			elseif elemName =='eventlink' then -- 事件
				table.insert(aContent, {
					type = 'eventlink',
					text = elemText, innerText = elemText:sub(2, -2),
					name = elem.szName, linkinfo = elem.szLinkInfo,
				})
			elseif not X.IsEmpty(elemText) then -- 未知类型的字符串、普通文本
				table.insert(aContent, {
					type = 'text',
					text = elemText, innerText = elemText,
				})
			end
		elseif elemType == 'Image' or elemType == 'Animate' then
			if string.sub(elemName, 1, 8) == 'emotion_' then -- 表情
				local dwID = tonumber((elemName:sub(9)))
				if dwID then
					local emo = X.GetChatEmotion(dwID)
					if emo then
						table.insert(aContent, {
							type = 'emotion',
							text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID,
						})
					end
				end
			else -- 货币单位
				local path, frame = elem:GetImagePath()
				if X.IsString(path) then
					path = X.StringLowerW(X.NormalizePath(path))
				end
				if path == 'ui\\image\\common\\money.uitex' and frame == 0 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Gold'], innerText = _L['Gold'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and frame == 2 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Silver'], innerText = _L['Silver'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and frame == 1 then
					table.insert(aContent, {
						type = 'text',
						text = _L['Copper'], innerText = _L['Copper'],
					})
				elseif path == 'ui\\image\\common\\money.uitex' and (frame == 31 or frame == 32 or frame == 33 or frame == 34) then
					table.insert(aContent, {
						type = 'text',
						text = _L['Brics'], innerText = _L['Brics'],
					})
				end
			end
		end
	elseif X.IsArray(oData) then
		for _, node in ipairs(oData) do
			ParseChatData(node, tOption, aContent, true)
		end
	end
	return aContent
end
function X.ParseChatData(oData, tOption)
	return ParseChatData(oData, tOption, {}, false)
end
end

-- 从原始聊天消息数据构建界面元素富文本字符串
-- (aSay: table) X.XmlifyChatData(aSay: table, r?: number, g?: number, b?: number, font?: number)
function X.XmlifyChatData(t, r, g, b, f)
	local aXML = {}
	for _, v in ipairs(t) do
		if v.type == 'text' then
			table.insert(aXML, GetFormatText(v.text, f, r, g, b))
		elseif v.type == 'name' then
			table.insert(aXML, GetFormatText(v.text, f, r, g, b, 515, nil, 'namelink_' .. (v.id or 0)))
		end
	end
	return table.concat(aXML)
end

-- 从原始聊天消息数据构建纯阅读字符串
-- (string) X.StringifyChatText(aSay: table)
function X.StringifyChatText(t)
	local aText = {}
	for _, v in ipairs(t) do
		if v.text then -- v.type == 'text' or v.type == 'name'
			table.insert(aText, v.text)
		elseif v.type == 'emotion' then
			local emo = X.GetChatEmotion(v.id)
			if emo then
				table.insert(aText, emo.szCmd)
			end
		end
	end
	return table.concat(aText)
end

-- 判断某个频道能否发言
-- (bool) X.CanUseChatChannel(number nChannel)
function X.CanUseChatChannel(nChannel)
	for _, v in ipairs({'WHISPER', 'TEAM', 'RAID', 'BATTLE_FIELD', 'NEARBY', 'TONG', 'TONG_ALLIANCE'}) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end

-- 切换聊天频道
-- (void) X.SwitchChatChannel(number nChannel)
-- (void) X.SwitchChatChannel(string szHeader)
-- (void) X.SwitchChatChannel(string szName)
function X.SwitchChatChannel(nChannel)
	local szHeader = X.CONSTANT.PLAYER_TALK_CHANNEL_HEADER[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		local edit = X.GetChatInput()
		if edit then
			edit:GetRoot():Show()
			edit:SetText('/w ')
			Station.SetFocusWindow(edit)
		end
	elseif type(nChannel) == 'string' then
		if string.sub(nChannel, 1, 1) == '/' then
			if nChannel == '/cafk' or nChannel == '/catr' then
				local edit = X.GetChatInput()
				if edit then
					edit:ClearText()
					for _, v in ipairs({{ type = 'text', text = nChannel }}) do
						edit:InsertObj(v.text, v)
					end
				end
			else
				SwitchChatChannel(nChannel..' ')
			end
		else
			SwitchChatChannel('/w ' .. string.gsub(nChannel,'[%[%]]','') .. ' ')
		end
	end
end

do
-- 聊天表情初始化
local MAX_EMOTION_LEN, EMOTION_CACHE = 0, nil
local function InitEmotion()
	if not EMOTION_CACHE then
		local t = {}
		local FaceIcon = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('FaceIcon', true)
		if FaceIcon then
			for i = 1, FaceIcon:GetRowCount() do
				local tLine = FaceIcon:GetRow(i)
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
				MAX_EMOTION_LEN = math.max(MAX_EMOTION_LEN, X.StringLenW(t1.szCmd))
			end
		end
		EMOTION_CACHE = t
	end
end
-- 获取聊天表情列表
-- typedef emo table
-- (emo[]) X.GetChatEmotion()                             -- 返回所有表情列表
-- (emo)   X.GetChatEmotion(szCommand)                    -- 返回指定Cmd的表情
-- (emo)   X.GetChatEmotion(szImageFile, nFrame, szType)  -- 返回指定图标的表情
function X.GetChatEmotion(arg0, arg1, arg2)
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
	return X.Clone(t)
end
-- parse faceicon in talking message
local function ParseFaceIcon(t)
	InitEmotion()
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= 'text' then
			-- if v.type == 'emotion' then
			-- 	v.type = 'text'
			-- end
			table.insert(t2, v)
		else
			local szText = v.text
			local szLeft = ''
			while szText and #szText > 0 do
				local szFace, dwFaceID = nil, nil
				local nPos = X.StringFindW(szText, '#')
				if not nPos then
					szLeft = szLeft .. szText
					szText = ''
				else
					szLeft = szLeft .. string.sub(szText, 1, nPos - 1)
					szText = string.sub(szText, nPos)
					for i = math.min(MAX_EMOTION_LEN, X.StringLenW(szText)), 2, -1 do
						local szTest = X.StringSubW(szText, 1, i)
						local emo = X.GetChatEmotion(szTest)
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
	local me = X.GetClientPlayer()
	local tar = X.GetTargetHandle(X.GetCharacterTarget(me))
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
			-- if v.type == 'name' then
			-- 	v = { type = 'text', text = '['..v.name..']' }
			-- end
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
					local _, nEndPos = X.StringFindW(szText, szSensitiveWord)
					if nEndPos and nEndPos < nSensitiveWordEndPos then
						local nSensitiveWordLenW = X.StringLenW(szSensitiveWord)
						nSensitiveWordEndLen = string.len(X.StringSubW(szSensitiveWord, nSensitiveWordLenW, nSensitiveWordLenW))
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

-- parserOptions 解析规则类型定义
-- parserOptions         (object|boolean) 解析器开关 true 表示全部解析， false 表示全不解析
-- parserOptions.name    (boolean)        解析聊天内容中的名字，默认解析
-- parserOptions.emotion (boolean)        解析聊天内容中的表情图片和名字，默认解析
-- parserOptions.sws     (boolean)        安全性关键词校验，默认不校验
-- parserOptions.len     (boolean)        聊天最大长度限制校验，默认不校验
local StandardizeParserOptions
do
local DEFAULT_PARSER_OPTIONS = X.FreezeTable({
	name = true,
	emotion = true,
	sws = false,
	len = true,
})
local FULL_PARSER_OPTIONS = X.FreezeTable({
	name = true,
	emotion = true,
	sws = true,
	len = true,
})
local NULL_PARSER_OPTIONS = X.FreezeTable({
	name = false,
	emotion = false,
	sws = false,
	len = false,
})
function StandardizeParserOptions(parsers)
	if parsers == true then
		parsers = FULL_PARSER_OPTIONS
	elseif parsers == false then
		parsers = NULL_PARSER_OPTIONS
	elseif not X.IsTable(parsers) then
		parsers = DEFAULT_PARSER_OPTIONS
	end
	local mt = {
		__index = function(_, k)
			local v = parsers[k]
			if X.IsNil(v) then
				v = DEFAULT_PARSER_OPTIONS[k]
			end
			return v
		end,
	}
	return setmetatable({}, mt)
end
end

X.RegisterRestriction('X.CHAT_CRLF', { ['*'] = true })
X.RegisterRestriction('X.CHAT_LEN', { ['*'] = true })
X.RegisterRestriction('X.CHAT_WUJIE', { ['*'] = true })

-- 格式化聊天内容
-- szText        -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- parserOptions -- 解析规则，参见 @parserOptions 定义
local function StandardizeChatData(szText, parserOptions)
	-- 聊天内容格式标准化
	local aSay = nil
	if X.IsTable(szText) then
		aSay = X.Clone(szText)
	else
		aSay = {{ type = 'text', text = szText }}
	end
	-- 过滤换行符
	if X.IsRestricted('X.CHAT_CRLF') then
		for _, v in ipairs(aSay) do
			if v.text then
				v.text = X.StringReplaceW(v.text, '\n', ' ')
			end
			if v.name then
				v.name = X.StringReplaceW(v.name, '\n', ' ')
			end
		end
	end
	-- 表情转义
	if parserOptions.emotion then
		aSay = ParseFaceIcon(aSay)
	end
	-- 名字转义
	if parserOptions.name then
		aSay = ParseName(aSay)
	end
	-- 安全性和长度校验
	if parserOptions.sws then
		aSay = ParseAntiSWS(aSay)
	end
	if parserOptions.len and X.IsRestricted('X.CHAT_LEN') then
		local nLen = 0
		for i, v in ipairs(aSay) do
			if nLen <= 64 then
				nLen = nLen + X.StringLenW(v.text or v.name or '')
				if nLen > 64 then
					if v.text then
						v.text = X.StringSubW(v.text, 1, 64 - nLen)
					end
					if v.name then
						v.name = X.StringSubW(v.name, 1, 64 - nLen)
					end
					for j = #aSay, i + 1, -1 do
						table.remove(aSay, j)
					end
				end
			end
		end
	end
	return aSay
end

-- 聊天数据签名
-- aSay        -- 标准化聊天内容
-- uuid        -- 消息唯一标识符
-- me          -- 玩家自身角色对象
local function SignChatData(aSay, uuid, me)
	if not aSay[1] or aSay[1].name ~= '' or aSay[1].type ~= 'eventlink' then
		table.insert(aSay, 1, { type = 'eventlink', name = '', text = '' })
	end
	local dwTime = GetCurrentTime()
	local szLinkInfo = X.EncodeJSON({
		_ = dwTime,
		a = X.IsDebugging() and 1 or nil,
		via = X.PACKET_INFO.NAME_SPACE,
		uuid = uuid and tostring(uuid),
	})
	aSay[1].linkinfo = szLinkInfo
	return aSay
end

-- 设置聊天内容
-- (void) X.SetChatInput(string szText[, table parsers, [string uuid]])
-- szText    -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- parsers   -- *可选* 解析器参数，参见 X.SendChat: tOptions.parsers
-- uuid      -- *可选* 消息唯一标识符，参见 X.SendChat: tOptions.uuid
function X.SetChatInput(szText, parsers, uuid)
	local me = X.GetClientPlayer()
	local edit = X.GetChatInput()
	if me and edit then
		local parserOptions = StandardizeParserOptions(parsers)
		local aSay = StandardizeChatData(szText, parserOptions)
		local aSignSay = SignChatData(aSay, uuid, me)
		edit:ClearText()
		for _, v in ipairs(aSignSay) do
			edit:InsertObj(v.text, v)
		end
	end
end

-- 发布聊天内容
-- (void) X.SendChat(mixed uTarget, string szText[, boolean bNoEscape, [boolean bSaveDeny] ])
-- uTarget   -- 聊天目标：
--              1、(number) PLAYER_TALK_CHANNLE.* 战场/团队聊天频道可智能切换
--              2、(string) 密聊的目标角色名
-- szText    -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- tOptions  -- 高级参数
--              tOptions.uuid            (string)         消息唯一标识符，用于刷屏过滤
--              tOptions.parsers         (object|boolean) 解析器开关 true 表示全部解析， false 表示全不解析
--              tOptions.parsers.name    (boolean)        解析聊天内容中的名字，默认解析
--              tOptions.parsers.emotion (boolean)        解析聊天内容中的表情图片和名字，默认解析
--              tOptions.save            (boolean)        在聊天输入栏保留不可发言的频道内容，默认为 false
function X.SendChat(nChannel, szText, tOptions)
	if not tOptions then
		tOptions = {}
	end
	-- 检查是否转向设置输入框
	if tOptions.save and not X.CanUseChatChannel(nChannel) then
		X.SetChatInput(szText, tOptions.parsers)
		X.SwitchChatChannel(nChannel)
		X.FocusChatInput()
		return
	end
	-- 初始化参数
	local szTarget, me = '', X.GetClientPlayer()
	if X.IsString(nChannel) then
		szTarget = nChannel
		nChannel = PLAYER_TALK_CHANNEL.WHISPER
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- 格式化并判断是否是系统输出
	local bSystem = nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS
	local parserOptions = StandardizeParserOptions(tOptions.parsers)
	if bSystem then
		parserOptions.sws = false
		parserOptions.len = false
	end
	local aSay = StandardizeChatData(szText, parserOptions)
	if bSystem then
		local szXml = X.XmlifyChatData(aSay, GetMsgFontColor('MSG_SYS'))
		return X.OutputSystemMessage({ szXml, rich = true })
	end
	-- 签名并发送
	local aSignSay = SignChatData(aSay, tOptions.uuid, me)
	if X.IS_REMAKE then
		me.Talk(nChannel, szTarget, aSignSay, true)
	else
		me.Talk(nChannel, szTarget, aSignSay)
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
function X.SendTabChat(nChannel, aTable, aAlignment)
	local aLenHW, aMaxLenHW = {}, {}
	for i, aText in ipairs(aTable) do
		aLenHW[i] = {}
		for j, szText in ipairs(aText) do
			aLenHW[i][j] = #szText
			aMaxLenHW[j] = math.max(aLenHW[i][j], aMaxLenHW[j] or 0)
		end
	end
	local aAlignment = setmetatable(aAlignment or {}, metaAlignment)
	for i, aText in ipairs(aTable) do
		local aSay, szFixL, szFixR = {}, nil, nil
		local nFixLenFW, nFixLenHW
		for j, szText in ipairs(aText) do
			nFixLenFW = math.floor(math.max(0, aMaxLenHW[j] - aLenHW[i][j]) / 2)
			if nFixLenFW % 2 == 1 then
				nFixLenFW = nFixLenFW - 1
			end
			nFixLenHW = aMaxLenHW[j] - (aLenHW[i][j] + nFixLenFW * 2)
			szFixL = W_SPACE:rep(math.ceil(nFixLenFW / 2)) .. SPACE:rep(math.ceil(nFixLenHW / 2))
			szFixR = W_SPACE:rep(math.floor(nFixLenFW / 2)) .. SPACE:rep(math.floor(nFixLenHW / 2))
			if aAlignment[j] == 'M' then
				aSay[j] = szFixL .. szText .. szFixR
			elseif aAlignment[j] == 'R' then
				aSay[j] = MergeHW(szFixL .. szFixR) .. szText
			else
				aSay[j] = szText .. MergeHW(szFixL .. szFixR)
			end
		end
		-- X.OutputSystemMessage(table.concat(aSay, '|'))
		X.SendChat(nChannel, (table.concat(aSay, ' ')))
	end
end
end

do
local m_LevelUpData
local function GetRegisterChannelLimitTable()
	if not m_LevelUpData then
		if IsFileExist('settings\\Chat\\ChatDailyCountLimit.tab') then
			m_LevelUpData = KG_Table.Load('settings\\Chat\\ChatDailyCountLimit.tab', {
				{f = 'i', t = 'Level'},
				{f = 'i', t = 'SceneChannelDailyLimit'},
				{f = 'i', t = 'WorldChannelDailyLimit'},
				{f = 'i', t = 'CampChannelDailyLimit'},
				{f = 'i', t = 'ForceChannelDailyLimit'},
				{f = 'i', t = 'IdentityChannelDailyLimit'},
			}, FILE_OPEN_MODE.NORMAL)
		else
			local me = X.GetClientPlayer()
			if not me then
				return false
			end
			local szPath = ('settings\\LevelUpData\\%s.tab'):format(({
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
				X.IS_REMAKE and {f = 'i', t = 'IdentityChannelDailyLimit'} or false,
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
				X.IS_REMAKE and {f = 'i', t = 'WorldChannelDailyLimitByVIP'} or false,
				X.IS_REMAKE and {f = 'i', t = 'WorldChannelDailyLimitBySuperVIP'} or false,
			}
			for i, v in X.ipairs_r(tTitle) do
				if not v then
					table.remove(tTitle, i)
				end
			end
			m_LevelUpData = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL)
		end
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
function X.GetChatChannelDailyLimit(nLevel, nChannel)
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

local function GenerateMsgTypeMenu(node, xInject)
	local t = { szOption = node.szOption }
	for _, v in ipairs(node) do
		if X.IsString(v) then
			local tInject
			if X.IsFunction(xInject) then
				tInject = xInject(v)
			elseif X.IsTable(xInject) then
				tInject = xInject
			end
			local t1 = {
				szOption = g_tStrings.tChannelName[v],
				rgb = GetMsgFontColor(v, true),
				UserData = v,
				bCheck = true,
			}
			if tInject then
				for k, v in pairs(tInject) do
					t1[k] = v
				end
			end
			table.insert(t, t1)
		elseif X.IsTable(v) then
			table.insert(t, GenerateMsgTypeMenu(v, xInject))
		end
	end
	return t
end

---插入消息频道菜单
---@param tMenu table @要插入的目标表
---@param xInject function | table @叶子菜单数据注入，如果为 table 类型则直接覆盖，如果为 方法则执行后获取结果再进行覆盖
---@return table @完整的消息频道菜单
function X.InsertMsgTypeMenu(tMenu, xInject)
	for _, v in ipairs(GenerateMsgTypeMenu(X.CONSTANT.MSG_TYPE_MENU, xInject)) do
		table.insert(tMenu, v)
	end
	return tMenu
end

-----------------------------------------------------------------------------------------
-- 聊天栏 HOOK
-----------------------------------------------------------------------------------------
do
-- HOOK聊天栏
local CHAT_HOOK = {
	BEFORE = {},
	AFTER = {},
	FILTER = {},
}
function X.HookChatPanel(szType, szKey, fnAction)
	if X.IsFunction(szKey) then
		szKey, fnAction = nil, szKey
	end
	if not CHAT_HOOK[szType] then
		return
	end
	if not szKey then
		szKey = GetTickCount()
		while CHAT_HOOK[szType][tostring(szKey)] do
			szKey = szKey + 0.1
		end
		szKey = tostring(szKey)
	end
	if X.IsNil(fnAction) then
		return CHAT_HOOK[szType][szKey]
	end
	if not X.IsFunction(fnAction) then
		fnAction = nil
	end
	CHAT_HOOK[szType][szKey] = fnAction
	return szKey
end

local l_hPrevItem
local function BeforeChatAppendItemFromString(h, szMsg, ...) -- h, szMsg, szChannel, dwTime, nR, nG, nB, ...
	for szKey, fnAction in pairs(CHAT_HOOK.FILTER) do
		local res, err, trace = X.XpCall(fnAction, h, szMsg, ...)
		if res then
			if not err then
				return h, '', ...
			end
		--[[#DEBUG BEGIN]]
		else
			X.ErrorLog(err, 'HookChatPanel.FILTER: ' .. szKey, trace)
		--[[#DEBUG END]]
		end
	end
	for szKey, fnAction in pairs(CHAT_HOOK.BEFORE) do
		local res, err, trace = X.XpCall(fnAction, h, szMsg, ...)
		if res then
			if X.IsString(err) then
				szMsg = err
			end
		--[[#DEBUG BEGIN]]
		else
			X.ErrorLog(err, 'HookChatPanel.BEFORE: ' .. szKey, trace)
		--[[#DEBUG END]]
		end
	end
	local nCount = h:GetItemCount()
	if nCount == 0 then
		l_hPrevItem = 0
	else
		l_hPrevItem = h:Lookup(nCount - 1)
	end
	return h, szMsg, ...
end

local function GetAfterChatAppendStartIndex(h)
	local nIndex = -1
	if l_hPrevItem == 0 then
		nIndex = 0
	elseif l_hPrevItem and l_hPrevItem:IsValid() and l_hPrevItem:GetParent() == h then
		nIndex = l_hPrevItem:GetIndex() + 1
	end
	return nIndex
end

local function AfterChatAppendItemFromString(h, ...)
	if l_hPrevItem then
		local nCount = h:GetItemCount()
		local nStart = GetAfterChatAppendStartIndex(h)
		if nStart >= 0 and nStart < nCount then
			for szKey, fnAction in pairs(CHAT_HOOK.AFTER) do
				local nIndex = GetAfterChatAppendStartIndex(h)
				if nIndex == -1 then
					break
				end
				local res, err, trace = X.XpCall(fnAction, h, nIndex, ...)
				if not res then
					X.ErrorLog(err, 'HookChatPanel.AFTER: ' .. szKey, trace)
				end
			end
		end
		l_hPrevItem = nil
	end
	return h, ...
end

local HOOKED_UI = setmetatable({}, { __mode = 'k' })
local function Hook(i)
	local frame = X.GetChatPanel(i)
	local h = frame and frame:Lookup('Wnd_Message', 'Handle_Message')
	if h and not HOOKED_UI[h] then
		HOOKED_UI[h] = true
		HookTableFunc(h, 'AppendItemFromString', BeforeChatAppendItemFromString, { bHookParams = true })
		HookTableFunc(h, 'AppendItemFromString', AfterChatAppendItemFromString, { bAfterOrigin = true, bHookParams = true })
	end
end
X.RegisterEvent('CHAT_PANEL_OPEN', 'ChatPanelHook', function(event) Hook(arg0) end)

local function Unhook(i)
	local frame = X.GetChatPanel(i)
	local h = frame and frame:Lookup('Wnd_Message', 'Handle_Message')
	if h and HOOKED_UI[h] then
		HOOKED_UI[h] = nil
		UnhookTableFunc(h, 'AppendItemFromString', BeforeChatAppendItemFromString)
		UnhookTableFunc(h, 'AppendItemFromString', AfterChatAppendItemFromString)
	end
end

local function HookAll()
	for _, k in X.pairs_c(X.CONSTANT.CHAT_PANEL_INDEX_LIST) do
		Hook(k)
	end
end
X.RegisterInit('LIB#ChatPanelHook', HookAll)
X.RegisterEvent('CHAT_PANEL_INIT', 'ChatPanelHook', HookAll)

local function UnhookAll()
	for _, k in X.pairs_c(X.CONSTANT.CHAT_PANEL_INDEX_LIST) do
		Unhook(k)
	end
end
X.RegisterExit('LIB#ChatPanelHook', UnhookAll)
X.RegisterReload('LIB#ChatPanelHook', UnhookAll)
end

-- 防止山寨
RegisterTalkFilter(function(nChannel, aSay, dwTalkerID, szName, bEcho, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
	local szGlobalID
	if X.IsPlayerCrossServer(dwTalkerID) then
		if not X.IsAuthorPlayerName(szName) then
			return
		end
		szGlobalID = X.GetPlayerGlobalID(dwTalkerID)
		if not X.IsGlobalID(szGlobalID) then
			return
		end
	end
	local p = aSay[1]
	if p and p.type == 'eventlink' and p.name == '' then
		local data = X.DecodeJSON(p.linkinfo)
		if data and data.a == 1 then
			return
		end
	end
	if X.GetClientPlayerID() == dwTalkerID then
		return
	end
	if not X.IsAuthorPlayerName(szName) or X.IsAuthorPlayer(dwTalkerID, szName, szGlobalID) then
		return
	end
	if X.IsTeammate(dwTalkerID) or X.IsFellowship(dwTalkerID) then
		if GetStringCRC(GetCurrentTime()) % 10 >= 2 then
			return
		end
	end
	return true
end, {
	PLAYER_TALK_CHANNEL.NEARBY,
	PLAYER_TALK_CHANNEL.SENCE,
	PLAYER_TALK_CHANNEL.WORLD,
	PLAYER_TALK_CHANNEL.TEAM,
	PLAYER_TALK_CHANNEL.RAID,
	PLAYER_TALK_CHANNEL.BATTLE_FIELD,
	PLAYER_TALK_CHANNEL.TONG,
	PLAYER_TALK_CHANNEL.FORCE,
	PLAYER_TALK_CHANNEL.CAMP,
	PLAYER_TALK_CHANNEL.WHISPER,
	PLAYER_TALK_CHANNEL.FRIENDS,
	PLAYER_TALK_CHANNEL.TONG_ALLIANCE,
})

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
