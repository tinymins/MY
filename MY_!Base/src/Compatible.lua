--------------------------------------------
-- @Desc  : �������������ȫ�ֺ���
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2017-01-24 15:44:51
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
EMPTY_TABLE = SetmetaReadonly({})
XML_LINE_BREAKER = GetFormatText("\n")
MENU_DIVIDER = { bDevide = true }
local XML_LINE_BREAKER = XML_LINE_BREAKER
local srep, tostring, string2byte = string.rep, tostring, string.byte
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local type, next, print, pairs, ipairs = type, next, print, pairs, ipairs
if not GetCampImageFrame then
	function GetCampImageFrame(eCamp, bFight)	-- ui\Image\UICommon\CommonPanel2.UITex
		local nFrame = nil
		if eCamp == CAMP.GOOD then
			if bFight then
				nFrame = 117
			else
				nFrame = 7
			end
		elseif eCamp == CAMP.EVIL then
			if bFight then
				nFrame = 116
			else
				nFrame = 5
			end
		end
		return nFrame
	end
end

if not GetCampImage then
	function GetCampImage(eCamp, bFight)
		local nFrame = GetCampImageFrame(eCamp, bFight)
		if nFrame then
			return 'ui\\Image\\UICommon\\CommonPanel2.UITex', nFrame
		end
	end
end

-- ֻ������
if not SetmetaReadonly then
function SetmetaReadonly(t)
	for k, v in pairs(t) do
		if type(v) == 'table' then
			t[k] = SetmetaReadonly(v)
		end
	end
	return setmetatable({}, {
		__index     = t,
		__newindex  = function() assert(false, 'table is readonly\n') end,
		__metatable = {
			const_table = t,
		},
	})
end
end

-- -- ֻ�����ֵ�ö��
-- if not pairs_c then
-- function pairs_c(t, ...)
-- 	if type(t) == "table" then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == "table" and metatable.const_table then
-- 			return pairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return pairs(t, ...)
-- end
-- end

-- -- ֻ��������ö��
-- if not ipairs_c then
-- function ipairs_c(t, ...)
-- 	if type(t) == "table" then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == "table" and metatable.const_table then
-- 			return ipairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return ipairs(t, ...)
-- end
-- end

if not clone then
function clone(var)
	local szType = type(var)
	if szType == "nil"
	or szType == "boolean"
	or szType == "number"
	or szType == "string" then
		return var
	elseif szType == "table" then
		local t = {}
		for key, val in pairs(var) do
			key = clone(key)
			val = clone(val)
			t[key] = val
		end
		return t
	elseif szType == "function"
	or szType == "userdata" then
		return nil
	else
		return nil
	end
end
end

if not empty then
function empty(var)
	local szType = type(var)
	if szType == "nil" then
		return true
	elseif szType == "boolean" then
		return var
	elseif szType == "number" then
		return var == 0
	elseif szType == "string" then
		return var == ""
	elseif szType == "function" then
		return false
	elseif szType == "table" then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end
end

if not var2str then
function var2str(var, indent, level)
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == "nil" then
			tinsert(t, "nil")
		elseif szType == "number" then
			tinsert(t, tostring(var))
		elseif szType == "string" then
			tinsert(t, string.format("%q", var))
		elseif szType == "function" then
			local s = string.dump(var)
			tinsert(t, 'loadstring("')
			-- "string slice too long"
			for i = 1, #s, 2000 do
				tinsert(t, tconcat({'', string2byte(s, i, i + 2000 - 1)}, "\\"))
			end
			tinsert(t, '")')
		elseif szType == "boolean" then
			tinsert(t, tostring(var))
		elseif szType == "table" then
			tinsert(t, "{")
			local s_tab_equ = "]="
			if indent then
				s_tab_equ = "] = "
				if not empty(var) then
					tinsert(t, "\n")
				end
			end
			for key, val in pairs(var) do
				if indent then
					tinsert(t, srep(indent, level + 1))
				end
				tinsert(t, "[")
				tinsert(t, table_r(key, level + 1, indent))
				tinsert(t, s_tab_equ) --"] = "
				tinsert(t, table_r(val, level + 1, indent))
				tinsert(t, ",")
				if indent then
					tinsert(t, "\n")
				end
			end
			if indent and not empty(var) then
				tinsert(t, srep(indent, level))
			end
			tinsert(t, "}")
		else --if (szType == "userdata") then
			tinsert(t, '"')
			tinsert(t, tostring(var))
			tinsert(t, '"')
		end
		return tconcat(t)
	end
	return table_r(var, level or 0, indent)
end
end

local _RoleName
if not GetUserRoleName then
function GetUserRoleName()
	if not _RoleName then
		_RoleName = GetClientPlayer() and GetClientPlayer().szName
	end
	return _RoleName
end
end

if not GetUserAccount then
function GetUserAccount()
	local szAccount
	local hFrame = Wnd.OpenWindow("LoginPassword")
	if hFrame then
		local hEdit = hFrame:Lookup('WndPassword/Edit_Account')
		if hEdit then
			szAccount = hEdit:GetText()
		end
		Wnd.CloseWindow(hFrame)
	end
	return szAccount
end
end

-- get item name by item
if not GetItemNameByItem then
function GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end
end

if not GetItemNameByItemInfo then
function GetItemNameByItemInfo(itemInfo, nBookInfo)
	if itemInfo.nGenre == ITEM_GENRE.BOOK then
		if nBookInfo then
			local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
			return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
		else
			return Table_GetItemName(itemInfo.nUiId)
		end
	else
		return Table_GetItemName(itemInfo.nUiId)
	end
end
end

if not GetItemNameByUIID then
function GetItemNameByUIID(nUiId)
	return Table_GetItemName(nUiId)
end
end

if not UI_OBJECT then
UI_OBJECT = SetmetaReadonly({
	NONE             = -1, -- ��Box
	ITEM             = 0 , -- �����е���Ʒ��nUiId, dwBox, dwX, nItemVersion, nTabType, nIndex
	SHOP_ITEM        = 1 , -- �̵�������۵���Ʒ nUiId, dwID, dwShopID, dwIndex
	OTER_PLAYER_ITEM = 2 , -- ����������ϵ���Ʒ nUiId, dwBox, dwX, dwPlayerID
	ITEM_ONLY_ID     = 3 , -- ֻ��һ��ID����Ʒ������װ������֮��ġ�nUiId, dwID, nItemVersion, nTabType, nIndex
	ITEM_INFO        = 4 , -- ������Ʒ nUiId, nItemVersion, nTabType, nIndex, nCount(��nCount����dwRecipeID)
	SKILL            = 5 , -- ���ܡ�dwSkillID, dwSkillLevel, dwOwnerID
	CRAFT            = 6 , -- ���ա�dwProfessionID, dwBranchID, dwCraftID
	SKILL_RECIPE     = 7 , -- �䷽dwID, dwLevel
	SYS_BTN          = 8 , -- ϵͳ����ݷ�ʽdwID
	MACRO            = 9 , -- ��
	MOUNT            = 10, -- ��Ƕ
	ENCHANT          = 11, -- ��ħ
	NOT_NEED_KNOWN   = 15, -- ����Ҫ֪������
	PENDANT          = 16, -- �Ҽ�
	PET              = 17, -- ����
	MEDAL            = 18, -- �������
	BUFF             = 19, -- BUFF
	MONEY            = 20, -- ��Ǯ
	TRAIN            = 21, -- ��Ϊ
	EMOTION_ACTION   = 22, -- ��������
})
end

GLOBAL_HEAD_CLIENTPLAYER = GLOBAL_HEAD_CLIENTPLAYER or 0
GLOBAL_HEAD_OTHERPLAYER  = GLOBAL_HEAD_OTHERPLAYER  or 1
GLOBAL_HEAD_NPC          = GLOBAL_HEAD_NPC          or 2
GLOBAL_HEAD_LIFE         = GLOBAL_HEAD_LIFE         or 0
GLOBAL_HEAD_GUILD        = GLOBAL_HEAD_GUILD        or 1
GLOBAL_HEAD_TITLE        = GLOBAL_HEAD_TITLE        or 2
GLOBAL_HEAD_NAME         = GLOBAL_HEAD_NAME         or 3
GLOBAL_HEAD_MARK         = GLOBAL_HEAD_MARK         or 4

EQUIPMENT_SUIT_COUNT = 4
PET_COUT_PER_PAGE    = 16
PET_MAX_COUNT        = 64

if not EQUIPMENT_SUB then
EQUIPMENT_SUB = {
	MELEE_WEAPON      = 0 , -- ��ս����
	RANGE_WEAPON      = 1 , -- Զ������
	CHEST             = 2 , -- ����
	HELM              = 3 , -- ͷ��
	AMULET            = 4 , -- ����
	RING              = 5 , -- ��ָ
	WAIST             = 6 , -- ����
	PENDANT           = 7 , -- ��׺
	PANTS             = 8 , -- ����
	BOOTS             = 9 , -- Ь��
	BANGLE            = 10, -- ����
	WAIST_EXTEND      = 11, -- �����Ҽ�
	PACKAGE           = 12, -- ����
	ARROW             = 13, -- ����
	BACK_EXTEND       = 14, -- �����Ҽ�
	HORSE             = 15, -- ����
	BULLET            = 16, -- �������
	FACE_EXTEND       = 17, -- �����Ҽ�
	MINI_AVATAR       = 18, -- Сͷ��
	PET               = 19, -- ����
	L_SHOULDER_EXTEND = 20, -- ���Ҽ�
	R_SHOULDER_EXTEND = 21, -- �Ҽ�Ҽ�
	BACK_CLOAK_EXTEND = 22, -- ����
	TOTAL             = 23, --
}
end

if not EQUIPMENT_INVENTORY then
EQUIPMENT_INVENTORY = {
	MELEE_WEAPON  = 1 , -- ��ͨ��ս����
	BIG_SWORD     = 2 , -- �ؽ�
	RANGE_WEAPON  = 3 , -- Զ������
	CHEST         = 4 , -- ����
	HELM          = 5 , -- ͷ��
	AMULET        = 6 , -- ����
	LEFT_RING     = 7 , -- ���ֽ�ָ
	RIGHT_RING    = 8 , -- ���ֽ�ָ
	WAIST         = 9 , -- ����
	PENDANT       = 10, -- ��׺
	PANTS         = 11, -- ����
	BOOTS         = 12, -- Ь��
	BANGLE        = 13, -- ����
	PACKAGE1      = 14, -- ��չ����1
	PACKAGE2      = 15, -- ��չ����2
	PACKAGE3      = 16, -- ��չ����3
	PACKAGE4      = 17, -- ��չ����4
	PACKAGE_MIBAO = 18, -- �󶨰�ȫ��Ʒ״̬�����͵Ķ��ⱳ���� ��ItemList V9������
	BANK_PACKAGE1 = 19, -- �ֿ���չ����1
	BANK_PACKAGE2 = 20, -- �ֿ���չ����2
	BANK_PACKAGE3 = 21, -- �ֿ���չ����3
	BANK_PACKAGE4 = 22, -- �ֿ���չ����4
	BANK_PACKAGE5 = 23, -- �ֿ���չ����5
	ARROW         = 24, -- ����
	TOTAL         = 25,
}
end

if not FORCE_TYPE then
FORCE_TYPE = {
	JIANG_HU  = 0 , -- ����
	SHAO_LIN  = 1 , -- ����
	WAN_HUA   = 2 , -- ��
	TIAN_CE   = 3 , -- ���
	CHUN_YANG = 4 , -- ����
	QI_XIU    = 5 , -- ����
	WU_DU     = 6 , -- �嶾
	TANG_MEN  = 7 , -- ����
	CANG_JIAN = 8 , -- �ؽ�
	GAI_BANG  = 9 , -- ؤ��
	MING_JIAO = 10, -- ����
	CANG_YUN  = 21, -- ����
}
end

if not KUNGFU_TYPE then
KUNGFU_TYPE = {
	TIAN_CE     = 1,      -- ����ڹ�
	WAN_HUA     = 2,      -- ���ڹ�
	CHUN_YANG   = 3,      -- �����ڹ�
	QI_XIU      = 4,      -- �����ڹ�
	SHAO_LIN    = 5,      -- �����ڹ�
	CANG_JIAN   = 6,      -- �ؽ��ڹ�
	GAI_BANG    = 7,      -- ؤ���ڹ�
	MING_JIAO   = 8,      -- �����ڹ�
	WU_DU       = 9,      -- �嶾�ڹ�
	TANG_MEN    = 10,     -- �����ڹ�
	CANG_YUN    = 18,     -- �����ڹ�
}
end

if not PEEK_OTHER_PLAYER_RESPOND then
PEEK_OTHER_PLAYER_RESPOND = {
	INVALID             = 0,
	SUCCESS             = 1,
	FAILED              = 2,
	CAN_NOT_FIND_PLAYER = 3,
	TOO_FAR             = 4,
}
end

INVENTORY_GUILD_BANK      = INVENTORY_GUILD_BANK or (INVENTORY_INDEX.TOTAL + 1) --���ֿ��������һ������λ��
INVENTORY_GUILD_PAGE_SIZE = INVENTORY_GUILD_PAGE_SIZE or 100
if not GetGuildBankBagPos then
function GetGuildBankBagPos(nPage, nIndex)
	return INVENTORY_GUILD_BANK, nPage * INVENTORY_GUILD_PAGE_SIZE + nIndex
end
end

MY_DEBUG = SetmetaReadonly({
	LOG     = 0,
	PMLOG   = 0,
	WARNING = 1,
	ERROR   = 2,
})

if not IsPhoneLock then
function IsPhoneLock()
	return GetClientPlayer() and GetClientPlayer().IsTradingMibaoSwitchOpen()
end
end

if not FormatDataStructure then
function FormatDataStructure(data, struct)
	local szType = type(struct)
	if szType == type(data) then
		if szType == 'table' then
			local t = {}
			for k, v in pairs(struct) do
				t[k] = FormatDataStructure(data[k], v)
			end
			return t
		end
	else
		data = clone(struct)
	end
	return data
end
end

if not IsSameData then
function IsSameData(data1, data2)
	if type(data1) == "table" and type(data2) == "table" then
		for k, v in pairs(data1) do
			if not IsSameData(data1[k], data2[k]) then
				return false
			end
		end
		return true
	else
		return data1 == data2
	end
end
end

------------------------------------
--            ����ͨѶ            --
------------------------------------
-- ON_BG_CHANNEL_MSG
-- arg0: ��ϢszKey
-- arg1: ��Ϣ��ԴƵ��
-- arg2: ��Ϣ������ID
-- arg3: ��Ϣ����������
-- arg4: ������������������
------------------------------------
-- �ж�һ��tSay�ṹ�ǲ��Ǳ���ͨѶ
if not IsBgMsg then
function IsBgMsg(t)
	return type(t) == "table" and t[1] and t[1].type == "eventlink" and t[1].name == "BG_CHANNEL_MSG"
end
end

-- ������ͨѶ
-- if not ProcessBgMsg then
-- function ProcessBgMsg(t, nChannel, dwTalkerID, szName, bEcho)
-- 	if IsBgMsg(t) and not bEcho and not (
-- 		nChannel == PLAYER_TALK_CHANNEL.NEARBY
-- 	 	or nChannel == PLAYER_TALK_CHANNEL.WORLD
-- 	 	or nChannel == PLAYER_TALK_CHANNEL.FORCE
-- 	 	or nChannel == PLAYER_TALK_CHANNEL.CAMP
-- 	 	or nChannel == PLAYER_TALK_CHANNEL.FRIENDS
-- 	 	or nChannel == PLAYER_TALK_CHANNEL.MENTOR
-- 	) then
-- 		local szKey, aParam = t[1].linkinfo or "", {}
-- 		if #t > 1 then
-- 			for i = 2, #t do
-- 				if t[i].type == "text" then
-- 					table.insert(aParam, (t[i].text))
-- 				elseif t[i].type == "eventlink" and t[i].name == "" then
-- 					table.insert(aParam, (str2var(t[i].linkinfo)))
-- 				end
-- 			end
-- 		end
-- 		FireUIEvent("ON_BG_CHANNEL_MSG", szKey, nChannel, dwTalkerID, szName, aParam)
-- 	end
-- end
-- end

-- ���ͱ���ͨѶ
-- SendBgMsg("����", "RAID_READY_CONFIRM") -- ���˱���ͨѶ
-- SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_READY_CONFIRM") -- Ƶ������ͨѶ
if not SendBgMsg then
function SendBgMsg(nChannel, szKey, ...)
	local tSay ={{ type = "eventlink", name = "BG_CHANNEL_MSG", linkinfo = szKey }}
	local szTarget = ""
	if type(nChannel) == "string" then
		szTarget = nChannel
		nChannel = PLAYER_TALK_CHANNEL.WHISPER
	end
	for _, v in ipairs({...}) do
		table.insert(tSay, { type = "eventlink", name = "", linkinfo = var2str(v) })
	end
	GetClientPlayer().Talk(nChannel, szTarget, tSay)
end
end
------------------------------------
-- ���ֿ��ܱ���ͨѶ����̫�� ��Ҫ�ִη���
-- ����д������������� �Ժ���ʱ����˵��
-- ��_SendBgMsg��ProcessBgMsg���������ͺ�
-- �ǵ�ÿ����������ʱ���ͽ������ݰٷֱȵ��¼�
------------------------------------
--           ����ͨѶEND           --
------------------------------------

if not HookSound then
local hook = {}
function HookSound(szSound, szKey, fnCondition)
	if not hook[szSound] then
		hook[szSound] = {}
	end
	hook[szSound][szKey] = fnCondition
end
local sounds = {}
for k, v in pairs(g_sound) do
	sounds[k], g_sound[k] = g_sound[k], nil
end
local function getsound(t, k)
	if hook[k] then
		for szKey, fnCondition in pairs(hook[k]) do
			if fnCondition() then
				return
			end
		end
	end
	return sounds[k]
end
local function setsound(t, k, v)
	sounds[k] = v
end
setmetatable(g_sound, {__index = getsound, __newindex = setsound})

local function resumegsound()
	setmetatable(g_sound, nil)
	for k, v in pairs(sounds) do
		g_sound[k] = v
	end
end
RegisterEvent('GAME_EXIT', resumegsound)
RegisterEvent('PLAYER_EXIT_GAME', resumegsound)
RegisterEvent('RELOAD_UI_ADDON_BEGIN', resumegsound)
end

-- ѡ���� ����
if not ipairs_r then
local function fnBpairs(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end

function ipairs_r(tab)
	return fnBpairs, tab, #tab + 1
end
end

if not str2var then
local szTempLog = "interface/temp.log"
local szTempJx3dat = "interface/temp.jx3dat"
function str2var(szText)
	Log(szTempLog, szText, "clear close")
	CPath.Move(szTempLog, szTempJx3dat)
	local data = LoadLUAData(szTempJx3dat)
	CPath.DelFile(szTempJx3dat)
	return data
end
end

if not GVoiceBase_GetSaying then
GVoiceBase_GetSaying = GV_GetSayings
end

if not GVoiceBase_CheckMicState then
GVoiceBase_CheckMicState = GVoice_CheckMicState
end

if not Table_GetCommonEnchantDesc then
function Table_GetCommonEnchantDesc(enchant_id)
	local res = g_tTable.CommonEnchant:Search(enchant_id)
	if res then
		return res.desc
	end
end
end
if not Table_GetProfessionName then
function Table_GetProfessionName(dwProfessionID)
	local szName = ""
	local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
	if tProfession then
		szName = tProfession.szName
	end
	return szName
end
end

if not EditBox_AppendLinkPlayer then
function EditBox_AppendLinkPlayer(szName)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj("[".. szName .."]", { type = "name", text = "[".. szName .."]", name = szName })
	Station.SetFocusWindow(edit)
	return true
end
end

if not EditBox_AppendLinkItem then
function EditBox_AppendLinkItem(dwID)
	local item = GetItem(dwID)
	if not item then
		return false
	end
	local szName = "[" .. GetItemNameByItem(item) .."]"
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj(szName, { type = "item", text = szName, item = item.dwID })
	Station.SetFocusWindow(edit)
	return true
end
end

-------------------------------------------
-- �������API���ݷ�ֹö���Լ��ӿ�û�е��±���
-------------------------------------------
if not MIC_STATE then
MIC_STATE = {
	NOT_AVIAL = 1,
	CLOSE_NOT_IN_ROOM = 2,
	CLOSE_IN_ROOM = 3,
	KEY = 4,
	FREE = 5,
}
end

if not GVoiceBase_IsOpen then
function GVoiceBase_IsOpen()
	return false
end
end

if not GVoiceBase_GetMicState then
function GVoiceBase_GetMicState()
	return MIC_STATE.CLOSE_NOT_IN_ROOM
end
end

if not GVoiceBase_SwitchMicState then
function GVoiceBase_SwitchMicState()
end
end

if not GVoiceBase_CheckMicState then
function GVoiceBase_CheckMicState()
end
end

if not SPEAKER_STATE then
SPEAKER_STATE = {
	OPEN = 1,
	CLOSE = 2,
}
end

if not GVoiceBase_GetSpeakerState then
function GVoiceBase_GetSpeakerState()
	return SPEAKER_STATE.CLOSE
end
end

if not GVoiceBase_SwitchSpeakerState then
function GVoiceBase_SwitchSpeakerState()
end
end

if not GVoiceBase_GetSaying then
function GVoiceBase_GetSaying()
	return {}
end
end

if not GVoiceBase_IsMemberSaying then
function GVoiceBase_IsMemberSaying(dwMemberID, sayingInfo)
	return false
end
end

if not GVoiceBase_IsMemberForbid then
function GVoiceBase_IsMemberForbid(dwMemberID)
	return false
end
end

if not GVoiceBase_ForbidMember then
function GVoiceBase_ForbidMember(dwMemberID, Forbid)
end
end

if not Table_IsTreasureBattleFieldMap then
function Table_IsTreasureBattleFieldMap()
	return false
end
end

UpdateItemInfoBoxObject = UpdataItemInfoBoxObject
