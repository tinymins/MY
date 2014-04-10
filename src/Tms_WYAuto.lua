Tms_WYAuto = Tms_WYAuto or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _WYAuto = {
	dwVersion = 0x0030000,
	szBuildDate = "20140209",
}
-----------------------------------------------
-- ……
-----------------------------------------------
_WYAutoDataDefault = {
    bAuto = true,
    bAutoJW = true,
    bAutoArea = false,
    bTabPvp = false,
    bAutoQKJY = false,  -- 乾坤剑意自动选中开关
    bAutoWDLD = false,  -- 屋顶漏洞自动选中开关
    bUnfocusJX = true,  -- 禁止选中剑心开关
    bEchoMsg = true,    -- 消息发布总开关
    cEchoChanel = PLAYER_TALK_CHANNEL.LOCAL_SYS,    -- 消息发布频道
    bTargetLock = true, -- 目标锁定开关
    bNoSelectSelf = true,   -- 是否允许锁定自己
    nTargetLockMode = 0, -- 目标锁定模式： 0 自动转火 1 锁定附近敌对NPC 2 锁定附近敌对NPC 3 自定义锁定
    nTargetLockNearNpcDistance = 20,    -- 锁定附近敌对NPC最大距离
    nTargetLockNearNpcSortMode = 0,     -- 距离最近/等级最低/未进战的/已进战的/在揍我的/揍别人的/血量最少/血量百分比最少
    nTargetLockNearPlayerDistance = 20,    -- 锁定附近敌对NPC最大距离
    nTargetLockNearPlayerSortMode = 0,     -- 距离最近/等级最低/未进战的/已进战的/在揍我的/揍别人的/血量最少/血量百分比最少
    szBannedEnemyNames = {},                 -- 屏蔽选中的名字们
    szPriorEnemyNames = {},                  -- 优先选中的名字们
    szBannedPlayerNames = {},                 -- 屏蔽选中的玩家名字们
    szPriorPlayerNames = {},                  -- 优先选中的玩家名字们
    szAutoFocusNames = {                -- 自动集火选中的目标名单
        ["击鼓手"] = true,
        ["傀儡丝"] = true,
        ["心魔"] = true,
        ["乾坤剑意"] = true,
        ["袄教使者"] = true,
        ["狼牙军官"] = true,
        ["屋顶漏洞"] = true,
        ["龙胆蛇"] = true,
        ["血玉"] = true,
        ["阴性血玉"] = true,
        ["诡异的物体"] = true,
        ["冥花连舞"] = true,
        ["捆缚祭链"] = false,
        ["维提吠达特天罚剑"] = true,
    }
}
_WYAutoData = _WYAutoData or _WYAutoDataDefault
for k, _ in pairs(_WYAutoData) do
	RegisterCustomData("_WYAutoData." .. k)
end
_WYAutoCache = {
    loaded = false,
    tMenuAutoFocusTarget = { },
    tMenuBannedEnemyNames = { },
    tMenuPriorEnemyNames = { },
    tMenuBannedPlayerNames = { },
    tMenuPriorPlayerNames = { },
}
----------------------------------------------------
-- 数据初始化
Tms_WYAuto.Loaded = function()
    if(_WYAutoCache.loaded) then return end
    _WYAutoCache.loaded = true
    
    local tMenu = {
        function()
            return {Tms_WYAuto.GetMenuList()}
        end,
    }
    Player_AppendAddonMenu(tMenu)
    Target_AppendAddonMenu({ function(dwID)
        return {
            Tms_WYAuto.GetTargetMenu(dwID),
        }
    end })
    Tms_WYAuto.Reload()
    
    -- Tms_WYAuto.println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。")
    OutputMessage("MSG_SYS", "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。\n")
end
Tms_WYAuto.Reload = function()
    -- 自动转火设定
    _WYAutoCache.tMenuAutoFocusTarget = {
        szOption = "自动转火 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
        bMCheck = true,
        bCheck = true,
        bChecked = _WYAutoData.nTargetLockMode == 0,
        fnAction = function()
            _WYAutoData.nTargetLockMode = 0
            Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·模式切换·自动转火")
            Tms_WYAuto.Reload()
        end,
        fnAutoClose = function() return true end,
        {  -- 添加新的集火目标
            szOption = "添加 ",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("添加自动转火目标", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    if nVal~="" then _WYAutoData.szAutoFocusNames[nVal]=true end
                    Tms_WYAuto.Reload()
                end)
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n添加新的自动转火目标。")
            end,
            fnAutoClose = function() return true end
        },
        {bDevide = true},
    }
    for szName, bFocus in pairs(_WYAutoData.szAutoFocusNames) do
        table.insert(_WYAutoCache.tMenuAutoFocusTarget, {  -- 自动选中集火目标
            szOption = szName,
            bCheck = true,
            bChecked = bFocus,
            fnAction = function()
                _WYAutoData.szAutoFocusNames[szName] = not _WYAutoData.szAutoFocusNames[szName]
                if _WYAutoData.szAutoFocusNames[szName] == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·自动选中["..szName.."]已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·自动选中["..szName.."]已关闭")
                end
                Tms_WYAuto.Reload()
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动选中["..szName.."]，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end,
            { szOption="删除", fnAction = function() _WYAutoData.szAutoFocusNames[szName]=nil Tms_WYAuto.Reload() end, fnAutoClose=function() return true end }
        })
    end
    -- 目标锁定屏蔽名单
    _WYAutoCache.tMenuBannedEnemyNames = {
        szOption = "屏蔽名单 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
        bMCheck = false,
        bCheck = false,
        bChecked = false,
        fnAction = function() end,
        fnAutoClose = function() return true end,
        {  -- 添加新的屏蔽名单
            szOption = "添加 ",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("添加屏蔽名称", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    if nVal~="" then _WYAutoData.szBannedEnemyNames[nVal]=true end
                    Tms_WYAuto.Reload()
                end)
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n添加新的屏蔽名称。")
            end,
            fnAutoClose = function() return true end
        },
        {bDevide = true},
    }
    for szName, bBanned in pairs(_WYAutoData.szBannedEnemyNames) do
        table.insert(_WYAutoCache.tMenuBannedEnemyNames, {  -- 自动选中集火目标
            szOption = szName,
            bCheck = true,
            bChecked = bBanned,
            fnAction = function()
                _WYAutoData.szBannedEnemyNames[szName] = not _WYAutoData.szBannedEnemyNames[szName]
                if _WYAutoData.szBannedEnemyNames[szName] == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·屏蔽锁定["..szName.."]已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·屏蔽锁定["..szName.."]已关闭")
                end
                Tms_WYAuto.Reload()
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n屏蔽锁定["..szName.."]，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end,
            { szOption="删除", fnAction = function() _WYAutoData.szBannedEnemyNames[szName]=nil Tms_WYAuto.Reload() end, fnAutoClose=function() return true end }
        })
    end
    -- 目标锁定优先名单
    _WYAutoCache.tMenuPriorEnemyNames = {
        szOption = "优先名单 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
        bMCheck = false,
        bCheck = false,
        bChecked = false,
        fnAction = function() end,
        fnAutoClose = function() return true end,
        {  -- 添加新的优先名单
            szOption = "添加 ",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("添加优先名称", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    if nVal~="" then _WYAutoData.szPriorEnemyNames[nVal]=true end
                    Tms_WYAuto.Reload()
                end)
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n添加新的优先名称。")
            end,
            fnAutoClose = function() return true end
        },
        {bDevide = true},
    }
    for szName, bPrior in pairs(_WYAutoData.szPriorEnemyNames) do
        table.insert(_WYAutoCache.tMenuPriorEnemyNames, {  -- 自动选中集火目标
            szOption = szName,
            bCheck = true,
            bChecked = bPrior,
            fnAction = function()
                _WYAutoData.szPriorEnemyNames[szName] = not _WYAutoData.szPriorEnemyNames[szName]
                if _WYAutoData.szPriorEnemyNames[szName] == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·优先锁定["..szName.."]已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·优先锁定["..szName.."]已关闭")
                end
                Tms_WYAuto.Reload()
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n优先锁定["..szName.."]，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end,
            { szOption="删除", fnAction = function() _WYAutoData.szPriorEnemyNames[szName]=nil Tms_WYAuto.Reload() end, fnAutoClose=function() return true end }
        })
    end
    -- 玩家锁定屏蔽名单
    _WYAutoCache.tMenuBannedPlayerNames = {
        szOption = "屏蔽名单 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
        bMCheck = false,
        bCheck = false,
        bChecked = false,
        fnAction = function() end,
        fnAutoClose = function() return true end,
        {  -- 添加新的屏蔽名单
            szOption = "添加 ",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("添加屏蔽名称", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    if nVal~="" then _WYAutoData.szBannedPlayerNames[nVal]=true end
                    Tms_WYAuto.Reload()
                end)
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n添加新的屏蔽名称。")
            end,
            fnAutoClose = function() return true end
        },
        {bDevide = true},
    }
    for szName, bBanned in pairs(_WYAutoData.szBannedPlayerNames) do
        table.insert(_WYAutoCache.tMenuBannedPlayerNames, {  -- 自动选中集火目标
            szOption = szName,
            bCheck = true,
            bChecked = bBanned,
            fnAction = function()
                _WYAutoData.szBannedPlayerNames[szName] = not _WYAutoData.szBannedPlayerNames[szName]
                Tms_WYAuto.Reload()
                if _WYAutoData.szBannedPlayerNames[szName] == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·屏蔽锁定["..szName.."]已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·屏蔽锁定["..szName.."]已关闭")
                end
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n屏蔽锁定["..szName.."]，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end,
            { szOption="删除", fnAction = function() _WYAutoData.szBannedPlayerNames[szName]=nil Tms_WYAuto.Reload() end, fnAutoClose=function() return true end }
        })
    end
    -- 玩家锁定优先名单
    _WYAutoCache.tMenuPriorPlayerNames = {
        szOption = "优先名单 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
        bMCheck = false,
        bCheck = false,
        bChecked = false,
        fnAction = function() end,
        fnAutoClose = function() return true end,
        {  -- 添加新的优先名单
            szOption = "添加 ",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("添加优先名称", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    if nVal~="" then _WYAutoData.szPriorPlayerNames[nVal]=true end
                    Tms_WYAuto.Reload()
                end)
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n添加新的优先名称。")
            end,
            fnAutoClose = function() return true end
        },
        {bDevide = true},
    }
    for szName, bPrior in pairs(_WYAutoData.szPriorPlayerNames) do
        table.insert(_WYAutoCache.tMenuPriorPlayerNames, {  -- 自动选中集火目标
            szOption = szName,
            bCheck = true,
            bChecked = bPrior,
            fnAction = function()
                _WYAutoData.szPriorPlayerNames[szName] = not _WYAutoData.szPriorPlayerNames[szName]
                if _WYAutoData.szPriorPlayerNames[szName] == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·优先锁定["..szName.."]已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·优先锁定["..szName.."]已关闭")
                end
                Tms_WYAuto.Reload()
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n优先锁定["..szName.."]，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end,
            { szOption="删除", fnAction = function() _WYAutoData.szPriorPlayerNames[szName]=nil Tms_WYAuto.Reload() end, fnAutoClose=function() return true end }
        })
    end
    TMS.BreatheCall("JW")
    TMS.BreatheCall("AutoFocusTarget")
    TMS.BreatheCall("LockNearTarget")
    if not _WYAutoData.bAuto then return end
    if _WYAutoData.bAutoJW == true then TMS.BreatheCall("JW", Tms_WYAuto.AutoJW) end
    if _WYAutoData.bTargetLock then 
        if _WYAutoData.nTargetLockMode == 0 then 
            TMS.BreatheCall("AutoFocusTarget", Tms_WYAuto.AutoFocusTarget)
        elseif _WYAutoData.nTargetLockMode == 1 then 
            TMS.BreatheCall("LockNearTarget", Tms_WYAuto.AutoLockNearTarget)
        elseif _WYAutoData.nTargetLockMode == 2 then 
            TMS.BreatheCall("LockNearTarget", Tms_WYAuto.AutoLockNearTarget)
        elseif _WYAutoData.nTargetLockMode == 3 then 
            return
        end
    end
end
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) Tms_WYAuto.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
Tms_WYAuto.GetVersion = function()
	local v = _WYAuto.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- (void) Tms_WYAuto.MenuTip(string str)	-- MenuTip
Tms_WYAuto.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})
end

--(void) Tms_WYAuto.print(optional nChannel, szText)     -- 输出消息
Tms_WYAuto.print = function(nChannel,szText)
	local me = GetClientPlayer()
	if type(nChannel) == "string" then
		szText = nChannel
		nChannel = _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	end
	local tSay = {{ type = "text", text = szText }}
	if nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
    end
	if nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText)
	elseif _WYAutoData.bEchoMsg then
		me.Talk(nChannel,"",tSay)
	end
end
--(void) Tms_WYAuto.println(optional nChannel,szText)     -- 换行输出消息
Tms_WYAuto.println = function(nChannel,szText)
	if type(nChannel) == "string" then
        Tms_WYAuto.print(nChannel .. "\n")
    else
        Tms_WYAuto.print(nChannel, szText .. "\n")
	end
end

----------------------------------------------------
local _SelectPoint = UserSelect.SelectPoint ---HOOK区域选中函数 改为默认直接选中----
function UserSelect.SelectPoint(fnAction, fnCancel, fnCondition, box) --获取释放点 函数
	_SelectPoint(fnAction, fnCancel, fnCondition, box) --显示区域选择
	if _WYAutoData.bAuto and _WYAutoData.bAutoArea then -- 开关打开
		local t = GetTargetHandle(GetClientPlayer().GetTarget()) or GetClientPlayer()
		UserSelect.DoSelectPoint(t.nX, t.nY, t.nZ)
	end
end
----------------------------------------------------
--注册 Tms_WYAuto.tBreatheAction["A"]=B	A索引 B函数
--注销 Tms_WYAuto.tBreatheAction["A"]=nil
----------------------------------------------------
--无目标技能释放--
function InvalidCast(dwSkillID, dwSkillLevel)
	local player = GetClientPlayer()
	local oTTP, oTID = player.GetTarget()
    dwSkillLevel = dwSkillLevel or player.GetSkillLevel(dwSkillID)
	local bCool, nLeft, nTotal = player.GetSkillCDProgress(dwSkillID, dwSkillLevel)
	if not bCool or nLeft == 0 and nTotal == 0 then
		SetTarget(TARGET.NOT_TARGET, 0)
		OnAddOnUseSkill(dwSkillID, dwSkillLevel)
        -- Tms_WYAuto.println(dwSkillID,"  ",dwSkillLevel)
        -- OnAddOnUseSkill(dwSkillID, 1)
		if player.dwID == oTID then
			SetTarget(TARGET.PLAYER, player.dwID)
		else
			SetTarget(oTTP, oTID)
		end
	end
end
---------------------------------------------------
-- (bool)返回玩家是否拥有指定id的buff
function buff(id)
    for _,v in pairs(GetClientPlayer().GetBuffList() or {}) do
		if v.dwID == id then
      		return true
    	end
    end
    return false
end
---------------------------------------------------
-- (bool)返回玩家是否处于可挂扶摇状态
function stand()
 	local N = GetClientPlayer()
	if N then
		local state = N.nMoveState
		if state == MOVE_STATE.ON_STAND or state == MOVE_STATE.ON_FLOAT or state == MOVE_STATE.ON_FREEZE or state == MOVE_STATE.ON_ENTRAP then
			return true
		end
	end
	return false
end

---------------------------------------------------
-- (void)禁止选中剑心
Tms_WYAuto.AutoUnfocusJX = function()
    if _WYAutoData.bAuto and _WYAutoData.bUnfocusJX then -- 禁止选中剑心开关打开
        local player = GetClientPlayer()
        local tar = GetTargetHandle(player.GetTarget())
        if(tar and tar.szName == "剑心") then
            player.StopCurrentAction()
            SetTarget(TARGET.PLAYER,player.dwID)
        end
    end
end
RegisterEvent("DO_SKILL_PREPARE_PROGRESS",Tms_WYAuto.AutoUnfocusJX) -- 技能开始读条 -- arg0=技能准备帧数 -- arg1=技能ID -- arg2=技能等级
RegisterEvent("DO_SKILL_CAST",Tms_WYAuto.AutoUnfocusJX) -- 技能释放 -- arg0=人物ID -- arg1=技能ID -- arg2=技能等级
RegisterEvent("PLAYER_STATE_UPDATE",Tms_WYAuto.AutoUnfocusJX)
RegisterEvent("SYNC_ROLE_DATA_END",Tms_WYAuto.AutoUnfocusJX)

---------------------------------------------------
-- 目标锁定 事件绑定
_WYAutoCache.LastTarget = {
    eTargetType = TARGET.NOT_TARGET,
    dwTargetID = 1,
    bRefocused = true,
}

---------------------------------------------------
-- (void)自动转火
Tms_WYAuto.AutoFocusTarget = function()
    if not _WYAutoData.bAuto then return end
    local me = GetClientPlayer() if not me then return end
    local tar = GetTargetHandle( me.GetTarget() )
    local tNearNpcList = TMS.GetNearNpcList()
    if tar and tar.nCurrentLife > 0 and _WYAutoData.szAutoFocusNames[tar.szName] then return end -- 如果当前目标在转火名单里并且存活 则返回
    for tid,ttar in pairs(tNearNpcList) do
        if ttar and ttar.nCurrentLife > 0 and _WYAutoData.szAutoFocusNames[ttar.szName] then
            if ( tar and tar.szName ) then _WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID = me.GetTarget() _WYAutoCache.LastTarget.bRefocused=false end
            SetTarget(TARGET.NPC,tid)
            return
        end
    end
    if(not tar)and(not _WYAutoCache.LastTarget.bRefocused) then SetTarget(_WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID) _WYAutoCache.LastTarget.bRefocused=true end
end
---------------------------------------------------
-- (void)自动选中指定范围内敌对NPC
Tms_WYAuto.AutoLockNearTarget = function()
    local player = GetClientPlayer() if not player then return end
    if _WYAutoData.bTargetLock and ( _WYAutoData.nTargetLockMode == 1 or _WYAutoData.nTargetLockMode == 2 ) then 
        local dwNpcID = 0            -- 记录 距离最近/等级最低/未进战的/已进战的/在揍我的/血量最少/血量百分比最少 的NPC的ID
        local nLowestNpcPropertiesValue = 9999  -- 当前参考量的最小值
        local nMaxBanPriorOffset = -1           -- 当前优先顺序的最大值
        local dwNearestNpcID = 0                -- 距离最近NPC ID
        local nNearestDistance = 9999           -- 距离最近NPC距离
        local nThisDistance = 9999              -- 当前NPC距离
        local nearTargetList = (_WYAutoData.nTargetLockMode==1 and TMS.GetNearNpcList()) or TMS.GetNearPlayerList()
        if _WYAutoData.bNoSelectSelf then nearTargetList[player.dwID]=nil end
        local nTargetLockNearNpcDistance = (_WYAutoData.nTargetLockMode==1 and _WYAutoData.nTargetLockNearNpcDistance) or _WYAutoData.nTargetLockNearPlayerDistance
        for npcid,npc in pairs(nearTargetList) do
            if IsEnemy(player.dwID, npcid) or _WYAutoData.nTargetLockMode==2 then
                local switch = {
                    [0] = function(player,npc)    -- 距离最近
                        return GetCharacterDistance(player.dwID, npc.dwID)
                    end,
                    [1] = function(player,npc)    -- 等级最低
                        return npc.nLevel
                    end,
                    [2] = function(player,npc)    -- 未进战的
                        if npc.bFightState then return -1 else return -2 end
                    end,
                    [3] = function(player,npc)    -- 已进战的
                        if npc.bFightState then return -2 else return -1 end
                    end,
                    [4] = function(player,npc)    -- 在揍我的
                        if npc.bFightState and GetTargetHandle(npc.GetTarget()) and GetTargetHandle(npc.GetTarget()).dwID == player.dwID then return -2 else return -1 end
                    end,
                    [5] = function(player,npc)    -- 揍别人的
                        if npc.bFightState and GetTargetHandle(npc.GetTarget()) and GetTargetHandle(npc.GetTarget()).dwID ~= player.dwID then return -2 else return -1 end
                    end,
                    [6] = function(player,npc)    -- 血量最少
                        return npc.nCurrentLife
                    end,
                    [7] = function(player,npc)    -- 血量百分比最少
                        return npc.nCurrentLife*100/npc.nMaxLife
                    end,
                }
                local fnGetBanPriorOffset = (_WYAutoData.nTargetLockMode==1 and function(szName)    -- 获取选中顺序数值加成
                    if _WYAutoData.szBannedEnemyNames[szName] then   -- 屏蔽的
                        return  -1
                    elseif _WYAutoData.szPriorEnemyNames[szName] then-- 优先的
                        return 1
                    else                                        -- 默认的
                        return 0
                    end
                end) or function(szName)    -- 获取选中顺序数值加成
                    if _WYAutoData.szBannedPlayerNames[szName] then   -- 屏蔽的
                        return  -1
                    elseif _WYAutoData.szPriorPlayerNames[szName] then-- 优先的
                        return 1
                    else                                        -- 默认的
                        return 0
                    end
                end
                local f = (_WYAutoData.nTargetLockMode==1 and switch[_WYAutoData.nTargetLockNearNpcSortMode]) or switch[_WYAutoData.nTargetLockNearPlayerSortMode]
                if(f) then
                    -- 求目标优先/屏蔽列表权重
                    local nBanPriorOffset = fnGetBanPriorOffset(npc.szName)
                    -- 求目标计算公式所得目标排序权重
                    local nNpcPropertiesValue = f(player,npc)
                    -- 求目标距离
                    local nDistance = GetCharacterDistance(player.dwID, npc.dwID)
                    if ( npc and nDistance/64 < nTargetLockNearNpcDistance  -- 与目标距离不超过最大设定值
                         and ( npc.nCurrentLife > 0 and nBanPriorOffset > -1    -- 目标存活并且没有被设置屏蔽
                            and ( nBanPriorOffset > nMaxBanPriorOffset   -- 优先级更高
                                  or ( nNpcPropertiesValue < nLowestNpcPropertiesValue and nBanPriorOffset == nMaxBanPriorOffset ) -- 优先级相同参考量小
                                  or ( nNpcPropertiesValue == nLowestNpcPropertiesValue and nBanPriorOffset == nMaxBanPriorOffset and nDistance < nThisDistance )       -- 优先级相同参考量相同距离最近
                                ) 
                             ) 
                    ) then
                        nMaxBanPriorOffset = nBanPriorOffset
                        nLowestNpcPropertiesValue = nNpcPropertiesValue
                        nThisDistance = nDistance
                        dwNpcID = npcid
                    end
                    if nBanPriorOffset > -1 and ( dwNearestNpcID == 0 or ( nDistance < nNearestDistance and nDistance/64 < nTargetLockNearNpcDistance ) ) then
                        nNearestDistance = nDistance
                        dwNearestNpcID = npcid
                    end
                -- else                -- for case default
                    -- Tms_WYAuto.print "Case default."
                end
            end
        end
        -- 选中符合要求的最佳目标 没有则选中最近的目标
        local nTargetType = (_WYAutoData.nTargetLockMode==1 and TARGET.NPC) or TARGET.PLAYER
        if dwNpcID ~= 0 and nLowestNpcPropertiesValue ~= -1 then SetTarget(nTargetType,dwNpcID) elseif dwNearestNpcID~=0 then SetTarget(nTargetType,dwNearestNpcID) end
    end
end

---------------------------------------------------
-- (void)七秀自动剑舞
Tms_WYAuto.AutoJW = function()
    -- 获取当前玩家装备的内功ID
	-- local Kungfu = UI_GetPlayerMountKungfuID() --GetClientPlayer().GetKungfuMount().dwSkillID
	-- if Kungfu and Kungfu ~= 10080 and Kungfu ~= 10081 then
		-- return
	-- end
	local me = GetClientPlayer()
	if not me or not me.GetKungfuMount() or me.GetOTActionState() ~= 0 then
		return
	end
	-- 7x
	if me.GetKungfuMount().dwMountType == 4 then
		-- auto dance
        if stand() and not buff(409) then
            InvalidCast(537)
        end
    end
end
----------------------------------------------------

---------------------------------------------------
-- 创建菜单
Tms_WYAuto.GetMenuList = function()
	local szVersion,v  = Tms_WYAuto.GetVersion()
	local menu = {  -- 主菜单
			szOption = "挽月堂手残点这里",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",{
				szOption = "当前版本 "..szVersion.."  ".._WYAuto.szBuildDate,bDisable = true,
			}
		}
	local menu_a_0 = {  -- 手残模式总开关
			szOption = "【手残模式总开关】 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAuto,
			fnAction = function()
                _WYAutoData.bAuto = not _WYAutoData.bAuto
                if _WYAutoData.bAuto == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]手残模式已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]手残模式已关闭")
                end
                Tms_WYAuto.Reload()
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_a_1 = {  -- 发布频道
			szOption = "【发布频道】 ",
            --SYS
            {szOption = "系统频道", bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.LOCAL_SYS, rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.LOCAL_SYS end, fnAutoClose = function() return true end},
            --近聊频道
            {szOption = g_tStrings.tChannelName.MSG_NORMAL, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.NEARBY, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.NEARBY end, fnAutoClose = function() return true end},
            --团队频道
            {szOption = g_tStrings.tChannelName.MSG_TEAM, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.RAID, rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.RAID end, fnAutoClose = function() return true end},
            --帮会频道
            {szOption = g_tStrings.tChannelName.MSG_GUILD, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.TONG, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.TONG end, fnAutoClose = function() return true end},
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bEchoMsg,
			fnAction = function()
                _WYAutoData.bEchoMsg = not _WYAutoData.bEchoMsg
                if _WYAutoData.bEchoMsg == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]设置发布已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]设置发布已关闭")
                end
			end,
			-- fnMouseEnter = function()
				-- Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
			-- end,
			fnAutoClose = function() return true end,
		}
	local menu_b_1 = {  -- 目标锁定/增强
        szOption = "目标锁定/增强 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT", 
        bCheck = true,
        bChecked = _WYAutoData.bTargetLock,
        fnAction = function()
            _WYAutoData.bTargetLock = not _WYAutoData.bTargetLock
            if _WYAutoData.bTargetLock == true then
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强已开启")
            else
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强已关闭")
            end
        end,
        fnAutoClose = function() return true end,
        -- 自动转火
        _WYAutoCache.tMenuAutoFocusTarget,
        {  -- 锁定附近敌对NPC
            szOption = "锁定附近敌对NPC ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 1,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 1
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·模式切换·锁定附近敌对NPC")
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 设置最大距离
                szOption = "设置最大锁定距离 ",
                bCheck = false,
                bChecked = false,
                fnAction = function()
                    -- 弹出界面
                    GetUserInputNumber(_WYAutoData.nTargetLockNearNpcDistance, 100, nil, function(num) _WYAutoData.nTargetLockNearNpcDistance = num end, function() end, function() end)
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n设置最大距离。")
                end,
                fnAutoClose = function() return true end
            },
            { bDevide = true }, 
            {  -- 优先选中
                szOption = "优先选中： ",
                fnAutoClose = function() return true end,
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                -- 距离最近
                {szOption = "距离最近", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 0, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 0 end, fnAutoClose = function() return true end},
                -- 等级最低
                {szOption = "等级最低", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 1, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 1 end, fnAutoClose = function() return true end},
                -- 未进战的
                {szOption = "未进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 2, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 2 end, fnAutoClose = function() return true end},
                -- 已进战的
                {szOption = "已进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 3, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 3 end, fnAutoClose = function() return true end},
                -- 在揍我的
                {szOption = "在揍我的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 4, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 4 end, fnAutoClose = function() return true end},
                -- 揍别人的
                {szOption = "揍别人的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 5, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 5 end, fnAutoClose = function() return true end},
                -- 血量最少
                {szOption = "血量最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 6, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 6 end, fnAutoClose = function() return true end},
                -- 血量百分比最少
                {szOption = "血量百分比最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 7, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 7 end, fnAutoClose = function() return true end},
            },
            _WYAutoCache.tMenuBannedEnemyNames,
            _WYAutoCache.tMenuPriorEnemyNames,
        }, 
        {  -- 锁定附近玩家
            szOption = "锁定附近玩家 ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 2,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 2
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·模式切换·锁定附近玩家")
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 设置最大距离
                szOption = "设置最大锁定距离 ",
                bCheck = false,
                bChecked = false,
                fnAction = function()
                    -- 弹出界面
                    GetUserInputNumber(_WYAutoData.nTargetLockNearPlayerDistance, 100, nil, function(num) _WYAutoData.nTargetLockNearPlayerDistance = num end, function() end, function() end)
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n设置最大距离。")
                end,
                fnAutoClose = function() return true end
            },
            {  -- 设置最大距离
                szOption = "不允许锁定自己为目标 ",
                bCheck = true,
                bChecked = _WYAutoData.bNoSelectSelf ,
                fnAction = function()
                    _WYAutoData.bNoSelectSelf = not _WYAutoData.bNoSelectSelf
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n不允许在自己符合条件时锁定自己为目标。")
                end,
                fnAutoClose = function() return true end
            },
            { bDevide = true }, 
            {  -- 优先选中
                szOption = "优先选中： ",
                fnAutoClose = function() return true end,
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                -- 距离最近
                {szOption = "距离最近", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 0, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 0 end, fnAutoClose = function() return true end},
                -- 等级最低
                {szOption = "等级最低", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 1, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 1 end, fnAutoClose = function() return true end},
                -- 未进战的
                {szOption = "未进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 2, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 2 end, fnAutoClose = function() return true end},
                -- 已进战的
                {szOption = "已进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 3, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 3 end, fnAutoClose = function() return true end},
                -- 在揍我的
                {szOption = "在揍我的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 4, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 4 end, fnAutoClose = function() return true end},
                -- 揍别人的
                {szOption = "揍别人的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 5, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 5 end, fnAutoClose = function() return true end},
                -- 血量最少
                {szOption = "血量最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 6, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 6 end, fnAutoClose = function() return true end},
                -- 血量百分比最少
                {szOption = "血量百分比最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearPlayerSortMode == 7, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearPlayerSortMode = 7 end, fnAutoClose = function() return true end},
            },
            _WYAutoCache.tMenuBannedPlayerNames,
            _WYAutoCache.tMenuPriorPlayerNames,
        }, 
        {  -- 自定义目标锁定
            szOption = "自定义目标锁定 ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 3,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 3
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]目标锁定/增强·模式切换·自定义目标锁定")
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 条件编辑器
                szOption = "条件编辑器 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                bCheck = false,
                bChecked = false,
                fnAction = function()
                    -- 弹出界面
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自定义目标锁定条件编辑器。")
                end,
                fnAutoClose = function() return true end
            },
        }, 
        { bDevide = true }, 
        {  -- 禁止选中剑心
            szOption = "禁止选中剑心 ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
            bCheck = true,
            bChecked = _WYAutoData.bUnfocusJX,
            fnAction = function()
                _WYAutoData.bUnfocusJX = not _WYAutoData.bUnfocusJX
                if _WYAutoData.bUnfocusJX == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]禁止选中剑心已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]禁止选中剑心已关闭")
                end
            end,
            fnMouseEnter = function()
                Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n禁止选中剑心防止误伤，点击切换启用/禁用状态。")
            end,
            fnAutoClose = function() return true end
        },
    }
	local menu_b_2 = {  -- 自动剑舞
			szOption = "自动剑舞 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoJW,
			fnAction = function()
                _WYAutoData.bAutoJW = not _WYAutoData.bAutoJW
                Tms_WYAuto.Reload()
                if _WYAutoData.bAutoJW == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]自动剑舞已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]自动剑舞已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动剑舞，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_3 = {  -- 范围技能辅助
			szOption = "范围技能辅助 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoArea,
			fnAction = function()
                _WYAutoData.bAutoArea = not _WYAutoData.bAutoArea
                if _WYAutoData.bAutoArea==true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]范围技能辅助已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]范围技能辅助已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n范围技能无目标向自己释放，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_4 = {  -- 只Tab玩家
			szOption = "只Tab玩家 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bTabPvp,
			fnAction = function()
                _WYAutoData.bTabPvp = not _WYAutoData.bTabPvp
                if _WYAutoData.bTabPvp == true then
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]只Tab玩家已开启")
                else
                    Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]只Tab玩家已关闭")
                end
                --true限制搜索玩家 --pvp
                SearchTarget_SetOtherSettting("OnlyPlayer",_WYAutoData.bTabPvp, "Enmey")
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n只Tab玩家，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_5 = {  -- 其它
			szOption = "其它 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = false,
			fnAction = function() end,
			fnAutoClose = function() return true end,
            {  -- 修剪附近的羊毛
			szOption = "修剪附近的羊毛 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = false,
			fnAction = function() 
                local me = GetClientPlayer()
                for tid,tar in pairs(TMS.GetNearPlayerList()) do
                    if tar and tar.dwSchoolID == 2 and tar.dwID~=me.dwID then
                        local tSay = {
                            {type = "name", name = me.szName},
                            {type = "text", text = "麻利的拔光了"},
                            {type = "name", name = tar.szName},
                            {type = "text", text = "的羊毛。"},
                        }
                        me.Talk( _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.NEARBY, "", tSay)
                    end
                end
                local tSay = {
                    {type = "name", name = me.szName},
                    {type = "text", text = "收拾了一下背包里的羊毛，希望今年能卖个好价钱。"},
                }
                me.Talk( _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.NEARBY, "", tSay)
            end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n修剪一下附近所有的蠢羊。")
			end,
			fnAutoClose = function() return true end
		}
		}
	local menu_c_1 = {  -- 退回角色列表
			szOption = "退回角色列表 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("返回角色选择页。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_c_2 = {  -- 退回登录界面
			szOption = "退回登录界面 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("返回账号登录页。")
			end,
			fnAutoClose = function() return true end
		}
	--table.insert(menu_0_0, menu_0_0_0)
    -- table.insert(menu_0, menu_0_0)
    table.insert(menu, menu_a_0)
    table.insert(menu, menu_a_1)
	table.insert(menu, {bDevide = true})
	table.insert(menu, menu_b_1)
	table.insert(menu, menu_b_2)
	table.insert(menu, menu_b_3)
	table.insert(menu, menu_b_4)
	table.insert(menu, menu_b_5)
	table.insert(menu, {bDevide = true})
	table.insert(menu, menu_c_1)
	table.insert(menu, menu_c_2)
	return menu
end

---------------------------------------------------
-- 创建菜单
Tms_WYAuto.GetTargetMenu = function(dwID)
    local tar = GetNpc(dwID)
    local bIsNpc = true
    if not tar then tar = GetPlayer(dwID) bIsNpc = false end
    local szName = false
    if tar then szName = tar.szName end
	return {  -- 目标菜单
        szOption = "[目标选中]加入屏蔽列表",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
        bCheck = true,
        bChecked = (bIsNpc and _WYAutoData.szBannedEnemyNames[szName]) or _WYAutoData.szBannedPlayerNames[szName],
        fnAction = function()
            if not szName then return end
            if bIsNpc then _WYAutoData.szBannedEnemyNames[szName] = not _WYAutoData.szBannedEnemyNames[szName]
            else _WYAutoData.szBannedPlayerNames[szName] = not _WYAutoData.szBannedPlayerNames[szName] end
            if (bIsNpc and _WYAutoData.szBannedEnemyNames[szName]) or _WYAutoData.szBannedPlayerNames[szName] then
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已加入目标选择屏蔽列表："..szName)
            else
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已移除目标选择屏蔽列表："..szName)
            end
            Tms_WYAuto.Reload()
        end,
        fnMouseEnter = function()
            Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n加入/移除 目标自动选择列表。")
        end,
        fnAutoClose = function() return true end
    }
	,{  -- 目标菜单
        szOption = "[目标选中]加入优先列表",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
        bCheck = true,
        bChecked = (bIsNpc and _WYAutoData.szPriorEnemyNames[szName]) or _WYAutoData.szPriorPlayerNames[szName],
        fnAction = function()
            if not szName then return end
            if bIsNpc then _WYAutoData.szPriorEnemyNames[szName] = not _WYAutoData.szPriorEnemyNames[szName]
            else _WYAutoData.szPriorPlayerNames[szName] = not _WYAutoData.szPriorPlayerNames[szName] end
            if (bIsNpc and _WYAutoData.szPriorEnemyNames[szName]) or _WYAutoData.szPriorPlayerNames[szName] then
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已加入目标选择优先列表："..szName)
            else
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已移除目标选择优先列表："..szName)
            end
            Tms_WYAuto.Reload()
        end,
        fnMouseEnter = function()
            Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n加入/移除 目标自动选择列表。")
        end,
        fnAutoClose = function() return true end
    }
    ,{  -- 目标转火
        szOption = "[目标转火]加入转火列表",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
        bCheck = true,
        bChecked = _WYAutoData.szAutoFocusNames[szName],
        fnAction = function()
            if not szName then return end
            _WYAutoData.szAutoFocusNames[szName] = not _WYAutoData.szAutoFocusNames[szName]
            if _WYAutoData.szAutoFocusNames[szName] then
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已加入目标集火列表："..szName)
            else
                Tms_WYAuto.println("[茗伊插件·挽月堂手残专用]已移除目标集火列表："..szName)
            end
            Tms_WYAuto.Reload()
        end,
        fnMouseEnter = function()
            Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n加入/移除 目标自动集火列表。")
        end,
        fnAutoClose = function() return true end
    }
end
---------------------------------------------------
-- 事件注册
-- RegisterEvent("LOGIN_GAME", function()
	-- local tMenu = {
		-- function()
			-- return {Tms_WYAuto.GetMenuList()}
		-- end,
	-- }
	-- Player_AppendAddonMenu(tMenu)
-- end)
RegisterEvent("CUSTOM_DATA_LOADED", Tms_WYAuto.Loaded)
-- RegisterEvent("BUFF_UPDATE", Tms_WYAuto.Breathe)
RegisterEvent("CUSTOM_DATA_LOADED", Tms_WYAuto.Reload)
Tms_WYAuto.println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]插件加载中……")

---------------------------------------------------
--这一条语句最好放在lua文件的末尾，也就是你定义的函数的后面
-- Wnd.OpenWindow("Interface/Tms_WYAuto/Tms_WYAuto.ini","Tms_WYAuto")
--第一个参数是窗体文件路径，第二个参数是窗体名，也就是WYAuto.ini的第一行那个名字。
---------------------------------------------------