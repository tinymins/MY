--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板主界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local Station, Table_BuffIsVisible, MY_GetBuffName = Station, Table_BuffIsVisible,  LIB.GetBuffName
---------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
local D = {}
local INI_ROOT = PACKET_INFO.ROOT .. 'MY_Cataclysm/ui/'
local CFG = MY_Cataclysm.CFG
local CTM_CONFIG_DEFAULT = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_Cataclysm/config/default/{$lang}.jx3dat')
local CTM_CONFIG_OFFICIAL = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_Cataclysm/config/official/{$lang}.jx3dat')
local CTM_CONFIG_CATACLYSM = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_Cataclysm/config/cataclysm/{$lang}.jx3dat')

local PASSPHRASE
do
local a, b = {111, 198, 5}, 31
for i = 0, 50 do
	for j, v in ipairs({ 23, 112, 234, 156 }) do
		insert(a, (i * j * ((b * v) % 256)) % 256)
	end
end
PASSPHRASE = char(unpack(a))
end

local TEAM_VOTE_REQUEST = {}
local BUFF_LIST = {}
local GKP_RECORD_TOTAL = 0
local CTM_CAPTION = ''
local CTM_CONFIG_PLAYER, CTM_CONFIG_LOADED
local CTM_BUFF_TEAMMON = {}
local DEBUG = false

do
local function InsertBuffListCache(aBuffList, szVia)
	for _, tab in ipairs(aBuffList) do
		local id = tab.dwID or tab.szName
		if id then
			for iid, aList in pairs(BUFF_LIST) do
				if iid == id or (tab.szName and type(iid) == 'number' and Table_GetBuffName(iid, 1) == tab.szName) then
					for i, p in ipairs_r(aList) do
						if (not tab.nLevel or p.nLevel == tab.nLevel)
						and (not tab.szStackOp or p.szStackOp == tab.szStackOp)
						and (not tab.nStackNum or p.nStackNum == tab.nStackNum)
						and (not tab.bOnlyMe or p.bOnlyMe == tab.bOnlyMe)
						and (not tab.bOnlyMine or p.bOnlyMine == tab.bOnlyMine) then
							remove(aList, i)
						end
					end
					if #aList == 0 then
						BUFF_LIST[iid] = nil
					end
				end
			end
			if not tab.bDelete then
				if not BUFF_LIST[id] then
					BUFF_LIST[id] = {}
				end
				insert(BUFF_LIST[id], 1, setmetatable({ szVia = szVia }, { __index = tab }))
			end
		end
	end
end
function D.UpdateBuffListCache()
	BUFF_LIST = {}
	if CFG.bBuffDataTeamMon and CTM_BUFF_TEAMMON then
		InsertBuffListCache(CTM_BUFF_TEAMMON, _L['From MY_TeamMon data'])
	end
	if CFG.aBuffList then
		InsertBuffListCache(CFG.aBuffList, _L['From custom data'])
	end
	if CFG.bBuffPushToOfficial then
		local aBuff = {}
		for _, dwID in pairs(BUFF_LIST) do
			if IsNumber(dwID) then
				insert(aBuff, dwID)
			end
		end
		Raid_MonitorBuffs(aBuff)
	end
	FireUIEvent('CTM_BUFF_LIST_CACHE_UPDATE')
end
end

do
local function ScanTeamMonRule(data)
	if not data.aCataclysmBuff then
		return
	end
	for _, v in ipairs(data.aCataclysmBuff) do
		v = Clone(v)
		v.dwID = data.dwID
		if data.bCheckLevel then
			v.nLevel = data.nLevel
		end
		v.nIcon = data.nIcon
		insert(CTM_BUFF_TEAMMON, v)
	end
end
local function UpdateTeamMonData()
	CTM_BUFF_TEAMMON = {}
	local aData = MY_TeamMon and MY_TeamMon.GetTable and MY_TeamMon.GetTable('BUFF')
	if aData then
		if aData[-1] then
			for _, v in ipairs(aData[-1]) do
				ScanTeamMonRule(v)
			end
		end
		if aData[LIB.GetMapID()] then
			for _, v in ipairs(aData[LIB.GetMapID()]) do
				ScanTeamMonRule(v)
			end
		end
	end
	local aData = MY_TeamMon and MY_TeamMon.GetTable and MY_TeamMon.GetTable('DEBUFF')
	if aData then
		if aData[-1] then
			for _, v in ipairs(aData[-1]) do
				ScanTeamMonRule(v)
			end
		end
		if aData[LIB.GetMapID()] then
			for _, v in ipairs(aData[LIB.GetMapID()]) do
				ScanTeamMonRule(v)
			end
		end
	end
	D.UpdateBuffListCache()
end
LIB.RegisterEvent('LOADING_ENDING.MY_CataclysmMain', UpdateTeamMonData)
local function onTeamMonUpdate()
	if arg0 and not arg0['BUFF'] and not arg0['DEBUFF'] then
		return
	end
	UpdateTeamMonData()
end
LIB.RegisterEvent('MY_TM_DATA_RELOAD.MY_CataclysmMain', onTeamMonUpdate)
end

function D.GetConfigurePath()
	return {'config/cataclysm/' .. MY_Cataclysm.szConfigName .. '.jx3dat', PATH_TYPE.GLOBAL}
end

function D.SaveConfigure()
	if not CTM_CONFIG_LOADED then
		return
	end
	LIB.SaveLUAData(D.GetConfigurePath(), CTM_CONFIG_PLAYER)
end

function D.SetConfig(Config, bKeepBuff)
	if bKeepBuff and CTM_CONFIG_PLAYER then
		Config.aBuffList = CTM_CONFIG_PLAYER.aBuffList
	end
	CTM_CONFIG_LOADED = true
	CTM_CONFIG_PLAYER = Config
	-- update version
	if Config.tBuffList then
		Config.aBuffList = {}
		for k, v in pairs(Config.tBuffList) do
			v.dwID = tonumber(k)
			if not v.dwID then
				v.szName = k
			end
			insert(Config.aBuffList, v)
		end
		Config.tBuffList = nil
	end
	-- options fixed
	if Config.eCss == 'OFFICIAL' then
		for k, v in pairs(CTM_CONFIG_OFFICIAL) do
			if type(CTM_CONFIG_PLAYER[k]) == 'nil' then
				CTM_CONFIG_PLAYER[k] = v
			end
		end
	elseif Config.eCss == 'CATACLYSM' then
		for k, v in pairs(CTM_CONFIG_CATACLYSM) do
			if type(CTM_CONFIG_PLAYER[k]) == 'nil' then
				CTM_CONFIG_PLAYER[k] = v
			end
		end
	else
		for k, v in pairs(CTM_CONFIG_DEFAULT) do
			if type(CTM_CONFIG_PLAYER[k]) == 'nil' then
				CTM_CONFIG_PLAYER[k] = v
			end
		end
	end
	CTM_CONFIG_PLAYER.bFasterHP = false
	setmetatable(CFG, {
		__index = CTM_CONFIG_PLAYER,
		__newindex = CTM_CONFIG_PLAYER,
	})
	D.UpdateBuffListCache()
	D.ReloadCataclysmPanel()
end

function D.SetConfigureName(szConfigName)
	if szConfigName then
		if MY_Cataclysm.szConfigName then
			D.SaveConfigure()
		end
		MY_Cataclysm.szConfigName = szConfigName
	end
	D.SetConfig(LIB.LoadLUAData(D.GetConfigurePath()) or Clone(CTM_CONFIG_DEFAULT))
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_CataclysmMain')
end

local CTM_LOOT_MODE = {
	[PARTY_LOOT_MODE.FREE_FOR_ALL] = {'ui/Image/TargetPanel/Target.UITex', 60},
	[PARTY_LOOT_MODE.DISTRIBUTE]   = {'ui/Image/UICommon/CommonPanel2.UITex', 92},
	[PARTY_LOOT_MODE.GROUP_LOOT]   = {'ui/Image/UICommon/LoginCommon.UITex', 29},
	[PARTY_LOOT_MODE.BIDDING]      = {'ui/Image/UICommon/GoldTeam.UITex', 6},
}
local CTM_LOOT_QUALITY = {
	[0] = 2399,
	[1] = 2396,
	[2] = 2401,
	[3] = 2397,
	[4] = 2402,
	[5] = 2400,
}

function D.InsertForceCountMenu(tMenu)
	local tForceList = {}
	local hTeam = GetClientTeam()
	local nCount = 0
	for nGroupID = 0, hTeam.nGroupNum - 1 do
		local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
		for _, dwMemberID in ipairs(tGroupInfo.MemberList) do
			local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
			if not tForceList[tMemberInfo.dwForceID] then
				tForceList[tMemberInfo.dwForceID] = 0
			end
			tForceList[tMemberInfo.dwForceID] = tForceList[tMemberInfo.dwForceID] + 1
		end
		nCount = nCount + #tGroupInfo.MemberList
	end
	local tSubMenu = { szOption = g_tStrings.STR_RAID_MENU_FORCE_COUNT ..
		FormatString(g_tStrings.STR_ALL_PARENTHESES, nCount)
	}
	for dwForceID, nCount in pairs(tForceList) do
		local szPath, nFrame = GetForceImage(dwForceID)
		insert(tSubMenu, {
			szOption = g_tStrings.tForceTitle[dwForceID] .. '   ' .. nCount,
			rgb = { LIB.GetForceColor(dwForceID) },
			szIcon = szPath,
			nFrame = nFrame,
			szLayer = 'ICON_LEFT'
		})
	end
	insert(tMenu, tSubMenu)
end

function D.InsertDistributeMenu(tMenu)
	local aDistributeMenu = {}
	InsertDistributeMenu(aDistributeMenu, not LIB.IsDistributer())
	for _, menu in ipairs(aDistributeMenu) do
		if menu.szOption == g_tStrings.STR_LOOT_LEVEL then
			insert(menu, 1, {
				bDisable = not LIB.IsDistributer(),
				szOption = g_tStrings.STR_WHITE,
				nFont = 79, rgb = {GetItemFontColorByQuality(1)},
				bMCheck = true, bChecked = GetClientTeam().nRollQuality == 1,
				fnAction = function() GetClientTeam().SetTeamRollQuality(1) end,
			})
			insert(menu, 1, {
				bDisable = not LIB.IsDistributer(),
				szOption = g_tStrings.STR_GRAY,
				nFont = 79, rgb = {GetItemFontColorByQuality(0)},
				bMCheck = true, bChecked = GetClientTeam().nRollQuality == 0,
				fnAction = function() GetClientTeam().SetTeamRollQuality(0) end,
			})
		end
		insert(tMenu, menu)
	end
end

function D.GetTeammateFrame()
	return Station.Lookup('Normal/Teammate')
end

function D.RaidPanel_Switch(bOpen)
	local frame = Station.Lookup('Normal/RaidPanel_Main')
	if bOpen then
		if not frame then
			OpenRaidPanel()
		end
	else
		if frame then
			-- 有一点问题 会被加呼吸 根据判断
			if not D.GetTeammateFrame() then
				Wnd.OpenWindow('Teammate')
			end
			CloseRaidPanel()
			Wnd.CloseWindow('Teammate')
		end
	end
end

function D.TeammatePanel_Switch(bOpen)
	local hFrame = D.GetTeammateFrame()
	if hFrame then
		if bOpen then
			hFrame:Show()
		else
			hFrame:Hide()
		end
	end
end

function D.GetGroupTotal()
	local me, team = GetClientPlayer(), GetClientTeam()
	local nGroup = 0
	if me.IsInRaid() then
		for i = 0, team.nGroupNum - 1 do
			local tGroup = team.GetGroupInfo(i)
			if #tGroup.MemberList > 0 then
				nGroup = nGroup + 1
			end
		end
	else
		nGroup = 1
	end
	return nGroup
end

function D.UpdatePrepareBarPos()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	local hTotal = frame:Lookup('', '')
	local hPrepare = hTotal:Lookup('Handle_Prepare')
	if MY_Cataclysm.bFold or D.GetGroupTotal() < 3 then
		hPrepare:SetRelPos(0, -18)
	else
		local container = frame:Lookup('Container_Main')
		hPrepare:SetRelPos(container:GetRelX() + container:GetW(), 3)
	end
	hTotal:FormatAllItemPos()
end

function D.SetFrameCaption(szText)
	local frame = D.GetFrame()
	if szText then
		CTM_CAPTION = szText
	end
	if frame then
		frame:Lookup('', 'Handle_BG/Text_Caption'):SetText(CTM_CAPTION)
	end
end

function D.SetFrameSize(bEnter)
	local frame = D.GetFrame()
	if frame then
		local nGroup = D.GetGroupTotal()
		local nGroupEx = nGroup
		if CFG.nAutoLinkMode ~= 5 then
			nGroupEx = 1
		end
		local container = frame:Lookup('Container_Main')
		local fScaleX = max(nGroupEx == 1 and 1 or 0, CFG.fScaleX)
		local minW = container:GetRelX() + container:GetW()
		local w = max(128 * nGroupEx * fScaleX, minW + 30)
		local h = select(2, frame:GetSize())
		frame:SetW(w)
		if not bEnter then
			w = max(128 * fScaleX, minW)
		end
		frame:SetDragArea(0, 0, w, h)
		frame:Lookup('', 'Handle_BG/Image_Title_BG'):SetW(w)
		D.UpdatePrepareBarPos()
	end
end

function D.CreateControlBar()
	local me           = GetClientPlayer()
	local team         = GetClientTeam()
	local nLootMode    = team.nLootMode
	local nRollQuality = team.nRollQuality
	local frame        = D.GetFrame()
	local container    = frame:Lookup('Container_Main')
	local szIniFile    = INI_ROOT .. 'MY_CataclysmMain_Button.ini'
	container:Clear()
	-- 团队工具 团队告示
	if me.IsInRaid() then
		container:AppendContentFromIni(szIniFile, 'Wnd_TeamTools')
		container:AppendContentFromIni(szIniFile, 'Wnd_TeamNotice')
	end
	-- 分配模式
	local hLootMode = container:AppendContentFromIni(szIniFile, 'WndButton_LootMode')
	if CTM_LOOT_MODE[nLootMode] then
		hLootMode:Lookup('', 'Image_LootMode'):FromUITex(unpack(CTM_LOOT_MODE[nLootMode]))
	end
	if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE
	or (nLootMode == PARTY_LOOT_MODE.BIDDING and OpenGoldTeam) then
		container:AppendContentFromIni(szIniFile, 'WndButton_LootQuality')
			:Lookup('', 'Image_LootQuality'):FromIconID(CTM_LOOT_QUALITY[nRollQuality])
		container:AppendContentFromIni(szIniFile, 'WndButton_GKP')
	end
	-- 世界标记
	if LIB.IsLeader() then
		container:AppendContentFromIni(szIniFile, 'WndButton_WorldMark')
	end
	-- 语音按钮
	if LIB.GVoiceBase_IsOpen() then --LIB.IsInBattleField() or LIB.IsInArena() or LIB.IsInPubg() or LIB.IsInDungeon() then
		local nSpeakerState = LIB.GVoiceBase_GetSpeakerState()
		container:AppendContentFromIni(szIniFile, 'Wnd_Speaker')
			:Lookup('WndButton_Speaker').nSpeakerState = nSpeakerState
		container:Lookup('Wnd_Speaker/WndButton_Speaker', 'Image_Normal')
			:SetVisible(nSpeakerState == CONSTANT.SPEAKER_STATE.OPEN)
		container:Lookup('Wnd_Speaker/WndButton_Speaker', 'Image_Close_Speaker')
			:SetVisible(nSpeakerState == CONSTANT.SPEAKER_STATE.CLOSE)
		local nMicState = LIB.GVoiceBase_GetMicState()
		container:AppendContentFromIni(szIniFile, 'Wnd_Microphone')
			:Lookup('WndButton_Microphone').nMicState = nMicState
		container:Lookup('Wnd_Microphone/WndButton_Microphone', 'Animate_Input_Mic')
			:SetVisible(nMicState == CONSTANT.MIC_STATE.FREE)
		container:Lookup('Wnd_Microphone/WndButton_Microphone', 'Image_UnInsert_Mic')
			:SetVisible(nMicState == CONSTANT.MIC_STATE.NOT_AVIAL)
		container:Lookup('Wnd_Microphone/WndButton_Microphone', 'Image_Close_Mic')
			:SetVisible(nMicState == CONSTANT.MIC_STATE.CLOSE_NOT_IN_ROOM or nMicState == CONSTANT.MIC_STATE.CLOSE_IN_ROOM)
		local hMicFree = container:Lookup('Wnd_Microphone/WndButton_Microphone', 'Handle_Free_Mic')
		local hMicHotKey = container:Lookup('Wnd_Microphone/WndButton_Microphone', 'Handle_HotKey')
		hMicFree:SetVisible(nMicState == CONSTANT.MIC_STATE.FREE)
		hMicHotKey:SetVisible(nMicState == CONSTANT.MIC_STATE.KEY)
		-- 自动调整语音按钮宽度
		local nMicWidth = hMicFree:GetRelX()
		if nMicState == CONSTANT.MIC_STATE.FREE then
			nMicWidth = nMicWidth + hMicFree:GetW()
		elseif nMicState == CONSTANT.MIC_STATE.KEY then
			nMicWidth = hMicHotKey:GetRelX() + hMicHotKey:GetW()
		end
		container:Lookup('Wnd_Microphone'):SetW(nMicWidth)
	end
	-- 最小化
	container:AppendContentFromIni(szIniFile, 'Wnd_Fold')
		:Lookup('CheckBox_Fold'):Check(MY_Cataclysm.bFold, WNDEVENT_FIRETYPE.PREVENT)
	-- 自动计算宽度
	local nW, wnd = 0
	for i = 0, container:GetAllContentCount() - 1 do
		wnd = container:LookupContent(i)
		wnd:SetRelX(nW)
		nW = nW + wnd:GetW()
	end
	container:SetW(nW)
	container:FormatAllContentPos()
	D.SetFrameSize(false)
	D.SetFrameCaption()
end

-- 创建中间层数据 常用的
function D.CreateItemData()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	for _, p in ipairs({
		{'hMember', 'MY_CataclysmParty_Item.' .. CFG.eFrameStyle .. '.ini', 'Handle_RoleDummy'},
		{'hBuff', 'MY_CataclysmParty_Item.' .. CFG.eFrameStyle .. '.ini', 'Handle_Buff'},
	}) do
		if frame[p[1]] then
			frame:RemoveItemData(frame[p[1]])
		end
		frame[p[1]] = frame:CreateItemData(INI_ROOT .. p[2], p[3]) or frame[p[1]] -- 兼容当前KGUI错误代码
	end
end

function D.OpenCataclysmPanel()
	if not D.GetFrame() then
		if CFG.eCss == '' then
			D.ConfirmRestoreConfig()
		end
		Wnd.OpenWindow(INI_ROOT .. 'MY_CataclysmMain.ini', 'MY_CataclysmMain')
	end
end

function D.CloseCataclysmPanel()
	if D.GetFrame() then
		Wnd.CloseWindow(D.GetFrame())
		MY_CataclysmParty:CloseParty()
		MY_Cataclysm.bFold = false
		FireUIEvent('CTM_SET_FOLD')
	end
end

function D.CheckCataclysmEnable()
	local me = GetClientPlayer()
	if not MY_Cataclysm.bEnable then
		D.CloseCataclysmPanel()
		return false
	end
	if CFG.bShowInRaid and not me.IsInRaid() then
		D.CloseCataclysmPanel()
		return false
	end
	if not me.IsInParty() then
		D.CloseCataclysmPanel()
		return false
	end
	D.OpenCataclysmPanel()
	return true
end

function D.ReloadCataclysmPanel()
	if D.GetFrame() then
		D.CreateItemData()
		D.CreateControlBar()
		MY_CataclysmParty:CloseParty()
		MY_CataclysmParty:ReloadParty()
	end
end

function D.UpdateAnchor(frame)
	local a = CFG.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('LEFTCENTER', 0, 0, 'LEFTCENTER', 100, -200)
	end
end

function D.OnWageStart()
	MY_CataclysmParty:StartTeamVote('wage_agree')
	local nTime = GetCurrentTime()
	local function fnAction()
		D.SetFrameCaption(_L('Wage await %ds...', 30 - (GetCurrentTime() - nTime)))
	end
	fnAction()
	LIB.BreatheCall('MY_Cataclysm_Wage', 1000, fnAction)
end

function D.OnWageFinish()
	MY_CataclysmParty:ClearTeamVote('wage_agree')
	D.SetFrameCaption('')
	LIB.BreatheCall('MY_Cataclysm_Wage', false)
end

-------------------------------------------------
-- 界面创建 事件注册
-------------------------------------------------
MY_CataclysmMain = {}
function MY_CataclysmMain.OnFrameCreate()
	if CFG.bFasterHP then
		this:RegisterEvent('RENDER_FRAME_UPDATE')
	end
	this:RegisterEvent('PARTY_SYNC_MEMBER_DATA')
	this:RegisterEvent('PARTY_ADD_MEMBER')
	this:RegisterEvent('PARTY_DISBAND')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('PARTY_UPDATE_MEMBER_INFO')
	this:RegisterEvent('PARTY_UPDATE_MEMBER_LMR')
	this:RegisterEvent('PARTY_LEVEL_UP_RAID')
	this:RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG')
	this:RegisterEvent('PLAYER_STATE_UPDATE')
	this:RegisterEvent('UPDATE_PLAYER_SCHOOL_ID')
	-- this:RegisterEvent('RIAD_READY_CONFIRM_RECEIVE_QUESTION')
	this:RegisterEvent('RIAD_READY_CONFIRM_RECEIVE_ANSWER')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PARTY_SET_MARK')
	this:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	this:RegisterEvent('TEAM_CHANGE_MEMBER_GROUP')
	this:RegisterEvent('PARTY_SET_FORMATION_LEADER')
	this:RegisterEvent('PARTY_LOOT_MODE_CHANGED')
	this:RegisterEvent('PARTY_ROLL_QUALITY_CHANGED')
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('TARGET_CHANGE')
	this:RegisterEvent('CHARACTER_THREAT_RANKLIST')
	this:RegisterEvent('BUFF_UPDATE')
	this:RegisterEvent('PLAYER_ENTER_SCENE')
	this:RegisterEvent('CTM_BUFF_LIST_CACHE_UPDATE')
	this:RegisterEvent('CTM_SET_FOLD')
	-- 拍团部分 arg0 0=T人 1=分工资
	this:RegisterEvent('TEAM_VOTE_REQUEST')
	-- arg0 回应状态 arg1 dwID arg2 同意=1 反对=0
	this:RegisterEvent('TEAM_VOTE_RESPOND')
	this:RegisterEvent('TEAM_INCOMEMONEY_CHANGE_NOTIFY')
	this:RegisterEvent('SYS_MSG')
	this:RegisterEvent('MY_RAID_REC_BUFF')
	this:RegisterEvent('MY_CAMP_COLOR_UPDATE')
	this:RegisterEvent('MY_FORCE_COLOR_UPDATE')
	this:RegisterEvent('GKP_RECORD_TOTAL')
	this:RegisterEvent('GVOICE_MIC_STATE_CHANGED')
	this:RegisterEvent('GVOICE_SPEAKER_STATE_CHANGED')
	this:RegisterEvent('ON_MY_MOSAICS_RESET')
	if GetClientPlayer() then
		D.UpdateAnchor(this)
		MY_CataclysmParty:AutoLinkAllPanel()
	end
	D.SetFrameSize()
	D.SetFrameCaption()
	D.CreateItemData()
	D.CreateControlBar()
	this:EnableDrag(CFG.bDrag)
end

-------------------------------------------------
-- 拖动窗体 OnFrameDrag
-------------------------------------------------

function MY_CataclysmMain.OnFrameDragSetPosEnd()
	MY_CataclysmParty:AutoLinkAllPanel()
end

function MY_CataclysmMain.OnFrameDragEnd()
	this:CorrectPos()
	CFG.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
	MY_CataclysmParty:AutoLinkAllPanel() -- fix screen pos
end

-------------------------------------------------
-- 事件处理
-------------------------------------------------
do
local function RecBuffWithTabs(tabs, dwOwnerID, dwBuffID, dwSrcID)
	if not tabs then
		return
	end
	for _, tab in ipairs(tabs) do
		if not tab.bOnlyMine or dwSrcID == UI_GetClientPlayerID() then
			MY_CataclysmParty:RecBuff(dwOwnerID, setmetatable({
				dwID      = dwBuffID,
				nLevel    = tab.nLevel or 0,
				bOnlyMine = tab.bOnlyMine or tab.bOnlySelf or tab.bSelf,
			}, { __index = tab }))
		end
	end
end
local function OnBuffUpdate(dwOwnerID, dwID, nLevel, nStackNum, dwSrcID)
	if LIB.IsBossFocusBuff(dwID, nLevel, nStackNum) then
		MY_CataclysmParty:RecBossFocusBuff(dwOwnerID, {
			dwID      = dwID     ,
			nLevel    = nLevel   ,
			nStackNum = nStackNum,
		})
	end
	if Table_BuffIsVisible(dwID, nLevel) then
		local szName = MY_GetBuffName(dwID, nLevel)
		RecBuffWithTabs(BUFF_LIST[dwID], dwOwnerID, dwID, dwSrcID)
		RecBuffWithTabs(BUFF_LIST[szName], dwOwnerID, dwID, dwSrcID)
	end
end
function MY_CataclysmMain.OnEvent(szEvent)
	if szEvent == 'RENDER_FRAME_UPDATE' then
		MY_CataclysmParty:CallDrawHPMP(true)
	elseif szEvent == 'SYS_MSG' then
		if arg0 == 'UI_OME_SKILL_CAST_LOG' and arg2 == 13165 then
			MY_CataclysmParty:KungFuSwitch(arg1)
		end
		if CFG.bShowEffect then
			if arg0 == 'UI_OME_SKILL_EFFECT_LOG' and arg5 == 6252
			and arg1 == GetControlPlayerID() and arg9[SKILL_RESULT_TYPE.THERAPY] then
				MY_CataclysmParty:CallEffect(arg2, 500)
			end
		end
	elseif szEvent == 'PARTY_SYNC_MEMBER_DATA' then
		MY_CataclysmParty:CallRefreshImages(arg1, true, true, nil, true)
		MY_CataclysmParty:CallDrawHPMP(arg1, true)
	elseif szEvent == 'PARTY_ADD_MEMBER' then
		if MY_CataclysmParty:GetPartyFrame(arg2) then
			MY_CataclysmParty:DrawParty(arg2)
		else
			MY_CataclysmParty:CreatePanel(arg2)
			MY_CataclysmParty:DrawParty(arg2)
			D.SetFrameSize()
		end
		if CFG.nAutoLinkMode ~= 5 then
			MY_CataclysmParty:AutoLinkAllPanel()
		end
		D.UpdatePrepareBarPos()
	elseif szEvent == 'PARTY_DELETE_MEMBER' then
		local me = GetClientPlayer()
		if me.dwID == arg1 then
			D.OnWageFinish()
			D.CloseCataclysmPanel()
		else
			local team = GetClientTeam()
			local tGroup = team.GetGroupInfo(arg3)
			if #tGroup.MemberList == 0 then
				MY_CataclysmParty:CloseParty(arg3)
				MY_CataclysmParty:AutoLinkAllPanel()
			else
				MY_CataclysmParty:DrawParty(arg3)
			end
			if CFG.nAutoLinkMode ~= 5 then
				MY_CataclysmParty:AutoLinkAllPanel()
			end
		end
		D.SetFrameSize()
		D.UpdatePrepareBarPos()
	elseif szEvent == 'PARTY_DISBAND' then
		D.OnWageFinish()
		D.CloseCataclysmPanel()
	elseif szEvent == 'PARTY_UPDATE_MEMBER_LMR' then
		MY_CataclysmParty:CallDrawHPMP(arg1, true)
	elseif szEvent == 'PARTY_UPDATE_MEMBER_INFO' then
		MY_CataclysmParty:CallRefreshImages(arg1, false, true, nil, true)
		MY_CataclysmParty:CallDrawHPMP(arg1, true)
	elseif szEvent == 'UPDATE_PLAYER_SCHOOL_ID' then
		if LIB.IsParty(arg0) then
			MY_CataclysmParty:CallRefreshImages(arg0, false, true)
		end
	elseif szEvent == 'PLAYER_STATE_UPDATE' then
		if LIB.IsParty(arg0) then
			MY_CataclysmParty:CallDrawHPMP(arg0, true)
		end
	elseif szEvent == 'PARTY_SET_MEMBER_ONLINE_FLAG' then
		MY_CataclysmParty:CallDrawHPMP(arg1, true)
	elseif szEvent == 'TEAM_AUTHORITY_CHANGED' then
		MY_CataclysmParty:CallRefreshImages(arg2, true)
		MY_CataclysmParty:CallRefreshImages(arg3, true)
		D.CreateControlBar()
	elseif szEvent == 'PARTY_SET_FORMATION_LEADER' then
		MY_CataclysmParty:RefreshFormation()
	elseif szEvent == 'PARTY_SET_MARK' then
		MY_CataclysmParty:RefreshMark()
	elseif szEvent == 'TEAM_VOTE_REQUEST' then
        -- arg0 nVoteType
        -- arg1 nArg0
        -- arg2 nArg1
		if arg0 == 1 then
			D.OnWageStart()
		end
	elseif szEvent == 'TEAM_VOTE_RESPOND' then
        -- arg0 nVoteType
        -- arg1 dwAnswerID
        -- arg2 bYes
        -- arg3 nArg0
        -- arg4 nArg1
		if arg0 == 1 then
			MY_CataclysmParty:ChangeTeamVoteState('wage_agree', arg1, arg2 == 1 and 'resolve' or 'reject')
		end
	elseif szEvent == 'TEAM_INCOMEMONEY_CHANGE_NOTIFY' then
		local nTotalRaidMoney = GetClientTeam().nInComeMoney
		if nTotalRaidMoney and nTotalRaidMoney == 0 then
			D.OnWageFinish()
		end
	-- elseif szEvent == 'RIAD_READY_CONFIRM_RECEIVE_QUESTION' then
	elseif szEvent == 'RIAD_READY_CONFIRM_RECEIVE_ANSWER' then
		MY_CataclysmParty:ChangeTeamVoteState('raid_ready', arg0, arg1 == 1 and 'resolve' or 'reject')
	elseif szEvent == 'TEAM_CHANGE_MEMBER_GROUP' then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		local tSrcGropu = team.GetGroupInfo(arg1)
		-- SrcGroup
		if #tSrcGropu.MemberList == 0 then
			MY_CataclysmParty:CloseParty(arg1)
			MY_CataclysmParty:AutoLinkAllPanel()
		else
			MY_CataclysmParty:DrawParty(arg1)
		end
		-- DstGroup
		if not MY_CataclysmParty:GetPartyFrame(arg2) then
			MY_CataclysmParty:CreatePanel(arg2)
		end
		MY_CataclysmParty:DrawParty(arg2)
		MY_CataclysmParty:RefreshGroupText()
		MY_CataclysmParty:RefreshMark()
		if CFG.nAutoLinkMode ~= 5 then
			MY_CataclysmParty:AutoLinkAllPanel()
		end
		D.SetFrameSize()
	elseif szEvent == 'PARTY_LEVEL_UP_RAID' then
		MY_CataclysmParty:RefreshGroupText()
	elseif szEvent == 'PARTY_LOOT_MODE_CHANGED' then
		D.CreateControlBar()
	elseif szEvent == 'PARTY_ROLL_QUALITY_CHANGED' then
		D.CreateControlBar()
	elseif szEvent == 'TARGET_CHANGE' then
		-- oldid， oldtype, newid, newtype
		MY_CataclysmParty:RefreshTarget(arg0, arg1, arg2, arg3)
	elseif szEvent == 'CHARACTER_THREAT_RANKLIST' then
		MY_CataclysmParty:RefreshThreat(arg0, arg1)
	elseif szEvent == 'MY_RAID_REC_BUFF' then
		MY_CataclysmParty:RecBuff(arg0, arg1)
	elseif szEvent == 'BUFF_UPDATE' then
		-- local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
		--     = arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
		if arg1 then
			return
		end
		OnBuffUpdate(arg0, arg4, arg8, arg5, arg9)
	elseif szEvent == 'PLAYER_ENTER_SCENE' then
		local me = GetClientPlayer()
		if not me then
			return
		end
		local dwID = arg0
		if not me.IsPlayerInMyParty(dwID) then
			return
		end
		local function update()
			local tar = GetPlayer(dwID)
			if not tar then
				return
			end
			local aList, nCount, buff = LIB.GetBuffList(tar)
			if nCount == 0 then
				return LIB.DelayCall(update, 75)
			end
			for i = 1, nCount do
				buff = aList[i]
				OnBuffUpdate(dwID, buff.dwID, buff.nLevel, buff.nStackNum, buff.dwSkillSrcID)
			end
		end
		LIB.DelayCall(update, 75)
	elseif szEvent == 'CTM_BUFF_LIST_CACHE_UPDATE' then
		local team = GetClientTeam()
		if not team then
			return
		end
		MY_CataclysmParty:ClearBuff()
		for _, dwID in ipairs(team.GetTeamMemberList()) do
			local tar = GetPlayer(dwID)
			if tar then
				local aBuff, nCount, buff = LIB.GetBuffList(tar)
				for i = 1, nCount do
					buff = aBuff[i]
					OnBuffUpdate(dwID, buff.dwID, buff.nLevel, buff.nStackNum, buff.dwSkillSrcID)
				end
			end
		end
	elseif szEvent == 'CTM_SET_FOLD' then
		D.UpdatePrepareBarPos()
	elseif szEvent == 'MY_CAMP_COLOR_UPDATE'
	or szEvent == 'MY_FORCE_COLOR_UPDATE' then
		D.ReloadCataclysmPanel()
	elseif szEvent == 'GKP_RECORD_TOTAL' then
		GKP_RECORD_TOTAL = arg0
	elseif szEvent == 'GVOICE_MIC_STATE_CHANGED' then
		D.CreateControlBar()
	elseif szEvent == 'GVOICE_SPEAKER_STATE_CHANGED' then
		D.CreateControlBar()
	elseif szEvent == 'ON_MY_MOSAICS_RESET' then
		D.ReloadCataclysmPanel()
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
		MY_CataclysmParty:RefreshSFX()
		MY_CataclysmParty:AutoLinkAllPanel()
	elseif szEvent == 'LOADING_END' then -- 勿删
		D.OnWageFinish()
		D.ReloadCataclysmPanel()
		D.RaidPanel_Switch(DEBUG)
		D.TeammatePanel_Switch(false)
		D.SetFrameSize()
		D.SetFrameCaption()
	end
end

do
local i = 1
function D.FrameBuffRefreshCall()
	local team = GetClientTeam()
	if not team then
		return
	end
	local aList = team.GetTeamMemberList()
	local nCount = #aList
	if i > nCount then
		i = 1
	end
	local tar = GetPlayer(aList[i])
	if tar then
		local aBuff, nCount, buff = LIB.GetBuffList(tar)
		for i = 1, nCount do
			buff = aBuff[i]
			OnBuffUpdate(tar.dwID, buff.dwID, buff.nLevel, buff.nStackNum, buff.dwSkillSrcID)
		end
	end
	i = i + 1
end
end

function MY_CataclysmMain.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then
		return
	end
	MY_CataclysmParty:RefreshDistance()
	MY_CataclysmParty:RefreshBuff()
	MY_CataclysmParty:RefreshAttention()
	MY_CataclysmParty:RefreshCaution()
	MY_CataclysmParty:RefreshTTarget()
	MY_CataclysmParty:RefreshBossTarget()
	MY_CataclysmParty:RefreshBossFocus()
	local fPrepare, szPrepare, nAlpha
	local dwType, dwID = me.GetTarget()
	if dwType == TARGET.NPC then
		local h = Station.Lookup('Normal/Target', 'Handle_Bar')
		if h and h:IsVisible() then
			local txt = h:Lookup('Text_Name')
			if txt then
				szPrepare = txt:GetText()
			end
			local img = h:Lookup('Image_Progress') or h:Lookup('Image_BarProgress')
			if img then
				fPrepare = img:GetPercentage()
			end
			nAlpha = h:GetAlpha()
		end
	elseif dwType == TARGET.PLAYER then
		local tar = GetPlayer(dwID)
		local dwType, dwID = tar.GetTarget()
		if dwType == TARGET.NPC then
			local h = Station.Lookup('Normal/TargetTarget', 'Handle_Bar')
			if h and h:IsVisible() then
				local txt = h:Lookup('Text_Name')
				if txt then
					szPrepare = txt:GetText()
				end
				local img = h:Lookup('Image_Progress') or h:Lookup('Image_BarProgress')
				if img then
					fPrepare = img:GetPercentage()
				end
				nAlpha = h:GetAlpha()
			end
		end
	end
	local hPrepare = this:Lookup('', 'Handle_Prepare')
	if fPrepare and szPrepare and nAlpha then
		hPrepare:Lookup('Text_Prepare'):SetText(szPrepare)
		hPrepare:Lookup('Image_Prepare'):SetPercentage(fPrepare)
		hPrepare:SetAlpha(nAlpha)
	else
		hPrepare:SetAlpha(0)
	end
	-- kill System Panel
	D.RaidPanel_Switch(DEBUG)
	D.TeammatePanel_Switch(false)
	D.FrameBuffRefreshCall()
	-- 官方代码太容易报错 放最后
	if not this.nBreatheTime or GetTime() - this.nBreatheTime >= 300 then -- 语音最短刷新间隔300ms
		MY_CataclysmParty:RefreshGVoice()
		this.nBreatheTime = GetTime()
	end
	LIB.GVoiceBase_CheckMicState()
end
end

function MY_CataclysmMain.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Option' then
		local me = GetClientPlayer()
		local menu = {}
		if me.IsInRaid() then
			-- 团队就位
			insert(menu, {
				szOption = g_tStrings.STR_RAID_MENU_READY_CONFIRM,
				{
					szOption = g_tStrings.STR_RAID_READY_CONFIRM_START,
					bDisable = not LIB.IsLeader(),
					fnAction = function()
						Send_RaidReadyConfirm()
						MY_CataclysmParty:StartTeamVote('raid_ready')
					end,
				},
				{
					szOption = g_tStrings.STR_RAID_READY_CONFIRM_RESET,
					fnAction = function() MY_CataclysmParty:ClearTeamVote('raid_ready') end,
				}
			})
			insert(menu, { bDevide = true })
		end
		-- 分配
		D.InsertDistributeMenu(menu, not LIB.IsDistributer())
		insert(menu, { bDevide = true })
		if me.IsInRaid() then
			-- 编辑模式
			insert(menu, { szOption = gsub(g_tStrings.STR_RAID_MENU_RAID_EDIT, 'Ctrl', 'Alt'), bDisable = not LIB.IsLeader() or not me.IsInRaid(), bCheck = true, bChecked = CFG.bEditMode, fnAction = function()
				CFG.bEditMode = not CFG.bEditMode
				GetPopupMenu():Hide()
			end })
			-- 人数统计
			insert(menu, { bDevide = true })
			D.InsertForceCountMenu(menu)
			insert(menu, { bDevide = true })
		end
		insert(menu, { szOption = _L['Interface settings'], rgb = { 255, 255, 0 }, fnAction = function()
			LIB.ShowPanel()
			LIB.FocusPanel()
			LIB.SwitchTab('MY_Cataclysm')
		end })
		if LIB.IsDebugClient(true) then
			insert(menu, { bDevide = true })
			insert(menu, { szOption = 'DEBUG', bCheck = true, bChecked = DEBUG, fnAction = function()
				DEBUG = not DEBUG
			end	})
		end
		local nX, nY = Cursor.GetPos(true)
		menu.x, menu.y = nX, nY
		PopupMenu(menu)
	elseif szName == 'WndButton_WorldMark' then
		local me  = GetClientPlayer()
		local dwMapID = me.GetMapID()
		local nMapType = select(2, GetMapParams(dwMapID))
		if not nMapType or nMapType ~= MAP_TYPE.DUNGEON then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.STR_WORLD_MARK)
			return
		end
		Wnd.ToggleWindow('WorldMark')
	elseif szName == 'WndButton_GKP' then
		local team = GetClientTeam()
		local nLootMode = team.nLootMode
		if nLootMode == PARTY_LOOT_MODE.BIDDING then
			return OpenGoldTeam()
		end
		if not MY_GKP_MI then
			return LIB.Alert(_L['Please install and load GKP addon first.'])
		end
		return MY_GKP_MI.TogglePanel()
	elseif szName == 'Wnd_TeamTools' then
		if not MY_TeamTools then
			return LIB.Alert(_L['Please install and load MY_TeamTools addon first.'])
		end
		MY_TeamTools.Toggle()
	elseif szName == 'Wnd_TeamNotice' then
		if not MY_TeamNotice then
			return LIB.Alert(_L['Please install and load MY_TeamNotice addon first.'])
		end
		MY_TeamNotice.OpenFrame()
	elseif szName == 'WndButton_LootMode' or szName == 'WndButton_LootQuality' then
		if LIB.IsDistributer() then
			local menu = {}
			if szName == 'WndButton_LootMode' then
				D.InsertDistributeMenu(menu, not LIB.IsDistributer())
				PopupMenu(menu[1])
			elseif szName == 'WndButton_LootQuality' then
				D.InsertDistributeMenu(menu, not LIB.IsDistributer())
				PopupMenu(menu[2])
			end
		else
			return LIB.Sysmsg(_L['You are not the distrubutor.'])
		end
	elseif szName == 'WndButton_Speaker' then
		LIB.GVoiceBase_SwitchSpeakerState()
	elseif szName == 'WndButton_Microphone' then
		LIB.GVoiceBase_SwitchMicState()
	end
end

function MY_CataclysmMain.OnLButtonDown()
	MY_CataclysmParty:BringToTop()
end

function MY_CataclysmMain.OnRButtonDown()
	MY_CataclysmParty:BringToTop()
end

function MY_CataclysmMain.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Fold' then
		MY_Cataclysm.bFold = true
		FireUIEvent('CTM_SET_FOLD')
	end
end

function MY_CataclysmMain.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Fold' then
		MY_Cataclysm.bFold = false
		FireUIEvent('CTM_SET_FOLD')
	end
end

function MY_CataclysmMain.OnMouseLeave()
	local szName = this:GetName()
	if szName == 'WndButton_GKP'
	or szName == 'WndButton_LootMode'
	or szName == 'WndButton_LootQuality'
	or szName == 'Wnd_TeamTools'
	or szName == 'Wnd_TeamNotice' then
		this:SetAlpha(220)
	end
	if not IsKeyDown('LButton') then
		D.SetFrameSize()
	end
	HideTip()
end

local SPEAKER_TIP = {
	[CONSTANT.SPEAKER_STATE.OPEN ] = g_tStrings.GVOICE_SPEAKER_OPEN_TIP,
	[CONSTANT.SPEAKER_STATE.CLOSE] = g_tStrings.GVOICE_SPEAKER_CLOSE_TIP,
}
local MIC_TIP = setmetatable({
	[CONSTANT.MIC_STATE.NOT_AVIAL        ] = g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP,
	[CONSTANT.MIC_STATE.CLOSE_NOT_IN_ROOM] = g_tStrings.GVOICE_MIC_JOIN_STATE_TIP,
	[CONSTANT.MIC_STATE.CLOSE_IN_ROOM    ] = g_tStrings.GVOICE_MIC_KEY_STATE_TIP,
	[CONSTANT.MIC_STATE.FREE             ] = g_tStrings.GVOICE_MIC_CLOSE_STATE_TIP,
}, {
	__index = function(t, k)
		if k == CONSTANT.MIC_STATE.KEY then
			if LIB.GetHotKey('TOGGLE_GVOCIE_SAY') then
				return (g_tStrings.GVOICE_MIC_FREE_STATE_TIP
					:format(LIB.GetHotKeyDisplay('TOGGLE_GVOCIE_SAY')))
			else
				return g_tStrings.GVOICE_MIC_FREE_STATE_TIP2
			end
		end
	end,
})

function MY_CataclysmMain.OnMouseEnter()
	local szName = this:GetName()
	if szName == 'WndButton_GKP'
	or szName == 'WndButton_LootMode'
	or szName == 'WndButton_LootQuality'
	or szName == 'Wnd_TeamTools'
	or szName == 'Wnd_TeamNotice' then
		this:SetAlpha(255)
	end
	if szName == 'WndButton_Speaker' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(SPEAKER_TIP[this.nSpeakerState]), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
	elseif szName == 'WndButton_Microphone' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(MIC_TIP[this.nMicState]), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
	end
	D.SetFrameSize(true)
end

function D.CheckEnableTeamPanel()
	if D.CheckCataclysmEnable() then
		D.ReloadCataclysmPanel()
	end
	if not MY_Cataclysm.bEnable then
		local me = GetClientPlayer()
		if me.IsInRaid() then
			FireUIEvent('CTM_PANEL_RAID', true)
		elseif me.IsInParty() then
			FireUIEvent('CTM_PANEL_TEAMATE', true)
		end
	end
end

function D.ToggleTeamPanel()
	MY_Cataclysm.bEnable = not MY_Cataclysm.bEnable
	D.CheckEnableTeamPanel()
end

function D.ConfirmRestoreConfig()
	MessageBox({
		szName = 'MY_Cataclysm_Restore_Default',
		szAlignment = 'CENTER',
		szMessage = _L['Please choose your favorite raid style.\nYou can rechoose in setting panel.'],
		{
			szOption = _L['Official style'],
			fnAction = function()
				D.SetConfig(Clone(CTM_CONFIG_OFFICIAL), true)
				D.CheckEnableTeamPanel()
				LIB.SwitchTab('MY_Cataclysm', true)
			end,
		},
		{
			szOption = _L['Cataclysm style'],
			fnAction = function()
				D.SetConfig(Clone(CTM_CONFIG_CATACLYSM), true)
				D.CheckEnableTeamPanel()
				LIB.SwitchTab('MY_Cataclysm', true)
			end,
		},
		{
			szOption = _L['Keep current'],
			fnAction = function()
				if CFG.eCss == '' then
					CFG.eCss = 'DEFAULT'
				end
			end,
		},
	})
end

local ui = {
	GetFrame             = D.GetFrame,
	OpenCataclysmPanel   = D.OpenCataclysmPanel,
	CloseCataclysmPanel  = D.CloseCataclysmPanel,
	SetConfigureName     = D.SetConfigureName,
	SetFrameSize         = D.SetFrameSize,
	UpdateBuffListCache  = D.UpdateBuffListCache,
	CheckEnableTeamPanel = D.CheckEnableTeamPanel,
	ToggleTeamPanel      = D.ToggleTeamPanel,
	CheckCataclysmEnable = D.CheckCataclysmEnable,
	ReloadCataclysmPanel = D.ReloadCataclysmPanel,
	ConfirmRestoreConfig = D.ConfirmRestoreConfig,
}
setmetatable(MY_Cataclysm, { __index = ui, __newindex = function() end, __metatable = true })


LIB.RegisterEvent('CTM_PANEL_TEAMATE', function()
	D.TeammatePanel_Switch(arg0)
end)
LIB.RegisterEvent('CTM_PANEL_RAID', function()
	D.RaidPanel_Switch(arg0)
end)

-- 关于界面打开和刷新面板的时机
-- 1) 普通情况下 组队会触发[PARTY_UPDATE_BASE_INFO]打开+刷新
-- 2) 进入竞技场/战场的情况下 不会触发[PARTY_UPDATE_BASE_INFO]事件
--    需要利用外面注册的[LOADING_END]来打开+刷新
-- 3) 如果在竞技场/战场掉线重上的情况下 需要使用外面注册的[LOADING_END]来打开面板
--    然后在UI上注册的[LOADING_END]的来刷新界面，否则获取不到团队成员，只能获取到有几个队
--    UI的[LOADING_END]晚大约30m，然后就能获取到团队成员了??????
-- 4) 从竞技场/战场回到原服使用外面注册的[LOADING_END]来打开+刷新
-- 5) 普通掉线/过地图使用外面注册的[LOADING_END]打开+刷新，避免过地图时候团队变动没有收到事件的情况。
-- 6) 综上所述的各式各样的奇葩情况 可以做如下的调整
--    利用外面的注册的[LOADING_END]来打开
--    利用UI注册的[LOADING_END]来刷新
--    避免多次重复刷新面板浪费开销

LIB.RegisterEvent('PARTY_UPDATE_BASE_INFO', function()
	D.CheckCataclysmEnable()
	D.ReloadCataclysmPanel()
	PlaySound(SOUND.UI_SOUND, g_sound.Gift)
end)

LIB.RegisterEvent('PARTY_LEVEL_UP_RAID', function()
	D.CheckCataclysmEnable()
	D.ReloadCataclysmPanel()
end)
LIB.RegisterEvent('LOADING_END', D.CheckCataclysmEnable)

-- 保存和读取配置
LIB.RegisterInit('MY_Cataclysm', function() D.SetConfigureName() end)
LIB.RegisterFlush('MY_Cataclysm', D.SaveConfigure)


LIB.RegisterAddonMenu(function()
	return { szOption = _L['Cataclysm Team Panel'], bCheck = true, bChecked = MY_Cataclysm.bEnable, fnAction = D.ToggleTeamPanel }
end)

LIB.RegisterTutorial({
	szKey = 'MY_Cataclysm',
	szMessage = _L['Would you like to use MY cataclysm?'],
	fnRequire = function() return not MY_Cataclysm.bEnable end,
	{
		szOption = _L['Use'],
		bDefault = true,
		fnAction = function()
			MY_Cataclysm.bEnable = true
			D.CheckEnableTeamPanel()
			LIB.RedrawTab('MY_Cataclysm')
		end,
	},
	{
		szOption = _L['Not use'],
		fnAction = function()
			MY_Cataclysm.bEnable = false
			D.CheckEnableTeamPanel()
			LIB.RedrawTab('MY_Cataclysm')
		end,
	},
})
