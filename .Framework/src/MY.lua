---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
MY = { }
--[[
#######################################################################################################
            #                 #         #           # # # # # # # #             #       #                   #               # # # # # # # # #     
            #                 #         #                       #           #   #   #   #         # # # # # # # # # # #     #       #       #     
  # # # # # # # # # # #       #     #   #   # #   #           #       #         #       #               #       #           #         #     #     
            #                 #     #   # #   #   #   #     #     #   #   # # # # # #   # # # #     #   #       #   #     # # # # # # # # # # #   
          # # #           # # # #   # # #     #   #     #   #   #     #       # #     #     #     #     #       #     #     #       #       #     
        #   #   #             #   # #   #     #   #         #         #     #   # #     #   #                               # # # # # # # # #     
        #   #   #             #     #   #     #   #     #   #   #     #   #     #   #   #   #       # # # # # # # #         #       #       #     
      #     #     #           #     #   #   # #   #   #     #     #   #       #         #   #         #           #         # # # # # # # # #     
    #       #       #         #     #   #         #         #         #   # # # # #     #   #           #       #                   #             
  #   # # # # # # #   #       # #   #         #   #       # #         #     #     #       #               # # #             # # # # # # # # #     
            #             # #       #         #   #                   #       # #       #   #         # #       # #                 #             
            #                         # # # # #   # # # # # # # # # # #   # #     #   #       #   # #               # #   # # # # # # # # # # #   
#######################################################################################################
]]
local _DEBUG_ = 0
local _BUILD_ = "20140712"
local _VERSION_ = 0x1000002
local _ADDON_ROOT_ = '\\Interface\\MY\\'
local _FRAMEWORK_ROOT_ = '\\Interface\\MY\\.Framework\\'

--[[ 多语言处理
    (table) MY.LoadLangPack(void)
]]
MY.LoadLangPack = function(szLangFolder)
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_.."lang\\default") or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_.."lang\\" .. szLang) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
    if type(szLangFolder)=="string" then
        szLangFolder = string.gsub(szLangFolder,"[/\\]+$","")
        local t2 = LoadLUAData(szLangFolder.."\\default") or {}
        for k, v in pairs(t2) do
            t0[k] = v
        end
        local t3 = LoadLUAData(szLangFolder.."\\" .. szLang) or {}
        for k, v in pairs(t3) do
            t0[k] = v
        end
    end
	setmetatable(t0, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t0
end
local _L = MY.LoadLangPack()
-----------------------------------------------
-- 私有函数
-----------------------------------------------
local _MY = {
    frame = nil,
    hBox = nil,
    hRequest = nil,
    bLoaded = false,
    dwVersion = _VERSION_,
    nDebugLevel = _DEBUG_,
    szBuildDate = _BUILD_,
    szName = _L["mingyi plugins"],
    szShortName = _L["mingyi plugin"],
    szIniFile = _FRAMEWORK_ROOT_.."ui\\MY.ini",
    szIniFileTabBox = _FRAMEWORK_ROOT_.."ui\\WndTabBox.ini",
    szIniFileMainPanel = _FRAMEWORK_ROOT_.."ui\\MainPanel.ini",
    
    tTabs = {},         -- 标签页
    tEvent = {},        -- 游戏事件绑定
    tInitFun = {},      -- 初始化函数
}
MY.GetAddonInfo = function()
    local t = {}
    t.szName      = _MY.szName
    t.szShortName = _MY.szShortName
    t.dwVersion   = _VERSION_
    t.szBuildDate = _BUILD_
    t.nDebugLevel = _DEBUG_
    t.szRoot      = _ADDON_ROOT_
    t.szFrameworkRoot = _FRAMEWORK_ROOT_
    return t
end
_MY.Init = function()
    if _MY.bLoaded then return end
	-- var
    _MY.bLoaded = true
	_MY.hBox = MY.GetFrame():Lookup("","Box_1")
	_MY.hRequest = MY.GetFrame():Lookup("Page_1")
    -- 窗口按钮
    MY.UI(MY.GetFrame()):find("#Button_WindowClose"):click(function() MY.ClosePanel() end)
    -- 重绘选项卡
    MY.RedrawTabPanel()
    -- init functions
    for i = 1, #_MY.tInitFun, 1 do
        pcall(_MY.tInitFun[i].fn)
    end

    -- 显示欢迎信息
    MY.Sysmsg({_L("%s, welcome to use mingyi plugins!", GetClientPlayer().szName) .. " v" .. MY.GetVersion() .. ' Build ' .. _MY.szBuildDate})
    if _MY.nDebugLevel >=3 then
        _MY.frame:Hide()
    else
        _MY.frame:Show()
    end
end

--[[
#######################################################################################################
    # # # # # # # # #                                                         #           #       
    #       #       #     # # # # # # # # # # #     # # # # # # # # #           #       #         
    # # # # # # # # #               #                   #       #                                 
    #       #       #             #                     #       #           # # # # # # # # #     
    # # # # # # # # #       # # # # # # # # # #         #       #                   #             
            #               #     #     #     #         #       #                   #             
        # #   # #           #     # # # #     #   # # # # # # # # # # #   # # # # # # # # # # #   
  # # #           # # #     #     #     #     #         #       #                   #             
        #       #           #     # # # #     #         #       #                 #   #           
        #       #           #     #     #     #       #         #               #       #         
      #         #           # # # # # # # # # #       #         #             #           #       
    #           #           #                 #     #           #         # #               # #   
#######################################################################################################
]]
-- close window
MY.ClosePanel = function(bRealClose)
	local frame = MY.GetFrame()
	if frame then
		if not bRealClose then
			frame:Hide()
		else
			Wnd.CloseWindow(frame)
			_MY.frame = nil
		end
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end
-- open window
MY.OpenPanel = function()
    local frame = MY.GetFrame()
    if frame then
        frame:Show()
        frame:BringToTop()
    end
end
-- toggle panel
MY.TogglePanel = function()
    local frame = MY.GetFrame()
    if frame and frame:IsVisible() then
        frame:Hide()
    elseif frame then
        frame:Show()
        frame:BringToTop()
    end
end

--[[ 获取主窗体句柄
    (frame) MY.GetFrame()
]]
MY.GetFrame = function()
    if not _MY.frame then
        _MY.frame = Wnd.OpenWindow(_MY.szIniFile, "MY")
        _MY.frame:Hide()
    end
    return _MY.frame
end

-- (string, number) MY.GetVersion()     -- HM的 获取字符串版本号 修改方便拿过来了
MY.GetVersion = function()
    local v = _MY.dwVersion
    local szVersion = string.format("%d.%d.%d", v/0x1000000,
        math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
    if  v%0x100 ~= 0 then
        szVersion = szVersion .. "b" .. tostring(v%0x100)
    end
    return szVersion, v
end
--[[
#######################################################################################################
            #                 #         #                   #                                     
  # # # # # # # # # # #       #   #     #         #           #             # # # #   # # # #     
      #     #     #         #     #     #           #                       #     #   #     #     
      # # # # # # #         #     # # # # # # #         # # # # # # #       #     #   #     #     
            #             # #   #       #                     #             #     #   #     #     
    # # # # # # # # #       #           #         #           #             #     #   #     #     
            #       #       #           #           #         #           # # # # # # # # # # #   
  # # # # # # # # # # #     #   # # # # # # # #         # # # # # # #       #     #   #     #     
            #       #       #           #                     #             #     #   #     #     
    # # # # # # # # #       #           #           #         #             #     #   #     #     
            #               #           #         #           #             #     #   #     #     
          # #               #           #             # # # # # # # # #   #     # # #     # #     
#######################################################################################################
]]
--[[ 注册初始化函数
    RegisterInit(string szFunName, function fn) -- 注册
    RegisterInit(function fn)                   -- 注册
    RegisterInit(string szFunName)              -- 注销
]]
MY.RegisterInit = function(arg1, arg2)
    local szFunName, fn
    if type(arg1)=='function' then fn = arg1 end
    if type(arg1)=='string'   then szFunName = arg1 end
    if type(arg2)=='function' then fn = arg1 end
    if type(arg2)=='string'   then szFunName = arg1 end
    if fn then
        if szFunName then
            for i = #_MY.tInitFun, 1, -1 do
                if _MY.tInitFun[i].szFunName == szFunName then
                    _MY.tInitFun[i] = { szFunName = szFunName, fn = fn }
                    return nil
                end
            end
        end
        table.insert(_MY.tInitFun, { szFunName = szFunName, fn = fn })
    elseif szFunName then
        for i = #_MY.tInitFun, 1, -1 do
            if _MY.tInitFun[i].szFunName == szFunName then
                table.remove(_MY.tInitFun, i)
            end
        end
    end
end
--[[ 注册游戏事件监听
    -- 注册
    MY.RegisterEvent( szEventName, szListenerId, fnListener )
    MY.RegisterEvent( szEventName, fnListener )
    -- 注销
    MY.RegisterEvent( szEventName, szListenerId )
    MY.RegisterEvent( szEventName )
 ]]
MY.RegisterEvent = function(szEventName, arg1, arg2)
    local szListenerId, fnListener
    -- param check
    if type(szEventName)~="string" then return end
    if type(arg1)=="function" then fnListener=arg1 elseif type(arg1)=="string" then szListenerId=arg1 end
    if type(arg2)=="function" then fnListener=arg2 elseif type(arg2)=="string" then szListenerId=arg2 end
    if fnListener then -- register event
        -- 第一次添加注册系统事件
        if type(_MY.tEvent[szEventName])~="table" then
            _MY.tEvent[szEventName] = {}
            RegisterEvent(szEventName, function(...)
                local param = {}
                for i = 0, 100, 1 do
                    if _G['arg'..i] then
                        table.insert(param, _G['arg'..i])
                    else
                        break
                    end
                end
                for i = #_MY.tEvent[szEventName], 1, -1 do
                    local hEvent = _MY.tEvent[szEventName][i]
                    if type(hEvent.fn)=="function" then
                        -- try to run event function
                        local status, err = pcall(hEvent.fn, unpack(param))
                        -- error report
                        if not status then MY.Debug(err..'\n', 'OnEvent#'..szEventName, 2) end
                    else
                        -- remove none function event
                        table.remove(_MY.tEvent[szEventName], i)
                        -- report error
                        MY.Debug((hEvent.szName or 'id:anonymous')..' is not a function.\n', 'OnEvent#'..szEventName, 2)
                    end
                end
            end)
        end
        -- 往事件数组中添加
        table.insert( _MY.tEvent[szEventName], { fn = fnListener, szName = szListenerId } )
    elseif szListenerId and _MY.tEvent[szEventName] then -- unregister event handle by id
        for i = #_MY.tEvent[szEventName], 1, -1 do
            if _MY.tEvent[szEventName][i].szName == fnListener then
                table.remove(_MY.tEvent[szEventName], i)
            end
        end
    elseif szEventName and _MY.tEvent[szEventName] then -- unregister all event handle
        _MY.tEvent[szEventName] = {}
    end
end
--[[
#######################################################################################################
    #           #                 # # # # # # #           #               
      #     #   #         # # #         #                 #               
            # # # # #       #         #                   # # # # # #     
          #     #           #     # # # # # # #           #               
  # # #         #           #     #           #           #               
      #   # # # # # # #     #     #     #     #   # # # # # # # # # # #   
      #       #   #         #     #     #     #           #               
      #       #   #         #     #     #     #           # # #           
      #     #     #   #     # #   #     #     #           #     # #       
      #   #         # #   #           #   #               #         #     
    #   #                           #       #             #               
  #       # # # # # # #         # #           #           #               
#######################################################################################################
]]
--[[ 重绘Tab窗口 ]]
MY.RedrawTabPanel = function()
    local nTop = 3
    local frame = MY.GetFrame():Lookup("Window_Tabs"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    for i = 1, #_MY.tTabs, 1 do
        local tTab = _MY.tTabs[i]
        -- insert tab
        local fx = Wnd.OpenWindow(_MY.szIniFileTabBox, "aTabBox")
        if fx then
            local item = fx:Lookup("TabBox")
            if item then
                item:ChangeRelation(MY.GetFrame():Lookup("Window_Tabs"), true, true)
                item:SetName("TabBox_" .. tTab.szName)
                item:SetRelPos(0,nTop)
                item:Lookup("","Text_TabBox_Title"):SetText(tTab.szTitle)
                item:Lookup("","Text_TabBox_Title"):SetFontColor(unpack(tTab.rgbTitleColor))
                item:Lookup("","Text_TabBox_Title"):SetAlpha(tTab.alpha)
                if tTab.dwIconFrame then
                    item:Lookup("","Image_TabBox_Icon"):FromUITex(tTab.szIconTex, tTab.dwIconFrame)
                else
                    item:Lookup("","Image_TabBox_Icon"):FromTextureFile(tTab.szIconTex)
                end
                local w,h = item:GetSize()
                nTop = nTop + h
            end
            -- register tab mouse event
            item.OnMouseEnter = function()
                this:Lookup("","Image_TabBox_Background"):Hide()
                this:Lookup("","Image_TabBox_Background_Hover"):Show()
            end
            item.OnMouseLeave = function()
                this:Lookup("","Image_TabBox_Background"):Show()
                this:Lookup("","Image_TabBox_Background_Hover"):Hide()
            end
            item.OnLButtonDown = function()
                if this:Lookup("","Image_TabBox_Background_Sel"):IsVisible() then return end
                PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
                local p = this:GetParent():GetFirstChild()
                while p do
                    p:Lookup("","Image_TabBox_Background_Sel"):Hide()
                    p = p:GetNext()
                end
                this:Lookup("","Image_TabBox_Background_Sel"):Show()
                local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
                while frame do
                    if frame.fn.OnPanelDeactive then
                        local status, err = pcall(frame.fn.OnPanelDeactive, frame)
                        if not status then MY.Debug(err..'\n','MY#OnPanelDeactive',1) end
                    end
                    frame:Destroy()
                    frame = frame:GetNext()
                end
                -- insert main panel
                local fx = Wnd.OpenWindow(_MY.szIniFileMainPanel, "aMainPanel")
                local mainpanel
                if fx then
                    mainpanel = fx:Lookup("MainPanel")
                    if mainpanel then
                        mainpanel:ChangeRelation(MY.GetFrame():Lookup("Window_Main"), true, true)
                        mainpanel:SetRelPos(0,0)
                        mainpanel.fn = tTab.fn
                    end
                end
                Wnd.CloseWindow(fx)
                if tTab.fn.OnPanelActive then
                    local status, err = pcall(tTab.fn.OnPanelActive, mainpanel)
                    if not status then MY.Debug(err..'\n','MY#OnPanelActive',1) end
                end
            end
        end
        Wnd.CloseWindow(fx)
    end
end
--[[ 注册选项卡
    (void) MY.RegisterPanel( szName, szTitle, szIniFile, szIconTex, rgbaTitleColor, fn )
    szName          选项卡唯一ID
    szTitle         选项卡按钮标题
    szIconTex       选项卡图标文件|图标帧
    rgbaTitleColor  选项卡文字rgba
    fn              选项卡各种响应函数 {
        fn.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
        fn.OnPanelDeactive(wnd)    选项卡取消激活
    }
    Ex： MY.RegisterPanel( "Test", "测试标签", "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, { OnPanelActive = function(wnd) end } )
 ]]
MY.RegisterPanel = function( szName, szTitle, szIconTex, rgbaTitleColor, fn )
    if szTitle == nil then
        for i = #_MY.tTabs, 1, -1 do
            if _MY.tTabs[i].szName == szName then
                table.remove(_MY.tTabs, i)
            end
        end
    else
        -- format szIconTex
        if type(szIconTex)~="string" then szIconTex = 'UI/Image/Common/Logo.UITex|6' end
        local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
        if dwIconFrame then dwIconFrame = tonumber(dwIconFrame) end
        szIconTex = string.gsub(szIconTex, '%|.*', '')

        -- format other params
        if type(fn)~="table" then fn = {} end
        if type(rgbaTitleColor)~="table" then rgbaTitleColor = { 255, 255, 255, 200 } end
        if type(rgbaTitleColor[1])~="number" then rgbaTitleColor[1] = 255 end
        if type(rgbaTitleColor[2])~="number" then rgbaTitleColor[2] = 255 end
        if type(rgbaTitleColor[3])~="number" then rgbaTitleColor[3] = 255 end
        if type(rgbaTitleColor[4])~="number" then rgbaTitleColor[4] = 200 end
        table.insert( _MY.tTabs, { szName = szName, szTitle = szTitle, fn = fn, szIconTex = szIconTex, dwIconFrame = dwIconFrame, rgbTitleColor = {rgbaTitleColor[1],rgbaTitleColor[2],rgbaTitleColor[3]}, alpha = rgbaTitleColor[4] } )
    end
    MY.RedrawTabPanel()
end
--[[ 激活选项卡
    (void) MY.ActivePanel( szName )
    szName          选项卡唯一ID
]]
MY.ActivePanel = function( szName )
    local eTab = MY.GetFrame():Lookup("Window_Tabs"):Lookup('TabBox_'..szName)
    if not eTab then return end
    local _this = this
    this = eTab
    pcall(eTab.OnLButtonDown)
    this = _this
end

--[[
#######################################################################################################
            #                                       # # # # # # # #             #       #         
  # # # # # # # # # # #     # # # # # # # # #                   #           #   #   #   #         
  #     #       #     #     #               #     #           #       #         #       #         
      #     #     #         #               #     #   #     #     #   #   # # # # # #   # # # #   
          #                 #               #     #     #   #   #     #       # #     #     #     
    # # # # # # # # #       #               #     #         #         #     #   # #     #   #     
    #     #         #       #               #     #     #   #   #     #   #     #   #   #   #     
    #   # # # # #   #       #               #     #   #     #     #   #       #         #   #     
    # # #     #     #       #               #     #         #         #   # # # # #     #   #     
    #     # #       #       # # # # # # # # #     #       # #         #     #     #       #       
    #   #     #     #       #               #     #                   #       # #       #   #     
    # # # # # # # # #                             # # # # # # # # # # #   # #     #   #       #   
#######################################################################################################
]]
-- 绑定UI事件
MY.RegisterUIEvent = function(raw, szEvent, fnEvent)
    if not raw['tMy'..szEvent] then
        raw['tMy'..szEvent] = { raw[szEvent] }
        raw[szEvent] = function()
            for _, fn in ipairs(raw['tMy'..szEvent]) do pcall(fn) end
        end
    end
    if fnEvent then table.insert(raw['tMy'..szEvent], fnEvent) end
end
-- create frame
MY.OnFrameCreate = function()
end
MY.OnMouseWheel = function()
    MY.Debug(string.format('OnMouseWheel#%s.%s:%i\n',this:GetName(),this:GetType(),Station.GetMessageWheelDelta()),nil,0)
    return true
end
-- key down
MY.OnFrameKeyDown = function()
	if GetKeyName(Station.GetMessageKey()) == "Esc" then
		MY.ClosePanel()
		return 1
	end
	return 0
end
---------------------------------------------------
---------------------------------------------------
-- 事件、快捷键、菜单注册



if _MY.nDebugLevel <3 then RegisterEvent("CALL_LUA_ERROR", function() OutputMessage("MSG_SYS", arg0) end) end

-- MY.RegisterEvent("CUSTOM_DATA_LOADED", _MY.Init)
MY.RegisterEvent("LOADING_END", _MY.Init)

-- MY.RegisterEvent("PLAYER_ENTER_GAME", _MY.Init)
