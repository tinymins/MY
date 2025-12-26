--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Tong')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 帮会成员相关接口
--------------------------------------------------------------------------------

-- 获取帮会成员列表
---@param bShowOffLine boolean @是否显示离线成员
---@param szSorter string @排序字段
---@param bAsc boolean @是否升序排序
---@return table @帮会成员列表
function X.GetTongMemberInfoList(bShowOffLine, szSorter, bAsc)
	if bShowOffLine == nil then bShowOffLine = false  end
	if szSorter     == nil then szSorter     = 'name' end
	if bAsc         == nil then bAsc         = true   end
	local aSorter = {
		['name'  ] = 'name'                    ,
		['level' ] = 'group'                   ,
		['school'] = 'development_contribution',
		['score' ] = 'score'                   ,
		['map'   ] = 'join_time'               ,
		['remark'] = 'last_offline_time'       ,
	}
	szSorter = aSorter[szSorter]
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- 后面两个参数不知道什么鬼
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

-- 获取帮会名称
---@param dwTongID number @帮会ID
---@param nGetType? number @0 表示逻辑直接请求，一般是刷新player对象头顶显示, -1兼容老插件，不发送事件
---@return string @帮会名称
function X.GetTongName(dwTongID, nGetType)
	local szTongName
	if X.IsNumber(dwTongID) and dwTongID > 0 and not X.IsClientPlayerCrossServer() then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, nGetType or 253)
	end
	return szTongName
end

-- 获取自身帮会名称
---@param nGetType? number @0 表示逻辑直接请求，一般是刷新player对象头顶显示, -1兼容老插件，不发送事件
---@return string @帮会名称
function X.GetClientPlayerTongName(nGetType)
	local dwTongID = (X.GetClientPlayer() or X.CONSTANT.EMPTY_TABLE).dwTongID
	return X.GetTongName(dwTongID, nGetType)
end

-- 获取帮会成员
---@param arg0 string | number @帮会成员ID或名称
---@return table @帮会成员信息
function X.GetTongMemberInfo(arg0)
	if not arg0 then
		return
	end
	return GetTongClient().GetMemberInfo(arg0)
end

-- 判断是否是帮会成员
---@param arg0 string | number @帮会成员ID或名称
---@return boolean @是否是帮会成员
function X.IsTongMember(arg0)
	return X.GetTongMemberInfo(arg0) and true or false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
