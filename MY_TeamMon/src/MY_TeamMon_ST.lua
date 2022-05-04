--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 倒计时类
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_ST'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_ST'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local SplitString, TrimString, FormatDuration = X.SplitString, X.TrimString, X.FormatDuration
local FilterCustomText = MY_TeamMon.FilterCustomText

local O = X.CreateUserSettingsModule('MY_TeamMon_ST', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'TOPRIGHT', r = 'CENTER', x = -250, y = -300 },
	},
	nBelowDecimal = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
})
local D = {}

-- ST class
local ST = {}
ST.__index = ST

local MY_TM_TYPE = MY_TeamMon.MY_TM_TYPE
local ST_INIFILE = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_ST.ini'
local ST_UI_NOMAL   = 5
local ST_UI_WARNING = 2
local ST_UI_ALPHA   = 180
local ST_TIME_EXPIRE = {}
local ST_CACHE = {}
do
	for k, v in pairs(MY_TM_TYPE) do
		ST_CACHE[v] = setmetatable({}, { __mode = 'v' })
		ST_TIME_EXPIRE[v] = {}
	end
end

-- 解析分段倒计时
local function GetCountdown(tTime, szSender, szReceiver)
	local tab = {}
	local t = SplitString(tTime, ';')
	for k, v in ipairs(t) do
		local time = SplitString(v, ',')
		if time[1] and time[2] and tonumber(TrimString(time[1])) and time[2] ~= '' then
			table.insert(tab, { nTime = tonumber(time[1]), szName = FilterCustomText(time[2], szSender, szReceiver) })
		end
	end
	if X.IsEmpty(tab) then
		return nil
	else
		table.sort(tab, function(a, b) return a.nTime < b.nTime end)
		return tab
	end
end
-- 倒计时模块 事件名称 MY_TM_ST_CREATE
-- nType 倒计时类型 MY_TM_TYPE
-- szKey 同一类型内唯一标识符
-- tParam {
--      szName   -- 倒计时名称 如果是分段就不需要传名称
--      nTime    -- 时间  例 10,测试;25,测试2; 或 30
--      nRefresh -- 多少时间内禁止重复刷新
--      nIcon    -- 倒计时图标ID
--      bTalk    -- 是否发布倒计时 5秒内聊天框提示 【szName】 剩余 n 秒。
-- }
-- 例子：FireUIEvent('MY_TM_ST_CREATE', 0, 'test', { nTime = '5,test;15,测试;25,c', szName = 'demo' })
-- 性能测试：for i = 1, 200 do FireUIEvent('MY_TM_ST_CREATE', 0, i, { nTime = Random(5, 15), nIcon = i }) end
local function CreateCountdown(nType, szKey, tParam, szSender, szReceiver)
	assert(type(tParam) == 'table', 'CreateCountdown failed!')
	local tTime = {}
	local nTime = GetTime()
	if type(tParam.nTime) == 'number' then
		tTime = tParam
	else
		local tCountdown = GetCountdown(tParam.nTime, szSender, szReceiver)
		if tCountdown then
			tTime = tCountdown[1]
			tParam.nTime = tCountdown
			tParam.nRefresh = tParam.nRefresh or tCountdown[#tCountdown].nTime - 3 -- 最大时间内防止重复刷新 但是脱离战斗的NPC需要手动删除
		else
			return X.Sysmsg(
				_L['MY_TeamMon'],
				_L['Countdown format error']
					.. ' TYPE: ' .. _L['Countdown TYPE ' .. nType]
					.. ' KEY:' .. szKey .. ' Content:' .. tParam.nTime,
				X.CONSTANT.MSG_THEME.ERROR)
		end
	end
	if tTime.nTime == 0 then
		local ui = ST_CACHE[nType][szKey]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
		ST_TIME_EXPIRE[nType][szKey] = nil
	elseif tTime.nTime == -1 then
		local ui = ST_CACHE[nType][szKey]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
	elseif tTime.nTime == -2 then
		ST_TIME_EXPIRE[nType][szKey] = nil
	else
		local nExpire = ST_TIME_EXPIRE[nType][szKey]
		if nExpire and nExpire > nTime then
			return
		end
		ST_TIME_EXPIRE[nType][szKey] = nTime + (tParam.nRefresh or 0) * 1000
		ST:ctor(nType, szKey, tParam):SetInfo(tTime, tParam.nIcon or 13):Switch(false)
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TM_ST_CREATE')
	this:RegisterEvent('MY_TM_ST_DEL')
	this:RegisterEvent('MY_TM_ST_CLEAR')
	D.hItem = this:CreateItemData(ST_INIFILE, 'Handle_Item')
	D.UpdateAnchor(this)
	D.handle = this:Lookup('', 'Handle_List')
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_ST_CREATE' then
		CreateCountdown(arg0, arg1, arg2, arg3, arg4)
	elseif szEvent == 'MY_TM_ST_DEL' then
		local ui = ST_CACHE[arg0][arg1]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
		ST_TIME_EXPIRE[arg0][arg1] = nil
	elseif szEvent == 'MY_TM_ST_CLEAR' then
		D.handle:Clear()
		for k, v in pairs(ST_TIME_EXPIRE) do
			ST_TIME_EXPIRE[k] = {}
		end
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		this:BringToTop()
		UpdateCustomModeWindow(this, _L['Countdown'])
	elseif szEvent == 'LOADING_END' then
		for k, v in pairs(ST_CACHE) do
			for kk, vv in pairs(v) do
				if vv and vv:IsValid() and not vv.bHold then
					vv.obj:RemoveItem()
				end
			end
		end
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
end

local function SetSTAction(ui, nLeft, nPer)
	local me = GetClientPlayer()
	local obj = ui.obj
	if nLeft < 5 then
		local nTimeLeft = nLeft * 1000 % 1000
		local nAlpha = 255 * nTimeLeft / 1000
		if math.floor(nLeft / 1) % 2 == 1 then
			nAlpha = 255 - nAlpha
		end
		obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):Switch(true):SetAlpha(100 + nAlpha)
		if ui.bTalk and me.IsInParty() then
			if not ui.szTalk or ui.szTalk ~= math.floor(nLeft) then
				ui.szTalk = math.floor(nLeft)
				MY_TeamMon.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('[%s] remaining %ds.', obj:GetName(), math.floor(nLeft)))
			end
		end
	else
		if ui.nAlpha < ST_UI_ALPHA then
			ui.nAlpha = math.min(ST_UI_ALPHA, ui.nAlpha + 15)
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):SetAlpha(ui.nAlpha)
		else
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer)
		end
	end
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then return end
	local nNow = GetTime()
	for k, v in pairs(ST_CACHE) do
		for kk, vv in pairs(v) do
			if vv:IsValid() then
				if type(vv.countdown) == 'number' then
					local nLeft  = vv.countdown - ((nNow - vv.nLeft) / 1000)
					if nLeft >= 0 then
						SetSTAction(vv, nLeft, nLeft / vv.countdown)
					else
						vv.obj:RemoveItem()
					end
				else
					local time = vv.countdown[1]
					local nLeft = time.nTime - (nNow - vv.nLeft) / 1000
					if nLeft >= 0 then
						SetSTAction(vv, nLeft, nLeft / time.nTime)
					else
						if #vv.countdown == 1 then
							vv.obj:RemoveItem()
						else
							local nATime = (nNow - vv.nCreate) / 1000
							vv.nLeft = nNow
							table.remove(vv.countdown, 1)
							local time = vv.countdown[1]
							time.nTime = time.nTime - nATime
							vv.obj:SetInfo(time):Switch(false)
						end
					end
				end
			end
		end
	end
	D.handle:Sort()
	D.handle:FormatAllItemPos()
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.Init()
	Wnd.CloseWindow('MY_TeamMon_ST')
	Wnd.OpenWindow(ST_INIFILE, 'MY_TeamMon_ST')
end

-- 构造函数
function ST:ctor(nType, szKey, tParam)
	if not ST_CACHE[nType] then
		return
	end
	if not tParam.szName then
		tParam.szName = nType .. '#' .. szKey
	end
	local ui = ST_CACHE[nType][szKey]
	local nTime = GetTime()
	local oo
	if ui and ui:IsValid() then
		oo = ui.obj
		oo.ui.nCreate   = nTime
		oo.ui.nLeft     = nTime
		oo.ui.countdown = tParam.nTime
		oo.ui.nRefresh  = tParam.nRefresh or 1
		oo.ui.bTalk     = tParam.bTalk
		oo.ui.nFrame    = tParam.nFrame
	else -- 没有ui的情况下 创建
		oo = {}
		setmetatable(oo, self)
		oo.ui                = D.handle:AppendItemFromData(D.hItem)
		-- 参数
		oo.ui.nCreate        = nTime
		oo.ui.nLeft          = nTime
		oo.ui.countdown      = tParam.nTime
		oo.ui.nRefresh       = tParam.nRefresh or 1
		oo.ui.bTalk          = tParam.bTalk
		oo.ui.nFrame         = tParam.nFrame
		oo.ui.bHold          = tParam.bHold
		-- 杂项
		oo.ui.nAlpha         = 30
		-- ui
		oo.ui.time           = oo.ui:Lookup('TimeLeft')
		oo.ui.txt            = oo.ui:Lookup('SkillName')
		oo.ui.img            = oo.ui:Lookup('Image')
		oo.ui.sha            = oo.ui:Lookup('shadow')
		oo.ui.sfx            = oo.ui:Lookup('SFX')
		oo.ui.obj            = oo
		ST_CACHE[nType][szKey] = oo.ui
		oo.ui:Show()
		oo.ui.sfx:Set2DRotation(math.pi / 2)
		D.handle:FormatAllItemPos()
	end
	return oo
end

-- 设置倒计时的名称和时间 用于动态改变分段倒计时
function ST:SetInfo(tTime, nIcon)
	if tTime.szName then
		self.ui.txt:SetText(tTime.szName)
	end
	if tTime.nTime then
		self.ui.time:SetText(
			(
				tTime.nTime >= 60
					and FormatDuration(tTime.nTime - tTime.nTime % 60, 'ENGLISH_ABBR', { accuracyunit = 'minute' })
					or ''
			)
			.. (
				(D.bReady and O.nBelowDecimal ~= 0 and (O.nBelowDecimal == 3601 or (tTime.nTime < O.nBelowDecimal and tTime.nTime >= 0.1)))
					and ('%.1fs'):format(tTime.nTime % 60)
					or ('%ds'):format(tTime.nTime % 60)
			)
		)
		self.ui:SetUserData(math.floor(tTime.nTime))
	end
	if nIcon then
		local box = self.ui:Lookup('Box')
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
		box:SetObjectIcon(nIcon)
	end
	return self
end

-- 设置进度条
function ST:SetPercentage(fPercentage)
	self.ui.img:SetPercentage(fPercentage)
	self.ui.sfx:SetRelX(32 + 300 * fPercentage)
	self.ui.sha:SetW(300 - 300 * fPercentage)
	self.ui.sha:SetRelX(32 + 300 * fPercentage)
	self.ui:FormatAllItemPos()
	return self
end

-- 改变样式 如果true则更改为第二样式 用于时间小于5秒的时候
function ST:Switch(bSwitch)
	if bSwitch then
		self.ui.txt:SetFontColor(255, 255, 255)
		-- self.ui.time:SetFontColor(255, 255, 255)
		self.ui.img:SetFrame(ST_UI_WARNING)
		-- self.ui.sha:SetColorRGB(30, 0, 0)
	else
		self.ui.txt:SetFontColor(255, 255, 0)
		self.ui.time:SetFontColor(255, 255, 255)
		self.ui.img:SetFrame(self.ui.nFrame or ST_UI_NOMAL)
		self.ui.img:SetAlpha(self.ui.nAlpha)
		-- self.ui.sha:SetAlpha(100)
		self.ui.sha:SetColorRGB(0, 0, 0)
	end
	return self
end

function ST:SetAlpha(nAlpha)
	self.ui.img:SetAlpha(nAlpha)
	-- self.ui.sha:SetAlpha(100 * (nAlpha / 255))
	return self
end

function ST:GetName()
	return self.ui.txt:GetText()
end

-- 删除倒计时
function ST:RemoveItem()
	D.handle:RemoveItem(self.ui)
	D.handle:FormatAllItemPos()
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_TeamMon_ST', function()
	D.bReady = true
	D.Init()
end)

X.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_TeamMon_ST', function()
	D.bReady = false
end)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_ST',
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				'nBelowDecimal',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'nBelowDecimal',
			},
			root = O,
		},
	},
}
MY_TeamMon_ST = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
