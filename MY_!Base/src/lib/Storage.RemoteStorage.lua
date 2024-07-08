--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 远程存储
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
