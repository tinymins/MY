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
-- 幸运香囊 -- 下一次有一点五倍几率砸中年兽陶罐
-- 幸运锦囊 -- 下一次砸年兽陶罐失败则保留两点五成积分
-- 如意香囊 -- 下一次有两点五倍几率砸中年兽陶罐
-- 如意锦囊 -- 下一次砸年兽陶罐失败则保留一半积分
-- 寄忧谷 -- 下一次有五倍几率砸中年兽陶罐
-- 醉生 -- 下一次砸年兽陶罐失败则不损失积分

local DEFAULT_O = {
	nPausePoint              = 327680, -- 停砸分数线
	bUseTaoguan              = true  , -- 必要时使用背包的陶罐
	bNoYinchuiUseJinchui     = false , -- 没小银锤时使用小金锤
	nUseXiaojinchui          = 320   , -- 优先使用小金锤的分数
	bPauseNoXiaojinchui      = false , -- 缺少小金锤时停砸
	nUseXingyunXiangnang     = 80    , -- 开始吃幸运香囊的分数
	bPauseNoXingyunXiangnang = false , -- 缺少幸运香囊时停砸
	nUseXingyunJinnang       = 80    , -- 开始吃幸运锦囊的分数
	bPauseNoXingyunJinnang   = false , -- 缺少幸运锦囊时停砸
	nUseRuyiXiangnang        = 80    , -- 开始吃如意香囊的分数
	bPauseNoRuyiXiangnang    = false , -- 缺少如意香囊时停砸
	nUseRuyiJinnang          = 80    , -- 开始吃如意锦囊的分数
	bPauseNoRuyiJinnang      = false , -- 缺少如意锦囊时停砸
	nUseJiyougu              = 1280  , -- 开始吃寄忧谷的分数
	bPauseNoJiyougu          = true  , -- 缺少寄忧谷时停砸
	nUseZuisheng             = 1280  , -- 开始吃醉生的分数
	bPauseNoZuisheng         = true  , -- 缺少醉生时停砸
	tFilterItem = {
		[LIB.GetObjectName('ITEM_INFO', 5, 6072)] = true, -- 鞭炮
		[LIB.GetObjectName('ITEM_INFO', 5, 6069)] = true, -- 火树银花
		[LIB.GetObjectName('ITEM_INFO', 5, 6068)] = true, -- 龙凤呈祥
		[LIB.GetObjectName('ITEM_INFO', 5, 6067)] = true, -- 彩云逐月
		[LIB.GetObjectName('ITEM_INFO', 5, 6076)] = true, -- 熠熠生辉
		[LIB.GetObjectName('ITEM_INFO', 5, 6073)] = true, -- 焰火棒
		[LIB.GetObjectName('ITEM_INFO', 5, 6070)] = true, -- 窜天猴
		[LIB.GetObjectName('ITEM_INFO', 5, 6077)] = true, -- 彩云逐月
		[LIB.GetObjectName('ITEM_INFO', 5, 8025, 1168)] = true, -- 剪纸：龙腾
		[LIB.GetObjectName('ITEM_INFO', 5, 8025, 1170)] = true, -- 剪纸：凤舞
		[LIB.GetObjectName('ITEM_INFO', 5, 6066)] = true, -- 元宝灯
		[LIB.GetObjectName('ITEM_INFO', 5, 6067)] = true, -- 桃花灯
		[LIB.GetObjectName('ITEM_INFO', 5, 6048)] = true, -- 桃木牌·马
		[LIB.GetObjectName('ITEM_INFO', 5, 6049)] = true, -- 桃木牌·年
		[LIB.GetObjectName('ITEM_INFO', 5, 6050)] = true, -- 桃木牌·吉
		[LIB.GetObjectName('ITEM_INFO', 5, 6051)] = true, -- 桃木牌·祥
		[LIB.GetObjectName('ITEM_INFO', 5, 6200)] = true, -- 图样：彩云逐月
		[LIB.GetObjectName('ITEM_INFO', 5, 6203)] = true, -- 图样：熠熠生辉
		[LIB.GetObjectName('ITEM_INFO', 5, 6258)] = false, -- 监本印文兑换券
		[LIB.GetObjectName('ITEM_INFO', 5, 31599)] = false, -- 战魂佩
		[LIB.GetObjectName('ITEM_INFO', 5, 30692)] = false, -- 豪侠贡
		[LIB.GetObjectName('ITEM_INFO', 5, 6024)] = true, -- 年年有鱼灯
		[LIB.GetObjectName('ITEM_INFO', 5, 20959)] = false, -- 年兽陶罐
		[LIB.GetObjectName('ITEM_INFO', 5, 6027)] = false, -- 幸运香囊
	},
}
local O = Clone(DEFAULT_O)
RegisterCustomData('MY_Taoguan.nPausePoint')
RegisterCustomData('MY_Taoguan.bUseTaoguan')
RegisterCustomData('MY_Taoguan.bNoYinchuiUseJinchui')
RegisterCustomData('MY_Taoguan.nUseXiaojinchui')
RegisterCustomData('MY_Taoguan.bPauseNoXiaojinchui')
RegisterCustomData('MY_Taoguan.nUseXingyunXiangnang')
RegisterCustomData('MY_Taoguan.bPauseNoXingyunXiangnang')
RegisterCustomData('MY_Taoguan.nUseXingyunJinnang')
RegisterCustomData('MY_Taoguan.bPauseNoXingyunJinnang')
RegisterCustomData('MY_Taoguan.nUseRuyiXiangnang')
RegisterCustomData('MY_Taoguan.bPauseNoRuyiXiangnang')
RegisterCustomData('MY_Taoguan.nUseRuyiJinnang')
RegisterCustomData('MY_Taoguan.bPauseNoRuyiJinnang')
RegisterCustomData('MY_Taoguan.nUseJiyougu')
RegisterCustomData('MY_Taoguan.bPauseNoJiyougu')
RegisterCustomData('MY_Taoguan.nUseZuisheng')
RegisterCustomData('MY_Taoguan.bPauseNoZuisheng')
RegisterCustomData('MY_Taoguan.tFilterItem')

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local TAOGUAN = LIB.GetItemNameByUIID(74224) -- 年兽陶罐
local XIAOJINCHUI = LIB.GetItemNameByUIID(65611) -- 小金锤
local XIAOYINCHUI = LIB.GetItemNameByUIID(65609) -- 小银锤
local MEILIANGYUQIAN = LIB.GetItemNameByUIID(65589) -- 梅良玉签
local XINGYUNXIANGNANG = LIB.GetItemNameByUIID(65578) -- 幸运香囊
local XINGYUNJINNANG = LIB.GetItemNameByUIID(65581) -- 幸运锦囊
local RUYIXIANGNANG = LIB.GetItemNameByUIID(65579) -- 如意香囊
local RUYIJINNANG = LIB.GetItemNameByUIID(65582) -- 如意锦囊
local JIYOUGU = LIB.GetItemNameByUIID(65580) -- 寄忧谷
local ZUISHENG = LIB.GetItemNameByUIID(65583) -- 醉生
local ITEM_CD = 1 * GLOBAL.GAME_FPS + 8 -- 吃药CD
local HAMMER_CD = 5 * GLOBAL.GAME_FPS + 8 -- 锤子CD
local MAX_POINT_POW = 16 -- 分数最高倍数（2^n）

local D = {
	bEnable = false, -- 启用状态
	nPoint = 0, -- 当前总分数
	nUseItemLFC = 0, -- 上次吃药的逻辑帧
	nUseHammerLFC = 0, -- 上次用锤子的逻辑帧
	dwDoodadID = 0, -- 自动拾取过滤的交互物件ID
	aUseItemPS = { -- 设置界面的物品使用条件
		{ szName = XIAOJINCHUI, szID = 'Xiaojinchui' },
		{ szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang' },
		{ szName = XINGYUNJINNANG, szID = 'XingyunJinnang' },
		{ szName = RUYIXIANGNANG, szID = 'RuyiXiangnang' },
		{ szName = RUYIJINNANG, szID = 'RuyiJinnang' },
		{ szName = JIYOUGU, szID = 'Jiyougu' },
		{ szName = ZUISHENG, szID = 'Zuisheng' },
	},
	aUseItemOrder = { -- 状态转移函数中物品与BUFF判断逻辑
		{
			{ szName = JIYOUGU, szID = 'Jiyougu', dwBuffID = 1660, nBuffLevel = 3 },
			{ szName = RUYIXIANGNANG, szID = 'RuyiXiangnang', dwBuffID = 1660, nBuffLevel = 2 },
			{ szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang', dwBuffID = 1660, nBuffLevel = 1 },
		},
		{
			{ szName = ZUISHENG, szID = 'Zuisheng', dwBuffID = 1661, nBuffLevel = 3 },
			{ szName = RUYIJINNANG, szID = 'RuyiJinnang', dwBuffID = 1661, nBuffLevel = 2 },
			{ szName = XINGYUNJINNANG, szID = 'XingyunJinnang', dwBuffID = 1661, nBuffLevel = 1 },
		},
	},
}

-- 使用背包物品
function D.UseBagItem(szName, bWarn)
	local me = GetClientPlayer()
	for i = 1, 6 do
		for j = 0, me.GetBoxSize(i) - 1 do
		local it = GetPlayerItem(me, i, j)
			if it and it.szName == szName then
				--[[#DEBUG BEGIN]]
				LIB.Debug('MY_Taoguan', 'UseItem: ' .. i .. ',' .. j .. ' ' .. szName, DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				OnUseItem(i, j)
				return true
			end
		end
	end
	if bWarn then
		LIB.Sysmsg(_L('Auto taoguan: missing [%s]!', szName))
	end
end

-- 砸罐子状态机转移函数
function D.BreakCanStateTransfer()
	local me = GetClientPlayer()
	if not me or not D.bEnable then
		return
	end
	local nLFC = GetLogicFrameCount()
	-- 确认掉砸金蛋确认框
	LIB.DoMessageBox('PlayerMessageBoxCommon')
	-- 吃药还在CD则等待
	if nLFC - D.nUseItemLFC < ITEM_CD then
		return
	end
	-- 检查吃药BUFF满足情况
	for _, aItem in ipairs(D.aUseItemOrder) do
		-- 每个分组优先级顺序处理
		for _, item in ipairs(aItem) do
			-- 符合吃药分数条件
			if D.nPoint >= O['nUse' .. item.szID] then
				-- 如果已经有BUFF，即吃过药了，则跳出循环
				if LIB.GetBuff(me, item.dwBuffID, item.nBuffLevel) then
					break
				end
				-- 否则尝试吃药
				if D.UseBagItem(item.szName, O['bPauseNo' .. item.szID]) then
					D.nUseItemLFC = nLFC
					-- 吃成功了，等待下次状态机转移函数调用
					return
				end
				if O['bPauseNo' .. item.szID] then
					-- 吃失败了，暂停砸罐子
					D.Stop()
					return
				end
			end
		end
	end
	-- 锤子还在CD则等待
	if nLFC - D.nUseHammerLFC < HAMMER_CD then
		return
	end
	-- 寻找能砸的陶罐
	local npcTaoguan
	for _, npc in ipairs(LIB.GetNearNpc()) do
		if npc and npc.dwTemplateID == 6820 then
			if LIB.GetDistance(npc) < 4 then
				npcTaoguan = npc
				break
			end
		end
	end
	-- 没有能砸的陶罐考虑自己放一个
	if not npcTaoguan and O.bUseTaoguan then
		if D.UseBagItem(TAOGUAN) then
			D.nUseItemLFC = nLFC
		end
	end
	-- 还是没有找到罐子则等待
	if not npcTaoguan then
		return
	end
	-- 找到罐子了，设为目标
	LIB.SetTarget(TARGET.NPC, npcTaoguan.dwID)
	-- 需要用小金锤，砸他丫的
	if D.nPoint >= O.nUseXiaojinchui then
		if D.UseBagItem(XIAOJINCHUI, O.bPauseNoXiaojinchui) then
			-- 砸成功了，等锤子CD
			D.nUseHammerLFC = nLFC
			return
		end
		if O.bPauseNoXiaojinchui then
			-- 砸失败了，暂停砸罐子
			D.Stop()
			return
		end
	end
	-- 需要用小银锤，砸他丫的
	if D.UseBagItem(XIAOYINCHUI) then
		-- 砸成功了，等锤子CD
		D.nUseHammerLFC = nLFC
		return
	end
	-- 没有小银锤时使用小金锤？
	if O.bNoYinchuiUseJinchui and D.UseBagItem(XIAOJINCHUI) then
		-- 砸成功了，等锤子CD
		D.nUseHammerLFC = nLFC
		return
	end
	-- 没有金锤也没有银锤，凉了呀
	D.UseBagItem(XIAOYINCHUI, true)
	D.Stop()
end

-------------------------------------
-- 事件处理
-------------------------------------
function D.MonitorZP(szMsg)
	local _, _, nP = string.find(szMsg, _L['Current total score:(%d+)'])
	if nP then
		D.nPoint = tonumber(nP)
		if D.nPoint >= O.nPausePoint then
			D.Stop()
			D.bReachLimit = true
			LIB.Sysmsg(_L['Auto taoguan: reach limit!'])
		end
		D.nUseHammerLFC = GetLogicFrameCount()
	end
end

function D.OnLootItem()
	if arg0 == GetClientPlayer().dwID and arg2 > 2 and GetItem(arg1).szName == MEILIANGYUQIAN then
		D.nPoint = 0
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
					LIB.Sysmsg(_L('Auto taoguan: filter item [%s].', szName))
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

-- 砸罐子开始（注册事件）
function D.Start()
	if D.bEnable then
		return
	end
	D.bEnable = true
	LIB.RegisterMsgMonitor('MY_Taoguan', D.MonitorZP, {'MSG_SYS'})
	LIB.BreatheCall('MY_Taoguan', D.BreakCanStateTransfer)
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
	LIB.Sysmsg(_L['Auto taoguan: on.'])
end

-- 砸罐子关闭（注销事件）
function D.Stop()
	if not D.bEnable then
		return
	end
	D.bEnable = false
	LIB.RegisterMsgMonitor('MY_Taoguan', false)
	LIB.BreatheCall('MY_Taoguan', false)
	LIB.RegisterEvent('NPC_ENTER_SCENE.MY_Taoguan', false)
	LIB.RegisterEvent('LOOT_ITEM.MY_Taoguan', false)
	LIB.RegisterEvent('DOODAD_ENTER_SCENE.MY_Taoguan', false)
	LIB.RegisterEvent('HELP_EVENT.MY_Taoguan', false)
	LIB.Sysmsg(_L['Auto taoguan: off.'])
end

-- 砸罐子开关
function D.Switch()
	if D.bEnable then
		D.Stop()
	else
		D.Start()
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

	-- 分数达到多少停砸
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Stop simple broken can when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = MY_Taoguan.nPausePoint,
		menu = function()
			local ui = UI(this)
			local m0 = {}
			for i = 2, MAX_POINT_POW do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					MY_Taoguan.nPausePoint = v
					ui:Text(tostring(v))
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

	-- 没有小银锤时使用小金锤
	-- nX = X + 10
	nY = nY + 28
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L('When no %s use %s?', XIAOYINCHUI, XIAOJINCHUI),
		checked = MY_Taoguan.bNoYinchuiUseJinchui,
		oncheck = function(bChecked) MY_Taoguan.bNoYinchuiUseJinchui = bChecked end,
	}):AutoWidth()

	-- 各种东西使用分数和缺少停砸
	local nMaxItemNameLen = 0
	for _, p in ipairs(D.aUseItemPS) do
		nMaxItemNameLen = max(nMaxItemNameLen, wlen(p.szName))
	end
	for _, p in ipairs(D.aUseItemPS) do
		nX = X + 10
		nY = nY + 28
		nX = ui:Append('Text', {
			x = nX, y = nY,
			text = _L('Use %s when score reaches', p.szName .. rep(g_tStrings.STR_ONE_CHINESE_SPACE, nMaxItemNameLen - wlen(p.szName))),
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		nX = ui:Append('WndComboBox', {
			x = nX, y = nY, w = 100, h = 25,
			text = MY_Taoguan['nUse' .. p.szID],
			menu = function()
				local ui = UI(this)
				local m0 = {}
				for i = 2, MAX_POINT_POW - 1 do
					local v = 10 * 2 ^ i
					table.insert(m0, { szOption = tostring(v), fnAction = function()
						MY_Taoguan['nUse' .. p.szID] = v
						ui:Text(tostring(v))
					end })
				end
				return m0
			end,
		}):Pos('BOTTOMRIGHT') + 10
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Stop break when no item'],
			checked = MY_Taoguan['bPauseNo' .. p.szID],
			oncheck = function(bChecked)
				MY_Taoguan['bPauseNo' .. p.szID] = bChecked
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- 拾取过滤
	nX = X + 10
	nY = nY + 38
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 150,
		text = _L['Pickup filters'],
		menu = function()
			local m0 = {}
			for k, v in pairs(MY_Taoguan.tFilterItem) do
				local m1 = {
					szOption = k,
					bCheck = true, bChecked = v == true,
					fnAction = function(d, b)
						MY_Taoguan.tFilterItem[k] = b
					end,
				}
				if DEFAULT_O.tFilterItem[k] == nil then
					m1.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
					m1.nFrame = 49
					m1.nMouseOverFrame = 51
					m1.nIconWidth = 17
					m1.nIconHeight = 17
					m1.szLayer = 'ICON_RIGHTMOST'
					m1.fnClickIcon = function()
						MY_Taoguan.tFilterItem[k] = nil
						Wnd.CloseWindow('PopupMenuPanel')
					end
				end
				table.insert(m0, m1)
			end
			if #m0 > 0 then
				insert(m0, CONSTANT.MENU_DIVIDER)
			end
			insert(m0, {
				szOption = _L['Custom add'],
				fnAction = function()
					local function fnConfirm(szText)
						O.tFilterItem[szText] = true
					end
					GetUserInput(_L['Please input custom name'], fnConfirm, nil, nil, nil, '', 20)
				end,
			})
			return m0
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['(Checked will not be picked up, if still pick please check system auto pick config)'] })

	-- 控制按钮
	nX = X + 10
	nY = nY + 36
	nX = ui:Append('WndButton', {
		x = nX, y = nY, w = 130, h = 30,
		text = _L['Start/stop break can'],
		onclick = D.Switch,
	}):Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndButton', {
		x = nX, y = nY, w = 130, h = 30,
		text = _L['Restore default config'],
		onclick = function()
			for k, v in pairs(DEFAULT_O) do
				MY_Taoguan[k] = v
			end
			LIB.SwitchTab('MY_Taoguan', true)
		end,
	}):Pos('BOTTOMRIGHT')
end
LIB.RegisterPanel('MY_Taoguan', _L[MODULE_NAME], _L['Target'], 119, PS)

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				nPausePoint = true,
				bUseTaoguan = true,
				bNoYinchuiUseJinchui = true,
				nUseXiaojinchui = true,
				bPauseNoXiaojinchui = true,
				nUseXingyunXiangnang = true,
				bPauseNoXingyunXiangnang = true,
				nUseXingyunJinnang = true,
				bPauseNoXingyunJinnang = true,
				nUseRuyiXiangnang = true,
				bPauseNoRuyiXiangnang = true,
				nUseRuyiJinnang = true,
				bPauseNoRuyiJinnang = true,
				nUseJiyougu = true,
				bPauseNoJiyougu = true,
				nUseZuisheng = true,
				bPauseNoZuisheng = true,
				tFilterItem = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				nPausePoint = true,
				bUseTaoguan = true,
				bNoYinchuiUseJinchui = true,
				nUseXiaojinchui = true,
				bPauseNoXiaojinchui = true,
				nUseXingyunXiangnang = true,
				bPauseNoXingyunXiangnang = true,
				nUseXingyunJinnang = true,
				bPauseNoXingyunJinnang = true,
				nUseRuyiXiangnang = true,
				bPauseNoRuyiXiangnang = true,
				nUseRuyiJinnang = true,
				bPauseNoRuyiJinnang = true,
				nUseJiyougu = true,
				bPauseNoJiyougu = true,
				nUseZuisheng = true,
				bPauseNoZuisheng = true,
				tFilterItem = true,
			},
			triggers = {
				tFilterItem = function()
					if IsEmpty(O.tFilterItem) then
						O.tFilterItem = {}
					end
					for v, b in pairs(DEFAULT_O.tFilterItem) do
						if O.tFilterItem[v] == nil then
							O.tFilterItem[v] = b
						end
					end
				end,
			},
			root = O,
		},
	},
}
MY_Taoguan = LIB.GeneGlobalNS(settings)
end
