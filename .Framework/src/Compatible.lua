--------------------------------------------
-- @Desc  : �������������ȫ�ֺ���
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-04-20 11:13:24
-- @Ref: �����������Դ�� @haimanchajian.com
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

if not empty then
	function empty(e)
		local szType = type(e)
		if szType == 'string' then
			return #szType == 0
		elseif szType == 'table' then
			for _, _ in pairs(e) do
				return false
			end
			return true
		else
			return e == nil
		end
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
