--------------------------------------------
-- @Desc  : 焦点列表
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-07-30 19:22:10
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-02-08 02:36:09
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Focus/lang/")
local _C = {}
_C.tFocusList = {}
_C.szIniFile = MY.GetAddonInfo().szRoot .. 'MY_Focus/ui/MY_Focus.ini'
_C.bMinimize = false
MY_Focus = {}
MY_Focus.bEnable        = true  -- 是否启用
MY_Focus.bFocusFriend   = false -- 焦点附近好友
MY_Focus.bFocusTong     = false -- 焦点帮会成员
MY_Focus.bFocusEnemy    = false -- 焦点敌对玩家
MY_Focus.bAutoHide      = true  -- 无焦点时隐藏
MY_Focus.nMaxDisplay    = 5     -- 最大显示数量
MY_Focus.bAutoFocus     = true  -- 启用默认焦点
MY_Focus.bHideDeath     = false -- 隐藏死亡目标
MY_Focus.bFocusJJCParty = false -- 焦竞技场队友
MY_Focus.bFocusJJCEnemy = true  -- 焦竞技场敌队
MY_Focus.bShowTarget    = false -- 显示目标目标
MY_Focus.bTraversal     = false -- 遍历焦点列表
MY_Focus.tAutoFocus = {}    -- 默认焦点
MY_Focus.tFocusList = {     -- 永久焦点
	[TARGET.NPC]    = {},
	[TARGET.PLAYER] = {},
	[TARGET.DOODAD] = {},
}
MY_Focus.anchor = { x=-300, y=220, s="TOPRIGHT", r="TOPRIGHT" } -- 默认坐标
RegisterCustomData("MY_Focus.bEnable")
RegisterCustomData("MY_Focus.bFocusFriend")
RegisterCustomData("MY_Focus.bFocusTong")
RegisterCustomData("MY_Focus.bFocusEnemy")
RegisterCustomData("MY_Focus.bAutoHide")
RegisterCustomData("MY_Focus.nMaxDisplay")
RegisterCustomData("MY_Focus.bAutoFocus")
RegisterCustomData("MY_Focus.bHideDeath")
RegisterCustomData("MY_Focus.bFocusJJCParty")
RegisterCustomData("MY_Focus.bFocusJJCEnemy")
RegisterCustomData("MY_Focus.bShowTarget")
RegisterCustomData("MY_Focus.bTraversal")
RegisterCustomData("MY_Focus.tAutoFocus")
RegisterCustomData("MY_Focus.tFocusList")
RegisterCustomData("MY_Focus.anchor")

local m_frame
MY_Focus.Open = function()
	m_frame = Wnd.OpenWindow(_C.szIniFile, 'MY_Focus')
	m_frame:Lookup('', 'Handle_List'):Clear()
	MY.UI(m_frame):anchor(MY_Focus.anchor)
	
	MY.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectEnterScene(TARGET.PLAYER, arg0)
	end)
	MY.RegisterEvent('NPC_ENTER_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectEnterScene(TARGET.NPC, arg0)
	end)
	MY.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectEnterScene(TARGET.DOODAD, arg0)
	end)
	MY.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectLeaveScene(TARGET.PLAYER, arg0)
	end)
	MY.RegisterEvent('NPC_LEAVE_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectLeaveScene(TARGET.NPC, arg0)
	end)
	MY.RegisterEvent('DOODAD_LEAVE_SCENE', 'MY_Focus', function()
		MY_Focus.OnObjectLeaveScene(TARGET.DOODAD, arg0)
	end)
	MY_Focus.ScanNearby()
end

MY_Focus.Close = function()
	Wnd.CloseWindow(m_frame)
	MY.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Focus')
	MY.RegisterEvent('NPC_ENTER_SCENE'   , 'MY_Focus')
	MY.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Focus')
	MY.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_Focus')
	MY.RegisterEvent('NPC_LEAVE_SCENE'   , 'MY_Focus')
	MY.RegisterEvent('DOODAD_LEAVE_SCENE', 'MY_Focus')
end

-- 获取当前显示的焦点列表
MY_Focus.GetDisplayList = function()
	local t = {}
	if _C.bMinimize then
		return t
	end
	for i, v in ipairs(_C.tFocusList) do
		if i > MY_Focus.nMaxDisplay then
			break
		end
		table.insert(t, v)
	end
	return t
end

-- 获取指定焦点的Handle 没有返回nil
MY_Focus.GetHandle = function(dwType, dwID)
	return Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
end

-- 添加默认焦点
MY_Focus.AddAutoFocus = function(szName)
	for _, v in ipairs(MY_Focus.tAutoFocus) do
		if v == szName then
			return
		end
	end
	table.insert(MY_Focus.tAutoFocus, szName)
	-- 更新焦点列表
	MY_Focus.ScanNearby()
end

-- 删除默认焦点
MY_Focus.DelAutoFocus = function(szName)
	for i = #MY_Focus.tAutoFocus, 1, -1 do
		if MY_Focus.tAutoFocus[i] == szName then
			table.remove(MY_Focus.tAutoFocus, i)
		end
	end
	-- 刷新UI
	if szName:sub(1,1) == '^' then
		-- 正则表达式模式：重绘焦点列表
		MY_Focus.RescanNearby()
	else
		-- 全字符匹配模式：检查是否在永久焦点中 没有则删除Handle
		for i = #_C.tFocusList, 1, -1 do
			local p = _C.tFocusList[i]
			local h = MY.Game.GetObject(p.dwType, p.dwID)
			if h and MY.Game.GetObjectName(h) == szName and
			not MY_Focus.tFocusList[p.dwType][p.dwID] then
				MY_Focus.OnObjectLeaveScene(p.dwType, p.dwID)
			end
		end
	end
end

-- 添加永久焦点
MY_Focus.AddStaticFocus = function(dwType, dwID)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	for _dwType, tFocusList in pairs(MY_Focus.tFocusList) do
		for _dwID, _ in pairs(tFocusList) do
			if _dwType == dwType and _dwID == dwID then
				return
			end
		end
	end
	MY_Focus.tFocusList[dwType][dwID] = true
	MY_Focus.OnObjectEnterScene(dwType, dwID)
end

-- 删除永久焦点
MY_Focus.DelStaticFocus = function(dwType, dwID)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	MY_Focus.tFocusList[dwType][dwID] = nil
	MY_Focus.OnObjectLeaveScene(dwType, dwID)
end

-- 重新扫描附近对象更新焦点列表（只增不减）
MY_Focus.ScanNearby = function()
	for dwID, _ in pairs(MY.Player.GetNearPlayer()) do
		MY_Focus.OnObjectEnterScene(TARGET.PLAYER, dwID)
	end
	for dwID, _ in pairs(MY.Player.GetNearNpc()) do
		MY_Focus.OnObjectEnterScene(TARGET.NPC, dwID)
	end
	for dwID, _ in pairs(MY.Player.GetNearDoodad()) do
		MY_Focus.OnObjectEnterScene(TARGET.DOODAD, dwID)
	end
end

-- 对象进入视野
MY_Focus.OnObjectEnterScene = function(dwType, dwID, nRetryCount)
	if nRetryCount and nRetryCount >5 then
		return
	end
	local obj = MY.Game.GetObject(dwType, dwID)
	if not obj then
		return
	end

	local szName = MY.Game.GetObjectName(obj)
	-- 解决玩家刚进入视野时名字为空的问题
	if (dwType == TARGET.PLAYER and not szName) or
	not (GetClientPlayer()) then -- 解决自身刚进入场景的时候的问题
		MY.DelayCall(function()
			MY_Focus.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
		end, 300)
	elseif szName then -- 判断是否需要焦点
		local bFocus = false
		-- 判断永久焦点
		if MY_Focus.tFocusList[dwType][dwID] then
			bFocus = true
		end
		-- 判断默认焦点
		if MY_Focus.bAutoFocus and not bFocus then
			for _, v in ipairs(MY_Focus.tAutoFocus) do
				if v == szName or
				(v:sub(1,1) == '^' and string.find(szName, v)) then
					bFocus = true
				end
			end
		end
		-- 判断竞技场
		if MY.Player.IsInArena() then
			if dwType == TARGET.PLAYER then
				if MY_Focus.bFocusJJCEnemy and MY_Focus.bFocusJJCParty then
					bFocus = true
				elseif MY_Focus.bFocusJJCParty then
					if not IsEnemy(UI_GetClientPlayerID(), dwID) then
						bFocus = true
					end
				elseif MY_Focus.bFocusJJCEnemy then
					if IsEnemy(UI_GetClientPlayerID(), dwID) then
						bFocus = true
					end
				end
			end
		else
			if not MY.Player.IsInBattleField() then
				-- 判断好友
				if dwType == TARGET.PLAYER and
				MY_Focus.bFocusFriend and
				MY.Player.GetFriend(dwID) then
					bFocus = true
				end
				-- 判断同帮会
				if dwType == TARGET.PLAYER and
				MY_Focus.bFocusTong and
				dwID ~= MY.GetClientInfo().dwID and
				MY.Player.GetTongMember(dwID) then
					bFocus = true
				end
			end
			-- 判断敌对玩家
			if dwType == TARGET.PLAYER and
			MY_Focus.bFocusEnemy and
			IsEnemy(UI_GetClientPlayerID(), dwID) then
				bFocus = true
			end
		end
		
		-- 加入焦点
		if bFocus then
			MY_Focus.AddFocus(dwType, dwID)
		end
	end
end

-- 对象离开视野
MY_Focus.OnObjectLeaveScene = function(dwType, dwID)
	MY_Focus.DelFocus(dwType, dwID)
end

-- 目标加入焦点列表
MY_Focus.AddFocus = function(dwType, dwID, szName)
	local nIndex
	for i, p in ipairs(_C.tFocusList) do
		if p.dwType == dwType and p.dwID == dwID then
			nIndex = i
			break
		end
	end
	if not nIndex then
		table.insert(_C.tFocusList, {dwType = dwType, dwID = dwID, szName = szName})
		nIndex = #_C.tFocusList
	end
	if nIndex < MY_Focus.nMaxDisplay then
		MY_Focus.DrawFocus(dwType, dwID)
		MY_Focus.AdjustUI()
	end
end

-- 目标移除焦点列表
MY_Focus.DelFocus = function(dwType, dwID)
	-- 从列表数据中删除
	for i = #_C.tFocusList, 1, -1 do
		local p = _C.tFocusList[i]
		if p.dwType == dwType and p.dwID == dwID then
			table.remove(_C.tFocusList, i)
			break
		end
	end
	-- 从UI中删除
	local hItem = Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
	if hItem then
		MY.UI(hItem):remove()
		-- 补上UI（超过数量限制时）
		local p = _C.tFocusList[MY_Focus.nMaxDisplay]
		if p then
			MY_Focus.DrawFocus(p.dwType, p.dwID)
		end
	end
end

-- 获取焦点列表
MY_Focus.GetFocusList = function()
	local t = {}
	for _, v in ipairs(_C.tFocusList) do
		table.insert(t, v)
	end
	return t
end

-- 清空焦点列表
MY_Focus.ClearFocus = function()
	_C.tFocusList = {}
	
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if not hList then
		return
	end
	hList:Clear()
end

-- 重新扫描附近焦点
MY_Focus.RescanNearby = function()
	MY_Focus.ClearFocus()
	MY_Focus.ScanNearby()
end

-- 重绘列表
MY_Focus.RedrawList = function(hList)
	if not hList then
		hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
		if not hList then
			return
		end
	end
	hList:Clear()
	MY_Focus.UpdateList()
end

-- 更新列表
MY_Focus.UpdateList = function()
	for i, p in ipairs(MY_Focus.GetDisplayList()) do
		MY_Focus.DrawFocus(p.dwType, p.dwID)
	end
end

-- 绘制指定的焦点Handle（没有则添加创建）
MY_Focus.DrawFocus = function(dwType, dwID)
	local obj, info, bInfo = MY.Game.GetObject(dwType, dwID)
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if not (obj and hList) then
		return
	end

	local hItem = MY_Focus.GetHandle(dwType, dwID)
	if not hItem then
		hItem = hList:AppendItemFromIni(_C.szIniFile, 'Handle_Info')
		hItem:SetName('Handle_Info_'..dwType..'_'..dwID)
	end
	
	-- 名字
	hItem:Lookup('Handle_Name/Text_Name'):SetText(MY.Game.GetObjectName(obj) or obj.dwID)
	-- 心法
	if dwType == TARGET.PLAYER then
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_Name/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(info.dwMountKungfuID))
		else
			local kungfu = obj.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_Name/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(kungfu.dwSkillID))
			end
		end
	end
	-- 血量
	if dwType ~= TARGET.DOODAD then
		local nCurrentLife, nMaxLife = info.nCurrentLife, info.nMaxLife
		local nCurrentMana, nMaxMana = info.nCurrentMana, info.nMaxMana
		local szLife = ''
		if nCurrentLife > 10000 then
			szLife = szLife .. FormatString(g_tStrings.MPNEY_TENTHOUSAND, math.floor(nCurrentLife / 1000) / 10)
		else
			szLife = szLife .. nCurrentLife
		end
		if nMaxLife > 0 then
			local nPercent = math.floor(nCurrentLife / nMaxLife * 100)
			if nPercent > 100 then
				nPercent = 100
			end
			szLife = szLife .. '(' .. nPercent .. '%)'
			hItem:Lookup('Handle_LM/Image_Health'):SetPercentage(nCurrentLife / nMaxLife)
			hItem:Lookup('Handle_LM/Text_Health'):SetText(szLife)
		end
		if nMaxMana > 0 then
			hItem:Lookup('Handle_LM/Image_Mana'):SetPercentage(nCurrentMana / nMaxMana)
			hItem:Lookup('Handle_LM/Text_Mana'):SetText(nCurrentMana .. '/' .. nMaxMana)
		end
	end
	-- 读条
	if dwType ~= TARGET.DOODAD then
		local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillPrepareState()
		if MY_Focus.bTraversal and dwType == TARGET.PLAYER
		and (not bIsPrepare and obj.GetOTActionState() == 1) then
			MY.Player.WithTarget(dwType, dwID, function()
				local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillPrepareState()
				if bIsPrepare then
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText(MY_Focus.GetSkillName(dwSkillID, dwSkillLevel))
				else
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
				end
			end)
		else
			if bIsPrepare then
				hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
				hItem:Lookup('Handle_Progress/Text_Progress'):SetText(MY_Focus.GetSkillName(dwSkillID, dwSkillLevel))
			else
				hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
				hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
			end
		end
	end
	-- 目标的目标
	if MY_Focus.bShowTarget and dwType ~= TARGET.DOODAD then
		local tp, id = obj.GetTarget()
		local tar = MY.Game.GetObject(tp, id)
		if tar then
			hItem:Lookup('Handle_Progress/Text_Target'):SetText(MY.Game.GetObjectName(tar) or tar.dwID)
		else
			hItem:Lookup('Handle_Progress/Text_Target'):SetText('')
		end
	end
	-- 选中状态
	hItem:Lookup('Image_Select'):Hide()
	local player = GetClientPlayer()
	if player then
		local dwTargetType, dwTargetID = player.GetTarget()
		if dwTargetType == dwType and dwTargetID == dwID then
			hItem:Lookup('Image_Select'):Show()
		end
	end
	-- 目标距离
	local nDistance = math.floor(math.sqrt(math.pow(player.nX - obj.nX, 2) + math.pow(player.nY - obj.nY, 2)) * 10 / 64) / 10
	hItem:Lookup('Handle_Compass/Compass_Distance'):SetText(nDistance)
	-- 自身面向
	if player then
		hItem:Lookup('Handle_Compass/Image_Player'):Show()
		hItem:Lookup('Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
	end
	-- 相对位置
	hItem:Lookup('Handle_Compass/Image_PointRed'):Hide()
	hItem:Lookup('Handle_Compass/Image_PointGreen'):Hide()
	if player and nDistance > 0 then
		local h
		if IsEnemy(UI_GetClientPlayerID(), dwID) then
			h = hItem:Lookup('Handle_Compass/Image_PointRed')
		else
			h = hItem:Lookup('Handle_Compass/Image_PointGreen')
		end
		h:Show()
		local nRotate = 0
		-- 特判角度
		if player.nX == obj.nX then
			if player.nY > obj.nY then
				nRotate = math.pi / 2
			else
				nRotate = - math.pi / 2
			end
		else
			nRotate = math.atan((player.nY - obj.nY) / (player.nX - obj.nX))
		end
		if nRotate < 0 then
			nRotate = nRotate + math.pi
		end
		if obj.nY < player.nY then
			nRotate = math.pi + nRotate
		end
		local nRadius = 13.5
		h:SetRelPos(nRadius + nRadius * math.cos(nRotate) + 2, nRadius - 3 - 13.5 * math.sin(nRotate))
		h:GetParent():FormatAllItemPos()
	end
	
	hItem:FormatAllItemPos()
	hList:FormatAllItemPos()
end

-- 自适应调整界面大小
MY_Focus.AdjustUI = function()
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if not hList then
		return
	end
	
	local tList = MY_Focus.GetDisplayList()
	hList:SetSize(240, 70 * #tList)
	hList:GetRoot():SetSize(240, 70 * #tList + 32)
	if #tList == 0 and MY_Focus.bAutoHide and not _C.bMinimize then
		hList:GetRoot():Hide()
	elseif (not MY_Focus.bAutoHide) or #tList ~= 0 then
		hList:GetRoot():Show()
	end
end

-- 获取内功心法字符串
local m_tKungfuName = {}
MY_Focus.GetKungfuName = function(dwKungfuID)
	if not m_tKungfuName[dwKungfuID] then
		m_tKungfuName[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1)
	end
	return m_tKungfuName[dwKungfuID]
end

-- 获取技能名称字符串
local m_tSkillName = {}
MY_Focus.GetSkillName = function(dwSkillID, dwSkillLevel)
	if not m_tSkillName[dwSkillID] then
		m_tSkillName[dwSkillID] = Table_GetSkillName(dwSkillID, dwSkillLevel)
	end
	return m_tSkillName[dwSkillID]
end

--[[
##########################################################################
									#                 #         #         
						  # # # # # # # # # # #       #   #     #         
  # #     # # # # # # #       #     #     #         #     #     #         
	#     #       #           # # # # # # #         #     # # # # # # #   
	#     #       #                 #             # #   #       #         
	#     #       #         # # # # # # # # #       #           #         
	#     #       #                 #       #       #           #         
	#     #       #       # # # # # # # # # # #     #   # # # # # # # #   
	#     #       #                 #       #       #           #         
	  # #     # # # # #     # # # # # # # # #       #           #         
									#               #           #         
								  # #               #           #         
##########################################################################
]]

-- 周期重绘
MY_Focus.OnFrameBreathe = function()
	if MY_Focus.bHideDeath then
		for _, p in ipairs(MY_Focus.GetFocusList()) do
			if p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER then
				local tar = MY.GetObject(p.dwType, p.dwID)
				if not tar or tar.nMoveState == MOVE_STATE.ON_DEATH then
					MY_Focus.DelFocus(p.dwType, p.dwID)
				end
			end
		end
	end
	MY_Focus.UpdateList()
	MY_Focus.AdjustUI()
end

MY_Focus.OnFrameDragSetPosEnd = function()
	this:CorrectPos()
	MY_Focus.anchor = MY.UI(this):anchor('TOPRIGHT')
end

MY_Focus.OnItemLButtonClick = function()
	local name = this:GetName()
	name:gsub('Handle_Info_(%d+)_(%d+)', function(dwType, dwID)
		SetTarget(dwType, dwID)
	end)
end

MY_Focus.OnItemRButtonClick = function()
	local name = this:GetName()
	name:gsub('Handle_Info_(%d+)_(%d+)', function(dwType, dwID)
		dwType, dwID = tonumber(dwType), tonumber(dwID)
		local t = {}
		if dwType == TARGET.PLAYER then
			t = MY.Game.GetTargetContextMenu(dwType, this:Lookup('Handle_Name/Text_Name'):GetText(), dwID)
		end
		table.insert(t, 1, {
			szOption = _L['delete focus'],
			fnAction = function()
				MY_Focus.DelStaticFocus(dwType, dwID)
			end
		})
		PopupMenu(t)
	end)
end

MY_Focus.OnLButtonClick = function()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		MY.OpenPanel()
		MY.SwitchTab('MY_Focus')
	end
end

MY_Focus.OnCheckBoxCheck = function()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		_C.bMinimize = true
		this:GetRoot():Lookup('', 'Handle_List'):Hide()
	end
end

MY_Focus.OnCheckBoxUncheck = function()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		_C.bMinimize = false
		this:GetRoot():Lookup('', 'Handle_List'):Show()
	end
end

MY.RegisterTargetAddonMenu('MY_Focus', function()
	local dwType, dwID = GetClientPlayer().GetTarget()
	return {
		szOption = _L['add to focus list'],
		fnAction = function()
			MY_Focus.AddStaticFocus(dwType, dwID)
		end,
	}
end)

MY.RegisterInit(function()
	if MY_Focus.bEnable then
		MY_Focus.Open()
	else
		MY_Focus.Close()
	end
end)

MY.RegisterPanel( "MY_Focus", _L["focus list"], _L['Target'], "ui/Image/button/SystemButton_1.UITex|9", {255,255,0,200}, { OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local xr, yr, wr = w - 240, 40, 240
	local xl, yl, wl = 5,  5, w - wr -15
	
	-- 左侧
	local x, y = xl, yl
	ui:append("WndCheckBox_Enable", "WndCheckBox"):children("#WndCheckBox_Enable")
	  :pos(x, y):width(250):text(_L['enable']):color(255, 255, 0):check(MY_Focus.bEnable)
	  :check(function(bChecked)
	  	MY_Focus.bEnable = bChecked
	  	if MY_Focus.bEnable then
	  		MY_Focus.Open()
	  	else
	  		MY_Focus.Close()
	  	end
	  end)
	y = y + 25
	
	-- <hr />
	ui:append('Image_Spliter','Image'):item('#Image_Spliter')
	  :pos(x, y):size(w - x, 1):image('UI/Image/UICommon/ScienceTreeNode.UITex', 62)
	y = y + 5
	
	ui:append("WndCheckBox_AutoFocus", "WndCheckBox"):children("#WndCheckBox_AutoFocus")
	  :pos(x, y):text(_L['auto focus']):check(MY_Focus.bAutoFocus)
	  :check(function(bChecked)
	  	MY_Focus.bAutoFocus = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	
	local list = ui:append('WndListBox_1', 'WndListBox'):children('#WndListBox_1'):pos(x, y + 30):size(wl - x + xl, h - y - 40)
	-- 初始化list控件
	for _, v in ipairs(MY_Focus.tAutoFocus) do
		list:listbox('insert', v, v)
	end
	list:listbox('onmenu', function(szText, szID)
		return {{
			szOption = _L['delete'],
			fnAction = function()
				list:listbox('delete', szText, szID)
				for i = #MY_Focus.tAutoFocus, 1, -1 do
					if MY_Focus.tAutoFocus[i] == szText then
						table.remove(MY_Focus.tAutoFocus, i)
						MY_Focus.RescanNearby()
					end
				end
			end,
		}}
	end)
	-- add
	ui:append("WndButton_Add", "WndButton"):children("#WndButton_Add")
	  :pos(wl - 160, y):width(80)
	  :text(_L["add"])
	  :click(function()
	  	GetUserInput(_L['add auto focus'], function(szText)
	  		-- 去掉前后空格
	  		szText = (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
	  		-- 验证是否为空
	  		if szText=="" then
	  			return
	  		end
	  		-- 验证是否重复
	  		for i, v in ipairs(MY_Focus.tAutoFocus) do
	  			if v == szText then
	  				return
	  			end
	  		end
	  		-- 加入表
	  		table.insert(MY_Focus.tAutoFocus, szText)
	  		-- 更新UI
	  		list:listbox('insert', szText, szText)
	  		MY_Focus.RescanNearby()
	  	end, function() end, function() end, nil, '')
	  end)
	-- del
	ui:append("WndButton_Del", "WndButton"):children("#WndButton_Del")
	  :pos(wl - 80, y):width(80)
	  :text(_L["delete"])
	  :click(function()
	  	for _, v in ipairs(list:listbox('select', 'selected')) do
	  		list:listbox('delete', v.text, v.id)
	  		for i = #MY_Focus.tAutoFocus, 1, -1 do
	  			if MY_Focus.tAutoFocus[i] == v.text then
	  				table.remove(MY_Focus.tAutoFocus, i)
	  				MY_Focus.RescanNearby()
	  			end
	  		end
	  	end
	  end)
	
	-- 右侧
	local x, y = xr, yr
	ui:append("WndCheckBox_Auto_Hide", "WndCheckBox"):children("#WndCheckBox_Auto_Hide")
	  :pos(x, y):width(wr):text(_L['hide when empty']):check(MY_Focus.bAutoHide)
	  :check(function(bChecked)
	  	MY_Focus.bAutoHide = bChecked
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_AF_Friend", "WndCheckBox"):children("#WndCheckBox_AF_Friend")
	  :pos(x, y):width(wr):text(_L['auto focus friend']):check(MY_Focus.bFocusFriend)
	  :check(function(bChecked)
	  	MY_Focus.bFocusFriend = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_AF_Tong", "WndCheckBox"):children("#WndCheckBox_AF_Tong")
	  :pos(x, y):width(wr):text(_L['auto focus tong']):check(MY_Focus.bFocusTong)
	  :check(function(bChecked)
	  	MY_Focus.bFocusTong = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_AF_Enemy", "WndCheckBox"):children("#WndCheckBox_AF_Enemy")
	  :pos(x, y):width(wr):text(_L['auto focus enemy']):check(MY_Focus.bFocusEnemy)
	  :check(function(bChecked)
	  	MY_Focus.bFocusEnemy = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_AF_JJCParty", "WndCheckBox"):children("#WndCheckBox_AF_JJCParty")
	  :pos(x, y):width(wr):text(_L['jjc auto focus party']):check(MY_Focus.bFocusJJCParty)
	  :check(function(bChecked)
	  	MY_Focus.bFocusJJCParty = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_AF_JJCEnemy", "WndCheckBox"):children("#WndCheckBox_AF_JJCEnemy")
	  :pos(x, y):width(wr):text(_L['jjc auto focus enemy']):check(MY_Focus.bFocusJJCEnemy)
	  :check(function(bChecked)
	  	MY_Focus.bFocusJJCEnemy = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_ShowTarget", "WndCheckBox"):children("#WndCheckBox_ShowTarget")
	  :pos(x, y):width(wr):text(_L['show focus\'s target']):check(MY_Focus.bShowTarget)
	  :check(function(bChecked)
	  	MY_Focus.bShowTarget = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_Traversal", "WndCheckBox"):children("#WndCheckBox_Traversal")
	  :pos(x, y):width(wr):text(_L['traversal object']):tip(_L['may cause some problem in dungeon map'])
	  :check(MY_Focus.bTraversal)
	  :check(function(bChecked)
	  	MY_Focus.bTraversal = bChecked
	  end)
	y = y + 30
	
	ui:append("WndCheckBox_HideDead", "WndCheckBox"):children("#WndCheckBox_HideDead")
	  :pos(x, y):width(wr):text(_L['hide dead object']):check(MY_Focus.bHideDeath)
	  :check(function(bChecked)
	  	MY_Focus.bHideDeath = bChecked
	  	MY_Focus.RescanNearby()
	  end)
	y = y + 30
	
	ui:append("WndComboBox_MaxLength", "WndComboBox"):children("#WndComboBox_MaxLength")
	  :pos(x, y):width(150)
	  :text(_L['max display length'])
	  :menu(function()
	  	local t = {}
	  	for i = 1, 15 do
	  		table.insert(t, {
	  			szOption = i,
	  			bMCheck = true,
	  			bChecked = MY_Focus.nMaxDisplay == i,
	  			fnAction = function()
	  				Wnd.CloseWindow('PopupMenuPanel')
	  				MY_Focus.nMaxDisplay = i
	  				MY_Focus.RedrawList()
	  			end,
	  		})
	  	end
	  	return t
	  end)
	y = y + 30
end})
