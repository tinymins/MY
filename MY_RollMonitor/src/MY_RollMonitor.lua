--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : ROLL点监控
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RollMonitor/MY_RollMonitor'
local PLUGIN_NAME = 'MY_RollMonitor'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RollMonitor'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SORT_TYPE = {
	FIRST = 1,  -- 只记录第一次
	LAST  = 2,  -- 只记录最后一次
	MAX   = 3,  -- 多次摇点取最高点
	MIN   = 4,  -- 多次摇点取最低点
	AVG   = 5,  -- 多次摇点取平均值
	AVG2  = 6,  -- 去掉最高最低取平均值
}
local SORT_TYPE_LIST = {
	SORT_TYPE.FIRST, SORT_TYPE.LAST, SORT_TYPE.MAX,
	SORT_TYPE.MIN  , SORT_TYPE.AVG , SORT_TYPE.AVG2,
}
local SORT_TYPE_INFO = {
	[SORT_TYPE.FIRST] = { -- 只记录第一次
 		szName = _L['only first score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			return aRecord[nIndex1].nRoll
		end
	},
	[SORT_TYPE.LAST] = { -- 只记录最后一次
 		szName = _L['only last score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			return aRecord[nIndex2].nRoll
		end
	},
	[SORT_TYPE.MAX] = { -- 多次摇点取最高点
 		szName = _L['highest score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = math.max(nRoll, aRecord[i].nRoll)
			end
			return nRoll
		end
	},
	[SORT_TYPE.MIN] = { -- 多次摇点取最低点
 		szName = _L['lowest score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = math.min(nRoll, aRecord[i].nRoll)
			end
			return nRoll
		end
	},
	[SORT_TYPE.AVG] = { -- 多次摇点取平均值
 		szName = _L['average score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = nRoll + aRecord[i].nRoll
			end
			return nRoll / (nIndex2 - nIndex1 + 1)
		end
	},
	[SORT_TYPE.AVG2] = { -- 去掉最高最低取平均值
 		szName = _L['average score with out pole'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nTotal, nMax, nMin = 0, 0, 0
			local nCount = nIndex2 - nIndex1 + 1
			for i = nIndex1, nIndex2 do
				local nRoll = aRecord[i].nRoll
				nMin = math.min(nMin, nRoll)
				nMax = math.max(nMax, nRoll)
				nTotal = nTotal + nRoll
			end
			if nCount > 2 then
				nCount = nCount - 2
				nTotal = nTotal - nMax - nMin
			end
			return nTotal / nCount
		end
	},
}
local PUBLISH_CHANNELS = {
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM, szName = _L['PTC_TEAM_CHANNEL'], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID, szName = _L['PTC_RAID_CHANNEL'], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG, szName = _L['PTC_TONG_CHANNEL'], rgb = GetMsgFontColor('MSG_GUILD' , true) },
}
local TIME_LIMIT = {-1, 60, 120, 180, 300, 600, 1200, 1800, 3600}
local TIME_LIMIT_TITLE = {
	 [-1  ] = _L['unlimited time'],
	 [60  ] = _L('last %d minute(s)', 1),
	 [120 ] = _L('last %d minute(s)', 2),
	 [180 ] = _L('last %d minute(s)', 3),
	 [300 ] = _L('last %d minute(s)', 5),
	 [600 ] = _L('last %d minute(s)', 10),
	 [1200] = _L('last %d minute(s)', 20),
	 [1800] = _L('last %d minute(s)', 30),
	 [3600] = _L('last %d minute(s)', 60),
}
local PS = { nPriority = 3 }
local m_uiBoard       -- 面板ui控件
local m_tRecords = {} -- 历史ROLL点详细记录
local m_aRecTime = {} -- 新纪录的时间戳（用来重绘面板）
--[[
m_tRecords = {
	['茗伊'] = {
		szName = '茗伊',
		{nTime = 1446516554, nRoll = 100},
		{nTime = 1446516577, nRoll = 50 },
	}, ...
}
]]
local O = X.CreateUserSettingsModule('MY_RollMonitor', _L['General'], {
	nSortType = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['record mode'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nTimeLimit = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['valid time'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = -1,
	},
	nPublish = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['publish setting'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nPublishChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['publish channel'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = PLAYER_TALK_CHANNEL.RAID,
	},
	bPublishUnroll = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['publish unroll'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPublishRestart = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		szDescription = X.MakeCaption({
			_L['publish while restart'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

-- 事件响应处理
-- 打开面板
-- (void) D.OpenPanel()
function D.OpenPanel()
	X.Panel.Show()
	X.Panel.Focus()
	X.Panel.SwitchTab('RollMonitor')
end

-- 清空ROLL点
-- (void) D.Clear(nChannel, bEcho)
-- (boolean) bEcho   : 是否发送重新开始聊天消息
-- (number)  nChannel: 发送频道
function D.Clear(bEcho, nChannel)
	if bEcho == nil then
		bEcho = O.bPublishRestart
	end
	if bEcho then
		nChannel = nChannel or O.nPublishChannel
		X.SendChat(nChannel, _L['----------- roll restart -----------'] .. '\n')
	end
	m_tRecords = {}
	D.DrawBoard()
end

-- 获得个人ROLL点结果
-- D.GetPersonResult(szName, nSortType, nTimeLimit)
-- D.GetPersonResult(aRecord, nSortType, nTimeLimit)
-- (string)    szName     : 要获取的玩家名字
-- (table)     aRecord    : 要获取的原始数据
-- (SORT_TYPE) nSortType  : 排序方式 值参见枚举
-- (number)    nTimeLimit : 监测时间限制 如最近5分钟则传300
function D.GetPersonResult(szName, nSortType, nTimeLimit)
	-- 格式化参数
	nSortType = nSortType or O.nSortType
	nTimeLimit = nTimeLimit or O.nTimeLimit
	local nStartTime = 0
	if nTimeLimit > 0 then
		nStartTime = GetCurrentTime() - nTimeLimit
	end
	local aRecord
	if type(szName) == 'table' then
		aRecord = szName
	else
		aRecord = m_tRecords[szName] or X.CONSTANT.EMPTY_TABLE
	end
	-- 计算有效Roll点数组下标
	local aTime = {}
	local nIndex1, nIndex2 = 0, #aRecord
	for i, rec in ipairs(aRecord) do
		if rec.nTime < nStartTime then
			nIndex1 = i
		else
			table.insert(aTime, rec.nTime)
		end
	end
	nIndex1 = nIndex1 + 1
	if nIndex1 > nIndex2 then
		return
	end
	local t = {
		szName = aRecord.szName,
		nRoll  = SORT_TYPE_INFO[nSortType].fnCalc(aRecord, nIndex1, nIndex2),
		nCount = nIndex2 - nIndex1 + 1,
		aTime  = aTime,
	}
	return t
end

-- 获得全部排序结果
-- (void) D.GetResult(nSortType, nTimeLimit)
-- (SORT_TYPE) nSortType  : 排序方式 值参见枚举
-- (number)    nTimeLimit : 监测时间限制 如最近5分钟则传300(-1表示不限时)
function D.GetResult(nSortType, nTimeLimit)
	-- 格式化参数
	nSortType = nSortType or O.nSortType
	nTimeLimit = nTimeLimit or O.nTimeLimit
	-- 获取结果并排序
	local t = {}
	for _, aRecord in pairs(m_tRecords) do
		aRecord = D.GetPersonResult(aRecord, nSortType, nTimeLimit)
		if aRecord then
			table.insert(t, aRecord)
		end
	end
	table.sort(t, function(v1, v2) return v1.nRoll > v2.nRoll end)
	return t
end

-- 发布ROLL点
-- (void) D.Echo(nSortType, nLimit, nChannel, bShowUnroll)
-- (enum)    nSortType  : 排序方式 枚举[SORT_TYPE]
-- (number)  nLimit     : 最大显示条数限制
-- (number)  nChannel   : 发送频道
-- (boolean) bShowUnroll: 是否显示未ROLL点
function D.Echo(nSortType, nLimit, nChannel, bShowUnroll)
	if bShowUnroll == nil then
		bShowUnroll = O.bPublishUnroll
	end
	nSortType = nSortType or O.nSortType
	nLimit    = nLimit    or O.nPublish
	nChannel  = nChannel  or O.nPublishChannel

	X.SendChat(nChannel, ('[%s][%s][%s]%s\n'):format(
		X.PACKET_INFO.SHORT_NAME, _L['roll monitor'],
		TIME_LIMIT_TITLE[O.nTimeLimit],
		SORT_TYPE_INFO[nSortType].szName
	), { parsers = { name = false } })
	X.SendChat(nChannel, _L['-------------------------------'] .. '\n')
	local tNames = {}
	for i, aRecord in ipairs(D.GetResult(nSortType)) do
		if nLimit <= 0 or i <= nLimit then
			X.SendChat(nChannel, _L('[%s] rolls for %d times, valid score is %s.', aRecord.szName, aRecord.nCount, string.gsub(aRecord.nRoll, '(%d+%.%d%d)%d+','%1')) .. '\n')
		end
		tNames[aRecord.szName] = true
	end
	local team = GetClientTeam()
	if team and bShowUnroll then
		local szUnrolledNames = ''
		for _, dwID in ipairs(team.GetTeamMemberList()) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not tNames[szName] then
				szUnrolledNames = szUnrolledNames .. '[' .. szName .. ']'
			end
		end
		if szUnrolledNames~='' then
			X.SendChat(nChannel, szUnrolledNames .. _L['haven\'t roll yet.']..'\n')
		end
	end
	X.SendChat(nChannel, _L['-------------------------------'] .. '\n')
end

-- 重新绘制结果显示区域
-- (void) D.DrawBoard(ui uiBoard)
function D.DrawBoard(ui)
	if not ui then
		ui = m_uiBoard
	end
	m_aRecTime = {}
	if ui then
		local szMsg = ''
		local tNames = {}
		for _, aRecord in ipairs(D.GetResult()) do
			szMsg = szMsg ..
				X.GetChatCopyXML() ..
				GetFormatText('['..aRecord.szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0') ..
				GetFormatText(_L( ' rolls for %d times, valid score is %s.', aRecord.nCount, (string.gsub(aRecord.nRoll,'(%d+%.%d%d)%d+','%1')) ) .. '\n')
			for _, nTime in ipairs(aRecord.aTime) do
				table.insert(m_aRecTime, nTime)
			end
			tNames[aRecord.szName] = true
		end
		table.sort(m_aRecTime)
		local team = GetClientTeam()
		if team then
			local szUnrolledNames = ''
			for _, dwID in ipairs(team.GetTeamMemberList()) do
				local szName = team.GetClientTeamMemberName(dwID)
				if not tNames[szName] then
					szUnrolledNames = szUnrolledNames .. GetFormatText('['..szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0')
				end
			end
			if szUnrolledNames ~= '' then
				szMsg = szMsg ..
				X.GetChatCopyXML() ..
				szUnrolledNames .. GetFormatText(_L['haven\'t roll yet.'])
			end
		end
		szMsg = X.RenderChatLink(szMsg)
		if MY_ChatEmotion and MY_ChatEmotion.Render then
			szMsg = MY_ChatEmotion.Render(szMsg)
		end
		if MY_Farbnamen and MY_Farbnamen.Render then
			szMsg = MY_Farbnamen.Render(szMsg)
		end
		ui:Clear():Append(szMsg)
	end
end

-- 检查是否需要重绘 如需重绘则重新绘制
local function CheckBoardRedraw()
	if m_aRecTime[1]
	and m_aRecTime[1] < GetCurrentTime() then
		D.DrawBoard()
	end
end

-- 系统频道监控处理函数
local function OnMsgArrive(szMsg, nFont, bRich, r, g, b)
	local isRoll = false
	for szName, nRoll in string.gmatch(szMsg, _L['ROLL_MONITOR_EXP'] ) do
		-- 格式化数值
		nRoll = tonumber(nRoll)
		if not nRoll then
			return
		end
		isRoll = true
		-- 判断缓存中该玩家是否已存在记录
		if not m_tRecords[szName] then
			m_tRecords[szName] = { szName = szName }
		end
		local aRecord = m_tRecords[szName]
		-- 格式化数组 更新各数值
		table.insert(m_aRecTime, GetCurrentTime())
		table.insert(aRecord, {nTime = GetCurrentTime(), nRoll = nRoll})
	end
	if not isRoll then
		return
	end
	D.DrawBoard()
end
RegisterMsgMonitor(OnMsgArrive, {'MSG_SYS'})


--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RollMonitor',
	exports = {
		{
			fields = {
				OpenPanel = D.OpenPanel,
				Clear = D.Clear,
			},
		},
	},
}
MY_RollMonitor = X.CreateModule(settings)
end


-- 标签激活响应函数
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	-- 记录模式
	ui:Append('WndComboBox', {
		x = 20, y = 10, w = 180,
		text = SORT_TYPE_INFO[O.nSortType].szName,
		menu = function()
			local t = {}
			local el = this
			for _, nSortType in ipairs(SORT_TYPE_LIST) do
				table.insert(t, {
					szOption = SORT_TYPE_INFO[nSortType].szName,
					fnAction = function()
						O.nSortType = nSortType
						D.DrawBoard()
						X.UI(el):Text(SORT_TYPE_INFO[nSortType].szName)
						return 0
					end,
				})
			end
			return t
		end
	})
	-- 有效时间
	ui:Append('WndComboBox', {
		x = 210, y = 10, w = 120,
		text = TIME_LIMIT_TITLE[O.nTimeLimit],
		menu = function()
			local t = {}
			local el = this
			for _, nSec in ipairs(TIME_LIMIT) do
				table.insert(t, {
					szOption = TIME_LIMIT_TITLE[nSec],
					fnAction = function()
						X.UI(el):Text(TIME_LIMIT_TITLE[nSec])
						O.nTimeLimit = nSec
						D.DrawBoard()
						return 0
					end,
				})
			end
			return t
		end
	})
	-- 清空
	ui:Append('WndButton', {
		x = nW - 176, y = 10, w = 90, text = _L['restart'],
		onLClick = function(nButton) D.Clear() end,
		menuRClick = function()
			local t = {{
				szOption = _L['publish while restart'],
				bCheck = true, bMCheck = false, bChecked = O.bPublishRestart,
				fnAction = function() O.bPublishRestart = not O.bPublishRestart end,
			}, { bDevide = true }}
			for _, tChannel in ipairs(PUBLISH_CHANNELS) do
				table.insert(t, {
					szOption = tChannel.szName,
					rgb = tChannel.rgb,
					bCheck = true, bMCheck = true, bChecked = O.nPublishChannel == tChannel.nChannel,
					fnAction = function()
						O.nPublishChannel = tChannel.nChannel
					end
				})
			end
			return t
		end,
		tip = {
			render = _L['left click to restart, right click to open setting.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	})
	-- 发布
	ui:Append('WndButton', {
		x = nW - 86, y = 10, w = 80, text = _L['publish'],
		onLClick = function() D.Echo() end,
		menuRClick = function()
			local t = { {
				szOption = _L['publish setting'], {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 3,
					fnAction = function() O.nPublish = 3 end,
					szOption = _L('publish top %d', 3)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 5,
					fnAction = function() O.nPublish = 5 end,
					szOption = _L('publish top %d', 5)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 10,
					fnAction = function() O.nPublish = 10 end,
					szOption = _L('publish top %d', 10)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 0,
					fnAction = function() O.nPublish = 0 end,
					szOption = _L['publish all']
				}, { bDevide = true }, {
					bCheck = true, bChecked = O.bPublishUnroll,
					fnAction = function() O.bPublishUnroll = not O.bPublishUnroll end,
					szOption = _L['publish unroll']
				}
			}, { bDevide = true } }
			for _, tChannel in ipairs(PUBLISH_CHANNELS) do
				table.insert( t, {
					szOption = tChannel.szName,
					rgb = tChannel.rgb,
					bCheck = true, bMCheck = true, bChecked = O.nPublishChannel == tChannel.nChannel,
					fnAction = function()
						O.nPublishChannel = tChannel.nChannel
					end
				} )
			end
			return t
		end,
		tip = {
			render = _L['left click to publish, right click to open setting.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
			offset = { x = -80 },
		},
	})
	-- 输出板
	m_uiBoard = ui:Append('WndScrollHandleBox',{
		x = 20,  y = 40, w = nW - 26, h = nH - 60,
		handleStyle = 3, text = _L['average score with out pole']
	})
	D.DrawBoard()
	X.BreatheCall('MY_RollMonitorRedraw', 1000, CheckBoardRedraw)
end

function PS.OnPanelDeactive()
	m_uiBoard = nil
	X.BreatheCall('MY_RollMonitorRedraw', false)
end

X.Panel.Register(_L['General'], 'RollMonitor', _L['roll monitor'], 287, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
