--------------------------------------------
-- @Desc  : 焦点列表
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-07-30 19:22:10
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-05-27 10:59:42
--------------------------------------------
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_Focus/ui/MY_Focus.ini'
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Focus/lang/")
local l_tFocusList = {}
local l_bMinimize = false
local l_dwLockType, l_dwLockID, l_lockInDisplay
MY_Focus = {}
MY_Focus.bEnable            = false -- 是否启用
MY_Focus.bFocusBoss         = true  -- 焦点重要NPC
MY_Focus.bFocusFriend       = false -- 焦点附近好友
MY_Focus.bFocusTong         = false -- 焦点帮会成员
MY_Focus.bOnlyPublicMap     = true  -- 仅在公共地图焦点好友帮会成员
MY_Focus.bSortByDistance    = false -- 优先焦点近距离目标
MY_Focus.bFocusEnemy        = false -- 焦点敌对玩家
MY_Focus.bAutoHide          = true  -- 无焦点时隐藏
MY_Focus.nMaxDisplay        = 5     -- 最大显示数量
MY_Focus.bAutoFocus         = true  -- 启用默认焦点
MY_Focus.bHideDeath         = false -- 隐藏死亡目标
MY_Focus.bDisplayKungfuIcon = false -- 显示心法图标
MY_Focus.bFocusJJCParty     = false -- 焦竞技场队友
MY_Focus.bFocusJJCEnemy     = true  -- 焦竞技场敌队
MY_Focus.bShowTarget        = false -- 显示目标目标
MY_Focus.bTraversal         = false -- 遍历焦点列表
MY_Focus.bHealHelper        = false -- 辅助治疗模式
MY_Focus.bEnableSceneNavi   = false -- 场景追踪点
MY_Focus.fScaleX            = 1     -- 缩放比例
MY_Focus.fScaleY            = 1     -- 缩放比例
MY_Focus.tAutoFocus = {}    -- 默认焦点
MY_Focus.tFocusList = {     -- 永久焦点
	[TARGET.NPC]    = {},
	[TARGET.PLAYER] = {},
	[TARGET.DOODAD] = {},
}
MY_Focus.tFocusTplList = {  -- 永久焦点(按照TemplateID)
	[TARGET.NPC]    = {},
	[TARGET.DOODAD] = {},
}
MY_Focus.anchor = { x=-300, y=220, s="TOPRIGHT", r="TOPRIGHT" } -- 默认坐标
RegisterCustomData("MY_Focus.bEnable", 1)
RegisterCustomData("MY_Focus.bFocusBoss")
RegisterCustomData("MY_Focus.bFocusFriend")
RegisterCustomData("MY_Focus.bFocusTong")
RegisterCustomData("MY_Focus.bOnlyPublicMap")
RegisterCustomData("MY_Focus.bSortByDistance")
RegisterCustomData("MY_Focus.bFocusEnemy")
RegisterCustomData("MY_Focus.bAutoHide")
RegisterCustomData("MY_Focus.nMaxDisplay")
RegisterCustomData("MY_Focus.bAutoFocus")
RegisterCustomData("MY_Focus.bHideDeath")
RegisterCustomData("MY_Focus.bDisplayKungfuIcon")
RegisterCustomData("MY_Focus.bFocusJJCParty")
RegisterCustomData("MY_Focus.bFocusJJCEnemy")
RegisterCustomData("MY_Focus.bShowTarget")
RegisterCustomData("MY_Focus.bTraversal")
RegisterCustomData("MY_Focus.bHealHelper")
RegisterCustomData("MY_Focus.bEnableSceneNavi")
RegisterCustomData("MY_Focus.tAutoFocus")
RegisterCustomData("MY_Focus.tFocusList")
RegisterCustomData("MY_Focus.tFocusTplList")
RegisterCustomData("MY_Focus.anchor")
RegisterCustomData("MY_Focus.fScaleX")
RegisterCustomData("MY_Focus.fScaleY")

function MY_Focus.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_Focus')
end

function MY_Focus.Close()
	local hFrame = MY_Focus.GetFrame()
	if hFrame then
		Wnd.CloseWindow(hFrame)
	end
end

function MY_Focus.GetFrame(szWnd, szItem)
	if szWnd then
		if szItem then
			return Station.Lookup('Normal/MY_Focus/' .. szWnd, szItem)
		else
			return Station.Lookup('Normal/MY_Focus/' .. szWnd)
		end
	else
		return Station.Lookup('Normal/MY_Focus')
	end
end

function MY_Focus.SetScale(fScaleX, fScaleY)
	MY_Focus.fScaleX = fScaleX
	MY_Focus.fScaleY = fScaleY
	
	local hFrame = MY_Focus.GetFrame()
	if not hFrame then
		return
	end
	if hFrame.fScaleX and hFrame.fScaleY then
		-- hFrame:SetSize(hFrame:GetW() / hFrame.fScaleX, hFrame:GetH() / hFrame.fScaleY)
		hFrame:Scale(1 / hFrame.fScaleX, 1 / hFrame.fScaleY)
	end
	hFrame.fScaleX = fScaleX
	hFrame.fScaleY = fScaleY
	-- hFrame:SetSize(hFrame:GetW() / hFrame.fScaleX, hFrame:GetH() / hFrame.fScaleY)
	hFrame:Scale(fScaleX, fScaleY)
end

-- 获取当前显示的焦点列表
function MY_Focus.GetDisplayList()
	local t = {}
	if l_bMinimize then
		return t
	end
	if MY_Focus.bHideDeath then
		for _, p in ipairs(l_tFocusList) do
			if #t >= MY_Focus.nMaxDisplay then
				break
			end
			local tar = MY.GetObject(p.dwType, p.dwID)
			if tar and not (
				((p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER) and tar.nMoveState == MOVE_STATE.ON_DEATH)
				or (p.dwType == TARGET.DOODAD and tar.nKind == DOODAD_KIND.CORPSE)
			) then
				table.insert(t, p)
			end
		end
	else
		for i, v in ipairs(l_tFocusList) do
			if i > MY_Focus.nMaxDisplay then
				break
			end
			table.insert(t, v)
		end
	end
	return t
end

function MY_Focus.SortFocus(fn)
	local p = GetClientPlayer()
	fn = fn or function(p1, p2)
		p1 = MY.GetObject(p1.dwType, p1.dwID)
		p2 = MY.GetObject(p2.dwType, p2.dwID)
		if p1 and p2 then
			return math.pow(p.nX - p1.nX, 2) + math.pow(p.nY - p1.nY, 2) < math.pow(p.nX - p2.nX, 2) + math.pow(p.nY - p2.nY, 2)
		end
		return true
	end
	table.sort(l_tFocusList, fn)
end

-- 获取指定焦点的Handle 没有返回nil
function MY_Focus.GetHandle(dwType, dwID)
	return Station.Lookup('Normal/MY_Focus', 'Handle_List/HI_'..dwType..'_'..dwID)
end

-- 添加默认焦点
function MY_Focus.AddAutoFocus(szName)
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
function MY_Focus.DelAutoFocus(szName)
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
		for i = #l_tFocusList, 1, -1 do
			local p = l_tFocusList[i]
			local h = MY.Game.GetObject(p.dwType, p.dwID)
			if h and MY.Game.GetObjectName(h) == szName and
			not MY_Focus.tFocusList[p.dwType][p.dwID] then
				MY_Focus.OnObjectLeaveScene(p.dwType, p.dwID)
			end
		end
	end
end

-- 添加永久焦点
function MY_Focus.AddStaticFocus(dwType, dwID, bDistinctTplID)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	if bDistinctTplID then
		local KObject = MY.GetObject(dwType, dwID)
		local dwTemplateID = KObject.dwTemplateID
		if MY_Focus.tFocusTplList[dwType]
		and MY_Focus.tFocusTplList[dwType][dwTemplateID] then
			return
		end
		MY_Focus.tFocusTplList[dwType][dwTemplateID] = true
		MY_Focus.RescanNearby()
	else
		if MY_Focus.tFocusList[dwType]
		and MY_Focus.tFocusList[dwType][dwID] then
			return
		end
		MY_Focus.tFocusList[dwType][dwID] = true
		MY_Focus.OnObjectEnterScene(dwType, dwID)
	end
end

-- 删除永久焦点
function MY_Focus.DelStaticFocus(dwType, dwID)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	if MY_Focus.tFocusList[dwType][dwID] then
		MY_Focus.tFocusList[dwType][dwID] = nil
		MY_Focus.OnObjectLeaveScene(dwType, dwID)
	else
		local KObject = MY.GetObject(dwType, dwID)
		local dwTemplateID = KObject.dwTemplateID
		if MY_Focus.tFocusTplList[dwType]
		and MY_Focus.tFocusTplList[dwType][dwTemplateID] then
			MY_Focus.tFocusTplList[dwType][dwTemplateID] = nil
		end
		MY_Focus.RescanNearby()
	end
end

-- 重新扫描附近对象更新焦点列表（只增不减）
function MY_Focus.ScanNearby()
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
function MY_Focus.OnObjectEnterScene(dwType, dwID, nRetryCount)
	if nRetryCount and nRetryCount > 5 then
		return
	end
	local me = GetClientPlayer()
	local obj = MY.Game.GetObject(dwType, dwID)
	if not obj then
		return
	end

	local szName = MY.Game.GetObjectName(obj)
	-- 解决玩家刚进入视野时名字为空的问题
	if (dwType == TARGET.PLAYER and not szName) or
	not me then -- 解决自身刚进入场景的时候的问题
		MY.DelayCall(300, function()
			MY_Focus.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
		end)
	elseif szName then -- 判断是否需要焦点
		local bFocus = false
		-- 判断永久焦点
		if MY_Focus.tFocusList[dwType][dwID] then
			bFocus = true
		end
		if dwType ~= TARGET.PLAYER then
			if MY_Focus.tFocusTplList[dwType][obj.dwTemplateID] then
				bFocus = true
			end
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
		if MY.IsInArena() then
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
			elseif dwType == TARGET.NPC then
				if MY_Focus.bFocusJJCParty
				and not IsEnemy(UI_GetClientPlayerID(), dwID)
				and obj.dwTemplateID == 46140 then -- 清绝歌影 的主体影子
					MY_Focus.DelFocus(TARGET.PLAYER, obj.dwEmployer)
					bFocus = true
				end
			end
		else
			if not MY_Focus.bOnlyPublicMap or (not MY.IsInBattleField() and not MY.IsInDungeon(true) and not MY.IsInArena()) then
				-- 判断好友
				if dwType == TARGET.PLAYER and
				MY_Focus.bFocusFriend and
				MY.GetFriend(dwID) then
					bFocus = true
				end
				-- 判断同帮会
				if dwType == TARGET.PLAYER and
				MY_Focus.bFocusTong and
				dwID ~= MY.GetClientInfo().dwID and
				MY.GetTongMember(dwID) then
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
		
		-- 判断重要NPC
		if not bFocus and
		dwType == TARGET.NPC and
		MY_Focus.bFocusBoss and
		MY.IsBoss(me.GetMapID(), obj.dwTemplateID) then
			bFocus = true
		end
		
		-- 加入焦点
		if bFocus then
			MY_Focus.AddFocus(dwType, dwID, szName)
		end
	end
end

-- 对象离开视野
function MY_Focus.OnObjectLeaveScene(dwType, dwID)
	local KObject = MY.GetObject(dwType, dwID)
	if KObject then
		if dwType == TARGET.NPC then
			if MY_Focus.bFocusJJCParty
			and MY.IsInArena()
			and not IsEnemy(UI_GetClientPlayerID(), dwID)
			and KObject.dwTemplateID == 46140 then -- 清绝歌影 的主体影子
				MY_Focus.AddFocus(TARGET.PLAYER, KObject.dwEmployer, MY.GetObjectName(KObject))
			end
		end
	end
	MY_Focus.DelFocus(dwType, dwID)
end

-- 目标加入焦点列表
function MY_Focus.AddFocus(dwType, dwID, szName)
	local nIndex
	for i, p in ipairs(l_tFocusList) do
		if p.dwType == dwType and p.dwID == dwID then
			nIndex = i
			break
		end
	end
	if not nIndex then
		table.insert(l_tFocusList, {dwType = dwType, dwID = dwID, szName = szName})
		nIndex = #l_tFocusList
	end
	if nIndex < MY_Focus.nMaxDisplay then
		MY_Focus.DrawFocus(dwType, dwID)
		MY_Focus.AdjustUI()
	end
end

-- 目标移除焦点列表
function MY_Focus.DelFocus(dwType, dwID)
	-- 从列表数据中删除
	for i = #l_tFocusList, 1, -1 do
		local p = l_tFocusList[i]
		if p.dwType == dwType and p.dwID == dwID then
			table.remove(l_tFocusList, i)
			break
		end
	end
	-- 从UI中删除
	local szKey = 'HI_' .. dwType .. '_' .. dwID
	local hItem = Station.Lookup('Normal/MY_Focus', 'Handle_List/' .. szKey)
	if hItem then
		if MY_Focus.bEnableSceneNavi and Navigator_Remove then
			Navigator_Remove("MY_FOCUS." .. szKey:sub(4))
		end
		MY.UI(hItem):remove()
		-- 补上UI（超过数量限制时）
		local p = l_tFocusList[MY_Focus.nMaxDisplay]
		if p then
			MY_Focus.DrawFocus(p.dwType, p.dwID)
		end
	end
end

-- 获取焦点列表
function MY_Focus.GetFocusList()
	local t = {}
	for _, v in ipairs(l_tFocusList) do
		table.insert(t, v)
	end
	return t
end

-- 清空焦点列表
function MY_Focus.ClearFocus()
	l_tFocusList = {}
	if Navigator_Remove then
		Navigator_Remove("MY_FOCUS")
	end
	
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if not hList then
		return
	end
	hList:Clear()
end

-- 重新扫描附近焦点
function MY_Focus.RescanNearby()
	MY_Focus.ClearFocus()
	MY_Focus.ScanNearby()
end

-- 重绘列表
function MY_Focus.RedrawList(hList)
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
function MY_Focus.UpdateList()
	l_lockInDisplay = false
	local tNames = {}
	for i, p in ipairs(MY_Focus.GetDisplayList()) do
		MY_Focus.DrawFocus(p.dwType, p.dwID)
		tNames['HI_' .. p.dwType .. '_' .. p.dwID] = true
	end
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if hList then
		for i = hList:GetItemCount() - 1, 0, -1 do
			local szKey = hList:Lookup(i):GetName()
			if not tNames[szKey] then
				if MY_Focus.bEnableSceneNavi and Navigator_Remove then
					Navigator_Remove("MY_FOCUS." .. szKey:sub(4))
				end
				hList:RemoveItem(i)
			end
		end
		hList:FormatAllItemPos()
	end
end

-- 绘制指定的焦点Handle（没有则添加创建）
function MY_Focus.DrawFocus(dwType, dwID)
	local obj, info, bInfo = MY.Game.GetObject(dwType, dwID)
	local szName = MY.Game.GetObjectName(obj)
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	local player = GetClientPlayer()
	if not (obj and hList) then
		return
	end

	local hItem = MY_Focus.GetHandle(dwType, dwID)
	if not hItem then
		if MY_Focus.bEnableSceneNavi and Navigator_SetID then
			Navigator_SetID("MY_FOCUS." .. dwType .. "_" .. dwID, dwType, dwID, szName)
		end
		hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Info')
		hItem:Scale(MY_Focus.fScaleX, MY_Focus.fScaleY)
		hItem:SetName('HI_'..dwType..'_'..dwID)
	end
	
	---------- 左侧 ----------
	-- 小图标列表
	local hInfoList = hItem:Lookup("Handle_InfoList")
	-- 锁定
	hInfoList:Lookup('Handle_Lock'):Hide()
	if dwType == l_dwLockType and dwID == l_dwLockID then
		l_lockInDisplay = true
		hInfoList:Lookup('Handle_Lock'):Show()
	end
	-- 心法
	hInfoList:Lookup('Handle_Kungfu'):Hide()
	if dwType == TARGET.PLAYER then
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(info.dwMountKungfuID))
			hInfoList:Lookup('Handle_Kungfu'):Show()
			hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = obj.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(kungfu.dwSkillID))
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(g_tStrings.tForceTitle[obj.dwForceID])
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromUITex(GetForceImage(obj.dwForceID))
			end
		end
	end
	-- 阵营
	hInfoList:Lookup('Handle_Camp'):Hide()
	if dwType == TARGET.PLAYER
	and (obj.nCamp == CAMP.GOOD or obj.nCamp == CAMP.EVIL) then
		hInfoList:Lookup('Handle_Camp'):Show()
		hInfoList:Lookup('Handle_Camp/Image_Camp'):FromUITex(GetCampImage(obj.nCamp, obj.bCampFlag))
	end
	-- 标记
	hInfoList:Lookup('Handle_Mark'):Hide()
	local KTeam = GetClientTeam()
	if KTeam and MY.IsInParty() then
		local tMark = KTeam.GetTeamMark()
		if tMark then
			local nMarkID = tMark[dwID]
			if nMarkID then
				hInfoList:Lookup('Handle_Mark'):Show()
				hInfoList:Lookup('Handle_Mark/Image_Mark'):FromUITex(PARTY_MARK_ICON_PATH, PARTY_MARK_ICON_FRAME_LIST[nMarkID])
			end
		end
	end
	hInfoList:FormatAllItemPos()
	
	-- 目标距离
	local nDistance = math.floor(math.sqrt(math.pow(player.nX - obj.nX, 2) + math.pow(player.nY - obj.nY, 2) + math.pow((player.nZ - obj.nZ) / 8, 2)) * 10 / 64) / 10
	hItem:Lookup('Handle_Compass/Compass_Distance'):SetText(nDistance)
	hItem:Lookup('Handle_School/School_Distance'):SetText(nDistance)
	-- 自身面向
	if player then
		hItem:Lookup('Handle_Compass/Image_Player'):Show()
		hItem:Lookup('Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
	end
	-- 左侧主要部分
	if MY_Focus.bDisplayKungfuIcon and dwType == TARGET.PLAYER then
		hItem:Lookup('Handle_Compass'):Hide()
		hItem:Lookup('Handle_School'):Show()
		-- 心法图标
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = obj.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_School/Image_School'):FromUITex(GetForceImage(obj.dwForceID))
			end
		end
	else
		hItem:Lookup('Handle_School'):Hide()
		hItem:Lookup('Handle_Compass'):Show()
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
			h:SetRelPos((nRadius + nRadius * math.cos(nRotate) + 2) * MY_Focus.fScaleX, (nRadius - 3 - 13.5 * math.sin(nRotate)) * MY_Focus.fScaleY)
			h:GetParent():FormatAllItemPos()
		end
	end
	---------- 右侧 ----------
	-- 名字
	hItem:Lookup('Handle_LMN/Text_Name'):SetText(szName or obj.dwID)
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
			hItem:Lookup('Handle_LMN/Image_Health'):SetPercentage(nCurrentLife / nMaxLife)
			hItem:Lookup('Handle_LMN/Text_Health'):SetText(szLife)
		end
		if nMaxMana > 0 then
			hItem:Lookup('Handle_LMN/Image_Mana'):SetPercentage(nCurrentMana / nMaxMana)
			hItem:Lookup('Handle_LMN/Text_Mana'):SetText(nCurrentMana .. '/' .. nMaxMana)
		end
	end
	-- 读条
	if dwType ~= TARGET.DOODAD then
		local nType, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillOTActionState()
		if MY_Focus.bTraversal and dwType == TARGET.PLAYER
		and (
			nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			and nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
			and obj.GetOTActionState() == 1
		) then
			MY.Player.WithTarget(dwType, dwID, function()
				local nType, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillOTActionState()
				if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText(MY_Focus.GetSkillName(dwSkillID, dwSkillLevel))
				else
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
				end
			end)
		else
			if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
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
	if player then
		local dwTargetType, dwTargetID = player.GetTarget()
		if dwTargetType == dwType and dwTargetID == dwID then
			hItem:Lookup('Image_Select'):Show()
		end
	end
	
	hItem:FormatAllItemPos()
	hList:FormatAllItemPos()
end

-- 自适应调整界面大小
function MY_Focus.AdjustUI()
	local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
	if not hList then
		return
	end
	
	local tList = MY_Focus.GetDisplayList()
	hList:SetH(70 * #tList * MY_Focus.fScaleY)
	hList:GetRoot():SetH((70 * #tList + 32) * MY_Focus.fScaleY)
	if #tList == 0 and MY_Focus.bAutoHide and not l_bMinimize then
		hList:GetRoot():Hide()
	elseif (not MY_Focus.bAutoHide) or #tList ~= 0 then
		hList:GetRoot():Show()
	end
end

-- 获取内功心法字符串
local m_tKungfuName = {}
function MY_Focus.GetKungfuName(dwKungfuID)
	if not m_tKungfuName[dwKungfuID] then
		m_tKungfuName[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1)
	end
	return m_tKungfuName[dwKungfuID]
end

-- 获取技能名称字符串
local m_tSkillName = {}
function MY_Focus.GetSkillName(dwSkillID, dwSkillLevel)
	if not m_tSkillName[dwSkillID] then
		m_tSkillName[dwSkillID] = Table_GetSkillName(dwSkillID, dwSkillLevel)
	end
	return m_tSkillName[dwSkillID]
end

-- ########################################################################## --
--                                     #                 #         #          --
--                           # # # # # # # # # # #       #   #     #          --
--   # #     # # # # # # #       #     #     #         #     #     #          --
--     #     #       #           # # # # # # #         #     # # # # # # #    --
--     #     #       #                 #             # #   #       #          --
--     #     #       #         # # # # # # # # #       #           #          --
--     #     #       #                 #       #       #           #          --
--     #     #       #       # # # # # # # # # # #     #   # # # # # # # #    --
--     #     #       #                 #       #       #           #          --
--       # #     # # # # #     # # # # # # # # #       #           #          --
--                                     #               #           #          --
--                                   # #               #           #          --
-- ########################################################################## --
-- 周期重绘
function MY_Focus.OnFrameBreathe()
	if l_dwLockType and l_dwLockID and l_lockInDisplay then
		local dwType, dwID = MY.GetTarget()
		if dwType ~= l_dwLockType or dwID ~= l_dwLockID then
			MY.SetTarget(l_dwLockType, l_dwLockID)
		end
	end
	if MY_Focus.bSortByDistance then
		MY_Focus.SortFocus()
	end
	MY_Focus.UpdateList()
	MY_Focus.AdjustUI()
end

function MY_Focus.OnFrameCreate()
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("PARTY_SET_MARK")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_ENTER_SCENE")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("DOODAD_ENTER_SCENE")
	this:RegisterEvent("PLAYER_LEAVE_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")
	this:RegisterEvent("DOODAD_LEAVE_SCENE")
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	
	MY_Focus.SetScale(MY_Focus.fScaleX, MY_Focus.fScaleY)
	MY_Focus.OnEvent("UI_SCALED")
	MY_Focus.OnEvent("LOADING_END")
	MY_Focus.RescanNearby()
end

function MY_Focus.OnEvent(event)
	if event == "LOADING_END" or event == "CUSTOM_DATA_LOADED" then
		if not MY_Focus.tFocusList then
			MY_Focus.tFocusList = {}
		end
		for _, dwType in ipairs({TARGET.PLAYER, TARGET.NPC, TARGET.DOODAD}) do
			if not MY_Focus.tFocusList[dwType] then
				MY_Focus.tFocusList[dwType] = {}
			end
		end
		if not MY_Focus.tFocusTplList then
			MY_Focus.tFocusTplList = {}
		end
		for _, dwType in ipairs({TARGET.NPC, TARGET.DOODAD}) do
			if not MY_Focus.tFocusTplList[dwType] then
				MY_Focus.tFocusTplList[dwType] = {}
			end
		end
	elseif event == "PARTY_SET_MARK" then
		MY_Focus.UpdateList()
	elseif event == 'UI_SCALED' then
		XGUI(this):anchor(MY_Focus.anchor)
	elseif event == 'PLAYER_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.DOODAD, arg0)
	elseif event == 'PLAYER_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.DOODAD, arg0)
	end
end

function MY_Focus.OnFrameDragSetPosEnd()
	this:CorrectPos()
	MY_Focus.anchor = MY.UI(this):anchor('TOPRIGHT')
end

function MY_Focus.OnItemMouseEnter()
	local name = this:GetName()
	if name:find('HI_(%d+)_(%d+)') then
		this:Lookup("Image_Hover"):Show()
		if MY_Focus.bHealHelper then
			this.dwLastType, this.dwLastID = MY.GetTarget()
			MY_Focus.OnItemLButtonClick()
		end
	end
end

function MY_Focus.OnItemMouseLeave()
	local name = this:GetName()
	if name:find('HI_(%d+)_(%d+)') then
		if this:Lookup("Image_Hover") then
			this:Lookup("Image_Hover"):Hide()
			if MY_Focus.bHealHelper then
				MY.SetTarget(this.dwLastType, this.dwLastID)
			end
		end
	end
end

function MY_Focus.OnItemLButtonClick()
	local name = this:GetName()
	name:gsub('HI_(%d+)_(%d+)', function(dwType, dwID)
		if MY_Focus.bHealHelper then
			this.dwLastType, this.dwLastID = dwType, dwID
		end
		SetTarget(dwType, dwID)
	end)
end

function MY_Focus.OnItemRButtonClick()
	local name = this:GetName()
	name:gsub('^HI_(%d+)_(%d+)$', function(dwType, dwID)
		dwType, dwID = tonumber(dwType), tonumber(dwID)
		local t = MY.Game.GetTargetContextMenu(dwType, this:Lookup('Handle_LMN/Text_Name'):GetText(), dwID)
		table.insert(t, 1, {
			szOption = _L['delete focus'],
			fnAction = function()
				if l_dwLockType == dwType and l_dwLockID == dwID then
					l_dwLockType = nil
					l_dwLockID = nil
				end
				MY_Focus.DelStaticFocus(dwType, dwID)
			end,
		})
		local bLock = dwType == l_dwLockType and dwID == l_dwLockID
		table.insert(t, {
			szOption = bLock and _L['unlock focus'] or _L['lock focus'],
			fnAction = function()
				if bLock then
					l_dwLockID = nil
					l_dwLockType = nil
				else
					l_dwLockID = dwID
					l_dwLockType = dwType
					MY.SetTarget(dwType, dwID)
				end
				MY_Focus.UpdateList()
			end,
		})
		PopupMenu(t)
	end)
end

function MY_Focus.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		MY.OpenPanel()
		MY.SwitchTab('MY_Focus')
	end
end

function MY_Focus.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		l_bMinimize = true
		this:GetRoot():Lookup('', 'Handle_List'):Hide()
	end
end

function MY_Focus.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		l_bMinimize = false
		this:GetRoot():Lookup('', 'Handle_List'):Show()
	end
end

MY.RegisterTargetAddonMenu('MY_Focus', function()
	local dwType, dwID = GetClientPlayer().GetTarget()
	if dwType == TARGET.PLAYER then
		return {
			szOption = _L['add to focus list'],
			fnAction = function()
				if not MY_Focus.bEnable then
					MY_Focus.bEnable = true
					MY_Focus.Open()
				end
				MY_Focus.AddStaticFocus(dwType, dwID)
			end,
		}
	else
		return {{
			szOption = _L['add to focus list'],
			fnAction = function()
				if not MY_Focus.bEnable then
					MY_Focus.bEnable = true
					MY_Focus.Open()
				end
				MY_Focus.AddStaticFocus(dwType, dwID)
			end,
		}, {
			szOption = _L['add to static focus list'],
			fnAction = function()
				if not MY_Focus.bEnable then
					MY_Focus.bEnable = true
					MY_Focus.Open()
				end
				MY_Focus.AddStaticFocus(dwType, dwID, true)
			end,
		}}
	end
end)

MY.RegisterInit('MY_FOCUS', function()
	if MY_Focus.bEnable then
		MY_Focus.Open()
	else
		MY_Focus.Close()
	end
end)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w  = ui:width()
	local h  = math.max(ui:height(), 440)
	local xr, yr, wr = w - 260, 40, 260
	local xl, yl, wl = 5,  5, w - wr -15
	
	-- 左侧
	local x, y = xl, yl
	ui:append("WndCheckBox", {
		x = x, y = y, w = 250, text = _L['enable'],
		r = 255, g = 255, b = 0, checked = MY_Focus.bEnable,
		oncheck = function(bChecked)
			MY_Focus.bEnable = bChecked
			if MY_Focus.bEnable then
				MY_Focus.Open()
			else
				MY_Focus.Close()
			end
		end,
	})
	y = y + 25
	
	-- <hr />
	ui:append("Image", {x = x, y = y, w = w - x, h = 1, image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62})
	y = y + 5
	
	ui:append("WndCheckBox", {
		x = x, y = y, text = _L['auto focus'], checked = MY_Focus.bAutoFocus,
		oncheck = function(bChecked)
			MY_Focus.bAutoFocus = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	
	local list = ui:append("WndListBox", {x = x, y = y + 30, w = wl - x + xl, h = h - y - 40}, true)
	-- 初始化list控件
	for _, v in ipairs(MY_Focus.tAutoFocus) do
		list:listbox('insert', v, v)
	end
	list:listbox('onmenu', function(hItem, szText, szID)
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
	ui:append("WndButton", {
		x = wl - 160, y = y, w = 80,
		text = _L["add"],
		onclick = function()
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
		end,
	})
	-- del
	ui:append("WndButton", {
		x = wl - 80, y = y, w = 80,
		text = _L["delete"],
		onclick = function()
			for _, v in ipairs(list:listbox('select', 'selected')) do
				list:listbox('delete', v.text, v.id)
				for i = #MY_Focus.tAutoFocus, 1, -1 do
					if MY_Focus.tAutoFocus[i] == v.text then
						table.remove(MY_Focus.tAutoFocus, i)
						MY_Focus.RescanNearby()
					end
				end
			end
		end,
	})
	
	-- 右侧
	local x, y = xr, yr - 20
	local deltaX = 23
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['hide when empty'],
		checked = MY_Focus.bAutoHide,
		oncheck = function(bChecked)
			MY_Focus.bAutoHide = bChecked
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['auto focus very important npc'],
		tip = _L['boss list is always been collecting and updating'],
		tippostype = MY.Const.UI.Tip.POS_TOP,
		checked = MY_Focus.bFocusBoss,
		oncheck = function(bChecked)
			MY_Focus.bFocusBoss = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['auto focus friend'],
		checked = MY_Focus.bFocusFriend,
		oncheck = function(bChecked)
			MY_Focus.bFocusFriend = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("Image", {
		x = x + 5, y = y - 3, w = 10, h = 8,
		image = "ui/Image/UICommon/ScienceTree.UITex",
		imageframe = 10,
	})
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['auto focus tong'],
		checked = MY_Focus.bFocusTong,
		oncheck = function(bChecked)
			MY_Focus.bFocusTong = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("Image", {
		x = x + 5, y = y, w = 10, h = 10,
		image = "ui/Image/UICommon/ScienceTree.UITex",
		imageframe = 10,
	})
	ui:append("Image", {
		x = x + 10, y = y + 5, w = 10, h = 10,
		image = "ui/Image/UICommon/ScienceTree.UITex",
		imageframe = 8,
	})
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = wr, text = _L['auto focus only in public map'],
		checked = MY_Focus.bOnlyPublicMap,
	  	oncheck = function(bChecked)
			MY_Focus.bOnlyPublicMap = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['auto focus enemy'],
		checked = MY_Focus.bFocusEnemy,
		oncheck = function(bChecked)
			MY_Focus.bFocusEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['jjc auto focus party'],
		checked = MY_Focus.bFocusJJCParty,
		oncheck = function(bChecked)
			MY_Focus.bFocusJJCParty = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['jjc auto focus enemy'],
		checked = MY_Focus.bFocusJJCEnemy,
		oncheck = function(bChecked)
			MY_Focus.bFocusJJCEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['show focus\'s target'],
		checked = MY_Focus.bShowTarget,
		oncheck = function(bChecked)
			MY_Focus.bShowTarget = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y,w = wr, text = _L['traversal object'],
		tip = _L['may cause some problem in dungeon map'],
		tippostype = MY.Const.UI.Tip.POS_BOTTOM,
		checked = MY_Focus.bTraversal,
		oncheck = function(bChecked)
			MY_Focus.bTraversal = bChecked
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['hide dead object'],
		checked = MY_Focus.bHideDeath,
		oncheck = function(bChecked)
			MY_Focus.bHideDeath = bChecked
			MY_Focus.RescanNearby()
		end,
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['display kungfu icon instead of location'],
		checked = MY_Focus.bDisplayKungfuIcon,
		oncheck = function(bChecked)
			MY_Focus.bDisplayKungfuIcon = bChecked
		end,
	})
	y = y + deltaX
	
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_SortByDistance',
		x = x, y = y, w = wr,
		text = _L['sort by distance'],
		checked = MY_Focus.bSortByDistance,
		oncheck = function(bChecked)
			MY_Focus.bSortByDistance = bChecked
			MY_Focus.RedrawList()
		end
	})
	y = y + deltaX
	
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_EnableSceneNavi',
		x = x, y = y, w = wr,
		text = _L['enable scene navi'],
		checked = MY_Focus.bEnableSceneNavi,
		oncheck = function(bChecked)
			MY_Focus.bEnableSceneNavi = bChecked
			MY_Focus.RescanNearby()
		end
	})
	y = y + deltaX
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr, text = _L['heal healper'],
		tip = _L['select target when mouse enter'],
		tippostype = MY.Const.UI.Tip.POS_BOTTOM,
		checked = MY_Focus.bHealHelper,
		oncheck = function(bChecked)
			MY_Focus.bHealHelper = bChecked
		end,
	})
	y = y + deltaX
	
	ui:append("WndComboBox", {
		x = x, y = y, w = 150,
		text = _L['max display length'],
		menu = function()
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
		end,
	})
	y = y + deltaX
	
	ui:append("WndSliderBox", {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L("current scale-x is %d%%.", val) end,
		range = {10, 300},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_Focus.fScaleX * 100,
		onchange = function(raw, val)
			MY_Focus.SetScale(val / 100, MY_Focus.fScaleY)
		end,
	})
	y = y + deltaX
	
	ui:append("WndSliderBox", {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L("current scale-y is %d%%.", val) end,
		range = {10, 300},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_Focus.fScaleY * 100,
		onchange = function(raw, val)
			MY_Focus.SetScale(MY_Focus.fScaleX, val / 100)
		end,
	})
	y = y + deltaX
end
MY.RegisterPanel("MY_Focus", _L["focus list"], _L['Target'], "ui/Image/button/SystemButton_1.UITex|9", {255,255,0,200}, PS)
