--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Distance')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local O = X.CreateUserSettingsModule('LIB', _L['System'], {
	szDistanceType = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.OneOf('gwwean', 'euclidean','plane'),
		xDefaultValue = 'gwwean',
	},
})
function X.GetGlobalDistanceType()
	return O.szDistanceType
end

function X.SetGlobalDistanceType(szType)
	O.szDistanceType = szType
end

function X.GetDistanceTypeList(bGlobal)
	local t = {
		{ szType = 'gwwean', szText = _L.DISTANCE_TYPE['gwwean'] },
		{ szType = 'euclidean', szText = _L.DISTANCE_TYPE['euclidean'] },
		{ szType = 'plane', szText = _L.DISTANCE_TYPE['plane'] },
	}
	if (bGlobal) then
		table.insert(t, { szType = 'global', szText = _L.DISTANCE_TYPE['global'] })
	end
	return t
end

function X.GetDistanceTypeMenu(bGlobal, eValue, fnAction)
	local t = {}
	for _, p in ipairs(X.GetDistanceTypeList(true)) do
		local t1 = {
			szOption = p.szText,
			bCheck = true, bMCheck = true,
			bChecked = p.szType == eValue,
			UserData = p,
			fnAction = fnAction,
		}
		if p.szType == 'global' then
			t1.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t1.nFrame = 105
			t1.nMouseOverFrame = 106
			t1.szLayer = 'ICON_RIGHTMOST'
			t1.fnClickIcon = function()
				X.ShowPanel()
				X.SwitchTab('GlobalConfig')
				X.UI.ClosePopupMenu()
			end
		end
		table.insert(t, t1)
	end
	return t
end
end

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- X.GetDistance(OObject[, szType])
-- X.GetDistance(nX, nY)
-- X.GetDistance(nX, nY, nZ[, szType])
-- X.GetDistance(OObject1, OObject2[, szType])
-- X.GetDistance(OObject1, nX2, nY2)
-- X.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- X.GetDistance(nX1, nY1, nX2, nY2)
-- X.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
--         'global'   : 使用全局配置
function X.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if X.IsTable(arg0) then
		arg0 = X.GetObject(X.Unpack(arg0))
		if not arg0 then
			return
		end
	end
	if X.IsTable(arg1) then
		arg1 = X.GetObject(X.Unpack(arg1))
		if not arg1 then
			return
		end
	end
	if X.IsUserdata(arg0) then -- OObject -
		nX1, nY1, nZ1 = arg0.nX, arg0.nY, arg0.nZ
		if X.IsUserdata(arg1) then -- OObject1, OObject2
			nX2, nY2, nZ2, szType = arg1.nX, arg1.nY, arg1.nZ, arg2
		elseif X.IsNumber(arg1) and X.IsNumber(arg2) then -- OObject1, nX2, nY2
			if X.IsNumber(arg3) then -- OObject1, nX2, nY2, nZ2[, szType]
				nX2, nY2, nZ2, szType = arg1, arg2, arg3, arg4
			else -- OObject1, nX2, nY2[, szType]
				nX2, nY2, szType = arg1, arg2, arg3
			end
		else -- OObject[, szType]
			local me = X.GetClientPlayer()
			nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg1
		end
	elseif X.IsNumber(arg0) and X.IsNumber(arg1) then -- nX1, nY1 -
		if X.IsNumber(arg2) then
			if X.IsNumber(arg3) then
				if X.IsNumber(arg4) and X.IsNumber(arg5) then -- nX1, nY1, nZ1, nX2, nY2, nZ2[, szType]
					nX1, nY1, nZ1, nX2, nY2, nZ2, szType = arg0, arg1, arg2, arg3, arg4, arg5, arg6
				else -- nX1, nY1, nX2, nY2[, szType]
					nX1, nY1, nX2, nY2, szType = arg0, arg1, arg2, arg3, arg4
				end
			else -- nX1, nY1, nZ1[, szType]
				local me = X.GetClientPlayer()
				nX1, nY1, nZ1, nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg0, arg1, arg2, arg3
			end
		else -- nX1, nY1
			local me = X.GetClientPlayer()
			nX1, nY1, nX2, nY2 = me.nX, me.nY, arg0, arg1
		end
	end
	if not szType or szType == 'global' then
		szType = X.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return math.max(math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, math.floor(math.abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

-- 获取两个3D坐标点之间的距离
---@param nX1 userdata @点1的X坐标
---@param nY1 userdata @点1的Y坐标
---@param nZ1 userdata @点1的Z坐标
---@param nX2 userdata @点2的X坐标
---@param nY2 userdata @点2的Y坐标
---@param nZ2 userdata @点2的Z坐标
---@param szType? string @距离计算方式：'euclidean': 欧氏距离 (default)； 'plane': 平面距离； 'gwwean': 郭氏距离； 'global': 使用全局配置；
---@return number @距离计算结果
function X.Get3DPointDistance(nX1, nY1, nZ1, nX2, nY2, nZ2, szType)
	if not szType or szType == 'global' then
		szType = X.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return math.max(math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, math.floor(math.abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

-- 获取两个2D坐标点之间的距离
---@param nX1 userdata @点1的X坐标
---@param nY1 userdata @点1的Y坐标
---@param nX2 userdata @点2的X坐标
---@param nY2 userdata @点2的Y坐标
---@param szType? string @距离计算方式：'euclidean': 欧氏距离 (default)； 'plane': 平面距离； 'gwwean': 郭氏距离； 'global': 使用全局配置；
---@return number @距离计算结果
function X.Get2DPointDistance(nX1, nY1, nX2, nY2, szType)
	return X.Get3DPointDistance(nX1, nY1, 0, nX2, nY2, 0, szType)
end

-- 获取两个目标之间的距离
---@param kTar1 userdata @目标1
---@param kTar2 userdata @目标2
---@param szType? string @距离计算方式：'euclidean': 欧氏距离 (default)； 'plane': 平面距离； 'gwwean': 郭氏距离； 'global': 使用全局配置；
---@return number @距离计算结果
function X.GetTargetDistance(kTar1, kTar2, szType)
	return X.Get3DPointDistance(kTar1.nX, kTar1.nY, kTar1.nZ, kTar2.nX, kTar2.nY, kTar2.nZ, szType)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
