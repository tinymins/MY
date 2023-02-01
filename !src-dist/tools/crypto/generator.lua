local a = {}
for i = 0, 255 do
	a[i] = i
end

math.randomseed(os.time())
for i = 0, 255 do
	local j = math.random(0, 255)
	local v = a[j]
	a[j] = a[i]
	a[i] = v
end

print("{")
print(("\t[0x00] = 0x%02X,"):format(a[0]))
for i = 0, 15 do
	local s = {"\t"}
	for j = 1, 16 do
		if a[i * 16 + j] then
			table.insert(s, (("0x%02X, "):format(a[i * 16 + j])))
		end
	end
	print(table.concat(s))
end
print("}")

local r = {}
for i = 0, 255 do
	r[a[i]] = i
end

print("[")
for i = 0, 15 do
	local s = {"\t"}
	for j = 0, 15 do
		table.insert(s, (("0x%02X, "):format(r[i * 16 + j])))
	end
	print(table.concat(s))
end
print("]")
