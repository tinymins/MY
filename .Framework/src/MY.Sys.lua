--------------------------------------------
-- @Desc  : 茗伊插件 - 系统函数库
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-06-26 11:38:05
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
MY.Sys.IsShieldedVersion = function(bShieldedVersion)
	if bShieldedVersion == nil then
		return MY.Sys.bShieldedVersion
	else
		MY.Sys.bShieldedVersion = bShieldedVersion
		if not bShieldedVersion and MY.IsPanelOpened() then
			MY.ReopenPanel()
		end
	end
end
MY.IsShieldedVersion = MY.Sys.IsShieldedVersion
pcall(function()
	MY.Sys.bShieldedVersion = (MY.Sys.GetLang() == 'zhcn')
end)

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
-- 格式化数据文件路径（替换$uid、$lang、$server以及补全相对路径）
-- (string) MY.Sys.GetLUADataPath(szFileUri)
MY.Sys.GetLUADataPath = function(szFileUri)
	-- Unified the directory separator
	szFileUri = string.gsub(szFileUri, '\\', '/')
	-- if exist $uid then add user role identity
	if string.find(szFileUri, "%$uid") then
		szFileUri = szFileUri:gsub("%$uid", MY.Player.GetUUID())
	end
	-- if exist $lang then add language identity
	if string.find(szFileUri, "%$lang") then
		szFileUri = szFileUri:gsub("%$lang", string.lower(MY.Sys.GetLang()))
	end
	-- if exist $server then add server identity
	if string.find(szFileUri, "%$server") then
		szFileUri = szFileUri:gsub("%$server", ((MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- ensure has file name
	if string.sub(szFileUri, -1) == '/' then
		szFileUri = szFileUri .. "data"
	end
	-- if it's relative path then complete path with "/@DATA/"
	if string.sub(szFileUri, 1, 1) ~= '/' then
		szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
	end
	return szFileUri
end
MY.GetLUADataPath = MY.Sys.GetLUADataPath

-- 保存数据文件
-- MY.SaveLUAData( szFileUri, tData, indent, crc)
-- szFileUri           数据文件路径(1)
-- tData               要保存的数据
-- indent              数据文件缩进
-- crc                 是否添加CRC校验头（默认true）
-- (1)： 当路径为绝对路径时(以斜杠开头)不作处理
--       当路径为相对路径时 相对于插件下@DATA目录
MY.Sys.SaveLUAData = function(szFileUri, tData, indent, crc)
	local nStartTick = GetTickCount()
	-- format uri
	szFileUri = MY.GetLUADataPath(szFileUri)
	-- save data
	local data = SaveLUAData(szFileUri, tData, indent, crc or false)
	-- performance monitor
	MY.Debug({_L('%s saved during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', MY_DEBUG.PMLOG)
	return data
end
MY.SaveLUAData = MY.Sys.SaveLUAData

-- 加载数据文件：相对于data文件夹
-- MY.LoadLUAData( szFileUri)
-- szFileUri           数据文件路径(1)
-- (1)： 当路径为绝对路径时(以斜杠开头)不作处理
--       当路径为相对路径时 相对于插件下@DATA目录
MY.Sys.LoadLUAData = function(szFileUri)
	local nStartTick = GetTickCount()
	-- format uri
	szFileUri = MY.GetLUADataPath(szFileUri)
	-- load data
	local data = LoadLUAData(szFileUri)
	-- performance monitor
	MY.Debug({_L('%s loaded during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', MY_DEBUG.PMLOG)
	return data
end
MY.LoadLUAData = MY.Sys.LoadLUAData

--szName [, szDataFile]
MY.RegisterUserData = function(szName, szFileName)
	
end

MY.Sys.SetGlobalValue = function(szVarPath, Val)
	local t = MY.String.Split(szVarPath, ".")
	local tab = _G
	for k, v in ipairs(t) do
		if type(tab[v]) == "nil" then
			tab[v] = {}
		end
		if k == #t then
			tab[v] = Val
		end
		tab = tab[v]
	end
end
MY.SetGlobalValue = MY.Sys.SetGlobalValue

MY.Sys.GetGlobalValue = function(szVarPath)
	local tVariable = _G
	for szIndex in string.gmatch(szVarPath, "[^%.]+") do
		if tVariable and type(tVariable) == "table" then
			tVariable = tVariable[szIndex]
		else
			tVariable = nil
			break
		end
	end
	return tVariable
end
MY.GetGlobalValue = MY.Sys.GetGlobalValue

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
MY.RegisterInit('MYLIB#INITDATA', function()
	local t = MY.LoadLUAData('config/initial.$lang.jx3dat')
	if t then
		for v_name, v_data in pairs(t) do
			MY.SetGlobalValue(v_name, v_data)
		end
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
_C.tFreeWebPages = {}
-- (void) MY.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnSuccess, fnError, nTimeout)
	if not (type(szUrl) == "string" and type(fnSuccess) == "function") then
		return
	end
	if type(nTimeout) ~= "number" then
		nTimeout = 10000
	end
	if type(fnError) ~= "function" then
		fnError = function(szUrl, errMsg)
			MY.Debug({szUrl .. ' - ' .. errMsg}, 'RemoteRequest', MY_DEBUG.WARNING)
		end
	end
	
	local RequestID, hFrame
	local nFreeWebPages = #_C.tFreeWebPages
	if nFreeWebPages > 0 then
		RequestID = _C.tFreeWebPages[nFreeWebPages]
		hFrame = Station.Lookup('Lowest/MYRR_' .. RequestID)
		table.remove(_C.tFreeWebPages)
	end
	-- create page
	if not hFrame then
		RequestID = ("%X_%X"):format(GetTickCount(), math.floor(math.random() * 65536))
		hFrame = Wnd.OpenWindow(MY.GetAddonInfo().szFrameworkRoot .. 'ui/WndWebPage.ini', "MYRR_" .. RequestID)
		hFrame:Hide()
	end
	local hPage = hFrame:Lookup('WndWebPage')
	
	-- bind callback function
	hPage.OnDocumentComplete = function()
		local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
		if szUrl ~= szTitle or szContent ~= "" then
			MY.Debug({string.format("%s - %s", szTitle, szUrl)}, 'MYRR::OnDocumentComplete', MY_DEBUG.LOG)
			-- 注销超时处理时钟
			MY.DelayCall("MYRR_TO_" .. RequestID)
			-- 成功回调函数
			local status, err = pcall(fnSuccess, szTitle, szContent)
			if not status then
				MY.Debug({err}, 'MYRR::OnDocumentComplete::Callback', MY_DEBUG.ERROR)
			end
			table.insert(_C.tFreeWebPages, RequestID)
		end
	end
	
	-- do with this remote request
	MY.Debug({szUrl}, 'MYRR', MY_DEBUG.LOG)
	-- register request timeout clock
	MY.DelayCall("MYRR_TO_" .. RequestID, function()
		MY.Debug({szUrl}, 'MYRR::Timeout', MY_DEBUG.WARNING) -- log
		-- request timeout, call timeout function.
		local status, err = pcall(fnError, szUrl, "timeout")
		if not status then
			MY.Debug({err}, 'MYRR::TIMEOUT', MY_DEBUG.ERROR)
		end
		table.insert(_C.tFreeWebPages, RequestID)
	end, nTimeout)
	
	-- start ie navigate
	hPage:Navigate(szUrl)
end

-------------------------------
-- remote data storage online
-- bosslist (done)
-- focus list (working on)
-- chat blocklist (working on)
-------------------------------
-- 个人数据版本号
local m_nStorageVer = {}
MY.RegisterInit("'MYLIB#STORAGE_DATA", function()
	m_nStorageVer = MY.LoadLUAData('config/STORAGE_VERSION/$uid.$lang.jx3dat') or {}
	MY.RemoteRequest('http://data.jx3.derzh.com/data/all.php?l=' .. MY.GetLang()
	.. "&data=" .. MY.String.SimpleEcrypt(MY.Json.Encode({
		n = GetUserRoleName(), i = UI_GetClientPlayerID(),
		s = MY.GetServer(), _ = GetCurrentTime()
	})), function(szTitle, szContent)
		local data = MY.Json.Decode(szContent)
		if data then
			for k, v in pairs(data.public) do
				FireUIEvent("MY_PUBLIC_STORAGE_UPDATE", k, v)
			end
			for k, v in pairs(data.private) do
				if not m_nStorageVer[k] or m_nStorageVer[k] < v.v then
					local oData = MY.Json.Decode(v.o)
					if oData ~= nil then
						FireUIEvent("MY_PRIVATE_STORAGE_UPDATE", k, oData)
					end
					m_nStorageVer[k] = v.v
				end
			end
		end
	end)
end)
MY.RegisterExit("'MYLIB#STORAGE_DATA", function()
	MY.SaveLUAData('config/STORAGE_VERSION/$uid.$lang.jx3dat', m_nStorageVer)
end)
-- 保存个人数据 方便网吧党和公司家里多电脑切换
MY.Sys.StorageData = function(szKey, oData)
	MY.DelayCall("STORAGE_" .. szKey, function()
		MY.RemoteRequest('http://data.jx3.derzh.com/data/sync.php?l=' .. MY.GetLang()
		.. "&data=" .. MY.String.SimpleEcrypt(MY.Json.Encode({
			n = GetUserRoleName(), i = UI_GetClientPlayerID(),
			s = MY.GetServer(), v = GetCurrentTime(),
			k = szKey, o = oData
		})), function(szTitle, szContent)
			local data = MY.Json.Decode(szContent)
			if data and data.succeed then
				FireUIEvent("MY_PRIVATE_STORAGE_SYNC", szKey)
			end
		end)
	end, 120000)
	m_nStorageVer[szKey] = GetCurrentTime()
end
MY.StorageData = MY.Sys.StorageData
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
-- (string szKey) MY.DelayCall([string szKey, ]function fnAction[, number nDelay]) -- 注册
-- (string szKey) MY.DelayCall(string szKey, number nDelay) -- 改变Delay时间
-- (string szKey) MY.DelayCall(string szKey) -- 注销
-- szKey       -- 延迟调用ID 用于取消调用
-- fnAction    -- 调用函数
-- nDelay      -- 延迟调用时间，单位：毫秒，实际调用延迟延迟是 62.5 的整倍数
MY.DelayCall = function(szKey, fnAction, nDelay)
	if type(szKey) == "function" then
		szKey, fnAction, nDelay = GetTickCount(), szKey, fnAction
		while _C.tDelayCall[szKey] do
			szKey = szKey + 0.1
		end
	elseif type(fnAction) == "number" then
		nDelay, fnAction = fnAction
	end
	if fnAction then -- reg
		if not nDelay then
			nDelay = 1
		end
		_C.tDelayCall[szKey] = { nTime = nDelay + GetTickCount(), fnAction = fnAction }
	elseif nDelay then -- modify
		local dc = _C.tDelayCall[szKey]
		if dc then
			dc.nTime = nDelay + GetTickCount()
		end
	elseif szKey then -- unreg
		_C.tDelayCall[szKey] = nil
	end
	return szKey
end

-- 注册呼吸循环调用函数
-- (string szKey) MY.BreatheCall([string szKey, ]function fnAction[, number nInterval])
-- (string szKey) MY.BreatheCall(string szKey, number nTime[, bool bOnce]) -- 改变呼吸调用频率
-- szKey       -- 名称，必须唯一，重复则覆盖
-- fnAction    -- 循环呼吸调用函数，设为 nil 则表示取消这个 key 下的呼吸处理函数
-- nInterval   -- 调用间隔，单位：毫秒
MY.BreatheCall = function(szKey, fnAction, nInterval)
	local bOnce
	if type(szKey) == "function" then
		szKey, fnAction, nInterval = GetTickCount(), szKey, fnAction
		while _C.tBreatheCall[szKey] do
			szKey = szKey + 0.1
		end
	elseif type(fnAction) == "number" then
		nInterval, bOnce, fnAction = fnAction, nInterval
	end
	if fnAction then -- reg
		_C.tBreatheCall[szKey] = {
			fnAction = fnAction,
			nNext = GetTickCount(),
			nInterval = nInterval or 0,
		}
	elseif nInterval then -- modify
		local bc = _C.tBreatheCall[szKey]
		if bc then
			if not bOnce then
				bc.nInterval = nInterval
			end
			bc.nNext = GetTickCount() + nInterval
		end
	elseif szKey then -- unreg
		_C.tBreatheCall[szKey] = nil
	end
	return szKey
end

-- breathe
local _tCalls = {} -- avoid error: invalid key to 'next'
MY.UI.RegisterUIEvent(MY, "OnFrameBreathe", function()
	local nTime = GetTickCount()
	-- get breathe calls
	for szKey, bc in pairs(_C.tBreatheCall) do
		if bc.nNext <= nTime then
			bc.nNext = nTime + bc.nInterval
			_tCalls[szKey] = bc
		end
	end
	-- run breathe calls
	for szKey, bc in pairs(_tCalls) do
		local res, err = pcall(bc.fnAction)
		if not res then
			MY.Debug({err}, "BreatheCall#" .. szKey, MY_DEBUG.ERROR)
		elseif err == 0 then    -- function return 0 means to stop its breathe
			_C.tBreatheCall[szKey] = nil
		end
		_tCalls[szKey] = nil
	end
	-- get delay calls
	for szKey, dc in pairs(_C.tDelayCall) do
		if dc.nTime <= nTime then
			_C.tDelayCall[szKey] = nil
			_tCalls[szKey] = dc
		end
	end
	-- run delay calls
	for szKey, dc in pairs(_tCalls) do
		local res, err = pcall(dc.fnAction)
		if not res then
			MY.Debug({err}, "DelayCall#" .. szKey, MY_DEBUG.ERROR)
		end
		_tCalls[szKey] = nil
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
		bChecked = MY.IsPanelVisible(),
		
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
	if type(nLevel)~="number"  then nLevel = MY_DEBUG.WARNING end
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
	elseif nLevel >= MY.GetAddonInfo().nLogLevel then
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, "\n"))
	end
end

MY.StartDebugMode = function()
	if JH then
		JH.bDebugClient = true
	end
	MY.Sys.IsShieldedVersion(false)
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

-- 测试用
if loadstring then
function MY.ProcessCommand(cmd)
	local ls = loadstring("return " .. cmd)
	if ls then
		return ls()
	end
end
end

MY.Sys.DoMessageBox = function(szName, i)
	local frame = Station.Lookup("Topmost2/MB_" .. szName) or Station.Lookup("Topmost/MB_" .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup("Wnd_All/Btn_Option" .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				if frame.args then
					btn.fnAction(unpack(frame.args))
				else
					btn.fnAction()
				end
			elseif frame.fnAction then
				if frame.args then
					frame.fnAction(i, unpack(frame.args))
				else
					frame.fnAction(i)
				end
			end
			frame.OnFrameDestroy = nil
			CloseMessageBox(szName)
		end
	end
end
MY.DoMessageBox = MY.Sys.DoMessageBox
