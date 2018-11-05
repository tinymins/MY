--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 基础库加载完成处理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
local ns = MY
MY = setmetatable({}, {
	__metatable = true,
	__index = ns,
	__newindex = function() assert(false, 'DO NOT modify MY after initialized!!!') end
})

FireUIEvent('MY_BASE_LOADING_END')
