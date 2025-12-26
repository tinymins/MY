--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·声音
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Sound')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local SOUND_VOLUME_CACHE
local function CaptureSoundVolumes()
	local frame = Station.SearchFrame('SoundSettingPanel')
	local bClose = not frame
	if not frame then
		frame = X.UI.OpenFrame('SoundSettingPanel')
	end
	local chkMainMute = frame and frame:Lookup('CheckBox_Silence')
	local scrollMainVolume = frame and frame:Lookup('Scroll_MainVolume')
	local nMainVolume = chkMainMute and not chkMainMute:IsCheckBoxChecked() and scrollMainVolume
		and (scrollMainVolume:GetScrollPos() / scrollMainVolume:GetStepCount())
		or 0
	local chkBgMute = frame and frame:Lookup('CheckBox_BgSound')
	local scrollBgVolume = frame and frame:Lookup('Scroll_BgVolume')
	local nBgVolume = chkBgMute and chkBgMute:IsCheckBoxChecked() and scrollBgVolume
		and (scrollBgVolume:GetScrollPos() / scrollBgVolume:GetStepCount())
		or 0
	local chkRoleMute = frame and frame:Lookup('CheckBox_RoleSound')
	local scrollRoleVolume = frame and frame:Lookup('Scroll_ChVolume')
	local nRoleVolume = chkRoleMute and chkRoleMute:IsCheckBoxChecked() and scrollRoleVolume
		and (scrollRoleVolume:GetScrollPos() / scrollRoleVolume:GetStepCount())
		or 0
	local chkSceneMute = frame and frame:Lookup('CheckBox_SceneSound')
	local scrollSceneVolume = frame and frame:Lookup('Scroll_SceneVolume')
	local nSceneVolume = chkSceneMute and chkSceneMute:IsCheckBoxChecked() and scrollSceneVolume
		and (scrollSceneVolume:GetScrollPos() / scrollSceneVolume:GetStepCount())
		or 0
	local chkUIMute = frame and frame:Lookup('CheckBox_UISound')
	local scrollUIVolume = frame and frame:Lookup('Scroll_UIVolume')
	local nUIVolume = chkUIMute and chkUIMute:IsCheckBoxChecked() and scrollUIVolume
		and (scrollUIVolume:GetScrollPos() / scrollUIVolume:GetStepCount())
		or 0
	local chkTipMute = frame and frame:Lookup('CheckBox_Tip')
	local scrollTipVolume = frame and frame:Lookup('Scroll_TipVolume')
	local nTipVolume = chkTipMute and chkTipMute:IsCheckBoxChecked() and scrollTipVolume
		and (scrollTipVolume:GetScrollPos() / scrollTipVolume:GetStepCount())
		or 0
	local chkSpeakMute = frame and frame:Lookup('CheckBox_Speak')
	local scrollSpeakVolume = frame and frame:Lookup('Scroll_SpeakVolume')
	local nSpeakVolume = chkSpeakMute and chkSpeakMute:IsCheckBoxChecked() and scrollSpeakVolume
		and (scrollSpeakVolume:GetScrollPos() / scrollSpeakVolume:GetStepCount())
		or 0
	local chkErrorMute = frame and frame:Lookup('CheckBox_ErrorSound')
	local scrollErrorVolume = frame and frame:Lookup('Scroll_ErrorVolume')
	local nErrorVolume = chkErrorMute and chkErrorMute:IsCheckBoxChecked() and scrollErrorVolume
		and (scrollErrorVolume:GetScrollPos() / scrollErrorVolume:GetStepCount())
		or 0
	local chkHelpMute = frame and frame:Lookup('CheckBox_Help')
	local scrollHelpVolume = frame and frame:Lookup('Scroll_HelpVolume')
	local nHelpVolume = chkHelpMute and chkHelpMute:IsCheckBoxChecked() and scrollHelpVolume
		and (scrollHelpVolume:GetScrollPos() / scrollHelpVolume:GetStepCount())
		or 0
	if bClose then
		X.UI.CloseFrame('SoundSettingPanel')
	end
	SOUND_VOLUME_CACHE = {
		[SOUND.BG_MUSIC       ] = nBgVolume    * nMainVolume,
		[SOUND.UI_SOUND       ] = nUIVolume    * nMainVolume,
		[SOUND.UI_ERROR_SOUND ] = nErrorVolume * nMainVolume,
		[SOUND.SCENE_SOUND    ] = nSceneVolume * nMainVolume,
		[SOUND.CHARACTER_SOUND] = nRoleVolume  * nMainVolume,
		[SOUND.CHARACTER_SPEAK] = nSpeakVolume * nMainVolume,
		[SOUND.FRESHER_TIP    ] = nHelpVolume  * nMainVolume,
		[SOUND.SYSTEM_TIP     ] = nTipVolume   * nMainVolume,
	}
end

local SOUND_PANEL_OPEN_TIME
X.RegisterEvent('ON_FRAME_CREATE', 'LIB#SOUND_VOLUME', function()
	if arg0 and arg0:GetName() == 'SoundSettingPanel' then
		SOUND_PANEL_OPEN_TIME = GetTickCount()
	end
end)
X.RegisterEvent('ON_FRAME_DESTROY', 'LIB#SOUND_VOLUME', function()
	if arg0 and arg0:GetName() == 'SoundSettingPanel' then
		if GetTickCount() - SOUND_PANEL_OPEN_TIME >= 500 then
			SOUND_VOLUME_CACHE = nil
		end
	end
end)

function X.GetSoundVolume(eChannel)
	if not SOUND_VOLUME_CACHE then
		CaptureSoundVolumes()
	end
	return SOUND_VOLUME_CACHE[eChannel] or 0
end
end

do
local SOUND_ROOT = X.PACKET_INFO.FRAMEWORK_ROOT .. 'audio/'
local SOUNDS = {
	{
		szType = _L['Default'],
		{ dwID = 1, szName = _L['Bing.ogg'], szPath = SOUND_ROOT .. 'Bing.ogg', szWwise = 'UserPluginAudio_MY_Base_Bing' },
		{ dwID = 88001, szName = _L['Notify.ogg'], szPath = SOUND_ROOT .. 'Notify.ogg', szWwise = 'UserPluginAudio_MY_Base_Notify' },
	},
}
local CACHE, WWISE_EVENT = nil, {}
local function GetSoundList()
	local a = { szOption = _L['Sound'] }
	for _, v in ipairs(SOUNDS) do
		table.insert(a, v)
	end
	local RE = _G[X.NSFormatString('{$NS}_Resource')]
	if X.IsTable(RE) and X.IsFunction(RE.GetSoundList) then
		for _, v in ipairs(RE.GetSoundList()) do
			table.insert(a, v)
		end
	end
	return a
end
local function GetSoundMenu(tSound, fnAction, tCheck, bMultiple)
	local t = {}
	if tSound.szType then
		t.szOption = tSound.szType
	elseif tSound.dwID then
		t.szOption = tSound.szName
		t.bCheck = true
		t.bChecked = tCheck[tSound.dwID]
		t.bMCheck = not bMultiple
		t.UserData = tSound
		t.fnAction = fnAction
		t.fnMouseEnter = function()
			if IsCtrlKeyDown() then
				X.PlaySound(SOUND.UI_SOUND, tSound.szPath, false)
			else
				local szXml = GetFormatText(_L['Hold ctrl when move in to preview.'], nil, 255, 255, 0)
				OutputTip(szXml, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end
		end
		t.fnMouseLeave = function()
			HideTip()
		end
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundMenu(v, fnAction, tCheck, bMultiple)
		if t1 then
			table.insert(t, t1)
		end
	end
	if t.dwID and not IsLocalFileExist(t.szPath) then
		return
	end
	return t
end

function X.GetSoundMenu(fnAction, tCheck, bMultiple)
	local function fnMenuAction(tSound, bCheck)
		fnAction(tSound.dwID, bCheck)
	end
	return GetSoundMenu(GetSoundList(), fnMenuAction, tCheck, bMultiple)
end

local function Cache(tSound)
	if not X.IsTable(tSound) then
		return
	end
	if tSound.dwID then
		CACHE[tSound.dwID] = {
			dwID = tSound.dwID,
			szName = tSound.szName,
			szPath = tSound.szPath,
		}
		if tSound.szWwise then
			WWISE_EVENT[string.lower(tSound.szPath)] = tSound.szWwise
		end
	end
	for _, t in ipairs(tSound) do
		Cache(t)
	end
end

local function GeneCache()
	if not CACHE then
		CACHE = {}
		local RE = _G[X.NSFormatString('{$NS}_Resource')]
		if X.IsTable(RE) and X.IsFunction(RE.GetSoundList) then
			local tSound = RE.GetSoundList()
			if tSound then
				Cache(tSound)
			end
		end
		Cache(SOUNDS)
	end
	return true
end

function X.GetSoundName(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szName
end

function X.GetSoundPath(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szPath
end

function X.RegisterWwiseSound(szPath, szEvent)
	WWISE_EVENT[string.lower(szPath)] = szEvent
end

local SOUND_PLAYER
local SOUND_BRIDGE_ROOT = X.PACKET_INFO.DATA_ROOT .. '#cache/sound/'
-- 播放声音
-- X.PlaySound(eChannel, szSoundPath, bAllowCustomize)
---@param eChannel SOUND @音频播放通道
---@param szSoundPath string @音频文件地址
---@param bAllowCustomize boolean @是否允许用户使用个性化音频覆盖，默认允许
function X.PlaySound(eChannel, szSoundPath, bAllowCustomize)
	if not GeneCache() then
		return
	end
	-- 允许简写基础库提供的音频资源地址
	szSoundPath = X.StringReplaceW(szSoundPath, '\\', '/')
	if not X.StringFindW(szSoundPath, '/') then
		szSoundPath = X.ConcatPath(X.PACKET_INFO.FRAMEWORK_ROOT, 'audio', szSoundPath)
	end
	local szFinalPath
	-- 自定义声音覆盖：仅可覆盖本插件的音频资源，覆盖文件位于插件数据文件夹角色配置、全局配置目录下的同名子路径文件
	if not szFinalPath and bAllowCustomize ~= false then
		local szPath = X.GetRelativePath(szSoundPath, '')
		if szPath then
			local szPrefix = X.PACKET_INFO.ROOT:lower()
			if szPath:lower():sub(1, #szPrefix) == szPrefix then
				szPath = szPath:sub(#szPrefix + 1)
				szPath = X.ConcatPath('audio', szPath)
			else
				szPath = nil
			end
		end
		if szPath then
			for _, ePathType in ipairs({
				X.PATH_TYPE.ROLE,
				X.PATH_TYPE.GLOBAL,
			}) do
				local szPath = X.FormatPath({ szPath, ePathType })
				if IsFileExist(szPath) then
					szFinalPath = szPath
					break
				end
			end
		end
	end
	-- 插件内置声音：位于基础库 audio 子文件夹
	if not szFinalPath then
		if IsFileExist(szSoundPath) then
			szFinalPath = szSoundPath
		end
	end
	-- 播放声音
	if szFinalPath then
		if X.ENVIRONMENT.SOUND_DRIVER == 'FMOD' then -- FMOD
			szFinalPath = X.NormalizePath(szFinalPath)
			PlaySound(eChannel, szFinalPath)
		elseif WWISE_EVENT[string.lower(szFinalPath)] then -- WWISE
			PlaySound(eChannel, WWISE_EVENT[string.lower(szFinalPath)])
		else -- fallback
			if not SOUND_PLAYER then
				SOUND_PLAYER = X.UI.GetTempElement('WndWebCef', X.NSFormatString('{$NS}Lib__SoundPlayer'))
			end
			szFinalPath = X.GetAbsolutePath(szFinalPath)
			szFinalPath = X.StringReplaceW(szFinalPath, '\\', '/')
			local SOUND_BRIDGE_PATH = SOUND_BRIDGE_ROOT .. eChannel .. '.html'
			CPath.MakeDir(SOUND_BRIDGE_ROOT)
			SaveDataToFile('<!DOCTYPE html><html><body><audio id="audio" autoplay><source src="' .. X.EncodeFileURI(szFinalPath) .. '"></audio><script>var audio = document.getElementById("audio"); audio.volume = ' .. X.GetSoundVolume(eChannel) .. ';</script></body></html>', SOUND_BRIDGE_PATH)
			SOUND_PLAYER:Navigate('about:blank')
			SOUND_PLAYER:Navigate(X.EncodeFileURI(X.StringReplaceW(X.GetAbsolutePath(SOUND_BRIDGE_PATH), '\\', '/')))
		end
	end
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
