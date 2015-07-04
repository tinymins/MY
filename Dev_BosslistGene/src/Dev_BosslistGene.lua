--------------------------------------------
-- @Desc  : BOSS列表生成工具
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-07-04 23:02:25
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Dev_BosslistGene/lang/")
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local BOSS_ADD_PATH = MY.GetAddonInfo().szRoot .. "Dev_BosslistGene/data/add.jx3dat"
local BOSS_DEL_PATH = MY.GetAddonInfo().szRoot .. "Dev_BosslistGene/data/del.jx3dat"

_C.GetDungeonBoss = function()
	local t = {}
	
	local nCount = g_tTable.DungeonBoss:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.DungeonBoss:GetRow(i)
		local dwMapID = tLine.dwMapID
		local szNpcList = tLine.szNpcList
		for szNpcIndex in string.gmatch(szNpcList, "(%d+)") do
			local p = g_tTable.DungeonNpc:Search(tonumber(szNpcIndex))
			if p then
				if not t[dwMapID] then
					t[dwMapID] = {}
				end
				t[dwMapID][p.dwNpcID] = p.szName
			end
		end
	end
	
	for dwMapID, tBoss in pairs(MY.LoadLUAData(BOSS_ADD_PATH) or {}) do
		if not t[dwMapID] then
			t[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tBoss) do
			t[dwMapID][dwNpcID] = szName
		end
	end
	for dwMapID, tBoss in pairs(MY.LoadLUAData(BOSS_DEL_PATH) or {}) do
		if t[dwMapID] then
			for dwNpcID, szName in pairs(tBoss) do
				t[dwMapID][dwNpcID] = nil
			end
		end
	end
	return t
end

_C.GetDungeonBossFmt = function()
	local t = { '{\n\t"version" : ', MY.Sys.FormatTime('yyyyMMdd', GetCurrentTime()), ',\n'}
	for dwMapID, tMap in pairs(_C.GetDungeonBoss()) do
		tinsert(t, '\t"')
		tinsert(t, dwMapID)
		tinsert(t, '" : {\n')
		for dwNpcID, szName in pairs(tMap) do
			tinsert(t, '\t\t"')
			tinsert(t, dwNpcID)
			tinsert(t, '" : "')
			tinsert(t, szName)
			tinsert(t, '",\n')
		end
		if t[#t] == '",\n' then
			t[#t] = '"\n'
		end
		tinsert(t, '\t},\n')
	end
	if t[#t] == '\t},\n' then
		t[#t] = '\t}\n'
	end
	tinsert(t, '}')
	return tconcat(t)
end

_C.GetDungeonBossFmt2 = function()
	local nTime = MY.Sys.FormatTime('yyyyMMdd', GetCurrentTime())
	local t = { '{"version":', nTime, "," }
	for dwMapID, tMap in pairs(_C.GetDungeonBoss()) do
		tinsert(t, '"')
		tinsert(t, dwMapID)
		tinsert(t, '":{')
		for dwNpcID, szName in pairs(tMap) do
			tinsert(t, '"')
			tinsert(t, dwNpcID)
			tinsert(t, '":"')
			tinsert(t, "1")
			tinsert(t, '",')
		end
		if t[#t] == '",' then
			t[#t] = '"'
		end
		tinsert(t, '},')
	end
	if t[#t] == '},' then
		t[#t] = '}'
	end
	tinsert(t, '}')
	return tconcat(t)
end

MY.RegisterPanel(
"Dev_BosslistGene", _L["BosslistGene"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 10
	local w, h = ui:size()
	
	ui:append('WndButton', {
		text = _L['Gene'], x = x, y = y, w = 150, onclick = function()
			ui:children("#WndEdit"):text(_C.GetDungeonBossFmt2())
		end,
	})
	y = y + 30
	
	ui:append("WndEditBox", "WndEdit", {
		multiline = true, x = x, y = y, w = w - 2 * x, h = h - y - 20
	})
end})
