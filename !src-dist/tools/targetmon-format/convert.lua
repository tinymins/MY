
local srep = string.rep
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local type = type
local next = next
local print = print
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local string2byte = string.byte

function clone(var)
	local szType = type(var)
	if szType == 'nil'
	or szType == 'boolean'
	or szType == 'number'
	or szType == 'string' then
		return var
	elseif szType == 'table' then
		local t = {}
		for key, val in pairs(var) do
			key = clone(key)
			val = clone(val)
			t[key] = val
		end
		return t
	elseif szType == 'function'
	or szType == 'userdata' then
		return nil
	else
		return nil
	end
end

function empty(var)
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

local function table_r(var, level, indent)
	if level == 3 then
		indent = nil
	end
	local t = {}
	local szType = type(var)
	if szType == 'nil' then
		tinsert(t, 'nil')
	elseif szType == 'number' then
		tinsert(t, tostring(var))
	elseif szType == 'string' then
		tinsert(t, string.format('%q', var))
	elseif szType == 'function' then
		local s = string.dump(var)
		tinsert(t, 'loadstring("')
		-- 'string slice too long'
		for i = 1, #s, 2000 do
			tinsert(t, tconcat({'', string2byte(s, i, i + 2000 - 1)}, '\\'))
		end
		tinsert(t, '")')
	elseif szType == 'boolean' then
		tinsert(t, tostring(var))
	elseif szType == 'table' then
		tinsert(t, '{')
		local s_tab_equ = '='
		if indent then
			s_tab_equ = ' = '
			if not empty(var) then
				tinsert(t, '\n')
			end
		end
		local nohash = true
		local key, val, lastkey, lastval
		local tlist, thash = {}, {}
		repeat
			key, val = next(var, lastkey)
			if key then
				-- judge if this is a pure list table
				if nohash and (
					type(key) ~= 'number'
					or (lastval == nil and key ~= 1) -- first loop and index is not 1 : hash table
					or (lastkey and lastkey + 1 ~= key)
				) then
					nohash = false
				end
				-- process to insert to table
				if nohash then -- pure list table
					if indent then
						tinsert(t, srep(indent, level + 1))
					end
					tinsert(t, table_r(val, level + 1, indent))
					tinsert(t, ',')
					if indent then
						tinsert(t, '\n')
					end
				elseif type(key) == 'string' and key:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then -- a = val
					if indent then
						tinsert(t, srep(indent, level + 1))
					end
					tinsert(t, key)
					tinsert(t, s_tab_equ) --' = '
					tinsert(t, table_r(val, level + 1, indent))
					tinsert(t, ',')
					if indent then
						tinsert(t, '\n')
					end
				else -- [10010] = val -- ['.start with or contains special char'] = val
					if indent then
						tinsert(t, srep(indent, level + 1))
					end
					tinsert(t, '[')
					tinsert(t, table_r(key, level + 1, indent))
					tinsert(t, ']')
					tinsert(t, s_tab_equ) --' = '
					tinsert(t, table_r(val, level + 1, indent))
					tinsert(t, ',')
					if indent then
						tinsert(t, '\n')
					end
				end
				lastkey, lastval = key, val
			end
		until not key
		if not empty(var) then
			if indent then -- insert `}` with indent
				tinsert(t, srep(indent, level))
			else -- remove last comma when no indent
				tremove(t)
			end
		end
		tinsert(t, '}')
	else --if (szType == 'userdata') then
		tinsert(t, '"')
		tinsert(t, tostring(var))
		tinsert(t, '"')
	end
	return tconcat(t)
end

function var2str(var, indent, level)
	return table_r(var, level or 0, indent)
end

do
local Log = print
local envmeta = {}
function str2var(str, env)
	if type(str) ~= 'string' then
		Log('[LOADSTRING ERROR]bad argument #1 to str2var, string expected, got ' .. type(str) .. '.')
		return
	end
	local fn, bdata = loadstring('return ' .. str)
	if not fn then
		fn, bdata = loadstring(str), true
	end
	if not fn then
		Log('[LOADSTRING ERROR]failed on decoding #1 of str2var, plain text is: ' .. str)
		return
	end
	local env, datalist = env or {}
	setmetatable(env, envmeta)
	setfenv(fn, env)
	datalist = {pcall(fn)}
	setmetatable(env, nil)
	if datalist[1] then
		if bdata then
			datalist = {env.data}
		else
			tremove(datalist, 1)
		end
	else
		Log('[CALL ERROR]str2var("' .. str .. '"): \nERROR:' .. datalist[2])
	end
	return unpack(datalist)
end
end

local function Read(path)
	local file = io.open(path, 'rb')
	local content = file:read('*a')
	file:close()
	return content
end

local function Write(path, content)
	local file = io.open(path, 'w')
	file:write(content)
	file:close()
end

local content = Read(arg[1])
local data = str2var(content) or {}
for i, v in ipairs(data) do
	v.enable = false
end
local content = 'data = ' .. var2str(data, '\t')
Write(arg[2] or arg[1], content)
