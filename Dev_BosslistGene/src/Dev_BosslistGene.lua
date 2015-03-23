--------------------------------------------
-- @Desc  : BOSS列表生成工具
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-03-23 13:57:56
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Dev_BosslistGene/lang/")

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
	return t
end

_C.GetDungeonBossFmt = function()
	local t = _C.GetDungeonBoss()
	local s = '{\n\t"version" : ' .. MY.Sys.FormatTime('yyyyMMdd', GetCurrentTime()) .. ',\n'
	for dwMapID, tMap in pairs(t) do
		s = s .. '\t"' .. dwMapID .. '" : {\n'
		for dwNpcID, szName in pairs(tMap) do
			s = s .. '\t\t"' .. dwNpcID .. '" : "' .. szName .. '",\n'
		end
		s = s:sub(1, -3) .. '\n'
		s = s .. '\t},\n'
	end
	s = s:sub(1, -3) .. '\n'
	s = s .. '}'
	return s
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
			ui:children("#WndEdit"):text(_C.GetDungeonBossFmt())
		end,
	})
	y = y + 30
	
	ui:append("WndEditBox", "WndEdit", {
		multiline = true, x = x, y = y, w = w - 2 * x, h = h - y - 20
	})
end})
