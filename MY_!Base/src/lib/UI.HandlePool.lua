--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : HandlePool
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.HandlePool')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

---------------------------------------------------------------------
-- 可重复利用的简易 Handle 元件缓存池
---------------------------------------------------------------------
local HandlePool = {}
HandlePool.__index = HandlePool
-- construct
function HandlePool:ctor(handle, xml)
	local oo = {}
	setmetatable(oo, self)
	oo.handle, oo.xml = handle, xml
	handle.nFreeCount = 0
	handle:Clear()
	return oo
end

-- clear
function HandlePool:Clear()
	self.handle:Clear()
	self.handle.nFreeCount = 0
end

-- new item
function HandlePool:New()
	local handle = self.handle
	local nCount = handle:GetItemCount()
	if handle.nFreeCount > 0 then
		for i = nCount - 1, 0, -1 do
			local item = handle:Lookup(i)
			if item.bFree then
				item.bFree = false
				handle.nFreeCount = handle.nFreeCount - 1
				return item
			end
		end
		handle.nFreeCount = 0
	else
		handle:AppendItemFromString(self.xml)
		local item = handle:Lookup(nCount)
		item.bFree = false
		return item
	end
end

-- remove item
function HandlePool:Remove(item)
	if item:IsValid() then
		self.handle:RemoveItem(item)
	end
end

-- free item
function HandlePool:Free(item)
	if item:IsValid() then
		self.handle.nFreeCount = self.handle.nFreeCount + 1
		item.bFree = true
		item:SetName('')
		item:Hide()
	end
end

function HandlePool:GetAllItem(bShow)
	local t = {}
	for i = self.handle:GetItemCount() - 1, 0, -1 do
		local item = self.handle:Lookup(i)
		if bShow and item:IsVisible() or not bShow then
			table.insert(t, item)
		end
	end
	return t
end
-- public api, create pool
-- (class) X.UI.HandlePool(userdata handle, string szXml)
X.UI.HandlePool = setmetatable({}, { __call = function(me, ...) return HandlePool:ctor( ... ) end, __metatable = true, __newindex = function() end })

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
