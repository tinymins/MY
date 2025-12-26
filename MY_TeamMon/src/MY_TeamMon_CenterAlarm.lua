--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 中央报警
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_CenterAlarm'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_CenterAlarm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_TeamMon_CenterAlarm', { ['*'] = false, exp = false })
--------------------------------------------------------------------------------

local INI_FILE = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_CenterAlarm.ini'
local O = X.CreateUserSettingsModule('MY_TeamMon_CenterAlarm', _L['Raid'], {
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_CenterAlarm'],
			_L['UI Anchor'],
		}),
		szRestriction = 'MY_TeamMon_CenterAlarm',
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 0, y = 350 },
	},
})
local D = {}

-- FireUIEvent('MY_TEAM_MON__CENTER_ALARM__CREATE', 'test', 3)
local function CreateCentralAlert(szMsg, nTime, bXml)
	local msg = D.msg
	nTime = nTime or 3
	msg:Clear()
	if not bXml then
		szMsg = GetFormatText(szMsg, 44, 255, 255, 255)
	end
	msg:AppendItemFromString(szMsg)
	msg:FormatAllItemPos()
	local w, h = msg:GetAllItemSize()
	msg:SetRelPos((480 - w) / 2, (45 - h) / 2 - 1)
	D.handle:FormatAllItemPos()
	msg.nTime   = nTime
	msg.nCreate = GetTime()
	D.frame:SetAlpha(255)
	D.frame:Show()
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TEAM_MON__CENTER_ALARM__CREATE')
	D.frame  = this
	D.handle = this:Lookup('', '')
	D.msg    = this:Lookup('', 'MessageBox')
	D.UpdateAnchor(this)
end

function D.OnFrameRender()
	local nNow = GetTime()
	if D.msg.nCreate then
		local nTime = ((nNow - D.msg.nCreate) / 1000)
		local nLeft  = D.msg.nTime - nTime
		if nLeft < 0 then
			D.msg.nCreate = nil
			D.frame:Hide()
		else
			local nTimeLeft = nTime * 1000 % 750
			local nAlpha = 50 * nTimeLeft / 750
			if math.floor(nTime / 0.75) % 2 == 1 then
				nAlpha = 50 - nAlpha
			end
			D.frame:SetAlpha(255 - nAlpha)
		end
	end
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TEAM_MON__CENTER_ALARM__CREATE' then
		CreateCentralAlert(arg0, arg1, arg2)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Center alarm'])
		if szEvent == 'ON_ENTER_CUSTOM_UI_MODE' then
			this:Show()
		else
			this:Hide()
		end
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.CheckEnable()
	X.UI.CloseFrame('MY_TeamMon_CenterAlarm')
	if X.IsRestricted('MY_TeamMon_CenterAlarm') then
		return
	end
	X.UI.OpenFrame(INI_FILE, 'MY_TeamMon_CenterAlarm'):Hide()
end

function D.Init()
	D.CheckEnable()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_CenterAlarm',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'tAnchor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'tAnchor',
			},
			root = O,
		},
	},
}
MY_TeamMon_CenterAlarm = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_TeamMon_CenterAlarm', D.Init)

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon_CenterAlarm', function()
	if arg0 and arg0 ~= 'MY_TeamMon_CenterAlarm' then
		return
	end
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
