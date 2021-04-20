--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ս����־ ��ʽ����ԭʼ�¼�����
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local O = {
	bEnable = false, -- ���ݼ�¼�ܿ���
	nMaxHistory = 300, -- �����ʷ��������
	nMinFightTime = 30, -- ��Сս��ʱ��
	bOnlyDungeon = true, -- �����ؾ�������
	bOnlySelf = true, -- ����¼���Լ��йص�
}
RegisterCustomData('MY_CombatLogs.bEnable')
RegisterCustomData('MY_CombatLogs.nMaxHistory')
RegisterCustomData('MY_CombatLogs.nMinFightTime')
RegisterCustomData('MY_CombatLogs.bOnlyDungeon')
RegisterCustomData('MY_CombatLogs.bOnlySelf')


local D = {}
local DS_ROOT = {'userdata/combat_logs/', PATH_TYPE.ROLE}

local LOG_ENABLE = false -- ����������ܿ��أ���������ʱ����
local LOG_TIME = 0
local LOG_FILE -- ��ǰ��־�ļ������ڴ���ģʽ���������߼�ս��״̬ʱ��Ϊ��
local LOG_CACHE = {} -- ��δ���̵����ݣ����ʹ���ѹ����
local LOG_CACHE_LIMIT = 20 -- �������ݴﵽ������������
local LOG_CRC = 0
local LOG_TARGET_INFO_TIME = {} -- Ŀ����Ϣ��¼ʱ��
local LOG_TARGET_INFO_TIME_LIMIT = 10000 -- Ŀ����Ϣ�ٴμ�¼��Сʱ����
local LOG_DOODAD_INFO_TIME = {} -- ���������Ϣ��¼ʱ��
local LOG_DOODAD_INFO_TIME_LIMIT = 10000 -- ���������Ϣ�ٴμ�¼��Сʱ����

local LOG_REPLAY = {} -- ��������� ����սʱ�����������ѹ������
local LOG_REPLAY_FRAME = GLOBAL.GAME_FPS * 1 -- ��սʱ�򽫶�õ�����ѹ�������߼�֡��

local LOG_TYPE = {
	FIGHT_TIME                            = 1,
	PLAYER_ENTER_SCENE                    = 2,
	PLAYER_LEAVE_SCENE                    = 3,
	PLAYER_INFO                           = 4,
	PLAYER_FIGHT_HINT                     = 5,
	NPC_ENTER_SCENE                       = 6,
	NPC_LEAVE_SCENE                       = 7,
	NPC_INFO                              = 8,
	NPC_FIGHT_HINT                        = 9,
	DOODAD_ENTER_SCENE                    = 10,
	DOODAD_LEAVE_SCENE                    = 11,
	DOODAD_INFO                           = 12,
	BUFF_UPDATE                           = 13,
	PLAYER_SAY                            = 14,
	ON_WARNING_MESSAGE                    = 15,
	PARTY_ADD_MEMBER                      = 16,
	PARTY_SET_MEMBER_ONLINE_FLAG          = 17,
	MSG_SYS                               = 18,
	SYS_MSG_UI_OME_SKILL_CAST_LOG         = 19,
	SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG = 20,
	SYS_MSG_UI_OME_SKILL_EFFECT_LOG       = 21,
	SYS_MSG_UI_OME_SKILL_BLOCK_LOG        = 22,
	SYS_MSG_UI_OME_SKILL_SHIELD_LOG       = 23,
	SYS_MSG_UI_OME_SKILL_MISS_LOG         = 24,
	SYS_MSG_UI_OME_SKILL_HIT_LOG          = 25,
	SYS_MSG_UI_OME_SKILL_DODGE_LOG        = 26,
	SYS_MSG_UI_OME_COMMON_HEALTH_LOG      = 27,
	SYS_MSG_UI_OME_DEATH_NOTIFY           = 28,
}

-- ��������״̬
function D.UpdateEnable()
	local bEnable = O.bEnable and (not O.bOnlyDungeon or LIB.IsInDungeon())
	if not bEnable and LOG_ENABLE then
		D.CloseCombatLogs()
	elseif bEnable and not LOG_ENABLE and LIB.IsFighting() then
		D.OpenCombatLogs()
	end
	LOG_ENABLE = bEnable
end
LIB.RegisterEvent('LOADING_ENDING', D.UpdateEnable)

-- ������ʷ�����б�
function D.GetHistoryFiles()
	local aFiles = {}
	local szRoot = LIB.FormatPath(DS_ROOT)
	for _, v in ipairs(CPath.GetFileList(szRoot)) do
		if v:find('.jcl.tsv$') then
			insert(aFiles, v)
		end
	end
	sort(aFiles, function(a, b) return a > b end)
	for k, v in ipairs(aFiles) do
		aFiles[k] = szRoot .. v
	end
	return aFiles
end

-- ������ʷ��������
function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = O.nMaxHistory + 1, #aFiles do
		CPath.DelFile(aFiles[i])
	end
end

-- ���ӵ��µ���־�ļ�
function D.OpenCombatLogs()
	D.CloseCombatLogs()
	local szRoot = LIB.FormatPath(DS_ROOT)
	CPath.MakeDir(szRoot)
	local szTime = LIB.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
	local szMapName = ''
	local me = GetClientPlayer()
	if me then
		local map = LIB.GetMapInfo(me.GetMapID())
		if map then
			szMapName = '-' .. map.szName
		end
	end
	LOG_FILE = szRoot .. szTime .. szMapName .. '.jcl.log'
	LOG_TIME = GetCurrentTime()
	LOG_CACHE = {}
	LOG_TARGET_INFO_TIME = {}
	LOG_DOODAD_INFO_TIME = {}
	LOG_CRC = 0
	Log(LOG_FILE, '', 'clear')
end

-- �رյ���־�ļ�������
function D.CloseCombatLogs()
	if not LOG_FILE then
		return
	end
	D.FlushLogs(true)
	Log(LOG_FILE, '', 'close')
	if GetCurrentTime() - LOG_TIME < O.nMinFightTime then
		CPath.DelFile(LOG_FILE)
	else
		CPath.Move(LOG_FILE, wsub(LOG_FILE, 1, -5))
	end
	LOG_FILE = nil
end
LIB.RegisterReload('MY_CombatLogs', D.CloseCombatLogs)

-- ����������д�����
function D.FlushLogs(bForce)
	if not LOG_FILE then
		return
	end
	if not bForce and #LOG_CACHE < LOG_CACHE_LIMIT then
		return
	end
	for _, v in ipairs(LOG_CACHE) do
		Log(LOG_FILE, v)
	end
	LOG_CACHE = {}
end

-- �����¼�����
function D.InsertLog(szEvent, oData, bReplay)
	if not LOG_ENABLE then
		return
	end
	assert(szEvent, 'error: missing event id')
	-- ������־��
	local nLFC = GetLogicFrameCount()
	local szLog = nLFC
		.. '\t' .. GetCurrentTime()
		.. '\t' .. GetTime()
		.. '\t' .. szEvent
		.. '\t' .. wgsub(wgsub(LIB.EncodeLUAData(oData), '\\\n', '\\n'), '\t', '\\t')
	local nCRC = GetStringCRC(LOG_CRC .. szLog .. 'c910e9b9-8359-4531-85e0-6897d8c129f7')
	-- ���뻺��
	insert(LOG_CACHE, nCRC .. '\t' .. szLog .. '\n')
	-- ��������¼���
	if bReplay ~= false then
		while LOG_REPLAY[1] and nLFC - LOG_REPLAY[1].nLFC > LOG_REPLAY_FRAME do
			remove(LOG_REPLAY, 1)
		end
		insert(LOG_REPLAY, { nLFC = nLFC, szLog = szLog })
	end
	-- ������ʽУ����
	LOG_CRC = nCRC
	-- ������ݴ���
	D.FlushLogs()
end

-- �ط�����¼�
function D.ImportRecentLogs()
	-- �������¼������뻺��
	local nLFC, nCRC = GetLogicFrameCount(), LOG_CRC
	for _, v in ipairs(LOG_REPLAY) do
		if nLFC - v.nLFC <= LOG_REPLAY_FRAME then
			nCRC = GetStringCRC(nCRC .. v.szLog .. 'c910e9b9-8359-4531-85e0-6897d8c129f7')
			insert(LOG_CACHE, nCRC .. '\t' .. v.szLog .. '\n')
		end
	end
	-- ������ʽУ����
	LOG_CRC = nCRC
	-- ������ݴ���
	D.FlushLogs()
end

-- ��ͼ�����ǰս������
LIB.RegisterEvent({ 'LOADING_ENDING', 'RELOAD_UI_ADDON_END', 'BATTLE_FIELD_END', 'ARENA_END', 'MY_CLIENT_PLAYER_LEAVE_SCENE' }, function()
	D.FlushLogs(true)
end)

-- �˳�ս�� ��������
LIB.RegisterEvent('MY_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local bFighting, szUUID, nDuring = arg0, arg1, arg2
	if not bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring })
	end
	if bFighting then -- �����µ�ս��
		D.OpenCombatLogs()
		D.ImportRecentLogs()
	else
		D.CloseCombatLogs()
	end
	if bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring })
	end
end)

function D.WillRecID(dwID)
	if O.bOnlySelf then
		if not IsPlayer(dwID) then
			local npc = GetNpc(dwID)
			if npc then
				dwID = npc.dwEmployer
			end
		end
		return dwID == UI_GetClientPlayerID()
	end
	return true
end

-- ����Ŀ����Ϣ
function D.OnTargetUpdate(dwID, bForce)
	if not IsNumber(dwID) then
		return
	end
	if not bForce and LOG_TARGET_INFO_TIME[dwID] and LOG_TARGET_INFO_TIME[dwID] - GetTime() < LOG_TARGET_INFO_TIME_LIMIT then
		return
	end
	local bIsPlayer = IsPlayer(dwID)
	if bIsPlayer then
		local player = GetPlayer(dwID)
		if not player then
			return
		end
		local szName = player.szName
		local dwForceID = player.dwForceID
		local dwMountKungfuID = -1
		if dwID == UI_GetClientPlayerID() then
			dwMountKungfuID = UI_GetPlayerMountKungfuID()
		else
			local info = GetClientTeam().GetMemberInfo(dwID)
			if info and not IsEmpty(info.dwMountKungfuID) then
				dwMountKungfuID = info.dwMountKungfuID
			else
				local kungfu = player.GetKungfuMount()
				if kungfu then
					dwMountKungfuID = kungfu.dwSkillID
				end
			end
		end
		local aEquip, nEquipScore = {}, player.GetTotalEquipScore()
		for nEquipIndex, tEquipInfo in pairs(LIB.GetPlayerEquipInfo(player)) do
			insert(aEquip, {
				nEquipIndex,
				tEquipInfo.dwTabType,
				tEquipInfo.dwTabIndex,
				tEquipInfo.nStrengthLevel,
				tEquipInfo.aSlotItem,
				tEquipInfo.dwPermanentEnchantID,
				tEquipInfo.dwTemporaryEnchantID,
				tEquipInfo.dwTemporaryEnchantLeftSeconds,
			})
		end
		D.InsertLog(LOG_TYPE.PLAYER_INFO, { dwID, szName, dwForceID, dwMountKungfuID, nEquipScore, aEquip })
	else
		local npc = GetNpc(dwID)
		if not npc then
			return
		end
		local szName = LIB.GetObjectName(npc, 'never') or ''
		D.InsertLog(LOG_TYPE.NPC_INFO, { dwID, szName, npc.dwTemplateID, npc.dwEmployer, npc.nX, npc.nY, npc.nZ })
	end
	LOG_TARGET_INFO_TIME[dwID] = GetTime()
end

-- ���潻�������Ϣ
function D.OnDoodadUpdate(dwID, bForce)
	if not bForce and LOG_DOODAD_INFO_TIME[dwID] and LOG_DOODAD_INFO_TIME[dwID] - GetTime() < LOG_DOODAD_INFO_TIME_LIMIT then
		return
	end
	local doodad = GetDoodad(dwID)
	if not doodad then
		return
	end
	D.InsertLog(LOG_TYPE.DOODAD_INFO, { dwID, doodad.dwTemplateID, doodad.nX, doodad.nY, doodad.nZ })
	LOG_DOODAD_INFO_TIME[dwID] = GetTime()
end

-- ϵͳ��־��أ�����Դ��
LIB.RegisterEvent('SYS_MSG', function()
	if not LOG_ENABLE then
		return
	end
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		-- ����ʩ����־��
		-- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID (arg3)dwLevel�����ܵȼ�
		-- D.OnSkillCast(arg1, arg2, arg3)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_LOG, { arg1, arg2, arg3 })
		end
	elseif arg0 == 'UI_OME_SKILL_CAST_RESPOND_LOG' then
		-- ����ʩ�Ž����־��
		-- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID
		-- (arg3)dwLevel�����ܵȼ� (arg4)nRespond����ö����[[SKILL_RESULT_CODE]]
		-- D.OnSkillCastRespond(arg1, arg2, arg3, arg4)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG, { arg1, arg2, arg3, arg4 })
		end
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- if not LIB.IsInArena() then
		-- �������ղ�����Ч��������ֵ�ı仯����
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)bReact���Ƿ�Ϊ���� (arg4)nType��Effect���� (arg5)dwID:Effect��ID
		-- (arg6)dwLevel��Effect�ĵȼ� (arg7)bCriticalStrike���Ƿ���� (arg8)nCount��tResultCount���ݱ���Ԫ�ظ��� (arg9)tResultCount����ֵ����
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_EFFECT_LOG, { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 })
		end
	elseif arg0 == 'UI_OME_SKILL_BLOCK_LOG' then
		-- ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)nType��Effect������
		-- (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ� (arg6)nDamageType���˺����ͣ���ö����[[SKILL_RESULT_TYPE]]
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_BLOCK_LOG, { arg1, arg2, arg3, arg4, arg5, arg6 })
		end
	elseif arg0 == 'UI_OME_SKILL_SHIELD_LOG' then
		-- ���ܱ�������־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_SHIELD_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_MISS_LOG' then
		-- ����δ����Ŀ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_MISS_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		-- ��������Ŀ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_HIT_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_DODGE_LOG' then
		-- ���ܱ�������־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_DODGE_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		-- ��ͨ������־��
		-- (arg1)dwCharacterID���������ID (arg2)nDeltaLife������Ѫ��ֵ
		-- D.OnCommonHealth(arg1, arg2)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_COMMON_HEALTH_LOG, { arg1, arg2 })
		end
	elseif arg0 == 'UI_OME_DEATH_NOTIFY' then
		-- ������־��
		-- (arg1)dwCharacterID������Ŀ��ID (arg2)dwKiller����ɱ��ID
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { arg1, arg2 })
		end
	end
end)

-- ϵͳBUFF��أ�����Դ��
LIB.RegisterEvent('BUFF_UPDATE', function()
	-- local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
	--     = arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
	if not LOG_ENABLE then
		return
	end
	-- buff update��
	-- arg0��dwPlayerID��arg1��bDelete��arg2��nIndex��arg3��bCanCancel
	-- arg4��dwBuffID��arg5��nStackNum��arg6��nEndFrame��arg7����update all?
	-- arg8��nLevel��arg9��dwSkillSrcID
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.BUFF_UPDATE, { arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 })
	end
end)

LIB.RegisterEvent('PLAYER_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_ENTER_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_LEAVE_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('NPC_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_ENTER_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('NPC_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_LEAVE_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('DOODAD_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_ENTER_SCENE, { arg0 })
end)

LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_LEAVE_SCENE, { arg0 })
end)

-- ϵͳ��Ϣ��־
LIB.RegisterMsgMonitor('MSG_SYS.MY_Recount_DS_Everything', function(szChannel, szMsg, nFont, bRich)
	if not LOG_ENABLE then
		return
	end
	local szText = szMsg
	if bRich then
		if LIB.ContainsEchoMsgHeader(szMsg) then
			return
		end
		szText = LIB.GetPureText(szMsg)
	end
	szText = szText:gsub('\r', '')
	D.InsertLog(LOG_TYPE.MSG_SYS, { szText, szChannel })
end)

-- ��ɫ������־
LIB.RegisterEvent('PLAYER_SAY', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szContent, arg1: dwTalkerID, arg2: nChannel, arg3: szName, arg4: bOnlyShowBallon
	-- arg5: bSecurity, arg6: bGMAccount, arg7: bCheater, arg8: dwTitleID, arg9: szMsg
	if not IsPlayer(arg1) and D.WillRecID(arg1) then
		local szText = LIB.GetPureText(arg0)
		if szText and szText ~= '' then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.PLAYER_SAY, { szText, arg1, arg2, arg3 })
		end
	end
end)

-- ϵͳ�������־
LIB.RegisterEvent('ON_WARNING_MESSAGE', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szWarningType, arg1: szText
	D.InsertLog(LOG_TYPE.ON_WARNING_MESSAGE, { arg0, arg1 })
end)

-- ��ҽ����˳�ս����־
LIB.RegisterEvent('MY_PLAYER_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = LIB.GetObject(TARGET.PLAYER, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = LIB.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.PLAYER_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- NPC �����˳�ս����־
LIB.RegisterEvent('MY_NPC_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = LIB.GetObject(TARGET.NPC, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = LIB.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.NPC_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- ����������־
LIB.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nOnlineFlag
	if not D.WillRecID(arg1) then
		return
	end
	D.OnTargetUpdate(arg1)
	D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { arg0, arg1, arg2 })
end)

-- ����ս�������¼
LIB.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- ��սɨ����� ��¼��ս������/���ߵ���
	if not LOG_ENABLE then
		return
	end
	local team = GetClientTeam()
	local me = GetClientPlayer()
	if not team or not me or (not me.IsInParty() and not me.IsInRaid()) then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwID)
		if info and D.WillRecID(dwID) then
			D.OnTargetUpdate(dwID)
			if not info.bIsOnLine then
				D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { team.dwTeamID, dwID, 0 })
			elseif info.bDeathFlag then
				D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { dwID, nil })
			end
		end
	end
end)

-- ��;���˽��� ���������¼
LIB.RegisterEvent('PARTY_ADD_MEMBER', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nGroupIndex
	if D.WillRecID(arg1) then
		D.OnTargetUpdate(arg1)
		D.InsertLog(LOG_TYPE.PARTY_ADD_MEMBER, { arg0, arg1, arg2 })
	end
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['MY_CombatLogs'],
		checked = MY_CombatLogs.bEnable,
		oncheck = function(bChecked)
			MY_CombatLogs.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonstyle = 'OPTION',
		autoenable = function() return MY_CombatLogs.bEnable end,
		menu = function()
			local menu = {}
			insert(menu, {
				szOption = _L['Only in dungeon'],
				bCheck = true,
				bChecked = MY_CombatLogs.bOnlyDungeon,
				fnAction = function()
					MY_CombatLogs.bOnlyDungeon = not MY_CombatLogs.bOnlyDungeon
				end,
			})
			insert(menu, {
				szOption = _L['Only self related'],
				bCheck = true,
				bChecked = MY_CombatLogs.bOnlySelf,
				fnAction = function()
					MY_CombatLogs.bOnlySelf = not MY_CombatLogs.bOnlySelf
				end,
			})
			local m0 = { szOption = _L['Max history'] }
			for _, i in ipairs({10, 20, 30, 50, 100, 200, 300, 500, 1000, 2000, 5000}) do
				insert(m0, {
					szOption = tostring(i),
					fnAction = function()
						MY_CombatLogs.nMaxHistory = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMaxHistory == i,
				})
			end
			insert(menu, m0)
			local m0 = { szOption = _L['Min fight time'] }
			for _, i in ipairs({10, 20, 30, 60, 90, 120, 180, 240}) do
				insert(m0, {
					szOption = _L('%s second(s)', i),
					fnAction = function()
						MY_CombatLogs.nMinFightTime = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMinFightTime == i,
				})
			end
			insert(menu, m0)
			insert(menu, {
				szOption = _L['Show data files'],
				fnAction = function()
					UI.OpenTextEditor(LIB.GetAbsolutePath(DS_ROOT))
				end,
			})
			return menu
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + LH
	return nX, nY, nLFY
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
				bEnable       = true,
				nMaxHistory   = true,
				nMinFightTime = true,
				bOnlyDungeon  = true,
				bOnlySelf     = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable       = true,
				nMaxHistory   = true,
				nMinFightTime = true,
				bOnlyDungeon  = true,
				bOnlySelf     = true,
			},
			triggers = {
				bEnable      = D.UpdateEnable,
				bOnlyDungeon = D.UpdateEnable,
				bOnlySelf    = D.UpdateEnable,
			},
			root = O,
		},
	},
}
MY_CombatLogs = LIB.GeneGlobalNS(settings)
end