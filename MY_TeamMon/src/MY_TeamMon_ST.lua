--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����ʱ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_ST'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local SplitString, TrimString, FormatTimeCounter = LIB.SplitString, LIB.TrimString, LIB.FormatTimeCounter
local FilterCustomText = MY_TeamMon.FilterCustomText

local ANCHOR = { s = 'TOPRIGHT', r = 'CENTER', x = -250, y = -300 } -- szSide, szRelSide, fOffsetX, fOffsetY
local D = {}

MY_TeamMon_ST = {
	bEnable = true,
	tAnchor = {},
}
LIB.RegisterCustomData('MY_TeamMon_ST')

-- ST class
local ST = {}
ST.__index = ST

local MY_TM_TYPE = MY_TeamMon.MY_TM_TYPE
local ST_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_ST.ini'
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

-- �����ֶε���ʱ
local function GetCountdown(tTime, szSender, szReceiver)
	local tab = {}
	local t = SplitString(tTime, ';')
	for k, v in ipairs(t) do
		local time = SplitString(v, ',')
		if time[1] and time[2] and tonumber(TrimString(time[1])) and time[2] ~= '' then
			insert(tab, { nTime = tonumber(time[1]), szName = FilterCustomText(time[2], szSender, szReceiver) })
		end
	end
	if IsEmpty(tab) then
		return nil
	else
		sort(tab, function(a, b) return a.nTime < b.nTime end)
		return tab
	end
end
-- ����ʱģ�� �¼����� MY_TM_ST_CREATE
-- nType ����ʱ���� MY_TM_TYPE
-- szKey ͬһ������Ψһ��ʶ��
-- tParam {
--      szName   -- ����ʱ���� ����ǷֶξͲ���Ҫ������
--      nTime    -- ʱ��  �� 10,����;25,����2; �� 30
--      nRefresh -- ����ʱ���ڽ�ֹ�ظ�ˢ��
--      nIcon    -- ����ʱͼ��ID
--      bTalk    -- �Ƿ񷢲�����ʱ 5�����������ʾ ��szName�� ʣ�� n �롣
-- }
-- ���ӣ�FireUIEvent('MY_TM_ST_CREATE', 0, 'test', { nTime = '5,test;15,����;25,c', szName = 'demo' })
-- ���ܲ��ԣ�for i = 1, 200 do FireUIEvent('MY_TM_ST_CREATE', 0, i, { nTime = Random(5, 15), nIcon = i }) end
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
			tParam.nRefresh = tParam.nRefresh or tCountdown[#tCountdown].nTime - 3 -- ���ʱ���ڷ�ֹ�ظ�ˢ�� ��������ս����NPC��Ҫ�ֶ�ɾ��
		else
			return LIB.Sysmsg(
				_L['MY_TeamMon'],
				_L['Countdown format error']
					.. ' TYPE: ' .. _L['Countdown TYPE ' .. nType]
					.. ' KEY:' .. szKey .. ' Content:' .. tParam.nTime,
				CONSTANT.MSG_THEME.ERROR)
		end
	end
	if tTime.nTime == 0 then
		local ui = ST_CACHE[nType][szKey]
		if ui and ui:IsValid() then
			ST_TIME_EXPIRE[nType][szKey] = nil
			return ui.obj:RemoveItem()
		end
	else
		local nExpire =  ST_TIME_EXPIRE[nType][szKey]
		if nExpire and nExpire > nTime then
			return
		end
		ST_TIME_EXPIRE[nType][szKey] = nTime + (tParam.nRefresh or 0) * 1000
		ST:ctor(nType, szKey, tParam):SetInfo(tTime, tParam.nIcon or 13):Switch(false)
	end
end

function MY_TeamMon_ST.OnFrameCreate()
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

function MY_TeamMon_ST.OnEvent(szEvent)
	if szEvent == 'MY_TM_ST_CREATE' then
		CreateCountdown(arg0, arg1, arg2, arg3, arg4)
	elseif szEvent == 'MY_TM_ST_DEL' then
		local ui = ST_CACHE[arg0][arg1]
		if ui and ui:IsValid() then
			if arg2 then -- ǿ��������ɾ��
				ui.obj:RemoveItem()
				ST_TIME_EXPIRE[arg0][arg1] = nil
			end
		end
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

function MY_TeamMon_ST.OnFrameDragEnd()
	this:CorrectPos()
	MY_TeamMon_ST.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
end

local function SetSTAction(ui, nLeft, nPer)
	local me = GetClientPlayer()
	local obj = ui.obj
	if nLeft < 5 then
		local nTimeLeft = nLeft * 1000 % 1000
		local nAlpha = 255 * nTimeLeft / 1000
		if floor(nLeft / 1) % 2 == 1 then
			nAlpha = 255 - nAlpha
		end
		obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):Switch(true):SetAlpha(100 + nAlpha)
		if ui.bTalk and me.IsInParty() then
			if not ui.szTalk or ui.szTalk ~= floor(nLeft) then
				ui.szTalk = floor(nLeft)
				LIB.Talk(_L('[%s] remaining %ds.', obj:GetName(), floor(nLeft)))
			end
		end
	else
		if ui.nAlpha < ST_UI_ALPHA then
			ui.nAlpha = min(ST_UI_ALPHA, ui.nAlpha + 15)
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):SetAlpha(ui.nAlpha)
		else
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer)
		end
	end
end

function MY_TeamMon_ST.OnFrameBreathe()
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
							remove(vv.countdown, 1)
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
	local a = IsEmpty(MY_TeamMon_ST.tAnchor) and ANCHOR or MY_TeamMon_ST.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

function D.Init()
	local frame = Wnd.OpenWindow(ST_INIFILE, 'MY_TeamMon_ST')
end

-- ���캯��
function ST:ctor(nType, szKey, tParam)
	if not ST_CACHE[nType] then
		return
	end
	local ui = ST_CACHE[nType][szKey]
	local nTime = GetTime()
	local key = nType .. '#' .. szKey
	tParam.szName = tParam.szName or key
	local oo
	if ui and ui:IsValid() then
		oo = ui.obj
		oo.ui.nCreate   = nTime
		oo.ui.nLeft     = nTime
		oo.ui.countdown = tParam.nTime
		oo.ui.nRefresh  = tParam.nRefresh or 1
		oo.ui.bTalk     = tParam.bTalk
		oo.ui.nFrame    = tParam.nFrame
	else -- û��ui������� ����
		oo = {}
		setmetatable(oo, self)
		oo.ui                = D.handle:AppendItemFromData(D.hItem)
		-- ����
		oo.ui.nCreate        = nTime
		oo.ui.nLeft          = nTime
		oo.ui.countdown      = tParam.nTime
		oo.ui.nRefresh       = tParam.nRefresh or 1
		oo.ui.bTalk          = tParam.bTalk
		oo.ui.nFrame         = tParam.nFrame
		oo.ui.bHold          = tParam.bHold
		-- ����
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
		oo.ui.sfx:Set2DRotation(PI / 2)
		D.handle:FormatAllItemPos()
	end
	return oo
end
-- ���õ���ʱ�����ƺ�ʱ�� ���ڶ�̬�ı�ֶε���ʱ
function ST:SetInfo(tTime, nIcon)
	if tTime.szName then
		self.ui.txt:SetText(tTime.szName)
	end
	if tTime.nTime then
		self.ui:SetUserData(floor(tTime.nTime))
		self.ui.time:SetText(FormatTimeCounter(tTime.nTime))
	end
	if nIcon then
		local box = self.ui:Lookup('Box')
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
		box:SetObjectIcon(nIcon)
	end
	return self
end
-- ���ý�����
function ST:SetPercentage(fPercentage)
	self.ui.img:SetPercentage(fPercentage)
	self.ui.sfx:SetRelX(32 + 300 * fPercentage)
	self.ui.sha:SetW(300 - 300 * fPercentage)
	self.ui.sha:SetRelX(32 + 300 * fPercentage)
	self.ui:FormatAllItemPos()
	return self
end
-- �ı���ʽ ���true�����Ϊ�ڶ���ʽ ����ʱ��С��5���ʱ��
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
-- ɾ������ʱ
function ST:RemoveItem()
	D.handle:RemoveItem(self.ui)
	D.handle:FormatAllItemPos()
end

LIB.RegisterInit('MY_TeamMon_ST', D.Init)