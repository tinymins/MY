--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 检测附近共战
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {}

local tChannels = {
	{ nChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS, szName = _L['system channel'], rgb = GetMsgFontColor('MSG_SYS'   , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM     , szName = _L['team channel'  ], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID     , szName = _L['raid channel'  ], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG     , szName = _L['tong channel'  ], rgb = GetMsgFontColor('MSG_GUILD' , true) },
}
function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndButton', {
		x = W - 140, y = y, w = 120,
		text = _L['check nearby gongzhan'],
		onlclick = function()
			if LIB.BreatheCall('MY_GongzhanCheck') then
				LIB.BreatheCall('MY_GongzhanCheck', false)
			else
				-- 逻辑：两次遍历附近的人 第一次同步数据 第二次输出数据
				local nChannel = O.nGongzhanPublishChannel or PLAYER_TALK_CHANNEL.LOCAL_SYS
				local dwTarType, dwTarID = LIB.GetTarget()
				local aPendingID = LIB.GetNearPlayerID() -- 等待扫描的玩家
				local aProcessID = Clone(aPendingID) -- 等待输出的玩家
				local aGongZhan = {} -- 扫描到的共战数据
				local nCount, nIndex = #aPendingID, 1
				local function Echo(nIndex, nCount)
					LIB.Topmsg(_L('Scanning gongzhan: %d/%d', nIndex, nCount))
				end
				LIB.RenderCall('MY_GongzhanCheck', function()
					local bTermial, bStep
					if nIndex <= nCount then -- 获取下一个有效的扫描目标
						local dwID = aPendingID[nIndex]
						local tar = GetPlayer(dwID)
						while not tar and nIndex <= nCount do
							Echo(nIndex, nCount * 2 + 1)
							nIndex = nIndex + 1
							dwID = aPendingID[nIndex]
							tar = GetPlayer(dwID)
						end
						if tar then
							local dwType, dwID = LIB.GetTarget()
							if dwType ~= TARGET.PLAYER or dwID ~= tar.dwID then -- 设置目标同步BUFF数据
								LIB.SetTarget(TARGET.PLAYER, tar.dwID)
							else
								Echo(nIndex, nCount * 2 + 1)
								nIndex = nIndex + 1
							end
						end
					elseif nIndex <= nCount * 2 then -- 获取下一个有效的输出目标
						local dwID = aProcessID[nIndex - nCount]
						local tar = GetPlayer(dwID)
						while not tar and nIndex <= nCount * 2 do
							Echo(nIndex, nCount * 2 + 1)
							nIndex = nIndex + 1
							dwID = aProcessID[nIndex - nCount]
							tar = GetPlayer(dwID)
						end
						if tar then
							local dwType, dwID = LIB.GetTarget()
							if dwType ~= TARGET.PLAYER or dwID ~= tar.dwID then -- 先设置目标才能获取BUFF数据
								LIB.SetTarget(TARGET.PLAYER, tar.dwID)
							else
								-- 检测是否有共战
								local aBuff, nBuffCount, buff = LIB.GetBuffList(tar)
								for i = 1, nBuffCount do
									buff = aBuff[i]
									if (not buff.bCanCancel) and find(Table_GetBuffName(buff.dwID, buff.nLevel), _L['GongZhan']) ~= nil then
										local info = Table_GetBuff(buff.dwID, buff.nLevel)
										if info and info.bShow ~= 0 then
											insert(aGongZhan, { szName = tar.szName, nTime = (buff.nEndFrame - GetLogicFrameCount()) / 16 })
										end
									end
								end
								Echo(nIndex, nCount * 2 + 1)
								nIndex = nIndex + 1
							end
						end
					else
						Echo(nIndex, nCount * 2 + 1)
						LIB.Talk(nChannel, _L['------------------------------------'])
						for _, r in ipairs(aGongZhan) do
							LIB.Talk(nChannel, _L('Detected [%s] has GongZhan buff for %s.', r.szName, LIB.FormatTimeCounter(r.nTime, nil, 2)))
						end
						LIB.Talk(nChannel, _L('Nearby GongZhan Total Count: %d.', #aGongZhan))
						LIB.Talk(nChannel, _L['------------------------------------'])
						LIB.SetTarget(dwTarType, dwTarID)
						return 0
					end
				end)
			end
		end,
		rmenu = function()
			local t = { { szOption = _L['send to ...'], bDisable = true }, { bDevide = true } }
			for _, tChannel in ipairs(tChannels) do
				table.insert( t, {
					szOption = tChannel.szName,
					rgb = tChannel.rgb,
					bCheck = true, bMCheck = true, bChecked = O.nGongzhanPublishChannel == tChannel.nChannel,
					fnAction = function()
						O.nGongzhanPublishChannel = tChannel.nChannel
					end
				} )
			end
			return t
		end,
	})
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_GongzhanCheck = LIB.GeneGlobalNS(settings)
end
