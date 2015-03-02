local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."XLifeBar/lang/")
local _Cache = {}
local OT_STATE = {
    START_SKILL   = 1,  -- 开始技能读条(显示边框)
    START_PREPARE = 2,  -- 开始读条(显示边框)
    START_CHANNEL = 3,  -- 开始逆读条(显示边框)
    ON_SKILL      = 4,  -- 正在技能读条(需要每帧获取值重绘)
    ON_PREPARE    = 5,  -- 正在正向读条(需要每帧计算重绘)
    ON_CHANNEL    = 6,  -- 正在逆向读条(需要每帧计算重绘)
    BREAK = 7,          -- 打断读条(变红隐藏)
    SUCCEED = 8,        -- 读条成功结束(隐藏)
    FAILED = 9,         -- 读条失败结束(隐藏)
    IDLE  = 10,         -- 没有读条(空闲)
}

-- 这个只是默认配置 改这里没用的 会修改的话 修改data文件
local Config_Default = {
    nCamp = -1,
    Col = {
        Player = {
            Self  = {30 ,140,220},      -- 自己
            Party = {30 ,140,220},      -- 团队
            Enemy = {255,30 ,30 },      -- 敌对
            Neutrality = {255,255,0},   -- 中立
            Ally  = {30 ,255,30 },      -- 相同阵营
        },
        Npc = {
            Party = {30 ,140,220},-- 团队
            Enemy = {255,30 ,30 },-- 敌对
            Neutrality = {255,255,0},-- 中立
            Ally  = {30 ,255,30 },-- 相同阵营
        }
    },
    bShowName    = { Player = { Self = true , Party = true , Neutrality = true , Enemy = true , Ally = true , }, Npc = { Party = true , Neutrality = true , Enemy = true , Ally = true , }, },
    bShowTitle   = { Player = { Self = true , Party = true , Neutrality = true , Enemy = true , Ally = true , }, Npc = { Party = true , Neutrality = true , Enemy = true , Ally = true , }, },
    bShowTong    = { Player = { Self = true , Party = true , Neutrality = true , Enemy = true , Ally = true , },},
    bShowLife    = { Player = { Self = true , Party = true , Neutrality = true , Enemy = true , Ally = true , }, Npc = { Party = false, Neutrality = true , Enemy = true , Ally = true , }, },
    bShowLifePer = { Player = { Self = false, Party = false, Neutrality = false, Enemy = false, Ally = false, }, Npc = { Party = false, Neutrality = false, Enemy = false, Ally = false, }, },
    bShowOTBar   = { Player = { Self = true , Party = false, Neutrality = false, Enemy = true , Ally = false, }, Npc = { Party = false, Neutrality = false, Enemy = true , Ally = false, }, },
    nLineHeight = { 100, 80, 60},
    bShowSpecialNpc = false,
    
    nLifeWidth = 80,
    nLifeHeight = 8,
    nLifeOffsetY = 27,
    nPerHeight = 42,
    
    nOTBarWidth = 80,
    nOTBarHeight = 6,
    nOTBarOffsetY = 22,
    nOTTitleHeight = 21,
    bOTEnhancedMod = false,
    
    nAlpha = 200,
    nFont = 16,
    nDistance = 24 * 24 * 64 * 64,
    
    bHideLifePercentageWhenFight = false,
    bHideLifePercentageDecimal = false,
    
    bAdjustIndex = false,
}
local Config = clone(Config_Default)

XLifeBar = XLifeBar or {}
setmetatable(XLifeBar, { __call = function(me, ...) return me.X.new(...) end, __metatable = true })
XLifeBar.bEnabled = false
XLifeBar.bUseGlobalConfig = false
XLifeBar.tSysHeadTop      = false
RegisterCustomData("XLifeBar.bEnabled")
RegisterCustomData("XLifeBar.bUseGlobalConfig")
RegisterCustomData("XLifeBar.tSysHeadTop")
local _XLifeBar = {
    szConfig = "userdata/XLifeBar/cfg",
    tObject = {},
    tTongList = {},
    tNpc = {},
    tPlayer = {},
    dwTargetID = 0,
    bFightState = false,
}
local HP = XLifeBar.HP

_XLifeBar.GetNz = function(nZ,nZ2)
    return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

_XLifeBar.GetForce = function(dwID)
    local me = GetClientPlayer()
    if not me then
        return "Neutrality"
    end
    if Config.nCamp == -1 or not IsPlayer(dwID) then
        if dwID == me.dwID then
            return "Self"
        elseif IsParty(me.dwID, dwID) then
            return "Party"
        elseif IsNeutrality(me.dwID, dwID) then
            return "Neutrality"
        elseif IsEnemy(me.dwID, dwID) then -- 敌对关系
            local r,g,b = GetHeadTextForceFontColor(dwID, me.dwID)
            if r == 255 and g == 255 and b == 0 then
                return "Neutrality"
            else
                return "Enemy"
            end
        elseif IsAlly(me.dwID, dwID) then -- 相同阵营
            return "Ally"
        else
            return "Neutrality" -- "Other"
        end
    else
        local tar = MY.GetObject(TARGET.PLAYER, dwID)
        if not tar then
            return "Neutrality"
        elseif dwID == me.dwID then
            return "Self"
        elseif IsParty(me.dwID, dwID) then
            return "Party"
        elseif tar.nCamp == Config.nCamp then
            return "Ally"
        elseif not tar.bCampFlag or     -- 没开阵营
        tar.nCamp == CAMP.NEUTRAL or    -- 目标中立
        Config.nCamp == CAMP.NEUTRAL or -- 自己中立
        me.GetScene().nCampType == MAP_CAMP_TYPE.ALL_PROTECT then -- 停战地图
            return "Neutrality"
        else
            return "Enemy"
        end
    end
end

_XLifeBar.GetTongName = function(dwTongID, szFormatString)
    szFormatString = szFormatString or "%s"
    if type(dwTongID) ~= 'number' or dwTongID == 0 then
        return nil
    end
    if not _XLifeBar.tTongList[dwTongID] then
        if GetTongClient().ApplyGetTongName(dwTongID) then
            _XLifeBar.tTongList[dwTongID] = GetTongClient().ApplyGetTongName(dwTongID)
        end
    end
    if _XLifeBar.tTongList[dwTongID] then
        return string.format(szFormatString, _XLifeBar.tTongList[dwTongID])
    end
end

-- 获取读条状态
_XLifeBar.bLock = false
_XLifeBar.aCallback = {}
_XLifeBar.WithPrepareStateHandle = function()
    if _XLifeBar.bLock then return end
    if #_XLifeBar.aCallback > 0 then
        _XLifeBar.bLock = true
        local r = table.remove(_XLifeBar.aCallback, 1)
        local object, callback = r.object, r.callback
        
        local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = object.GetSkillPrepareState()
        if (not bIsPrepare) and object.GetOTActionState then   -- 如果没读条 判断一下如果是玩家(有object.GetOTActionState方法)的话 判断OTActionState是否为0
            if object.GetOTActionState()==1 then    -- 为1 说明在副本外不能获取 设置一下临时目标再试一次
                MY.Player.SetTempTarget(TARGET.PLAYER, object.dwID)
                bIsPrepare, dwSkillID, dwSkillLevel, fProgress = object.GetSkillPrepareState()
                MY.Player.ResumeTarget()
            end
        end
        
        pcall(callback, bIsPrepare, dwSkillID, dwSkillLevel, fProgress, r.param)
        _XLifeBar.bLock = false
        _XLifeBar.WithPrepareStateHandle()
    end
end
_XLifeBar.WithPrepareState = function(object, callback, param)
    if Config.bOTEnhancedMod then   -- 增强模式（切换目标）
        -- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
        table.insert(_XLifeBar.aCallback, {object = object, callback = callback, param = param})
        _XLifeBar.WithPrepareStateHandle()
    else
        local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = object.GetSkillPrepareState()
        pcall(callback, bIsPrepare, dwSkillID, dwSkillLevel, fProgress, param)
    end
end

-- 重绘所有UI，并在bNoSave为假时保存配置文件
_XLifeBar.Reset = function(bNoSave)
    _XLifeBar.tObject = {}
    _XLifeBar.Handle:Clear()
    if not bNoSave then
        if XLifeBar.bUseGlobalConfig then
            MY.Sys.SaveLUAData(_XLifeBar.szConfig, Config)
        else
            MY.Sys.SaveUserData(_XLifeBar.szConfig, Config)
        end
    end
    -- auto adjust index
    MY.BreatheCall("XLifeBar_AdjustIndex")
    if Config.bAdjustIndex then
        MY.BreatheCall("XLifeBar_AdjustIndex", function()
            local n = 0
            local t = {}
            -- refresh current index data
            for dwID, tab in pairs(_XLifeBar.tObject) do
                n = n + 1
                if n > 200 then
                    break
                end
                PostThreadCall(function(tab, xScreen, yScreen)
                    tab.nIndex = yScreen or 0
                end, tab, "Scene_GetCharacterTopScreenPos", dwID)
                
                table.insert(t, { handle = tab.handle, index = tab.nIndex })
            end
            -- sort
            table.sort(t, function(a, b) return a.index < b.index end)
            -- adjust
            for i = #t, 1, -1 do
                if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
                    t[i].handle:ExchangeIndex(i - 1)
                end
            end
        end, 500)
    end
    
    if XLifeBar.bEnabled then
        if Config.bShowName.Npc.Party or Config.bShowName.Npc.Neutrality
        or Config.bShowName.Npc.Ally  or Config.bShowName.Npc.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME , false)
        end
        if Config.bShowTitle.Npc.Party or Config.bShowTitle.Npc.Neutrality
        or Config.bShowTitle.Npc.Ally or Config.bShowTitle.Npc.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE, false)
        end
        if Config.bShowLife.Npc.Party or Config.bShowLife.Npc.Neutrality
        or Config.bShowLife.Npc.Ally or Config.bShowLife.Npc.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LEFE , false)
        end
        if Config.bShowName.Player.Party or Config.bShowName.Player.Neutrality
        or Config.bShowName.Player.Ally or Config.bShowName.Player.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME , false)
        end
        if Config.bShowTitle.Player.Party or Config.bShowTitle.Player.Neutrality
        or Config.bShowTitle.Player.Ally or Config.bShowTitle.Player.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE, false)
        end
        if Config.bShowLife.Player.Party or Config.bShowLife.Player.Neutrality
        or Config.bShowLife.Player.Ally or Config.bShowLife.Player.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LEFE , false)
        end
        if Config.bShowTong.Player.Party or Config.bShowTong.Player.Neutrality
        or Config.bShowTong.Player.Ally or Config.bShowTong.Player.Enemy then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD, false)
        end
        if Config.bShowName.Player.Self then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , false)
        end
        if Config.bShowTitle.Player.Self then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, false)
        end
        if Config.bShowLife.Player.Self then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LEFE , false)
        end
        if Config.bShowTong.Player.Self then
            SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, false)
        end
    elseif XLifeBar.tSysHeadTop then
        SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME , XLifeBar.tSysHeadTop['GLOBAL_HEAD_NPC_NAME'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE, XLifeBar.tSysHeadTop['GLOBAL_HEAD_NPC_TITLE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LEFE , XLifeBar.tSysHeadTop['GLOBAL_HEAD_NPC_LEFE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME , XLifeBar.tSysHeadTop['GLOBAL_HEAD_OTHERPLAYER_NAME'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE, XLifeBar.tSysHeadTop['GLOBAL_HEAD_OTHERPLAYER_TITLE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LEFE , XLifeBar.tSysHeadTop['GLOBAL_HEAD_OTHERPLAYER_LEFE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD, XLifeBar.tSysHeadTop['GLOBAL_HEAD_OTHERPLAYER_GUILD'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , XLifeBar.tSysHeadTop['GLOBAL_HEAD_CLIENTPLAYER_NAME'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, XLifeBar.tSysHeadTop['GLOBAL_HEAD_CLIENTPLAYER_TITLE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LEFE , XLifeBar.tSysHeadTop['GLOBAL_HEAD_CLIENTPLAYER_LEFE'])
        SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, XLifeBar.tSysHeadTop['GLOBAL_HEAD_CLIENTPLAYER_GUILD'])
    end
end
-- 重载配置文件并重绘
_XLifeBar.Reload = function()
    local _Config
    if XLifeBar.bUseGlobalConfig then
        _Config = MY.Sys.LoadLUAData(_XLifeBar.szConfig)
    else
        _Config = MY.Sys.LoadUserData(_XLifeBar.szConfig)
    end
    if _Config then
        Config = _Config
        for k, v in pairs(Config_Default) do
            if type(Config[k])~=type(Config_Default[k]) then
                Config[k] = clone(Config_Default[k])
            end
        end
        _XLifeBar.Reset(true)
    end
end
MY.RegisterInit(function()
    Wnd.OpenWindow("interface/MY/XLifeBar/XLifeBar.ini","XLifeBar")
    _XLifeBar.Reload()
end)
MY.RegisterEvent('LOADING_END', _XLifeBar.Reload) -- 过图重新加载刷新界面

XLifeBar.X = class()
-- 构造函数
function XLifeBar.X:ctor(object)
    if not _XLifeBar.tObject[object.dwID] then
        _XLifeBar.tObject[object.dwID] = {
            handle  = nil,
            szName  = '' ,
            szTong  = '' ,
            szTitle = '' ,
            fLife   = -1 ,
            szForce = _XLifeBar.GetForce(object.dwID),
            OT = {
                nState      = OT_STATE.IDLE,
                nPercentage = 0            ,
                szTitle     = ""           ,
                nStartFrame = 0            ,
                nFrameCount = 0            ,
            },
            nIndex = 0,
        }
    end
    self.self = object
    self.tab = _XLifeBar.tObject[object.dwID]
    self.force = self.tab.szForce
    self.hp = HP.new(object.dwID, _XLifeBar.Handle, _XLifeBar.tObject[object.dwID].handle)
    return self
end
-- 创建UI
function XLifeBar.X:Create()
    if not self.hp.handle then
        -- 创建UI
        self.hp:Create()
        -- handle写回缓存 防止二次Create()
        _XLifeBar.tObject[self.self.dwID].handle = self.hp.handle
        -- 开始绘制永远不会重绘的东西
        -- 绘制血条边框
        local cfgLife
        if IsPlayer(self.self.dwID) then
            cfgLife = Config.bShowLife.Player[self.force]
        else
            cfgLife = Config.bShowLife.Npc[self.force]
        end
        if cfgLife then
            self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, Config.nAlpha)
        end
    end
    return self
end
-- 删除UI
function XLifeBar.X:Remove()
    if self.hp.handle then
        self.hp:Remove()
    end
    _XLifeBar.tObject[self.self.dwID] = nil
    return self
end
-- 对目标头顶颜色进行滤镜处理（高亮/死亡）
function XLifeBar.X:FxColor(r,g,b,a)
    -- 死亡判定
    if self.self.nMoveState == MOVE_STATE.ON_DEATH then
        if _XLifeBar.dwTargetID == self.self.dwID then
            return math.ceil(r/2.2), math.ceil(g/2.2), math.ceil(b/2.2), a
        else
            return math.ceil(r/2.5), math.ceil(g/2.5), math.ceil(b/2.5), a
        end
    elseif _XLifeBar.dwTargetID == self.self.dwID then
        return 255-(255-r)*0.3, 255-(255-g)*0.3, 255-(255-b)*0.3, a
    else
        return r,g,b,a
    end
end
-- 设置名字
function XLifeBar.X:SetName(szName)
    if self.tab.szName ~= szName then
        self.tab.szName = szName
        self:DrawNames()
    end
    return self
end
-- 设置称号
function XLifeBar.X:SetTitle(szTitle)
    if self.tab.szTitle ~= szTitle then
        self.tab.szTitle = szTitle
        self:DrawNames()
    end
    return self
end
-- 设置帮会
function XLifeBar.X:SetTong(szTongName)
    if self.tab.szTong ~= szTongName then
        self.tab.szTong = szTongName
        self:DrawNames()
    end
    return self
end
-- 重绘头顶文字
function XLifeBar.X:DrawNames()
    local tWordlines = {}
    local r,g,b,a,f
    local cfgName, cfgTitle, cfgTong
    local tab = _XLifeBar.tObject[self.self.dwID]
    if IsPlayer(self.self.dwID) then
        cfgLife  = Config.bShowLife.Player[self.force]
        cfgName  = Config.bShowName.Player[self.force]
        cfgTitle = Config.bShowTitle.Player[self.force]
        cfgTong  = Config.bShowTong.Player[self.force]
        r,g,b    = unpack(Config.Col.Player[self.force])
    else
        cfgLife  = Config.bShowLife.Npc[self.force]
        cfgName  = Config.bShowName.Npc[self.force]
        cfgTitle = Config.bShowTitle.Npc[self.force]
        cfgTong  = false
        r,g,b    = unpack(Config.Col.Npc[self.force])
    end
    a,f = Config.nAlpha, Config.nFont
    r,g,b,a = self:FxColor(r,g,b,a)
    
    local i = #Config.nLineHeight
    if cfgTong and self.self.dwTongID and self.self.dwTongID ~= 0 then
        local szTongName = _XLifeBar.GetTongName(self.self.dwTongID, "[%s]")
        if szTongName then
            table.insert( tWordlines, {szTongName, Config.nLineHeight[i]} )
            i = i - 1
        end
    end
    if cfgTitle and self.self.szTitle and self.self.szTitle~="" then
        table.insert( tWordlines, {"<" .. self.self.szTitle .. ">", Config.nLineHeight[i]} )
        i = i - 1
    end
    if cfgName then
        local szName = MY.Game.GetObjectName(self.self)
        if szName and not tonumber(szName) then
            table.insert( tWordlines, {MY.Game.GetObjectName(self.self), Config.nLineHeight[i]} )
            i = i - 1
        end
    end
    
    -- 没有名字的玩意隐藏血条
    if cfgName and #tWordlines == 0 then
        self.hp:DrawLifebar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, {r,g,b,0,self.tab.fLife})
        self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, 0)
    elseif cfgLife then
        self.hp:DrawLifebar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, {r,g,b,a,self.tab.fLife})
        self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, a)
    end
    self.hp:DrawWordlines(tWordlines, {r,g,b,a,f})
    return self
end
-- 设置血量
function XLifeBar.X:SetLife(dwLifePercentage)
    if dwLifePercentage < 0 or dwLifePercentage > 1 then dwLifePercentage = 1 end -- fix
    if self.tab.fLife ~= dwLifePercentage then
        local dwLife = self.tab.fLife
        self.tab.fLife = dwLifePercentage
        if dwLife < 0.01 or dwLifePercentage < 0.01 then
            self:DrawNames()
        end
        self:DrawLife()
    end
    return self
end
function XLifeBar.X:DrawLife()
    local cfgLife, cfgLifePer, r,g,b,a,f
    if IsPlayer(self.self.dwID) then
        cfgLife    = Config.bShowLife.Player[self.force]
        cfgLifePer = Config.bShowLifePer.Player[self.force]
        r,g,b      = unpack(Config.Col.Player[self.force])
    else
        cfgLife    = Config.bShowLife.Npc[self.force]
        cfgLifePer = Config.bShowLifePer.Npc[self.force]
        r,g,b      = unpack(Config.Col.Npc[self.force])
    end
    a, f = Config.nAlpha, Config.nFont
    r,g,b,a = self:FxColor(r,g,b,a)
    if cfgLife then
        self.hp:DrawLifebar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetY, {r,g,b,a,self.tab.fLife})
    end
    if cfgLifePer then
        local szFormatString = '%.1f'
        if Config.bHideLifePercentageWhenFight and not GetClientPlayer().bFightState then
            szFormatString = ''
        elseif Config.bHideLifePercentageDecimal then
            szFormatString = '%.0f'
        end
        self.hp:DrawLifePercentage({string.format(szFormatString, 100 * self.tab.fLife), Config.nPerHeight}, {r,g,b,a,f})
    end
    return self
end
-- 设置/获取OT状态
function XLifeBar.X:SetOTState(nState)
    if nState == OT_STATE.BREAK then
        self.tab.OT.nStartFrame = GetLogicFrameCount()
        self:DrawOTBar({255,0,0}):DrawOTTitle({255,0,0})
    elseif nState == OT_STATE.SUCCEED then
        self.tab.OT.nStartFrame = GetLogicFrameCount()
    end
    self.tab.OT.nState = nState
    return self
end
function XLifeBar.X:GetOTState()
    return self.tab.OT.nState
end
-- 设置读条标题
function XLifeBar.X:SetOTTitle(szOTTitle, rgba)
    if self.tab.OT.szTitle ~= szOTTitle then
        self.tab.OT.szTitle = szOTTitle
        self:DrawOTTitle(rgba)
    end
    return self
end
function XLifeBar.X:DrawOTTitle(rgba)
    local cfgOTBar, r,g,b,a,f
    if IsPlayer(self.self.dwID) then
        cfgOTBar   = Config.bShowOTBar.Player[self.force]
        r,g,b      = unpack(Config.Col.Player[self.force])
    else
        cfgOTBar   = Config.bShowOTBar.Npc[self.force]
        r,g,b      = unpack(Config.Col.Npc[self.force])
    end
    a, f = Config.nAlpha, Config.nFont
    if rgba then r,g,b,a = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
    r,g,b,a = self:FxColor(r,g,b,a)
    if cfgOTBar then
        self.hp:DrawOTTitle({self.tab.OT.szTitle, Config.nOTTitleHeight }, {r,g,b,a,f})
    end
    return self
end
-- 设置读条进度
function XLifeBar.X:SetOTPercentage(nPercentage, rgba)
    if nPercentage > 1 then nPercentage = 1 elseif nPercentage < 0 then nPercentage = 0 end
    if self.tab.OT.nPercentage ~= nPercentage then
        self.tab.OT.nPercentage = nPercentage
        self:DrawOTBar(rgba)
    end
    return self
end
function XLifeBar.X:DrawOTBar(rgba)
    local cfgOTBar, r,g,b,a,f
    if IsPlayer(self.self.dwID) then
        cfgOTBar   = Config.bShowOTBar.Player[self.force]
        r,g,b      = unpack(Config.Col.Player[self.force])
    else
        cfgOTBar   = Config.bShowOTBar.Npc[self.force]
        r,g,b      = unpack(Config.Col.Npc[self.force])
    end
    a, f = Config.nAlpha, Config.nFont
    if rgba then r,g,b,a,p = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
    r,g,b,a = self:FxColor(r,g,b,a)
    if cfgOTBar then
        self.hp:DrawOTBar(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetY, {r,g,b,a,self.tab.OT.nPercentage})
    end
    return self
end
function XLifeBar.X:DrawOTBarBorder(nAlpha)
    nAlpha = nAlpha or Config.nAlpha
    if IsPlayer(self.self.dwID) then
        cfgOTBar   = Config.bShowOTBar.Player[self.force]
    else
        cfgOTBar   = Config.bShowOTBar.Npc[self.force]
    end
    if cfgOTBar then
        self.hp:DrawOTBarBorder(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetY, nAlpha)
    end
    return self
end
-- 开始读条
function XLifeBar.X:StartOTBar(szOTTitle, nFrameCount, bIsChannelSkill)
    local tab = _XLifeBar.tObject[self.self.dwID]
    tab.OT = {
        nState = ( bIsChannelSkill and OT_STATE.START_CHANNEL ) or OT_STATE.START_PREPARE,
        szTitle = szOTTitle,
        nStartFrame = GetLogicFrameCount(),
        nFrameCount = nFrameCount,
    }
    return self
end

function XLifeBar.OnFrameCreate()
    if JH and JH.GetShadowHandle then
        _XLifeBar.Handle = JH.GetShadowHandle("XLifeBar")
    else
        _XLifeBar.Handle = this
    end
end

local m_fnOnSystemHeadSettingSure = function()
    -- 保存官方头顶设置
    local hFrame = this:GetRoot()
    local hWnd = hFrame:Lookup('Wnd_Display')
    if hWnd then
        local tSysHeadTop = {
            ['GLOBAL_HEAD_NPC_NAME'          ] = hWnd:Lookup('CheckBox_NN'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_NPC_TITLE'         ] = hWnd:Lookup('CheckBox_NT'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_NPC_LEFE'          ] = hWnd:Lookup('CheckBox_NB'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_OTHERPLAYER_NAME'  ] = hWnd:Lookup('CheckBox_PN'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_OTHERPLAYER_TITLE' ] = hWnd:Lookup('CheckBox_PT'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_OTHERPLAYER_LEFE'  ] = hWnd:Lookup('CheckBox_PB'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_OTHERPLAYER_GUILD' ] = hWnd:Lookup('CheckBox_ShowOtherGuild'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_CLIENTPLAYER_NAME' ] = hWnd:Lookup('CheckBox_SN'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_CLIENTPLAYER_TITLE'] = hWnd:Lookup('CheckBox_ST'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_CLIENTPLAYER_LEFE' ] = hWnd:Lookup('CheckBox_SB'):IsCheckBoxChecked(),
            ['GLOBAL_HEAD_CLIENTPLAYER_GUILD'] = hWnd:Lookup('CheckBox_ShowSelfGuild'):IsCheckBoxChecked(),
        }
        local bSave
        for _, bOn in pairs(tSysHeadTop) do
            if bOn then
                bSave = true
                break
            end
        end
        if bSave then
            XLifeBar.tSysHeadTop = tSysHeadTop
        end
    end
end

local _nDisX, _nDisY
local CheckInvalidRect
CheckInvalidRect = function(dwType, dwID, me, bNoCreate)
    local object, info = MY.GetObject(dwType, dwID)
    if not object then
        return
    end
    _nDisX, _nDisY = me.nX - object.nX, me.nY - object.nY
    if _nDisX * _nDisX + _nDisY * _nDisY < Config.nDistance
    --[[ 这是镜头补偿判断 但是不好用先不加 and (fPitch > -0.8 or _XLifeBar.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)]]
    then
        if _XLifeBar.tObject[dwID] and _XLifeBar.tObject[dwID].handle then
            local tab = _XLifeBar.tObject[dwID]
            local xlb = XLifeBar(object)
            -- 基本属性设置
            xlb:SetLife(info.nCurrentLife / info.nMaxLife)
               :SetTong(_XLifeBar.GetTongName(object.dwTongID, "[%s]"))
               :SetTitle(object.szTitle)
               :SetName(MY.Game.GetObjectName(object))
            if me.bFightState ~= _XLifeBar.bFightState then
                xlb:DrawLife()
            end
            -- 读条判定
            local nState = xlb:GetOTState()
            if nState ~= OT_STATE.ON_SKILL then
                _XLifeBar.WithPrepareState(object, function(bIsPrepare, dwSkillID, dwSkillLevel, fProgress, xlb)
                    if bIsPrepare then
                        xlb:SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel)):DrawOTTitle():SetOTPercentage(fProgress):SetOTState(OT_STATE.START_SKILL)
                    end
                end, xlb)
            end
            if nState == OT_STATE.START_SKILL then                              -- 技能读条开始
                xlb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(0):SetOTState(OT_STATE.ON_SKILL)
            elseif nState == OT_STATE.ON_SKILL then                             -- 技能读条中
                _XLifeBar.WithPrepareState(object, function(bIsPrepare, dwSkillID, dwSkillLevel, fProgress, xlb)
                    if bIsPrepare then
                        xlb:SetOTPercentage(fProgress):SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel))
                    else
                        xlb:SetOTPercentage(1):SetOTState(OT_STATE.SUCCEED)
                    end
                end, xlb)
            elseif nState == OT_STATE.START_PREPARE then                        -- 读条开始
                xlb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(0):SetOTState(OT_STATE.ON_PREPARE):DrawOTTitle()
            elseif nState == OT_STATE.ON_PREPARE then                           -- 读条中
                if not object.GetOTActionState or object.GetOTActionState() == 0 then    -- 为0 说明没有读条
                    xlb:SetOTPercentage(1):SetOTState(OT_STATE.SUCCEED)
                else
                    xlb:SetOTPercentage(( GetLogicFrameCount() - tab.OT.nStartFrame ) / tab.OT.nFrameCount)
                end
            elseif nState == OT_STATE.START_CHANNEL then                        -- 逆读条开始
                xlb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(1):SetOTState(OT_STATE.ON_CHANNEL):DrawOTTitle()
            elseif nState == OT_STATE.ON_CHANNEL then                           -- 逆读条中
                local nPercentage = 1 - ( GetLogicFrameCount() - tab.OT.nStartFrame ) / tab.OT.nFrameCount
                if object.GetOTActionState and
                object.GetOTActionState() == 2 and -- 为2 说明在读条引导保护 计算当前帧进度
                nPercentage >= 0 then
                    xlb:SetOTPercentage(nPercentage):DrawOTTitle()
                else
                    xlb:SetOTPercentage(0):SetOTState(OT_STATE.SUCCEED)
                end
            elseif nState == OT_STATE.SUCCEED then                              -- 读条成功
                if GetLogicFrameCount() - tab.OT.nStartFrame < 16 then -- 渐变
                    local rgba = { nil,nil,nil, Config.nAlpha - (GetLogicFrameCount() - tab.OT.nStartFrame) * (Config.nAlpha/16) }
                    xlb:DrawOTBarBorder(rgba[4]):DrawOTBar(rgba):DrawOTTitle(rgba)
                else
                    local rgba = { nil,nil,nil, 0 }
                    xlb:SetOTTitle("", rgba):SetOTState(OT_STATE.IDLE):DrawOTBarBorder(0):DrawOTBar(rgba)
                end
            elseif nState == OT_STATE.BREAK then                                -- 读条打断
                if GetLogicFrameCount() - tab.OT.nStartFrame < 16 then -- 渐变
                    local rgba = { 255,0,0, Config.nAlpha - (GetLogicFrameCount() - tab.OT.nStartFrame) * (Config.nAlpha/16) }
                    xlb:DrawOTBarBorder(rgba[4]):DrawOTBar(rgba):DrawOTTitle(rgba)
                else
                    xlb:SetOTTitle(""):SetOTState(OT_STATE.IDLE):DrawOTBarBorder(0):DrawOTBar({nil,nil,nil,0})
                end
            end
            
            -- 势力切换
            local szForce = _XLifeBar.GetForce(dwID)
            if szForce ~= tab.szForce then
                XLifeBar(object):Remove():Create()
                CheckInvalidRect(dwType, dwID, me, true)
            end
        elseif not bNoCreate then
            if dwType == TARGET.PLAYER or object.CanSeeName() or Config.bShowSpecialNpc then
                XLifeBar(object):Create()
                CheckInvalidRect(dwType, dwID, me, true)
            end
        end
    elseif _XLifeBar.tObject[dwID] then
        XLifeBar(object):Remove()
    end
end

function XLifeBar.OnFrameBreathe()
    -- HOOK官方头顶设置面板确认按钮
    local hFrame = Station.Lookup('Topmost/UISettingPanel')
    if hFrame and not hFrame.bHookedByXLifeBar then
        local hBtn = hFrame:Lookup('Btn_Sure')
        if hBtn and not hBtn.OnLButtonDown then
            hBtn.OnLButtonDown = m_fnOnSystemHeadSettingSure
        end
        local hBtn = hFrame:Lookup('Btn_Apply')
        if hBtn and not hBtn.OnLButtonDown then
            hBtn.OnLButtonDown = m_fnOnSystemHeadSettingSure
        end
        hFrame.bHookedByXLifeBar = true
    end
    
    if not XLifeBar.bEnabled then
        return
    end
    local me = GetClientPlayer()
    if not me then
        return
    end
    
    -- local _, _, fPitch = Camera_GetRTParams()
    for k , v in pairs(_XLifeBar.tNpc) do
        CheckInvalidRect(TARGET.NPC, k, me)
    end
    
    for k , v in pairs(_XLifeBar.tPlayer) do
        CheckInvalidRect(TARGET.PLAYER, k, me)
    end
    
    if me.bFightState ~= _XLifeBar.bFightState then
        _XLifeBar.bFightState = me.bFightState
    end
end

-- -- event
-- MY.RegisterEvent("SYS_MSG", function()
--     if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
--         Output(arg1, arg4, arg5, arg0, "UI_OME_SKILL_HIT_LOG")
--     elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
--         Output(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ,arg11, arg12, arg13, GetPlayer(arg1).szName, GetSkill(arg5, arg6).szSkillName)
--     end
-- end)
-- 逆读条事件响应
MY.RegisterEvent("DO_SKILL_CAST", function()
    local dwID, dwSkillID = arg0, arg1
    local skill = GetSkill(arg1, 1)
    if skill.bIsChannelSkill then
        local tab = _XLifeBar.tObject[dwID]
        local nFrame = MY.Player.GetChannelSkillFrame(dwSkillID) or 0
        local object = MY.Game.GetObject(dwID)
        if object then
            XLifeBar(object):StartOTBar(skill.szSkillName, nFrame, true)
        end
    end
end)
-- 读条打断事件响应
MY.RegisterEvent("OT_ACTION_PROGRESS_BREAK", function()
    if _XLifeBar.tObject[arg0] then
        local object = MY.Game.GetObject(arg0)
        if object then
            XLifeBar(object):SetOTState(OT_STATE.BREAK)
        end
    end
end)
-- MY.RegisterEvent("OT_ACTION_PROGRESS", function()Output("OT_ACTION_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("OT_ACTION_PROGRESS_UPDATE", function()Output("OT_ACTION_PROGRESS_UPDATE",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_PREPARE_PROGRESS", function()Output("DO_SKILL_PREPARE_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_CHANNEL_PROGRESS", function()Output("DO_SKILL_CHANNEL_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_HOARD_PROGRESS", function()Output("DO_SKILL_HOARD_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- 拾取事件响应
MY.RegisterEvent("DO_PICK_PREPARE_PROGRESS", function()
    local dooadad = GetDoodad(arg1)
    local szName = dooadad.szName
    if szName=="" then
        szName = GetDoodadTemplate(dooadad.dwTemplateID).szName
    end
    XLifeBar(GetClientPlayer()):StartOTBar(szName, arg0, false)
end)
-- MY.RegisterEvent("DO_CUSTOM_OTACTION_PROGRESS ", function()Output("DO_CUSTOM_OTACTION_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_RECIPE_PREPARE_PROGRESS", function()Output("DO_RECIPE_PREPARE_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("ON_SKILL_CHANNEL_PROGRESS ", function()Output("ON_SKILL_CHANNEL_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)

RegisterEvent("NPC_ENTER_SCENE",function()
    _XLifeBar.tNpc[arg0] = true
end)

RegisterEvent("NPC_LEAVE_SCENE",function()
    _XLifeBar.tNpc[arg0] = nil
    local object = GetNpc(arg0)
    if object then
        XLifeBar(object):Remove()
    end
end)

RegisterEvent("PLAYER_ENTER_SCENE",function()
    _XLifeBar.tPlayer[arg0] = true
end)

RegisterEvent("PLAYER_LEAVE_SCENE",function()
    _XLifeBar.tPlayer[arg0] = nil
    local object = GetPlayer(arg0)
    if object then
        XLifeBar(object):Remove()
    end
end)

RegisterEvent("UPDATE_SELECT_TARGET",function()
    local dwID, _ = Target_GetTargetData()
    if _XLifeBar.dwTargetID == dwID then
        return
    end
    local dwOldTargetID = _XLifeBar.dwTargetID
    _XLifeBar.dwTargetID = dwID
    if _XLifeBar.tObject[dwOldTargetID] then
        local object = MY.Game.GetObject(dwOldTargetID)
        if object then
            XLifeBar(object):DrawNames():DrawLife()
        end
    end
    if _XLifeBar.tObject[dwID] then
        local object = MY.Game.GetObject(dwID)
        if object then
            XLifeBar(object):DrawNames():DrawLife()
        end
    end
end)

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    local x, y = 10, 10
    local offsety = 40
    local fnLoadUI = function(ui)
        ui:children("#WndSliderBox_LifebarWidth"):value(Config.nLifeWidth)
        ui:children("#WndSliderBox_LifebarHeight"):value(Config.nLifeHeight)
        ui:children("#WndSliderBox_LifeHeight"):value(Config.nLifeOffsetY)
        ui:children("#WndSliderBox_OTbarWidth"):value(Config.nOTBarWidth)
        ui:children("#WndSliderBox_OTbarHeight"):value(Config.nOTBarHeight)
        ui:children("#WndSliderBox_OTHeight"):value(Config.nOTBarOffsetY)
        ui:children("#WndSliderBox_FristHeight"):value(Config.nLineHeight[1])
        ui:children("#WndSliderBox_SecondHeight"):value(Config.nLineHeight[2])
        ui:children("#WndSliderBox_ThirdHeight"):value(Config.nLineHeight[3])
        ui:children("#WndSliderBox_PerHeight"):value(Config.nPerHeight)
        ui:children("#WndSliderBox_Distance"):value(math.sqrt(Config.nDistance) / 64)
        ui:children("#WndSliderBox_Alpha"):value(Config.nAlpha)
        ui:children("#WndCheckBox_ShowSpecialNpc"):check(Config.bShowSpecialNpc)
        ui:children("#WndButton_Font"):text(_L("Font: %d",Config.nFont))
    end
    -- 开启/关闭
    ui:append("WndCheckBox", "WndCheckBox_Switcher"):children("#WndCheckBox_Switcher")
      :pos(x,y):text(_L["enable/disable"])
      :check(XLifeBar.bEnabled or false)
      :check(function(bChecked) XLifeBar.bEnabled = bChecked _XLifeBar.Reset(true) end)
    -- 使用所有角色公共设置
    ui:append("WndCheckBox", "WndCheckBox_GlobalConfig"):children("#WndCheckBox_GlobalConfig")
      :width(180):pos(x + 110, y):text(_L["use global config"])
      :check(XLifeBar.bUseGlobalConfig or false)
      :check(function(bChecked)
        XLifeBar.bUseGlobalConfig = bChecked
        _XLifeBar.Reload()
        fnLoadUI(ui)
      end)
    y = y + offsety
    -- <hr />
    ui:append("Image", "Image_Spliter"):find('#Image_Spliter'):pos(x,y-7):size(w-x*2,2):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)
    
    x, y = 10, 60
    offsety = 27
    ui:append("WndSliderBox", "WndSliderBox_LifebarWidth"):children("#WndSliderBox_LifebarWidth")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("lifebar width: %s px.", value) end)--血条长度
      :value(Config.nLifeWidth or Config_Default.nLifeWidth)
      :change(function(value) Config.nLifeWidth = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_LifebarHeight"):children("#WndSliderBox_LifebarHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("lifebar height: %s px.", value) end)--血条高度
      :value(Config.nLifeHeight or Config_Default.nLifeHeight)
      :change(function(value) Config.nLifeHeight = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_LifeHeight"):children("#WndSliderBox_LifeHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("lifebar offset-y: %d px.", value) end)--血条高度偏移
      :value(Config.nLifeOffsetY or Config_Default.nLifeOffsetY)
      :change(function(value) Config.nLifeOffsetY = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_PerHeight"):children("#WndSliderBox_PerHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("percentage offset-y: %d px.", value) end)--百分比高度
      :value(Config.nPerHeight or Config_Default.nPerHeight)
      :change(function(value) Config.nPerHeight = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_OTBarWidth"):children("#WndSliderBox_OTBarWidth")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("otbar width: %s px.", value) end)--OT长度
      :value(Config.nOTBarWidth or Config_Default.nOTBarWidth)
      :change(function(value) Config.nOTBarWidth = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_OTBarHeight"):children("#WndSliderBox_OTBarHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("otbar height: %s px.", value) end)--OT高度
      :value(Config.nOTBarHeight or Config_Default.nOTBarHeight)
      :change(function(value) Config.nOTBarHeight = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_OTHeight"):children("#WndSliderBox_OTHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("otbar offset-y: %d px.", value) end)--OT高度偏移
      :value(Config.nOTBarOffsetY or Config_Default.nOTBarOffsetY)
      :change(function(value) Config.nOTBarOffsetY = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_OTTitleHeight"):children("#WndSliderBox_OTTitleHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("ot title offset-y: %d px.", value) end)--OT名称高度
      :value(Config.nOTTitleHeight or Config_Default.nOTTitleHeight)
      :change(function(value) Config.nOTTitleHeight = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_FristHeight"):children("#WndSliderBox_FristHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("1st line offset-y: %d px.", value) end)--第一行字高度
      :value(Config.nLineHeight[1] or Config_Default.nLineHeight[1])
      :change(function(value) Config.nLineHeight[1] = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_SecondHeight"):children("#WndSliderBox_SecondHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("2nd line offset-y: %d px.", value) end)--第二行字高度
      :value(Config.nLineHeight[2] or Config_Default.nLineHeight[2])
      :change(function(value) Config.nLineHeight[2] = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_ThirdHeight"):children("#WndSliderBox_ThirdHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("3rd line offset-y: %d px.", value) end)--第三行字高度
      :value(Config.nLineHeight[3] or Config_Default.nLineHeight[3])
      :change(function(value) Config.nLineHeight[3] = value;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_Distance"):children("#WndSliderBox_Distance")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,300)
      :text(function(value) return _L("Max Distance: %s foot.", value) end)
      :value(math.sqrt(Config.nDistance or Config_Default.nDistance) / 64)
      :change(function(value) Config.nDistance = value * value * 64 * 64;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndSliderBox", "WndSliderBox_Alpha"):children("#WndSliderBox_Alpha")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_PERCENT):range(0,255)
      :text(function(value) return _L("alpha: %.0f%%.", value) end)--透明度
      :value(Config.nAlpha or Config_Default.nAlpha)
      :change(function(value) Config.nAlpha = value*255/100;_XLifeBar.Reset() end)
    y = y + offsety
    
    -- 右半边
    x, y = 350, 60
    offsety = 34
    -- 显示名字
    ui:append("WndComboBox", "WndComboBox_Name"):children("#WndComboBox_Name")
      :pos(x,y):text(_L["name display config"])
      :menu(function()
        local t = {}
        table.insert(t,{    szOption = _L["player name display"] , bDisable = true} )
        for k,v in pairs(Config.bShowName.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowName.Player[k],
                fnAction = function() 
                    Config.bShowName.Player[k] = not Config.bShowName.Player[k]
                    _XLifeBar.Reset()
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["npc name display"] , bDisable = true} )
        for k,v in pairs(Config.bShowName.Npc) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowName.Npc[k],
                fnAction = function() 
                    Config.bShowName.Npc[k] = not Config.bShowName.Npc[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Npc[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Npc[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        return t
      end)
    y = y + offsety

    -- 称号
    ui:append("WndComboBox", "WndComboBox_Title"):children("#WndComboBox_Title")
      :pos(x,y):text(_L["title display config"])
      :menu(function()
        local t = {}
        table.insert(t,{    szOption = _L["player title display"] , bDisable = true} )
        for k,v in pairs(Config.bShowTitle.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowTitle.Player[k],
                fnAction = function() 
                    Config.bShowTitle.Player[k] = not Config.bShowTitle.Player[k];
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["npc title display"] , bDisable = true} )
        for k,v in pairs(Config.bShowTitle.Npc) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowTitle.Npc[k],
                fnAction = function() 
                    Config.bShowTitle.Npc[k] = not Config.bShowTitle.Npc[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Npc[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Npc[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        return t
      end)
    y = y + offsety
    
    -- 帮会
    ui:append("WndComboBox", "WndComboBox_Tong"):children("#WndComboBox_Tong")
      :pos(x,y):text(_L["tong display config"])
      :menu(function()
        local t = {}
        table.insert(t,{    szOption = _L["player tong display"] , bDisable = true} )
        for k,v in pairs(Config.bShowTong.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowTong.Player[k],
                fnAction = function() 
                    Config.bShowTong.Player[k] = not Config.bShowTong.Player[k];
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        return t
      end)
    y = y + offsety
      
    -- 血条设置
    ui:append("WndComboBox", "WndComboBox_Lifebar"):children("#WndComboBox_Lifebar")
      :pos(x,y):text(_L["lifebar display config"])
      :menu(function()
        local t = {}
        table.insert(t,{    szOption = _L["player lifebar display"] , bDisable = true} )
        for k,v in pairs(Config.bShowLife.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowLife.Player[k],
                fnAction = function() 
                    Config.bShowLife.Player[k] = not Config.bShowLife.Player[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["npc lifebar display"] , bDisable = true} )
        for k,v in pairs(Config.bShowLife.Npc) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowLife.Npc[k],
                fnAction = function() 
                    Config.bShowLife.Npc[k] = not Config.bShowLife.Npc[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Npc[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Npc[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        return t
      end)
    y = y + offsety
    
    -- 显示血量%
    ui:append("WndComboBox", "WndComboBox_LifePercentage"):children("#WndComboBox_LifePercentage")
      :pos(x,y):text(_L["lifepercentage display config"])
      :menu(function()
        local t = {}
        table.insert(t,{    szOption = _L["player lifepercentage display"] , bDisable = true} )
        for k,v in pairs(Config.bShowLifePer.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowLifePer.Player[k],
                fnAction = function() 
                    Config.bShowLifePer.Player[k] = not Config.bShowLifePer.Player[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["npc lifepercentage display"] , bDisable = true} )
        for k,v in pairs(Config.bShowLifePer.Npc) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowLifePer.Npc[k],
                fnAction = function() 
                    Config.bShowLifePer.Npc[k] = not Config.bShowLifePer.Npc[k];
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Npc[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Npc[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{
            szOption = _L['hide when unfight'], 
            bCheck = true, 
            bChecked = Config.bHideLifePercentageWhenFight,
            fnAction = function() 
                Config.bHideLifePercentageWhenFight = not Config.bHideLifePercentageWhenFight;
                _XLifeBar.Reset() 
            end,
        })
        table.insert(t,{
            szOption = _L['hide decimal'], 
            bCheck = true, 
            bChecked = Config.bHideLifePercentageDecimal,
            fnAction = function() 
                Config.bHideLifePercentageDecimal = not Config.bHideLifePercentageDecimal;
                _XLifeBar.Reset() 
            end,
        })
        return t
      end)
    y = y + offsety
    
    -- 显示读条%
    ui:append("WndComboBox", "WndComboBox_SkillPercentage"):children("#WndComboBox_SkillPercentage")
      :pos(x,y):text(_L["skillpercentage display config"])
      :menu(function()
        local t = {}
        table.insert(t,{
            szOption = _L['enhanced mod'], 
            bCheck = true, 
            bChecked = Config.bOTEnhancedMod,
            fnAction = function() 
                Config.bOTEnhancedMod = not Config.bOTEnhancedMod
                _XLifeBar.Reset() 
            end,
            fnMouseEnter = function()
                local szText="<text>text=" .. EncodeComponentsString(_L['Check this option may cause target switch.']) .." font=16 </text>"
                local x, y = this:GetAbsPos()
                local w, h = this:GetSize()
                OutputTip(szText, 100, {x, y, w, h}, MY.Const.UI.Tip.POS_RIGHT)
            end,
        })
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["player skillpercentage display"] , bDisable = true} )
        for k,v in pairs(Config.bShowOTBar.Player) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowOTBar.Player[k],
                fnAction = function() 
                    Config.bShowOTBar.Player[k] = not Config.bShowOTBar.Player[k]
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Player[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Player[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        table.insert(t,{    bDevide = true} )
        table.insert(t,{    szOption = _L["npc skillpercentage display"] , bDisable = true} )
        for k,v in pairs(Config.bShowOTBar.Npc) do
            table.insert(t,{
                szOption = _L[k], 
                bCheck = true, 
                bChecked = Config.bShowOTBar.Npc[k],
                fnAction = function() 
                    Config.bShowOTBar.Npc[k] = not Config.bShowOTBar.Npc[k];
                    _XLifeBar.Reset() 
                end,
                rgb = Config.Col.Npc[k],
                bColorTable = true,
                fnChangeColor = function(_,r,g,b)
                    Config.Col.Npc[k] = {r,g,b}
                    _XLifeBar.Reset()
                end
            })
        end
        return t
      end)
    y = y + offsety
    
    -- 当前阵营
    ui:append("WndComboBox", "WndComboBox_CampSwitch"):children("#WndComboBox_CampSwitch")
      :pos(x,y):text(_L["set current camp"])
      :menu(function()
        return {{
            szOption = _L['auto detect'],
            bCheck = true, bMCheck = true,
            bChecked = Config.nCamp == -1,
            fnAction = function()
                Config.nCamp = -1
                _XLifeBar.Reset()
            end,
        }, {
            szOption = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD],
            bCheck = true, bMCheck = true,
            bChecked = Config.nCamp == CAMP.GOOD,
            fnAction = function()
                Config.nCamp = CAMP.GOOD
                _XLifeBar.Reset()
            end,
        }, {
            szOption = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL],
            bCheck = true, bMCheck = true,
            bChecked = Config.nCamp == CAMP.EVIL,
            fnAction = function()
                Config.nCamp = CAMP.EVIL
                _XLifeBar.Reset()
            end,
        }, {
            szOption = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL],
            bCheck = true, bMCheck = true,
            bChecked = Config.nCamp == CAMP.NEUTRAL,
            fnAction = function()
                Config.nCamp = CAMP.NEUTRAL
                _XLifeBar.Reset()
            end,
        }}
      end)
    y = y + offsety
    offsety = 37
    
    ui:append("WndCheckBox", "WndCheckBox_ShowSpecialNpc"):children("#WndCheckBox_ShowSpecialNpc")
      :pos(x,y):text(_L['show special npc'])
      :check(Config.bShowSpecialNpc or false)
      :check(function(bChecked) Config.bShowSpecialNpc = bChecked;_XLifeBar.Reset() end)
    y = y + offsety - 10
      
    ui:append("WndCheckBox", "WndCheckBox_AdjustIndex"):children("#WndCheckBox_AdjustIndex")
      :pos(x, y):text(_L['adjust index'])
      :check(Config.bAdjustIndex or false)
      :check(function(bChecked) Config.bAdjustIndex = bChecked;_XLifeBar.Reset() end)
    y = y + offsety
    
    ui:append("WndButton", "WndButton_Font"):children("#WndButton_Font")
      :pos(x,y):text(_L("Font: %d",Config.nFont))
      :click(function()
        MY.UI.OpenFontPicker(function(nFont)
            Config.nFont = nFont;_XLifeBar.Reset()
            ui:children("#WndButton_Font"):text(_L("Font: %d",Config.nFont))
        end)
      end)
    y = y + offsety - 10
    
    ui:append("WndButton", "WndButton_Reset"):children("#WndButton_Reset")
      :pos(x,y):width(120):text(_L['reset config'])
      :click(function()
        MessageBox({
            szName = "XLifeBar_Reset",
            szMessage = _L['Are you sure to reset config?'], {
                szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
                    Config = clone(Config_Default)
                    _XLifeBar.Reset()
                    fnLoadUI(ui)
                end
            }, {szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
        })
      end)
    y = y + offsety
end
MY.RegisterPanel( "XLifeBar", _L["x lifebar"], _L['General'], "UI/Image/LootPanel/LootPanel.UITex|74", {255,127,0,200}, { OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = nil } )
