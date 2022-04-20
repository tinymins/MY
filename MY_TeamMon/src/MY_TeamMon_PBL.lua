--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队重要BUFF列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_PBL'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------

local GetBuff = X.GetBuff

-- 这个需要重写 构思已有 就是没时间。。
local O = X.CreateUserSettingsModule('MY_TeamMon_PBL', _L['Raid'], {
	bHoverSelect = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 400, y = 0 },
	},
})
local D = {}

local TEMP_TARGET_TYPE, TEMP_TARGET_ID
local CACHE_LIST = setmetatable({}, { __mode = 'v' })
local PBL_INI_FILE = X.PACKET_INFO.ROOT ..  'MY_TeamMon/ui/MY_TeamMon_PBL.ini'

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('TARGET_CHANGE')
	this:RegisterEvent('MY_TM_PARTY_BUFF_LIST')
	D.hItem = this:CreateItemData(PBL_INI_FILE, 'Handle_Item')
	D.frame = this
	D.handle = this:Lookup('', 'Handle_List')
	D.bg = this:Lookup('', 'Image_Bg')
	D.handle:Clear()
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TeamMon_PBL'])
	D.UpdateAnchor(this)
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'TARGET_CHANGE' then
		D.SwitchSelect()
	elseif event == 'MY_TM_PARTY_BUFF_LIST' then
		D.OnTableInsert(arg0, arg1, arg2, arg3)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' or event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['MY_TeamMon_PBL'])
		if event == 'ON_ENTER_CUSTOM_UI_MODE' then
			D.frame:Show()
		else
			D.SwitchPanel(D.handle:GetItemCount())
			D.frame:EnableDrag(true) -- 还是支持拖动的
			D.frame:SetDragArea(0, 0, 200, 30)
		end
	end
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then return end
	local dwKungfuID = UI_GetPlayerMountKungfuID()
	local DISTANCE = 20
	if dwKungfuID == 10080 then -- 奶秀修正
		DISTANCE = 22
	elseif dwKungfuID == 10028 then -- 奶花修正
		DISTANCE = 24
	end
	for i = D.handle:GetItemCount() -1, 0, -1 do
		local h = D.handle:Lookup(i)
		if h and h:IsValid() then
			local data = h.data
			local p, info = D.GetPlayer(data.dwID)
			local buff
			if p then
				buff = GetBuff(p, data.dwBuffID)
			end
			if p and info and buff then
				local nDistance = X.GetDistance(p)
				h:Lookup('Image_life'):SetPercentage(info.fCurrentLife64 / math.max(info.fMaxLife64, 1))
				h:Lookup('Text_Name'):SetText(i + 1 .. ' ' .. info.szName)
				if nDistance > DISTANCE then
					h:Lookup('Image_life'):SetAlpha(150)
				else
					h:Lookup('Image_life'):SetAlpha(255)
				end
				local box = h:Lookup('Box_Icon')
				local nSec = X.GetEndTime(buff.nEndFrame)
				if nSec < 60 then
					box:SetOverText(1, X.FormatDuration(math.min(nSec, 5999), 'PRIME'))
				else
					box:SetOverText(1, '')
				end
				if buff.nStackNum > 1 then
					box:SetOverText(0, buff.nStackNum)
				end
			else
				D.handle:RemoveItem(h)
				D.handle:FormatAllItemPos()
				D.SwitchPanel(D.handle:GetItemCount())
			end
		end
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Style' then
		local menu = {
			{ szOption = _L['Mouse enter select'], bCheck = true, bChecked = O.bHoverSelect, fnAction = function()
				O.bHoverSelect = not O.bHoverSelect
			end }
		}
		PopupMenu(menu)
	elseif szName == 'Btn_Close' then
		D.handle:Clear()
		D.SwitchPanel(0)
	end
end

function D.OnItemLButtonDown()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
		end
		X.SetTarget(TARGET.PLAYER, this.data.dwID)
	end
end

function D.OnItemMouseLeave()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect and TEMP_TARGET_TYPE and TEMP_TARGET_ID then
			X.SetTarget(TEMP_TARGET_TYPE, TEMP_TARGET_ID)
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
		end
		HideTip()
	end
end

function D.OnItemMouseEnter()
	if this:GetName() == 'Handle_Item' then
		if O.bHoverSelect then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = X.GetTarget()
			X.SetTarget(TARGET.PLAYER, this.data.dwID)
		end
		X.OutputBuffTip(this, this.data.dwBuffID, this.data.nLevel)
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPCENTER')
end

function D.Init()
	Wnd.CloseWindow('MY_TeamMon_PBL')
	Wnd.OpenWindow(PBL_INI_FILE, 'MY_TeamMon_PBL')
	D.SwitchPanel(0)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.SwitchSelect()
	local dwType, dwID = Target_GetTargetData()
	for i = D.handle:GetItemCount() -1, 0, -1 do
		local h = D.handle:Lookup(i)
		if h and h:IsValid() then
			local sel = h:Lookup('Image_Select')
			if sel and sel:IsValid() then
				if dwID == h.data.dwID then
					sel:Show()
				else
					sel:Hide()
				end
			end
		end
	end
end

function D.SwitchPanel(nCount)
	local h = 40
	D.frame:SetH(h * nCount + 30)
	D.bg:SetH(h * nCount + 30)
	D.handle:SetH(h * nCount)
	if nCount == 0 then
		D.frame:Hide()
	else
		D.frame:Show()
	end
end

function D.ClosePanel()
	Wnd.CloseWindow(D.frame)
	D.frame = nil
end

function D.GetPlayer(dwID)
	local player, info
	if dwID == UI_GetClientPlayerID() then
		player = GetClientPlayer()
		info = {
			dwMountKungfuID = UI_GetPlayerMountKungfuID(),
			szName = player.szName,
		}
	else
		player = GetPlayer(dwID)
		info = GetClientTeam().GetMemberInfo(dwID)
	end
	if info then
		if player then
			info.fCurrentLife64, info.fMaxLife64 = X.GetObjectLife(player)
		else
			info.fCurrentLife64, info.fMaxLife64 = X.GetObjectLife(info)
		end
	end
	return player, info
end

function D.OnTableInsert(dwID, dwBuffID, nLevel, nIcon)
	local p, info = D.GetPlayer(dwID)
	if not p or not info then
		return
	end
	local key = dwID .. '_' .. dwBuffID .. '_' .. nLevel -- 主要担心窗口名称太长
	if CACHE_LIST[key] and CACHE_LIST[key]:IsValid() then
		return
	end
	local buff = GetBuff(p, dwBuffID)
	if not buff then
		return
	end
	local dwTargetType, dwTargetID = Target_GetTargetData()
	-- 判断是否有8帧之内的气劲 如果有则排序时候应当拥有相同的权重（解决不同客户端同步团队BUFF顺序不一致的问题）
	local nLFC = GetLogicFrameCount()
	local nSortLFC = nLFC
	for i = D.handle:GetItemCount() - 1, 0, -1 do
		local hItem = D.handle:Lookup(i)
		if nLFC - hItem.nLFC <= ENVIRONMENT.GAME_FPS / 2 and nLFC - hItem.nSortLFC <= ENVIRONMENT.GAME_FPS / 2 then
			nSortLFC = hItem.nSortLFC
			break
		end
	end
	local data = { dwID = dwID, dwBuffID = dwBuffID, nLevel = nLevel }
	local h = D.handle:AppendItemFromData(D.hItem)
	local nCount = D.handle:GetItemCount()
	if dwTargetID == dwID then
		h:Lookup('Image_Select'):Show()
	end
	h:SetUserData(nSortLFC * 1000 + dwID % 1000)
	h:Lookup('Image_KungFu'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID) or 1435)
	h:Lookup('Text_Name'):SetText(nCount .. ' ' .. info.szName)
	h:Lookup('Image_life'):SetPercentage(info.fCurrentLife64 / math.max(info.fMaxLife64, 1))
	local box = h:Lookup('Box_Icon')
	local _, icon = X.GetBuffName(dwBuffID, nLevel)
	if nIcon then
		icon = nIcon
	end
	box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
	box:SetObjectIcon(icon)
	box:SetObjectStaring(true)
	box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	box:SetOverTextFontScheme(1, 8)
	box:SetOverTextFontScheme(0, 7)
	local nSec = X.GetEndTime(buff.nEndFrame)
	if nSec < 60 then
		box:SetOverText(1, math.floor(nSec) .. '\'')
	end
	if buff.nStackNum > 1 then
		box:SetOverText(0, buff.nStackNum)
	end
	h.data = data
	h.nLFC = nLFC
	h.nSortLFC = nSortLFC
	h:Show()
	D.handle:Sort()
	D.handle:FormatAllItemPos()
	D.SwitchPanel(nCount)
	CACHE_LIST[key] = h
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_TeamMon_PBL', D.Init)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_PBL',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'bHoverSelect',
				'tAnchor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bHoverSelect',
				'tAnchor',
			},
			root = O,
		},
	},
}
MY_TeamMon_PBL = X.CreateModule(settings)
end
