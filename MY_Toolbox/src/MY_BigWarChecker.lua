--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��սû��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = true,
}
RegisterCustomData('MY_BigWarChecker.bEnable')

local function IsBigWarFinishable(me)
	for _, aQuestInfo in ipairs(CONSTANT.QUEST_INFO.BIG_WARS) do
		local info = me.GetQuestTraceInfo(aQuestInfo[1])
		if info then
			local finished = false
			if info.finish then
				finished = true
			elseif info.quest_state then
				finished = true
				for _, state in ipairs(info.quest_state) do
					if state.need ~= state.have then
						finished = false
					end
				end
			end
			if finished then
				return true
			end
		end
	end
end

-- ��սû��
LIB.RegisterFrameCreate('ExitPanel.BIG_WAR_CHECK', function(name, frame)
	local me = GetClientPlayer()
	if me then
		local ui = UI(frame)
		if IsBigWarFinishable(me) then
			OutputWarningMessage('MSG_WARNING_RED', _L['Warning: Bigwar has been finished but not handed yet!'])
			PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			if ui:Children('#Text_MY_Tip'):Count() == 0 then
				ui:Append('Text', { name = 'Text_MY_Tip', y = ui:Height(), w = ui:Width(), color = {255, 255, 0}, font = 199, halign = 1})
			end
			ui:Children('#Text_MY_Tip'):Text(_L['Warning: Bigwar has been finished but not handed yet!'])
			local nTick = GetTime()
			local el = ui:Children('#Text_MY_Tip')[1]
			local SCALE_ANIMATE_TIME, SHAKE_ANIMATE_TIME = 200, 200
			LIB.RenderCall(function()
				if not IsElement(el) then
					return 0
				end
				local nTime = GetTime() - nTick
				if nTime >= SCALE_ANIMATE_TIME then
					el:SetFontScale(1)
					ui:Children('#Text_MY_Tip'):Shake(10, 10, 10, SHAKE_ANIMATE_TIME)
					return 0
				end
				el:SetFontScale((1 - nTime / SCALE_ANIMATE_TIME) * 6 + 1)
			end)
		else
			ui:Children('#Text_MY_Tip'):Remove()
		end
	end
end)
LIB.RegisterFrameCreate('OptionPanel.BIG_WAR_CHECK', function(name, frame)
	local me = GetClientPlayer()
	if me then
		local ui = UI(frame)
		if IsBigWarFinishable(me) then
			if ui:Children('#Text_MY_Tip'):Count() == 0 then
				ui:Append('Text', { name = 'Text_MY_Tip', y = -20, w = ui:Width(), color = {255, 255, 0}, font = 199, halign = 1})
			end
			ui:Children('#Text_MY_Tip'):Text(_L['Warning: Bigwar has been finished but not handed yet!']):Shake(10, 10, 10, 1000)
		else
			ui:Children('#Text_MY_Tip'):Remove()
		end
	end
end)

local TASK_STATE = {
	ACCEPTABLE = 1,
	ACCEPTED = 2,
	FINISHABLE = 3,
	FINISHED = 4,
	UNACCEPTABLE = 5,
	UNKNOWN = 6,
}
local function GetTaskState(me, dwQuestID, dwNpcTemplateID)
	-- ��ȡ��������״̬ -1: ����id�Ƿ� 0: ���񲻴��� 1: �������ڽ����� 2: ������ɵ���û�н� 3: ���������
	local nState = me.GetQuestPhase(dwQuestID)
	if nState == 1 then
		return TASK_STATE.ACCEPTED
	end
	if nState == 2 then
		return TASK_STATE.FINISHABLE
	end
	if nState == 3 then
		return TASK_STATE.FINISHED
	end
	-- ��ȡ����״̬
	if me.GetQuestState(dwQuestID) == QUEST_STATE.FINISHED then
		return TASK_STATE.FINISHED
	end
	-- ��ȡ�Ƿ�ɽ�
	local eCanAccept = me.CanAcceptQuest(dwQuestID, dwNpcTemplateID)
	if eCanAccept == QUEST_RESULT.SUCCESS then
		return TASK_STATE.ACCEPTABLE
	end
	if eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED then
		return TASK_STATE.ACCEPTED
	end
	if eCanAccept == QUEST_RESULT.FINISHED_MAX_COUNT then
		return TASK_STATE.FINISHED
	end
	-- local KQuestInfo = GetQuestInfo(dwQuestID)
	-- if KQuestInfo.bRepeat then -- ���ظ�����û��������һ���ɽӣ���ʱ���ͼ���Ի����в��ɽ��ܣ�
	-- 	return TASK_STATE.ACCEPTABLE
	-- end
	-- if eCanAccept == QUEST_RESULT.FAILED then
	-- 	return TASK_STATE.UNACCEPTABLE
	-- end
	return TASK_STATE.UNKNOWN
end

LIB.RegisterEvent('LOADING_END.MY_BigWarChecker', function()
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	-- ������ս��״̬����
	local aQuestInfo = {}
	for _, v in ipairs(CONSTANT.QUEST_INFO.BIG_WARS) do
		local szPos = Table_GetQuestPosInfo(v[1], 'quest_state', 1)
		local szMap = szPos and szPos:match('N (%d+),')
		local dwMap = szMap and tonumber(szMap)
		insert(aQuestInfo, {
			dwQuestID = v[1],
			dwNpcTemplateID = v[2],
			dwMapID = dwMap,
			eState = GetTaskState(me, v[1], v[2]),
		})
	end
	-- ����һЩ����Ҫ��ʾ�����
	for _, v in ipairs(aQuestInfo) do
		-- �������˴�սֱ�ӷ���
		if v.eState == TASK_STATE.FINISHED or v.eState == TASK_STATE.FINISHABLE then
			return
		end
		-- ����пɽӵĴ�ս���ǲ��������ͼ�򷵻�
		if v.eState == TASK_STATE.ACCEPTABLE and v.dwMapID ~= dwMapID then
			return
		end
	end
	-- �������û�ӵ�ǰ��ͼ��ս�ͱ���
	for _, v in ipairs(aQuestInfo) do
		if v.dwMapID == dwMapID and v.eState ~= TASK_STATE.ACCEPTED and v.eState ~= TASK_STATE.FINISHED then
			local function fnAction()
				OutputWarningMessage('MSG_WARNING_RED', _L['This map is big war map and you did not accepted the quest, is that correct?'])
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			end
			LIB.DelayCall(10000, fnAction)
			fnAction()
			return
		end
	end
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
}
MY_BigWarChecker = LIB.GeneGlobalNS(settings)
end