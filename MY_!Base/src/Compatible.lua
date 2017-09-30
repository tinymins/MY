--------------------------------------------
-- @Desc  : 茗伊插件兼容性全局函数
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-01-24 15:44:51
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
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

-- 只读表创建
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

-- -- 只读表字典枚举
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

-- -- 只读表数组枚举
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
	NONE             = -1, -- 空Box
	ITEM             = 0 , -- 身上有的物品。nUiId, dwBox, dwX, nItemVersion, nTabType, nIndex
	SHOP_ITEM        = 1 , -- 商店里面出售的物品 nUiId, dwID, dwShopID, dwIndex
	OTER_PLAYER_ITEM = 2 , -- 其他玩家身上的物品 nUiId, dwBox, dwX, dwPlayerID
	ITEM_ONLY_ID     = 3 , -- 只有一个ID的物品。比如装备链接之类的。nUiId, dwID, nItemVersion, nTabType, nIndex
	ITEM_INFO        = 4 , -- 类型物品 nUiId, nItemVersion, nTabType, nIndex, nCount(书nCount代表dwRecipeID)
	SKILL            = 5 , -- 技能。dwSkillID, dwSkillLevel, dwOwnerID
	CRAFT            = 6 , -- 技艺。dwProfessionID, dwBranchID, dwCraftID
	SKILL_RECIPE     = 7 , -- 配方dwID, dwLevel
	SYS_BTN          = 8 , -- 系统栏快捷方式dwID
	MACRO            = 9 , -- 宏
	MOUNT            = 10, -- 镶嵌
	ENCHANT          = 11, -- 附魔
	NOT_NEED_KNOWN   = 15, -- 不需要知道类型
	PENDANT          = 16, -- 挂件
	PET              = 17, -- 宠物
	MEDAL            = 18, -- 宠物徽章
	BUFF             = 19, -- BUFF
	MONEY            = 20, -- 金钱
	TRAIN            = 21, -- 修为
	EMOTION_ACTION   = 22, -- 动作表情
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
	MELEE_WEAPON      = 0 , -- 近战武器
	RANGE_WEAPON      = 1 , -- 远程武器
	CHEST             = 2 , -- 上衣
	HELM              = 3 , -- 头部
	AMULET            = 4 , -- 项链
	RING              = 5 , -- 戒指
	WAIST             = 6 , -- 腰带
	PENDANT           = 7 , -- 腰缀
	PANTS             = 8 , -- 裤子
	BOOTS             = 9 , -- 鞋子
	BANGLE            = 10, -- 护臂
	WAIST_EXTEND      = 11, -- 腰部挂件
	PACKAGE           = 12, -- 包裹
	ARROW             = 13, -- 暗器
	BACK_EXTEND       = 14, -- 背部挂件
	HORSE             = 15, -- 坐骑
	BULLET            = 16, -- 弩或陷阱
	FACE_EXTEND       = 17, -- 脸部挂件
	MINI_AVATAR       = 18, -- 小头像
	PET               = 19, -- 跟宠
	L_SHOULDER_EXTEND = 20, -- 左肩挂件
	R_SHOULDER_EXTEND = 21, -- 右肩挂件
	BACK_CLOAK_EXTEND = 22, -- 披风
	TOTAL             = 23, --
}
end

if not EQUIPMENT_INVENTORY then
EQUIPMENT_INVENTORY = {
	MELEE_WEAPON  = 1 , -- 普通近战武器
	BIG_SWORD     = 2 , -- 重剑
	RANGE_WEAPON  = 3 , -- 远程武器
	CHEST         = 4 , -- 上衣
	HELM          = 5 , -- 头部
	AMULET        = 6 , -- 项链
	LEFT_RING     = 7 , -- 左手戒指
	RIGHT_RING    = 8 , -- 右手戒指
	WAIST         = 9 , -- 腰带
	PENDANT       = 10, -- 腰缀
	PANTS         = 11, -- 裤子
	BOOTS         = 12, -- 鞋子
	BANGLE        = 13, -- 护臂
	PACKAGE1      = 14, -- 扩展背包1
	PACKAGE2      = 15, -- 扩展背包2
	PACKAGE3      = 16, -- 扩展背包3
	PACKAGE4      = 17, -- 扩展背包4
	PACKAGE_MIBAO = 18, -- 绑定安全产品状态下赠送的额外背包格 （ItemList V9新增）
	BANK_PACKAGE1 = 19, -- 仓库扩展背包1
	BANK_PACKAGE2 = 20, -- 仓库扩展背包2
	BANK_PACKAGE3 = 21, -- 仓库扩展背包3
	BANK_PACKAGE4 = 22, -- 仓库扩展背包4
	BANK_PACKAGE5 = 23, -- 仓库扩展背包5
	ARROW         = 24, -- 暗器
	TOTAL         = 25,
}
end

if not FORCE_TYPE then
FORCE_TYPE = {
	JIANG_HU  = 0 , -- 江湖
	SHAO_LIN  = 1 , -- 少林
	WAN_HUA   = 2 , -- 万花
	TIAN_CE   = 3 , -- 天策
	CHUN_YANG = 4 , -- 纯阳
	QI_XIU    = 5 , -- 七秀
	WU_DU     = 6 , -- 五毒
	TANG_MEN  = 7 , -- 唐门
	CANG_JIAN = 8 , -- 藏剑
	GAI_BANG  = 9 , -- 丐帮
	MING_JIAO = 10, -- 明教
	CANG_YUN  = 21, -- 苍云
}
end

if not KUNGFU_TYPE then
KUNGFU_TYPE = {
	TIAN_CE     = 1,      -- 天策内功
	WAN_HUA     = 2,      -- 万花内功
	CHUN_YANG   = 3,      -- 纯阳内功
	QI_XIU      = 4,      -- 七秀内功
	SHAO_LIN    = 5,      -- 少林内功
	CANG_JIAN   = 6,      -- 藏剑内功
	GAI_BANG    = 7,      -- 丐帮内功
	MING_JIAO   = 8,      -- 明教内功
	WU_DU       = 9,      -- 五毒内功
	TANG_MEN    = 10,     -- 唐门内功
	CANG_YUN    = 18,     -- 苍云内功
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

INVENTORY_GUILD_BANK      = INVENTORY_GUILD_BANK or (INVENTORY_INDEX.TOTAL + 1) --帮会仓库界面虚拟一个背包位置
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
--            背景通讯            --
------------------------------------
-- ON_BG_CHANNEL_MSG
-- arg0: 消息szKey
-- arg1: 消息来源频道
-- arg2: 消息发布者ID
-- arg3: 消息发布者名字
-- arg4: 不定长参数数组数据
------------------------------------
-- 判断一个tSay结构是不是背景通讯
if not IsBgMsg then
function IsBgMsg(t)
	return type(t) == "table" and t[1] and t[1].type == "eventlink" and t[1].name == "BG_CHANNEL_MSG"
end
end

-- 处理背景通讯
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

-- 发送背景通讯
-- SendBgMsg("茗伊", "RAID_READY_CONFIRM") -- 单人背景通讯
-- SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_READY_CONFIRM") -- 频道背景通讯
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
-- 有种可能背景通讯数据太大 需要分次发送
-- 懒得写了先马克在这里 以后有时间再说吧
-- 在_SendBgMsg和ProcessBgMsg做拆分重组就好
-- 记得每次重组数据时发送接收数据百分比的事件
------------------------------------
--           背景通讯END           --
------------------------------------

if not ExecuteWithThis then
function ExecuteWithThis(element, fnAction, ...)
	if not (element and element:IsValid()) then
		Log("[UI ERROR]Invalid element on executing ui event!")
		return false
	end
	if type(fnAction) == "string" then
		if element[fnAction] then
			fnAction = element[fnAction]
		else
			local szFrame = element:GetRoot():GetName()
			if type(_G[szFrame]) == "table" then
				fnAction = _G[szFrame][fnAction]
			end
		end
	end
	if type(fnAction) ~= "function" then
		Log("[UI ERROR]Invalid function on executing ui event! # " .. element:GetTreePath())
		return false
	end
	local _this = this
	this = element
	fnAction(...)
	this = _this
	return true
end
end
if not SafeExecuteWithThis then
function SafeExecuteWithThis(element, fnAction, ...)
	if not element or not fnAction then
		return
	end
	return ExecuteWithThis(element, fnAction, ...)
end
end

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

-- 选代器 倒序
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

UpdateItemInfoBoxObject = UpdataItemInfoBoxObject
