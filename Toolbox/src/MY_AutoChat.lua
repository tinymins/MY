--------------------------------------------
-- @Desc  : 自动对话（for 台服）
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-03-09 21:26:52
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-03-10 22:26:49
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _C = { Data = {} }
MY_AutoChat = { bEnable = true, bEchoOn = false, bEnableShift = true, CurrentWindow = 0, Conents = nil }
RegisterCustomData("MY_AutoChat.bEnable")
RegisterCustomData("MY_AutoChat.bEchoOn")
RegisterCustomData("MY_AutoChat.bEnableShift")

MY_AutoChat.LoadData = function() _C.Data = MY.LoadLUAData("config/AUTO_CHAT/data") or MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "ToolBox/data/interact/") or _C.Data end
MY_AutoChat.SaveData = function() MY.SaveLUAData("config/AUTO_CHAT/data", _C.Data) end
MY_AutoChat.GetName  = function(dwType, dwID)
	local szMap  = _L['Common']
	local szName = MY.GetObjectName(MY.GetObject(dwType, dwID))
	if szName then
		if dwType ~= TARGET.ITEM then
			szMap = Table_GetMapName(GetClientPlayer().GetMapID())
		end
		return szName, szMap
	else
		return _L['Common'], _L['Common']
	end
end

MY_AutoChat.AddData = function(szMap, szName, szKey)
	if not _C.Data[szMap] then
		_C.Data[szMap] = { [szName] = { [szKey] = 1 } }
	elseif not _C.Data[szMap][szName] then
		_C.Data[szMap][szName] = { [szKey] = 1 }
	elseif not _C.Data[szMap][szName][szKey] then
		_C.Data[szMap][szName][szKey] = 1
	end
	MY_AutoChat.SaveData()
	MY_AutoChat.DoSomething()
end

MY_AutoChat.DelData = function(szMap, szName, szKey)
	if not _C.Data[szMap] or not _C.Data[szMap][szName] or not _C.Data[szMap][szName][szKey] then
		return
	else
		_C.Data[szMap][szName][szKey] = nil
		if empty(_C.Data[szMap][szName]) then
			_C.Data[szMap][szName] = nil
			if empty(_C.Data[szMap]) then
				_C.Data[szMap] = nil
			end
		end
	end
	MY_AutoChat.SaveData()
end

MY_AutoChat.Choose = function(szMap, szName, dwIndex, aInfo)
	if not (szMap and szName and dwIndex and aInfo
	and _C.Data[szMap] and _C.Data[szMap][szName]) then
		return
	end
	local tChat = _C.Data[szMap][szName]
	
	for i, v in ipairs(aInfo) do
		if (v.name == '$' or v.name == "W") and tChat[v.context] and v.attribute.id then
			for i = 1, tChat[v.context] do
				GetClientPlayer().WindowSelect(dwIndex, v.attribute.id)
			end
			if MY_AutoChat.bEchoOn then
				MY.Sysmsg({_L("Conversation with [%s] auto chose: %s", szName, v.context)})
			end
			return
		end
	end
end

function MY_AutoChat.DoSomething()
	-- Output(MY_AutoChat.Conents, MY_AutoChat.CurrentWindow)
	if MY_AutoChat.bEnableShift and IsShiftKeyDown() then
		MY.Sysmsg({_L["Auto interact disabled due to SHIFT key pressed."]})
		return
	end
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() then
		local dwType, dwID, dwIndex, aInfo = frame.dwTargetType, frame.dwTargetId, frame.dwIndex, frame.aInfo
		local szName, szMap = MY_AutoChat.GetName(dwType, dwID)
		if szName and aInfo then
			MY_AutoChat.Choose(szMap, szName, dwIndex, aInfo)
		end
	end
end

_C.HookDialoguePanel = function()
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() and not frame.bMYHooked then
		MY.UI(frame):append('WndButton', {
			x = 50, y = 10, w = 80, text = _L['autochat'],
			menu = function()
				local dwType, dwID, dwIdx = frame.dwTargetType, frame.dwTargetId, frame.dwIndex
				local szName, szMap = MY_AutoChat.GetName(dwType, dwID)
				if szName and szMap then
					if frame.aInfo then
						local t = { {szOption = szName, bDisable = true}, { bDevide = true } }
						local tChat = {}
						-- 面板上的对话
						for i, v in ipairs(frame.aInfo) do
							if v.name == "$" or v.name == 'W' then
								local r, g, b = 255, 255, 255
								local szIcon, nFrame, szLayer, fnClickIcon
								if _C.Data[szMap] and _C.Data[szMap][szName] and _C.Data[szMap][szName][v.context] then
									r, g, b = 255, 0, 255
									szIcon = 'ui/Image/UICommon/Feedanimials.UITex'
									nFrame = 86
									nMouseOverFrame = 87
									szLayer = "ICON_RIGHT"
									fnClickIcon = function()
										MY_AutoChat.DelData(szMap, szName, v.context)
										Wnd.CloseWindow('PopupMenuPanel')
									end
								end
								table.insert(t, {
									r = r, g = g, b = b,
									szOption = v.context,
									fnAction = function() MY_AutoChat.AddData(szMap, szName, v.context) end,
									szIcon = szIcon, nFrame = nFrame, nMouseOverFrame = nMouseOverFrame,
									szLayer = szLayer, fnClickIcon = fnClickIcon,
								})
								tChat[v.context] = true
							end
						end
						-- 保存的自动对话
						if _C.Data[szMap] and _C.Data[szMap][szName] then
							for szKey, _ in pairs(_C.Data[szMap][szName]) do
								if not tChat[szKey] then
									table.insert(t, {
										r = 255, g = 0, b = 255,
										szOption = szKey,
										fnAction = function() MY_AutoChat.AddData(szMap, szName, szKey) end,
										szIcon = 'ui/Image/UICommon/Feedanimials.UITex', nFrame = 86, nMouseOverFrame = 87,
										szLayer = "ICON_RIGHT", fnClickIcon = function()
											MY_AutoChat.DelData(szMap, szName, szKey)
											Wnd.CloseWindow('PopupMenuPanel')
										end,
									})
									tChat[szKey] = true
								end
							end
						end
						return t
					end
				end
			end
		})
		frame.bMYHooked = true
	end
end

MY.RegisterPlayerAddonMenu('MY_AutoChat', function()
	if MY.IsShieldedVersion() then
		return
	end
	
	return {
		szOption = _L['autochat'], {
			szOption = _L['enable'],
			bCheck = true, bChecked = MY_AutoChat.bEnable,
			fnAction = function()
				MY_AutoChat.bEnable = not MY_AutoChat.bEnable
			end
		}, {
			szOption = _L['echo when autochat'],
			bCheck = true, bChecked = MY_AutoChat.bEchoOn,
			fnAction = function()
				MY_AutoChat.bEchoOn = not MY_AutoChat.bEchoOn
			end
		}, {
			szOption = _L['disable when shift key pressed'],
			bCheck = true, bChecked = MY_AutoChat.bEnableShift,
			fnAction = function()
				MY_AutoChat.bEnableShift = not MY_AutoChat.bEnableShift
			end
		},
	}
end)

RegisterEvent("OPEN_WINDOW", function()
	if MY.IsShieldedVersion() or not MY_AutoChat.bEnable then
		return
	end
	if empty(_C.Data) then
		MY_AutoChat.LoadData()
	end
	_C.HookDialoguePanel()
	MY_AutoChat.CurrentWindow = arg0
	MY_AutoChat.Conents = arg1
	MY_AutoChat.DoSomething()
end)
