--------------------------------------------
-- @Desc  : UI事件ID计算
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-01-05 18:25:03
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MYDev_VarWatch/lang/")
local XML_LINE_BREAKER = XML_LINE_BREAKER
local srep, tostring, string2byte = string.rep, tostring, string.byte
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local type, next, print, pairs, ipairs = type, next, print, pairs, ipairs
local DATA_PATH = {"config/dev_varwatch.jx3dat", MY_DATA_PATH.GLOBAL}
_C.tVarList = MY.LoadLUAData(DATA_PATH) or {}

local function var2str_x(var, indent, level) -- 只解析一层table且不解析方法
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == "nil" then
			tinsert(t, "nil")
		elseif szType == "number" then
			tinsert(t, tostring(var))
		elseif szType == "string" then
			tinsert(t, string.format("%q", var))
		elseif szType == "boolean" then
			tinsert(t, tostring(var))
		elseif szType == "table" then
			tinsert(t, "{")
			local s_tab_equ = "]="
			if indent then
				s_tab_equ = "] = "
				if not empty(var) then
					tinsert(t, "\n")
				end
			end
			for key, val in pairs(var) do
				if indent then
					tinsert(t, srep(indent, level + 1))
				end
				tinsert(t, "[")
				tinsert(t, tostring(key))
				tinsert(t, s_tab_equ) --"] = "
				tinsert(t, tostring(val))
				tinsert(t, ",")
				if indent then
					tinsert(t, "\n")
				end
			end
			if indent and not empty(var) then
				tinsert(t, srep(indent, level))
			end
			tinsert(t, "}")
		else --if (szType == "userdata") then
			tinsert(t, '"')
			tinsert(t, tostring(var))
			tinsert(t, '"')
		end
		return tconcat(t)
	end
	return table_r(var, level or 0, indent)
end

MY.RegisterPanel(
"Dev_VarWatch", _L["VarWatch"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
	OnPanelActive = function(wnd)
		local ui = MY.UI(wnd)
		local x, y = 10, 10
		local w, h = ui:size()
		local nLimit = 20
		
		local tWndEditK = {}
		local tWndEditV = {}
		
		for i = 1, nLimit do
			tWndEditK[i] = ui:append("WndEditBox", {
				name = "WndEditBox_K" .. i,
				text = _C.tVarList[i],
				x = x, y = y + (i - 1) * 25,
				w = 150, h = 25,
				color = {255, 255, 255},
				onchange = function(raw, text)
					_C.tVarList[i] = MY.String.Trim(text)
					MY.SaveLUAData(DATA_PATH, _C.tVarList)
				end,
			}):children("#WndEditBox_K" .. i)
			
			tWndEditV[i] = ui:append("WndEditBox", {
				name = "WndEditBox_V" .. i,
				x = x + 150, y = y + (i - 1) * 25,
				w = w - 2 * x - 150, h = 25,
				color = {255, 255, 255},
			}):children("#WndEditBox_V" .. i)
		end
		
		MY.BreatheCall("DEV_VARWATCH", function()
			for i = 1, nLimit do
				local szKey = _C.tVarList[i]
				local hFocus = Station.GetFocusWindow()
				if not empty(szKey) and -- 忽略空白的Key
				wnd:GetRoot():IsVisible() and ( -- 主界面隐藏了就不要解析了
					not hFocus or (
						not hFocus:GetTreePath():find(tWndEditK[i]:name()) and  -- 忽略K编辑中的
						not hFocus:GetTreePath():find(tWndEditV[i]:name()) -- 忽略V编辑中的
					)
				) then
					if loadstring then
						local t = {select(2, pcall(loadstring("return " .. szKey)))}
						for k, v in pairs(t) do
							t[k] = tostring(v)
						end
						tWndEditV[i]:text(tconcat(t, ", "))
					else
						tWndEditV[i]:text(var2str_x(MY.GetGlobalValue(szKey)))
					end
				end
			end
		end)
	end,
	OnPanelDeactive = function()
		MY.BreatheCall("DEV_VARWATCH", false)
	end,
})
