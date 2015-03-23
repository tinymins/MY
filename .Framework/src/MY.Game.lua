--------------------------------------------
-- @Desc  : ������� ��Ϸ������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-03-23 10:33:33
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = MY or {}
MY.Game = MY.Game or {}
local _Cache, _L = {}, MY.LoadLangPack()
local _C = {}

-- #######################################################################################################
--       #       #               #         #           #           #         
--       #       #               #     # # # # # #     # #       # # # #     
--       #   # # # # # #         #         #         #     # #     #   #     
--   #   # #     #     #     # # # #   # # # # #             # # # # # # #   
--   #   #       #     #         #         #   #     # # #   #     #   #     
--   #   #       #     #         #     # # # # # #     #   #     # # # #     
--   #   # # # # # # # # #       # #       #   #       #   # #     #         
--       #       #           # # #     # # # # #     # # #   # # # # # #     
--       #     #   #             #         #           #     #     #         
--       #     #   #             #     #   # # # #     #   # # # # # # # #   
--       #   #       #           #     #   #           # #   #     #         
--       # #           # #     # #   #   # # # # #     #   #   # # # # # #   
-- #######################################################################################################
_Cache.tHotkey = {}
--[[ ����ϵͳ��ݼ�
	(void) MY.AddHotKey(string szName, string szTitle, func fnAction)   -- ����ϵͳ��ݼ�
]]
MY.Game.AddHotKey = function(szName, szTitle, fnAction)
	if string.sub(szName, 1, 3) ~= "MY_" then
		szName = "MY_" .. szName
	end
	table.insert(_Cache.tHotkey, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end
--[[ ��ȡ��ݼ�����
	(string) MY.GetHotKeyName(string szName, boolean bBracket, boolean bShort)      -- ȡ�ÿ�ݼ�����
]]
MY.Game.GetHotKeyName = function(szName, bBracket, bShort)
	if string.sub(szName, 1, 3) ~= "MY_" then
		szName = "MY_" .. szName
	end
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szKey = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szKey ~= "" and bBracket then
		szKey = "(" .. szKey .. ")"
	end
	return szKey
end
--[[ ��ȡ��ݼ�
	(table) MY.GetHotKey(string szName, true , true )       -- ȡ�ÿ�ݼ�
	(number nKey, boolean bShift, boolean bCtrl, boolean bAlt) MY.GetHotKey(string szName, true , fasle)        -- ȡ�ÿ�ݼ�
]]
MY.Game.GetHotKey = function(szName, bBracket, bShort)
	if string.sub(szName, 1, 3) ~= "MY_" then
		szName = "MY_" .. szName
	end
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end
--[[ ���ÿ�ݼ�/�򿪿�ݼ��������    -- HM����ٳ�����
	(void) MY.SetHotKey()                               -- �򿪿�ݼ��������
	(void) MY.SetHotKey(string szGroup)     -- �򿪿�ݼ�������岢��λ�� szGroup ���飨�����ã�
	(void) MY.SetHotKey(string szCommand, number nKey )     -- ���ÿ�ݼ�
	(void) MY.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- ���ÿ�ݼ�
]]
MY.Game.SetHotKey = function(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
	if nIndex then
		if string.sub(szCommand, 1, 3) ~= "MY_" then
			szCommand = "MY_" .. szCommand
		end
		if not nKey then nIndex, nKey = 1, nIndex end
		Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
	else
		local szGroup = szCommand or MY.GetAddonInfo().szName

		local frame = Station.Lookup("Topmost/HotkeyPanel")
		if not frame then
			frame = Wnd.OpenWindow("HotkeyPanel")
		elseif not frame:IsVisible() then
			frame:Show()
		end
		if not szGroup then return end
		-- load aKey
		local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
		for k, v in pairs(bindings) do
			if v.szHeader ~= "" then
				if aKey then
					break
				elseif v.szHeader == szGroup then
					aKey = {}
				else
					nI = nI + 1
				end
			end
			if aKey then
				if not v.Hotkey1 then
					v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				if not v.Hotkey2 then
					v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				table.insert(aKey, v)
			end
		end
		if not aKey then return end
		local hP = frame:Lookup("", "Handle_List")
		local hI = hP:Lookup(nI)
		if hI.bSel then return end
		-- update list effect
		for i = 0, hP:GetItemCount() - 1 do
			local hB = hP:Lookup(i)
			if hB.bSel then
				hB.bSel = false
				if hB.IsOver then
					hB:Lookup("Image_Sel"):SetAlpha(128)
					hB:Lookup("Image_Sel"):Show()
				else
					hB:Lookup("Image_Sel"):Hide()
				end
			end
		end
		hI.bSel = true
		hI:Lookup("Image_Sel"):SetAlpha(255)
		hI:Lookup("Image_Sel"):Show()
		-- update content keys [hI.nGroupIndex]
		local hK = frame:Lookup("", "Handle_Hotkey")
		local szIniFile = "UI/Config/default/HotkeyPanel.ini"
		Hotkey.SetCapture(false)
		hK:Clear()
		hK.nGroupIndex = hI.nGroupIndex
		hK:AppendItemFromIni(szIniFile, "Text_GroupName")
		hK:Lookup(0):SetText(szGroup)
		hK:Lookup(0).bGroup = true
		for k, v in ipairs(aKey) do
			hK:AppendItemFromIni(szIniFile, "Handle_Binding")
			local hI = hK:Lookup(k)
			hI.bBinding = true
			hI.nIndex = k
			hI.szTip = v.szTip
			hI:Lookup("Text_Name"):SetText(v.szDesc)
			for i = 1, 2, 1 do
				local hK = hI:Lookup("Handle_Key"..i)
				hK.bKey = true
				hK.nIndex = i
				local hotkey = v["Hotkey"..i]
				hotkey.bUnchangeable = v.bUnchangeable
				hK.bUnchangeable = v.bUnchangeable
				local text = hK:Lookup("Text_Key"..i)
				text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
				-- update btn
				if hK.bUnchangeable then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
				elseif hK.bDown then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
				elseif hK.bRDown then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
				elseif hK.bSel then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
				elseif hK.bOver then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
				elseif hotkey.bChange then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
				elseif hotkey.bConflict then
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
				else
					hK:Lookup("Image_Key"..hK.nIndex):SetFrame(53)
				end
			end
		end
		-- update content scroll
		hK:FormatAllItemPos()
		local wAll, hAll = hK:GetAllItemSize()
		local w, h = hK:GetSize()
		local scroll = frame:Lookup("Scroll_Key")
		local nCountStep = math.ceil((hAll - h) / 10)
		scroll:SetStepCount(nCountStep)
		scroll:SetScrollPos(0)
		if nCountStep > 0 then
			scroll:Show()
			scroll:GetParent():Lookup("Btn_Up"):Show()
			scroll:GetParent():Lookup("Btn_Down"):Show()
		else
			scroll:Hide()
			scroll:GetParent():Lookup("Btn_Up"):Hide()
			scroll:GetParent():Lookup("Btn_Down"):Hide()
		end
		-- update list scroll
		local scroll = frame:Lookup("Scroll_List")
		if scroll:GetStepCount() > 0 then
			local _, nH = hI:GetSize()
			local nStep = math.ceil((nI * nH) / 10)
			if nStep > scroll:GetStepCount() then
				nStep = scroll:GetStepCount()
			end
			scroll:SetScrollPos(nStep)
		end
	end
end

MY.RegisterInit(function()
	-- hotkey
	Hotkey.AddBinding("MY_Total", _L["Open/Close main panel"], MY.GetAddonInfo().szName, MY.TogglePanel, nil)
	for _, v in ipairs(_Cache.tHotkey) do
		Hotkey.AddBinding(v.szName, v.szTitle, "", v.fnAction, nil)
	end
	for i = 1, 5 do
		Hotkey.AddBinding('MY_HotKey_Null_'..i, _L['none-function hotkey'], "", function() end, nil)
	end
end)

-- #######################################################################################################
--                                 #                   # # # #   # # # #     
--     # # # #   # # # # #       # # # # # # #         #     #   #     #     
--     #     #   #       #     #   #       #           # # # #   # # # #     
--     #     #   #       #           # # #                     #     #       
--     # # # #   #   # #         # #       # #                 #       #     
--     #     #   #           # #     #         # #   # # # # # # # # # # #   
--     #     #   # # # # #           #                       #   #           
--     # # # #   #   #   #     # # # # # # # #           # #       # #       
--     #     #   #   #   #         #         #       # #               # #   
--     #     #   #     #           #         #         # # # #   # # # #     
--     #     #   #   #   #       #           #         #     #   #     #     
--   #     # #   # #     #     #         # #           # # # #   # # # #     
-- #######################################################################################################
--[[ ��ȡ��ǰ������
]]
MY.Game.GetServer = function()
	return table.concat({GetUserServer()},'_'), {GetUserServer()}
end

--[[ ��ȡָ������
	(KObject, info, bIsInfo) MY.GetObject([number dwType, ]number dwID)
	-- dwType: [��ѡ]��������ö�� TARGET.*
	-- dwID  : ����ID
	-- return: ���� dwType ���ͺ� dwID ȡ�ò�������
	--         ������ʱ����nil, nil
]]
MY.Game.GetObject = function(dwType, dwID)
	if not dwID then
		dwType, dwID = nil, dwType
	end
	local p, info, b
	
	if not dwType then
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		elseif GetDoodad(dwID) then
			dwType = TARGET.DOODAD
		else
			dwType = TARGET.NPC
		end
	end
	
	if dwType == TARGET.PLAYER then
		local me = GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif me and me.IsPlayerInMyParty(dwID) then
			p, info, b = GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = GetPlayer(dwID), GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = GetNpc(dwID), GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = GetDoodad(dwID), GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end
MY.GetObject = MY.Game.GetObject

--[[ ��ȡָ�����������
]]
MY.Game.GetObjectName = function(obj)
	if not obj then
		return nil
	end

	local szName = obj.szName
	if IsPlayer(obj.dwID) then  -- PLAYER
		if szName == "" then
			szName = nil
		end
		return szName
	elseif obj.nMaxLife then    -- NPC
		if szName == "" then
			szName = string.gsub(Table_GetNpcTemplateName(obj.dwTemplateID), "^%s*(.-)%s*$", "%1")
			if szName == "" then
				szName = nil
			end
		end
		if szName and obj.dwEmployer and obj.dwEmployer ~= 0 then
			local szEmpName = MY.Game.GetObjectName(
				(IsPlayer(obj.dwEmployer) and GetPlayer(obj.dwEmployer)) or GetNpc(obj.dwEmployer)
			) or g_tStrings.STR_SOME_BODY
			
			szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. (szName or '')
		end
		return szName
	elseif obj.CanLoot then -- DOODAD
		if szName == "" then
			szName = string.gsub(Table_GetDoodadTemplateName(obj.dwTemplateID), "^%s*(.-)%s*$", "%1")
			if szName == "" then
				szName = nil
			end
		end
	elseif obj.IsRepairable then -- ITEM
		return GetItemNameByItem(obj)
	end
end
MY.GetObjectName = MY.Game.GetObjectName

--[[ ��ȡָ�����ֵ��Ҽ��˵�
]]
MY.Game.GetTargetContextMenu = function(dwType, szName, dwID)
	local t = {}
	if dwType == TARGET.PLAYER then
		table.insert(t, {
			szOption = _L['copy'],
			fnAction = function()
				MY.Talk(GetClientPlayer().szName, '[' .. szName .. ']')
			end,
		})
		-- table.insert(t, {
		--     szOption = _L['whisper'],
		--     fnAction = function()
		--         MY.SwitchChat(szName)
		--     end,
		-- })
		pcall(InsertPlayerCommonMenu, t, dwID, szName)
		-- get dwID
		if not dwID and MY_Farbnamen then
			local tInfo = MY_Farbnamen.GetAusName(szName)
			if tInfo then
				dwID = tonumber(tInfo.dwID)
			end
		end
		-- insert view equip
		if dwID and UI_GetClientPlayerID() ~= dwID then
			table.insert(t, {
				szOption = _L['show equipment'],
				fnAction = function()
					ViewInviteToPlayer(dwID)
				end,
			})
		end
		-- insert view arena
		table.insert(t, {
			szOption = g_tStrings.LOOKUP_CORPS,
			-- fnDisable = function() return not GetPlayer(dwID) end,
			fnAction = function()
				Wnd.CloseWindow("ArenaCorpsPanel")
				OpenArenaCorpsPanel(true, dwID)
			end,
		})
		-- view qixue
		if dwID and InsertTargetMenu then
			local tx = {}
			local tTarget = { MY.GetTarget() }
			MY.SetTarget(dwType, dwID)
			InsertTargetMenu(tx, dwID) -- ����ɷ�ʵĹٷ��������û�ڶ�����ֱ��ȡ�õ�ǰĿ��FXCK���޸�
			MY.SetTarget(unpack(tTarget))
			for _, v in ipairs(tx) do
				if v.szOption == g_tStrings.LOOKUP_INFO then
					for _, vv in ipairs(v) do
						if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then
							table.insert(t, vv)
							break
						end
					end
					break
				end
			end
		end
		-- insert invite team
		if szName and InsertInviteTeamMenu then
			InsertInviteTeamMenu(t, szName)
		end
	end
	
	return t
end
MY.GetTargetContextMenu = MY.Game.GetTargetContextMenu

--[[ �ж�һ����ͼ�ǲ��Ǹ���
	(bool) MY.Game.IsDungeonMap(szMapName)
	(bool) MY.Game.IsDungeonMap(dwMapID)
]]
MY.Game.IsDungeonMap = function(szMapNameOrdwID)
	if not _Cache.tMapList then
		_Cache.tMapList = {}
		for _, dwMapID in ipairs(GetMapList()) do
			local map          = { dwID = dwMapID }
			local szName       = Table_GetMapName(dwMapID)
			local tDungeonInfo = g_tTable.DungeonInfo:Search(dwMapID)
			if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
				map.bDungeon = true
			end
			_Cache.tMapList[szName] = map
			_Cache.tMapList[dwMapID] = map
		end
	end
	
	local map = _Cache.tMapList[szMapNameOrdwID]
	if map and map.bDungeon then
		return true
	end
	return false
end
MY.IsDungeonMap = MY.Game.IsDungeonMap

--[[ ��ȡ��ͼBOSS�б�
	(table) MY.Game.GetBossList()
	(table) MY.Game.GetBossList(dwMapID)
]]
MY.Game.GetBossList = function(dwMapID)
	if dwMapID then
		dwMapID = tostring(dwMapID)
	end
	if not _C.tBossList then
		_C.tBossList = MY.Sys.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/bosslist', true) or { version = 0 }
	end
	
	if dwMapID then
		return clone(_C.tBossList[dwMapID])
	else
		return clone(_C.tBossList)
	end
end

--[[ ��ȡָ����ͼָ��ģ��ID��NPC�ǲ���BOSS
	(boolean) MY.Game.IsBoss(dwMapID, dwTem)
]]
MY.Game.IsBoss = function(dwMapID, dwTemplateID)
	dwMapID, dwTemplateID = tostring(dwMapID), tostring(dwTemplateID)
	if _C.tBossList and _C.tBossList[dwMapID]
	and _C.tBossList[dwMapID][dwTemplateID] then
		return true
	else
		return false
	end
end
MY.IsBoss = MY.Game.IsBoss

-- remote boss list online
MY.RegisterInit(function()
	-- start remote version check
	MY.RemoteRequest('http://data.jx3.derzh.com/data/bosslist.html', function(szTitle, szContent)
		-- decode data
		local data = MY.Json.Decode(szContent)
		if not data then
			MY.Debug(L["Bosslist update check failed, server respond unkown data."], 'MY::tBossList', 3)
			return
		end
		
		if not _C.tBossList then
			MY.Game.GetBossList()
		end
		
		if data.version > _C.tBossList.version then
			_C.tBossList = data
			MY.Sys.SaveLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/bosslist', _C.tBossList, true)
			MY.Sysmsg(_L('Important Npc list updated to v%d.', data.version))
		end
	end)
end)
