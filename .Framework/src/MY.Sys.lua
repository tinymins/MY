--------------------------------------------
-- @Desc  : ������� - ϵͳ������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-02-10 14:42:29
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
--------------------------------------------
-- ���غ����ͱ���
--------------------------------------------
MY = MY or {}
MY.Sys = MY.Sys or {}
MY.Sys.bShieldedVersion = false -- ���α���з�Ĺ��ܣ��������ã�
local _Cache, _L, _C = {}, MY.LoadLangPack(), {}

--[[ ��ȡ��Ϸ����
]]
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

-- Save & Load Lua Data
-- #######################################################################################################
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
-- #######################################################################################################
--[[ ���������ļ�
	MY.SaveLUAData( szFileUri, tData[, bNoDistinguishLang] )
	szFileUri           �����ļ�·��(1)
	tData               Ҫ���������
	bNoDistinguishLang  �Ƿ�ȡ���Զ����ֿͻ�������
	(1)�� ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
		  ��·��Ϊ���·��ʱ ����ڲ����@DATAĿ¼
]]
MY.Sys.SaveLUAData = function(szFileUri, tData, bNoDistinguishLang)
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
	return SaveLUAData(szFileUri, tData)
end
MY.SaveLUAData = MY.Sys.SaveLUAData
--[[ ���������ļ��������data�ļ���
	MY.LoadLUAData( szFileUri[, bNoDistinguishLang] )
	szFileUri           �����ļ�·��(1)
	bNoDistinguishLang  �Ƿ�ȡ���Զ����ֿͻ�������
	(1)�� ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
		  ��·��Ϊ���·��ʱ ����ڲ����@DATAĿ¼
]]
MY.Sys.LoadLUAData = function(szFileUri, bNoDistinguishLang)
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
	return LoadLUAData(szFileUri)
end
MY.LoadLUAData = MY.Sys.LoadLUAData

--[[ �����û����� ע��Ҫ����Ϸ��ʼ��֮��ʹ�ò�Ȼû��ClientPlayer����
	(data) MY.Sys.SaveUserData(szFileUri, tData)
]]
MY.Sys.SaveUserData = function(szFileUri, tData)
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- ����û�ʶ���ַ�
	szFileUri = szFileUri .. (MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '') .. "_" .. MY.Player.GetClientInfo().dwID
	-- ��ȡ����
	return MY.Sys.SaveLUAData(szFileUri, tData)
end
MY.SaveUserData = MY.Sys.SaveUserData

--[[ �����û����� ע��Ҫ����Ϸ��ʼ��֮��ʹ�ò�Ȼû��ClientPlayer����
	(data) MY.Sys.LoadUserData(szFile [,szSubAddonName])
]]
MY.Sys.LoadUserData = function(szFileUri)
	-- ͳһ��Ŀ¼�ָ���
	szFileUri = string.gsub(szFileUri, '\\', '/')
	if string.sub(szFileUri, -1) ~= '/' then
		szFileUri = szFileUri .. "_"
	end
	-- ����û�ʶ���ַ�
	szFileUri = szFileUri .. (MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '') .. "_" .. MY.Player.GetClientInfo().dwID
	-- ��ȡ����
	return MY.Sys.LoadLUAData(szFileUri)
end
MY.LoadUserData = MY.Sys.LoadUserData

--szName [, szDataFile]
MY.RegisterUserData = function(szName, szFileName)
	
end

--[[ ��������
	MY.Sys.PlaySound(szFilePath[, szCustomPath])
	szFilePath   ��Ƶ�ļ���ַ
	szCustomPath ���Ի���Ƶ�ļ���ַ
	ע�����Ȳ���szCustomPath, szCustomPath�����ڲŻᲥ��szFilePath
]]
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

-- Remote Request
-- #######################################################################################################
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
-- --#######################################################################################################
_Cache.tRequest = {}      -- �����������
_Cache.bRequest = false   -- ��������æ��
--[[ (void) MY.RemoteRequest(string szUrl, func fnAction)       -- ����Զ�� HTTP ����
-- szUrl        -- ��������� URL������ http:// �� https://��
-- fnAction     -- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnSuccess, fnError, nTimeout)
	-- ��ʽ������
	if type(szUrl)~="string" then return end
	if type(fnSuccess)~="function" then return end
	if type(fnError)~="function" then fnError = function(szUrl,errMsg) MY.Debug(szUrl..' - '..errMsg.."\n",'RemoteRequest',1) end end
	if type(nTimeout)~="number" then nTimeout = 10000 end
	-- ���������β����������
	table.insert(_Cache.tRequest,{ szUrl = szUrl, fnSuccess = fnSuccess, fnError = fnError, nTimeout = nTimeout })
	-- ��ʼ�����������
	_Cache.DoRemoteRequest()
end

-- get `ie` ui element
_C.GetIE = function()
	local frame = MY.GetFrame()
	if not frame then
		return false
	end
	local ie = frame:Lookup("Page_1")
	if not ie then
		MY.Debug('Page_1 not found in Normal::MY', 'MYRR', 3)
		return false
	end
	-- init ie
	if not ie.OnDocumentComplete then
		ie.OnDocumentComplete = function()
			-- �ж��Ƿ���Զ������ȴ��ص� û����ֱ�ӷ���
			if not _Cache.bRequest then
				return
			end
			-- ����ص�
			local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			-- ��ȡ��������ײ�Ԫ��
			local rr = _Cache.tRequest[1]
			-- �жϵ�ǰҳ���Ƿ��������
			if szUrl ~= szTitle or szContent ~= "" then
				-- ��������ص�
				MY.Debug(string.format("%s\n%s\n", szUrl, szTitle), 'MYRR::OnDocumentComplete', 0)
				-- ע����ʱ����ʱ��
				MY.DelayCall("MY_Remote_Request_Timeout")
				-- �ɹ��ص�����
				local status, err = pcall(rr.fnSuccess, szTitle, szContent)
				if not status then
					MY.Debug(err .. '\n', 'MYRR::OnDocumentComplete::Callback', 3)
				end
				-- �������б��Ƴ�
				table.remove(_Cache.tRequest, 1)
				-- ��������״̬Ϊ����
				_Cache.bRequest = false
				-- ������һ��Զ������
				_Cache.DoRemoteRequest()
			end
		end
	end
	return ie
end

-- ����Զ���������
_Cache.DoRemoteRequest = function()
	-- check if request queue is clear
	if #_Cache.tRequest == 0 then
		_Cache.bRequest = false
		MY.Debug('Remote Request Queue Is Clear.\n', 'MYRR', 0)
		return
	end
	
	-- �����ǰ������δ��������� ����Զ��������д��ڿ���״̬
	if not _Cache.bRequest and #_Cache.tRequest > 0 then
		-- get ie element
		local ie = _C.GetIE()
		if not ie then
			MY.DelayCall(_Cache.DoRemoteRequest, 3000)
			MY.Debug('network plugin has not been initalized yet!\n', 'MYRR', 1)
			return
		end
		-- get the remote request which is going to process
		local rr = _Cache.tRequest[1]
		-- do with this remote request
		MY.Debug(rr.szUrl .. '\n', 'MYRR', 0)
		-- register request timeout clock
		MY.DelayCall(function()
			MY.Debug(rr.szUrl .. '\n', 'MYRR::Timeout', 1) -- log
			-- request timeout, call timeout function.
			local status, err = pcall(rr.fnError, rr.szUrl, "timeout")
			if not status then
				MY.Debug(err .. '\n', 'MYRR::TIMEOUT', 3)
			end
			-- remove this request from queue
			table.remove(_Cache.tRequest, 1)
			-- set requset queue state to idle
			_Cache.bRequest = false
			-- process next request
			_Cache.DoRemoteRequest()
		end, rr.nTimeout, "MY_Remote_Request_Timeout")
		-- start ie navigate
		ie:Navigate(rr.szUrl)
		-- set ie status to busy
		_Cache.bRequest = true
	end
end

-- Breathe Call & Delay Call
-- #######################################################################################################
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
-- --#######################################################################################################
_Cache.nFrameCount = GetLogicFrameCount()
_Cache.tDelayCall = {}    -- delay call ����
_Cache.tBreatheCall = {}  -- breathe call ����
--[[ �ӳٵ���
	(void) MY.DelayCall(func fnAction, number nDelay, string szName)
	fnAction    -- ���ú���
	nTime       -- �ӳٵ���ʱ�䣬��λ�����룬ʵ�ʵ����ӳ��ӳ��� 62.5 ��������
	szName      -- �ӳٵ���ID ����ȡ������
	ȡ������
	(void) MY.DelayCall(string szName)
	szName      -- �ӳٵ���ID
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
	
	if szName and nDelay and not fnAction then -- ����DelayCall�ӳ�ʱ��
		for i = #_Cache.tDelayCall, 1, -1 do
			if _Cache.tDelayCall[i].szName == szName then
				_Cache.tDelayCall[i].nTime = nDelay + GetTime()
			end
		end
	else -- һ���µ�DelayCall�����߸���ԭ���ģ�
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
--[[ ע�����ѭ�����ú���
	(void) MY.BreatheCall(string szKey, func fnAction[, number nTime])
	szKey       -- ���ƣ�����Ψһ���ظ��򸲸�
	fnAction    -- ѭ���������ú�������Ϊ nil ���ʾȡ����� key �µĺ���������
	nTime       -- ���ü������λ�����룬Ĭ��Ϊ 62.5����ÿ����� 16�Σ���ֵ�Զ�������� 62.5 ��������
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
--[[ �ı��������Ƶ��
	(void) MY.BreatheCallDelay(string szKey, nTime)
	nTime       -- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
]]
MY.BreatheCallDelay = function(szKey, nTime)
	for _, t in ipairs(_Cache.tBreatheCall) do
		if t.szName == StringLowerW(szKey) then
			t.nFrame = math.ceil(nTime / 62.5)
			t.nNext = GetLogicFrameCount() + t.nFrame
		end
	end
end
--[[ �ӳ�һ�κ��������ĵ���Ƶ��
	(void) MY.BreatheCallDelayOnce(string szKey, nTime)
	nTime       -- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
]]
MY.BreatheCallDelayOnce = function(szKey, nTime)
	for _, t in ipairs(_Cache.tBreatheCall) do
		if t.szName == StringLowerW(szKey) then
			t.nNext = GetLogicFrameCount() + math.ceil(nTime / 62.5)
		end
	end
end
-- breathe
MY.UI.RegisterUIEvent(MY, "OnFrameBreathe", function()
	-- add frame counter
	_Cache.nFrameCount = GetLogicFrameCount()
	-- run breathe calls
	local nFrame = _Cache.nFrameCount
	for i = #_Cache.tBreatheCall, 1, -1 do
		if nFrame >= _Cache.tBreatheCall[i].nNext then
			local bc = _Cache.tBreatheCall[i]
			bc.nNext = nFrame + bc.nFrame
			local res, err = pcall(bc.fnAction, unpack(bc.param))
			if not res then
				MY.Debug("BreatheCall#" .. (bc.szName or ('anonymous_'..i)) .." ERROR: " .. err)
			elseif err == 0 then    -- function return 0 means to stop its breathe
				for i = #_Cache.tBreatheCall, 1, -1 do
					if _Cache.tBreatheCall[i] == bc then
						table.remove(_Cache.tBreatheCall, i)
					end
				end
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
-- GetLogicFrameCount()��ͼ����
MY.RegisterEvent('LOADING_END', function()
	local nFrameOffset = GetLogicFrameCount() - _Cache.nFrameCount
	_Cache.nFrameCount = GetLogicFrameCount()
	for _, bc in ipairs(_Cache.tBreatheCall) do
		bc.nNext = bc.nNext + nFrameOffset
	end
end)

-- #######################################################################################################
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
-- #######################################################################################################
_Cache.tPlayerMenu = {}   -- ���ͷ��˵�
_Cache.tTargetMenu = {}   -- Ŀ��ͷ��˵�
_Cache.tTraceMenu  = {}   -- �������˵�

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
	-- �����˵�
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
--[[ ע�����ͷ��˵�
	-- ע��
	(void) MY.RegisterPlayerAddonMenu(szName,Menu)
	(void) MY.RegisterPlayerAddonMenu(Menu)
	-- ע��
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
--[[ ע��Ŀ��ͷ��˵�
	-- ע��
	(void) MY.RegisterTargetAddonMenu(szName,Menu)
	(void) MY.RegisterTargetAddonMenu(Menu)
	-- ע��
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
--[[ ע�Ṥ�����˵�
	-- ע��
	(void) MY.RegisterTraceButtonMenu(szName,Menu)
	(void) MY.RegisterTraceButtonMenu(Menu)
	-- ע��
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

-- #######################################################################################################
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
-- #######################################################################################################
--[[ ��ʾ������Ϣ
	MY.Sysmsg(oContent, oTitle)
	szContent    Ҫ��ʾ��������Ϣ
	szTitle      ��Ϣͷ��
	tContentRgbF ������Ϣ������ɫrgbf[��ѡ��Ϊ��ʹ��Ĭ����ɫ���塣]
	tTitleRgbF   ��Ϣͷ��������ɫrgbf[��ѡ��Ϊ�պ�������Ϣ������ɫ��ͬ��]
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
--[[ Debug���
	(void)MY.Debug(szText, szHead, nLevel)
	szText  Debug��Ϣ
	szHead  Debugͷ
	nLevel  Debug����[���ڵ�ǰ����ֵ���������]
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
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szHead .. ']' .. szText)
	end
end

--[[ ��ʽ����ʱʱ��
	(string) MY.Sys.FormatTimeCount(szFormat, nTime)
	szFormat  ��ʽ���ַ��� ��ѡ��H,M,S,hh,mm,ss,h,m,s
]]
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

--[[ ��ʽ��ʱ��
	(string) MY.Sys.FormatTimeCount(szFormat, nTimestamp)
	szFormat   ��ʽ���ַ��� ��ѡ��yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
	nTimestamp UNIXʱ���
]]
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

--[[ register global esc key down action
	(void) MY.Sys.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
	(void) MY.Sys.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
	(string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
	(function)fnCondition -- a function returns if fnAction will be execute
	(function)fnAction    -- inf fnCondition() is true then fnAction will be called
	(boolean)bTopmost    -- this param equals true will be called in high priority
]]
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
