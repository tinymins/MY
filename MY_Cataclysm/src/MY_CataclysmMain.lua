-- @Author: Webster
-- @Date:   2015-01-21 15:21:19
-- @Last Modified by:   William Chan
-- @Last Modified time: 2017-01-10 14:53:49
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
-----------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Cataclysm/lang/")
local Station, UI_GetClientPlayerID, Table_BuffIsVisible = Station, UI_GetClientPlayerID, Table_BuffIsVisible
local GetBuffName = MY.GetBuffName

local INI_ROOT = MY.GetAddonInfo().szRoot .. "MY_Cataclysm/ui/"
local CTM_CONFIG = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_Cataclysm/config/default/$lang.jx3dat")
local CTM_CONFIG_CATACLYSM = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_Cataclysm/config/ctm/$lang.jx3dat")

local TEAM_VOTE_REQUEST = {}
local BUFF_LIST = {}
local GKP_RECORD_TOTAL = 0
local CTM_CONFIG_PLAYER
local DEBUG = false

MY_Cataclysm = {}
MY_Cataclysm.bDebug = false
MY_Cataclysm.szConfigName = "common"
RegisterCustomData("MY_Cataclysm.szConfigName")

local function UpdateBuffListCache()
	BUFF_LIST = {}
	for _, tab in ipairs(Cataclysm_Main.aBuffList) do
		local id = tab.dwID or tab.szName
		if not BUFF_LIST[id] then
			BUFF_LIST[id] = {}
		end
		insert(BUFF_LIST[id], tab)
	end
end

local function GetConfigurePath()
	return {"config/cataclysm/" .. MY_Cataclysm.szConfigName .. ".jx3dat", MY_DATA_PATH.GLOBAL}
end

local function SetConfig(Config)
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
	for k, v in pairs(CTM_CONFIG) do
		if type(CTM_CONFIG_PLAYER[k]) == "nil" then
			CTM_CONFIG_PLAYER[k] = v
		end
	end
	setmetatable(Cataclysm_Main, {
		__index = CTM_CONFIG_PLAYER,
		__newindex = CTM_CONFIG_PLAYER,
	})
	UpdateBuffListCache()
	CTM_CONFIG_PLAYER.bFasterHP = false
end

local function SetConfigureName(szConfigName)
	if szConfigName then
		MY_Cataclysm.szConfigName = szConfigName
	end
	SetConfig(MY.LoadLUAData(GetConfigurePath()) or clone(CTM_CONFIG_CATACLYSM))
end

local function GetFrame()
	return Station.Lookup("Normal/Cataclysm_Main")
end

local CTM_LOOT_MODE = {
	[PARTY_LOOT_MODE.FREE_FOR_ALL] = {"ui/Image/TargetPanel/Target.UITex", 60},
	[PARTY_LOOT_MODE.DISTRIBUTE]   = {"ui/Image/UICommon/CommonPanel2.UITex", 92},
	[PARTY_LOOT_MODE.GROUP_LOOT]   = {"ui/Image/UICommon/LoginCommon.UITex", 29},
	[PARTY_LOOT_MODE.BIDDING]      = {"ui/Image/UICommon/GoldTeam.UITex", 6},
}
local CTM_LOOT_QUALITY = {
	[0] = 2399,
	[1] = 2396,
	[2] = 2401,
	[3] = 2397,
	[4] = 2402,
	[5] = 2400,
}

local function InsertForceCountMenu(tMenu)
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
		table.insert(tSubMenu, {
			szOption = g_tStrings.tForceTitle[dwForceID] .. "   " .. nCount,
			rgb = { MY.GetForceColor(dwForceID) },
			szIcon = szPath,
			nFrame = nFrame,
			szLayer = "ICON_LEFT"
		})
	end
	table.insert(tMenu, tSubMenu)
end

local _InsertDistributeMenu = InsertDistributeMenu
local function InsertDistributeMenu(tMenu)
	local aDistributeMenu = {}
	_InsertDistributeMenu(aDistributeMenu, not MY.IsDistributer())
	for _, menu in ipairs(aDistributeMenu) do
		if menu.szOption == g_tStrings.STR_LOOT_LEVEL then
			insert(menu, 1, {
				bDisable = not MY.IsDistributer(),
				szOption = g_tStrings.STR_WHITE,
				nFont = 79, rgb = {GetItemFontColorByQuality(1)},
				bMCheck = true, bChecked = GetClientTeam().nRollQuality == 1,
				fnAction = function() GetClientTeam().SetTeamRollQuality(1) end,
			})
			insert(menu, 1, {
				bDisable = not MY.IsDistributer(),
				szOption = g_tStrings.STR_GRAY,
				nFont = 79, rgb = {GetItemFontColorByQuality(0)},
				bMCheck = true, bChecked = GetClientTeam().nRollQuality == 0,
				fnAction = function() GetClientTeam().SetTeamRollQuality(0) end,
			})
		end
		insert(tMenu, menu)
	end
end

local function GetTeammateFrame()
	return Station.Lookup("Normal/Teammate")
end

local function RaidPanel_Switch(bOpen)
	local frame = Station.Lookup("Normal/RaidPanel_Main")
	if bOpen then
		if not frame then
			OpenRaidPanel()
		end
	else
		if frame then
			-- ��һ������ �ᱻ�Ӻ��� �����ж�
			if not GetTeammateFrame() then
				Wnd.OpenWindow("Teammate")
			end
			CloseRaidPanel()
			Wnd.CloseWindow("Teammate")
		end
	end
end

local function TeammatePanel_Switch(bOpen)
	local hFrame = GetTeammateFrame()
	if hFrame then
		if bOpen then
			hFrame:Show()
		else
			hFrame:Hide()
		end
	end
end

local function GetGroupTotal()
	local me, team = GetClientPlayer(), GetClientTeam()
	local nGroup = 0
	if me.IsInRaid() then
		for i = 0, team.nGroupNum - 1 do
			local tGropu = team.GetGroupInfo(i)
			if #tGropu.MemberList > 0 then
				nGroup = nGroup + 1
			end
		end
	else
		nGroup = 1
	end
	return nGroup
end

local function SetFrameSize(bEnter)
	local frame = GetFrame()
	if frame then
		local nGroup = GetGroupTotal()
		local nGroupEx = nGroup
		if Cataclysm_Main.nAutoLinkMode ~= 5 then
			nGroupEx = 1
		end
		local container = frame:Lookup("Container_Main")
		local fScaleX = math.max(nGroupEx == 1 and 1 or 0, Cataclysm_Main.fScaleX)
		local minW = container:GetRelX() + container:GetW()
		local w = max(128 * nGroupEx * fScaleX, minW)
		local h = select(2, frame:GetSize())
		frame:SetW(w)
		if not bEnter then
			w = max(128 * fScaleX, minW)
		end
		frame:SetDragArea(0, 0, w, h)
		frame:Lookup("", "Handle_BG/Image_Title_BG"):SetW(w)
	end
end

local function CreateControlBar()
	local team         = GetClientTeam()
	local nLootMode    = team.nLootMode
	local nRollQuality = team.nRollQuality
	local frame        = GetFrame()
	local container    = frame:Lookup("Container_Main")
	local szIniFile    = INI_ROOT .. "Cataclysm_Button.ini"
	container:Clear()
	-- ����ģʽ
	local hLootMode = container:AppendContentFromIni(szIniFile, "WndButton_LootMode")
	hLootMode:Lookup("", "Image_LootMode"):FromUITex(unpack(CTM_LOOT_MODE[nLootMode]))
	if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE then
		container:AppendContentFromIni(szIniFile, "WndButton_LootQuality")
			:Lookup("", "Image_LootQuality"):FromIconID(CTM_LOOT_QUALITY[nRollQuality])
		container:AppendContentFromIni(szIniFile, "WndButton_GKP")
	end
	-- ������
	if MY.IsLeader() then
		container:AppendContentFromIni(szIniFile, "WndButton_WorldMark")
	end
	-- ������ť
	if GVoiceBase_IsOpen() then --MY.IsInBattleField() or MY.IsInArena() or MY.IsInPubg() or MY.IsInDungeon() then
		local nSpeakerState = GVoiceBase_GetSpeakerState()
		container:AppendContentFromIni(szIniFile, "Wnd_Speaker")
			:Lookup("WndButton_Speaker").nSpeakerState = nSpeakerState
		container:Lookup("Wnd_Speaker/WndButton_Speaker", "Image_Normal")
			:SetVisible(nSpeakerState == SPEAKER_STATE.OPEN)
		container:Lookup("Wnd_Speaker/WndButton_Speaker", "Image_Close_Speaker")
			:SetVisible(nSpeakerState == SPEAKER_STATE.CLOSE)
		local nMicState = GVoiceBase_GetMicState()
		container:AppendContentFromIni(szIniFile, "Wnd_Microphone")
			:Lookup("WndButton_Microphone").nMicState = nMicState
		container:Lookup("Wnd_Microphone/WndButton_Microphone", "Animate_Input_Mic")
			:SetVisible(nMicState == MIC_STATE.FREE)
		container:Lookup("Wnd_Microphone/WndButton_Microphone", "Image_UnInsert_Mic")
			:SetVisible(nMicState == MIC_STATE.NOT_AVIAL)
		container:Lookup("Wnd_Microphone/WndButton_Microphone", "Image_Close_Mic")
			:SetVisible(nMicState == MIC_STATE.CLOSE_NOT_IN_ROOM or nMicState == MIC_STATE.CLOSE_IN_ROOM)
		container:Lookup("Wnd_Microphone/WndButton_Microphone", "Handle_HotKey")
			:SetVisible(nMicState == MIC_STATE.KEY)
		container:Lookup("Wnd_Microphone/WndButton_Microphone", "Handle_Free_Mic")
			:SetVisible(nMicState == MIC_STATE.FREE)
	end
	local nW, wnd = 0
	for i = 0, container:GetAllContentCount() - 1 do
		wnd = container:LookupContent(i)
		wnd:SetRelX(nW)
		nW = nW + wnd:GetW()
	end
	container:SetW(nW)
	container:FormatAllContentPos()
	SetFrameSize(false)
end

-- �����м������ ���õ�
local function CreateItemData()
	local frame = GetFrame()
	if not frame then
		return
	end
	for _, p in ipairs({
		{"hMember", "Cataclysm_Item" .. Cataclysm_Main.nCss .. ".ini", "Handle_RoleDummy"},
		{"hBuff", "Cataclysm_Item" .. Cataclysm_Main.nCss .. ".ini", "Handle_Buff"},
	}) do
		if frame[p[1]] then
			frame:RemoveItemData(frame[p[1]])
		end
		frame[p[1]] = frame:CreateItemData(INI_ROOT .. p[2], p[3]) or frame[p[1]] -- ���ݵ�ǰKGUI�������
	end
end

local function OpenCataclysmPanel()
	if not GetFrame() then
		Wnd.OpenWindow(INI_ROOT .. "Cataclysm_Main.ini", "Cataclysm_Main")
	end
end

local function CloseCataclysmPanel()
	if GetFrame() then
		Wnd.CloseWindow(GetFrame())
		Grid_CTM:CloseParty()
	end
end

local function CheckCataclysmEnable(szEvent)
	local me = GetClientPlayer()
	if not Cataclysm_Main.bRaidEnable then
		CloseCataclysmPanel()
		return false
	end
	if Cataclysm_Main.bShowInRaid and not me.IsInRaid() then
		CloseCataclysmPanel()
		return false
	end
	if not me.IsInParty() then
		CloseCataclysmPanel()
		return false
	end
	OpenCataclysmPanel()
	return true
end

local function ReloadCataclysmPanel()
	if GetFrame() then
		CreateItemData()
		CreateControlBar()
		Grid_CTM:CloseParty()
		Grid_CTM:ReloadParty()
	end
end

local function UpdateAnchor(frame)
	local a = Cataclysm_Main.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint("LEFTCENTER", 0, 0, "LEFTCENTER", 100, -200)
	end
end

-------------------------------------------------
-- ���洴�� �¼�ע��
-------------------------------------------------
Cataclysm_Main = {
	GetFrame            = GetFrame,
	CloseCataclysmPanel = CloseCataclysmPanel,
	OpenCataclysmPanel  = OpenCataclysmPanel,
}
local Cataclysm_Main = Cataclysm_Main
function Cataclysm_Main.OnFrameCreate()
	if Cataclysm_Main.bFasterHP then
		this:RegisterEvent("RENDER_FRAME_UPDATE")
	end
	this:RegisterEvent("PARTY_SYNC_MEMBER_DATA")
	this:RegisterEvent("PARTY_ADD_MEMBER")
	this:RegisterEvent("PARTY_DISBAND")
	this:RegisterEvent("PARTY_DELETE_MEMBER")
	this:RegisterEvent("PARTY_UPDATE_MEMBER_INFO")
	this:RegisterEvent("PARTY_UPDATE_MEMBER_LMR")
	this:RegisterEvent("PARTY_LEVEL_UP_RAID")
	this:RegisterEvent("PARTY_SET_MEMBER_ONLINE_FLAG")
	this:RegisterEvent("PLAYER_STATE_UPDATE")
	this:RegisterEvent("UPDATE_PLAYER_SCHOOL_ID")
	this:RegisterEvent("RIAD_READY_CONFIRM_RECEIVE_ANSWER")
	-- this:RegisterEvent("RIAD_READY_CONFIRM_RECEIVE_QUESTION")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PARTY_SET_MARK")
	this:RegisterEvent("TEAM_AUTHORITY_CHANGED")
	this:RegisterEvent("TEAM_CHANGE_MEMBER_GROUP")
	this:RegisterEvent("PARTY_SET_FORMATION_LEADER")
	this:RegisterEvent("PARTY_LOOT_MODE_CHANGED")
	this:RegisterEvent("PARTY_ROLL_QUALITY_CHANGED")
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("TARGET_CHANGE")
	this:RegisterEvent("BUFF_UPDATE")
	-- ���Ų��� arg0 0=T�� 1=�ֹ���
	this:RegisterEvent("TEAM_VOTE_REQUEST")
	-- arg0 ��Ӧ״̬ arg1 dwID arg2 ͬ��=1 ����=0
	this:RegisterEvent("TEAM_VOTE_RESPOND")
	-- this:RegisterEvent("TEAM_INCOMEMONEY_CHANGE_NOTIFY")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("MY_KUNGFU_SWITCH")
	this:RegisterEvent("MY_RAID_REC_BUFF")
	this:RegisterEvent("GKP_RECORD_TOTAL")
	this:RegisterEvent("GVOICE_MIC_STATE_CHANGED")
	this:RegisterEvent("GVOICE_SPEAKER_STATE_CHANGED")
	if GetClientPlayer() then
		UpdateAnchor(this)
		Grid_CTM:AutoLinkAllPanel()
	end
	SetFrameSize()
	CreateItemData()
	CreateControlBar()
	this:EnableDrag(Cataclysm_Main.bDrag)
end
-------------------------------------------------
-- �϶����� OnFrameDrag
-------------------------------------------------

function Cataclysm_Main.OnFrameDragSetPosEnd()
	Grid_CTM:AutoLinkAllPanel()
end

function Cataclysm_Main.OnFrameDragEnd()
	this:CorrectPos()
	Cataclysm_Main.tAnchor = GetFrameAnchor(this, "TOPLEFT")
	Grid_CTM:AutoLinkAllPanel() -- fix screen pos
end

-------------------------------------------------
-- �¼�����
-------------------------------------------------
do
local function RecBuffWithTabs(tabs, dwOwnerID, dwBuffID, dwSrcID)
	if not tabs then
		return
	end
	for _, tab in ipairs(tabs) do
		if not tab.bOnlySelf or dwSrcID == UI_GetClientPlayerID() then
			Grid_CTM:RecBuff(dwOwnerID, setmetatable({
				dwID      = dwBuffID,
				nLevel    = tab.nLevel or 0,
			}, { __index = tab }))
		end
	end
end
function Cataclysm_Main.OnEvent(szEvent)
	if szEvent == "RENDER_FRAME_UPDATE" then
		Grid_CTM:CallDrawHPMP(true)
	elseif szEvent == "SYS_MSG" then
		if Cataclysm_Main.bShowEffect then
			if arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg5 == 6252 and arg1 == UI_GetClientPlayerID() and arg9[SKILL_RESULT_TYPE.THERAPY] then
				Grid_CTM:CallEffect(arg2, 500)
			end
		end
	elseif szEvent == "PARTY_SYNC_MEMBER_DATA" then
		Grid_CTM:CallRefreshImages(arg1, true, true, nil, true)
		Grid_CTM:CallDrawHPMP(arg1, true)
	elseif szEvent == "PARTY_ADD_MEMBER" then
		if Grid_CTM:GetPartyFrame(arg2) then
			Grid_CTM:DrawParty(arg2)
		else
			Grid_CTM:CreatePanel(arg2)
			Grid_CTM:DrawParty(arg2)
			SetFrameSize()
		end
		if Cataclysm_Main.nAutoLinkMode ~= 5 then
			Grid_CTM:AutoLinkAllPanel()
		end
	elseif szEvent == "PARTY_DELETE_MEMBER" then
		local me = GetClientPlayer()
		if me.dwID == arg1 then
			CloseCataclysmPanel()
		else
			local team = GetClientTeam()
			local tGropu = team.GetGroupInfo(arg3)
			if #tGropu.MemberList == 0 then
				Grid_CTM:CloseParty(arg3)
				Grid_CTM:AutoLinkAllPanel()
			else
				Grid_CTM:DrawParty(arg3)
			end
			if Cataclysm_Main.nAutoLinkMode ~= 5 then
				Grid_CTM:AutoLinkAllPanel()
			end
		end
		SetFrameSize()
	elseif szEvent == "PARTY_DISBAND" then
		CloseCataclysmPanel()
	elseif szEvent == "PARTY_UPDATE_MEMBER_LMR" then
		Grid_CTM:CallDrawHPMP(arg1, true)
	elseif szEvent == "PARTY_UPDATE_MEMBER_INFO" then
		Grid_CTM:CallRefreshImages(arg1, false, true, nil, true)
		Grid_CTM:CallDrawHPMP(arg1, true)
	elseif szEvent == "UPDATE_PLAYER_SCHOOL_ID" then
		if MY.IsParty(arg0) then
			Grid_CTM:CallRefreshImages(arg0, false, true)
		end
	elseif szEvent == "PLAYER_STATE_UPDATE" then
		if MY.IsParty(arg0) then
			Grid_CTM:CallDrawHPMP(arg0, true)
		end
	elseif szEvent == "PARTY_SET_MEMBER_ONLINE_FLAG" then
		Grid_CTM:CallDrawHPMP(arg1, true)
	elseif szEvent == "TEAM_AUTHORITY_CHANGED" then
		Grid_CTM:CallRefreshImages(arg2, true)
		Grid_CTM:CallRefreshImages(arg3, true)
		CreateControlBar()
	elseif szEvent == "PARTY_SET_FORMATION_LEADER" then
		Grid_CTM:RefreshFormation()
	elseif szEvent == "PARTY_SET_MARK" then
		Grid_CTM:RefreshMark()
	-- elseif szEvent == "RIAD_READY_CONFIRM_RECEIVE_QUESTION" then
	elseif szEvent == "TEAM_VOTE_REQUEST" then
		if arg0 == 1 then
			if MY.IsLeader() then
				Grid_CTM:Send_RaidReadyConfirm(true)
			end
		end
	elseif szEvent == "TEAM_VOTE_RESPOND" then
		if arg0 == 1 then
			if MY.IsLeader() then
				Grid_CTM:ChangeReadyConfirm(arg1, arg2 == 1)
			end
		end
	elseif szEvent == "RIAD_READY_CONFIRM_RECEIVE_ANSWER" then
		Grid_CTM:ChangeReadyConfirm(arg0, arg1 == 1)
	elseif szEvent == "TEAM_CHANGE_MEMBER_GROUP" then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		local tSrcGropu = team.GetGroupInfo(arg1)
		-- SrcGroup
		if #tSrcGropu.MemberList == 0 then
			Grid_CTM:CloseParty(arg1)
			Grid_CTM:AutoLinkAllPanel()
		else
			Grid_CTM:DrawParty(arg1)
		end
		-- DstGroup
		if not Grid_CTM:GetPartyFrame(arg2) then
			Grid_CTM:CreatePanel(arg2)
		end
		Grid_CTM:DrawParty(arg2)
		Grid_CTM:RefreshGroupText()
		Grid_CTM:RefreshMark()
		if Cataclysm_Main.nAutoLinkMode ~= 5 then
			Grid_CTM:AutoLinkAllPanel()
		end
		SetFrameSize()
	elseif szEvent == "PARTY_LEVEL_UP_RAID" then
		Grid_CTM:RefreshGroupText()
	elseif szEvent == "PARTY_LOOT_MODE_CHANGED" then
		CreateControlBar()
	elseif szEvent == "PARTY_ROLL_QUALITY_CHANGED" then
		CreateControlBar()
	elseif szEvent == "MY_KUNGFU_SWITCH" then
		Grid_CTM:KungFuSwitch(arg0)
	elseif szEvent == "TARGET_CHANGE" then
		-- oldid�� oldtype, newid, newtype
		Grid_CTM:RefreshTarget(arg0, arg1, arg2, arg3)
	elseif szEvent == "MY_RAID_REC_BUFF" then
		Grid_CTM:RecBuff(arg0, arg1)
	elseif szEvent == "BUFF_UPDATE" then
		-- local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
		--     = arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
		if arg1 then
			return
		end
		if Table_BuffIsVisible(arg4, arg8) then
			local szName = GetBuffName(arg4, arg8)
			RecBuffWithTabs(BUFF_LIST[arg4], arg0, arg4, arg9)
			RecBuffWithTabs(BUFF_LIST[szName], arg0, arg4, arg9)
		end
	elseif szEvent == "GKP_RECORD_TOTAL" then
		GKP_RECORD_TOTAL = arg0
	elseif szEvent == "GVOICE_MIC_STATE_CHANGED" then
		CreateControlBar()
	elseif szEvent == "GVOICE_SPEAKER_STATE_CHANGED" then
		CreateControlBar()
	elseif szEvent == "UI_SCALED" then
		UpdateAnchor(this)
		Grid_CTM:AutoLinkAllPanel()
	elseif szEvent == "LOADING_END" then -- ��ɾ
		ReloadCataclysmPanel()
		RaidPanel_Switch(DEBUG)
		TeammatePanel_Switch(false)
		SetFrameSize()
	end
end
end

function Cataclysm_Main.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then return end
	Grid_CTM:RefreshDistance()
	Grid_CTM:RefreshBuff()
	if Cataclysm_Main.bShowTargetTargetAni then
		Grid_CTM:RefreshTTarget()
	end
	-- kill System Panel
	RaidPanel_Switch(DEBUG)
	TeammatePanel_Switch(false)
	-- �ٷ�����̫���ױ��� �����
	if not this.nBreatheTime or GetTime() - this.nBreatheTime >= 300 then -- �������ˢ�¼��300ms
		Grid_CTM:RefreshGVoice()
		this.nBreatheTime = GetTime()
	end
	GVoiceBase_CheckMicState()
end

function Cataclysm_Main.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Option" then
		local me = GetClientPlayer()
		local menu = {}
		if me.IsInRaid() then
			-- �ŶӾ�λ
			table.insert(menu, { szOption = g_tStrings.STR_RAID_MENU_READY_CONFIRM,
				{ szOption = g_tStrings.STR_RAID_READY_CONFIRM_START, bDisable = not MY.IsLeader(), fnAction = function() Grid_CTM:Send_RaidReadyConfirm() end },
				{ szOption = g_tStrings.STR_RAID_READY_CONFIRM_RESET, bDisable = not MY.IsLeader(), fnAction = function() Grid_CTM:Clear_RaidReadyConfirm() end }
			})
			table.insert(menu, { bDevide = true })
		end
		-- ����
		InsertDistributeMenu(menu, not MY.IsDistributer())
		table.insert(menu, { bDevide = true })
		if me.IsInRaid() then
			-- �༭ģʽ
			table.insert(menu, { szOption = string.gsub(g_tStrings.STR_RAID_MENU_RAID_EDIT, "Ctrl", "Alt"), bDisable = not MY.IsLeader() or not me.IsInRaid(), bCheck = true, bChecked = Cataclysm_Main.bEditMode, fnAction = function()
				Cataclysm_Main.bEditMode = not Cataclysm_Main.bEditMode
				GetPopupMenu():Hide()
			end })
			-- ����ͳ��
			table.insert(menu, { bDevide = true })
			InsertForceCountMenu(menu)
			table.insert(menu, { bDevide = true })
		end
		table.insert(menu, { szOption = _L["Interface settings"], rgb = { 255, 255, 0 }, fnAction = function()
			MY.SwitchTab("MY_Cataclysm")
			MY.OpenPanel()
		end })
		if MY_Cataclysm.bDebug then
			table.insert(menu, { bDevide = true })
			table.insert(menu, { szOption = "DEBUG", bCheck = true, bChecked = DEBUG, fnAction = function()
				DEBUG = not DEBUG
			end	})
		end
		local nX, nY = Cursor.GetPos(true)
		menu.x, menu.y = nX, nY
		PopupMenu(menu)
	elseif szName == "WndButton_WorldMark" then
		local me  = GetClientPlayer()
		local dwMapID = me.GetMapID()
		local nMapType = select(2, GetMapParams(dwMapID))
	    if not nMapType or nMapType ~= MAP_TYPE.DUNGEON then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_WORLD_MARK)
			return
		end
		Wnd.ToggleWindow("WorldMark")
	elseif szName == "WndButton_GKP" then
		if not MY_GKP then
			return MY.Alert(_L["Please install and load GKP addon first."])
		end
		return MY_GKP.TogglePanel()
	elseif szName == "WndButton_LootMode" or szName == "WndButton_LootQuality" then
		if MY.IsDistributer() then
			local menu = {}
			if szName == "WndButton_LootMode" then
				InsertDistributeMenu(menu, not MY.IsDistributer())
				PopupMenu(menu[1])
			elseif szName == "WndButton_LootQuality" then
				InsertDistributeMenu(menu, not MY.IsDistributer())
				PopupMenu(menu[2])
			end
		else
			return MY.Sysmsg({_L["You are not the distrubutor."]})
		end
	elseif szName == "WndButton_Speaker" then
		GVoiceBase_SwitchSpeakerState()
	elseif szName == "WndButton_Microphone" then
		GVoiceBase_SwitchMicState()
	end
end

function Cataclysm_Main.OnLButtonDown()
	Grid_CTM:BringToTop()
end

function Cataclysm_Main.OnRButtonDown()
	Grid_CTM:BringToTop()
end


function Cataclysm_Main.OnMouseLeave()
	local szName = this:GetName()
	if szName == "WndButton_GKP" or szName == "WndButton_LootMode" or szName == "WndButton_LootQuality" then
		this:SetAlpha(220)
	end
	if not IsKeyDown("LButton") then
		SetFrameSize()
	end
	HideTip()
end

local SPEAKER_TIP = {
	[SPEAKER_STATE.OPEN ] = g_tStrings.GVOICE_SPEAKER_OPEN_TIP,
	[SPEAKER_STATE.CLOSE] = g_tStrings.GVOICE_SPEAKER_CLOSE_TIP,
}
local MIC_TIP = setmetatable({
	[MIC_STATE.NOT_AVIAL        ] = g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP,
	[MIC_STATE.CLOSE_NOT_IN_ROOM] = g_tStrings.GVOICE_MIC_JOIN_STATE_TIP,
	[MIC_STATE.CLOSE_IN_ROOM    ] = g_tStrings.GVOICE_MIC_KEY_STATE_TIP,
	[MIC_STATE.FREE             ] = g_tStrings.GVOICE_MIC_CLOSE_STATE_TIP,
}, {
	__index = function(t, k)
		if k == MIC_STATE.KEY then
			if MY.GetHotKey("TOGGLE_GVOCIE_SAY") then
				return (g_tStrings.GVOICE_MIC_FREE_STATE_TIP
					:format(MY.GetHotKeyDisplay("TOGGLE_GVOCIE_SAY")))
			else
				return g_tStrings.GVOICE_MIC_FREE_STATE_TIP2
			end
		end
	end,
})

function Cataclysm_Main.OnMouseEnter()
	local szName = this:GetName()
	if szName == "WndButton_GKP" or szName == "WndButton_LootMode" or szName == "WndButton_LootQuality" then
		this:SetAlpha(255)
	end
	if szName == "WndButton_Speaker" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(SPEAKER_TIP[this.nSpeakerState]), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
	elseif szName == "WndButton_Microphone" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(MIC_TIP[this.nMicState]), 400, { x, y, w, h }, ALW.TOP_BOTTOM)
	end
	SetFrameSize(true)
end

local function CheckEnableTeamPanel()
	if CheckCataclysmEnable() then
		ReloadCataclysmPanel()
	end
	if not Cataclysm_Main.bRaidEnable then
		local me = GetClientPlayer()
		if me.IsInRaid() then
			FireUIEvent("CTM_PANEL_RAID", true)
		elseif me.IsInParty() then
			FireUIEvent("CTM_PANEL_TEAMATE", true)
		end
	end
end

local function ToggleTeamPanel()
	Cataclysm_Main.bRaidEnable = not Cataclysm_Main.bRaidEnable
	CheckEnableTeamPanel()
end

do
local PS = {}
function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:append("Text", { x = x, y = y, text = _L["Cataclysm Team Panel"], font = 27 }, true):autoWidth():height()

	x = x + 10
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Enable Cataclysm Team Panel"],
		oncheck = ToggleTeamPanel, checked = Cataclysm_Main.bRaidEnable,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Only in team"],
		checked = Cataclysm_Main.bShowInRaid,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowInRaid = bCheck
			if CheckCataclysmEnable() then
				ReloadCataclysmPanel()
			end
			local me = GetClientPlayer()
			if me.IsInParty() and not me.IsInRaid() then
				FireUIEvent("CTM_PANEL_TEAMATE", Cataclysm_Main.bShowInRaid)
			end
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append("WndCheckBox", {
		x = x, y = y, text = g_tStrings.WINDOW_LOCK,
		checked = not Cataclysm_Main.bDrag,
		oncheck = function(bCheck)
			Cataclysm_Main.bDrag = not bCheck
			if GetFrame() then
				GetFrame():EnableDrag(not bCheck)
			end
		end,
	}, true):autoWidth():height() + 5

	-- ���ѿ�
	x = X
	y = y + ui:append("Text", { x = x, y = y, text = g_tStrings.STR_RAID_TIP_IMAGE, font = 27 }, true):height()

	x = X + 10
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show ManaCount"],
		checked = Cataclysm_Main.nShowMP,
		oncheck = function(bCheck)
			Cataclysm_Main.nShowMP = bCheck
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndButton2", {
		x = x, y = y, text = g_tStrings.STR_SKILL_MANA .. g_tStrings.FONT,
		onclick = function()
			XGUI.OpenFontPicker(function(nFont)
				Cataclysm_Main.nManaFont = nFont
				if GetFrame() then
					Grid_CTM:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoenable = function() return Cataclysm_Main.nShowMP end,
	}, true):width() + 5

	ui:append("WndSliderBox", {
		x = x, y = y - 1,
		value = Cataclysm_Main.fManaFontScale * 100,
		range = {1, 400},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		textfmt = function(val) return _L("Scale %d%%", val) end,
		onchange = function(val)
			Cataclysm_Main.fManaFontScale = val / 100
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
		autoenable = function() return Cataclysm_Main.nShowMP end,
	}, true)
	y = y + 25

	x = X + 10
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_TIP_TARGET,
		checked = Cataclysm_Main.bShowTargetTargetAni,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowTargetTargetAni = bCheck
			if GetFrame() then
				Grid_CTM:RefreshTTarget()
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show distance"],
		checked = Cataclysm_Main.bShowDistance,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowDistance = bCheck
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Attack Warning"],
		checked = Cataclysm_Main.bHPHitAlert,
		oncheck = function(bCheck)
			Cataclysm_Main.bHPHitAlert = bCheck
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	local me = GetClientPlayer()
	if me.dwForceID == 6 then
		x = x + ui:append("WndCheckBox", {
			x = X + 10, y = y, text = _L["ZuiWu Effect"],
			color = { MY.GetForceColor(6) },
			checked = Cataclysm_Main.bShowEffect,
			oncheck = function(bCheck)
				Cataclysm_Main.bShowEffect = bCheck
			end,
		}, true):autoWidth():width() + 5
	end
	y = y + 25

	-- Ѫ����ʾ
	x = X
	y = y + ui:append("Text", { x = x, y = y, text = g_tStrings.STR_RAID_LIFE_SHOW .. _L["& Icon"], font = 27 }, true):height()

	x = x + 10
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_LIFE_LEFT,
		group = "lifemode", checked = Cataclysm_Main.nHPShownMode2 == 2,
		oncheck = function()
			Cataclysm_Main.nHPShownMode2 = 2
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_LIFE_LOSE,
		group = "lifemode", checked = Cataclysm_Main.nHPShownMode2 == 1,
		oncheck = function()
			Cataclysm_Main.nHPShownMode2 = 1
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_LIFE_HIDE,
		group = "lifemode", checked = Cataclysm_Main.nHPShownMode2 == 0,
		oncheck = function()
			Cataclysm_Main.nHPShownMode2 = 0
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	ui:append("WndSliderBox", {
		x = x, y = y - 1,
		value = Cataclysm_Main.fLifeFontScale * 100,
		range = {1, 400},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		textfmt = function(val) return _L("Scale %d%%", val) end,
		onchange = function(val)
			Cataclysm_Main.fLifeFontScale = val / 100
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
		autoenable = function() return Cataclysm_Main.nHPShownMode2 ~= 0 end,
	}, true)
	y = y + 25

	-- ��ֵ
	x = X + 10
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show Format value"],
		group = "lifval", checked = Cataclysm_Main.nHPShownNumMode == 1,
		autoenable = function() return Cataclysm_Main.nHPShownMode2 ~= 0 end,
		oncheck = function()
			Cataclysm_Main.nHPShownNumMode = 1
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show Percentage value"],
		group = "lifval", checked = Cataclysm_Main.nHPShownNumMode == 2,
		autoenable = function() return Cataclysm_Main.nHPShownMode2 ~= 0 end,
		oncheck = function()
			Cataclysm_Main.nHPShownNumMode = 2
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show full value"],
		group = "lifval", checked = Cataclysm_Main.nHPShownNumMode == 3,
		autoenable = function() return Cataclysm_Main.nHPShownMode2 ~= 0 end,
		oncheck = function()
			Cataclysm_Main.nHPShownNumMode = 3
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	ui:append("WndButton2", {
		x = x, y = y - 1, text = g_tStrings.STR_RAID_LIFE_SHOW .. g_tStrings.FONT,
		onclick = function()
			XGUI.OpenFontPicker(function(nFont)
				Cataclysm_Main.nLifeFont = nFont
				if GetFrame() then
					Grid_CTM:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoenable = function() return Cataclysm_Main.nHPShownMode2 ~= 0 end,
	}, true)
	y = y + 25

	-- Icon
	x = X + 10
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show Force Icon"],
		group = "icon", checked = Cataclysm_Main.nShowIcon == 1,
		oncheck = function()
			Cataclysm_Main.nShowIcon = 1
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, true, nil, true)
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_SHOW_KUNGFU,
		group = "icon", checked = Cataclysm_Main.nShowIcon == 2,
		oncheck = function()
			Cataclysm_Main.nShowIcon = 2
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, true, nil, true)
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show Camp Icon"],
		group = "icon", checked = Cataclysm_Main.nShowIcon == 3,
		oncheck = function()
			Cataclysm_Main.nShowIcon = 3
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, true, nil, true)
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Show Text Force"],
		group = "icon", checked = Cataclysm_Main.nShowIcon == 4,
		oncheck = function()
			Cataclysm_Main.nShowIcon = 4
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, true, nil, true)
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth()
	y = y + 25

	-- ����
	x = X
	y = y + ui:append("Text", { x = x, y = y, text = g_tStrings.OTHER, font = 27 }, true):height()

	x = x + 10
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_TARGET_ASSIST,
		checked = Cataclysm_Main.bTempTargetEnable,
		oncheck = function(bCheck)
			Cataclysm_Main.bTempTargetEnable = bCheck
		end,
	}, true):autoWidth():width()

	y = y + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Don't show Tip in fight"],
		checked = Cataclysm_Main.bTempTargetFightTip,
		oncheck = function(bCheck)
			Cataclysm_Main.bTempTargetFightTip = bCheck
		end,
	}, true):autoWidth():height()

	-- y = y + ui:append("WndCheckBox", { x = 10, y = nY, text = _L["Faster Refresh HP(Greater performance loss)"], checked = Cataclysm_Main.bFasterHP, enable = false })
	-- :Click(function(bCheck)
	-- 	Cataclysm_Main.bFasterHP = bCheck
	-- 	if GetFrame() then
	-- 		if bCheck then
	-- 			GetFrame():RegisterEvent("RENDER_FRAME_UPDATE")
	-- 		else
	-- 			GetFrame():UnRegisterEvent("RENDER_FRAME_UPDATE")
	-- 		end
	-- 	end
	-- end, true):Pos_()

	x = X
	y = y + ui:append("Text", { x = x, y = y, text = _L["configure"], font = 27 }, true):height()

	x = x + 10
	x = x + ui:append("Text", { x = x, y = y, text = _L["Configuration name"] }, true):autoWidth():width() + 5

	x = x + ui:append("WndEditBox", {
		x = x, y = y + 4, w = 200, h = 25,
		text = MY_Cataclysm.szConfigName,
		onchange = function(txt)
			SetConfigureName(txt)
		end,
		onblur = function()
			CheckEnableTeamPanel()
			MY.SwitchTab("MY_Cataclysm", true)
		end,
	}, true):width() + 5

	-- �ָ�Ĭ��
	y = y + ui:append("WndButton2", {
		x = x, y = y, text = _L["Restore default"],
		onclick = function()
			MessageBox({
				szName = "MY_Cataclysm Restore default",
				szAlignment = "CENTER",
				szMessage = _L["Sure to restore default?"],
				{
					szOption = _L["Restore official"],
					fnAction = function()
						local Config = clone(CTM_CONFIG)
						Config.aBuffList = CTM_CONFIG_PLAYER.aBuffList
						SetConfig(Config)
						CheckEnableTeamPanel()
						MY.SwitchTab("MY_Cataclysm", true)
					end,
				},
				{
					szOption = _L["Restore cataclysm"],
					fnAction = function()
						local Config = clone(CTM_CONFIG_CATACLYSM)
						Config.aBuffList = CTM_CONFIG_PLAYER.aBuffList
						SetConfig(Config)
						CheckEnableTeamPanel()
						MY.SwitchTab("MY_Cataclysm", true)
					end,
				},
				{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
			})
		end,
	}, true):height()
end
MY.RegisterPanel("MY_Cataclysm", _L["Cataclysm"], _L["Raid"], "ui/Image/UICommon/RaidTotal.uitex|62", {255, 255, 0}, PS)
end

do
local PS = {}
function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:append("Text", { x = x, y = y, text = _L["Grid Style"], font = 27 }, true):height()

	x = x + 10
	y = y + 5
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_GUILD_NAME .. g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		group = "namecolor", checked = Cataclysm_Main.nColoredName == 1,
		oncheck = function()
			Cataclysm_Main.nColoredName = 1
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, false, nil, true)
				Grid_CTM:CallDrawHPMP(true ,true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_GUILD_NAME .. g_tStrings.STR_RAID_COLOR_NAME_CAMP,
		group = "namecolor", checked = Cataclysm_Main.nColoredName == 2,
		oncheck = function()
			Cataclysm_Main.nColoredName = 2
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, false, nil, true)
				Grid_CTM:CallDrawHPMP(true ,true)
			end
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_GUILD_NAME .. g_tStrings.STR_RAID_COLOR_NAME_NONE,
		group = "namecolor", checked = Cataclysm_Main.nColoredName == 0,
		oncheck = function()
			Cataclysm_Main.nColoredName = 0
			if GetFrame() then
				Grid_CTM:CallRefreshImages(true, false, false, nil, true)
				Grid_CTM:CallDrawHPMP(true ,true)
			end
		end,
	}, true):autoWidth():width() + 5

	-- �����޸�
	y = y + ui:append("WndButton2", {
		x = x, y = y - 3, text = g_tStrings.STR_GUILD_NAME .. g_tStrings.FONT,
		onclick = function()
			XGUI.OpenFontPicker(function(nFont)
				Cataclysm_Main.nNameFont = nFont
				if GetFrame() then
					Grid_CTM:CallRefreshImages(true, false, false, nil, true)
					Grid_CTM:CallDrawHPMP(true, true)
				end
			end)
		end,
	}, true):height()

	x = X + 10
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show AllGrid"],
		checked = Cataclysm_Main.bShowAllGrid,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowAllGrid = bCheck
			ReloadCataclysmPanel()
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_DISTANCE,
		checked = Cataclysm_Main.bEnableDistance,
		oncheck = function(bCheck)
			Cataclysm_Main.bEnableDistance = bCheck
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append("WndSliderBox", {
		x = x, y = y - 1,
		value = Cataclysm_Main.fNameFontScale * 100,
		range = {1, 400},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		textfmt = function(val) return g_tStrings.STR_GUILD_NAME .. _L("Scale %d%%", val) end,
		onchange = function(val)
			Cataclysm_Main.fNameFontScale = val / 100
			if GetFrame() then
				Grid_CTM:CallRefreshImages(nil, nil, nil, nil, true)
			end
		end,
	}, true):height()

	x = X
	y = y + 10
	y = y + ui:append("Text", { x = x, y = y, text = g_tStrings.BACK_COLOR, font = 27 }, true):height()

	x = x + 10
	y = y + 5
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Colored as official team frame"],
		group = "BACK_COLOR", checked = Cataclysm_Main.nBGColorMode == 3,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nBGColorMode = 3
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
			MY.SwitchTab("MY_Cataclysm_GridStyle", true)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_COLOR_NAME_NONE,
		group = "BACK_COLOR", checked = Cataclysm_Main.nBGColorMode == 0,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nBGColorMode = 0
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
			MY.SwitchTab("MY_Cataclysm_GridStyle", true)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Colored according to the distance"],
		group = "BACK_COLOR", checked = Cataclysm_Main.nBGColorMode == 1,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nBGColorMode = 1
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
			MY.SwitchTab("MY_Cataclysm_GridStyle", true)
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		group = "BACK_COLOR", checked = Cataclysm_Main.nBGColorMode == 2,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nBGColorMode = 2
			if GetFrame() then
				Grid_CTM:CallDrawHPMP(true, true)
			end
			MY.SwitchTab("MY_Cataclysm_GridStyle", true)
		end,
	}, true):autoWidth():height() + 5

	if Cataclysm_Main.nBGColorMode ~= 2 then
		-- ���÷ֶξ���ȼ�
		x = X + 10
		if Cataclysm_Main.nBGColorMode == 1 or Cataclysm_Main.nBGColorMode == 3 then
			y = y + ui:append("WndButton3", {
				x = x, y = y, text = _L["Edit Distance Level"],
				onclick = function()
					GetUserInput(_L["distance, distance, ..."], function(szText)
						local t = MY.Split(MY.Trim(szText), ",")
						local tt = {}
						for k, v in ipairs(t) do
							if not tonumber(v) then
								table.remove(t, k)
							else
								table.insert(tt, tonumber(v))
							end
						end
						if #t > 0 then
							Cataclysm_Main.tDistanceLevel = tt
							Cataclysm_Main.tDistanceCol = {}
							Cataclysm_Main.tDistanceAlpha = {}
							for k, v in ipairs(t) do
								table.insert(Cataclysm_Main.tDistanceCol, { 255, 255, 255 })
								table.insert(Cataclysm_Main.tDistanceAlpha, 255)
							end
							MY.SwitchTab("MY_Cataclysm_GridStyle", true)
						end
					end)
				end,
			}, true):height()
		end

		-- �ֶξ��뱳��
		x = X + 20
		for i = 1, #Cataclysm_Main.tDistanceLevel do
			if Cataclysm_Main.nBGColorMode ~= 1 and Cataclysm_Main.nBGColorMode ~= 3 and i > 1 then
				break
			end
			local n = Cataclysm_Main.tDistanceLevel[i - 1] or 0
			local txt = n .. g_tStrings.STR_METER .. " - " .. Cataclysm_Main.tDistanceLevel[i] .. g_tStrings.STR_METER .. g_tStrings.BACK_COLOR
			if Cataclysm_Main.nBGColorMode == 0 then
				txt = g_tStrings.BACK_COLOR
			end
			ui:append("Text", { x = x, y = y, text = txt }):autoWidth()
			if Cataclysm_Main.nBGColorMode == 3 then
				y = y + ui:append("WndSliderBox", {
					x = 280, y = y + 3, h = 22,
					range = {0, 255},
					value = Cataclysm_Main.tDistanceAlpha[i],
					sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
					onchange = function(val)
						Cataclysm_Main.tDistanceAlpha[i] = val
						if GetFrame() then
							Grid_CTM:CallDrawHPMP(true, true)
						end
					end,
				}, true):height() + 5
			else
				y = y + ui:append("Shadow", {
					w = 22, h = 22, x = 280, y = y + 3, color = Cataclysm_Main.tDistanceCol[i],
					onclick = function()
						local this = this
						XGUI.OpenColorPicker(function(r, g, b)
							Cataclysm_Main.tDistanceCol[i] = { r, g, b }
							if GetFrame() then
								Grid_CTM:CallDrawHPMP(true, true)
							end
							XGUI(this):color(r, g, b)
						end)
					end,
				}, true):height() + 5
			end
		end

		-- ��ͬ����Χ����
		ui:append("Text", { x = x, y = y, text = g_tStrings.STR_RAID_DISTANCE_M4 }):autoWidth()
		if Cataclysm_Main.nBGColorMode == 3 then
			y = y + ui:append("WndSliderBox", {
				x = 280, y = y + 3, h = 22,
				range = {0, 255},
				value = Cataclysm_Main.tOtherAlpha[3],
				sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
				onchange = function(val)
					Cataclysm_Main.tOtherAlpha[3] = val
					if GetFrame() then
						Grid_CTM:CallDrawHPMP(true, true)
					end
				end,
			}, true):height() + 5
		else
			y = y + ui:append("Shadow", {
				w = 22, h = 22, x = 280, y = y + 3,
				color = Cataclysm_Main.tOtherCol[3],
				onclick = function()
					local this = this
					XGUI.OpenColorPicker(function(r, g, b)
						Cataclysm_Main.tOtherCol[3] = { r, g, b }
						if GetFrame() then
							Grid_CTM:CallDrawHPMP(true, true)
						end
						XGUI(this):color(r, g, b)
					end)
				end,
			}, true):height() + 5
		end

		-- ���߱���
		ui:append("Text", { x = x, y = y, text = g_tStrings.STR_GUILD_OFFLINE .. g_tStrings.BACK_COLOR }, true):autoWidth()
		if Cataclysm_Main.nBGColorMode == 3 then
			y = y + ui:append("WndSliderBox", {
				x = 280, y = y + 3, h = 22,
				range = {0, 255},
				value = Cataclysm_Main.tOtherAlpha[2],
				sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
				onchange = function(val)
					Cataclysm_Main.tOtherAlpha[2] = val
					if GetFrame() then
						Grid_CTM:CallDrawHPMP(true, true)
					end
				end,
			}, true):height() + 5
		else
			y = y + ui:append("Shadow", {
				w = 22, h = 22, x = 280, y = y + 3, color = Cataclysm_Main.tOtherCol[2],
				onclick = function()
					local this = this
					XGUI.OpenColorPicker(function(r, g, b)
						Cataclysm_Main.tOtherCol[2] = { r, g, b }
						if GetFrame() then
							Grid_CTM:CallDrawHPMP(true, true)
						end
						XGUI(this):color(r, g, b)
					end)
				end,
			}, true):height() + 5
		end

		-- ����
		if Cataclysm_Main.nBGColorMode ~= 3 then
			ui:append("Text", { x = x, y = y, text = g_tStrings.STR_SKILL_MANA .. g_tStrings.BACK_COLOR }, true):autoWidth()
			y = y + ui:append("Shadow", {
				w = 22, h = 22, x = 280, y = y + 3, color = Cataclysm_Main.tManaColor,
				onclick = function()
					XGUI.OpenColorPicker(function(r, g, b)
						Cataclysm_Main.tManaColor = { r, g, b }
						ui:Fetch("STR_SKILL_MANA"):Color(r, g, b)
						if GetFrame() then
							Grid_CTM:CallDrawHPMP(true, true)
						end
					end)
				end,
			}, true):height() + 5
		end
	end

	-- Ѫ����������ɫ
	x = X + 10
	y = y + 5
	if Cataclysm_Main.nBGColorMode ~= 3 then
		x = x + ui:append("WndCheckBox", {
			x = x, y = y, text = _L["LifeBar Gradient"],
			checked = Cataclysm_Main.bLifeGradient,
			oncheck = function(bCheck)
				Cataclysm_Main.bLifeGradient = bCheck
				if GetFrame() then
					Grid_CTM:CallDrawHPMP(true, true)
				end
			end,
		}, true):autoWidth():width() + 5

		x = x + ui:append("WndCheckBox", {
			x = x, y = y, text = _L["ManaBar Gradient"],
			checked = Cataclysm_Main.bManaGradient,
			oncheck = function(bCheck)
				Cataclysm_Main.bManaGradient = bCheck
				if GetFrame() then
					Grid_CTM:CallDrawHPMP(true, true)
				end
			end,
		}, true):autoWidth():width() + 5
	end
end
MY.RegisterPanel("MY_Cataclysm_GridStyle", _L["Grid Style"], _L["Raid"], "ui/Image/UICommon/RaidTotal.uitex|68", {255, 255, 0}, PS)
end

do
local PS = {}
function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:append("Text", { x = x, y = y, text = _L["Interface settings"], font = 27 }, true):height()

	x = X + 10
	y = y + 3
	x = x + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Official team frame style"],
		group = "CSS", checked = Cataclysm_Main.nCss == 1,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nCss = 1
			ReloadCataclysmPanel()
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Cataclysm team frame style"],
		group = "CSS", checked = Cataclysm_Main.nCss == 2,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nCss = 2
			ReloadCataclysmPanel()
		end,
	}, true):autoWidth():height()

	x = X + 10
	x = x + ui:append("Text", { x = x, y = y, text = _L["Interface Width"]}, true):autoWidth():width() + 5
	y = y + ui:append("WndSliderBox", {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = Cataclysm_Main.fScaleX * 100,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = nVal / Cataclysm_Main.fScaleX, Cataclysm_Main.fScaleY / Cataclysm_Main.fScaleY
			Cataclysm_Main.fScaleX = nVal
			if GetFrame() then
				Grid_CTM:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L("%d%%", val) end,
	}, true):height()

	x = X + 10
	x = x + ui:append("Text", { x = x, y = y, text = _L["Interface Height"]}, true):autoWidth():width() + 5
	y = y + ui:append("WndSliderBox", {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = Cataclysm_Main.fScaleY * 100,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = Cataclysm_Main.fScaleX / Cataclysm_Main.fScaleX, nVal / Cataclysm_Main.fScaleY
			Cataclysm_Main.fScaleY = nVal
			if GetFrame() then
				Grid_CTM:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L("%d%%", val) end,
	}, true):height()

	x = X
	y = y + 10
	y = y + ui:append("Text", { x = x, y = y, text = g_tStrings.OTHER, font = 27 }, true):height()

	x = x + 10
	y = y + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show Group Number"],
		checked = Cataclysm_Main.bShowGroupNumber,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowGroupNumber = bCheck
			ReloadCataclysmPanel()
		end,
	}, true):height()

	if Cataclysm_Main.nBGColorMode ~= 3 then
		x = x + ui:append("Text", { x = x, y = y, text = g_tStrings.STR_ALPHA }, true):autoWidth():width() + 5
		y = y + ui:append("WndSliderBox", {
			x = x, y = y + 3,
			range = {0, 255},
			value = Cataclysm_Main.nAlpha,
			sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
			onchange = function(nVal)
				Cataclysm_Main.nAlpha = nVal
				if GetFrame() then
					FireUIEvent("CTM_SET_ALPHA")
				end
			end,
			textfmt = function(val) return _L("%d%%", val / 255 * 100) end,
		}, true):height()
	end

	x = X
	y = y + 10
	y = y + ui:append("Text", { x = x, y = y, text = _L["Arrangement"], font = 27 }, true):height()

	x = x + 10
	y = y + 3
	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["One lines: 5/0"],
		group = "Arrangement", checked = Cataclysm_Main.nAutoLinkMode == 5,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nAutoLinkMode = 5
			if GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Two lines: 1/4"],
		group = "Arrangement", checked = Cataclysm_Main.nAutoLinkMode == 1,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nAutoLinkMode = 1
			if GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Two lines: 2/3"],
		group = "Arrangement", checked = Cataclysm_Main.nAutoLinkMode == 2,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nAutoLinkMode = 2
			if GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Two lines: 3/2"],
		group = "Arrangement", checked = Cataclysm_Main.nAutoLinkMode == 3,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nAutoLinkMode = 3
			if GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append("WndRadioBox", {
		x = x, y = y, text = _L["Two lines: 4/1"],
		group = "Arrangement", checked = Cataclysm_Main.nAutoLinkMode == 4,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			Cataclysm_Main.nAutoLinkMode = 4
			if GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3
end
MY.RegisterPanel("MY_Cataclysm_InterfaceSettings", _L["Interface settings"], _L["Raid"], "ui/Image/UICommon/RaidTotal.uitex|71", {255, 255, 0}, PS)
end

do
-- ����
local function GetListText(aBuffList)
	local aName = {}
	for _, v in ipairs(aBuffList) do
		local a = {}
		insert(a, v.szName or v.dwID)
		if v.nLevel then
			insert(a, "lv" .. v.nLevel)
		end
		if v.nStackNum and v.szStackOp then
			insert(a, "sn" .. v.szStackOp .. v.nStackNum)
		end
		if v.bOnlySelf then
			insert(a, "self")
		end
		a = { concat(a, "|") }

		if v.col then
			local cols = { v.col }
			if v.nColAlpha and v.col:sub(1, 1) ~= "#" then
				insert(cols, v.nColAlpha)
			end
			insert(a, "[" .. concat(cols, "|") .. "]")
		end
		if v.szReminder then
			insert(a, "(" .. v.szReminder .. ")")
		end
		if v.nPriority then
			insert(a, "#" .. v.nPriority)
		end
		insert(aName, (concat(a, ",")))
	end
	return concat(aName, "\n")
end

local function GetTextList(szText)
	local t = {}
	for _, line in ipairs(MY.Split(szText, "\n")) do
		line = MY.Trim(line)
		if line ~= "" then
			local tab = {}
			local vals = MY.Split(line, ",")
			for i, val in ipairs(vals) do
				if i == 1 then
					local vs = MY.Split(val, "|")
					for j, v in ipairs(vs) do
						v = MY.Trim(v)
						if v ~= "" then
							if j == 1 then
								tab.dwID = tonumber(v)
								if not tab.dwID then
									tab.szName = v
								end
							elseif v == "self" then
								tab.bOnlySelf = true
							elseif v:sub(1, 2) == "lv" then
								tab.nLevel = tonumber((v:sub(3)))
							elseif v:sub(1, 2) == "sn" then
								if tonumber(v:sub(4, 4)) then
									tab.szStackOp = v:sub(3, 3)
									tab.nStackNum = tonumber((v:sub(4)))
								else
									tab.szStackOp = v:sub(3, 4)
									tab.nStackNum = tonumber((v:sub(5)))
								end
							end
						end
					end
				elseif val:sub(1, 1) == "#" then
					tab.nPriority = tonumber((val:sub(2)))
				elseif val:sub(1, 1) == "[" and val:sub(-1, -1) == "]" then
					val = val:sub(2, -2)
					if val:sub(1, 1) == "#" then
						tab.col = val
					else
						local vs = MY.Split(val, "|")
						tab.col = vs[1]
						tab.nColAlpha = vs[2] and tonumber(vs[2])
					end
				elseif val:sub(1, 1) == "(" and val:sub(-1, -1) == ")" then
					tab.szReminder = val:sub(2, -2)
				end
			end
			insert(t, tab)
		end
	end
	return t
end

local PS = {}
function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y
	local w, h = ui:size()

	-- BUFF����
	y = y + ui:append("Text", { x = x, y = y, text = _L["Buff settings"], font = 27 }, true):autoSize():height()

	x = X + 10
	x = x + ui:append("Text", { x = x, y = y, text = _L["Max buff count"]}, true):autoWidth():width() + 5
	y = y + ui:append("WndSliderBox", {
		x = x, y = y, text = "",
		range = {0, 10},
		value = Cataclysm_Main.nMaxShowBuff,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		onchange = function(nVal)
			Cataclysm_Main.nMaxShowBuff = nVal
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):height()

	x = X + 10
	x = x + ui:append("Text", { x = x, y = y, text = _L["buff Size"]}, true):autoWidth():width() + 5
	x = x + ui:append("WndCheckBox", {
		x = x, y = y,
		text = g_tStrings.STR_OPTIMIZE_AUTO,
		checked = Cataclysm_Main.bAutoBuffSize,
		oncheck = function(bCheck)
			Cataclysm_Main.bAutoBuffSize = bCheck
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width()
	y = y + ui:append("WndSliderBox", {
		x = x, y = y + 3, h = 25, w = 200,
		enable = not Cataclysm_Main.bAutoBuffSize,
		autoenable = function() return not Cataclysm_Main.bAutoBuffSize end,
		range = {50, 200},
		value = Cataclysm_Main.fBuffScale * 100,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		onchange = function(nVal)
			Cataclysm_Main.fBuffScale = nVal / 100
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
		textfmt = function(val) return _L("%d%%", val) end,
	}, true):autoWidth():height()

	x = X + 10
	y = y + 5
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Buff Staring"],
		checked = Cataclysm_Main.bStaring,
		oncheck = function(bCheck)
			Cataclysm_Main.bStaring = bCheck
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show Buff Time"],
		checked = Cataclysm_Main.bShowBuffTime,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowBuffTime = bCheck
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show Buff Num"],
		checked = Cataclysm_Main.bShowBuffNum,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowBuffNum = bCheck
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	y = y + ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Show Buff Reminder"],
		checked = Cataclysm_Main.bShowBuffReminder,
		oncheck = function(bCheck)
			Cataclysm_Main.bShowBuffReminder = bCheck
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():height()

	-- �ֶ����BUFF����
	x = X
	y = y + 10
	y = y + ui:append("Text", { x = x, y = y, text = _L["Manually add (One per line)"], font = 27 }, true):autoSize():height()

	x = x + 10
	y = y + 5
	y = y + ui:append("WndEditBox",{
		x = x, y = y, w = 450, h = 150, limit = 4096, multiline = true,
		text = GetListText(Cataclysm_Main.aBuffList),
		onchange = function(szText)
			Cataclysm_Main.aBuffList = GetTextList(szText)
			UpdateBuffListCache()
			MY.DelayCall("MY_Cataclysm_Reload", 300, ReloadCataclysmPanel)
		end,
	}, true):height()

	-- С��ʾ
	x = X
	y = y + 10
	y = y + ui:append("Text", { x = x, y = y, text = _L["Tips"], font = 27 }, true):autoSize():height()

	x = x + 10
	y = y + 5
	ui:append("Text", { x = x, y = y, w = w - x * 2, text = _L["Cataclysm_TIPS"], multiline = true }, true):autoHeight()
end
MY.RegisterPanel("MY_Cataclysm_BuffSettings", _L["Buff settings"], _L["Raid"], "ui/Image/UICommon/RaidTotal.uitex|74", {255, 255, 0}, PS)
end

MY.RegisterEvent("CTM_PANEL_TEAMATE", function()
	TeammatePanel_Switch(arg0)
end)
MY.RegisterEvent("CTM_PANEL_RAID", function()
	RaidPanel_Switch(arg0)
end)

-- ���ڽ���򿪺�ˢ������ʱ��
-- 1) ��ͨ����� ��ӻᴥ��[PARTY_UPDATE_BASE_INFO]��+ˢ��
-- 2) ���뾺����/ս��������� ���ᴥ��[PARTY_UPDATE_BASE_INFO]�¼�
--    ��Ҫ��������ע���[LOADING_END]����+ˢ��
-- 3) ����ھ�����/ս���������ϵ������ ��Ҫʹ������ע���[LOADING_END]�������
--    Ȼ����UI��ע���[LOADING_END]����ˢ�½��棬�����ȡ�����Ŷӳ�Ա��ֻ�ܻ�ȡ���м�����
--    UI��[LOADING_END]���Լ30m��Ȼ����ܻ�ȡ���Ŷӳ�Ա��??????
-- 4) �Ӿ�����/ս���ص�ԭ��ʹ������ע���[LOADING_END]����+ˢ��
-- 5) ��ͨ����/����ͼʹ������ע���[LOADING_END]��+ˢ�£��������ͼʱ���Ŷӱ䶯û���յ��¼��������
-- 6) ���������ĸ�ʽ������������� ���������µĵ���
--    ���������ע���[LOADING_END]����
--    ����UIע���[LOADING_END]��ˢ��
--    �������ظ�ˢ������˷ѿ���

MY.RegisterEvent("PARTY_UPDATE_BASE_INFO", function()
	CheckCataclysmEnable()
	ReloadCataclysmPanel()
	PlaySound(SOUND.UI_SOUND, g_sound.Gift)
end)

MY.RegisterEvent("PARTY_LEVEL_UP_RAID", function()
	CheckCataclysmEnable()
	ReloadCataclysmPanel()
end)
MY.RegisterEvent("LOADING_END", CheckCataclysmEnable)

-- ����Ͷ�ȡ����
MY.RegisterExit(function()
	MY.SaveLUAData(GetConfigurePath(), CTM_CONFIG_PLAYER)
end)

MY.RegisterInit("MY_Cataclysm", function() SetConfigureName() end)


MY.RegisterAddonMenu(function()
	return { szOption = _L["Cataclysm Team Panel"], bCheck = true, bChecked = Cataclysm_Main.bRaidEnable, fnAction = ToggleTeamPanel }
end)
