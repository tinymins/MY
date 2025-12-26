--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : LUA 基础函数
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------

local RANDOM_VALUE = nil
-- 保证与上一次结果不同的随机函数，当传入上下限值时候不保证
---@param nMin number @下限
---@param nMax number @上限
---@return number @随机结果
function X.Random(...)
	-- init
	if not RANDOM_VALUE then
		-- math.randomseed(os.clock() * math.random(os.time()))
		math.randomseed(GetTickCount() * math.random(GetCurrentTime()))
	end
	-- do random
	local fValue = math.random()
	while fValue == RANDOM_VALUE do
		X.OutputDebugMessage(
			X.PACKET_INFO.NAME_SPACE,
			'Random: math.random get same value: ' .. fValue
				.. ', this is abnormal, you should be attention about this!',
			X.DEBUG_LEVEL.ERROR
		)
		fValue = math.random()
	end
	RANDOM_VALUE = fValue
	-- finalize
	local nArgs = select('#', ...)
	if nArgs == 0 or nArgs > 2 then
		return fValue
	end
	local nMin, nMax = 1, 1
	if nArgs == 1 then
		nMin, nMax = 1, ...
	elseif nArgs == 2 then
		nMin, nMax = ...
	end
	return math.floor(fValue * (nMax - nMin)) + nMin
end

-- 获取调用栈
---@param str? string @调用栈附加字符串
---@return string @完整调用栈
function X.GetTraceback(str)
	local traceback = debug and debug.traceback and debug.traceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	if traceback then
		if str then
			str = str .. '\n' .. traceback
		else
			str = traceback
		end
	end
	return str or ''
end

-- 三元运算
---@generic T1, T2
---@param condition boolean @条件
---@param trueValue T1 @条件为真时的值
---@param falseValue T2 @条件为假时的值
---@return T1 | T2 @条件为真时的值，否则为条件为假时的值
function X.IIf(condition, trueValue, falseValue)
	if condition then
		return trueValue
	end
	return falseValue
end

-- 克隆数据
---@generic T
---@param var T @需要克隆的数据
---@return T @克隆后的数据
function X.Clone(var)
	if type(var) == 'table' then
		local ret = {}
		for k, v in pairs(var) do
			ret[X.Clone(k)] = X.Clone(v)
		end
		return ret
	else
		return var
	end
end

-- 读取数据
---@param var any @需要读取的数据
---@param keys string | string[] @需要读取的键
---@param dft any @默认值
---@return any @读取后的数据
function X.Get(var, keys, dft)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		for _, k in ipairs(keys) do
			if type(var) == 'table' then
				var, res = var[k], true
			else
				var, res = dft, false
				break
			end
		end
	end
	if var == nil then
		var, res = dft, false
	end
	return var, res
end

-- 设置数据
---@param var any @需要设置的数据
---@param keys string | string[] @需要设置的键
---@param val any @需要设置的值
---@return void
function X.Set(var, keys, val)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		local n = #keys
		for i = 1, n do
			local k = keys[i]
			if type(var) == 'table' then
				if i == n then
					var[k], res = val, true
				else
					if var[k] == nil then
						var[k] = {}
					end
					var = var[k]
				end
			else
				break
			end
		end
	end
	return res
end

-- 打包数据
---@vararg any @需要打包的数据
---@return table @打包后的数据
X.Pack = table.pack or function(...)
	return { n = select("#", ...), ... }
end

-- 拆包数据
---@param t table @需要拆包的数据
---@param i number @拆包的开始位置
---@param j number @拆包的结束位置
---@return any @拆包后的数据
X.Unpack = table.unpack or unpack

-- 数据长度
---@param t table | string @需要计算长度的数据
---@return number @数据长度
function X.Len(t)
	if type(t) == 'table' then
		return t.n or #t
	end
	return #t
end

-- 合并数据
---@generic T
---@vararg T @需要合并的数据
---@return T @合并后的数据
function X.Assign(t, ...)
	for index = 1, select('#', ...) do
		local t1 = select(index, ...)
		if type(t1) == 'table' then
			for k, v in pairs(t1) do
				t[k] = v
			end
		end
	end
	return t
end

-- 判断是否为空
---@param var any @需要判断的数据
---@return boolean @是否为空
function X.IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end

-- 深度判断相等
---@param var1 any @需要判断的数据1
---@param var2 any @需要判断的数据2
---@return boolean @是否相等
function X.IsEquals(var1, var2)
	if var1 == var2 then
		return true
	end
	if type(var1) ~= type(var2) then
		return false
	end
	local tp = type(var1)
	if tp == 'number' then
		if X.IsHugeNumber(var1) and X.IsHugeNumber(var2) then
			return true
		end
		return false
	end
	if tp == 'table' then
		local t = {}
		for k, v in pairs(var1) do
			if X.IsEquals(var1[k], var2[k]) then
				t[k] = true
			else
				return false
			end
		end
		for k, v in pairs(var2) do
			if not t[k] then
				return false
			end
		end
		return true
	end
	return false
end

-- 数组随机
---@param var any[] @需要随机的数组
---@return any @随机的数据
function X.RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[math.random(1, #var)]
	end
end

-- 判断数组是否包含某值
---@param var table @需要判断的表
---@param val any @需要判断的值
---@return boolean @是否包含
function X.Contains(var, val)
	if X.IsTable(var) then
		local iter = X.IsArray(var) and ipairs or pairs
		for _, v in iter(var) do
			if v == val then
				return true
			end
		end
	end
	return false
end

-- 根据回调查找匹配的元素
---@param var table @需要查找的表
---@param predicate fun(value: any, key: any, source: table): boolean @判断函数
---@return any @匹配的元素或 nil
function X.Find(var, predicate)
	if not X.IsTable(var) or not X.IsFunction(predicate) then
		return nil
	end
	local iter = X.IsArray(var) and ipairs or pairs
	for key, value in iter(var) do
		if predicate(value, key, var) then
			return value
		end
	end
	return nil
end

-- 判断数据是否为数组
---@param var any @需要判断的数据
---@return boolean @是否为数组
function X.IsArray(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return false
		end
		i = i + 1
	end
	return true
end

-- 判断数据是否为字典
---@param var any @需要判断的数据
---@return boolean @是否为字典
function X.IsDictionary(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return true
		end
		i = i + 1
	end
	return false
end

-- 判断数据是否为空
---@param var any @需要判断的数据
---@return boolean @是否为空
function X.IsNil(var)
	return type(var) == 'nil'
end

-- 判断数据是否为表
---@param var any @需要判断的数据
---@return boolean @是否为表
function X.IsTable(var)
	return type(var) == 'table'
end

-- 判断数据是否为数字
---@param var any @需要判断的数据
---@return boolean @是否为数字
function X.IsNumber(var)
	return type(var) == 'number'
end

-- 判断数据是否为正数
---@param var any @需要判断的数据
---@return boolean @是否为正数
function X.IsPositiveNumber(var)
	return X.IsNumber(var) and var > 0
end

-- 判断数据是否为字符串
---@param var any @需要判断的数据
---@return boolean @是否为字符串
function X.IsString(var)
	return type(var) == 'string'
end

-- 判断数据是否为布尔值
---@param var any @需要判断的数据
---@return boolean @是否为布尔值
function X.IsBoolean(var)
	return type(var) == 'boolean'
end

-- 判断数据是否为函数
---@param var any @需要判断的数据
---@return boolean @是否为函数
function X.IsFunction(var)
	return type(var) == 'function'
end

-- 判断数据是否为 C++ 对象
---@param var any @需要判断的数据
---@return boolean @是否为 C++ 对象
function X.IsUserdata(var)
	return type(var) == 'userdata'
end

-- 判断数据是否为无穷数
---@param var any @需要判断的数据
---@return boolean @是否为无穷数
function X.IsHugeNumber(var)
	return X.IsNumber(var) and not (var < math.huge and var > -math.huge)
end

-- 判断数据是否为有效的界面元素操作指针
---@param var any @需要判断的数据
---@return boolean @是否为有效的界面元素操作指针
function X.IsElement(var)
	return type(var) == 'table' and var.IsValid
		and var:IsValid()
		or false
end

-- 判断数据是否为角色唯一ID
---@param var any @需要判断的数据
---@return boolean @是否为角色唯一ID
function X.IsGlobalID(var)
	return X.IsString(var) and var ~= '' and var ~= '0' and string.find(var, '^[0-9]+$')
		and true
		or false
end

-- 判断数据是否为URL
---@param var any @需要判断的数据
---@return boolean @是否为URL
function X.IsURL(var)
	return X.IsString(var) and var:sub(1, 8):lower() == 'https://' or var:gsub(1, 7):lower() == 'http://'
end

-- 表数据设为只读
---@generic T
---@param t T 想要设为只读的表
---@return T 设为只读的表
function X.FreezeTable(t)
	return setmetatable({}, {
		__index     = t,
		__newindex  = function() assert(false, 'table is readonly\n') end,
		__metatable = {
			const_table = t,
		},
	})
end

-- 表数据递归设为只读
---@generic T
---@param t T 想要设为只读的表
---@return T 设为只读的表
function X.RecursiveFreezeTable(t)
	local p = setmetatable({}, { __index = t })
	for k, v in pairs(t) do
		if type(v) == 'table' then
			p[k] = X.RecursiveFreezeTable(v)
		else
			p[k] = v
		end
	end
	return setmetatable({}, {
		__index     = p,
		__newindex  = function() assert(false, 'table is readonly\n') end,
		__metatable = {
			const_table = t,
		},
	})
end

-- 表数据设为懒加载
---@generic T
---@param t T @想要设为懒加载的表
---@param _keyLoader table<string, fun(k: string): any> @表数据的懒加载函数
---@param fallbackLoader fun(k: string): any @表数据的通用懒加载函数
---@return T @设为懒加载的表
function X.LazyLoadingTable(t, _keyLoader, fallbackLoader)
	local keyLoader = X.Clone(_keyLoader)
	local p = setmetatable({}, { __index = t })
	for k, v in pairs(t) do
		p[k] = v
	end
	return setmetatable(p, {
		__index = function(t, k)
			local loader = keyLoader[k]
			if loader then
				keyLoader[k] = nil
				if not next(keyLoader) then
					setmetatable(t, nil)
				end
			else
				loader = fallbackLoader
			end
			if loader then
				local v = loader(k)
				t[k] = v
				return v
			end
		end,
	})
end

-- 键值对数组转对象
---@param kvp any[][] @键值对数组
---@return table @对象
function X.KvpToObject(kvp)
	local t = {}
	for _, v in ipairs(kvp) do
		if not X.IsNil(v[1]) then
			t[v[1]] = v[2]
		end
	end
	return t
end

-- 列表转列表值为键的对象
---@param arr any[] @列表
---@return table @对象
function X.ArrayToObject(arr)
	if not arr then
		return
	end
	local t = {}
	for k, v in pairs(arr) do
		t[v] = true
	end
	return t
end

-- 翻转对象键值
---@param obj table @对象
---@return table @对象
function X.FlipObjectKV(obj)
	local t = {}
	for k, v in pairs(obj) do
		t[v] = k
	end
	return t
end

-- 创建数据补丁
---@param oBase any @原始数据
---@param oData any @目标数据
---@return table @补丁数据
function X.GetPatch(oBase, oData)
	-- dictionary patch
	if X.IsDictionary(oData) or (X.IsDictionary(oBase) and X.IsTable(oData) and X.IsEmpty(oData)) then
		-- dictionary raw value patch
		if not X.IsTable(oBase) then
			return { v = oData }
		end
		-- dictionary children patch
		local tKeys, bDiff = {}, false
		local oPatch = {}
		for k, v in pairs(oData) do
			local patch = X.GetPatch(oBase[k], v)
			if not X.IsNil(patch) then
				bDiff = true
				table.insert(oPatch, { k = k, v = patch })
			end
			tKeys[k] = true
		end
		for k, v in pairs(oBase) do
			if not tKeys[k] then
				bDiff = true
				table.insert(oPatch, { k = k, v = nil })
			end
		end
		if not bDiff then
			return nil
		end
		return oPatch
	end
	if not X.IsEquals(oBase, oData) then
		-- nil value patch
		if X.IsNil(oData) then
			return { t = 'nil' }
		end
		-- table value patch
		if X.IsTable(oData) then
			return { v = oData }
		end
		-- other patch value
		return oData
	end
	-- empty patch
	return nil
end

-- 数据应用补丁
---@param oBase any @原始数据
---@param oPatch any @补丁数据
---@param bNew boolean @是否创建新的数据（而不是修改传入的数据）
---@return any @应用后的数据
function X.ApplyPatch(oBase, oPatch, bNew)
	if bNew ~= false then
		oBase = X.Clone(oBase)
		oPatch = X.Clone(oPatch)
	end
	-- patch in dictionary type can only be a special value patch
	if X.IsDictionary(oPatch) then
		-- nil value patch
		if oPatch.t == 'nil' then
			return nil
		end
		-- raw value patch
		if not X.IsNil(oPatch.v) then
			return oPatch.v
		end
	end
	-- dictionary patch
	if X.IsTable(oPatch) and X.IsDictionary(oPatch[1]) then
		if not X.IsTable(oBase) then
			oBase = {}
		end
		for _, patch in ipairs(oPatch) do
			if X.IsNil(patch.v) then
				oBase[patch.k] = nil
			else
				oBase[patch.k] = X.ApplyPatch(oBase[patch.k], patch.v, false)
			end
		end
		return oBase
	end
	-- empty patch
	if X.IsNil(oPatch) then
		return oBase
	end
	-- other patch value
	return oPatch
end

-- 通过标题部分创建标题，默认使用 · 连接分段
---@param aParts string[] @分段标题
---@param szConnect? string @连接字符串
---@return string @创建后的完整标题
function X.MakeCaption(aParts, szConnect)
	szConnect = szConnect or g_tStrings.STR_CONNECT
	return table.concat(aParts, szConnect)
end

-----------------------------------------------
-- 选代器
-----------------------------------------------

---@type fun(t: table): number @获取只读表长度
X.count_c  = count_c

---@type fun(t: table): fun(tab: table, index: number), table, number @遍历只读表
X.pairs_c  = pairs_c

---@type fun(t: table): fun(tab: table, index: number), table, number @倒序遍历只读数组
X.ipairs_c = ipairs_c

local function IpairsIterR(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end

-- 数组逆序选代器 -- for i, v in X.ipairs_r(data) do
---@param tab table @需要迭代的表
---@return fun(tab: table, index: number), table, number @迭代函数
function X.ipairs_r(tab)
	return IpairsIterR, tab, #tab + 1
end

local function SafePairsIter(a, i)
	i = i + 1
	if a[i] then
		return i, a[i][1], a[i][2], a[i][3]
	end
end

-- 安全的多表数组选代器 -- for i, v, d, di in X.sipairs(data1, data2, ...) do
---@vararg table @需要迭代的表
---@return fun(tab: table, index: number), table, number @迭代函数
function X.sipairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIter, iters, 0
end

-- 安全的多表选代器 -- for i, v, d, di in X.spairs(data1, data2, ...) do
---@vararg table @需要迭代的表
---@return fun(tab: table, index: number), table, number @迭代函数
function X.spairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIter, iters, 0
end

local function SafePairsIterR(a, i)
	i = i - 1
	if i > 0 then
		return i, a[i][1], a[i][2], a[i][3]
	end
end

-- 安全的多表数组倒序选代器 -- for i, v, d, di in X.sipairs_r(data1, data2, ...) do
---@vararg table @需要迭代的表
---@return fun(tab: table, index: number), table, number @迭代函数
function X.sipairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIterR, iters, #iters + 1
end

-- 安全的多表倒序选代器 -- for i, v, d, di in X.spairs_r(data1, data2, ...) do
---@vararg table @需要迭代的表
---@return fun(tab: table, index: number), table, number @迭代函数
function X.spairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIterR, iters, #iters + 1
end

-----------------------------------------------
-- 类
-----------------------------------------------

-- 创建类
---@param className string @类名
---@param classMembers table<string, any> @类成员函数对象
---@param super? table @父类
---@return table @类
function X.Class(className, classMembers, super)
	if X.IsTable(className) then
		className, classMembers, super = nil, className, classMembers
	end
	if not className then
		className = 'Unnamed Class'
	end
	-- 初始化成员变量表
	local classPrototypeProxy = setmetatable({}, { __index = super })
	for k, v in pairs(classMembers) do
		classPrototypeProxy[k] = v
	end
	-- 初始化父类、创建入口
	classPrototypeProxy.super = super
	classPrototypeProxy.new = function(classPrototype, ...)
		local classInstanceProxy = setmetatable(
			{
				super = function(classInstance, ...)
					if super.constructor then
						super.constructor(classInstance, ...)
					end
				end,
			},
			{
				__index = function(_, k)
					if k == 'new' or k == 'constructor' then
						return nil
					end
					return classPrototype[k]
				end,
			})
		local classInstance = setmetatable({}, {
			__index = classInstanceProxy,
			__tostring = function(t) return className .. ' (class instance)' end,
			__metatable = true,
		})
		if classPrototype.constructor then
			classPrototype.constructor(classInstance, ...)
		end
		return classInstance
	end
	-- 创建并返回类只读对象
	return setmetatable({}, {
		__index = classPrototypeProxy,
		__tostring = function(t) return className .. ' (class prototype)' end,
		__call = function (classPrototype, ...)
			return classPrototype:new(...)
		end,
		__newindex = function()
			assert(false, 'Class Prototype is readonly.')
		end,
		__metatable = true,
	})
end

-----------------------------------------------
-- Error
-----------------------------------------------

-- Error 生成错误对象
---@param message string @错误内容
---@return Error @错误对象
X.Error = X.Class('Error', {
	constructor = function(self, message, traceback)
		self.message = tostring(message)
		self.traceback = traceback or X.GetTraceback()
	end
})

-----------------------------------------------
-- Promise
-----------------------------------------------

-- Promise 生成承诺回调
---@param func fun(resolve: fun(result: any), reject: fun(error: Error)) @异步承诺函数主体
---@return table @承诺对象
X.Promise = X.Class('Promise', {
	-- 类静态函数
	Resolve = function(data)
		return 'RESOLVED', data
	end,

	Reject = function(error)
		return 'REJECTED', error
	end,

	-- 构造函数
	constructor = function(self, task, ...)
		-- 实例成员变量
		self.ctor = function() end
		self.task = task
		self.chains = {}
		self.status = 'PENDING'
		-- 事务触发器
		local function fnAction()
			self:__PROCESS_TASK__()
		end
		if X.DelayCall then
			X.DelayCall(1, fnAction)
		elseif DelayCall then
			DelayCall(1, fnAction)
		else
			fnAction()
		end
	end,

	-- 实例成员函数
	Then = function(self, onResolve)
		table.insert(self.chains, {
			type = 'then',
			handler = onResolve,
		})
		self:__PROCESS_CHAIN__()
		return self
	end,

	Catch = function(self, onReject)
		table.insert(self.chains, {
			type = 'catch',
			handler = onReject,
		})
		self:__PROCESS_CHAIN__()
		return self
	end,

	__PROCESS_TASK__ = function(self)
		local task = self.task
		local function onResolve(res)
			if self.status ~= 'PENDING' then
				return
			end
			self.status = 'RESOLVED'
			self.result = res
			self:__PROCESS_CHAIN__()
		end
		local function onReject(error)
			if self.status ~= 'PENDING' then
				return
			end
			self.status = 'REJECTED'
			self.error = error
			self:__PROCESS_CHAIN__()
		end
		self.task = nil
		if X.IsTable(task) and tostring(task) == 'Promise (class instance)' then
			task:Then(onResolve):Catch(onReject)
		else
			task(onResolve, onReject)
		end
	end,

	__PROCESS_CHAIN__ = function(self)
		if self.status == 'PENDING' then
			return
		end
		while true do
			local p = table.remove(self.chains, 1)
			if not p then
				break
			end
			local res
			if self.status == 'RESOLVED' then
				if p.type == 'then' then
					res = {X.XpCall(p.handler, self.result)}
				end
			elseif self.status == 'REJECTED' then
				if p.type == 'catch' then
					res = {X.XpCall(p.handler, self.error)}
				end
			end
			if res then
				local bSuccess = res[1]
				if bSuccess then
					local szStatus, vData = res[2], res[3]
					if X.IsTable(szStatus) and tostring(szStatus) == 'Promise (class instance)' then
						self.task = szStatus
						self.status = 'PENDING'
						self:__PROCESS_TASK__()
						break
					elseif szStatus == 'RESOLVED' then
						self.result = vData
						self.status = 'RESOLVED'
					elseif szStatus == 'REJECTED' then
						self.error = vData
						self.status = 'REJECTED'
					else
						self.status = 'RESOLVED'
					end
				else
					local szErrMsg, szTraceback = res[2], res[3]
					self.error = X.Error:new(szErrMsg or '', szTraceback)
					self.status = 'REJECTED'
				end
			end
		end
	end,
})

-----------------------------------------------
-- ProgressPromise
-----------------------------------------------

-- ProgressPromise 生成过程承诺回调
---@param func fun(resolve: fun(result: any), reject: fun(error: Error)) @异步过程承诺函数主体
---@return table @过程承诺对象
X.ProgressPromise = X.Class('ProgressPromise', {
	constructor = function(self, promiseFunction)
		self.progress = nil
		self.progressParams = nil
		self.progressHandlers = {}
		local function onProgress(...)
			self.progress = ...
			self.progressParams = {...}
			for _, f in ipairs(self.progressHandlers) do
				X.Call(f, ...)
			end
		end
		self:super(function(onResolve, onReject)
			promiseFunction(onResolve, onReject, onProgress)
		end)
	end,
	Progress = function(self, handler)
		if X.IsFunction(handler) then
			table.insert(self.progressHandlers, handler)
		end
		return self
	end,
}, X.Promise)

-----------------------------------------------
-- 安全调用
-----------------------------------------------
do
local xpAction, xpArgs, xpErrMsg, xpTraceback, xpErrLog
local function CallHandler()
	return xpAction(X.Unpack(xpArgs))
end
local function CallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = X.GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	xpErrLog = (errMsg or '') .. '\n' .. xpTraceback
	Log(xpErrLog)
	FireUIEvent('CALL_LUA_ERROR', xpErrLog .. '\n')
end
local function XpCallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = X.GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
end

-- 安全调用，常规输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.Call(fnAction, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = fnAction, X.Pack(...), nil, nil
	local res = X.Pack(xpcall(CallHandler, CallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return X.Unpack(res)
end

-- 安全调用，不输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.XpCall(fnAction, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = fnAction, X.Pack(...), nil, nil
	local res = X.Pack(xpcall(CallHandler, XpCallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return X.Unpack(res)
end
end

-- 预检查调用对象是否为函数的安全调用，常规输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.SafeCall(fnAction, ...)
	if not X.IsFunction(fnAction) then
		return false, 'NOT CALLABLE'
	end
	return X.Call(fnAction, ...)
end

-- 预检查调用对象是否为函数的安全调用，不输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.SafeXpCall(fnAction, ...)
	if not X.IsFunction(fnAction) then
		return false, 'NOT CALLABLE'
	end
	return X.XpCall(fnAction, ...)
end

-- 设置上下文的安全调用，常规输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.CallWithThis(context, fnAction, ...)
	local _this = this
	this = context
	local rtc = X.Pack(X.Call(fnAction, ...))
	this = _this
	return X.Unpack(rtc)
end

-- 预检查调用对象是否为函数的设置上下文的安全调用，常规输出错误日志
---@param fnAction fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.SafeCallWithThis(context, fnAction, ...)
	local _this = this
	this = context
	local rtc = X.Pack(X.SafeCall(fnAction, ...))
	this = _this
	return X.Unpack(rtc)
end

-- 设置上下文的安全调用，常规输出错误日志，界面组件支持字符串调用方法
---@param fnAction string | fun(...) @调用函数
---@param ... any @调用参数
---@return boolean, any @调用结果
function X.ExecuteWithThis(context, fnAction, ...)
	-- 界面组件支持字符串调用方法
	if X.IsString(fnAction) and X.IsElement(context) then
		if context[fnAction] then
			fnAction = context[fnAction]
		else
			local szFrame = context:GetRoot():GetName()
			fnAction = X.IsTable(_G[szFrame]) and _G[szFrame][fnAction]
		end
	end
	if not X.IsFunction(fnAction) then
		return false
	end
	return X.CallWithThis(context, fnAction, ...)
end

-- 测试用
function X.ExecuteInsideCommand(cmd)
	if loadstring then
		local ls = loadstring('return ' .. cmd)
		if ls then
			return ls()
		end
	end
end

function X.ExecuteAddonCommand(...)
	if ExecuteScriptCommand then
		return ExecuteScriptCommand(...)
	end
end

-----------------------------------------------
-- 宽字符
-----------------------------------------------

-- 获取字符串长度
---@param s string @需要获取长度的字符串
---@return number @字符串长度
X.StringLenW = wstring.len

-- 截取字符串
---@param str string 需要截取的字符串
---@param s number 开始位置
---@param e number 结束位置
---@return string 截取后的字符串
function X.StringSubW(str, s, e)
	if s < 0 or not e or e < 0 then
		local nLen = wstring.len(str)
		if s < 0 then
			s = nLen + s + 1
		end
		if not e then
			e = nLen
		elseif e < 0 then
			e = nLen + e + 1
		end
	end
	return wstring.sub(str, s, e)
end

-- 字符串字符迭代器
---@param str string @需要迭代的字符串
---@param func function(s: string): void @迭代器
---@return void
X.StringEachW = wstring.char_task

-- 字符串查找
---@param s string @需要查找的字符串
---@param p string @查找的字符串
---@return number, number @[nStartPos, nEndPos] 开始位置，结束位置
X.StringFindW = StringFindW
	and function(szHaystack, szNeedle, nOffset)
		if not nOffset then
			nOffset = 1
		end
		--[[#DEBUG BEGIN]]
		if szNeedle == '' then
			X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, X.GetTraceback('Call StringFindW with empty needle!'), X.DEBUG_LEVEL.ERROR)
		end
		--[[#DEBUG END]]
		-- 官方 StringFindW 有缺陷，当目标串 szHaystack 包含乱码时，查找结果可能低于偏移位置
		-- 最小复现： StringFindW(string.char(91,232,181,93), '[', 1)
		-- 最小复现结果： 返回 (0, 0) 这不可能，实际字符串下标最小为 1
		-- 解决方式： 检测到非法返回值时，回落到官方 LUA 实现 (wstring 库)，最终返回前再次校验约束关系
		local nStartPos, nEndPos = StringFindW(szHaystack, szNeedle, nOffset)
		if nStartPos and nStartPos < nOffset then
			local szPart = string.sub(szHaystack, nOffset)
			nStartPos, nEndPos = wstring.find(szPart, szNeedle)
			if nStartPos then
				nStartPos = nStartPos + nOffset - 1
				nEndPos = nEndPos + nOffset - 1
			end
		end
		if nStartPos and nEndPos and nStartPos >= nOffset then
			return nStartPos, nEndPos
		end
	end
	or function(szHaystack, szNeedle, nOffset)
		if not nOffset then
			nOffset = 1
		end
		local szPart = string.sub(szHaystack, nOffset)
		local nStartPos, nEndPos = wstring.find(szPart, szNeedle)
		if nStartPos then
			nStartPos = nStartPos + nOffset - 1
			nEndPos = nEndPos + nOffset - 1
		end
		if nStartPos and nEndPos and nStartPos >= nOffset then
			return nStartPos, nEndPos
		end
	end

-- 字符串切割
---@param s string @需要切割的字符串
---@param p string @分隔符
---@return string[] @切割后的字符串
X.StringSplitW = wstring.split

-- 字符串转半角
---@param s string @需要转半角的字符串
---@return string @转半角后的字符串
X.StringEnerW = StringEnerW or wstring.ener

-- 字符串转小写
---@param s string @需要转小写的字符串
---@return string @转小写后的字符串
X.StringLowerW = StringLowerW or wstring.lower

-- 字符串替换
---@param s string @需要替换的字符串
---@param p string @查找的字符串
---@param r string @替换的字符串
---@return string @替换后的字符串
X.StringReplaceW = StringReplaceW or wstring.replace
