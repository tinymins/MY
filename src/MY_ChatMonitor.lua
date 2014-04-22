--
-- 聊天监控
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能: 按关键字过滤获取聊天消息
-- 
local _L = MY.LoadLangPack()
MY_ChatMonitor = {}
MY_ChatMonitor.szKeyWords = _L['CHAT_MONITOR_KEYWORDS_SAMPLE']
MY_ChatMonitor.bIsRegexp = false
MY_ChatMonitor.nMaxRecord = 30
MY_ChatMonitor.bShowPreview = true
MY_ChatMonitor.tChannels = { ["MSG_NORMAL"] = true, ["MSG_CAMP"] = true, ["MSG_WORLD"] = true, ["MSG_MAP"] = true, ["MSG_SCHOOL"] = true, ["MSG_GUILD"] = true, ["MSG_FRIEND"] = true }
RegisterCustomData('MY_ChatMonitor.szKeyWords')
RegisterCustomData('MY_ChatMonitor.bIsRegexp')
RegisterCustomData('MY_ChatMonitor.nMaxRecord')
RegisterCustomData('MY_ChatMonitor.bShowPreview')
RegisterCustomData('MY_ChatMonitor.tChannels')
local _MY_ChatMonitor = { }
_MY_ChatMonitor.bInited = false
_MY_ChatMonitor.tCapture = {}
_MY_ChatMonitor.bCapture = false
_MY_ChatMonitor.ui = nil
_MY_ChatMonitor.uiBoard = nil
_MY_ChatMonitor.uiTipBoard = nil

-- 插入聊天内容时监控聊天信息
_MY_ChatMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
	-- filter
    if _MY_ChatMonitor.bCapture and _MY_ChatMonitor.ui and _MY_ChatMonitor.uiTest and _MY_ChatMonitor.uiTipBoard and MY_ChatMonitor.szKeyWords and MY_ChatMonitor.szKeyWords~='' and string.match(szMsg,'%s*<%s*text%s*>.*<%s*/text%s*>') then
        local tCapture = {
            szText = '',    -- 计算当前消息的纯文字内容 用于匹配
            szHash = '',    -- 计算当前消息的哈希 用于过滤相同
            szMsg  = szMsg, -- 消息源数据UI
            szTime = '',    -- 消息时间UI
        }
        -- 拼接消息
        _MY_ChatMonitor.uiTest:clear():append(szMsg):child('.Handle'):child():each(function(ele)
            tCapture.szText = tCapture.szText .. ele:GetText()
        end)
        tCapture.szHash = string.gsub(tCapture.szText,'\n', '')
        -- 计算系统消息颜色
        local colMsgSys = GetMsgFontColor("MSG_SYS", true)
        -- 如果不是系统信息 则去掉头部标签 类似[阵营][浩气盟][玩家名称] 舍弃哈希
        if (r~=colMsgSys[1] or g~=colMsgSys[2] or b~=colMsgSys[3]) then
            local nB, nE = StringFindW(tCapture.szHash, g_tStrings.STR_TALK_HEAD_SAY1)
            if nE then tCapture.szHash = string.sub(tCapture.szHash, nE + 1) end
        end
        --------------------------------------------------------------------------------------
        -- 开始计算是否符合过滤器要求
        local bCatch = false
        if MY_ChatMonitor.bIsRegexp then    -- regexp
            if string.find(tCapture.szText, MY_ChatMonitor.szKeyWords) then bCatch = true end
        else        -- normal
            local split = function(s, p)
                local rt= {}
                string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
                return rt
            end
            local escape = function(s) return string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1') end
            -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
            local bKeyWordsLine = false
            for _, szKeyWordsLine in ipairs( split(MY_ChatMonitor.szKeyWords, ';') ) do -- 符合一个即可
                if bKeyWordsLine then break end
                -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
                local bKeyWords = true
                for _, szKeyWords in ipairs( split(szKeyWordsLine, ',') ) do            -- 必须全部符合
                    if not bKeyWords then break end
                    -- 10|十人
                    local bKeyWord = false
                    for _, szKeyWord in ipairs( split(szKeyWords, '|') ) do         -- 符合一个即可
                        if bKeyWord then break end
                        szKeyWord = escape(szKeyWord)
                        if string.sub(szKeyWord, 1, 1)=="!" then    -- !小铁被吃了
                            szKeyWord = string.sub(szKeyWord, 2)
                            if not string.find(tCapture.szText, szKeyWord) then bKeyWord = true end
                        else                                        -- 十人   -- 10
                            if string.find(tCapture.szText, szKeyWord) then bKeyWord = true end
                        end
                    end
                    bKeyWords = bKeyWords and bKeyWord
                end
                bKeyWordsLine = bKeyWordsLine or bKeyWords
            end
            bCatch = bKeyWordsLine
        end
        --------------------------------------------------------------------------------------------
        -- 如果符合要求  -- 验证消息哈希 如果存在则跳过该消息
        if bCatch and (not _MY_ChatMonitor.tCapture[tCapture.szHash]) then
            -- 验证记录是否超过限制条数
            if #_MY_ChatMonitor.tCapture >= MY_ChatMonitor.nMaxRecord then 
                -- 处理记录列表
                _MY_ChatMonitor.tCapture[_MY_ChatMonitor.tCapture[1].szHash] = nil
                table.remove(_MY_ChatMonitor.tCapture, 1)
                -- 处理UI
                local bEnd = false
                if _MY_ChatMonitor.uiBoard then
                    _MY_ChatMonitor.uiBoard:hdl(1):child():each(function(ele)
                        if not bEnd then
                            if ele:GetType()=="Text" and StringFindW(ele:GetText(), "\n") then
                                bEnd = true
                            end
                            ele:GetParent():RemoveItem(ele:GetIndex())
                        end
                    end)
                end
            end
            -- 开始组装一条记录 tCapture
            local t =TimeToDate(GetCurrentTime())
            tCapture.szTime = GetFormatText(string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY_ChatMonitor.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY_ChatMonitor.RepeatChatLine(this) end", "timelink")
            -- binding event change
            tCapture.szMsg = string.gsub(tCapture.szMsg, 'eventid=%d+', 'eventid=371')
            -- save animiate group into name
            tCapture.szMsg = string.gsub(tCapture.szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")	
            
            -- 更新UI
            if _MY_ChatMonitor.uiBoard then
                _MY_ChatMonitor.uiBoard:append(tCapture.szTime..tCapture.szMsg)
                _MY_ChatMonitor.uiBoard:find('#^.*link'):del('#^namelink_'):click(function(nFlag) 
                    if nFlag==1 and IsCtrlKeyDown() then
                        MY_ChatMonitor.CopyChatItem(this)
                    end
                end)
                _MY_ChatMonitor.uiBoard:find('#^namelink_'):click(function(nFlag) 
                    local szName = this:GetText()
                    if nFlag==-1 then
                        PopupMenu((function()
                            return {{
                                szOption = _L['copy'],
                                fnAction = function()
                                    MY.Talk(GetClientPlayer().szName, szName)
                                end,
                            },{
                                szOption = _L['whisper'],
                                fnAction = function()
                                    MY.SwitchChat(szName)
                                end,
                            }}
                        end)())
                    elseif nFlag==1 then
                        if IsCtrlKeyDown() then
                            MY_ChatMonitor.CopyChatItem(this)
                        else
                            MY.SwitchChat(szName)
                            local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
                            if edit then Station.SetFocusWindow(edit) end
                        end
                    end
                end)
            end
            -- 更新缓存数组 哈希表
            _MY_ChatMonitor.tCapture[tCapture.szHash] = true
            table.insert(_MY_ChatMonitor.tCapture, tCapture)
            _MY_ChatMonitor.ShowTip(tCapture.szTime..tCapture.szMsg)
        end
    end
end

-- 海鳗里面抠出来的
-- 聊天复制并发布
_MY_ChatMonitor.RepeatChatLine = function(hTime)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	_MY_ChatMonitor.CopyChatLine(hTime)
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

-- 聊天表情初始化
_MY_ChatMonitor.InitFaceIcon = function()
	if not _MY_ChatMonitor.tFacIcon then
		local t = { image = {}, animate = {} }
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			if tLine.szType == "animate" then
				t.animate[tLine.nFrame] = tLine.szCommand
			else
				t.image[tLine.nFrame] = tLine.szCommand
			end
		end
		_MY_ChatMonitor.tFacIcon = t
	end
end

-- 聊天复制功能
_MY_ChatMonitor.CopyChatLine = function(hTime)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	edit:ClearText()
	local h, i, bBegin = hTime:GetParent(), hTime:GetIndex(), nil
	-- loop
	_MY_ChatMonitor.InitFaceIcon()
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
					-- NPC 喊话特殊处理
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
		elseif p:GetType() == "Image" then
			local nFrame = p:GetFrame()
			local szCmd = _MY_ChatMonitor.tFacIcon.image[nFrame]
			if szCmd then
				edit:InsertObj(szCmd, { type = "text", text = szCmd })
			end
		elseif p:GetType() == "Animate" then
			local nGroup = tonumber(p:GetName())
			if nGroup then
				local szCmd = _MY_ChatMonitor.tFacIcon.animate[nGroup]
				if szCmd then
					edit:InsertObj(szCmd, { type = "text", text = szCmd })
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end

-- 复制Item到输入框
_MY_ChatMonitor.CopyChatItem = function(p)
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
        end
        Station.SetFocusWindow(edit)
    end
end

_MY_ChatMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    ui:append('Label_KeyWord','Text'):children('#Label_KeyWord'):pos(22,15):size(100,25):text(_L['key words:'])
    ui:append('EditBox_KeyWord','WndEditBox'):children('#EditBox_KeyWord'):pos(80,15):size(400,25):text(MY_ChatMonitor.szKeyWords):change(function(szText) MY_ChatMonitor.szKeyWords = szText end)
    ui:append('Image_Help','Image'):children('#Image_Help'):image('UI/Image/UICommon/Commonpanel2.UITex',48):pos(8,10):size(25,25):hover(function(bIn) this:SetAlpha( (bIn and 255 ) or 180) end):click(function(nButton)
        local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(_L['CHAT_MONITOR_TIP']) .." font=207 </text>"
        local x, y = Cursor.GetPos()
        local w, h = this:GetSize()
        OutputTip(szText, 450, {x, y, w, h})
    end):alpha(180)
    ui:append('Image_Setting','Image'):children('#Image_Setting'):pos(600,13):image('UI/Image/UICommon/Commonpanel.UITex',18):size(30,30):alpha(200):hover(function(bIn) this:SetAlpha((bIn and 255) or 200) end):click(function()
        PopupMenu((function() 
            local t = {}
            for szChannel, tChannel in pairs({
                ['MSG_NORMAL'] = { szName = _L['nearby channel'], tCol = GetMsgFontColor("MSG_NORMAL", true) },
                ['MSG_SYS'] = { szName = _L['system channel'], tCol = GetMsgFontColor("MSG_SYS", true) },
                ['MSG_FRIEND'] = { szName = _L['friend channel'], tCol = GetMsgFontColor("MSG_FRIEND", true) },
                ['MSG_TEAM'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
                ['MSG_GUILD'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
                ['MSG_GUILD_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
                ['MSG_MAP'] = { szName = _L['map channel'], tCol = GetMsgFontColor("MSG_MAP", true) },
                ['MSG_SCHOOL'] = { szName = _L['school channel'], tCol = GetMsgFontColor("MSG_SCHOOL", true) },
                ['MSG_CAMP'] = { szName = _L['camp channel'], tCol = GetMsgFontColor("MSG_CAMP", true) },
                ['MSG_WORLD'] = { szName = _L['world channel'], tCol = GetMsgFontColor("MSG_WORLD", true) },
                ['MSG_WHISPER'] = { szName = _L['whisper channel'], tCol = GetMsgFontColor("MSG_WHISPER", true) },
            }) do
                table.insert(t,{
                    szOption = tChannel.szName,
                    rgb = tChannel.tCol,
                    fnAction = function()
                        MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                        _MY_ChatMonitor.RegisterMsgMonitor()
                    end,
                    bCheck = true,
                    bChecked = MY_ChatMonitor.tChannels[szChannel]
                })
            end
            table.insert(t, { bDevide = true })
            table.insert(t,{
                szOption = _L['show message preview box'],
                fnAction = function()
                    MY_ChatMonitor.bShowPreview = not MY_ChatMonitor.bShowPreview
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bShowPreview
            })
            table.insert(t, { bDevide = true })
            table.insert(t,{
                szOption = _L['regular expression'],
                fnAction = function()
                    MY_ChatMonitor.bIsRegexp = not MY_ChatMonitor.bIsRegexp
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bIsRegexp
            })
            return t
        end)())
    end)
    ui:append('Button_Switcher','WndButton'):children('#Button_Switcher'):pos(490,15):width(50):text((_MY_ChatMonitor.bCapture and _L['stop']) or _L['start']):click(function()
        if _MY_ChatMonitor.bCapture then
            MY.UI(this):text(_L['start'])
            _MY_ChatMonitor.bCapture = false
        else
            MY.UI(this):text(_L['stop'])
            _MY_ChatMonitor.bCapture = true
        end
    end)
    ui:append('Button_Clear','WndButton'):children('#Button_Clear'):pos(545,15):width(50):text(_L['clear']):click(function()
        _MY_ChatMonitor.tCapture = {}
        _MY_ChatMonitor.uiBoard:clear()
    end)
    _MY_ChatMonitor.uiBoard = ui:append('WndScrollBox_TalkList','WndScrollBox'):child('#WndScrollBox_TalkList'):handleStyle(3):pos(20,50):size(605,405)
    for i = 1, #_MY_ChatMonitor.tCapture, 1 do
        _MY_ChatMonitor.uiBoard:append( _MY_ChatMonitor.tCapture[i].szTime .. _MY_ChatMonitor.tCapture[i].szMsg )
    end
    _MY_ChatMonitor.ui = MY.UI(wnd)
    _MY_ChatMonitor.Init()
end

_MY_ChatMonitor.ShowTip = function(szMsg)
    if not MY_ChatMonitor.bShowPreview then return end
    local w, h = Station.GetClientSize() 
    local _w, _h = _MY_ChatMonitor.uiFrame:size()
    _MY_ChatMonitor.uiFrame:pos(w - _w - 100, h - _h - 150):bringToTop()
    if szMsg then _MY_ChatMonitor.uiTipBoard:clear():append(szMsg) end
    _MY_ChatMonitor.uiFrame:fadeTo(500,255)
    MY.DelayCall('MY_ChatMonitor_Hide')
    MY.DelayCall(function() _MY_ChatMonitor.uiFrame:fadeOut(500) end,5000,'MY_ChatMonitor_Hide')
end
_MY_ChatMonitor.Init = function()
    if _MY_ChatMonitor.bInited then return end
    _MY_ChatMonitor.bInited = true
    
    _MY_ChatMonitor.RegisterMsgMonitor()
    local fnOnTipClick = function() MY.ActivePanel('ChatMonitor') MY.OpenPanel() _MY_ChatMonitor.uiFrame:fadeOut(500) end
    _MY_ChatMonitor.uiFrame = MY.UI.OpenFrame('MY_ChatMonitor'):size(250,150):hover(function(bIn)
        MY.DelayCall('MY_ChatMonitor_Hide')
        if not bIn then MY.DelayCall(function() _MY_ChatMonitor.uiFrame:fadeOut(500) end,5000,'MY_ChatMonitor_Hide') end
    end):toggle(false)
    _MY_ChatMonitor.uiFrame:append('Image_bg',"Image"):find('#Image_bg'):image('UI/Image/Minimap/Minimap2.UITex',8):size(300,300):click(fnOnTipClick)
    _MY_ChatMonitor.uiTest = _MY_ChatMonitor.uiFrame:append('WndWindow_Test','WndWindow'):child('#WndWindow_Test'):toggle(false)
    _MY_ChatMonitor.uiTipBoard = _MY_ChatMonitor.uiFrame:append('Handle_Tip',"Handle"):children('#Handle_Tip'):handleStyle(3):pos(10,10):size(230,130)

    _MY_ChatMonitor.uiTipBoard:append('Text1','Text'):find('#Text1'):text(_L['welcome to use mingyi chat monitor.']):click(fnOnTipClick)
    _MY_ChatMonitor.ShowTip()
end
_MY_ChatMonitor.RegisterMsgMonitor = function()
    local t = {}
    for szChannel, bCapture in pairs(MY_ChatMonitor.tChannels) do
        if bCapture then table.insert(t, szChannel) end
    end
    UnRegisterMsgMonitor(_MY_ChatMonitor.OnMsgArrive)
    RegisterMsgMonitor(_MY_ChatMonitor.OnMsgArrive, t)
end
MY_ChatMonitor.CopyChatLine = _MY_ChatMonitor.CopyChatLine
MY_ChatMonitor.RepeatChatLine = _MY_ChatMonitor.RepeatChatLine
MY_ChatMonitor.CopyChatItem = _MY_ChatMonitor.CopyChatItem
MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _MY_ChatMonitor.OnPanelActive, OnPanelDeactive = function() _MY_ChatMonitor.uiBoard = nil end } )
