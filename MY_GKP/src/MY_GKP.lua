--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
-- 早期代码 需要重写
---------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
MY_GKP = {
	bDebug               = false,
	bDebug2              = false,
	bOn                  = true,  -- enable
	bMoneyTalk           = false, -- 金钱变动喊话
	bAlertMessage        = true,  -- 进入副本提醒清空数据
	bMoneySystem         = false, -- 记录系统金钱变动
	bDisplayEmptyRecords = true,  -- show 0 record
	bAutoSync            = true,  -- 自动接收分配者的同步信息
	bShowGoldBrick       = true,
	bShow2ndKungfuLoot   = true,  -- 显示第二心法装备推荐提示图标
}
LIB.RegisterCustomData('MY_GKP')
---------------------------------------------------------------------->
-- 本地函数与变量
----------------------------------------------------------------------<
local _GKP = {
	szIniFile   = PLUGIN_ROOT .. '/ui/MY_GKP.ini',
	tSyncQueue  = {},
	bSync       = {},
	GKP_Map     = '',
	GKP_Time    = 0,
	GKP_Record  = {},
	GKP_Account = {},
	Config = {
		Subsidies = {
			{ _L['Treasure Chests'], '', true},
			-- { LIB.GetItemNameByUIID(73214), '', true},
			{ _L['Boss'], '', true},
			{ _L['Banquet Allowance'], -1000, true},
			{ _L['Fines'], '', true},
			{ _L['Other'], '', true},
		},
		Scheme = {
			{ 100, true },
			{ 1000, true },
			{ 2000, true },
			{ 3000, true },
			{ 4000, true },
			{ 5000, true },
			{ 6000, true },
			{ 7000, true },
			{ 8000, true },
			{ 9000, true },
			{ 10000, true },
			{ 20000, true },
			{ 50000, true },
			{ 100000, true },
		},
	},
}
_GKP.Config = LIB.LoadLUAData({'config/gkp.cfg', PATH_TYPE.GLOBAL}) or _GKP.Config
---------------------------------------------------------------------->
-- 数据处理
----------------------------------------------------------------------<
setmetatable(MY_GKP, { __call = function(me, key, value, sort)
	if _GKP[key] then
		if value and (key == 'GKP_Time' or key == 'GKP_Map') then
			_GKP[key] = value
			_GKP.UpdateTitle()
		elseif value and type(value) == 'table' then
			_GKP.GeneDataInfo()
			table.insert(_GKP[key], value)
			_GKP.SaveData()
			if key == 'GKP_Record' then
				_GKP.DrawRecord()
			elseif key == 'GKP_Account' then
				_GKP.DrawAccount()
			end
		elseif value and type(value) == 'string' then
			if sort == 'asc' or sort == 'desc' then
				table.sort(_GKP[key], function(a, b)
					if a[value] and b[value] then
						if sort == 'asc' then
							if a[value] ~= b[value] then
								return a[value] < b[value]
							elseif a.key and b.key then
								return a.key < b.key
							else
								return a.nTime < b.nTime
							end
						else
							if a[value] ~= b[value] then
								return a[value] > b[value]
							elseif a.key and b.key then
								return a.key > b.key
							else
								return a.nTime > b.nTime
							end
						end

					else
						return false
					end
				end)
			elseif value == 'del' then
				if _GKP[key][sort] then
					_GKP[key][sort].bDelete = not _GKP[key][sort].bDelete
					_GKP.SaveData()
					if key == 'GKP_Record' then
						_GKP.DrawRecord()
					elseif key == 'GKP_Account' then
						_GKP.DrawAccount()
					end
					return _GKP[key][sort]
				end
			end
			return _GKP[key]
		elseif value and type(value) == 'number' then
			if _GKP[key][value] then
				_GKP[key][value] = sort
				_GKP.SaveData()
				if key == 'GKP_Record' then
					_GKP.DrawRecord()
				elseif key == 'GKP_Account' then
					_GKP.DrawAccount()
				end
				return _GKP[key][value]
			end
		else
			return _GKP[key]
		end
	end
end})

---------------------------------------------------------------------->
-- 本地函数
----------------------------------------------------------------------<
function _GKP.GeneDataInfo()
	local me = GetClientPlayer()
	if MY_GKP('GKP_Map') == '' and me and me.GetMapID() then
		MY_GKP('GKP_Map', Table_GetMapName(me.GetMapID()) or '')
	end
end

function _GKP.SaveConfig()
	LIB.SaveLUAData({'config/gkp.cfg', PATH_TYPE.GLOBAL}, _GKP.Config)
end

function _GKP.SaveData(bStorage)
	local szPath = 'userdata/gkp/current.gkp'
	if bStorage then
		LIB.SaveLUAData({szPath, PATH_TYPE.ROLE}, nil) -- 存储模式时清空当前存盘数据
		local i = 0
		repeat
			szPath = 'userdata/gkp/'
				.. LIB.FormatTime(MY_GKP('GKP_Time') or GetCurrentTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
				.. (i == 0 and '' or ('-' .. i))
				.. '_' .. MY_GKP('GKP_Map')
				.. '.gkp'
			i = i + 1
		until not IsLocalFileExist(LIB.FormatPath(szPath) .. '.jx3dat')
	end
	LIB.SaveLUAData({szPath, PATH_TYPE.ROLE}, {
		GKP_Map = MY_GKP('GKP_Map'),
		GKP_Time = MY_GKP('GKP_Time'),
		GKP_Record = MY_GKP('GKP_Record'),
		GKP_Account = MY_GKP('GKP_Account'),
	})
	_GKP.UpdateStat()
	_GKP.UpdateTitle()
end

function _GKP.LoadData(szFile, bAbs)
	if not bAbs then
		szFile = {'userdata/' .. szFile .. '.gkp', PATH_TYPE.ROLE}
	end
	local t = LIB.LoadLUAData(szFile)
	if t then
		_GKP.GKP_Map = t.GKP_Map or ''
		_GKP.GKP_Time = t.GKP_Time or 0
		_GKP.GKP_Record = t.GKP_Record or {}
		_GKP.GKP_Account = t.GKP_Account or {}
	end
	_GKP.DrawRecord()
	_GKP.DrawAccount()
	_GKP.UpdateStat()
	_GKP.UpdateTitle()
end

function _GKP.UpdateTitle()
	local txtTitle = Station.Lookup('Normal/MY_GKP', 'Text_Title')
	local szMap = MY_GKP('GKP_Map')
	local nTime = MY_GKP('GKP_Time')
	local szText = _L['GKP Golden Team Record']
		.. (szMap ~= '' and (' - ' .. szMap) or '')
		.. (nTime ~= 0 and (' - ' .. LIB.FormatTime(nTime, '%yyyy-%MM-%dd-%hh-%mm-%ss')) or '')
	txtTitle:SetText(szText)
end

function _GKP.UpdateStat()
	local a, b = _GKP.GetRecordSum()
	local c, d = _GKP.GetAccountSum()
	local hStat = Station.Lookup('Normal/MY_GKP', 'Handle_Record_Stat')
	local szXml = GetFormatText(_L['Reall Salary:'], 41) .. _GKP.GetMoneyTipText(a + b)
	if LIB.IsDistributer() or not LIB.IsInParty() then
		if c + d < 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Spending:'], 41) .. _GKP.GetMoneyTipText(d)
		elseif c ~= 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Reall income:'], 41) .. _GKP.GetMoneyTipText(c + d)
		end
		local e = (a + b) - (c + d)
		if a > 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Money on Debt:'], 41) .. _GKP.GetMoneyTipText(e)
		end
	end
	hStat:Clear()
	hStat:AppendItemFromString(szXml)
	hStat:FormatAllItemPos()
	hStat:SetSizeByAllItemSize()
	hStat.OnItemMouseEnter = function()
		local br = GetFormatText('\n', 41)
		local szXml = ''
		if a > 0 then
			szXml = szXml .. GetFormatText(_L['Total Auction:'], 41) .. _GKP.GetMoneyTipText(a) .. br
			if b ~= 0 then
				szXml = szXml .. GetFormatText(_L['Salary Allowance:'], 41) .. _GKP.GetMoneyTipText(b) .. br
				szXml = szXml .. GetFormatText(_L['Reall Salary:'], 41) .. _GKP.GetMoneyTipText(a + b) .. br
			end
		end
		if (LIB.IsDistributer() or not LIB.IsInParty()) and c > 0 then
			szXml = szXml .. GetFormatText(_L['Total income:'], 41) .. _GKP.GetMoneyTipText(c) .. br
			if d ~= 0 then
				szXml = szXml .. GetFormatText(_L['Spending:'], 41) .. _GKP.GetMoneyTipText(d) .. br
				szXml = szXml .. GetFormatText(_L['Reall income:'], 41) .. _GKP.GetMoneyTipText(c + d) .. br
			end
		end
		if szXml ~= '' then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputTip(szXml, 400, { x - w, y, w, h })
		end
	end
	FireUIEvent('GKP_RECORD_TOTAL', a, b)
end

function _GKP.OpenPanel(bDisableSound)
	local frame = Station.Lookup('Normal/MY_GKP') or Wnd.OpenWindow(_GKP.szIniFile, 'MY_GKP')
	frame:Show()
	frame:BringToTop()
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end
-- close
function _GKP.ClosePanel()
	if _GKP.frame then
		_GKP.frame:Hide()
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end
-- toggle
function _GKP.TogglePanel()
	if _GKP.IsOpened() then
		_GKP.ClosePanel()
	else
		_GKP.OpenPanel()
	end
end

function _GKP.IsOpened()
	return _GKP.frame and _GKP.frame:IsVisible()
end

-- initlization
function _GKP.Init()
	_GKP.OpenPanel(true):Hide()
	local function onDelay() -- Init延后 避免和进入副本冲突
		_GKP.LoadData('gkp/current')
	end
	LIB.DelayCall(125, onDelay)
end
LIB.RegisterEvent('FIRST_LOADING_END', _GKP.Init)

function _GKP.Random() -- 生成一个随机字符串 这还能重复我吃翔
	local a = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,_+;*-'
	local t = {}
	for i = 1, 64 do
		local n = math.random(1, string.len(a))
		table.insert(t, string.sub(a, n, n))
	end
	return table.concat(t)
end

function _GKP.Sysmsg(szMsg)
	LIB.Sysmsg({szMsg}, '[MY_GKP]')
end

function _GKP.GetTimeString(nTime, year)
	if year then
		return FormatTime('%H:%M:%S', nTime)
	else
		return FormatTime('%Y-%m-%d %H:%M:%S', nTime)
	end
end

function _GKP.GetMoneyCol(Money)
	local Money = tonumber(Money)
	if Money then
		if Money < 0 then
			return 0, 128, 255
		elseif Money < 1000 then
			return 255, 255, 255
		elseif Money < 10000 then
			return 255, 255, 164
		elseif Money < 100000 then
			return 255, 255, 0
		elseif Money < 1000000 then
			return 255, 192, 0
		elseif Money < 10000000 then
			return 255, 92, 0
		else
			return 255, 0, 0
		end
	else
		return 255, 255, 255
	end
end

function _GKP.GetFormatLink(item, bName)
	if type(item) == 'string' then
		if bName then
			return { type = 'name', name = item, text = '[' .. item ..']' }
		else
			return { type = 'text', text = item }
		end
	else
		if item.nGenre == ITEM_GENRE.BOOK then
			return { type = 'book', tabtype = item.dwTabType, index = item.dwIndex, bookinfo = item.nBookID, version = item.nVersion, text = '' }
		else
			return { type = 'iteminfo', version = item.nVersion, tabtype = item.dwTabType, index = item.dwIndex, text = '' }
		end
	end
end

---------------------------------------------------------------------->
-- 窗体创建时会被调用
----------------------------------------------------------------------<
function MY_GKP.OnFrameCreate()
	_GKP.frame = this
	_GKP.hRecordContainer = this:Lookup('PageSet_Menu/Page_GKP_Record/WndScroll_GKP_Record/WndContainer_Record_List')
	_GKP.hAccountContainer = this:Lookup('PageSet_Menu/Page_GKP_Account/WndScroll_GKP_Account/WndContainer_Account_List')
	local ui = UI(this)
	ui:Text(_L['GKP Golden Team Record']):Anchor('CENTER')
	ui:Append('WndButton', {
		x = 875, y = 48, w = 100, h = 35,
		text = g_tStrings.STR_LOG_SET,
		onclick = function()
			LIB.ShowPanel()
			LIB.FocusPanel()
			LIB.SwitchTab('MY_GKP')
		end,
	})
	ui:Append('WndButton3', {
		x = 15, y = 660, text = _L['Add Manually'],
		onclick = function()
			if not LIB.IsDistributer() and not MY_GKP.bDebug then -- debug
				return LIB.Alert(_L['You are not the distrubutor.'])
			end
			_GKP.Record()
		end,
	})
	ui:Append('WndButton3', { x = 840, y = 620, text = g_tStrings.GOLD_TEAM_SYLARY_LIST, onclick = _GKP.Calculation })
	ui:Append('WndButton3', { name = 'GOLD_TEAM_BID_LIST', x = 840, y = 660, text = g_tStrings.GOLD_TEAM_BID_LIST, onclick = _GKP.SpendingList })
	ui:Append('WndButton3', { name = 'Debt', x = 690, y = 660, text = _L['Debt Issued'], onclick = _GKP.OweList })
	ui:Append('WndButton3', { x = 540, y = 660, text = _L['Clear Record'], onclick = _GKP.ClearData })
	ui:Append('WndButton3', { x = 390, y = 660, text = _L['Loading Record'], menu = _GKP.RecoveryMenu })
	ui:Append('WndButton3', {
		x = 240, y = 660, text = _L['Manual SYNC'],
		lmenu = _GKP.OnSyncFromMenu, rmenu = _GKP.OnSyncToMenu,
		tip = _L['Left click to sync from others, right click to sync to others'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	})

	local hPageSet = ui:Children('#PageSet_Menu')
	hPageSet:Children('#WndCheck_GKP_Record'):Children('#Text_GKP_Record'):Text(g_tStrings.GOLD_BID_RECORD_STATIC_TITLE)
	hPageSet:Children('#WndCheck_GKP_Account'):Children('#Text_GKP_Account'):Text(g_tStrings.GOLD_BID_RPAY_STATIC_TITLE)
	LIB.RegisterEsc('MY_GKP', _GKP.IsOpened, _GKP.ClosePanel)
	-- 排序
	local page = this:Lookup('PageSet_Menu/Page_GKP_Record')
	local t = {
		{'#',         false},
		{'szPlayer',  _L['Gainer']},
		{'szName',    _L['Name of the Items']},
		{'nMoney',    _L['Auction Price']},
		{'szNpcName', _L['Source of the Object']},
		{'nTime',     _L['Distribution Time']},
	}
	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup('', 'Text_Record_Break' ..k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or 'asc'
				_GKP.DrawRecord(v[1], sort)
				if sort == 'asc' then
					txt.sort = 'desc'
				else
					txt.sort = 'asc'
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end

	-- 排序2
	local page = this:Lookup('PageSet_Menu/Page_GKP_Account')
	local t = {
		{'#',        false},
		{'szPlayer', _L['Transation Target']},
		{'nGold',    _L['Changes in Money']},
		{'szPlayer', _L['Ways of Money Change']},
		{'dwMapID',  _L['The Map of Current Location when Money Changes']},
		{'nTime',    _L['The Change of Time']},
	}

	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup('', 'Text_Account_Break' .. k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or 'asc'
				_GKP.DrawAccount(v[1], sort)
				if sort == 'asc' then
					txt.sort = 'desc'
				else
					txt.sort = 'asc'
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end
end

function MY_GKP.OnFrameKeyDown()
	if GetKeyName(Station.GetMessageKey()) == 'Esc' then
		_GKP.ClosePanel()
		return 1
	end
end

function MY_GKP.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		_GKP.ClosePanel()
	end
end

function MY_GKP.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == 'Text_Name' then
		if IsCtrlKeyDown() then
			return LIB.EditBox_AppendLinkPlayer(this:GetText())
		end
	end
end

function MY_GKP.OnItemMouseEnter()
	if this:GetName() == 'Text_Name' then
		local data = this.data
		local szIcon, nFrame = GetForceImage(data.dwForceID)
		local r, g, b = LIB.GetForceColor(data.dwForceID)
		local szXml = GetFormatImage(szIcon,nFrame,20,20) .. GetFormatText('  ' .. data.szPlayer .. g_tStrings.STR_COLON .. '\n', 136, r, g, b)
		if IsCtrlKeyDown() then
			szXml = szXml .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. '\n', 136, 255, 0, 0)
			szXml = szXml .. GetFormatText(EncodeLUAData(data, ' '), 136, 255, 255, 255)
		else
			szXml = szXml .. GetFormatText(_L['System Information as Shown Below\n\n'],136,255,255,255)
			local nNum,nNum1,nNum2 = 0,0,0
			for kk,vv in ipairs(MY_GKP('GKP_Record')) do
				if vv.szPlayer == data.szPlayer and not vv.bDelete then
					if  vv.nMoney > 0 then
						nNum = nNum + vv.nMoney
					else
						nNum1 = nNum1 + vv.nMoney
					end
				end
			end
			local r, g, b = _GKP.GetMoneyCol(nNum)
			szXml = szXml .. GetFormatText(_L['Total Cosumption:'],136,255,128,0) .. GetFormatText(nNum ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n',136,r,g,b)
			local r, g, b = _GKP.GetMoneyCol(nNum1)
			szXml = szXml .. GetFormatText(_L['Total Allowance:'],136,255,128,0) .. GetFormatText(nNum1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n',136,r,g,b)
			for kk,vv in ipairs(MY_GKP('GKP_Account')) do
				if vv.szPlayer == data.szPlayer and not vv.bDelete and vv.nGold > 0 then
					nNum2 = nNum2 + vv.nGold
				end
			end
			local r, g, b = _GKP.GetMoneyCol(nNum2)
			szXml = szXml .. GetFormatText(_L['Total Payment:'],136,255,128,0) .. GetFormatText(nNum2 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n',136,r,g,b)
			local nNum3 = nNum+nNum1-nNum2
			if nNum3 < 0 then
				nNum3 = 0
			end
			local r, g, b = _GKP.GetMoneyCol(nNum3)
			szXml = szXml .. GetFormatText(_L['Money on Debt:'],136,255,128,0) .. GetFormatText(nNum3 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n',136,r,g,b)
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(szXml, 400, { x, y, w, h })
	end
end

function MY_GKP.OnItemMouseLeave()
	HideTip()
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 10, 10
	local x, y = X, Y
	local w, h = ui:Size()

	ui:Append('Text', { x = x, y = y, text = _L['Preference Setting'], font = 27 })
	ui:Append('WndButton3', { x = w - 150, y = y, w = 150, h = 38, text = _L['Open Panel'], onclick = _GKP.OpenPanel })
	y = y + 28

	x = x + 10
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Popup Record for Distributor'], checked = MY_GKP.bOn,
		oncheck = function(bChecked)
			MY_GKP.bOn = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Clause with 0 Gold as Record'], checked = MY_GKP.bDisplayEmptyRecords,
		oncheck = function(bChecked)
			MY_GKP.bDisplayEmptyRecords = bChecked
			_GKP.DrawRecord()
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		color = { 255, 128, 0 } , text = _L['Show Gold Brick'], checked = MY_GKP.bShowGoldBrick,
		oncheck = function(bChecked)
			MY_GKP.bShowGoldBrick = bChecked
			_GKP.DrawRecord()
		_GKP.DrawAccount()
		_GKP.UpdateStat()
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Remind Wipe Data When Enter Dungeon'], checked = MY_GKP.bAlertMessage,
		oncheck = function(bChecked)
			MY_GKP.bAlertMessage = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['Automatic Reception with Record From Distributor'], checked = MY_GKP.bAutoSync,
		oncheck = function(bChecked)
			MY_GKP.bAutoSync = bChecked
		end,
	})
	y = y + 28

	y = y + 5
	ui:Append('WndComboBox', { x = x, y = y, w = 150, text = _L['Edit Allowance Protocols'], menu = _GKP.GetSubsidiesMenu })
	ui:Append('WndComboBox', { x = x + 160, y = y, text = _L['Edit Auction Protocols'], menu = _GKP.GetSchemeMenu })
	y = y + 28

	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Money Record'], font = 27 })
	y = y + 28

	x = x + 10
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 150, checked = MY_GKP.bMoneySystem, text = _L['Track Money Trend in the System'],
		oncheck = function(bChecked)
			MY_GKP.bMoneySystem = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 150, text = _L['Enable Money Trend'], checked = MY_GKP.bMoneyTalk,
		oncheck = function(bChecked)
			MY_GKP.bMoneyTalk = bChecked
		end,
	})
	y = y + 28

	if MY_GKP.bDebug then
		ui:Append('WndCheckBox', {
			x = w - 130, y = 50, text = 'Enable Debug', checked = MY_GKP.bDebug2,
			oncheck = function(bChecked)
				MY_GKP.bDebug2 = bChecked
			end,
		})
		y = y + 28
	end
end
LIB.RegisterPanel('MY_GKP', _L['GKP Golden Team Record'], _L['General'], 2490, PS)

---------------------------------------------------------------------->
-- 获取补贴方案菜单
----------------------------------------------------------------------<
function _GKP.GetSubsidiesMenu()
	local menu = { szOption = _L['Edit Allowance Protocols'], rgb = { 255, 0, 0 } }
	table.insert(menu, {
		szOption = _L['Add New Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L['New Protocol  Format: Protocol\'s Name, Money'], function(txt)
				local t = LIB.SplitString(txt, ',')
				table.insert(_GKP.Config.Subsidies, { t[1], tonumber(t[2]) or '', true })
				_GKP.SaveConfig()
			end)
		end
	})
	table.insert(menu, { bDevide = true})
	for k, v in ipairs(_GKP.Config.Subsidies) do
		table.insert(menu, {
			szOption = v[1],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				_GKP.SaveConfig()
			end,
		})
	end
	return menu
end
---------------------------------------------------------------------->
-- 获取拍卖方案菜单
----------------------------------------------------------------------<
function _GKP.GetSchemeMenu()
	local menu = { szOption = _L['Edit Auction Protocols'], rgb = { 255, 0, 0 } }
	table.insert(menu,{
		szOption = _L['Edit All Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L['New Protocol Format: Money, Money, Money'], function(txt)
				local t = LIB.SplitString(txt, ',')
				_GKP.Config.Scheme = {}
				for k, v in ipairs(t) do
					table.insert(_GKP.Config.Scheme, { tonumber(v) or 0, true })
				end
				_GKP.SaveConfig()
			end)
		end
	})
	table.insert(menu, { bDevide = true })
	for k, v in ipairs(_GKP.Config.Scheme) do
		table.insert(menu,{
			szOption = v[1],
			bCheck = true,
			bChecked = v[2],
			fnAction = function()
				v[2] = not v[2]
				_GKP.SaveConfig()
			end,
		})
	end

	return menu
end

function _GKP.GetMoneyTipText(nGold)
	local szUitex = 'ui/image/common/money.UITex'
	local r, g, b = _GKP.GetMoneyCol(nGold)
	if MY_GKP.bShowGoldBrick then
		if nGold >= 0 then
			return GetFormatText(math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		else
			nGold = nGold * -1
			return GetFormatText('-' .. math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		end
	else
		return GetFormatText(nGold, 41, r, g, b) .. GetFormatImage(szUitex, 0)
	end
end

---------------------------------------------------------------------->
-- 绘制物品记录
----------------------------------------------------------------------<
function _GKP.DrawRecord(key, sort)
	local key = key or _GKP.hRecordContainer.key or 'nTime'
	local sort = sort or _GKP.hRecordContainer.sort or 'desc'
	local tab = MY_GKP('GKP_Record',key,sort)
	_GKP.hRecordContainer.key = key
	_GKP.hRecordContainer.sort = sort
	_GKP.hRecordContainer:Clear()
	for k, v in ipairs(tab) do
		if MY_GKP.bDisplayEmptyRecords or v.nMoney ~= 0 then
			local wnd = _GKP.hRecordContainer:AppendContentFromIni(PLUGIN_ROOT .. '/ui/MY_GKP_Record_Item.ini', 'WndWindow', k)
			local item = wnd:Lookup('', '')
			if k % 2 == 0 then
				item:Lookup('Image_Line'):Hide()
			end
			item:RegisterEvent(32)
			item.OnItemRButtonClick = function()
				if not LIB.IsDistributer() and not MY_GKP.bDebug then
					return LIB.Alert(_L['You are not the distrubutor.'])
				end
				_GKP.Record(v, k)
			end
			item:Lookup('Text_No'):SetText(k)
			item:Lookup('Image_NameIcon'):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup('Text_Name'):SetText(v.szPlayer)
			item:Lookup('Text_Name'):SetFontColor(LIB.GetForceColor(v.dwForceID))
			local szName = v.szName or LIB.GetItemNameByUIID(v.nUiId)
			item:Lookup('Text_ItemName'):SetText(szName)
			if v.nQuality then
				item:Lookup('Text_ItemName'):SetFontColor(GetItemFontColorByQuality(v.nQuality))
			else
				item:Lookup('Text_ItemName'):SetFontColor(255, 255, 0)
			end
			item:Lookup('Handle_Money'):AppendItemFromString(_GKP.GetMoneyTipText(v.nMoney))
			item:Lookup('Handle_Money'):FormatAllItemPos()
			item:Lookup('Text_Source'):SetText(v.szNpcName)
			if v.bSync then
				item:Lookup('Text_Source'):SetFontColor(0,255,0)
			end
			item:Lookup('Text_Time'):SetText(_GKP.GetTimeString(v.nTime))
			if v.bEdit then
				item:Lookup('Text_Time'):SetFontColor(255,255,0)
			end
			local box = item:Lookup('Box_Item')
			if v.dwTabType == 0 and v.dwIndex == 0 then
				box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
				box:SetObjectIcon(582)
			else
				if v.nBookID then
					UpdataItemInfoBoxObject(box, v.nVersion, v.dwTabType, v.dwIndex, 99999, v.nBookID)
				else
					UpdataItemInfoBoxObject(box, v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum)
				end
			end
			local hItemName = item:Lookup('Text_ItemName')
			for kk, vv in ipairs({'OnItemMouseEnter', 'OnItemMouseLeave', 'OnItemLButtonDown', 'OnItemLButtonUp'}) do
				hItemName[vv] = function()
					if box[vv] then
						this = box
						box[vv]()
					end
				end
			end
			wnd:Lookup('WndButton_Delete').OnLButtonClick = function()
				if not LIB.IsDistributer() and not MY_GKP.bDebug then
					return LIB.Alert(_L['You are not the distrubutor.'])
				end
				local tab = MY_GKP('GKP_Record', 'del', k)
				if LIB.IsDistributer() then
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'del', tab)
				end
			end
			-- tip
			item:Lookup('Text_Name').data = v
			if v.bDelete then
				wnd:SetAlpha(80)
			end
		end
	end
	_GKP.hRecordContainer:FormatAllContentPos()
end

function _GKP.Bidding()
	local team = GetClientTeam()
	if not LIB.IsDistributer() then
		return LIB.Alert(_L['You are not the distrubutor.'])
	end
	local nGold = _GKP.GetRecordSum(true)
	if nGold <= 0 then
		return LIB.Alert(_L['Auction Money <=0.'])
	end
	local t, fnAction = {}, nil
	InsertDistributeMenu(t, false)
	for k, v in ipairs(t[1]) do
		if v.szOption == g_tStrings.STR_LOOTMODE_GOLD_BID_RAID then
			fnAction = v.fnAction
			break
		end
	end
	team.SetTeamLootMode(PARTY_LOOT_MODE.BIDDING)
	local LeaderAddMoney = Wnd.OpenWindow('LeaderAddMoney')
	local fx, fy = Station.GetClientSize()
	local w2, h2 = LeaderAddMoney:GetSize()
	LeaderAddMoney:SetAbsPos((fx - w2) / 2, (fy - h2) / 2)
	LeaderAddMoney:Lookup('Edit_PriceB'):SetText(math.floor(nGold / 10000))
	LeaderAddMoney:Lookup('Edit_Price'):SetText(nGold % 10000)
	LeaderAddMoney:Lookup('Edit_Reason'):SetText(_L['Auto append'])
	LeaderAddMoney:Lookup('Btn_Ok').OnLButtonUp = function()
		fnAction()
		Station.SetActiveFrame('GoldTeam')
		Station.Lookup('Normal/GoldTeam'):Lookup('PageSet_Total'):ActivePage(1)
	end
end

function MY_GKP.GetTeamMemberMenu(fnAction, bDisable, bSelf)
	local tTeam, menu = {}, {}
	for _, v in ipairs(GetClientTeam().GetTeamMemberList()) do
		local info = GetClientTeam().GetMemberInfo(v)
		table.insert(tTeam, { szName = info.szName, dwID = v, dwForce = info.dwForceID, bIsOnLine = info.bIsOnLine})
	end
	local dwID = UI_GetClientPlayerID()
	table.sort(tTeam, function(a, b) return a.dwForce < b.dwForce end)
	for _, v in ipairs(tTeam) do
		if v.dwID ~= dwID or bSelf then
			local szIcon, nFrame = GetForceImage(v.dwForce)
			table.insert(menu, {
				szOption = v.szName,
				szLayer  = 'ICON_RIGHTMOST',
				bDisable = bDisable and not v.bIsOnLine,
				szIcon   = szIcon,
				nFrame   = nFrame,
				rgb      = { LIB.GetForceColor(v.dwForce) },
				fnAction = function()
					fnAction(v)
				end
			})
		end
	end
	return menu
end

---------------------------------------------------------------------->
-- 同步数据
----------------------------------------------------------------------<
function _GKP.OnSyncFromMenu()
	local me = GetClientPlayer()
	if me.IsInParty() then
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			LIB.Confirm(_L('Wheater replace the current record with the synchronization [%s]\'s record?\n Please notice, this means you are going to lose the information of current record.', v.szName), function()
				LIB.Alert(_L('Asking for the sychoronization information...\n If no response in longtime, it may because [%s] is not using MY_GKP plugin or not responding.', v.szName))
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_Sync', v.szName) -- 请求同步信息
			end)
		end, true)
		table.insert(menu, 1, { bDevide = true })
		table.insert(menu, 1, { szOption = _L['Please select which will be the one you are going to ask record for.'], bDisable = true })
		return menu
	else
		LIB.Alert(_L['You are not in the team.'])
	end
end

function _GKP.OnSyncToMenu()
	local me = GetClientPlayer()
	if not me.IsInParty() then
		LIB.Alert(_L['You are not in the team.'])
	elseif not LIB.IsDistributer() and not MY_GKP.bDebug then
		LIB.Alert(_L['You are not the distrubutor.'])
	else
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			LIB.Confirm(_L('Wheater synchronize your record to [%s]?\n Please notice, this means the opposite sites are going to lose their information of current record.', v.szName), function()
				_GKP.SyncSend(v.dwID)
			end)
		end, true)
		table.insert(menu, { bDevide = true })
		table.insert(menu, {
			szOption = _L['Full raid.'],
			fnAction = function()
				LIB.Confirm(_L['Wheater synchronize your record to full raid?\n Please notice, this means the opposite sites are going to lose their information of current record.'], function()
					_GKP.SyncSend(0)
				end)
			end,
		})
		table.insert(menu, 1, { bDevide = true })
		table.insert(menu, 1, { szOption = _L['Please select which will be the one you are going to send record to.'], bDisable = true })
		return menu
	end
end

function _GKP.SyncSend(dwID)
	local tab = {
		GKP_Record  = MY_GKP('GKP_Record'),
		GKP_Account = MY_GKP('GKP_Account'),
	}
	local str = LIB.JsonEncode(tab)
	local nMax = 500
	local nTotle = math.ceil(#str / nMax)
	-- 密聊频道限制了字数 发起来太慢了
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_Sync_Start', dwID, nTotle)
	for i = 1, nTotle do
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_Sync_Content', dwID, string.sub(str ,(i-1) * nMax + 1, i * nMax))
	end
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_Sync_Stop', dwID)
end

local SYNC_LENG = 0

LIB.RegisterEvent('ON_BG_CHANNEL_MSG.LR_GKP', function()
	local szMsgID, nChannel, dwID, szName, data, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
	if szMsgID ~= 'LR_GKP' or bSelf then
		return
	end
	if (data[1] == 'SYNC' or data[1] == 'DEL') and MY_GKP.bAutoSync then
		local rawData = data[2]
		local tab = {
			bSync = true,
			bEdit = true,
			bDelete = data[1] == 'DEL',
			szPlayer = rawData.szPurchaserName,
			dwIndex = rawData.dwIndex,
			dwTabType = rawData.dwTabType,
			nQuality = rawData.nQuality,
			nVersion = rawData.nVersion or 0,
			nGenre = rawData.nGenre,
			nTime = rawData.nCreateTime,
			nMoney = rawData.nGold,
			key = rawData.hash,
			dwForceID = rawData.dwPurchaserForceID,
			szName = rawData.szName,
			dwDoodadID = rawData.dwDoodadID or 0,
			nUiId = rawData.nUiId or 0,
			szNpcName = rawData.szSourceName,
			nBookID = rawData.nGenre == ITEM_GENRE.BOOK
				and rawData.nBookID and rawData.nBookID ~= 0
				and rawData.nBookID or nil,
			nStackNum = rawData.nStackNum,
		}
		local szKey
		for k, v in ipairs(MY_GKP('GKP_Record')) do
			if v.key == tab.key then
				szKey = k
				break
			end
		end
		if szKey then
			MY_GKP('GKP_Record', szKey, tab)
		else
			MY_GKP('GKP_Record', tab)
		end
		--[[#DEBUG BEGIN]]
		LIB.Debug('#MY_GKP# Sync From LR Success', 'MY_GKP', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end)

LIB.RegisterBgMsg('MY_GKP', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if team then
		if not bIsSelf then
			if data[1] == 'GKP_Sync' and data[2] == me.szName then
				_GKP.SyncSend(dwID)
			end

			if data[2] == me.dwID or data[2] == 0 then
				if data[1] == 'GKP_Sync_Start' then
					if data[2] ~= 0 then
						LIB.Alert(_L['Start Sychoronizing...'])
					end
					_GKP.bSync, SYNC_LENG = true, data[3]
				end

				if data[1] == 'GKP_Sync_Content' and _GKP.bSync then
					table.insert(_GKP.tSyncQueue, data[3])
					if SYNC_LENG ~= 0 then
						local percent = #_GKP.tSyncQueue / SYNC_LENG
						LIB.Topmsg({_L('Sychoronizing data please wait %d%% loaded.', percent * 100)})
					end
				end
				if data[1] == 'GKP_Sync_Stop' then
					local str = table.concat(_GKP.tSyncQueue)
					_GKP.tSyncQueue = {}
					_GKP.bSync, SYNC_LENG = false, 0
					LIB.Alert(_L['Sychoronization Complete'])
					LIB.Topmsg({_L['Sychoronization Complete']})
					local tData, err = LIB.JsonDecode(str)
					if err then
						--[[#DEBUG BEGIN]]
						LIB.Debug(err, 'MY_GKP', DEBUG_LEVEL.ERROR)
						--[[#DEBUG END]]
						return _GKP.Sysmsg(_L['Abnormal with Data Sharing, Please contact and make feed back with the writer.'])
					end
					LIB.Confirm(_L('Data Sharing Finished, you have one last chance to confirm wheather cover the current data with [%s]\'s data or not? \n data of team bidding: %s\n transation data: %s', szName, #tData.GKP_Record, #tData.GKP_Account), function()
						_GKP.GKP_Record  = tData.GKP_Record
						_GKP.GKP_Account = tData.GKP_Account
						_GKP.DrawRecord()
						_GKP.DrawAccount()
						_GKP.SaveData()
					end)
				end
			end
			if (data[1] == 'del' or data[1] == 'edit' or data[1] == 'add') and MY_GKP.bAutoSync then
				local tab = data[2]
				tab.bSync = true
				if data[1] == 'add' then
					MY_GKP('GKP_Record', tab)
				else
					for k, v in ipairs(MY_GKP('GKP_Record')) do
						if v.key == tab.key then
							MY_GKP('GKP_Record', k, tab)
							break
						end
					end
				end
				--[[#DEBUG BEGIN]]
				LIB.Debug('#MY_GKP# Sync Success', 'MY_GKP', DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		end
		if data[1] == 'GKP_INFO' then
			if data[2] == 'Start' then
				local szFrameName = data[3] == 'Information on Debt' and 'GKP_Debt' or 'GKP_info'
				if data[3] == 'Information on Debt' and szName ~= me.szName then -- 欠债记录只自己看
					return
				end
				local ui = UI.CreateFrame(szFrameName, { w = 800, h = 400, text = _L['GKP Golden Team Record'], close = true, anchor = 'CENTER' })
				local x, y = 20, 50
				ui:Append('Text', { x = x, y = y, w = 760, h = 30, text = _L[data[3]], halign = 1, font = 236, color = { 255, 255, 0 } })
				ui:Append('WndButton3', { name = 'ScreenShot', x = x + 590, y = y, text = _L['Print Ticket'] }):Toggle(false):Click(function()
					local scale         = Station.GetUIScale()
					local left, top     = ui:Pos()
					local width, height = ui:Size()
					local right, bottom = left + width, top + height
					local btn           = this
					local path          = GetRootPath() .. string.format('\\ScreenShot\\GKP_Ticket_%s.png', FormatTime('%Y-%m-%d_%H.%M.%S', GetCurrentTime()))
					btn:Hide()
					LIB.DelayCall(function()
						ScreenShot(path, 100, scale * left, scale * top, scale * right, scale * bottom)
						LIB.DelayCall(function()
							LIB.Alert(_L('Shot screen succeed, file saved as %s .', path))
							btn:Show()
						end)
					end, 50)
				end)
				ui:Append('Text', { w = 120, h = 30, x = x + 40, y = y + 35, text = _L('Operator:%s', szName), font = 41 })
				ui:Append('Text', { w = 720, h = 30, x = x, halign = 2, y = y + 35, text = _L('Print Time:%s', _GKP.GetTimeString(GetCurrentTime())), font = 41 })
			end
			if data[2] == 'Info' then
				if data[3] == me.szName and tonumber(data[4]) and tonumber(data[4]) <= -100 then
					LIB.OutputWhisper(data[3] .. g_tStrings.STR_COLON .. data[4] .. g_tStrings.STR_GOLD, 'MY_GKP')
				end
				local frm = Station.Lookup('Normal/GKP_info')
				if frm and frm.done then
					frm = Station.Lookup('Normal/GKP_Debt')
				end
				if not frm and Station.Lookup('Normal/GKP_Debt') then
					frm = Station.Lookup('Normal/GKP_Debt')
				end
				if frm then
					if not frm.n then frm.n = 0 end
					local n = frm.n
					local ui = UI(frm)
					local x, y = 20, 50
					if n % 2 == 0 then
						ui:Append('Image', { w = 760, h = 30, x = x, y = y + 70 + 30 * n, image = 'ui/Image/button/ShopButton.UITex', imageframe = 75 })
					end
					local dwForceID, tBox = -1, {}
					if me.IsInParty() then
						for k, v in ipairs(team.GetTeamMemberList()) do
							if team.GetClientTeamMemberName(v) == data[3] then
								dwForceID = team.GetMemberInfo(v).dwForceID
							end
						end
					end
					for k, v in ipairs(MY_GKP('GKP_Record')) do -- 依赖于本地记录 反正也不可能差异到哪去
						if v.szPlayer == data[3] then
							if dwForceID == -1 then
								dwForceID = v.dwForceID
							end
							table.insert(tBox, v)
						end
					end
					if dwForceID ~= -1 then
						ui:Append('Image', { w = 28, h = 28, x = x + 30, y = y + 71 + 30 * n }):Image(GetForceImage(dwForceID))
					end
					ui:Append('Text', { w = 140, h = 30, x = x + 60, y = y + 70 + 30 * n, text = data[3], color = { LIB.GetForceColor(dwForceID) } })
					local handle = ui:Append('Handle', { w = 130, h = 20, x = x + 200, y = y + 70 + 30 * n, handlestyle = 3 })[1]
					handle:AppendItemFromString(_GKP.GetMoneyTipText(tonumber(data[4])))
					handle:FormatAllItemPos()
					for k, v in ipairs(tBox) do
						if k > 12 then
							ui:Append('Text', { x = x + 290 + k * 32 + 5, y = y + 71 + 30 * n, w = 28, h = 28, text = '.....', font = 23 })
							break
						end
						local hBox = ui:Append('Box', { x = x + 290 + k * 32, y = y + 71 + 30 * n, w = 28, h = 28, alpha = v.bDelete and 60 })
						if v.nUiId ~= 0 then
							hBox:ItemInfo(v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum or v.nBookID)
						else
							hBox:Icon(582):Hover(function(bHover)
								if bHover then
									local x, y = this:GetAbsPos()
									local w, h = this:GetSize()
									OutputTip(GetFormatText(v.szName .. g_tStrings.STR_TALK_HEAD_SAY1, 136) .. _GKP.GetMoneyTipText(v.nMoney), 250, { x, y, w, h })
								else
									HideTip()
								end
							end)
						end
					end
					if frm.n > 5 then
						ui:Size(800, 30 * frm.n + 250):Anchor('CENTER')
					end
					frm.n = frm.n + 1
				end
			end
			if data[2] == 'End' then
				local szFrameName = data[4] and 'GKP_info' or 'GKP_Debt'
				local frm = Station.Lookup('Normal/' .. szFrameName)
				if frm then
					if data[4] then
						local ui = UI(frm)
						local x, y = 20, 50
						local n = frm.n or 0
						local handle = ui:Append('Handle', { w = 230, h = 20, x = x + 30, y = y + 70 + 30 * n + 5, handlestyle = 3 })[1]
						handle:AppendItemFromString(GetFormatText(_L['Total Auction:'], 41) .. _GKP.GetMoneyTipText(tonumber(data[4])))
						handle:FormatAllItemPos()
						if LIB.IsDistributer() then
							ui:Append('WndButton4', {
								w = 91, h = 26, x = x + 620, y = y + 70 + 30 * n + 5, text = _L['salary'],
								onclick = function()
									LIB.Confirm(_L['Confirm?'], _GKP.Bidding)
								end,
							})
						end
						if data[5] and tonumber(data[5]) then
							local nTime = tonumber(data[5])
							ui:Append('Text', { w = 725, h = 30, x = x + 0, y = y + 70 + 30 * n + 5, text = _L('Spend time approx %d:%d', nTime / 3600, nTime % 3600 / 60), halign = 1 })
						end
						UI(frm):Children('#ScreenShot'):Toggle(true)
						if n >= 4 then
							local nMoney = tonumber(data[4]) or 0
							local t = {
								{ 50000,   1 }, -- 黑出翔
								{ 100000,  0 }, -- 背锅
								{ 250000,  2 }, -- 脸帅
								{ 500000,  6 }, -- 自称小红手
								{ 5000000, 3 }, -- 特别红
								{ 5000000, 5 }, -- 玄晶专用r
							}
							local nFrame = 4
							for k, v in ipairs(t) do
								if v[1] >= nMoney then
									nFrame = v[2]
									break
								end
							end
							local img = ui:Append('Image', {
								x = x + 590, y = y + n * 30 - 30, w = 150, h = 150, alpha = 180,
								image = PACKET_INFO.ROOT .. 'MY_GKP/img/GKPSeal.uitex', imageframe = nFrame,
								hover = function(bHover)
									if bHover then
										this:SetAlpha(30)
									else
										this:SetAlpha(180)
									end
								end,
							})[1]
							-- JH.Animate(img, 200):Scale(4)
						end
						frm.done = true
					elseif szFrameName == 'GKP_Debt' and not frm:IsVisible() then
						Wnd.CloseWindow(frm)
					end
				end
				_GKP.SetButton(true)
			end
		end
	end
end)

function _GKP.SetButton(bEnable)
	local frame = Station.Lookup('Normal/MY_GKP')
	if not frame then
		return
	end
	frame:Lookup('Debt'):Enable(bEnable)
	frame:Lookup('GOLD_TEAM_BID_LIST'):Enable(bEnable)
end

---------------------------------------------------------------------->
-- 恢复记录按钮
----------------------------------------------------------------------<
function _GKP.RecoveryMenu()
	local me = GetClientPlayer()
	local menu = {}
	local aFiles = {}
	local szPath = LIB.FormatPath({'userdata/gkp/', PATH_TYPE.ROLE}):sub(3):gsub('/', '\\'):sub(1, -2)
	for i, filename in ipairs(CPath.GetFileList(szPath)) do
		local year, month, day, hour, minute, second, index = filename:match('^(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+).-%.gkp.jx3dat')
		if not year then
			year, month, day, hour, minute, second = filename:match('^(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+).-%.gkp.jx3dat')
		end
		if not year then
			year, month, day = filename:match('^(%d+)%-(%d+)%-(%d+)%.gkp.jx3dat')
		end
		if year then
			if year then
				year = tonumber(year)
			end
			if month then
				month = tonumber(month)
			end
			if day then
				day = tonumber(day)
			end
			if hour then
				hour = tonumber(hour)
			end
			if minute then
				minute = tonumber(minute)
			end
			if second then
				second = tonumber(second)
			end
			if index then
				index = tonumber(index)
			end
			table.insert(aFiles, {year, month, day, hour, minute, second, index, filename = filename:sub(1, -12)})
		end
	end
	local function sortFile(a, b)
		local n = math.max(#a, #b)
		for i = 1, n do
			if not a[i] then
				return true
			elseif not b[i] then
				return false
			elseif a[i] ~= b[i] then
				return a[i] > b[i]
			end
		end
		return true
	end
	table.sort(aFiles, sortFile)

	for i = 1, math.min(#aFiles, 21) do
		local szFile = aFiles[i].filename
		table.insert(menu, {
			szOption = szFile .. '.gkp',
			fnAction = function()
				LIB.Confirm(_L['Are you sure to cover the current information with the last record data?'], function()
					_GKP.LoadData('gkp/' .. szFile)
					LIB.Alert(_L['Reocrd Recovered.'])
				end)
			end,
		})
	end

	if #menu > 0 then
		table.insert(menu, CONSTANT.MENU_DIVIDER)
	end
	table.insert(menu, {
		szOption = _L['Manually load from file.'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			local file = GetOpenFileName(
				_L['Please select gkp file.'],
				'GKP File(*.gkp,*.gkp.jx3dat)\0*.gkp;*.gkp.jx3dat\0All Files(*.*)\0*.*\0\0',
				LIB.FormatPath({'userdata/gkp', PATH_TYPE.ROLE})
			)
			if not IsEmpty(file) then
				LIB.Confirm(_L['Are you sure to cover the current information with the last record data?'], function()
					_GKP.LoadData(file, true)
					LIB.Alert(_L['Reocrd Recovered.'])
				end)
			end
		end
	})
	return menu
end
---------------------------------------------------------------------->
-- 清空数据
----------------------------------------------------------------------<
function _GKP.ClearData(bConfirm)
	local fnAction = function()
		if #_GKP.GKP_Record ~= 0 or #_GKP.GKP_Account ~= 0 then
			_GKP.SaveData(true)
		end
		_GKP.GKP_Map = ''
		_GKP.GKP_Time = GetCurrentTime()
		_GKP.GKP_Record = {}
		_GKP.GKP_Account = {}
		_GKP.DrawRecord()
		_GKP.DrawAccount()
		_GKP.UpdateStat()
		_GKP.UpdateTitle()
		FireUIEvent('MY_GKP_LOOT_BOSS')
		LIB.Alert(_L['Records are wiped'])
	end
	if bConfirm then
		fnAction()
	else
		LIB.Confirm(_L['Are you sure to wipe all of the records?'], fnAction)
	end
end
---------------------------------------------------------------------->
-- 欠费情况
----------------------------------------------------------------------<
function _GKP.OweList()
	local me = GetClientPlayer()
	if not me.IsInParty() and not MY_GKP.bDebug then return LIB.Alert(_L['You are not in the team.']) end
	local tMember = {}
	if IsEmpty(MY_GKP('GKP_Record')) then
		return LIB.Alert(_L['No Record'])
	end
	if not LIB.IsDistributer() and not MY_GKP.bDebug then
		return LIB.Alert(_L['You are not the distrubutor.'])
	end
	_GKP.SetButton(false)
	for k,v in ipairs(MY_GKP('GKP_Record')) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				if not tMember[v.szPlayer] then
					tMember[v.szPlayer] = 0
				end
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
		end
	end
	local _Account = {}
	for k,v in ipairs(MY_GKP('GKP_Account')) do
		if not v.bDelete and v.szPlayer and v.szPlayer ~= 'System' then
			if tMember[v.szPlayer] then
				tMember[v.szPlayer] = tMember[v.szPlayer] - v.nGold
			else
				if not _Account[v.szPlayer] then
					_Account[v.szPlayer] = 0
				end
				_Account[v.szPlayer] = _Account[v.szPlayer] + v.nGold
			end
		end
	end
	-- 欠账
	local tMember2 = {}
	for k,v in pairs(tMember) do
		if v ~= 0 then
			table.insert(tMember2, { szName = k, nGold = v * -1 })
		end
	end
	-- 正账
	for k,v in pairs(_Account) do
		if v > 0 then
			table.insert(tMember2, { szName = k, nGold = v })
		end
	end

	table.sort(tMember2, function(a,b) return a.nGold < b.nGold end)
	LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L['Information on Debt'])
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'Start', 'Information on Debt')
	for k,v in pairs(tMember2) do
		if v.nGold < 0 then
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, { _GKP.GetFormatLink(v.szName, true), _GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'Info', v.szName, v.nGold, '-')
		else
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, { _GKP.GetFormatLink(v.szName, true), _GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. '+' .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'Info', v.szName, v.nGold, '+')
		end
	end
	local nGold, nGold2 = 0, 0
	for _,v in ipairs(MY_GKP('GKP_Account')) do
		if not v.bDelete then
			if v.szPlayer and v.szPlayer ~= 'System' then -- 必须要有交易对象
				if tonumber(v.nGold) > 0 then
					nGold = nGold + v.nGold
				else
					nGold2 = nGold2 + v.nGold
				end
			end
		end
	end
	if nGold ~= 0 then
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Received: %d Gold.', nGold))
	end
	if nGold2 ~= 0 then
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Spending: %d Gold.', nGold2 * -1))
	end
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'End', _L('Received: %d Gold.', nGold))
end
---------------------------------------------------------------------->
-- 获取工资总额
----------------------------------------------------------------------<
function _GKP.GetRecordSum(bAccurate)
	local a, b = 0, 0
	for k, v in ipairs(MY_GKP('GKP_Record')) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				a = a + v.nMoney
			else
				b = b + v.nMoney
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a, b
	end
end

function _GKP.GetAccountSum(bAccurate)
	local a, b = 0, 0
	for k, v in ipairs(MY_GKP('GKP_Account')) do
		if not v.bDelete then
			if tonumber(v.nGold) > 0 then
				a = a + v.nGold
			else
				b = b + v.nGold
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a, b
	end
end

---------------------------------------------------------------------->
-- 消费情况按钮
----------------------------------------------------------------------<
function _GKP.SpendingList()
	local me = GetClientPlayer()
	if not me.IsInParty() and not MY_GKP.bDebug then return LIB.Alert(_L['You are not in the team.']) end
	local tMember = {}
	if IsEmpty(MY_GKP('GKP_Record')) then
		return LIB.Alert(_L['No Record'])
	end
	if not LIB.IsDistributer() and not MY_GKP.bDebug then
		return LIB.Alert(_L['You are not the distrubutor.'])
	end
	_GKP.SetButton(false)
	local tTime = {}
	for k, v in ipairs(MY_GKP('GKP_Record')) do
		if not v.bDelete then
			if not tMember[v.szPlayer] then
				tMember[v.szPlayer] = 0
			end
			if tonumber(v.nMoney) > 0 then
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
			table.insert(tTime, { nTime = v.nTime })
		end
	end
	table.sort(tTime, function(a, b)
		return a.nTime < b.nTime
	end)
	local nTime = tTime[#tTime].nTime - tTime[1].nTime -- 所花费的时间

	LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L['--- Consumption ---'])
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'Start', '--- Consumption ---')
	local sort = {}
	for k,v in pairs(tMember) do
		table.insert(sort,{ szName = k, nGold = v })
	end

	table.sort(sort,function(a,b) return a.nGold < b.nGold end)
	for k, v in ipairs(sort) do
		if v.nGold > 0 then
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, { _GKP.GetFormatLink(v.szName, true), _GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
		end
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'Info', v.szName, v.nGold)
	end
	LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Total Auction: %d Gold.', _GKP.GetRecordSum()))
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'GKP_INFO', 'End', _L('Total Auction: %d Gold.', _GKP.GetRecordSum()), _GKP.GetRecordSum(), nTime)
end
---------------------------------------------------------------------->
-- 结算工资按钮
----------------------------------------------------------------------<
function _GKP.Calculation()
	local me = GetClientPlayer()
	if not me.IsInParty() and not MY_GKP.bDebug then return LIB.Alert(_L['You are not in the team.']) end
	local team = GetClientTeam()
	if IsEmpty(MY_GKP('GKP_Record')) then
		return LIB.Alert(_L['No Record'])
	end
	if not LIB.IsDistributer() and not MY_GKP.bDebug then
		return LIB.Alert(_L['You are not the distrubutor.'])
	end
	GetUserInput(_L['Total Amount of People with Output Settle Account'],function(num)
		if not tonumber(num) then return end
		local a,b = _GKP.GetRecordSum()
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L['Salary Settle Account'])
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Salary Statistic: income  %d Gold.',a))
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Salary Allowance: %d Gold.',b))
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Reall Salary: %d Gold.',a+b,a,b))
		if a+b >= 0 then
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Amount of People with Settle Account: %d',num))
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('Actual per person: %d Gold.',math.floor((a+b)/num)))
		else
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L['The Account is Negative, no money is coming out!'])
		end
	end, nil, nil, nil, team.GetTeamSize())
end

---------------------------------------------------------------------->
-- 记账页面
----------------------------------------------------------------------<
function _GKP.Record(tab, item, bEnter)
	-- CreateFrame
	local szKey
	if IsTable(tab) and tab.key then
		szKey = tab.key
	elseif IsUserdata(item) then
		szKey = tab.nUiId .. _GKP.Random()
	else
		szKey = 0 .. _GKP.Random()
	end
	local ui = UI.CreateFrame('MY_GKP_Record#' .. GetStringCRC(szKey), { h = 380, w = 400, text = _L['GKP Golden Team Record'], close = true, focus = true })
	local x, y = 10, 55
	local nAuto = 0
	local dwForceID
	local hBox = ui:Append('Box', { name = 'Box', x = x + 175, y = y + 40, h = 48, w = 48 })
	local hCheckBox = ui:Append('WndCheckBox', { name = 'WndCheckBox', x = x + 50, y = y + 260, font = 65, text = _L['Equiptment Boss'] })
	local hButton = ui:Append('WndButton3', { name = 'Success', x = x + 175, y = y + 260, text = g_tStrings.STR_HOTKEY_SURE })
	ui:Remove(function()
		if ui[1].userdata then
			ui:Children('#Money'):Text(0)
			hButton:Click()
		end
	end)

	ui:Append('Text', { x = x + 65, y = y + 10, font = 65, text = _L['Keep Account to:'] })
	ui:Append('Text', { x = x + 65, y = y + 90, font = 65, text = _L['Name of the Item:'] })
	ui:Append('Text', { x = x + 65, y = y + 120, font = 65, text = _L['Route of Acquiring:'] })
	ui:Append('Text', { x = x + 65, y = y + 150, font = 65, text = _L['Auction Price:'] })

	local hPlayer = ui:Append('WndComboBox', {
		name = 'PlayerList',
		x = x + 140, y = y + 13, text = g_tStrings.PLAYER_NOT_EMPTY,
		menu = function()
			return MY_GKP.GetTeamMemberMenu(function(v)
				local hTeamList = ui:Children('#PlayerList')
				hTeamList:Text(v.szName):Color(LIB.GetForceColor(v.dwForce))
				dwForceID = v.dwForce
			end, false, true)
		end,
	})
	local hSource = ui:Append('WndEditBox', { name = 'Source', x = x + 140, y = y + 121, w = 185, h = 25 })
    local hName = ui:Append('WndAutocomplete', {
		name = 'Name', x = x + 140, y = y + 91, w = 185, h = 25,
		autocomplete = {
			{
				'option', 'beforeSearch', function(raw, option, text)
					option.source = {}
					for k, v in ipairs(_GKP.Config.Subsidies) do
						if v[3] then
							table.insert(option.source, v[1])
						end
					end
				end,
			},
			{
				'option', 'afterComplete', function(raw, option, text)
					if text then
						ui:Children('#Money'):Focus()
					end
				end,
			},
		},
		onclick = function()
			if IsPopupMenuOpened() then
				UI(this):Autocomplete('close')
			else
				UI(this):Autocomplete('search', '')
			end
		end,
	})
	local hMoney = ui:Append('WndAutocomplete', {
		name = 'Money', x = x + 140, y = y + 151, w = 185, h = 25, limit = 8, edittype = 1,
		autocomplete = {
			{
				'option', 'beforeSearch', function(raw, option, text)
					option.source = {}
					if tonumber(text) then
						if tonumber(text) < 100 and tonumber(text) > -100 and tonumber(text) ~= 0 then
							for k, v in ipairs({2, 3, 4}) do
								local szMoney = string.format('%0.'.. v ..'f', text):gsub('%.', '')
								table.insert(option.source, {
									text     = szMoney,
									keyword  = text,
									display  = _GKP.GetMoneyTipText(tonumber(szMoney)),
									richtext = true,
								})
							end
							table.insert(option.source, { divide = true, keyword = text })
						end
						table.insert(option.source, {
							text     = text,
							keyword  = text,
							display  = _GKP.GetMoneyTipText(tonumber(text)),
							richtext = true,
						})
					end
				end,
			},
		},
		onchange = function(szText)
			local ui = UI(this)
			if tonumber(szText) or szText == '' or szText == '-' then
				this.szText = szText
				ui:Color(_GKP.GetMoneyCol(szText))
			else
				LIB.Sysmsg({_L['Please enter numbers']})
				ui:Text(this.szText or '')
			end
		end,
	})
	-- set frame
	if tab and type(item) == 'userdata' then
		hPlayer:Text(tab.szPlayer):Color(LIB.GetForceColor(tab.dwForceID))
		hName:Text(tab.szName):Enable(false)
		hSource:Text(tab.szNpcName):Enable(false)
		ui[1].userdata = true
	else
		hPlayer:Text(g_tStrings.PLAYER_NOT_EMPTY):Color(255, 255, 255)
		hSource:Text(_L['Add Manually']):Enable(false)
	end
	if tab and type(item) == 'number' then -- 编辑
		hPlayer:Text(tab.szPlayer):Color(LIB.GetForceColor(tab.dwForceID))
		dwForceID = tab.dwForceID
		hName:Text(tab.szName or LIB.GetItemNameByUIID(tab.nUiId))
		hMoney:Text(tab.nMoney)
		hSource:Text(tab.szNpcName)
	end

	if tab and tab.nVersion and tab.nUiId and tab.dwTabType and tab.dwIndex and tab.nUiId ~= 0 then
		hBox:ItemInfo(tab.nVersion, tab.dwTabType, tab.dwIndex, tab.nBookID or tab.nStackNum)
	else
		hBox:ItemInfo()
		hBox:Icon(582)
	end
	if nAuto == 0 and type(item) ~= 'number' and tab then -- edit/add killfocus
		hMoney:Focus()
	elseif nAuto > 0 and tab then
		hMoney:Text(nAuto) -- OnEditChanged kill
		ui:Focus()
	elseif not tab then
		hName:Focus()
	end
	hButton:Click(function()
		if IsCtrlKeyDown() and IsShiftKeyDown() and IsAltKeyDown() then
			return Wnd.CloseWindow(ui[1])
		end
		local tab = tab or {
			nUiId      = 0,
			dwTabType  = 0,
			dwDoodadID = 0,
			nQuality   = 1,
			nVersion   = 0,
			dwIndex    = 0,
			nTime      = GetCurrentTime(),
			dwForceID  = dwForceID,
			szName     = hName:Text(),
		}
		local nMoney = tonumber(hMoney:Text()) or 0
		local szPlayer = hPlayer:Text()
		if hName:Text() == '' then
			return LIB.Alert(_L['Please entry the name of the item'])
		end
		if szPlayer == g_tStrings.PLAYER_NOT_EMPTY then
			return LIB.Alert(_L['Select a member who is in charge of account and put money in his account.'])
		end
		tab.szNpcName = hSource:Text()
		tab.nMoney    = nMoney
		tab.szPlayer  = szPlayer
		tab.key       = szKey
		tab.dwForceID = dwForceID or tab.dwForceID or 0
		if tab and type(item) == 'userdata' then
			if LIB.IsDistributer() then
				LIB.Talk(PLAYER_TALK_CHANNEL.RAID, {
					_GKP.GetFormatLink(tab),
					_GKP.GetFormatLink(' '.. nMoney .. g_tStrings.STR_GOLD),
					_GKP.GetFormatLink(_L[' Distribute to ']),
					_GKP.GetFormatLink(tab.szPlayer, true)
				})
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'add', tab)
			end
		elseif tab and type(item) == 'number' then
			tab.szName = hName:Text()
			tab.dwForceID = dwForceID or tab.dwForceID or 0
			tab.bEdit = true
			if LIB.IsDistributer() then
				LIB.Talk(PLAYER_TALK_CHANNEL.RAID, {
					_GKP.GetFormatLink(tab.szPlayer, true),
					_GKP.GetFormatLink(' '.. tab.szName),
					_GKP.GetFormatLink(' '.. nMoney ..g_tStrings.STR_GOLD),
					_GKP.GetFormatLink(_L['Make changes to the record.']),
				})
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'edit', tab)
			end
		else
			if LIB.IsDistributer() then
				LIB.Talk(PLAYER_TALK_CHANNEL.RAID, {
					_GKP.GetFormatLink(tab.szName),
					_GKP.GetFormatLink(' '.. nMoney ..g_tStrings.STR_GOLD),
					_GKP.GetFormatLink(_L['Manually make record to']),
					_GKP.GetFormatLink(tab.szPlayer, true)
				})
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', 'add', tab)
			end
		end
		if ui:Children('#WndCheckBox'):Check() then
			FireUIEvent('MY_GKP_LOOT_BOSS', tab.szPlayer)
		end
		if tab and type(item) == 'number' then
			MY_GKP('GKP_Record', item, tab)
		else
			MY_GKP('GKP_Record', tab)
		end
		Wnd.CloseWindow(ui[1])
	end)
	if bEnter then
		hButton:Click()
	end
end


---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
_GKP.TradingTarget = {}

function _GKP.MoneyUpdate(nGold, nSilver, nCopper)
	if nGold > -20 and nGold < 20 then
		return
	end
	if not _GKP.TradingTarget then
		return
	end
	if not _GKP.TradingTarget.szName and not MY_GKP.bMoneySystem then
		return
	end
	MY_GKP('GKP_Account', {
		nGold     = nGold, -- API给的有问题 …… 只算金
		szPlayer  = _GKP.TradingTarget.szName or 'System',
		dwForceID = _GKP.TradingTarget.dwForceID,
		nTime     = GetCurrentTime(),
		dwMapID   = GetClientPlayer().GetMapID()
	})
	if _GKP.TradingTarget.szName and MY_GKP.bMoneyTalk then
		if nGold > 0 then
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, {
				_GKP.GetFormatLink(_L['Received']),
				_GKP.GetFormatLink(_GKP.TradingTarget.szName, true),
				_GKP.GetFormatLink(_L['The'] .. nGold ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		else
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, {
				_GKP.GetFormatLink(_L['Pay to']),
				_GKP.GetFormatLink(_GKP.TradingTarget.szName, true),
				_GKP.GetFormatLink(' ' .. nGold * -1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		end
	end
end

function _GKP.DrawAccount(key,sort)
	local key = key or _GKP.hAccountContainer.key or 'szPlayer'
	local sort = sort or _GKP.hAccountContainer.sort or 'desc'
	local tab = MY_GKP('GKP_Account',key,sort)
	_GKP.hAccountContainer.key = key
	_GKP.hAccountContainer.sort = sort
	_GKP.hAccountContainer:Clear()
	local tMoney = GetClientPlayer().GetMoney()
	for k, v in ipairs(tab) do
		local c = _GKP.hAccountContainer:AppendContentFromIni(PLUGIN_ROOT .. '/ui/MY_GKP_Account_Item.ini', 'WndWindow', k)
		local item = c:Lookup('', '')
		if k % 2 == 0 then
			item:Lookup('Image_Line'):Hide()
		end
		c:Lookup('', 'Handle_Money'):AppendItemFromString(_GKP.GetMoneyTipText(v.nGold))
		c:Lookup('', 'Handle_Money'):FormatAllItemPos()
		item:Lookup('Text_No'):SetText(k)
		if v.szPlayer and v.szPlayer ~= 'System' then
			item:Lookup('Image_NameIcon'):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup('Text_Name'):SetText(v.szPlayer)
			item:Lookup('Text_Change'):SetText(_L['Player\'s transation'])
			item:Lookup('Text_Name'):SetFontColor(LIB.GetForceColor(v.dwForceID))
		else
			item:Lookup('Image_NameIcon'):FromUITex('ui/Image/uicommon/commonpanel4.UITex',3)
			item:Lookup('Text_Name'):SetText(_L['System'])
			item:Lookup('Text_Change'):SetText(_L['Reward & other ways'])
		end
		item:Lookup('Text_Map'):SetText(Table_GetMapName(v.dwMapID))
		item:Lookup('Text_Time'):SetText(_GKP.GetTimeString(v.nTime))
		c:Lookup('WndButton_Delete').OnLButtonClick = function()
			MY_GKP('GKP_Account', 'del', k)
		end
		-- tip
		item:Lookup('Text_Name').data = v
		if v.bDelete then
			c:SetAlpha(80)
		end
	end
	_GKP.hAccountContainer:FormatAllContentPos()
end

LIB.RegisterEvent('TRADING_OPEN_NOTIFY',function() -- 交易开始
	_GKP.TradingTarget = GetPlayer(arg0)
end)
LIB.RegisterEvent('TRADING_CLOSE',function() -- 交易结束
	_GKP.TradingTarget = {}
end)
LIB.RegisterEvent('MONEY_UPDATE',function() --金钱变动
	_GKP.MoneyUpdate(arg0, arg1, arg2)
end)

LIB.RegisterHotKey('MY_GKP', _L['Open/Close Golden Team Record'], _GKP.TogglePanel)
LIB.RegisterAddonMenu({ szOption = _L['Golden Team Record'], fnAction = _GKP.OpenPanel })

LIB.RegisterEvent('LOADING_END',function()
	if not IsEmpty(MY_GKP('GKP_Record')) or not IsEmpty(MY_GKP('GKP_Account')) then
		if LIB.IsInDungeon() and MY_GKP.bAlertMessage then
			LIB.Confirm(_L['Do you want to wipe the previous data when you enter the dungeon\'s map?'],function() _GKP.ClearData(true) end)
		end
	else
		MY_GKP('GKP_Time', GetCurrentTime())
	end
end)
MY_GKP.Record          = _GKP.Record
MY_GKP.GetMoneyCol     = _GKP.GetMoneyCol
MY_GKP.OpenPanel       = _GKP.OpenPanel
MY_GKP.ClosePanel      = _GKP.ClosePanel
MY_GKP.TogglePanel     = _GKP.TogglePanel
MY_GKP.GetFormatLink   = _GKP.GetFormatLink
function MY_GKP.GetConfig()
	return _GKP.Config
end
