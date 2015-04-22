--------------------------------------------
-- @Desc  : ������� - ϵͳ������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-04-22 13:43:50
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
MY = MY or {}
MY.Sys = MY.Sys or {}
MY.Sys.bShieldedVersion = false -- ���α���з�Ĺ��ܣ��������ã�
local _L, _C = MY.LoadLangPack(), {}

-- ��ȡ��Ϸ����
MY.Sys.GetLang = function()
	local _, _, lang = GetVersion()
	return lang
end
MY.GetLang = MY.Sys.GetLang

-- ��ȡ��������״̬
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
-- ���������ļ�
-- MY.SaveLUAData( szFileUri, tData[, bNoDistinguishLang] )
-- szFileUri           �����ļ�·��(1)
-- tData               Ҫ���������
-- bNoDistinguishLang  �Ƿ�ȡ���Զ����ֿͻ�������
-- (1)�� ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
--       ��·��Ϊ���·��ʱ ����ڲ����@DATAĿ¼
MY.Sys.SaveLUAData = function(szFileUri, tData, bNoDistinguishLang)
	local nStartTick = GetTickCount()
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	-- ��������·�����/@DATA/��ȫ
	if string.sub(szFileUri, 1, 1)~='/' then
		szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
	end
	-- �����Ϸ���Ժ�׺
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
	-- ����ϵͳAPI
	local ret = SaveLUAData(szFileUri, tData)
	-- performance monitor
	MY.Debug({_L('%s saved during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', 0)
	return ret
end
MY.SaveLUAData = MY.Sys.SaveLUAData

-- ���������ļ��������data�ļ���
-- MY.LoadLUAData( szFileUri[, bNoDistinguishLang] )
-- szFileUri           �����ļ�·��(1)
-- bNoDistinguishLang  �Ƿ�ȡ���Զ����ֿͻ�������
-- (1)�� ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
--       ��·��Ϊ���·��ʱ ����ڲ����@DATAĿ¼
MY.Sys.LoadLUAData = function(szFileUri, bNoDistinguishLang)
	local nStartTick = GetTickCount()
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	-- ��������·�����/@DATA/��ȫ
	if string.sub(szFileUri, 1, 1)~='/' then
		szFileUri = MY.GetAddonInfo().szRoot .. "@DATA/" .. szFileUri
	end
	-- �����Ϸ���Ժ�׺
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
	-- ����ϵͳAPI
	local ret = LoadLUAData(szFileUri)
	-- performance monitor
	MY.Debug({_L('%s loaded during %dms.', szFileUri, GetTickCount() - nStartTick)}, 'PMTool', 0)
	return ret
end
MY.LoadLUAData = MY.Sys.LoadLUAData

-- �����û����� ע��Ҫ����Ϸ��ʼ��֮��ʹ�ò�Ȼû��ClientPlayer����
-- (data) MY.Sys.SaveUserData(szFileUri, tData)
MY.Sys.SaveUserData = function(szFileUri, tData)
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- ����û�ʶ���ַ�
	szFileUri = szFileUri .. MY.Player.GetUUID()
	-- ��ȡ����
	return MY.Sys.SaveLUAData(szFileUri, tData)
end
MY.SaveUserData = MY.Sys.SaveUserData

-- �����û����� ע��Ҫ����Ϸ��ʼ��֮��ʹ�ò�Ȼû��ClientPlayer����
-- (data) MY.Sys.LoadUserData(szFile [,szSubAddonName])
MY.Sys.LoadUserData = function(szFileUri)
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- ����û�ʶ���ַ�
	szFileUri = szFileUri .. MY.Player.GetUUID()
	-- ��ȡ����
	return MY.Sys.LoadLUAData(szFileUri)
end
MY.LoadUserData = MY.Sys.LoadUserData

--szName [, szDataFile]
MY.RegisterUserData = function(szName, szFileName)
	
end

-- ��������
-- MY.Sys.PlaySound(szFilePath[, szCustomPath])
-- szFilePath   ��Ƶ�ļ���ַ
-- szCustomPath ���Ի���Ƶ�ļ���ַ
-- ע�����Ȳ���szCustomPath, szCustomPath�����ڲŻᲥ��szFilePath
MY.Sys.PlaySound = function(szFilePath, szCustomPath)
	szCustomPath = szCustomPath or szFilePath
	-- ͳһ��Ŀ¼�ָ���
	szCustomPath = string.gsub(szCustomPath, '\\', '/')
	-- ��������·�����/@Custom/��ȫ
	if string.sub(szCustomPath, 1, 1)~='/' then szCustomPath = MY.GetAddonInfo().szRoot .. "@Custom/" .. szCustomPath end
	if IsFileExist(szCustomPath) then
		PlaySound(SOUND.UI_SOUND, szCustomPath)
	else
		-- ͳһ��Ŀ¼�ָ���
		szFilePath = string.gsub(szFilePath, '\\', '/')
		-- ��������·�����/@Custom/��ȫ
		if string.sub(szFilePath, 1, 1)~='/' then szFilePath = MY.GetAddonInfo().szFrameworkRoot .. "audio/" .. szFilePath end
		PlaySound(SOUND.UI_SOUND, szFilePath)
	end
end
-- ����ע������
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
-- (void) MY.RemoteRequest(string szUrl, func fnAction)       -- ����Զ�� HTTP ����
-- szUrl        -- ��������� URL������ http:// �� https://��
-- fnAction     -- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle, szContent)]]
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
			-- ע����ʱ����ʱ��
			MY.DelayCall("MYRR_TO_" .. RequestID)
			-- �ɹ��ص�����
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
_C.tDelayCall = {}    -- delay call ����
_C.tBreatheCall = {}  -- breathe call ����

-- �ӳٵ���
-- (void) MY.DelayCall(func fnAction, number nDelay, string szName)
-- fnAction    -- ���ú���
-- nTime       -- �ӳٵ���ʱ�䣬��λ�����룬ʵ�ʵ����ӳ��ӳ��� 62.5 ��������
-- szName      -- �ӳٵ���ID ����ȡ������
-- ȡ������
-- (void) MY.DelayCall(string szName)
-- szName      -- �ӳٵ���ID
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
	
	if szName and nDelay and not fnAction then -- ����DelayCall�ӳ�ʱ��
		for i = #_C.tDelayCall, 1, -1 do
			if _C.tDelayCall[i].szName == szName then
				_C.tDelayCall[i].nTime = nDelay + GetTime()
			end
		end
	else -- һ���µ�DelayCall�����߸���ԭ���ģ�
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

-- ע�����ѭ�����ú���
-- (void) MY.BreatheCall(string szKey, func fnAction[, number nTime])
-- szKey       -- ���ƣ�����Ψһ���ظ��򸲸�
-- fnAction    -- ѭ���������ú�������Ϊ nil ���ʾȡ����� key �µĺ���������
-- nTime       -- ���ü������λ�����룬Ĭ��Ϊ 62.5����ÿ����� 16�Σ���ֵ�Զ�������� 62.5 ��������
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

-- �ı��������Ƶ��
-- (void) MY.BreatheCallDelay(string szKey, nTime)
-- nTime       -- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
MY.BreatheCallDelay = function(szKey, nTime)
	for _, t in ipairs(_C.tBreatheCall) do
		if t.szName == StringLowerW(szKey) then
			t.nFrame = math.ceil(nTime / 62.5)
			t.nNext = GetLogicFrameCount() + t.nFrame
		end
	end
end

-- �ӳ�һ�κ��������ĵ���Ƶ��
-- (void) MY.BreatheCallDelayOnce(string szKey, nTime)
-- nTime       -- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
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

-- GetLogicFrameCount()��ͼ����
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
_C.tPlayerMenu = {}   -- ���ͷ��˵�
_C.tTargetMenu = {}   -- Ŀ��ͷ��˵�
_C.tTraceMenu  = {}   -- �������˵�

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
	-- �����˵�
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

-- ע�����ͷ��˵�
-- ע��
-- (void) MY.RegisterPlayerAddonMenu(szName,Menu)
-- (void) MY.RegisterPlayerAddonMenu(Menu)
-- ע��
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

-- ע��Ŀ��ͷ��˵�
-- ע��
-- (void) MY.RegisterTargetAddonMenu(szName,Menu)
-- (void) MY.RegisterTargetAddonMenu(Menu)
-- ע��
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

-- ע�Ṥ�����˵�
-- ע��
-- (void) MY.RegisterTraceButtonMenu(szName,Menu)
-- (void) MY.RegisterTraceButtonMenu(Menu)
-- ע��
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
-- ��ʾ������Ϣ
-- MY.Sysmsg(oContent, oTitle)
-- szContent    Ҫ��ʾ��������Ϣ
-- szTitle      ��Ϣͷ��
-- tContentRgbF ������Ϣ������ɫrgbf[��ѡ��Ϊ��ʹ��Ĭ����ɫ���塣]
-- tTitleRgbF   ��Ϣͷ��������ɫrgbf[��ѡ��Ϊ�պ�������Ϣ������ɫ��ͬ��]
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

-- Debug���
-- (void)MY.Debug(oContent, szTitle, nLevel)
-- oContent Debug��Ϣ
-- szTitle  Debugͷ
-- nLevel   Debug����[���ڵ�ǰ����ֵ���������]
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

-- ��ʽ����ʱʱ��
-- (string) MY.Sys.FormatTimeCount(szFormat, nTime)
-- szFormat  ��ʽ���ַ��� ��ѡ��H,M,S,hh,mm,ss,h,m,s
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

-- ��ʽ��ʱ��
-- (string) MY.Sys.FormatTimeCount(szFormat, nTimestamp)
-- szFormat   ��ʽ���ַ��� ��ѡ��yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
-- nTimestamp UNIXʱ���
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
