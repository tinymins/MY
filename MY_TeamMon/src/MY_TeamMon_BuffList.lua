--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : BUFF列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_BuffList'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_BuffList'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_TeamMon_BuffList', { ['*'] = false, zhcn_exp = false, classic_yq = true, classic_exp = false  })
--------------------------------------------------------------------------------

local GetBuff = X.GetBuff
local FilterCustomText = MY_TeamMon.FilterCustomText

local INI_FILE = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_BuffList.ini'
local O = X.CreateUserSettingsModule('MY_TeamMon_BuffList', _L['Raid'], {
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_BuffList'],
			_L['UI Anchor'],
		}),
		szRestriction = 'MY_TeamMon_BuffList',
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'TOPLEFT', r = 'CENTER', x = 300, y = -200 },
	},
	nCount = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_BuffList'],
			_L['Max buff count'],
		}),
		szRestriction = 'MY_TeamMon_BuffList',
		xSchema = X.Schema.Number,
		xDefaultValue = 8,
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_BuffList'],
			_L['Buff size'],
		}),
		szRestriction = 'MY_TeamMon_BuffList',
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
})
local D = {
	fScale = 1,
}

-- FireUIEvent('MY_TEAM_MON__BUFF_LIST__CREATE', 103, 1, { 255, 0, 0 })
local function CreateBuffList(dwID, nLevel, col, tArgs, szSender, szReceiver)
	local key = tostring(dwID) -- .. '.' .. nLevel
	col = col or { 255, 255, 0 }
	tArgs = tArgs or {}
	local level = tArgs.bCheckLevel and nLevel or nil
	local buff = GetBuff(X.GetClientPlayer(), dwID, level)
	if buff then
		local ui, bScale
		if D.handle:Lookup(key) then
			ui = D.handle:Lookup(key)
		else
			if D.handle:GetItemCount() >= O.nCount then
				return
			end
			ui = D.handle:AppendItemFromData(D.hItem, key)
			bScale = true
		end
		local szName, nIcon = X.GetBuffName(dwID, nLevel)
		ui.dwID = dwID
		ui.nLevel = level
		ui:Lookup('Text_Name'):SetText(FilterCustomText(tArgs.szName, szSender, szReceiver) or szName)
		ui:Lookup('Text_Name'):SetFontColor(unpack(col))
		local box = ui:Lookup('Box')
		box:SetObjectIcon(tArgs.nIcon or nIcon)
		box:SetObjectSparking(true)
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		if buff.nStackNum > 1 then
			box:SetOverText(0, buff.nStackNum)
		else
			box:SetOverText(0, '')
		end
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, dwID, nLevel)
		ui:Lookup('Text_Time'):SetFontColor(unpack(col))
		if bScale then
			ui:Scale(O.fScale, O.fScale)
		end
		ui.bDelete = nil
		ui:SetAlpha(255)
		D.handle:FormatAllItemPos()
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TEAM_MON__BUFF_LIST__CREATE')
	D.hItem = this:CreateItemData(INI_FILE, 'Handle_Item')
	D.frame = this
	D.handle = this:Lookup('', '')
	D.handle:Clear()
	D.ReSize()
	D.UpdateAnchor(this)
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TEAM_MON__BUFF_LIST__CREATE' then
		CreateBuffList(arg0, arg1, arg2, arg3, arg4, arg5)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Buff list'])
	end
end
function D.OnItemMouseEnter()
	local h = this:GetParent()
	local buff = GetBuff(X.GetClientPlayer(), h.dwID, h.nLevel)
	if buff then
		this:SetObjectMouseOver(true)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		X.OutputBuffTip({ x, y, w, h }, buff.dwID, buff.nLevel, X.GetEndTime(buff.nEndFrame))
	end
end

function D.OnItemRButtonClick()
	local h = this:GetParent()
	X.CancelBuff(X.GetClientPlayer(), h.dwID, h.nLevel)
end

function D.OnItemMouseLeave()
	if this:IsValid() then
		this:SetObjectMouseOver(false)
		HideTip()
	end
end

function D.OnFrameBreathe()
	local me = X.GetClientPlayer()
	if not me then return end
	for i = D.handle:GetItemCount() -1, 0, -1 do
		local h = D.handle:Lookup(i)
		if h and h:IsValid() then
			if h.bDelete then
				local nAlpha = h:GetAlpha()
				if nAlpha == 0 then
					D.handle:RemoveItem(h)
					D.handle:FormatAllItemPos()
				else
					h:SetAlpha(math.max(0, nAlpha - 30))
					h:Lookup('Animate_Update'):SetAlpha(0)
				end
			else
				local buff = GetBuff(me, h.dwID, h.nLevel)
				if buff then
					local nSec = X.GetEndTime(buff.nEndFrame)
					if nSec > 24 * 60 * 60 then
						h:Lookup('Text_Time'):SetText('')
					else
						h:Lookup('Text_Time'):SetText(X.FormatDuration(nSec, 'PRIME'))
					end
					local nAlpha = h:Lookup('Animate_Update'):GetAlpha()
					if nAlpha > 0 then
						h:Lookup('Animate_Update'):SetAlpha(math.max(0, nAlpha - 8))
					end
					if buff.nStackNum > 1 then
						h:Lookup('Box'):SetOverText(0, buff.nStackNum)
					else
						h:Lookup('Box'):SetOverText(0, '')
					end
				else
					h.bDelete = true
				end
			end
		end
	end
	if not X.IsInCustomUIMode() then
		this:SetMousePenetrable(not IsCtrlKeyDown())
	else
		this:SetMousePenetrable(false)
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
end

function D.ReSize()
	if not D.frame or not D.handle then
		return
	end
	if D.fScale ~= O.fScale then
		local fNewScale = O.fScale / D.fScale
		D.frame:Scale(fNewScale, fNewScale)
		D.fScale = O.fScale
	end
	D.frame:SetSize(O.nCount * 55 * O.fScale, 90 * O.fScale)
	D.handle:SetSize(O.nCount * 55 * O.fScale, 90 * O.fScale)
	D.handle:FormatAllItemPos()
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.CheckEnable()
	X.UI.CloseFrame('MY_TeamMon_BuffList')
	if X.IsRestricted('MY_TeamMon_BuffList') then
		return
	end
	X.UI.OpenFrame(INI_FILE, 'MY_TeamMon_BuffList')
end

function D.Init()
	D.CheckEnable()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_BuffList',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'tAnchor',
				'nCount',
				'fScale',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'tAnchor',
				'nCount',
				'fScale',
			},
			triggers = {
				nCount = D.ReSize,
				fScale = D.ReSize,
			},
			root = O,
		},
	},
}
MY_TeamMon_BuffList = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_TeamMon_BuffList', D.Init)

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon_BuffList', function()
	if arg0 and arg0 ~= 'MY_TeamMon_BuffList' then
		return
	end
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
