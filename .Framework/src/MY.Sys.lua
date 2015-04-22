--------------------------------------------
-- @Desc  : 茗伊插件 - 系统函数库
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-04-22 13:43:50
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
MY = MY or {}
MY.Sys = MY.Sys or {}
MY.Sys.bShieldedVersion = false -- 屏蔽被河蟹的功能（国服启用）
local _L, _C = MY.LoadLangPack(), {}

-- 获取游戏语言
MY.Sys.GetLang = function()
	local _, _, lang = GetVersion()
	return lang
end
MY.GetLang = MY.Sys.GetLang

-- 获取功能屏蔽状态
pcall(function()
	if MY.Sys.GetLang() == 'zhcn' then
		MY.Sys.bShieldedVersion = true
	end
end)
MY.Sys.IsShieldedVersion = function()
	return MY.Sys.bShieldedVersion
end
MY.IsShieldedVersion = MY.Sys.IsShieldedVersion

_C.nFrameCount = 0
MY.Sys.GetFrameCount = function()
	return _C.nFrameCount
end
MY.GetFrameCount = MY.Sys.GetFrameCount

-- Save & Load Lua Data
-- ##################################################################################################
--         #       #             #                           #                                       
--     #   #   #   #             #     # # # # # #           #               # # # # # #             
--         #       #             #     #         #   # # # # # # # # # # #     #     #   # # # #     
--   # # # # # #   # # # #   # # # #   # # # # # #         #                   #     #     #   #     
--       # #     #     #         #     #     #           #     # # # # #       # # # #     #   #     
--     #   # #     #   #         #     # # # # # #       #           #         #     #     #   #     
--   #     #   #   #   #         # #   #     #         # #         #           # # # #     #   #     
--       #         #   #     # # #     # # # # # #   #   #   # # # # # # #     #     #     #   #     
--   # # # # #     #   #         #     # #       #       #         #           #     # #     #       
--     #     #       #           #   #   #       #       #         #         # # # # #       #       
--       # #       #   #         #   #   # # # # #       #         #                 #     #   #     
--   # #     #   #       #     # # #     #       #       #       # #                 #   #       #   
-- ##################################################################################################
-- 保存数据文件
-- MY.SaveLUAData( szFileUri, tData[, bNoDistinguishLang] )
-- szFileUri           数据文件路径(1)
-- tData               要保存的数据
-- bNoDistinguishLang  是否取消自动区分客户端语言
-- (1)： 当路径为绝对路径时(以斜杠开头)不作处理
--       当路径为相对路径时 相对于插件下@DATA目录
MY.Sys.SaveLUAData = function(szFileUri, tData, bNoDistinguishLang)
	local nStartTick = GetTickCount()
	-- 统一化目录分隔符
	szFileUri = string.gsub(szFileUri, '\\', '/')
	-- 如果是相对路径则从/@DATA/补全
	if string.sub(szFileUri, 1, 1)~='/' then
		szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
	end
	-- 添加游戏语言后缀
	if not bNoDistinguishLang then
		local lang = string.lower(MY.Sys.GetLang())
		if #lang > 0 then
			if string.sub(szFileUri, -1) ~= '/' then
				szFileUri = szFileUri .. "."
			end
			szFileUri = szFileUri .. lang
		end
	end
	if MY.Sys.GetLang() == 'vivn' then
		szFileUri = szFileUri .. '.jx3dat'
	end
	-- 调用系统API
	local ret = SaveLUAData(szFileUri, tData)
	-- performance monitor
	MY.Debug({_L('%s saved during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', 0)
	return ret
end
MY.SaveLUAData = MY.Sys.SaveLUAData

-- 加载数据文件：相对于data文件夹
-- MY.LoadLUAData( szFileUri[, bNoDistinguishLang] )
-- szFileUri           数据文件路径(1)
-- bNoDistinguishLang  是否取消自动区分客户端语言
-- (1)： 当路径为绝对路径时(以斜杠开头)不作处理
--       当路径为相对路径时 相对于插件下@DATA目录
MY.Sys.LoadLUAData = function(szFileUri, bNoDistinguishLang)
	local nStartTick = GetTickCount()
	-- 统一化目录分隔符
	szFileUri = string.gsub(szFileUri, '\\', '/')
	-- 如果是相对路径则从/@DATA/补全
	if string.sub(szFileUri, 1, 1)~='/' then
		szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
	end
	-- 添加游戏语言后缀
	if not bNoDistinguishLang then
		local lang = string.lower(MY.Sys.GetLang())
		if #lang > 0 then
			if string.sub(szFileUri, -1) ~= '/' then
				szFileUri = szFileUri .. "."
			end
			szFileUri = szFileUri .. lang
		end
	end
	if MY.Sys.GetLang() == 'vivn' then
		szFileUri = szFileUri .. '.jx3dat'
	end
	-- 调用系统API
	local ret = LoadLUAData(szFileUri)
	-- performance monitor
	MY.Debug({_L('%s loaded during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', 0)
	return ret
end
MY.LoadLUAData = MY.Sys.LoadLUAData

-- 保存用户数据 注意要在游戏初始化之后使用不然没有ClientPlayer对象
-- (data) MY.Sys.SaveUserData(szFileUri, tData)
MY.Sys.SaveUserData = function(szFileUri, tData)
	-- 统一化目录分隔符
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- 添加用户识别字符
	szFileUri = szFileUri .. MY.Player.GetUUID()
	-- 读取数据
	return MY.Sys.SaveLUAData(szFileUri, tData)
end
MY.SaveUserData = MY.Sys.SaveUserData

-- 加载用户数据 注意要在游戏初始化之后使用不然没有ClientPlayer对象
-- (data) MY.Sys.LoadUserData(szFile [,szSubAddonName])
MY.Sys.LoadUserData = function(szFileUri)
	-- 统一化目录分隔符
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- 添加用户识别字符
	szFileUri = szFileUri .. MY.Player.GetUUID()
	-- 读取数据
	return MY.Sys.LoadLUAData(szFileUri)
end
MY.LoadUserData = MY.Sys.LoadUserData

--szName [, szDataFile]
MY.RegisterUserData = function(szName, szFileName)
	
end

-- 播放声音
-- MY.Sys.PlaySound(szFilePath[, szCustomPath])
-- szFilePath   音频文件地址
-- szCustomPath 个性化音频文件地址
-- 注：优先播放szCustomPath, szCustomPath不存在才会播放szFilePath
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
	for v_name, v_data in pairs(MY.LoadLUAData('config/initial') or {}) do
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

-- ##################################################################################################
--   # # # # # # # # # # #       #       #           #           #                     #     #       
--   #                   #       #       # # # #       #   # # # # # # # #             #       #     
--   #                   #     #       #       #                 #           # # # # # # # # # # #   
--   # #       #       # #   #     # #   #   #               # # # # # #               #             
--   #   #   #   #   #   #   # # #         #         # #         #             #       # #     #     
--   #     #       #     #       #       #   #         #   # # # # # # # #       #     # #   #       
--   #     #       #     #     #     # #       # #     #     #         #             # #   #         
--   #   #   #   #   #   #   # # # #   # # # # #       #     # # # # # #           #   #   #         
--   # #       #       # #             #       #       #     #         #         #     #     #       
--   #                   #       # #   #       #       #     # # # # # #     # #       #       #     
--   #                   #   # #       # # # # #       # #   #         #               #         #   
--   #               # # #             #       #       #     #       # #             # #             
-- ##################################################################################################
-- (void) MY.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnSuccess, fnError, nTimeout)
	if not (type(szUrl) == "string" and type(fnSuccess) == "function") then
		return
	end
	if type(nTimeout)~="number" then
		nTimeout = 10000
	end
	if type(fnError)~="function" then
		fnError = function(szUrl, errMsg)
			MY.Debug({szUrl .. ' - ' .. errMsg}, 'RemoteRequest', 1)
		end
	end
	
	-- append new page
	local RequestID = ("%X_%X"):format(GetTickCount(), math.floor(math.random() * 65536))
	local uiPages = MY.UI(MY.GetFrame()):children('#Wnd_Pages')
	local hPage = uiPages:append('WndWebPage', 'WndWebPage_' .. RequestID):children('#' .. 'WndWebPage_' .. RequestID):raw(1)
	
	-- bind callback function
	hPage.OnDocumentComplete = function()
		local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
		if szUrl ~= szTitle or szContent ~= "" then
			MY.Debug({string.format("%s - %s", szTitle, szUrl)}, 'MYRR::OnDocumentComplete', 0)
			-- 注销超时处理时钟
			MY.DelayCall("MYRR_TO_" .. RequestID)
			-- 成功回调函数
			local status, err = pcall(fnSuccess, szTitle, szContent)
			if not status then
				MY.Debug({err}, 'MYRR::OnDocumentComplete::Callback', 3)
			end
			hPage:Destroy()
		end
	end
	
	-- do with this remote request
	MY.Debug({szUrl}, 'MYRR', 0)
	-- register request timeout clock
	MY.DelayCall(function()
		MY.Debug({szUrl}, 'MYRR::Timeout', 1) -- log
		-- request timeout, call timeout function.
		local status, err = pcall(fnError, szUrl, "timeout")
		if not status then
			MY.Debug({err}, 'MYRR::TIMEOUT', 3)
		end
		hPage:Destroy()
	end, nTimeout, "MYRR_TO_" .. RequestID)
	
	-- start ie navigate
	local WndFocus = Station.GetFocusWindow()
	hPage:Navigate(szUrl)
	Station.SetFocusWindow(WndFocus)
end

-- Breathe Call & Delay Call
-- ##################################################################################################
--                     # #                     #       # # # # # # # #             #       #         
--   # # # #   # # # #       # # # #           #                   #           #   #   #   #         
--         #         #       #     #           #     #           #       #         #       #         
--       #           #       #     #   # # # # # #   #   #     #     #   #   # # # # # #   # # # #   
--     #       #     #       #     #           #     #     #   #   #     #       # #     #     #     
--     # # #   #     # # #   # # # #           #     #         #         #     #   # #     #   #     
--         #   #     #       #     #     #     #     #     #   #   #     #   #     #   #   #   #     
--         #   #     #       #     #       #   #     #   #     #     #   #       #         #   #     
--     #   #   #     #       #     #       #   #     #         #         #   # # # # #     #   #     
--       #     # # # # # #   # # # #           #     #       # #         #     #     #       #       
--     #   #                 #     #           #     #                   #       # #       #   #     
--   #       # # # # # # #                 # # #     # # # # # # # # # # #   # #     #   #       #   
-- ##################################################################################################
_C.nLogicFrameCount = GetLogicFrameCount()
_C.tDelayCall = {}    -- delay call 队列
_C.tBreatheCall = {}  -- breathe call 队列

-- 延迟调用
-- (void) MY.DelayCall(func fnAction, number nDelay, string szName)
-- fnAction    -- 调用函数
-- nTime       -- 延迟调用时间，单位：毫秒，实际调用延迟延迟是 62.5 的整倍数
-- szName      -- 延迟调用ID 用于取消调用
-- 取消调用
-- (void) MY.DelayCall(string szName)
-- szName      -- 延迟调用ID
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
		for i = #_C.tDelayCall, 1, -1 do
			if _C.tDelayCall[i].szName == szName then
				_C.tDelayCall[i].nTime = nDelay + GetTime()
			end
		end
	else -- 一个新的DelayCall（或者覆盖原来的）
		if szName then
			for i = #_C.tDelayCall, 1, -1 do
				if _C.tDelayCall[i].szName == szName then
					table.remove(_C.tDelayCall, i)
				end
			end
		end
		if fnAction then
			if not nDelay then
				nDelay = 1000 / GLOBAL.GAME_FPS
			end
			table.insert(_C.tDelayCall, { nTime = nDelay + GetTime(), fnAction = fnAction, szName = szName, param = {} })
		end
	end
end

-- 注册呼吸循环调用函数
-- (void) MY.BreatheCall(string szKey, func fnAction[, number nTime])
-- szKey       -- 名称，必须唯一，重复则覆盖
-- fnAction    -- 循环呼吸调用函数，设为 nil 则表示取消这个 key 下的呼吸处理函数
-- nTime       -- 调用间隔，单位：毫秒，默认为 62.5，即每秒调用 16次，其值自动被处理成 62.5 的整倍数
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
		for i = #_C.tBreatheCall, 1, -1 do
			if _C.tBreatheCall[i].szName == szName then
				table.remove(_C.tBreatheCall, i)
			end
		end
	end
	if fnAction then
		local nFrame = 1
		if nInterval and nInterval > 0 then
			nFrame = math.ceil(nInterval / 62.5)
		end
		table.insert( _C.tBreatheCall, { szName = szName, fnAction = fnAction, nNext = GetLogicFrameCount() + 1, nFrame = nFrame, param = param } )
	end
end

-- 改变呼吸调用频率
-- (void) MY.BreatheCallDelay(string szKey, nTime)
-- nTime       -- 延迟时间，每 62.5 延迟一帧
MY.BreatheCallDelay = function(szKey, nTime)
	for _, t in ipairs(_C.tBreatheCall) do
		if t.szName == StringLowerW(szKey) then
			t.nFrame = math.ceil(nTime / 62.5)
			t.nNext = GetLogicFrameCount() + t.nFrame
		end
	end
end

-- 延迟一次呼吸函数的调用频率
-- (void) MY.BreatheCallDelayOnce(string szKey, nTime)
-- nTime       -- 延迟时间，每 62.5 延迟一帧
MY.BreatheCallDelayOnce = function(szKey, nTime)
	for _, t in ipairs(_C.tBreatheCall) do
		if t.szName == StringLowerW(szKey) then
			t.nNext = GetLogicFrameCount() + math.ceil(nTime / 62.5)
		end
	end
end

-- breathe
MY.UI.RegisterUIEvent(MY, "OnFrameBreathe", function()
	-- add frame counter
	_C.nLogicFrameCount = GetLogicFrameCount()
	_C.nFrameCount = _C.nFrameCount + 1
	-- run breathe calls
	local nFrame = _C.nLogicFrameCount
	for i = #_C.tBreatheCall, 1, -1 do
		if nFrame >= _C.tBreatheCall[i].nNext then
			local bc = _C.tBreatheCall[i]
			bc.nNext = nFrame + bc.nFrame
			local res, err = pcall(bc.fnAction, unpack(bc.param))
			if not res then
				MY.Debug({"BreatheCall#" .. (bc.szName or ('anonymous_'..i)) .." ERROR: " .. err})
			elseif err == 0 then    -- function return 0 means to stop its breathe
				for i = #_C.tBreatheCall, 1, -1 do
					if _C.tBreatheCall[i] == bc then
						table.remove(_C.tBreatheCall, i)
					end
				end
			end
		end
	end
	-- run delay calls
	local nTime = GetTime()
	for i = #_C.tDelayCall, 1, -1 do
		local dc = _C.tDelayCall[i]
		if dc.nTime <= nTime then
			local res, err = pcall(dc.fnAction, unpack(dc.param))
			if not res then
				MY.Debug({"DelayCall#" .. (dc.szName or 'anonymous') .." ERROR: " .. err})
			end
			table.remove(_C.tDelayCall, i)
		end
	end
end)

-- GetLogicFrameCount()过图修正
MY.RegisterEvent('LOADING_END', function()
	local nFrameOffset = GetLogicFrameCount() - _C.nLogicFrameCount
	_C.nLogicFrameCount = GetLogicFrameCount()
	for _, bc in ipairs(_C.tBreatheCall) do
		bc.nNext = bc.nNext + nFrameOffset
	end
end)

-- ##################################################################################################
--               # # # #         #         #               #       #             #           #       
--     # # # # #                 #           #       # # # # # # # # # # #         #       #         
--           #                 #       # # # # # #         #       #           # # # # # # # # #     
--         #         #       #     #       #                       # # #       #       #       #     
--       # # # # # #         # # #       #     #     # # # # # # #             # # # # # # # # #     
--             # #               #     #         #     #     #       #         #       #       #     
--         # #         #       #       # # # # # #       #     #   #           # # # # # # # # #     
--     # # # # # # # # # #   # # # #     #   #   #             #                       #             
--             #         #               #   #       # # # # # # # # # # #   # # # # # # # # # # #   
--       #     #     #           # #     #   #             #   #   #                   #             
--     #       #       #     # #       #     #   #       #     #     #                 #             
--   #       # #         #           #         # #   # #       #       # #             #             
-- ##################################################################################################
_C.tPlayerMenu = {}   -- 玩家头像菜单
_C.tTargetMenu = {}   -- 目标头像菜单
_C.tTraceMenu  = {}   -- 工具栏菜单

-- get plugin folder menu
_C.GetMainMenu = function()
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
_C.GetPlayerAddonMenu = function()
	-- 创建菜单
	local menu = _C.GetMainMenu()
	for i = 1, #_C.tPlayerMenu, 1 do
		local m = _C.tPlayerMenu[i].Menu
		if type(m)=="function" then m = m() end
		table.insert(menu, m)
	end
	return {menu}
end
-- get target addon menu
_C.GetTargetAddonMenu = function()
	local menu = {}
	for i = 1, #_C.tTargetMenu, 1 do
		local m = _C.tTargetMenu[i].Menu
		if type(m)=="function" then m = m() end
		table.insert(menu, m)
	end
	return menu
end
-- get trace button menu
_C.GetTraceButtonMenu = function()
	local menu = _C.GetMainMenu()
	for i = 1, #_C.tTraceMenu, 1 do
		local m = _C.tTraceMenu[i].Menu
		if type(m)=="function" then m = m() end
		table.insert(menu, m)
	end
	return {menu}
end

-- 注册玩家头像菜单
-- 注册
-- (void) MY.RegisterPlayerAddonMenu(szName,Menu)
-- (void) MY.RegisterPlayerAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterPlayerAddonMenu(szName)
MY.RegisterPlayerAddonMenu = function(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tPlayerMenu, 1, -1 do
			if _C.tPlayerMenu[i].szName == szName then
				_C.tPlayerMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tPlayerMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tPlayerMenu, 1, -1 do
			if _C.tPlayerMenu[i].szName == szName then
				table.remove(_C.tPlayerMenu, i)
			end
		end
	end
end

-- 注册目标头像菜单
-- 注册
-- (void) MY.RegisterTargetAddonMenu(szName,Menu)
-- (void) MY.RegisterTargetAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterTargetAddonMenu(szName)
MY.RegisterTargetAddonMenu = function(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tTargetMenu, 1, -1 do
			if _C.tTargetMenu[i].szName == szName then
				_C.tTargetMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tTargetMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tTargetMenu, 1, -1 do
			if _C.tTargetMenu[i].szName == szName then
				table.remove(_C.tTargetMenu, i)
			end
		end
	end
end

-- 注册工具栏菜单
-- 注册
-- (void) MY.RegisterTraceButtonMenu(szName,Menu)
-- (void) MY.RegisterTraceButtonMenu(Menu)
-- 注销
-- (void) MY.RegisterTraceButtonMenu(szName)
MY.RegisterTraceButtonMenu = function(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tTraceMenu, 1, -1 do
			if _C.tTraceMenu[i].szName == szName then
				_C.tTraceMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tTraceMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tTraceMenu, 1, -1 do
			if _C.tTraceMenu[i].szName == szName then
				table.remove(_C.tTraceMenu, i)
			end
		end
	end
end

TraceButton_AppendAddonMenu( { _C.GetTraceButtonMenu } )
Player_AppendAddonMenu( { _C.GetPlayerAddonMenu } )
Target_AppendAddonMenu( { _C.GetTargetAddonMenu } )

-- ##################################################################################################
--               # # # #         #         #             #         #                   #             
--     # # # # #                 #           #           #       #   #         #       #       #     
--           #                 #       # # # # # #   # # # #   #       #       #       #       #     
--         #         #       #     #       #           #     #   # # #   #     #       #       #     
--       # # # # # #         # # #       #     #     #   #                     # # # # # # # # #     
--             # #               #     #         #   # # # # # # #       #             #             
--         # #         #       #       # # # # # #       #   #   #   #   #             #             
--     # # # # # # # # # #   # # # #     #   #   #       # # # # #   #   #   #         #         #   
--             #         #               #   #       # # #   #   #   #   #   #         #         #   
--       #     #     #           # #     #   #           #   # # #   #   #   #         #         #   
--     #       #       #     # #       #     #   #       #   #   #       #   # # # # # # # # # # #   
--   #       # #         #           #         # #       #   #   #     # #                       #   
-- ##################################################################################################
-- 显示本地信息
-- MY.Sysmsg(oContent, oTitle)
-- szContent    要显示的主体消息
-- szTitle      消息头部
-- tContentRgbF 主体消息文字颜色rgbf[可选，为空使用默认颜色字体。]
-- tTitleRgbF   消息头部文字颜色rgbf[可选，为空和主体消息文字颜色相同。]
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

-- Debug输出
-- (void)MY.Debug(oContent, szTitle, nLevel)
-- oContent Debug信息
-- szTitle  Debug头
-- nLevel   Debug级别[低于当前设置值将不会输出]
MY.Debug = function(oContent, szTitle, nLevel)
	if type(nLevel)~="number"  then nLevel = 1 end
	if type(szTitle)~="string" then szTitle = 'MY DEBUG' end
	if type(oContent)~='table' then oContent = { oContent, bNoWrap = true } end
	if not oContent.r then
		if nLevel == 0 then
			oContent.r, oContent.g, oContent.b =   0, 255, 127
		elseif nLevel == 1 then
			oContent.r, oContent.g, oContent.b = 255, 170, 170
		elseif nLevel == 2 then
			oContent.r, oContent.g, oContent.b = 255,  86,  86
		else
			oContent.r, oContent.g, oContent.b = 255, 255, 0
		end
	end
	if nLevel >= MY.GetAddonInfo().nDebugLevel then
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, "\n"))
		MY.Sysmsg(oContent, szTitle)
	end
end

-- 格式化计时时间
-- (string) MY.Sys.FormatTimeCount(szFormat, nTime)
-- szFormat  格式化字符串 可选项H,M,S,hh,mm,ss,h,m,s
MY.Sys.FormatTimeCount = function(szFormat, nTime)
	local nSeconds = math.floor(nTime)
	local nMinutes = math.floor(nSeconds / 60)
	local nHours   = math.floor(nMinutes / 60)
	local nMinute  = nMinutes % 60
	local nSecond  = nSeconds % 60
	szFormat = szFormat:gsub('H', nHours)
	szFormat = szFormat:gsub('M', nMinutes)
	szFormat = szFormat:gsub('S', nSeconds)
	szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
	szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
	szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
	szFormat = szFormat:gsub('h', nHours)
	szFormat = szFormat:gsub('m', nMinute)
	szFormat = szFormat:gsub('s', nSecond)
	return szFormat
end
MY.FormatTimeCount = MY.Sys.FormatTimeCount

-- 格式化时间
-- (string) MY.Sys.FormatTimeCount(szFormat, nTimestamp)
-- szFormat   格式化字符串 可选项yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
-- nTimestamp UNIX时间戳
MY.Sys.FormatTime = function(szFormat, nTimestamp)
	local t = TimeToDate(nTimestamp)
	szFormat = szFormat:gsub('yyyy', string.format('%04d', t.year  ))
	szFormat = szFormat:gsub('yy'  , string.format('%02d', t.year % 100))
	szFormat = szFormat:gsub('MM'  , string.format('%02d', t.month ))
	szFormat = szFormat:gsub('dd'  , string.format('%02d', t.day   ))
	szFormat = szFormat:gsub('hh'  , string.format('%02d', t.hour  ))
	szFormat = szFormat:gsub('mm'  , string.format('%02d', t.minute))
	szFormat = szFormat:gsub('ss'  , string.format('%02d', t.second))
	szFormat = szFormat:gsub('y', t.year  )
	szFormat = szFormat:gsub('M', t.month )
	szFormat = szFormat:gsub('d', t.day   )
	szFormat = szFormat:gsub('h', t.hour  )
	szFormat = szFormat:gsub('m', t.minute)
	szFormat = szFormat:gsub('s', t.second)
	return szFormat
end
MY.FormatTime = MY.Sys.FormatTime

-- register global esc key down action
-- (void) MY.Sys.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
-- (void) MY.Sys.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
-- (string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
-- (function)fnCondition -- a function returns if fnAction will be execute
-- (function)fnAction    -- inf fnCondition() is true then fnAction will be called
-- (boolean)bTopmost    -- this param equals true will be called in high priority
MY.Sys.RegisterEsc = function(szID, fnCondition, fnAction, bTopmost)
	if fnCondition and fnAction then
		if RegisterGlobalEsc then
			RegisterGlobalEsc(szID, fnCondition, fnAction, bTopmost)
		end
	else
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(szID, bTopmost)
		end
	end
end
MY.RegisterEsc = MY.Sys.RegisterEsc
