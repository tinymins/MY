---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Sys = MY.Sys or {}
local _Cache, _L = {}, MY.LoadLangPack()

--[[ 获取游戏语言
]]
MY.Sys.GetLang = function()
    local _, _, lang = GetVersion()
    return lang
end
MY.GetLang = MY.Sys.GetLang

--[[
-- Save & Load Lua Data
#######################################################################################################
        #       #             #                           #                                       
    #   #   #   #             #     # # # # # #           #               # # # # # #             
        #       #             #     #         #   # # # # # # # # # # #     #     #   # # # #     
  # # # # # #   # # # #   # # # #   # # # # # #         #                   #     #     #   #     
      # #     #     #         #     #     #           #     # # # # #       # # # #     #   #     
    #   # #     #   #         #     # # # # # #       #           #         #     #     #   #     
  #     #   #   #   #         # #   #     #         # #         #           # # # #     #   #     
      #         #   #     # # #     # # # # # #   #   #   # # # # # # #     #     #     #   #     
  # # # # #     #   #         #     # #       #       #         #           #     # #     #       
    #     #       #           #   #   #       #       #         #         # # # # #       #       
      # #       #   #         #   #   # # # # #       #         #                 #     #   #     
  # #     #   #       #     # # #     #       #       #       # #                 #   #       #  
#######################################################################################################
]]
--[[ 保存数据文件
    MY.SaveLUAData( szFileUri, tData[, bNoDistinguishLang] )
    szFileUri           数据文件路径(1)
    tData               要保存的数据
    bNoDistinguishLang  是否取消自动区分客户端语言
    (1)： 当路径为绝对路径时(以斜杠开头)不作处理
          当路径为相对路径时 相对于插件下@DATA目录
]]
MY.Sys.SaveLUAData = function(szFileUri, tData, bNoDistinguishLang)
    -- 统一化目录分隔符
    szFileUri = string.gsub(szFileUri, '\\', '/')
    -- 如果是相对路径则从/@DATA/补全
    if string.sub(szFileUri, 1, 1)~='/' then
        szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
    end
    -- 统一后缀
    szFileUri = szFileUri .. '.MYDATA'
    -- 添加游戏语言后缀
    if not bNoDistinguishLang then
        local _, _, lang = GetVersion()
        lang = string.upper(lang)
        if #lang>0 then
            szFileUri = szFileUri .. '_' .. lang
        end
    end
    -- 调用系统API
    return SaveLUAData(szFileUri, tData)
end
MY.SaveLUAData = MY.Sys.SaveLUAData
--[[ 加载数据文件：相对于data文件夹
    MY.LoadLUAData( szFileUri[, bNoDistinguishLang] )
    szFileUri           数据文件路径(1)
    bNoDistinguishLang  是否取消自动区分客户端语言
    (1)： 当路径为绝对路径时(以斜杠开头)不作处理
          当路径为相对路径时 相对于插件下@DATA目录
]]
MY.Sys.LoadLUAData = function(szFileUri, bNoDistinguishLang)
    -- 统一化目录分隔符
    szFileUri = string.gsub(szFileUri, '\\', '/')
    -- 如果是相对路径则从/@DATA/补全
    if string.sub(szFileUri, 1, 1)~='/' then
        szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
    end
    -- 统一后缀
    szFileUri = szFileUri .. '.MYDATA'
    -- 添加游戏语言后缀
    if not bNoDistinguishLang then
        local _, _, lang = GetVersion()
        lang = string.upper(lang)
        if #lang>0 then
            szFileUri = szFileUri .. '_' .. lang
        end
    end
    -- 调用系统API
    return LoadLUAData(szFileUri)
end
MY.LoadLUAData = MY.Sys.LoadLUAData

--[[ 保存用户数据 注意要在游戏初始化之后使用不然没有ClientPlayer对象
    (data) MY.Sys.SaveUserData(szFileUri, tData)
]]
MY.Sys.SaveUserData = function(szFileUri, tData)
    return MY.Sys.SaveLUAData(szFileUri.."_"..(MY.Game.GetServer()).."_"..UI_GetClientPlayerID(), tData)
end

--[[ 加载用户数据 注意要在游戏初始化之后使用不然没有ClientPlayer对象
    (data) MY.Sys.LoadUserData(szFile [,szSubAddonName])
]]
MY.Sys.LoadUserData = function(szFileUri)
    return MY.Sys.LoadLUAData(szFileUri.."_"..(MY.Game.GetServer()).."_"..UI_GetClientPlayerID())
end

--szName [, szDataFile]
MY.RegisterUserData = function(szName, szFileName)
    
end

--[[ 播放声音
    MY.Sys.PlaySound(szFilePath[, szCustomPath])
    szFilePath   音频文件地址
    szCustomPath 个性化音频文件地址
    注：优先播放szCustomPath, szCustomPath不存在才会播放szFilePath
]]
MY.Sys.PlaySound = function(szFilePath, szCustomPath)
    szCustomPath = szCustomPath or szFilePath
    -- 统一化目录分隔符
    szCustomPath = string.gsub(szCustomPath, '\\', '/')
    -- 如果是相对路径则从/@Custom/补全
    if string.sub(szCustomPath, 1, 1)~='/' then szCustomPath = MY.GetAddonInfo().szRoot .. "@Custom/" .. szCustomPath end
    if IsFileExist(szCustomPath) then
        PlaySound(SOUND.UI_SOUND, szCustomPath)
    else
        -- 统一化目录分隔符
        szFilePath = string.gsub(szFilePath, '\\', '/')
        -- 如果是相对路径则从/@Custom/补全
        if string.sub(szFilePath, 1, 1)~='/' then szFilePath = MY.GetAddonInfo().szFrameworkRoot .. "audio/" .. szFilePath end
        PlaySound(SOUND.UI_SOUND, szFilePath)
    end
end
-- 加载注册数据
MY.RegisterInit(function()
    for v_name, v_data in pairs(MY.LoadLUAData('config/initalized_var') or {}) do
        local t = _G
        local k = MY.String.Split(v_name, '.')
        for i=1, #k-1 do
            if type(t[k[i]])=='nil' then
                t[k[i]] = {}
            end
            t = t[k[i]]
        end
        t[k[#k]] = v_data
    end
end)
--[[
-- Remote Request
#######################################################################################################
  # # # # # # # # # # #       #       #           #           #                     #     #       
  #                   #       #       # # # #       #   # # # # # # # #             #       #     
  #                   #     #       #       #                 #           # # # # # # # # # # #   
  # #       #       # #   #     # #   #   #               # # # # # #               #             
  #   #   #   #   #   #   # # #         #         # #         #             #       # #     #     
  #     #       #     #       #       #   #         #   # # # # # # # #       #     # #   #       
  #     #       #     #     #     # #       # #     #     #         #             # #   #         
  #   #   #   #   #   #   # # # #   # # # # #       #     # # # # # #           #   #   #         
  # #       #       # #             #       #       #     #         #         #     #     #       
  #                   #       # #   #       #       #     # # # # # #     # #       #       #     
  #                   #   # #       # # # # #       # #   #         #               #         #   
  #               # # #             #       #       #     #       # #             # #           
--#######################################################################################################
]]
_Cache.tRequest = {}      -- 网络请求队列
_Cache.bRequest = false   -- 网络请求繁忙中
--[[ (void) MY.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnSuccess, fnError, nTimeout)
    -- 格式化参数
    if type(szUrl)~="string" then return end
    if type(fnSuccess)~="function" then return end
    if type(fnError)~="function" then fnError = function(szUrl,errMsg) MY.Debug(szUrl..' - '..errMsg.."\n",'RemoteRequest',1) end end
    if type(nTimeout)~="number" then nTimeout = 10000 end
    -- 在请求队列尾部插入请求
    table.insert(_Cache.tRequest,{ szUrl = szUrl, fnSuccess = fnSuccess, fnError = fnError, nTimeout = nTimeout })
    -- 开始处理请求队列
    _Cache.DoRemoteRequest()
end
-- 处理远程请求队列
_Cache.DoRemoteRequest = function()
    -- 如果队列为空 则置队列状态为空闲并返回
    if table.getn(_Cache.tRequest)==0 then _Cache.bRequest = false MY.Debug('Remote Request Queue Is Clear.\n','MYRR',0) return end
    -- 如果当前队列有未处理的请求 并且远程请求队列处于空闲状态
    if not _Cache.bRequest then
        -- check if network plugins inited
        if not _Cache.hRequest then
            MY.DelayCall( _Cache.DoRemoteRequest, 3000 )
            MY.Debug('network plugin has not been initalized yet!\n','MYRR',1)
            _Cache.hRequest = MY.GetFrame():Lookup("Page_1")
            if _Cache.hRequest then
                -- web page complete
                _Cache.hRequest.OnDocumentComplete = function()
                    -- 判断是否有远程请求等待回调 没有则直接返回
                    if not _Cache.bRequest then return end
                    -- 处理回调
                    local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
                    -- 获取请求队列首部元素
                    local rr = _Cache.tRequest[1]
                    -- 判断当前页面是否符合请求
                    if szUrl ~= szTitle or szContent~="" then
                        -- 处理请求回调
                        MY.Debug(string.format("\n [RemoteRequest - OnDocumentComplete]\n [U] %s\n [T] %s\n", szUrl, szTitle),'MYRR',0)
                        -- 注销超时处理时钟
                        MY.DelayCall("MY_Remote_Request_Timeout")
                        -- 成功回调函数
                        pcall(rr.fnSuccess, szTitle, szContent)
                        -- 从请求列表移除
                        table.remove(_Cache.tRequest, 1)
                        -- 重置请求状态为空闲
                        _Cache.bRequest = false
                        -- 处理下一个远程请求
                        _Cache.DoRemoteRequest()
                    end
                end
            end
            return
        end
        -- 获取队列第一个元素
        local rr = _Cache.tRequest[1]
        -- 注册请求超时处理函数的时钟
        MY.DelayCall(function()
            -- debug
            MY.Debug('Remote Request Timeout.\n','MYRR',1)
            -- 请求超时 回调请求超时函数
            pcall(rr.fnError, rr.szUrl, "timeout")
            -- 从请求队列移除首元素
            table.remove(_Cache.tRequest, 1)
            -- 重置请求队列状态为空闲
            _Cache.bRequest = false
            -- 处理下一个远程请求
            _Cache.DoRemoteRequest()
        end,rr.nTimeout,"MY_Remote_Request_Timeout")
        -- 开始请求网络资源
        _Cache.hRequest:Navigate(rr.szUrl)
        -- 置请求队列状态为繁忙中
        _Cache.bRequest = true
    end
end

--[[
-- Breathe Call & Delay Call
#######################################################################################################
                    # #                     #       # # # # # # # #             #       #         
  # # # #   # # # #       # # # #           #                   #           #   #   #   #         
        #         #       #     #           #     #           #       #         #       #         
      #           #       #     #   # # # # # #   #   #     #     #   #   # # # # # #   # # # #   
    #       #     #       #     #           #     #     #   #   #     #       # #     #     #     
    # # #   #     # # #   # # # #           #     #         #         #     #   # #     #   #     
        #   #     #       #     #     #     #     #     #   #   #     #   #     #   #   #   #     
        #   #     #       #     #       #   #     #   #     #     #   #       #         #   #     
    #   #   #     #       #     #       #   #     #         #         #   # # # # #     #   #     
      #     # # # # # #   # # # #           #     #       # #         #     #     #       #       
    #   #                 #     #           #     #                   #       # #       #   #     
  #       # # # # # # #                 # # #     # # # # # # # # # # #   # #     #   #       #  
--#######################################################################################################
]]
_Cache.tDelayCall = {}    -- delay call 队列
_Cache.tBreatheCall = {}  -- breathe call 队列
--[[ 延迟调用
    (void) MY.DelayCall(func fnAction, number nDelay, string szName)
    fnAction    -- 调用函数
    nTime       -- 延迟调用时间，单位：毫秒，实际调用延迟延迟是 62.5 的整倍数
    szName      -- 延迟调用ID 用于取消调用
    取消调用
    (void) MY.DelayCall(string szName)
    szName      -- 延迟调用ID
]]
MY.DelayCall = function(arg0, arg1, arg2, arg3)
    local fnAction, nDelay, szName, param = nil, nil, nil, {}
    if type(arg0)=='function' then fnAction = arg0 end
    if type(arg1)=='function' then fnAction = arg1 end
    if type(arg2)=='function' then fnAction = arg2 end
    if type(arg3)=='function' then fnAction = arg3 end
    if type(arg0)=='string' then szName = arg0 end
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg3)=='string' then szName = arg3 end
    if type(arg0)=='number' then nDelay = arg0 end
    if type(arg1)=='number' then nDelay = arg1 end
    if type(arg2)=='number' then nDelay = arg2 end
    if type(arg3)=='number' then nDelay = arg3 end
    if type(arg0)=='table' then param = arg0 end
    if type(arg1)=='table' then param = arg1 end
    if type(arg2)=='table' then param = arg2 end
    if type(arg3)=='table' then param = arg3 end
    if not fnAction and not szName then return nil end
    
    if szName and nDelay and not fnAction then -- 调整DelayCall延迟时间
        for i = #_Cache.tDelayCall, 1, -1 do
            if _Cache.tDelayCall[i].szName == szName then
                _Cache.tDelayCall[i].nTime = nDelay + GetTime()
            end
        end
    else -- 一个新的DelayCall（或者覆盖原来的）
        if szName then
            for i = #_Cache.tDelayCall, 1, -1 do
                if _Cache.tDelayCall[i].szName == szName then
                    table.remove(_Cache.tDelayCall, i)
                end
            end
        end
        if fnAction and nDelay then
            table.insert(_Cache.tDelayCall, { nTime = nDelay + GetTime(), fnAction = fnAction, szName = szName, param = {} })
        end
    end
end
--[[ 注册呼吸循环调用函数
    (void) MY.BreatheCall(string szKey, func fnAction[, number nTime])
    szKey       -- 名称，必须唯一，重复则覆盖
    fnAction    -- 循环呼吸调用函数，设为 nil 则表示取消这个 key 下的呼吸处理函数
    nTime       -- 调用间隔，单位：毫秒，默认为 62.5，即每秒调用 16次，其值自动被处理成 62.5 的整倍数
]]
MY.BreatheCall = function(arg1, arg2, arg3, arg4)
    local fnAction, nInterval, szName, param = nil, nil, nil, {}
    if type(arg1)=='string' then szName = StringLowerW(arg1) end
    if type(arg2)=='string' then szName = StringLowerW(arg2) end
    if type(arg3)=='string' then szName = StringLowerW(arg3) end
    if type(arg4)=='string' then szName = StringLowerW(arg4) end
    if type(arg1)=='number' then nInterval = arg1 end
    if type(arg2)=='number' then nInterval = arg2 end
    if type(arg3)=='number' then nInterval = arg3 end
    if type(arg4)=='number' then nInterval = arg4 end
    if type(arg1)=='function' then fnAction = arg1 end
    if type(arg2)=='function' then fnAction = arg2 end
    if type(arg3)=='function' then fnAction = arg3 end
    if type(arg4)=='function' then fnAction = arg4 end
    if type(arg1)=='table' then param = arg1 end
    if type(arg2)=='table' then param = arg2 end
    if type(arg3)=='table' then param = arg3 end
    if type(arg4)=='table' then param = arg4 end
    if szName then
        for i = #_Cache.tBreatheCall, 1, -1 do
            if _Cache.tBreatheCall[i].szName == szName then
                table.remove(_Cache.tBreatheCall, i)
            end
        end
    end
    if fnAction then
        local nFrame = 1
        if nInterval and nInterval > 0 then
            nFrame = math.ceil(nInterval / 62.5)
        end
        table.insert( _Cache.tBreatheCall, { szName = szName, fnAction = fnAction, nNext = GetLogicFrameCount() + 1, nFrame = nFrame, param = param } )
    end
end
--[[ 改变呼吸调用频率
    (void) MY.BreatheCallDelay(string szKey, nTime)
    nTime       -- 延迟时间，每 62.5 延迟一帧
]]
MY.BreatheCallDelay = function(szKey, nTime)
    local t = _Cache.tBreatheCall[StringLowerW(szKey)]
    if t then
        t.nFrame = math.ceil(nTime / 62.5)
        t.nNext = GetLogicFrameCount() + t.nFrame
    end
end
--[[ 延迟一次呼吸函数的调用频率
    (void) MY.BreatheCallDelayOnce(string szKey, nTime)
    nTime       -- 延迟时间，每 62.5 延迟一帧
]]
MY.BreatheCallDelayOnce = function(szKey, nTime)
    local t = _Cache.tBreatheCall[StringLowerW(szKey)]
    if t then
        t.nNext = GetLogicFrameCount() + math.ceil(nTime / 62.5)
    end
end
-- breathe
MY.RegisterUIEvent(MY, "OnFrameBreathe", function()
    -- run breathe calls
    local nFrame = GetLogicFrameCount()
    for i = #_Cache.tBreatheCall, 1, -1 do
        if nFrame >= _Cache.tBreatheCall[i].nNext then
            local bc = _Cache.tBreatheCall[i]
            bc.nNext = nFrame + bc.nFrame
            local res, err = pcall(bc.fnAction, unpack(bc.param))
            if not res then
                MY.Debug("BreatheCall#" .. (bc.szName or ('anonymous_'..i)) .." ERROR: " .. err)
            elseif err == 0 then    -- function return 0 means to stop its breathe
                table.remove(_Cache.tBreatheCall, i)
            end
        end
    end
    -- run delay calls
    local nTime = GetTime()
    for i = #_Cache.tDelayCall, 1, -1 do
        local dc = _Cache.tDelayCall[i]
        if dc.nTime <= nTime then
            local res, err = pcall(dc.fnAction, unpack(dc.param))
            if not res then
                MY.Debug("DelayCall#" .. (dc.szName or 'anonymous') .." ERROR: " .. err)
            end
            table.remove(_Cache.tDelayCall, i)
        end
    end
end)

--[[
#######################################################################################################
              # # # #         #         #               #       #             #           #       
    # # # # #                 #           #       # # # # # # # # # # #         #       #         
          #                 #       # # # # # #         #       #           # # # # # # # # #     
        #         #       #     #       #                       # # #       #       #       #     
      # # # # # #         # # #       #     #     # # # # # # #             # # # # # # # # #     
            # #               #     #         #     #     #       #         #       #       #     
        # #         #       #       # # # # # #       #     #   #           # # # # # # # # #     
    # # # # # # # # # #   # # # #     #   #   #             #                       #             
            #         #               #   #       # # # # # # # # # # #   # # # # # # # # # # #   
      #     #     #           # #     #   #             #   #   #                   #             
    #       #       #     # #       #     #   #       #     #     #                 #             
  #       # #         #           #         # #   # #       #       # #             #         
#######################################################################################################
]]
_Cache.tPlayerMenu = {}   -- 玩家头像菜单
_Cache.tTargetMenu = {}   -- 目标头像菜单
_Cache.tTraceMenu  = {}   -- 工具栏菜单

-- get plugin folder menu
_Cache.GetMainMenu = function()
    return {
        szOption = _L["mingyi plugins"],
        fnAction = MY.TogglePanel,
        bCheck = true,
        bChecked = MY.GetFrame():IsVisible(),
        
        szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
        nFrame = 105, nMouseOverFrame = 106,
        szLayer = "ICON_RIGHT",
        fnClickIcon = MY.TogglePanel
    }
end
-- get player addon menu
_Cache.GetPlayerAddonMenu = function()
    -- 创建菜单
    local menu = _Cache.GetMainMenu()
    for i = 1, #_Cache.tPlayerMenu, 1 do
        local m = _Cache.tPlayerMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    return {menu}
end
-- get target addon menu
_Cache.GetTargetAddonMenu = function()
    local menu = {}
    for i = 1, #_Cache.tTargetMenu, 1 do
        local m = _Cache.tTargetMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    if #menu>1 then
        table.insert(menu, 1, { bDevide = true })
        table.insert(menu, { bDevide = true })
    end
    return menu
end
-- get trace button menu
_Cache.GetTraceButtonMenu = function()
    local menu = _Cache.GetMainMenu()
    for i = 1, #_Cache.tTraceMenu, 1 do
        local m = _Cache.tTraceMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    return {menu}
end
--[[ 注册玩家头像菜单
    -- 注册
    (void) MY.RegisterPlayerAddonMenu(szName,Menu)
    (void) MY.RegisterPlayerAddonMenu(Menu)
    -- 注销
    (void) MY.RegisterPlayerAddonMenu(szName)
]]
MY.RegisterPlayerAddonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_Cache.tPlayerMenu, 1, -1 do
            if _Cache.tPlayerMenu[i].szName == szName then
                _Cache.tPlayerMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_Cache.tPlayerMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_Cache.tPlayerMenu, 1, -1 do
            if _Cache.tPlayerMenu[i].szName == szName then
                table.remove(_Cache.tPlayerMenu, i)
            end
        end
    end
end
--[[ 注册目标头像菜单
    -- 注册
    (void) MY.RegisterTargetAddonMenu(szName,Menu)
    (void) MY.RegisterTargetAddonMenu(Menu)
    -- 注销
    (void) MY.RegisterTargetAddonMenu(szName)
]]
MY.RegisterTargetAddonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_Cache.tTargetMenu, 1, -1 do
            if _Cache.tTargetMenu[i].szName == szName then
                _Cache.tTargetMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_Cache.tTargetMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_Cache.tTargetMenu, 1, -1 do
            if _Cache.tTargetMenu[i].szName == szName then
                table.remove(_Cache.tTargetMenu, i)
            end
        end
    end
end
--[[ 注册工具栏菜单
    -- 注册
    (void) MY.RegisterTraceButtonMenu(szName,Menu)
    (void) MY.RegisterTraceButtonMenu(Menu)
    -- 注销
    (void) MY.RegisterTraceButtonMenu(szName)
]]
MY.RegisterTraceButtonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_Cache.tTraceMenu, 1, -1 do
            if _Cache.tTraceMenu[i].szName == szName then
                _Cache.tTraceMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_Cache.tTraceMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_Cache.tTraceMenu, 1, -1 do
            if _Cache.tTraceMenu[i].szName == szName then
                table.remove(_Cache.tTraceMenu, i)
            end
        end
    end
end

TraceButton_AppendAddonMenu( { _Cache.GetTraceButtonMenu } )
Player_AppendAddonMenu( { _Cache.GetPlayerAddonMenu } )
Target_AppendAddonMenu( { _Cache.GetTargetAddonMenu } )

--[[
#######################################################################################################
              # # # #         #         #             #         #                   #             
    # # # # #                 #           #           #       #   #         #       #       #     
          #                 #       # # # # # #   # # # #   #       #       #       #       #     
        #         #       #     #       #           #     #   # # #   #     #       #       #     
      # # # # # #         # # #       #     #     #   #                     # # # # # # # # #     
            # #               #     #         #   # # # # # # #       #             #             
        # #         #       #       # # # # # #       #   #   #   #   #             #             
    # # # # # # # # # #   # # # #     #   #   #       # # # # #   #   #   #         #         #   
            #         #               #   #       # # #   #   #   #   #   #         #         #   
      #     #     #           # #     #   #           #   # # #   #   #   #         #         #   
    #       #       #     # #       #     #   #       #   #   #       #   # # # # # # # # # # #   
  #       # #         #           #         # #       #   #   #     # #                       #   
#######################################################################################################
]]
--[[ 显示本地信息
    MY.Sysmsg(oContent, oTitle)
    szContent    要显示的主体消息
    szTitle      消息头部
    tContentRgbF 主体消息文字颜色rgbf[可选，为空使用默认颜色字体。]
    tTitleRgbF   消息头部文字颜色rgbf[可选，为空和主体消息文字颜色相同。]
]]
MY.Sysmsg = function(oContent, oTitle)
    oTitle = oTitle or MY.GetAddonInfo().szShortName
    if type(oTitle)~='table' then oTitle = { oTitle, bNoWrap = true } end
    if type(oContent)~='table' then oContent = { oContent, bNoWrap = true } end
    oContent.r, oContent.g, oContent.b, oContent.f = oContent.r or 255, oContent.g or 255, oContent.b or 0, oContent.f or 10

    for i = #oContent, 1, -1 do
        if type(oContent[i])=="number"  then oContent[i] = '' .. oContent[i] end
        if type(oContent[i])=="boolean" then oContent[i] = (oContent[i] and 'true') or 'false' end
        -- auto wrap each line
        if (not oContent.bNoWrap) and type(oContent[i])=="string" and string.sub(oContent[i], -1)~='\n' then
            oContent[i] = oContent[i] .. '\n'
        end
    end

    -- calc szMsg
    local szMsg = ''
    for i = 1, #oTitle, 1 do
        if oTitle[i]~='' then
            szMsg = szMsg .. '['..oTitle[i]..']'
        end
    end
    if #szMsg > 0 then
        szMsg = GetFormatText( szMsg..' ', oTitle.f or oContent.f, oTitle.r or oContent.r, oTitle.g or oContent.g, oTitle.b or oContent.b )
    end
    for i = 1, #oContent, 1 do
        szMsg = szMsg .. GetFormatText(oContent[i], oContent.f, oContent.r, oContent.g, oContent.b)
    end
    -- Output
    OutputMessage("MSG_SYS", szMsg, true)
end
--[[ Debug输出
    (void)MY.Debug(szText, szHead, nLevel)
    szText  Debug信息
    szHead  Debug头
    nLevel  Debug级别[低于当前设置值将不会输出]
]]
MY.Debug = function(szText, szHead, nLevel)
    if type(nLevel)~="number" then nLevel = 1 end
    if type(szHead)~="string" then szHead = 'MY DEBUG' end
    local oContent = { r=255, g=255, b=0 }
    if nLevel == 0 then
        oContent = { r=0,   g=255, b=127 }
    elseif nLevel == 1 then
        oContent = { r=255, g=170, b=170 }
    elseif nLevel == 2 then
        oContent = { r=255, g=86,  b=86  }
    end
    table.insert(oContent, szText)
    if nLevel >= MY.GetAddonInfo().nDebugLevel then
        MY.Sysmsg(oContent, szHead)
    end
end
