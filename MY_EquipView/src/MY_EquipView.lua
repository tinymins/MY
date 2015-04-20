--------------------------------------------
-- @Desc  : �ҵ�װ��һ��
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-4-20 09:04:25
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-04-20 12:09:59
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_EquipView/lang/")

_C.tEquipPos = {
	EQUIPMENT_INVENTORY.BANGLE       , -- ����
	EQUIPMENT_INVENTORY.CHEST        , -- ����
	EQUIPMENT_INVENTORY.WAIST        , -- ����
	EQUIPMENT_INVENTORY.HELM         , -- ͷ��
	EQUIPMENT_INVENTORY.PANTS        , -- ����
	EQUIPMENT_INVENTORY.BOOTS        , -- Ь��
	EQUIPMENT_INVENTORY.AMULET       , -- ����
	EQUIPMENT_INVENTORY.LEFT_RING    , -- ���ֽ�ָ
	EQUIPMENT_INVENTORY.RIGHT_RING   , -- ���ֽ�ָ
	EQUIPMENT_INVENTORY.PENDANT      , -- ��׺
	EQUIPMENT_INVENTORY.MELEE_WEAPON , -- ��ͨ��ս����
	EQUIPMENT_INVENTORY.RANGE_WEAPON , -- Զ������
	EQUIPMENT_INVENTORY.ARROW        , -- ����
	EQUIPMENT_INVENTORY.BIG_SWORD    , -- �ؽ�
}

_C.GetSuitIndex = function(me, nLogicIndex)
	local nSuitIndex = me.GetEquipIDArray(nLogicIndex)
	local dwBox
	if nSuitIndex == 0 then
		dwBox = INVENTORY_INDEX.EQUIP
	else
		dwBox = INVENTORY_INDEX["EQUIP_BACKUP"..nSuitIndex]
	end
	return nSuitIndex, dwBox
end

_C.UpdateAllEquipBox = function() -- update boxes
	if not _C.wnd then
		return
	end
	local ui = MY.UI(_C.wnd)
	local me = GetClientPlayer()
	for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
		local nSuitIndex, dwBox = _C.GetSuitIndex(me, i)
		for _, nType in ipairs(_C.tEquipPos) do
			local box = ui:item('#Box_' .. i .. '_' .. nType):raw(1)
			local item = GetPlayerItem(me, dwBox, nType)
			UpdataItemBoxObject(box, dwBox, nType, item, nil, nSuitIndex)
		end
	end
end
MY.RegisterEvent("BAG_ITEM_UPDATE", _C.UpdateAllEquipBox)

_C.PS = {
	OnPanelActive = function(wnd) -- append ui items
		_C.wnd = wnd
		local ui = MY.UI(wnd)
		for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				ui:append('Box', 'Box_' .. i .. '_' .. nType)
			end
		end
		_C.PS.OnPanelResize(wnd)
		_C.UpdateAllEquipBox()
	end,
	OnPanelResize = function(wnd) -- correct item pos
		local ui = MY.UI(wnd)
		local w , h  = ui:size()
		local x0, y0 = 0 , 10
		local x , y  = x0, y0
		local dx, dy, dy2 = 50, 48, 52
		
		for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				if x + dx > w then
					x, y = x0, y + dy
				end
				ui:item('#Box_' .. i .. '_' .. nType):pos(x, y)
				x = x + dx
			end
			x, y = x0, y + dy2
		end
	end,
	OnPanelDeactive = function()
		_C.wnd = nil
	end
}

MY.RegisterPanel("MY_EquipView", _L["equip view"], _L['General'], "ui/Image/UICommon/CommonPanel7.UITex|23", {255,127,0,200}, _C.PS)
