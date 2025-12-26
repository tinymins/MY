--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·语音
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.GVoice')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-------------------------------------------
-- 语音相关 API
-------------------------------------------

function X.GVoiceBase_IsOpen(...)
	if X.IsFunction(_G.GVoiceBase_IsOpen) then
		return _G.GVoiceBase_IsOpen(...)
	end
	return false
end

function X.GVoiceBase_GetMicState(...)
	if X.IsFunction(_G.GVoiceBase_GetMicState) then
		return _G.GVoiceBase_GetMicState(...)
	end
	return X.CONSTANT.MIC_STATE.CLOSE_NOT_IN_ROOM
end

function X.GVoiceBase_SwitchMicState(...)
	if X.IsFunction(_G.GVoiceBase_SwitchMicState) then
		return _G.GVoiceBase_SwitchMicState(...)
	end
end

function X.GVoiceBase_CheckMicState(...)
	if X.IsFunction(_G.GVoiceBase_CheckMicState) then
		return _G.GVoiceBase_CheckMicState(...)
	end
end

function X.GVoiceBase_GetSpeakerState(...)
	if X.IsFunction(_G.GVoiceBase_GetSpeakerState) then
		return _G.GVoiceBase_GetSpeakerState(...)
	end
	return X.CONSTANT.SPEAKER_STATE.CLOSE
end

function X.GVoiceBase_SwitchSpeakerState(...)
	if X.IsFunction(_G.GVoiceBase_SwitchSpeakerState) then
		return _G.GVoiceBase_SwitchSpeakerState(...)
	end
end

function X.GVoiceBase_GetSaying(...)
	if X.IsFunction(_G.GVoiceBase_GetSaying) then
		return _G.GVoiceBase_GetSaying(...)
	end
	return {}
end

function X.GVoiceBase_IsMemberSaying(...)
	if X.IsFunction(_G.GVoiceBase_IsMemberSaying) then
		return _G.GVoiceBase_IsMemberSaying(...)
	end
	return false
end

function X.GVoiceBase_IsMemberForbid(...)
	if X.IsFunction(_G.GVoiceBase_IsMemberForbid) then
		return _G.GVoiceBase_IsMemberForbid(...)
	end
	return false
end

function X.GVoiceBase_ForbidMember(...)
	if X.IsFunction(_G.GVoiceBase_ForbidMember) then
		return _G.GVoiceBase_ForbidMember(...)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
