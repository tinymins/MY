--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : RSS 数据订阅
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/MY_RSS')
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_!Base'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '*') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local D = {}
local RSS_FILE = {'temporary/rss.jx3dat', X.PATH_TYPE.GLOBAL}
local RSS_DATA = X.LoadLUAData(RSS_FILE) or {}
local RSS_ADAPTER = {}
local RSS_DATA_CACHE = {}
local RSS_BASE_URL      = 'https://rss.j3cx.com'
local RSS_PULL_BASE_URL = 'https://pull.j3cx.com'
local RSS_PUSH_BASE_URL = 'https://push.j3cx.com'
local RSS_PAGE_BASE_URL = 'https://page.j3cx.com'

function D.Get(szKey)
	if X.IsNil(RSS_DATA) then
		return
	end
	if not RSS_DATA_CACHE[szKey] then
		local data = X.Clone(RSS_DATA[szKey])
		if RSS_ADAPTER[szKey] then
			data = RSS_ADAPTER[szKey](data)
		end
		RSS_DATA_CACHE[szKey] = data
	end
	return RSS_DATA_CACHE[szKey]
end

function D.RegisterAdapter(szKey, fnAdapter)
	RSS_ADAPTER[szKey] = fnAdapter
	RSS_DATA_CACHE[szKey] = nil
	if X.IsNil(RSS_DATA) then
		return
	end
	FireUIEvent('MY_RSS_UPDATE', szKey)
end

function D.Sync()
	local RSS_URL = {
		RSS_BASE_URL .. '/rss'
			.. '?l=' .. X.ENVIRONMENT.GAME_LANG
			.. '&L=' .. X.ENVIRONMENT.GAME_EDITION
			.. '&_=' .. GetCurrentTime(),
		RSS_PULL_BASE_URL .. '/config/all'
			.. '?l=' .. X.ENVIRONMENT.GAME_LANG
			.. '&L=' .. X.ENVIRONMENT.GAME_EDITION
			.. '&_=' .. GetCurrentTime(),
	}
	local tData, tDataIndex = {}, {}
	local nPending =  #RSS_URL
	do
		local nYear, nMonth, nDay, nHour, nMinute, nSecond = X.TimeToDate(GetCurrentTime())
		if nHour >= 7 then
			nDay = nDay + 1
		end
		tData.EXPIRES = X.DateToTime(nYear, nMonth, nDay, 7, 0, 0)
	end
	local function fnAction(nIndex, data)
		if X.IsTable(data) then
			if X.IsNumber(data.EXPIRES) then
				tData.EXPIRES = math.min(tData.EXPIRES or math.huge, data.EXPIRES)
			end
			for k, v in pairs(data) do
				if k ~= 'EXPIRES' and nIndex < (tDataIndex[k] or math.huge) then
					tData[k] = v
					tDataIndex[k] = nIndex
					RSS_DATA[k] = v
					RSS_DATA_CACHE[k] = nil
					FireUIEvent('MY_RSS_UPDATE', k)
				end
			end
		end
		nPending = nPending - 1
		if nPending > 0 then
			return
		end
		for k, _ in pairs(RSS_DATA) do
			if X.IsNil(tData[k]) then
				RSS_DATA[k] = nil
				RSS_DATA_CACHE[k] = nil
				FireUIEvent('MY_RSS_UPDATE', k)
			end
		end
		X.SaveLUAData(RSS_FILE, RSS_DATA)
	end
	for nIndex, szURL in ipairs(RSS_URL) do
		X.Ajax({
			url = szURL,
			success = function(html, status)
				local data = X.DecodeJSON(html)
				fnAction(nIndex, data)
			end,
			error = function(errMsg, status)
				fnAction(nIndex, nil)
			end,
		})
	end
end

X.RegisterInit('MY_RSS', function()
	if not X.IsNumber(RSS_DATA.EXPIRES) or RSS_DATA.EXPIRES < GetCurrentTime() then
		D.Sync()
	else
		FireUIEvent('MY_RSS_UPDATE')
	end
end)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RSS',
	exports = {
		{
			fields = {
				'RegisterAdapter',
				'Get',
				'Sync',
				PULL_BASE_URL = RSS_PULL_BASE_URL,
				PUSH_BASE_URL = RSS_PUSH_BASE_URL,
				PAGE_BASE_URL = RSS_PAGE_BASE_URL,
			},
			root = D,
		},
	},
}
MY_RSS = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
