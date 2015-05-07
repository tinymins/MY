--------------------------------------------
-- @Desc  : 茗伊插件兼容性全局函数
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-05-07 10:27:39
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
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
