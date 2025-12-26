--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Item')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do local CACHE = {}
-- 获取指定物品的唯一键
-- X.GetItemKey(dwTabType, dwIndex, nBookID)
-- X.GetItemKey(KItem)
-- X.GetItemKey(KItemInfo, nBookID)
---@param dwTabType number @物品表类型
---@param dwIndex number @物品表下标
---@param nBookID number @物品为书籍时的书籍ID
---@param KItem usedata @物品对象
---@param KItemInfo usedata @物品模板对象
function X.GetItemKey(dwTabType, dwIndex, nBookID)
	local it, nGenre
	if X.IsUserdata(dwTabType) then
		it, nBookID = dwTabType, dwIndex
		nGenre = it.nGenre
		if not nBookID and nGenre == ITEM_GENRE.BOOK then
			nBookID = it.nBookID or -1
		end
		dwTabType, dwIndex = it.dwTabType, it.dwIndex
	else
		local KItemInfo = GetItemInfo(dwTabType, dwIndex)
		nGenre = KItemInfo and KItemInfo.nGenre
	end
	if not CACHE[dwTabType] then
		CACHE[dwTabType] = {}
	end
	if nGenre == ITEM_GENRE.BOOK then
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = {}
		end
		if not CACHE[dwTabType][dwIndex][nBookID] then
			CACHE[dwTabType][dwIndex][nBookID] = dwTabType .. ',' .. dwIndex .. ',' .. nBookID
		end
		return CACHE[dwTabType][dwIndex][nBookID]
	else
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = dwTabType .. ',' .. dwIndex
		end
		return CACHE[dwTabType][dwIndex]
	end
end
end

-- * 当前道具是否满足装备要求：包括身法，体型，门派，性别，等级，根骨，力量，体质
function X.DoesEquipmentSuit(kItem, bIsItem, kPlayer)
	if not kPlayer then
		kPlayer = X.GetClientPlayer()
	end
	local requireAttrib = kItem.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if bIsItem and not kPlayer.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		elseif not bIsItem and not kPlayer.SatisfyRequire(v.nID, v.nValue) then
			return false
		end
	end
	return true
end

-- * 当前装备是否适合当前内功
do
local CACHE = {}
local m_MountTypeToWeapon = X.KvpToObject({
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TIAN_CE  , WEAPON_DETAIL.SPEAR        }, -- 天策内功=长兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WAN_HUA  , WEAPON_DETAIL.PEN          }, -- 万花内功=笔类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHUN_YANG, WEAPON_DETAIL.SWORD        }, -- 纯阳内功=短兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.QI_XIU   , WEAPON_DETAIL.DOUBLE_WEAPON}, -- 七秀内功 = 双兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.SHAO_LIN , WEAPON_DETAIL.WAND         }, -- 少林内功=棍类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_JIAN, WEAPON_DETAIL.SWORD        }, -- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.GAI_BANG , WEAPON_DETAIL.STICK        }, -- 丐帮内功=短棒
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.MING_JIAO, WEAPON_DETAIL.KNIFE        }, -- 明教内功=弯刀
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WU_DU    , WEAPON_DETAIL.FLUTE        }, -- 五毒内功=笛类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TANG_MEN , WEAPON_DETAIL.BOW          }, -- 唐门内功=千机匣
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_YUN , WEAPON_DETAIL.BLADE_SHIELD }, -- 苍云内功=刀盾
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHANG_GE , WEAPON_DETAIL.HEPTA_CHORD  }, -- 长歌内功=琴
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.BA_DAO   , WEAPON_DETAIL.BROAD_SWORD  }, -- 霸刀内功=组合刀
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.PENG_LAI , WEAPON_DETAIL.UMBRELLA     }, -- 蓬莱内功=伞
	--WEAPON_DETAIL.FIST = 拳腕
	--WEAPON_DETAIL.DART = 弓弦
	--WEAPON_DETAIL.MACH_DART = 机关暗器
	--WEAPON_DETAIL.SLING_SHOT = 投掷
})
function X.IsItemInfoFitKungfu(kItemInfo, dwKungfuID)
	local me = X.GetClientPlayer()
	local kungfu = GetSkill(dwKungfuID, me.GetSkillLevel(dwKungfuID) or 1)
	if kItemInfo.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if not kungfu then
			return false
		end
		if kItemInfo.nDetail == WEAPON_DETAIL.BIG_SWORD and kungfu.dwMountType == 6 then
			return true
		end

		if (m_MountTypeToWeapon[kungfu.dwMountType] ~= kItemInfo.nDetail) then
			return false
		end

		if not kItemInfo.nRecommendID or kItemInfo.nRecommendID == 0 then
			return true
		end
	end

	if not kItemInfo.nRecommendID then
		return
	end
	local aRecommendKungfuID = CACHE[kItemInfo.nRecommendID]
	if not aRecommendKungfuID then
		local EquipRecommend = X.GetGameTable('EquipRecommend', true)
		if EquipRecommend then
			local res = EquipRecommend:Search(kItemInfo.nRecommendID)
			aRecommendKungfuID = {}
			for i, v in ipairs(X.SplitString(res.kungfu_ids, '|')) do
				table.insert(aRecommendKungfuID, tonumber(v))
			end
		end
		CACHE[kItemInfo.nRecommendID] = aRecommendKungfuID
	end

	if not aRecommendKungfuID or not aRecommendKungfuID[1] then
		return
	end

	if aRecommendKungfuID[1] == 0 then
		return true
	end

	if not kungfu then
		return false
	end
	for _, v in ipairs(aRecommendKungfuID) do
		if v == kungfu.dwSkillID then
			return true
		end
	end
end
end

function X.IsItemFitKungfu(kItem, dwKungfuID)
	local kItemInfo = GetItemInfo(kItem.dwTabType, kItem.dwIndex)
	return X.IsItemInfoFitKungfu(kItemInfo, dwKungfuID)
end

-- 获取物品精炼等级
---@param kItem userdata @物品对象
---@param kPlayer userdata @物品所属角色
---@return number, number, number @[有效精炼等级, 物品精炼等级, 装备栏精炼等级]
function X.GetItemStrengthLevel(kItem, kPlayer)
	if X.IS_REMAKE then
		if not kPlayer then
			kPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(kItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and kPlayer.GetEquipBoxStrength then
			local KItemInfo = GetItemInfo(kItem.dwTabType, kItem.dwIndex)
			local nMaxStrengthLevel = KItemInfo.nMaxStrengthLevel
			local nBoxStrengthLevel = kPlayer.GetEquipBoxStrength(dwBox)
			local nItemStrengthLevel = kItem.nStrengthLevel
			local nStrengthLevel = math.min(math.max(nItemStrengthLevel, nBoxStrengthLevel), nMaxStrengthLevel)
			return nStrengthLevel, nItemStrengthLevel, nBoxStrengthLevel
		end
	end
	return kItem.nStrengthLevel, kItem.nStrengthLevel, 0
end

-- 获取物品熔嵌孔镶嵌信息
---@param kItem userdata @物品对象
---@param nSlotIndex string @熔嵌孔下标
---@param kPlayer userdata @物品所属角色
---@return number, number, number @[有效熔嵌孔五行石ID, 物品熔嵌孔五行石ID, 装备栏熔嵌孔五行石ID]
function X.GetItemMountDiamondEnchantID(kItem, nSlotIndex, kPlayer)
	if X.IS_REMAKE then
		if not kPlayer then
			kPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(kItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and kPlayer.GetEquipBoxMountDiamondEnchantID then
			local dwBoxEnchantID, nBoxQuality = kPlayer.GetEquipBoxMountDiamondEnchantID(dwBox, nSlotIndex)
            local dwItemEnchantID = kItem.GetMountDiamondEnchantID(nSlotIndex)
            local dwEnchantID = kItem.GetAdaptedDiamondEnchantID(nSlotIndex, kItem.nLevel, dwBoxEnchantID)
			return dwEnchantID, dwItemEnchantID, dwBoxEnchantID
		end
	end
	local dwItemEnchantID = kItem.GetMountDiamondEnchantID(nSlotIndex)
	return dwItemEnchantID, dwItemEnchantID, 0
end

-- 获取物品五彩石孔镶嵌信息
---@param kItem userdata @物品对象
---@return number @有效熔嵌孔五彩石ID
function X.GetItemMountFEAEnchantID(kItem)
	if X.IS_REMAKE then
		return GetFEAEnchantID(kItem)
	end
	local dwItemFEAEnchantID = kItem.GetMountFEAEnchantID() or 0
	return dwItemFEAEnchantID
end

-- * 获取物品对应身上装备的位置
function X.GetItemEquipPos(kItem, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local dwPackage, dwBox, nCount = INVENTORY_INDEX.EQUIP, 0, 1
	if kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if kItem.nDetail == WEAPON_DETAIL.BIG_SWORD then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.ARROW then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.ARROW
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.CHEST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.CHEST
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.HELM then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.HELM
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.AMULET then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.AMULET
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.RING then
		if nIndex == 1 then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING
		end
		nCount = 2
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PENDANT then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PENDANT
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PANTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PANTS
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BOOTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BOOTS
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BANGLE then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BANGLE
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE then
		dwPackage, dwBox = X.GetClientPlayer().GetEquippedHorsePos()
	end
	return dwPackage, dwBox, nIndex, nCount
end

-- * 当前装备是否是比身上已经装备的更好
function X.IsBetterEquipment(kItem, dwPackage, dwBox)
	if kItem.nGenre ~= ITEM_GENRE.EQUIPMENT
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BULLET
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.MINI_AVATAR
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PET then
		return false
	end

	if not dwPackage or not dwBox then
		local nIndex, nCount = 0, 1
		while nIndex < nCount do
			dwPackage, dwBox, nIndex, nCount = X.GetItemEquipPos(kItem, nIndex + 1)
			if X.IsBetterEquipment(kItem, dwPackage, dwBox) then
				return true
			end
		end
		return false
	end

	local me = X.GetClientPlayer()
	local equipedItem = GetPlayerItem(me, dwPackage, dwBox)
	if not equipedItem then
		return false
	end
	if me.nLevel < me.nMaxLevel then
		return kItem.nEquipScore > equipedItem.nEquipScore
	end
	return (kItem.nEquipScore > equipedItem.nEquipScore) or (kItem.nLevel > equipedItem.nLevel and kItem.nQuality >= equipedItem.nQuality)
end

do local ITEM_CACHE = {}
function X.GetItemNameByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local szName = Table_GetItemName(nUiId)
		if szName == '' then
			szName = 'ITEM#' .. nUiId
		end
		ITEM_CACHE[nUiId] = szName
	end
	return ITEM_CACHE[nUiId]
end
end

function X.GetItemNameByItem(kItem)
	if kItem.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = X.RecipeToSegmentID(kItem.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(kItem.nUiId)
end

function X.GetItemNameByItemInfo(kItemInfo, nBookInfo)
	if kItemInfo.nGenre == ITEM_GENRE.BOOK and nBookInfo then
		local nBookID, nSegID = X.RecipeToSegmentID(nBookInfo)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(kItemInfo.nUiId)
end

do local ITEM_CACHE = {}
function X.GetItemIconByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local nIcon = Table_GetItemIconID(nUiId)
		if nIcon == -1 then
			nIcon = 1435
		end
		ITEM_CACHE[nUiId] = nIcon
	end
	return ITEM_CACHE[nUiId]
end
end

function X.UpdateItemBoxExtend(hBox, nQuality)
	local szImage = 'ui/Image/Common/Box.UITex'
	local nFrame
	if nQuality == 2 then
		nFrame = 13
	elseif nQuality == 3 then
		nFrame = 12
	elseif nQuality == 4 then
		nFrame = 14
	elseif nQuality == 5 then
		nFrame = 17
	end
	hBox:ClearExtentImage()
	hBox:ClearExtentAnimate()
	if nFrame and nQuality < 5 then
		hBox:SetExtentImage(szImage, nFrame)
	elseif nQuality == 5 then
		hBox:SetExtentAnimate(szImage, nFrame, -1)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
