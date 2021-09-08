--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动按上次配方合石头
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
X.RegisterRestriction('MY_AutoDiamond', { ['*'] = true })
--------------------------------------------------------------------------

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local D = {
	nAutoCount = 0,
}

-- 获取五行石数据
function D.GetDiamondData(dwBox, dwX)
	if not dwX then
		dwBox, dwX = select(2, dwBox:GetObjectData())
	end
	local d, item = {}, GetClientPlayer().GetItem(dwBox, dwX)
	d.dwBox, d.dwX = dwBox, dwX
	if item then
		d.level = string.match(item.szName, _L['DIAMOND_REGEX'])
		d.id, d.bind, d.num, d.detail = item.nUiId, item.bBind, item.nStackNum, item.nDetail
		d.dwTabType, d.dwIndex = item.dwTabType, item.dwIndex
	end
	return d
end

-- get refine
function D.GetRefineHandle()
	local handle = Station.Lookup('Normal/CastingPanel/PageSet_All/Page_Refine', '')
	return assert(handle, 'Can not find handle')
end

-- 保存五行石精炼方案
function D.SaveDiamondFormula()
	local t = {}
	local handle = D.GetRefineHandle()
	local box, hL = handle:Lookup('Handle_BoxItem/Box_Refine'), handle:Lookup('Handle_RefineExpend')
	table.insert(t, D.GetDiamondData(box))
	for i = 1, 16 do
		local box = hL:Lookup('Box_RefineExpend_' .. i)
		if box:IsObjectEnable() and box:GetObjectData() ~= -1 then
			table.insert(t, D.GetDiamondData(box))
		end
	end
	D.dFormula = t
end

-- 扫描背包石头及空位信息（存在 buggy cache）
function D.LoadBagDiamond()
	local me, t = GetClientPlayer(), {}
	for dwBox = 1, X.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local d = D.GetDiamondData(dwBox, dwX)
			if not d.id or d.level then
				for _, v in ipairs(D.dFormula) do
					if v.dwBox == dwBox and v.dwX == dwX then
						d = nil
					end
				end
				if d then
					table.insert(t, d)
				end
			end
		end
	end
	D.tBagCache = t
end

-- 还原背包格子里的石头，失败返回 false，成功返回 true
function D.RestoreBagDiamond(d)
	local me = GetClientPlayer()
	local tBag = D.tBagCache
	-- move box item
	local item = me.GetItem(d.dwBox, d.dwX)
	-- to stack
	if item then
		for k, v in ipairs(tBag) do
			if v.id == item.nUiId and v.bind == item.bBind and (v.num + item.nStackNum) <= item.nMaxStackNum then
				v.num = v.num + item.nStackNum
				me.ExchangeItem(d.dwBox, d.dwX, v.dwBox, v.dwX)
				item = nil
				break
			end
		end
	end
	-- to empty
	if item then
		for k, v in ipairs(tBag) do
			if not v.id then
				local v2 = D.GetDiamondData(d.dwBox, d.dwX)
				v2.dwBox, v2.dwX = v.dwBox, v.dwX
				tBag[k] = v2
				me.ExchangeItem(d.dwBox, d.dwX, v.dwBox, v.dwX)
				item = nil
				break
			end
		end
	end
	-- no freebox
	if item then
		return false
	end
	-- group bag by type/bind: same type, same bind, ... others
	local tBag2, nLeft = {}, d.num
	for _, v in ipairs(tBag) do
		if v.level == d.level and (v.bind == d.bind or v.bind == false) then
			local vt = nil
			for _, vv in ipairs(tBag2) do
				if vv.bind == v.bind then
					vt = vv
					break
				end
			end
			if not vt then
				vt = { num = 0, bind = v.bind }
				local vk = #tBag2 + 1
				if vk > 1 then
					if v.bind ~= d.bind then
						vk = 2
					else
						vk = 1
					end
				end
				table.insert(tBag2, vk, vt)
			end
			vt.num = vt.num + v.num
			table.insert(vt, v)
		end
	end
	-- select diamond1 (same type)
	for _, v in ipairs(tBag2) do
		if v.num >= nLeft then
			for _, vv in ipairs(v) do
				if vv.num >= nLeft then
					me.ExchangeItem(vv.dwBox, vv.dwX, d.dwBox, d.dwX, nLeft)
					vv.num = vv.num - nLeft
					break
				elseif vv.num > 0 then
					me.ExchangeItem(vv.dwBox, vv.dwX, d.dwBox, d.dwX, vv.num)
					nLeft = nLeft - vv.num
					vv.num = 0
				end
			end
			return true
		end
	end
	return false
end

function D.ProduceDiamond()
	if not D.fnProduceAction then
		X.Systopmsg(_L['Produce failed, action not exist.'], CONSTANT.MSG_THEME.ERROR)
		return
	end
	D.fnProduceAction()
end

function D.GetCastingAction()
	local frame = Station.Lookup('Topmost/MB_CastingPanelConfirm')
	if frame then
		D.fnProduceAction = frame:Lookup('Wnd_All/Btn_Option1').fnAction
		D.SaveDiamondFormula()
	end
end

function D.UpdateCounter()
	local frame = Station.SearchFrame('CastingPanel')
	local edit = frame and frame:Lookup('PageSet_All/Page_Refine/WndWindow_MYDiamond/WndEditBox_MYDiamond')
	if not edit then
		return
	end
	UI(edit):Text(D.nAutoCount, WNDEVENT_FIRETYPE.PREVENT)
end

-- 自动摆五行石材料，开始下一轮合成
function D.DoAutoDiamond()
	local box = D.GetRefineHandle():Lookup('Handle_BoxItem/Box_Refine')
	if not box then
		D.dFormula = nil
	end
	if not D.dFormula then
		return
	end
	-- 移除加锁（延迟一帧）
	X.DelayCall(50, function()
		local dwBox, dwX = select(2, box:GetObjectData())
		RemoveUILockItem('CastingPanel:' .. dwBox .. ',' .. dwX)
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
		box:SetObjectIcon(3388 - GetClientPlayer().nGender)
	end)
	-- 重新放入配方（延迟8帧执行，确保 unlock）
	X.DelayCall(200, function()
		if D.nAutoCount <= 0 then
			return
		end
		D.LoadBagDiamond()
		for _, v in ipairs(D.dFormula) do
			if not D.RestoreBagDiamond(v) then
				box:ClearObject()
				D.dFormula = nil
				D.tBagCache = nil
				X.Systopmsg(_L['Restore bag failed, material may not enough.'], CONSTANT.MSG_THEME.ERROR)
				return
			end
		end
		D.AwaitNextDuang()
		D.ProduceDiamond()
	end)
end

-- 隐藏结果特效
function D.HideDuang()
	local frame = Station.Lookup('Normal/CastingPanel')
	if not frame then
		return
	end
	local sfxSuccess = frame:Lookup('PageSet_All/Page_Refine', 'SFX_CommonRefineSuccess')
	local sfxFailure = frame:Lookup('PageSet_All/Page_Refine', 'SFX_CommonRefineFailure')
	sfxSuccess:Hide()
	sfxFailure:Hide()
end

-- 精炼结果显示
function D.PlayDuang(bSuccess)
	local frame = Station.Lookup('Normal/CastingPanel')
	if not frame then
		return
	end
	local sfx
	if bSuccess then
		sfx = frame:Lookup('PageSet_All/Page_Refine', 'SFX_CommonRefineSuccess')
		PlaySound(SOUND.UI_SOUND, g_sound.ElementalStoneSuccess)
	else
		sfx = frame:Lookup('PageSet_All/Page_Refine', 'SFX_CommonRefineFailure')
		PlaySound(SOUND.UI_SOUND, g_sound.ElementalStoneFailed)
	end
	sfx:Hide()
	sfx:Show()
	sfx:Play()
end

-- 注册下次精炼结果显示
function D.AwaitNextDuang()
	-- 播放结果动画
	X.RegisterEvent('DIAMON_UPDATE', 'MY_AutoDiamond__Duang', function()
		local nResult = arg0
		if nResult == DIAMOND_RESULT_CODE.SUCCESS then
			local d = D.dFormula and D.dFormula[1]
			if d and d.detail and d.detail > 0 then
				local KItem = GetPlayerItem(GetClientPlayer(), d.dwBox, d.dwX)
				if KItem then
					if KItem.nDetail > d.detail then
						X.DelayCall(1, function() D.HideDuang() D.PlayDuang(true) end)
						OutputMessage('MSG_ANNOUNCE_YELLOW', g_tStrings.tFEProduce.SUCCEED)
					else
						X.DelayCall(1, function() D.HideDuang() D.PlayDuang(false) end)
						OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.tFEProduce.FAILED)
					end
					D.HideDuang()
				end
			end
		end
		X.RegisterEvent('DIAMON_UPDATE', 'MY_AutoDiamond__Duang', false)
	end)
end

-------------------------------------
-- 设置界面
-------------------------------------
function D.CheckInjection(bRemove)
	local frame = Station.SearchFrame('CastingPanel')
	local page = frame and frame:Lookup('PageSet_All/Page_Refine')
	if not page then
		return
	end
	UI(page):Fetch('WndWindow_MYDiamond'):Remove()
	if not bRemove and not X.IsRestricted('MY_AutoDiamond') then
		local ui = UI(page):Append('WndWindow', { name = 'WndWindow_MYDiamond', y = 390, h = 24 })
		local nX, nY = 0, 2
		nX = nX + ui:Append('Text', {
			name = 'Text_MYDiamond',
			x = nX, y = nY, w = 'auto', h = 20,
			color = { 255, 128, 0 }, alpha = 192,
			text = _L['Produce diamond as last formula for'],
		}):Width() + 5
		nX = nX + ui:Append('WndEditBox', {
			name = 'WndEditBox_MYDiamond',
			text = D.nAutoCount,
			x = nX, y = nY - 2, w = 50, h = 20, alpha = 192,
			edittype = UI.EDIT_TYPE.NUMBER,
			onchange = function(szText)
				D.nAutoCount = tonumber(szText) or 0
			end,
			tip = _L['Will continue produce until counter reachs or casting failed.'],
			tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		}):Width() + 5
		nX = nX + ui:Append('Text', {
			name = 'Text_MYDiamond2',
			x = nX, y = nY, w = 'auto', h = 20,
			color = { 255, 128, 0 }, alpha = 192,
			text = _L['times'],
		}):Width() + 5
		nX = nX + ui:Append('WndButtonBox', {
			name = 'WndButton_MYDiamond',
			x = nX, y = nY, w = 50, h = 20,
			buttonstyle = 'FLAT',
			text = _L['Stop'],
			onclick = function()
				D.dFormula = nil
			end,
			autoenable = function() return not not D.dFormula end,
		}):Width() + 5
		ui:Width(nX)
		ui:Left((380 - nX) / 2)
	end
end
X.RegisterFrameCreate('CastingPanel', 'MY_AutoDiamond', function() D.CheckInjection() end)
X.RegisterEvent('MY_RESTRICTION', 'MY_AutoDiamond', function()
	if arg0 and arg0 ~= 'MY_AutoDiamond' then
		return
	end
	D.CheckInjection()
end)
X.RegisterInit('MY_AutoDiamond', function() D.CheckInjection() end)
X.RegisterReload('MY_AutoDiamond', function() D.CheckInjection(true) end)

X.RegisterEvent('DIAMON_UPDATE', 'MY_AutoDiamond', function()
	if D.nAutoCount <= 0 or not D.dFormula then
		return
	end
	if arg0 ~= DIAMOND_RESULT_CODE.SUCCESS then
		X.Systopmsg(_L['Casting failed, auto cast stopped.'], CONSTANT.MSG_THEME.ERROR)
		return
	end
	D.nAutoCount = math.max(D.nAutoCount - 1, 0)
	D.UpdateCounter()
	D.DoAutoDiamond()
end)
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_AutoDiamond', D.GetCastingAction)
