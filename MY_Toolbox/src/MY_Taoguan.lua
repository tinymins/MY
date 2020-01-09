--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动砸年兽陶罐
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Taoguan'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local O = {
	nUseGold = 320,       -- 优先使用金锤子的分数
	nUseZJ = 1280,        -- 开始吃醉生、寄优谷的分数
	bPauseNoZJ = true,    -- 缺少醉生、寄优时停砸
	nPausePoint = 327680, -- 停砸分数线
	nUseJX = 80,          -- 自动用掉锦囊、香囊
	bNonZS = false,       -- 不使用醉生
	bUseGold = false,     -- 没银锤时使用金锤
	bUseTaoguan = true,   -- 必要时自动使用背包的陶罐
	tFilterItem = {},
}
RegisterCustomData('MY_Taoguan.nUseGold')
RegisterCustomData('MY_Taoguan.nUseZJ')
RegisterCustomData('MY_Taoguan.bPauseNoZJ')
RegisterCustomData('MY_Taoguan.nPausePoint')
RegisterCustomData('MY_Taoguan.nUseJX')
RegisterCustomData('MY_Taoguan.bNonZS')
RegisterCustomData('MY_Taoguan.bUseGold')
RegisterCustomData('MY_Taoguan.bUseTaoguan')
RegisterCustomData('MY_Taoguan.tFilterItem')

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local TAOGUAN = LIB.GetItemNameByUIID(74224) -- 年兽陶罐
local XIAOJINCHUI = LIB.GetItemNameByUIID(65611) -- 小金锤
local XIAOYINCHUI = LIB.GetItemNameByUIID(65609) -- 小银锤
local MEILIANGYUQIAN = LIB.GetItemNameByUIID(65589) -- 梅良玉签
local JIYOUGU = LIB.GetItemNameByUIID(65580) -- 寄忧谷
local ZUISHENG = LIB.GetItemNameByUIID(65583) -- 醉生
local RUYIXIANGNANG = LIB.GetItemNameByUIID(65579) -- 如意香囊
local XINYUNXIANGNANG = LIB.GetItemNameByUIID(65578) -- 幸运香囊
local RUYIJINNANG = LIB.GetItemNameByUIID(65582) -- 如意锦囊
local XINYUNJINNANG = LIB.GetItemNameByUIID(65581) -- 幸运锦囊

local D = {
	bEnable = false,
	bHaveZJ = false,
	nPoint = 0,
	tListed = {},
	dwDoodadID = 0,
}

function D.UseBagItem(szName, bWarn)
	local me = GetClientPlayer()
	for i = 1, 6 do
		for j = 0, me.GetBoxSize(i) - 1 do
		local it = GetPlayerItem(me, i, j)
			if it and it.szName == szName then
				OnUseItem(i, j)
				return true
			end
		end
	end
	if bWarn then
		LIB.Sysmsg(_L('Auto taoguan: missing [%s]!', szName))
	end
end

function D.Switch()
	D.bEnable = not D.bEnable
	D.bHaveZJ = false
	if D.bEnable then
		LIB.Sysmsg(_L['Auto taoguan: on'])
		D.FindNear()
	else
		LIB.Sysmsg(_L['Auto taoguan: off'])
	end
end

function D.FindNear()
	local bFound = false
	D.bReachLimit = nil
	for k, _ in pairs(D.tListed) do
		local npc = GetNpc(k)
		if not npc then
			D.tListed[k] = nil
		elseif LIB.GetDistance(npc) < 4 then
			bFound = true
			FireUIEvent('NPC_ENTER_SCENE', k)
		end
	end
	if not bFound and O.bUseTaoguan then
		D.UseBagItem(TAOGUAN)
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
function D.MonitorZP(szMsg)
	local _, _, nP = string.find(szMsg, _L['Current total score:(%d+)'])
	if nP then
		D.nPoint = tonumber(nP)
		D.bHaveZJ = false
		if D.nPoint >= O.nPausePoint then
			D.bEnable = false
			D.bReachLimit = true
			LIB.Sysmsg(_L['Auto taoguan: reach limit!'])
		else
			-- foreced to find next
			LIB.DelayCall(5500, D.FindNear)
		end
	elseif D.bEnable and StringFindW(szMsg, TAOGUAN) then
		-- foreced to find next [年兽陶罐已破碎|请选中年兽陶罐后使用]
		LIB.DelayCall(5500, D.FindNear)
	end
end

function D.OnNpcEnter()
	local npc = GetNpc(arg0)
	if not npc or npc.dwTemplateID ~= 6820 then
		return
	end
	D.tListed[arg0] = true
	if not D.bEnable
		or (O.bPauseNoZJ and D.nPoint >= O.nUseZJ and not D.bHaveZJ)
	then
		return
	end
	if LIB.GetDistance(npc) < 4 then
		LIB.SetTarget(TARGET.NPC, arg0)
		if D.nPoint < O.nUseGold or not D.UseBagItem(XIAOJINCHUI) then
			if not D.UseBagItem(XIAOYINCHUI, true)
				and (not O.bUseGold or not D.UseBagItem(XIAOJINCHUI, true))
			then
				D.bEnable = false
			end
		end
	end
end

function D.OnLootItem()
	if arg0 == GetClientPlayer().dwID and arg2 > 2 and GetItem(arg1).szName == MEILIANGYUQIAN then
		D.nPoint = 0
		D.bHaveZJ = false
		LIB.Sysmsg(_L['Auto taoguan: score clear!'])
	end
end

function D.OnDoodadEnter()
	if D.bEnable or D.bReachLimit then
		local d = GetDoodad(arg0)
		if d and d.szName == TAOGUAN and d.CanDialog(GetClientPlayer())
			and LIB.GetDistance(d) < 4.1
		then
			D.dwDoodadID = arg0
			LIB.DelayCall(520, function()
				InteractDoodad(D.dwDoodadID)
			end)
		end
	end
end

function D.OnOpenDoodad()
	if D.bEnable or D.bReachLimit then
		local d = GetDoodad(D.dwDoodadID)
		if d and d.szName == TAOGUAN then
			local nQ, nM, me = 1, d.GetLootMoney(), GetClientPlayer()
			if nM > 0 then
				LootMoney(d.dwID)
			end
			for i = 0, 31 do
				local it, bRoll, bDist = d.GetLootItem(i, me)
				if not it then
					break
				end
				local szName = GetItemNameByItem(it)
				if it.nQuality >= nQ and not bRoll and not bDist
					and not O.tFilterItem[szName]
				then
					LootItem(d.dwID, it.dwID)
				else
					LIB.Sysmsg(_L('Auto taoguan: filter item [%s]', szName))
				end
			end
			local hL = Station.Lookup('Normal/LootList', 'Handle_LootList')
			if hL then
				hL:Clear()
			end
		end
		D.bReachLimit = nil
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local nX, nY = X, Y

	ui:Append('Text', { text = _L['Feature setting'], x = nX, y = nY, font = 27 })

	-- gold
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Use golden hammer when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		name = 'Combo_Size1',
		x = nX, y = nY, w = 100, h = 25,
		text = MY_Taoguan.nUseGold,
		menu = function()
			local m0 = {}
			for i = 3, 9 do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					MY_Taoguan.nUseGold = v
					ui:Fetch('Combo_Size1'):Text(tostring(v))
				end })
			end
			return m0
		end,
	}):Pos('BOTTOMRIGHT') + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Use silver hammer when no golden hammer?'],
		checked = MY_Taoguan.bUseGold,
		oncheck = function(bChecked) MY_Taoguan.bUseGold = bChecked end,
	}):AutoWidth()

	-- max
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Stop simple broken can when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		name = 'Combo_Size3',
		x = nX, y = nY, w = 100, h = 25,
		text = MY_Taoguan.nPausePoint,
		menu = function()
			local m0 = {}
			for i = 7, 16 do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					MY_Taoguan.nPausePoint = v
					ui:Fetch('Combo_Size3'):Text(tostring(v))
				end })
			end
			return m0
		end,
	}):Pos('BOTTOMRIGHT') + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Put can if needed?'],
		checked = MY_Taoguan.bUseTaoguan,
		oncheck = function(bChecked) MY_Taoguan.bUseTaoguan = bChecked end,
	}):AutoWidth()

	-- zj
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Use JiYouGu and ZuiSheng when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		name = 'Combo_Size2',
		x = nX, y = nY, w = 100, h = 25,
		text = MY_Taoguan.nUseZJ,
		menu = function()
			local m0 = {}
			for i = 5, 11 do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					MY_Taoguan.nUseZJ = v
					ui:Fetch('Combo_Size2'):Text(tostring(v))
				end })
			end
			return m0
		end,
	}):Pos('BOTTOMRIGHT') + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Stop break when no item'],
		checked = MY_Taoguan.bPauseNoZJ,
		oncheck = function(bChecked) MY_Taoguan.bPauseNoZJ = bChecked end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['No ZuiSheng'],
		checked = MY_Taoguan.bNonZS,
		oncheck = function(bChecked) MY_Taoguan.bNonZS = bChecked end,
	}):AutoWidth()

	-- JX
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Use JinNang and XiangNang when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	ui:Append('WndComboBox', {
		name = 'Combo_Size4',
		x = nX, y = nY, w = 100, h = 25,
		text = MY_Taoguan.nUseJX,
		menu = function()
			local m0 = {}
			for i = 2, 10 do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					MY_Taoguan.nUseJX = v
					ui:Fetch('Combo_Size4'):Text(tostring(v))
				end })
			end
			return m0
		end,
	})

	-- filter
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 150,
		text = _L['Pickup filters'],
		menu = function()
			local m0 = {}
			for k, v in pairs(MY_Taoguan.tFilterItem) do
				table.insert(m0, { szOption = k, bCheck = true, bChecked = v == true, fnAction = function(d, b)
					MY_Taoguan.tFilterItem[k] = b
				end })
			end
			return m0
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['(Checked will not be picked up, if still pick please check system auto pick config)'] })

	-- begin
	nX = X + 10
	nY = nY + 36
	nX = ui:Append('WndButton', {
		x = nX, y = nY, w = 130, h = 30,
		text = _L['Start/stop break can'],
		onclick = D.Switch,
	}):Pos('BOTTOMRIGHT')
end
LIB.RegisterPanel('MY_Taoguan', _L[MODULE_NAME], _L['Target'], 119, PS)

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
LIB.RegisterInit('MY_Taoguan', function()
	if IsEmpty(O.tFilterItem) then
		for v, b in pairs({
			[{5, 6072}] = true, -- 鞭炮
			[{5, 6069}] = true, -- 火树银花
			[{5, 6068}] = true, -- 龙凤呈祥
			[{5, 6067}] = true, -- 彩云逐月
			[{5, 6076}] = true, -- 熠熠生辉
			[{5, 6073}] = true, -- 焰火棒
			[{5, 6070}] = true, -- 窜天猴
			[{5, 8025, 1168}] = true, -- 剪纸：龙腾
			[{5, 8025, 1170}] = true, -- 剪纸：凤舞
			[{5, 6066}] = true, -- 元宝灯
			[{5, 6067}] = true, -- 桃花灯
			[{5, 6048}] = false, -- 桃木牌·马
			[{5, 6049}] = false, -- 桃木牌·年
			[{5, 6050}] = false, -- 桃木牌·吉
			[{5, 6051}] = true, -- 桃木牌·祥
			[{5, 6200}] = true, -- 图样：彩云逐月
			[{5, 6203}] = true, -- 图样：熠熠生辉
			[{5, 6258}] = false, -- 监本印文兑换券
			[{5, 31599}] = false, -- 战魂佩
			[{5, 30692}] = false, -- 豪侠贡
			[{5, 6024}] = true, -- 年年有鱼灯
		}) do
			local itemInfo = GetItemInfo(v[1], v[2])
			if itemInfo then
				O.tFilterItem[LIB.GetItemNameByItemInfo(itemInfo, v[3])] = b
			end
		end
	end
end)
LIB.RegisterMsgMonitor('MY_Taoguan', D.MonitorZP, {'MSG_SYS'})
LIB.BreatheCall('MY_Taoguan', function()
	if D.bEnable then
		LIB.DoMessageBox('PlayerMessageBoxCommon')
	end
	if D.bEnable and D.nPoint >= O.nUseZJ then
		local bJ, bZ = true, O.bNonZS == false
		local aBuff, nCount, buff = LIB.GetBuffList(GetClientPlayer())
		for i = 1, nCount do
			buff = aBuff[i]
			if buff.dwID == 1660 and buff.nLevel == 3 then
				bJ = false
			elseif buff.dwID == 1661 and buff.nLevel == 3 then
				bZ = false
			end
		end
		D.bHaveZJ = bJ == false and bZ == false
		if bJ and not D.UseBagItem(JIYOUGU, O.bPauseNoZJ) and O.bPauseNoZJ then
			D.bEnable = false
		elseif bZ and not D.UseBagItem(ZUISHENG, O.bPauseNoZJ) and O.bPauseNoZJ then
			D.bEnable = false
		end
	elseif D.bEnable and D.nPoint >= O.nUseJX then
		local me = GetClientPlayer()
		if not LIB.GetBuff(me, 1660) and not D.UseBagItem(RUYIXIANGNANG) then
			D.UseBagItem(XINYUNXIANGNANG)
		end
		if not LIB.GetBuff(me, 1661) and not D.UseBagItem(RUYIJINNANG) then
			D.UseBagItem(XINYUNJINNANG)
		end
	end
end, 1000)
LIB.RegisterEvent('NPC_ENTER_SCENE.MY_Taoguan', D.OnNpcEnter)
LIB.RegisterEvent('LOOT_ITEM.MY_Taoguan', D.OnLootItem)
LIB.RegisterEvent('DOODAD_ENTER_SCENE.MY_Taoguan', D.OnDoodadEnter)
LIB.RegisterEvent('HELP_EVENT.MY_Taoguan', function()
	if arg0 == 'OnOpenpanel' and arg1 == 'LOOT'
		and D.bEnable and D.dwDoodadID ~= 0
	then
		D.OnOpenDoodad()
		D.dwDoodadID = 0
	end
end)
LIB.RegisterHotKey('MY_Taoguan', _L['Turn on/off MY_Taoguan'], D.Switch)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				nUseGold = true,
				nUseZJ = true,
				bPauseNoZJ = true,
				nPausePoint = true,
				nUseJX = true,
				bNonZS = true,
				bUseGold = true,
				bUseTaoguan = true,
				tFilterItem = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				nUseGold = true,
				nUseZJ = true,
				bPauseNoZJ = true,
				nPausePoint = true,
				nUseJX = true,
				bNonZS = true,
				bUseGold = true,
				bUseTaoguan = true,
				tFilterItem = true,
			},
			root = O,
		},
	},
}
MY_Taoguan = LIB.GeneGlobalNS(settings)
end
