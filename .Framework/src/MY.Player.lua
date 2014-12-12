---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Player = MY.Player or {}
local _Cache, _L = {}, MY.LoadLangPack()
--[[
#######################################################################################################
              #     #       #             # #                         #             #             
  # # # #     #     #         #     # # #         # # # # # #         #             #             
  #     #   #       #               #                 #         #     #     # # # # # # # # #     
  #     #   #   # # # #             #                 #         #     #             #             
  #   #   # #       #     # # #     # # # # # #       # # # #   #     #       # # # # # # #       
  #   #     #       #         #     #     #         #       #   #     #             #             
  #     #   #   #   #         #     #     #       #   #     #   #     #   # # # # # # # # # # #   
  #     #   #     # #         #     #     #             #   #   #     #           #   #           
  #     #   #       #         #     #     #               #     #     #         #     #       #   
  # # #     #       #         #   #       #             #             #       # #       #   #     
  #         #       #       #   #                     #               #   # #   #   #     #       
  #         #     # #     #       # # # # # # #     #             # # #         # #         # #  
#######################################################################################################
]]
_Cache.tNearNpc = {}      -- 附近的NPC
_Cache.tNearPlayer = {}   -- 附近的物品
_Cache.tNearDoodad = {}   -- 附近的玩家

--[[ 获取附近NPC列表
    (table) MY.GetNearNpc(void)
]]
MY.Player.GetNearNpc = function(nLimit)
    local tNpc, i = {}, 0
    for dwID, _ in pairs(_Cache.tNearNpc) do
        local npc = GetNpc(dwID)
        if not npc then
            _Cache.tNearNpc[dwID] = nil
        else
            i = i + 1
            if npc.szName=="" then
                npc.szName = string.gsub(Table_GetNpcTemplateName(npc.dwTemplateID), "^%s*(.-)%s*$", "%1")
            end
            tNpc[dwID] = npc
            if nLimit and i == nLimit then break end
        end
    end
    return tNpc, i
end
MY.GetNearNpc = MY.Player.GetNearNpc

--[[ 获取附近玩家列表
    (table) MY.GetNearPlayer(void)
]]
MY.Player.GetNearPlayer = function(nLimit)
    local tPlayer, i = {}, 0
    for dwID, _ in pairs(_Cache.tNearPlayer) do
        local player = GetPlayer(dwID)
        if not player then
            _Cache.tNearPlayer[dwID] = nil
        else
            i = i + 1
            tPlayer[dwID] = player
            if nLimit and i == nLimit then break end
        end
    end
    return tPlayer, i
end
MY.GetNearPlayer = MY.Player.GetNearPlayer

--[[ 获取附近物品列表
    (table) MY.GetNearPlayer(void)
]]
MY.Player.GetNearDoodad = function(nLimit)
    local tDoodad, i = {}, 0
    for dwID, _ in pairs(_Cache.tNearDoodad) do
        local dooded = GetDoodad(dwID)
        if not dooded then
            _Cache.tNearDoodad[dwID] = nil
        else
            i = i + 1
            tDoodad[dwID] = dooded
            if nLimit and i == nLimit then break end
        end
    end
    return tDoodad, i
end
MY.GetNearDoodad = MY.Player.GetNearDoodad

RegisterEvent("NPC_ENTER_SCENE",    function() _Cache.tNearNpc[arg0]    = true end)
RegisterEvent("NPC_LEAVE_SCENE",    function() _Cache.tNearNpc[arg0]    = nil  end)
RegisterEvent("PLAYER_ENTER_SCENE", function() _Cache.tNearPlayer[arg0] = true end)
RegisterEvent("PLAYER_LEAVE_SCENE", function() _Cache.tNearPlayer[arg0] = nil  end)
RegisterEvent("DOODAD_ENTER_SCENE", function() _Cache.tNearDoodad[arg0] = true end)
RegisterEvent("DOODAD_LEAVE_SCENE", function() _Cache.tNearDoodad[arg0] = nil  end)

--[[获取好友列表
]]
MY.Player.GetFriendList = function(arg0)
    local t = {}
    local me = GetClientPlayer()
    local tGroup = { { id = 0, name = "" } }
    for _, group in ipairs(me.GetFellowshipGroupInfo() or {}) do
        table.insert(tGroup, group)
    end
    if type(arg0)=="number" then
        for i=#tGroup, 1, -1 do
            if arg0~=tGroup[i].id then
                table.remove(tGroup, i)
            end
        end
    elseif type(arg0)=="string" then
        for i=#tGroup, 1, -1 do
            if arg0~=tGroup[i].name then
                table.remove(tGroup, i)
            end
        end
    end
    local n = 0
    for _,group in ipairs(tGroup) do
        for _,p in ipairs(me.GetFellowshipInfo(group.id)) do
            t[p.id] = p
            n = n + 1
        end
    end
    
    return t, n
end

--[[获取好友
]]
MY.Player.GetFriend = function(arg0)
    if not arg0 then return nil end
    local tFriend = MY.Player.GetFriendList()
    if type(arg0) == "number" then
        return tFriend[arg0]
    elseif type(arg0) == "string" then
        for id, p in pairs(tFriend) do
            if p.name == arg0 then
                return p
            end
        end
    end
end
--[[
#######################################################################################################
                                  #                                                       #                   
  # # # # # # # # # # #         #                               # # # # # # # # #         #     # # # # #     
            #             # # # # # # # # # # #       #         #               #         #                   
          #               #                   #     #   #       #               #     # # # #                 
    # # # # # # # # # #   #                   #     #   #       # # # # # # # # #         #   # # # # # # #   
    #     #     #     #   #     # # # # #     #     # # # #     #               #       # #         #         
    #     # # # #     #   #     #       #     #   #   #   #     #               #       # # #       #         
    #     #     #     #   #     #       #     #   #   #   #     # # # # # # # # #     #   #     #   #   #     
    #     # # # #     #   #     #       #     #   #     #       #               #         #     #   #     #   
    #     #     #     #   #     # # # # #     #     # #   # #   #               #         #   #     #     #   
    # # # # # # # # # #   #                   #                 # # # # # # # # #         #         #         
    #                 #   #               # # #                 #               #         #       # #         
#######################################################################################################
]]
--[[ 取得目标类型和ID
    (dwType, dwID) MY.GetTarget()       -- 取得自己当前的目标类型和ID
    (dwType, dwID) MY.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
]]
MY.Player.GetTarget = function(object)
    if not object then
        object = GetClientPlayer()
    end
    if object then
        return object.GetTarget()
    else
        return TARGET.NO_TARGET, 0
    end
end
MY.GetTarget = MY.Player.GetTarget
--[[ 取得操作对象
    (KObject) MY.GetObject([number dwType, ]number dwID)
    -- dwType: [可选]对象类型枚举 TARGET.*
    -- dwID  : 对象ID
    -- return: 根据 dwType 类型和 dwID 取得操作对象
    --         不存在时返回nil
]]
MY.Player.GetObject = function(dwType, dwID)
    if not dwType then
        local me = GetClientPlayer()
        if me then
            dwType, dwID = me.GetTarget()
        else
            dwType, dwID = TARGET.NO_TARGET, 0
        end
    elseif not dwID then
        dwID, dwType = dwType, TARGET.NPC
        if IsPlayer(dwID) then
            dwType = TARGET.PLAYER
        end
    end
    if dwID <= 0 or dwType == TARGET.NO_TARGET then
        return nil
    elseif dwType == TARGET.PLAYER then
        return GetPlayer(dwID)
    elseif dwType == TARGET.DOODAD then
        return GetDoodad(dwID)
    else
        return GetNpc(dwID)
    end
end
MY.GetObject = MY.Player.GetObject

--[[ 根据 dwType 类型和 dwID 设置目标
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID]]
MY.Player.SetTarget = function(dwType, dwID)
    -- check dwType
    if type(dwType)=="userdata" then
        dwType, dwID = ( IsPlayer(dwType) and TARGET.PLAYER ) or TARGET.NPC, dwType.dwID
    elseif type(dwType)=="string" then
        dwType, dwID = 0, dwType
    end
    -- conv if dwID is string
    if type(dwID)=="string" then
        for _, p in pairs(MY.GetNearNpc()) do
            if p.szName == dwID then
                dwType, dwID = TARGET.NPC, p.dwID
            end
        end
        for _, p in pairs(MY.GetNearPlayer()) do
            if p.szName == dwID then
                dwType, dwID = TARGET.PLAYER, p.dwID
            end
        end
    end
    if not dwType or dwType <= 0 then
        dwType, dwID = TARGET.NO_TARGET, 0
    elseif not dwID then
        dwID, dwType = dwType, TARGET.NPC
        if IsPlayer(dwID) then
            dwType = TARGET.PLAYER
        end
    end
    SetTarget(dwType, dwID)
end
MY.SetTarget = MY.Player.SetTarget

--[[ 设置/取消 临时目标
    -- MY.Player.SetTempTarget(dwType, dwID)
    -- MY.Player.ResumeTarget()
]]
_Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
MY.Player.SetTempTarget = function(dwType, dwID)
    TargetPanel_SetOpenState(true)
    _Cache.pTempTarget = { GetClientPlayer().GetTarget() }
    MY.Player.SetTarget(dwType, dwID)
    TargetPanel_SetOpenState(false)
end
MY.SetTempTarget = MY.Player.SetTempTarget
MY.Player.ResumeTarget = function()
    TargetPanel_SetOpenState(true)
    -- 当之前的目标不存在时，切到空目标
    if _Cache.pTempTarget[1] ~= TARGET.NO_TARGET and not MY.GetObject(unpack(_Cache.pTempTarget)) then
        _Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
    end
    MY.Player.SetTarget(unpack(_Cache.pTempTarget))
    _Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
    TargetPanel_SetOpenState(false)
end
MY.ResumeTarget = MY.Player.ResumeTarget

--[[ 临时设置目标为指定目标并执行函数
    (void) MY.Player.WithTarget(dwType, dwID, callback)
]]
_Cache.tWithTarget = {}
_Cache.lockWithTarget = false
_Cache.WithTargetHandle = function()
    if _Cache.lockWithTarget or
    #_Cache.tWithTarget == 0 then
        return
    end

    _Cache.lockWithTarget = true
    local r = table.remove(_Cache.tWithTarget, 1)
    
    MY.Player.SetTempTarget(r.dwType, r.dwID)
    local status, err = pcall(r.callback)
    if not status then
        MY.Debug(err, 'MY.Player.lua#WithTargetHandle', 2)
    end
    MY.Player.ResumeTarget()
    
    _Cache.lockWithTarget = false
    _Cache.WithTargetHandle()
end
MY.Player.WithTarget = function(dwType, dwID, callback)
    -- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
    table.insert(_Cache.tWithTarget, {
        dwType   = dwType  ,
        dwID     = dwID    ,
        callback = callback,
    })
    _Cache.WithTargetHandle()
end

--[[ 求N2在N1的面向角  --  重载+2
    -- 输入N1坐标、面向、N2坐标
    (number) MY.GetFaceToTargetDegree(nX,nY,nFace,nTX,nTY)
    -- 输入N1、N2
    (number) MY.GetFaceToTargetDegree(oN1, oN2)
    -- 输出
    nil -- 参数错误
    number -- 面向角(0-180)
]]
MY.Player.GetFaceDegree = function(nX,nY,nFace,nTX,nTY)
    if type(nY)=="userdata" and type(nX)=="userdata" then nTX=nY.nX nTY=nY.nY nY=nX.nY nFace=nX.nFaceDirection nX=nX.nX end
    if type(nX)~="number" or type(nY)~="number" or type(nFace)~="number" or type(nTX)~="number" or type(nTY)~="number" then return nil end
    local a = nFace * math.pi / 128
    return math.acos( ( (nTX-nX)*math.cos(a) + (nTY-nY)*math.sin(a) ) / ( (nTX-nX)^2 + (nTY-nY)^2) ^ 0.5 ) * 180 / math.pi
end
--[[ 求oT2在oT1的正面还是背面
    (bool) MY.IsFaceToTarget(oT1,oT2)
    -- 正面返回true
    -- 背对返回false
    -- 参数不正确时返回nil
]]
MY.Player.IsFaceToTarget = function(oT1,oT2)
    if type(oT1)~="userdata" or type(oT2)~="userdata" then return nil end
    local a = oT1.nFaceDirection * math.pi / 128
    return (oT2.nX-oT1.nX)*math.cos(a) + (oT2.nY-oT1.nY)*math.sin(a) > 0
end
--[[ 装备名为szName的装备
    (void) MY.Equip(szName)
    szName  装备名称
]]
MY.Player.Equip = function(szName)
    local me = GetClientPlayer()
    for i=1,6 do
        if me.GetBoxSize(i)>0 then
            for j=0, me.GetBoxSize(i)-1 do
                local item = me.GetItem(i,j)
                if item == nil then
                    j=j+1
                elseif Table_GetItemName(item.nUiId)==szName then -- GetItemNameByItem(item)
                    local eRetCode, nEquipPos = me.GetEquipPos(i, j)
                    if szName==_L["ji guan"] or szName==_L["nu jian"] then
                        for k=0,15 do
                            if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, k) == nil then
                                OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
                                return
                            end
                        end
                        return
                    else
                        OnExchangeItem(i, j, INVENTORY_INDEX.EQUIP, nEquipPos)
                        return
                    end
                end
            end
        end
    end
end

--[[ 获取对象的buff列表
    (table) MY.GetBuffList(obj)
]]
MY.Player.GetBuffList = function(obj)
    obj = obj or GetClientPlayer()
    local aBuffTable = {}
    local nCount = obj.GetBuffCount() or 0
    for i=1,nCount,1 do
        local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
        if dwID then
            table.insert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid})
        end
    end
    return aBuffTable
end

_Cache.tPlayerSkills = {}   -- 玩家技能列表[缓存]   -- 技能名反查ID
_Cache.tSkillCache = {}     -- 技能列表缓存         -- 技能ID查技能名称图标
--[[ 通过技能名称获取技能对象
    (table) MY.GetSkillByName(szName)
]]
MY.Player.GetSkillByName = function(szName)
    if table.getn(_Cache.tPlayerSkills)==0 then
        for i = 1, g_tTable.Skill:GetRowCount() do
            local tLine = g_tTable.Skill:GetRow(i)
            if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not _Cache.tPlayerSkills[tLine.szName]) or tLine.fSortOrder>_Cache.tPlayerSkills[tLine.szName].fSortOrder) then
                _Cache.tPlayerSkills[tLine.szName] = tLine
            end
        end
    end
    return _Cache.tPlayerSkills[szName]
end
--[[ 判断技能名称是否有效
    (bool) MY.IsValidSkill(szName)
]]
MY.Player.IsValidSkill = function(szName)
    if MY.Player.GetSkillByName(szName)==nil then return false else return true end
end
--[[ 判断当前用户是否可用某个技能
    (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
]]
MY.Player.CanUseSkill = function(dwSkillID, dwLevel)
    -- 判断技能是否有效 并将中文名转换为技能ID
    if type(dwSkillID) == "string" then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.Player.GetSkillByName(dwSkillID).dwSkillID else return false end end
    local me, box = GetClientPlayer(), _Cache.hBox
    if me and box then
        if not dwLevel then
            if dwSkillID ~= 9007 then
                dwLevel = me.GetSkillLevel(dwSkillID)
            else
                dwLevel = 1
            end
        end
        if dwLevel > 0 then
            box:EnableObject(false)
            box:SetObjectCoolDown(1)
            box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
            UpdataSkillCDProgress(me, box)
            return box:IsObjectEnable() and not box:IsObjectCoolDown()
        end
    end
    return false
end
--[[ 释放技能,释放成功返回true
    (bool)MY.UseSkill(dwSkillID, bForceStopCurrentAction, eTargetType, dwTargetID)
    dwSkillID               技能ID
    bForceStopCurrentAction 是否打断当前运功
    eTargetType             释放目标类型
    dwTargetID              释放目标ID
]]
MY.Player.UseSkill = function(dwSkillID, bForceStopCurrentAction, eTargetType, dwTargetID)
    -- 判断技能是否有效 并将中文名转换为技能ID
    if type(dwSkillID) == "string" then if MY.Player.IsValidSkill(dwSkillID) then dwSkillID = MY.Player.GetSkillByName(dwSkillID).dwSkillID else return false end end
    local me = GetClientPlayer()
    -- 获取技能CD
    local bCool, nLeft, nTotal = me.GetSkillCDProgress( dwSkillID, me.GetSkillLevel(dwSkillID) ) local bIsPrepare ,dwPreSkillID ,dwPreSkillLevel , fPreProgress= me.GetSkillPrepareState()
    local oTTP, oTID = me.GetTarget()
    if dwTargetID~=nil then SetTarget(eTargetType, dwTargetID) end
    if ( not bCool or nLeft == 0 and nTotal == 0 ) and not ( not bForceStopCurrentAction and dwPreSkillID == dwSkillID ) then
        me.StopCurrentAction() OnAddOnUseSkill( dwSkillID, me.GetSkillLevel(dwSkillID) )
        if dwTargetID then SetTarget(oTTP, oTID) end
        return true
    else
        if dwTargetID then SetTarget(oTTP, oTID) end
        return false
    end
end
-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) MY.Player.GetSkillName(number dwSkillID[, number dwLevel])
MY.Player.GetSkillName = function(dwSkillID, dwLevel)
    if not _Cache.tSkillCache[dwSkillID] then
        local tLine = Table_GetSkill(dwSkillID, dwLevel)
        if tLine and tLine.dwSkillID > 0 and tLine.bShow
            and (StringFindW(tLine.szDesc, "_") == nil  or StringFindW(tLine.szDesc, "<") ~= nil)
        then
            _Cache.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
        else
            local szName = "SKILL#" .. dwSkillID
            if dwLevel then
                szName = szName .. ":" .. dwLevel
            end
            _Cache.tSkillCache[dwSkillID] = { szName, 13 }
        end
    end
    return unpack(_Cache.tSkillCache[dwSkillID])
end

--[[ 登出游戏
    (void) MY.LogOff(bCompletely)
    bCompletely 为true返回登陆页 为false返回角色页 默认为false
]]
MY.Player.LogOff = function(bCompletely)
    if bCompletely then
        ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
    else
        ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
    end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) MY.Player.GetChannelSkillFrame(number dwSkillID)
MY.Player.GetChannelSkillFrame = function(dwSkillID)
    local t = _Cache.tSkillEx[dwSkillID]
    if t then
        return t.nChannelFrame
    end
end
-- Load skill extend data
_Cache.tSkillEx = LoadLUAData(MY.GetAddonInfo().szFrameworkRoot.."data/skill_ex") or {}