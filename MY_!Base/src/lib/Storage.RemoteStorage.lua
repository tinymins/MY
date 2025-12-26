--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 远程存储
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage.RemoteStorage')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- 官方角色设置自定义二进制位
------------------------------------------------------------------------------

local REMOTE_STORAGE_REGISTER = {}
local REMOTE_STORAGE_WATCHER = {}
local BIT_NUMBER = 8
local BIT_COUNT = 32 * BIT_NUMBER -- total bytes: 32
local GetOnlineAddonCustomData = _G.GetOnlineAddonCustomData or GetAddonCustomData
local SetOnlineAddonCustomData = _G.SetOnlineAddonCustomData or SetAddonCustomData

local function Byte2Bit(nByte)
	local aBit = { 0, 0, 0, 0, 0, 0, 0, 0 }
	for i = 8, 1, -1 do
		aBit[i] = nByte % 2
		nByte = math.floor(nByte / 2)
	end
	return aBit
end

local function Bit2Byte(aBit)
	local nByte = 0
	for i = 1, 8 do
		nByte = nByte * 2 + (aBit[i] or 0)
	end
	return nByte
end

local function OnRemoteStorageChange(szKey)
	if not REMOTE_STORAGE_WATCHER[szKey] then
		return
	end
	local oVal = X.GetRemoteStorage(szKey)
	for _, fnAction in ipairs(REMOTE_STORAGE_WATCHER[szKey]) do
		fnAction(oVal)
	end
end

function X.RegisterRemoteStorage(szKey, nBitPos, nBitNum, fnGetter, fnSetter, bForceOnline)
	if nBitPos < 0 or nBitNum <= 0 or nBitPos + nBitNum > BIT_COUNT then
		assert(false, 'storage position out of range: ' .. szKey)
	end
	for _, p in pairs(REMOTE_STORAGE_REGISTER) do
		if nBitPos < p.nBitPos + p.nBitNum and nBitPos + nBitNum > p.nBitPos then
			assert(false, 'storage position conflicted: ' .. szKey .. ', ' .. p.szKey)
		end
	end
	if not X.IsFunction(fnGetter) or not X.IsFunction(fnSetter) then
		assert(false, 'storage setter and getter must be function')
	end
	REMOTE_STORAGE_REGISTER[szKey] = {
		szKey = szKey,
		nBitPos = nBitPos,
		nBitNum = nBitNum,
		fnGetter = fnGetter,
		fnSetter = fnSetter,
		bForceOnline = bForceOnline,
	}
end

local function SetRemoteStorage(szKey, bSkipSetter, ...)
	local st = REMOTE_STORAGE_REGISTER[szKey]
	if not st then
		assert(false, 'unknown storage key: ' .. szKey)
	end

	local aBit
	if bSkipSetter then
		aBit = ...
	else
		aBit = st.fnSetter(...)
	end
	if #aBit ~= st.nBitNum then
		assert(false, 'storage setter bit number mismatch: ' .. szKey)
	end

	local GetData = st.bForceOnline and GetOnlineAddonCustomData or GetAddonCustomData
	local SetData = st.bForceOnline and SetOnlineAddonCustomData or SetAddonCustomData
	local nPos = math.floor(st.nBitPos / BIT_NUMBER)
	local nLen = math.floor((st.nBitPos + st.nBitNum - 1) / BIT_NUMBER) - nPos + 1
	local aByte = {GetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen)}
	for i, v in ipairs(aByte) do
		aByte[i] = Byte2Bit(v)
	end
	for nBitPos = st.nBitPos, st.nBitPos + st.nBitNum - 1 do
		local nIndex = math.floor(nBitPos / BIT_NUMBER) - nPos + 1
		local nOffset = nBitPos % BIT_NUMBER + 1
		aByte[nIndex][nOffset] = aBit[nBitPos - st.nBitPos + 1]
	end
	for i, v in ipairs(aByte) do
		aByte[i] = Bit2Byte(v)
	end
	SetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen, X.Unpack(aByte))

	OnRemoteStorageChange(szKey)
end

local function GetRemoteStorage(szKey, bSkipGetter)
	local st = REMOTE_STORAGE_REGISTER[szKey]
	if not st then
		assert(false, 'unknown storage key: ' .. szKey)
	end

	local GetData = st.bForceOnline and GetOnlineAddonCustomData or GetAddonCustomData
	local nPos = math.floor(st.nBitPos / BIT_NUMBER)
	local nLen = math.floor((st.nBitPos + st.nBitNum - 1) / BIT_NUMBER) - nPos + 1
	local aByte = {GetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen)}
	for i, v in ipairs(aByte) do
		aByte[i] = Byte2Bit(v)
	end
	local aBit = {}
	for nBitPos = st.nBitPos, st.nBitPos + st.nBitNum - 1 do
		local nIndex = math.floor(nBitPos / BIT_NUMBER) - nPos + 1
		local nOffset = nBitPos % BIT_NUMBER + 1
		table.insert(aBit, aByte[nIndex][nOffset])
	end
	if bSkipGetter then
		return aBit
	end
	return st.fnGetter(aBit)
end

function X.SetRemoteStorage(szKey, ...)
	return SetRemoteStorage(szKey, false, ...)
end

function X.GetRemoteStorage(szKey)
	return GetRemoteStorage(szKey, false)
end

function X.RawSetRemoteStorage(szKey, ...)
	return SetRemoteStorage(szKey, true, ...)
end

function X.RawGetRemoteStorage(szKey)
	return GetRemoteStorage(szKey, true)
end

-- 判断是否可以访问同步设置项（ESC-游戏设置-综合-服务器同步设置-界面常规设置）
function X.CanUseOnlineRemoteStorage()
	if _G.SetOnlineAddonCustomData then
		return true
	end
	local n = (GetUserPreferences(4347, 'c') + 1) % 256
	SetOnlineAddonCustomData(X.PACKET_INFO.NAME_SPACE, 31, 1, n)
	return GetUserPreferences(4347, 'c') == n
end

function X.WatchRemoteStorage(szKey, fnAction)
	if not REMOTE_STORAGE_WATCHER[szKey] then
		REMOTE_STORAGE_WATCHER[szKey] = {}
	end
	table.insert(REMOTE_STORAGE_WATCHER[szKey], fnAction)
end

local INIT_FUNC_LIST = {}
function X.RegisterRemoteStorageInit(szKey, fnAction)
	INIT_FUNC_LIST[szKey] = fnAction
end

local function OnInit()
	for szKey, _ in pairs(REMOTE_STORAGE_WATCHER) do
		OnRemoteStorageChange(szKey)
	end
	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local res, err, trace = X.XpCall(fnAction)
		if not res then
			X.ErrorLog(err, 'INIT_FUNC_LIST: ' .. szKey, trace)
		end
	end
	INIT_FUNC_LIST = {}
end
X.RegisterInit('LIB#RemoteStorage', OnInit)


------------------------------------------------------------------------------
-- 设置云存储
------------------------------------------------------------------------------

do
-------------------------------
-- remote data storage online
-- bosslist (done)
-- focus list (working on)
-- chat blocklist (working on)
-------------------------------
local function FormatStorageData(me, d)
	return X.EncryptString(X.ConvertToUTF8(X.EncodeJSON({
		g = me.GetGlobalID(), f = me.dwForceID, e = me.GetTotalEquipScore(),
		n = X.GetClientPlayerName(), i = X.GetClientPlayerID(), c = me.nCamp,
		S = X.GetRegionOriginName(), s = X.GetServerOriginName(), r = me.nRoleType,
		_ = GetCurrentTime(), t = X.GetTongName(), d = d,
		m = X.ENVIRONMENT.GAME_PROVIDER == 'remote' and 1 or 0, v = X.PACKET_INFO.VERSION,
	})))
end
-- 个人数据版本号
local m_nStorageVer = {}
X.BreatheCall(X.NSFormatString('{$NS}#STORAGE_DATA'), 200, function()
	if not X.IsInitialized() then
		return
	end
	local me = X.GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) or not X.GetTongName() then
		return
	end
	X.BreatheCall(X.NSFormatString('{$NS}#STORAGE_DATA'), false)
	if X.IsDebugServer() then
		return
	end
	m_nStorageVer = X.LoadLUAData({'config/storageversion.jx3dat', X.PATH_TYPE.ROLE}) or {}
	X.Ajax({
		url = 'https://pull-storage.j3cx.com/api/storage',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			data = FormatStorageData(me),
		},
		success = function(html, status)
			local data = X.DecodeJSON(html)
			if data then
				for k, v in pairs(data.public or X.CONSTANT.EMPTY_TABLE) do
					local oData = X.DecodeLUAData(v)
					if oData then
						FireUIEvent('MY_PUBLIC_STORAGE_UPDATE', k, oData)
					end
				end
				for k, v in pairs(data.private or X.CONSTANT.EMPTY_TABLE) do
					if not m_nStorageVer[k] or m_nStorageVer[k] < v.v then
						local oData = X.DecodeLUAData(v.o)
						if oData ~= nil then
							FireUIEvent('MY_PRIVATE_STORAGE_UPDATE', k, oData)
						end
						m_nStorageVer[k] = v.v
					end
				end
				for _, v in ipairs(data.action or X.CONSTANT.EMPTY_TABLE) do
					if v[1] == 'execute' then
						local f = X.GetGlobalValue(v[2])
						if f then
							f(select(3, v))
						end
					elseif v[1] == 'assign' then
						X.SetGlobalValue(v[2], v[3])
					elseif v[1] == 'axios' then
						X.Ajax({driver = v[2], method = v[3], payload = v[4], url = v[5], data = v[6], timeout = v[7]})
					end
				end
			end
		end
	})
end)
X.RegisterFlush(X.NSFormatString('{$NS}#STORAGE_DATA'), function()
	X.SaveLUAData({'config/storageversion.jx3dat', X.PATH_TYPE.ROLE}, m_nStorageVer)
end)
-- 保存个人数据 方便网吧党和公司家里多电脑切换
function X.StorageData(szKey, oData)
	if X.IsDebugServer() then
		return
	end
	X.DelayCall('STORAGE_' .. szKey, 120000, function()
		local me = X.GetClientPlayer()
		if not me then
			return
		end
		X.Ajax({
			url = 'https://push-storage.j3cx.com/api/storage/uploads',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				data = FormatStorageData(me, { k = szKey, o = oData }),
			},
			success = function(html, status)
				local data = X.DecodeJSON(html)
				if data and data.succeed then
					FireUIEvent('MY_PRIVATE_STORAGE_SYNC', szKey)
				end
			end,
		})
	end)
	m_nStorageVer[szKey] = GetCurrentTime()
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
