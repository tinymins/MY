--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����ʱ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local SplitString, TrimString, FormatTimeCounter = LIB.SplitString, LIB.TrimString, LIB.FormatTimeCounter

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon_ST', _L['MY_TeamMon_ST'], 0x2013500) then
	return
end

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
local function GetCountdown(tTime)
	local tab = {}
	local t = SplitString(tTime, ';')
	for k, v in ipairs(t) do
		local time = SplitString(v, ',')
		if time[1] and time[2] and tonumber(TrimString(time[1])) and time[2] ~= '' then
			insert(tab, { nTime = tonumber(time[1]), szName = time[2] })
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
local function CreateCountdown(nType, szKey, tParam)
	assert(type(tParam) == 'table', 'CreateCountdown failed!')
	local tTime = {}
	local nTime = GetTime()
	if type(tParam.nTime) == 'number' then
		tTime = tParam
	else
		local tCountdown = GetCountdown(tParam.nTime)
		if tCountdown then
			tTime = tCountdown[1]
			tParam.nTime = tCountdown
			tParam.nRefresh = tParam.nRefresh or tCountdown[#tCountdown].nTime - 3 -- ���ʱ���ڷ�ֹ�ظ�ˢ�� ��������ս����NPC��Ҫ�ֶ�ɾ��
		else
			return LIB.Sysmsg(
				_L['Countdown format Error']
					.. ' TYPE: ' .. _L['Countdown TYPE ' .. nType]
					.. ' KEY:' .. szKey .. ' Content:' .. tParam.nTime,
				_L['MY_TeamMon'], 'MSG_SYS.ERROR')
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

MY_TeamMon_ST = {
	bEnable = true,
	tAnchor = {},
}
LIB.RegisterCustomData('MY_TeamMon_ST')

local D = {}

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
		CreateCountdown(arg0, arg1, arg2)
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
	MY_TeamMon_ST.tAnchor = GetFrameAnchor(this)
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
				LIB.Talk(_L('[%s] left over %d.', obj:GetName(), floor(nLeft)))
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
	local a = MY_TeamMon_ST.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, -300)
	end
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
		self.ui:SetUserData(math.floor(tTime.nTime))
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

LIB.RegisterEvent('LOGIN_GAME', D.Init)