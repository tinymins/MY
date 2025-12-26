--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Minimap')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 追加小地图标记
-- (void) X.UpdateMinimapArrowPoint(number dwType, KObject tar, number nF1[, number nF2])
-- (void) X.UpdateMinimapArrowPoint(number dwType, number nX, number nZ, number nF1[, number nF2])
-- dwType -- 类型 由UI脚本指定 (enum MINI_MAP_POINT)
-- tar    -- 目标对象 KPlayer，KNpc，KDoodad
-- nF1    -- 图标帧次
-- nF2    -- 箭头帧次，默认 48 就行
function X.UpdateMinimapArrowPoint(dwType, tar, nF1, nF2, nFadeOutTime, argX)
	local m = Station.Lookup('Normal/Minimap/Wnd_Minimap/Minimap_Map')
	if not m then
		return
	end
	local nX, nZ, dwID
	if X.IsNumber(tar) then
		dwID = GetStringCRC(tar .. nF1)
		nX, nZ = Scene_PlaneGameWorldPosToScene(tar, nF1)
		nF1, nF2, nFadeOutTime = nF2, nFadeOutTime, argX
	else
		dwID = tar.dwID
		nX, nZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	end
	m:UpdataArrowPoint(dwType, dwID, nF1, nF2 or 48, nX, nZ, nFadeOutTime or 16)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
