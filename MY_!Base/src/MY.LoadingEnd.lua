--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 基础库加载完成处理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
local MY_ORG = MY
if IsDebugClient() then
function MY_DebugSetVal(szKey, oVal)
	MY_ORG[szKey] = oVal
end
end

MY = setmetatable({}, {
	__metatable = true,
	__index = MY_ORG,
	__newindex = function() assert(false, 'DO NOT modify MY after initialized!!!') end
})

FireUIEvent('MY_BASE_LOADING_END')

-- 修复剑心导致玩家头像越来越大的问题。。。
do
local nInitWidth, nFinalWidth
MY.RegisterEvent('ON_FRAME_CREATE.FixJXPlayer', function()
	if arg0:GetName() == 'Player' then
		nInitWidth = arg0:GetW()
	end
end)
local function RevertWidth()
	local frame = Station.Lookup('Normal/Player')
	if not frame or not nInitWidth then
		return
	end
	nFinalWidth = frame:GetW()
	frame:SetW(nInitWidth)
end
local function ApplyWidth()
	local frame = Station.Lookup('Normal/Player')
	if not frame or not nFinalWidth then
		return
	end
	frame:SetW(nFinalWidth)
end
MY.RegisterReload('FixJXPlayer', RevertWidth)
MY.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE.FixJXPlayer', RevertWidth)
MY.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE.FixJXPlayer', ApplyWidth)
end
