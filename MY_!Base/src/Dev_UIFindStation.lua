--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面查看器
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/UIFindStation')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. '/lang/Dev/')
--------------------------------------------------------------------------------

local O = {
	bButton = false,
	szQuery = '',
	szResult = '',
	tLayer = { 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' },
}
local D = {}

do
local function fnApply(wnd)
	if wnd and wnd:IsVisible() then
		-- update mouse tips
		if wnd:GetType() == 'WndButton' or wnd:GetType() == 'WndCheckBox' then
			if O.bButton then
				wnd._OnMouseEnter = wnd.OnMouseEnter
				wnd.OnMouseEnter = function()
					local nX, nY = wnd:GetAbsPos()
					local nW, nH = wnd:GetSize()
					local szTip = GetFormatText(_L['<Component Path>'] .. '\n', 101)
					szTip = szTip .. GetFormatText(string.sub(wnd:GetTreePath(), 1, -2), 106)
					OutputTip(szTip, 400, { nX, nY, nW, nH })
				end
			else
				wnd.OnMouseEnter = wnd._OnMouseEnter
				wnd._OnMouseEnter = nil
			end
		end
		-- update childs
		local cld = wnd:GetFirstChild()
		while cld ~= nil do
			fnApply(cld)
			cld = cld:GetNext()
		end
	end
end
function D.UpdateButton()
	O.bButton = not O.bButton
	for _, v in ipairs(O.tLayer) do
		fnApply(Station.Lookup(v))
	end
end
end

do
local function fnApply(wnd)
	if wnd and wnd:IsVisible() then
		-- update mouse tips
		if wnd:GetType() == 'Box' then
			if O.bBox then
				wnd._OnItemMouseEnter = wnd.OnItemMouseEnter
				wnd.OnItemMouseEnter = function()
					local nX, nY = wnd:GetAbsPos()
					local nW, nH = wnd:GetSize()
					local szTip = GetFormatText(_L['<Component Path>'] .. '\n', 101)
					szTip = szTip .. GetFormatText(string.sub(wnd:GetTreePath(), 1, -2), 106)
					OutputTip(szTip, 400, { nX, nY, nW, nH })
				end
			else
				wnd.OnItemMouseEnter = wnd._OnItemMouseEnter
				wnd._OnItemMouseEnter = nil
			end
		elseif wnd:GetType() == 'Handle' then
			-- handle traverse
			for i = 0, wnd:GetItemCount() - 1, 1 do
				fnApply(wnd:Lookup(i))
			end
		elseif wnd:GetType() == 'WndFrame' or wnd:GetType() == 'WndWindow' then
			-- main handle
			fnApply(wnd:Lookup('', ''))
			-- update childs
			local cld = wnd:GetFirstChild()
			while cld ~= nil do
				fnApply(cld)
				cld = cld:GetNext()
			end
		end
	end
end
function D.UpdateBox()
	O.bBox = not O.bBox
	for _, v in ipairs(O.tLayer) do
		fnApply(Station.Lookup(v))
	end
end
end

do
local function fnSearch(wnd, szText, tResult)
	if not wnd or not wnd:IsVisible() then
		return
	end
	local hnd = wnd
	if wnd:GetType() ~= 'Handle' and wnd:GetType() ~= 'TreeLeaf' then
		hnd = wnd:Lookup('', '')
	end
	if hnd then
		for i = 0, hnd:GetItemCount() - 1, 1 do
			local hT = hnd:Lookup(i)
			if hT:GetType() == 'Handle' or hT:GetType() == 'TreeLeaf' then
				fnSearch(hT, szText, tResult)
			elseif hT:GetType() == 'Text' and hT:IsVisible() and string.find(hT:GetText(), szText) then
				local p1, p2 = hT:GetTreePath()
				table.insert(tResult, { p1 = string.sub(p1, 1, -2), p2 = p2, txt = hT:GetText() })
			end
		end
	end
	if hnd ~= wnd then
		local cld = wnd:GetFirstChild()
		while cld ~= nil do
			fnSearch(cld, szText, tResult)
			cld = cld:GetNext()
		end
	end
end
function D.SearchText(szText)
	local tResult = {}
	-- lookup
	if szText ~= '' then
		for _, v in ipairs(O.tLayer) do
			fnSearch(Station.Lookup(v), szText, tResult)
		end
	end
	-- concat result
	local szResult = ''
	for _, v in ipairs(tResult) do
		szResult = szResult .. v.p1 .. ', ' .. v.p2 .. ': ' .. v.txt .. '\n'
	end
	if szResult == '' then
		szResult = 'NO-RESULT'
	end
	return szResult
end
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
local PS = {}

function PS.IsRestricted()
	return not X.IsDebugging('Dev_UIFindStation')
end

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()

	ui:Append('Text', { x = nX, y = nY, text = _L['Find component'], font = 27 })
	ui:Append('WndCheckBox', {
		x = nX + 10, y = nY + 28,
		text = _L['Enable button search, mouseover it will show its path'],
		checked = O.bButton, onCheck = D.UpdateButton,
	}):AutoWidth()
	ui:Append('WndCheckBox', {
		x = nX + 10, y = nY + 56,
		text = _L['Enable box search, mouseover it will show its path'],
		checked = O.bBox, onCheck = D.UpdateBox,
	}):AutoWidth()
	ui:Append('Text', { x = nX + 0, y = nY + 92, text = _L['Find by text'], font = 27 })

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = nY + 120,
		text = _L['Keyword: '],
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndEditBox', {
		name = 'Edit_Query',
		x = nX, y = nY + 120, w = 200, h = 27,
		limit = 256,
		text = O.szQuery,
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 120,
		text = _L['Search'],
		onClick = function()
			ui:Children('#Edit_Result'):Text(_L['Searching, please wait...'])
			O.szQuery = ui:Children('#Edit_Query'):Text()
			O.szResult = D.SearchText(O.szQuery)
			ui:Children('#Edit_Result'):Text(O.szResult)
		end,
	}):Width() + 5
	ui:Append('Text', { x = nX, y = nY + 120, text = _L['(Supports Lua regex)'] })

	nX = nPaddingX + 10
	ui:Append('WndEditBox', { name = 'Edit_Result', x = nX, y = nY + 150, limit = 9999, w = 480, h = 200, multiline = true, text = O.szResult })
end

X.Panel.Register(_L['Development'], 'Dev_UIFindStation', _L['Dev_UIFindStation'], 2791, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
