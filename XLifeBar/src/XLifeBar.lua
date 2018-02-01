local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."XLifeBar/lang/")
local D = {}
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

local Config_Default = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "XLifeBar/config/default.jx3dat")
if not Config_Default then
    return MY.Debug({_L["Default config cannot be loaded, please reinstall!!!"]}, _L["x lifebar"], MY_DEBUG.ERROR)
end
local Config = clone(Config_Default)

local function GetConfig(key, relation, force)
    local cfg, value = Config[key][relation]
    if force == 'Npc' or force == 'Player' then
        value = cfg[force]
    else
        if cfg.DifferentiateForce then
            value = cfg[force]
        end
        if value == nil then
            value = Config[key][relation]["Player"]
        end
    end
    return value
end

XLifeBar = XLifeBar or {}
setmetatable(XLifeBar, { __call = function(me, ...) return me.X.new(...) end, __metatable = true })
XLifeBar.bEnabled = false
XLifeBar.bUseGlobalConfig   = false
XLifeBar.bOnlyInDungeon     = false
XLifeBar.bOnlyInArena       = false
XLifeBar.bOnlyInBattleField = false
RegisterCustomData("XLifeBar.bEnabled")
RegisterCustomData("XLifeBar.bUseGlobalConfig")
RegisterCustomData("XLifeBar.bOnlyInDungeon")
RegisterCustomData("XLifeBar.bOnlyInArena")
RegisterCustomData("XLifeBar.bOnlyInBattleField")

local function IsShielded() return MY.IsShieldedVersion() and MY.IsInPubg() end
local function IsEnabled() return XLifeBar.bEnabled and not IsShielded() end
local function IsMapEnabled()
    return IsEnabled() and (
        not (
            XLifeBar.bOnlyInDungeon or
            XLifeBar.bOnlyInArena or
            XLifeBar.bOnlyInBattleField
        ) or (
            (XLifeBar.bOnlyInDungeon     and MY.IsInDungeon(true)) or
            (XLifeBar.bOnlyInArena       and MY.IsInArena()) or
            (XLifeBar.bOnlyInBattleField and (MY.IsInBattleField() or MY.IsInPubg()))
        )
    )
end

local CONFIG_PATH = "config/xlifebar.jx3dat"
local OBJECT_INFO_CACHE = {}
local TONG_NAME_CACHE = {}
local NPC_CACHE = {}
local PLAYER_CACHE = {}
local TARGET_ID = 0
local LAST_FIGHT_STATE = false
local SYS_HEAD_TOP_STATE
local HP = XLifeBar.HP

function D.GetNz(nZ,nZ2)
    return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

function D.LoadConfig()
    if XLifeBar.bUseGlobalConfig then
    	local szOrgFile = MY.GetLUADataPath("userdata/XLifeBar/cfg.$lang.jx3dat")
    	local szFilePath = MY.GetLUADataPath({ CONFIG_PATH, MY_DATA_PATH.GLOBAL })
    	if IsLocalFileExist(szOrgFile) then
    		CPath.Move(szOrgFile, szFilePath)
    	end
        Config = MY.LoadLUAData(szFilePath)
    else
    	local szOrgFile = MY.GetLUADataPath("userdata/XLifeBar/cfg_$uid.$lang.jx3dat")
    	local szFilePath = MY.GetLUADataPath({ CONFIG_PATH, MY_DATA_PATH.ROLE })
    	if IsLocalFileExist(szOrgFile) then
    		CPath.Move(szOrgFile, szFilePath)
    	end
        Config = MY.LoadLUAData(szFilePath)
    end
    Config = MY.FormatDataStructure(Config, Config_Default, true)
end

function D.SaveConfig()
    MY.SaveLUAData({
        CONFIG_PATH,
        XLifeBar.bUseGlobalConfig
            and MY_DATA_PATH.GLOBAL
            or MY_DATA_PATH.ROLE
    }, Config)
end
MY.RegisterExit(D.SaveConfig)

function D.GetRelation(dwID)
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
            local r, g, b = GetHeadTextForceFontColor(dwID, me.dwID) -- 我看他的颜色
            if MY.GetFoe(dwID) then
                return "Foe"
            elseif r == 255 and g == 255 and b == 0 then
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
        elseif MY.GetFoe(dwID) then
            return "Foe"
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

function D.GetForce(dwID)
    if not IsPlayer(dwID) then
        return "Npc"
    else
        local tar = MY.GetObject(TARGET.PLAYER, dwID)
        if not tar then
            return 0
        else
            return tar.dwForceID
        end
    end
end

function D.GetTongName(dwTongID, szFormatString)
    szFormatString = szFormatString or "%s"
    if type(dwTongID) ~= 'number' or dwTongID == 0 then
        return nil
    end
    if not TONG_NAME_CACHE[dwTongID] then
        TONG_NAME_CACHE[dwTongID] = GetTongClient().ApplyGetTongName(dwTongID)
    end
    if TONG_NAME_CACHE[dwTongID] then
        return string.format(szFormatString, TONG_NAME_CACHE[dwTongID])
    end
end

function D.AutoSwitchSysHeadTop()
    if IsMapEnabled() then
        D.SaveSysHeadTop()
        D.HideSysHeadTop()
    else
        D.ResumeSysHeadTop()
    end
end
function D.HideSysHeadTop()
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_NAME , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_TITLE, false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_LIFE , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_NAME , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_TITLE, false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_LIFE , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_GUILD, false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE , false)
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, false)
end
function D.SaveSysHeadTop()
    if SYS_HEAD_TOP_STATE then
        return
    end
    SYS_HEAD_TOP_STATE = {
        ['GLOBAL_HEAD_NPC_NAME'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME ),
        ['GLOBAL_HEAD_NPC_TITLE'         ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE),
        ['GLOBAL_HEAD_NPC_LEFE'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE ),
        ['GLOBAL_HEAD_OTHERPLAYER_NAME'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME ),
        ['GLOBAL_HEAD_OTHERPLAYER_TITLE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE),
        ['GLOBAL_HEAD_OTHERPLAYER_LEFE'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE ),
        ['GLOBAL_HEAD_OTHERPLAYER_GUILD' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD),
        ['GLOBAL_HEAD_CLIENTPLAYER_NAME' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME ),
        ['GLOBAL_HEAD_CLIENTPLAYER_TITLE'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE),
        ['GLOBAL_HEAD_CLIENTPLAYER_LEFE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE ),
        ['GLOBAL_HEAD_CLIENTPLAYER_GUILD'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD),
    }
end
function D.ResumeSysHeadTop()
    if not SYS_HEAD_TOP_STATE then
        return
    end
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_NAME'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_TITLE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_LEFE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_NAME'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_TITLE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_LEFE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_GUILD'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_NAME'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_TITLE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_LEFE'])
    SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_GUILD'])
    SYS_HEAD_TOP_STATE = nil
end
MY.RegisterExit(D.ResumeSysHeadTop)

-- 重绘所有UI
function D.Reset()
    OBJECT_INFO_CACHE = {}
    XGUI.GetShadowHandle("XLifeBar"):Clear()
    -- auto adjust index
    MY.BreatheCall("XLifeBar_AdjustIndex")
    if Config.bAdjustIndex then
        MY.BreatheCall("XLifeBar_AdjustIndex", function()
            local n = 0
            local t = {}
            -- refresh current index data
            for dwID, tab in pairs(OBJECT_INFO_CACHE) do
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

    D.AutoSwitchSysHeadTop()
end
-- 加载界面
MY.RegisterEvent('LOGIN_GAME', function() MY.UI.CreateFrame("XLifeBar", { level = "Lowest", empty = true }) end)
-- 重载配置文件并重绘
MY.RegisterEvent('FIRST_LOADING_END', function() D.LoadConfig() D.Reset() end)
-- 过图可能切换开关状态
MY.RegisterEvent('LOADING_END', D.AutoSwitchSysHeadTop)

XLifeBar.X = class()
-- 构造函数
function XLifeBar.X:ctor(object)
    if not OBJECT_INFO_CACHE[object.dwID] then
        OBJECT_INFO_CACHE[object.dwID] = {
            handle  = nil,
            szName  = '' ,
            szTong  = '' ,
            szTitle = '' ,
            fLife   = -1 ,
            szForce = D.GetForce(object.dwID),
            szRelation = D.GetRelation(object.dwID),
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
    self.tab = OBJECT_INFO_CACHE[object.dwID]
    self.force = self.tab.szForce
    self.relation = self.tab.szRelation
    self.hp = HP.new(object.dwID)
    return self
end
-- 创建UI
function XLifeBar.X:Create()
    if not self.hp.handle then
        -- 创建UI
        self.hp:Create()
        -- handle写回缓存 防止二次Create()
        OBJECT_INFO_CACHE[self.self.dwID].handle = self.hp.handle
        -- 开始绘制永远不会重绘的东西
        -- 绘制血条边框
        local cfgLife = GetConfig("ShowLife", self.relation, self.force)
        if cfgLife then
            self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, Config.nAlpha)
        end
    end
    return self
end
-- 删除UI
function XLifeBar.X:Remove()
    if self.hp.handle then
        self.hp:Remove()
    end
    OBJECT_INFO_CACHE[self.self.dwID] = nil
    return self
end
-- 对目标头顶颜色进行滤镜处理（高亮/死亡）
function XLifeBar.X:FxColor(r,g,b,a)
    -- 死亡判定
    if self.self.nMoveState == MOVE_STATE.ON_DEATH then
        if TARGET_ID == self.self.dwID then
            return math.ceil(r/2.2), math.ceil(g/2.2), math.ceil(b/2.2), a
        else
            return math.ceil(r/2.5), math.ceil(g/2.5), math.ceil(b/2.5), a
        end
    elseif TARGET_ID == self.self.dwID then
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
function XLifeBar.X:SetTong(szTong)
    if self.tab.szTong ~= szTong then
        self.tab.szTong = szTong
        self:DrawNames()
    end
    return self
end
-- 重绘头顶文字
function XLifeBar.X:DrawNames()
    local tWordlines = {}
    local r,g,b,a,f
    local cfgName, cfgTitle, cfgTong
    local tab = OBJECT_INFO_CACHE[self.self.dwID]
    if IsPlayer(self.self.dwID) then
        cfgLife  = GetConfig("ShowLife", self.relation, self.force)
        cfgName  = GetConfig("ShowName", self.relation, self.force)
        cfgTitle = GetConfig("ShowTitle", self.relation, self.force)
        cfgTong  = GetConfig("ShowTong", self.relation, self.force)
        r,g,b    = unpack(GetConfig("Color", self.relation, self.force))
    else
        cfgLife  = GetConfig("ShowLife", self.relation, self.force)
        cfgName  = GetConfig("ShowName", self.relation, self.force)
        cfgTitle = GetConfig("ShowTitle", self.relation, self.force)
        cfgTong  = false
        r,g,b    = unpack(GetConfig("Color", self.relation, self.force))
    end
    a,f = Config.nAlpha, Config.nFont
    r,g,b,a = self:FxColor(r,g,b,a)

    local i = #Config.nLineHeight
    if cfgTong then
        local szTong = self.tab.szTong
        if szTong and szTong ~= '' then
            table.insert(tWordlines, { szTong, Config.nLineHeight[i] })
            i = i - 1
        end
    end
    if cfgTitle then
        local szTitle = self.tab.szTitle
        if szTitle and szTitle ~= "" then
            table.insert(tWordlines, { "<" .. self.tab.szTitle .. ">", Config.nLineHeight[i] })
            i = i - 1
        end
    end
    if cfgName then
        local szName = self.tab.szName
        if szName and not tonumber(szName) then
            table.insert(tWordlines, { szName, Config.nLineHeight[i] })
            i = i - 1
        end
    end

    -- 没有名字的玩意隐藏血条
    if cfgName and #tWordlines == 0 then
        self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, 0, self.tab.fLife, Config.szLifeDirection })
        self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, 0)
    elseif cfgLife then
        self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, a, self.tab.fLife, Config.szLifeDirection })
        self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, a)
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
    local cfgLife    = GetConfig("ShowLife", self.relation, self.force)
    local cfgLifePer = GetConfig("ShowLifePer", self.relation, self.force)
    local r, g, b    = unpack(GetConfig("Color", self.relation, self.force))
    local a, f = Config.nAlpha, Config.nFont
    r, g, b, a = self:FxColor(r, g, b, a)
    if cfgLife then
        self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, a, self.tab.fLife, Config.szLifeDirection })
    end
    if cfgLifePer then
        local szFormatString = '%.1f'
        if Config.bHideLifePercentageWhenFight and not GetClientPlayer().bFightState then
            szFormatString = ''
        elseif Config.bHideLifePercentageDecimal then
            szFormatString = '%.0f'
        end
        self.hp:DrawLifePercentage({string.format(szFormatString, 100 * self.tab.fLife), Config.nLifePerOffsetX, Config.nLifePerOffsetY}, {r,g,b,a,f})
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
    local cfgOTBar = GetConfig("ShowOTBar", self.relation, self.force)
    local r, g, b  = unpack(GetConfig("Color", self.relation, self.force))
    local a, f = Config.nAlpha, Config.nFont
    if rgba then r,g,b,a = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
    r,g,b,a = self:FxColor(r,g,b,a)
    if cfgOTBar then
        self.hp:DrawOTTitle({ self.tab.OT.szTitle, Config.nOTTitleOffsetX, Config.nOTTitleOffsetY }, {r,g,b,a,f})
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
    local cfgOTBar = GetConfig("ShowOTBar", self.relation, self.force)
    local r, g, b  = unpack(GetConfig("Color", self.relation, self.force))
    local a, f = Config.nAlpha, Config.nFont
    if rgba then r,g,b,a,p = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
    r,g,b,a = self:FxColor(r,g,b,a)
    if cfgOTBar then
        self.hp:DrawOTBar(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetX, Config.nOTBarOffsetY, { r, g, b, a, self.tab.OT.nPercentage, Config.szOTBarDirection })
    end
    return self
end
function XLifeBar.X:DrawOTBarBorder(nAlpha)
    local cfgOTBar = GetConfig("ShowOTBar", self.relation, self.force)
    if cfgOTBar then
        self.hp:DrawOTBarBorder(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetX, Config.nOTBarOffsetY, nAlpha or Config.nAlpha)
    end
    return self
end
-- 开始读条
function XLifeBar.X:StartOTBar(szOTTitle, nFrameCount, bIsChannelSkill)
    local tab = OBJECT_INFO_CACHE[self.self.dwID]
    tab.OT = {
        nState = ( bIsChannelSkill and OT_STATE.START_CHANNEL ) or OT_STATE.START_PREPARE,
        szTitle = szOTTitle,
        nStartFrame = GetLogicFrameCount(),
        nFrameCount = nFrameCount,
    }
    return self
end

local _nDisX, _nDisY
local function CheckInvalidRect(dwType, dwID, me, bNoCreate)
    local object, info = MY.GetObject(dwType, dwID)
    if not object then
        return
    end
    _nDisX, _nDisY = me.nX - object.nX, me.nY - object.nY
    if Config.nDistance <= 0 or _nDisX * _nDisX + _nDisY * _nDisY < Config.nDistance
    -- 这是镜头补偿判断 但是不好用先不加 and (fPitch > -0.8 or D.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)
    then
        if OBJECT_INFO_CACHE[dwID] and OBJECT_INFO_CACHE[dwID].handle then
            local tab = OBJECT_INFO_CACHE[dwID]
            local xlb = XLifeBar(object)
            -- 基本属性设置
            xlb:SetLife(info.nCurrentLife / info.nMaxLife)
               :SetTong(D.GetTongName(object.dwTongID, "[%s]"))
               :SetTitle(object.szTitle)
            local szName = MY.Game.GetObjectName(object)
            if szName then
                if not Config.bShowDistance or dwID == me.dwID then
                    xlb:SetName(szName)
                else
                    xlb:SetName(
                        szName .. _L.STR_SPLIT_DOT
                        .. math.floor(GetCharacterDistance(me.dwID, dwID) / 64)
                        .. g_tStrings.STR_METER
                    )
                end
            end
            if me.bFightState ~= LAST_FIGHT_STATE then
                xlb:DrawLife()
            end
            -- 读条判定
            local nState = xlb:GetOTState()
            if nState ~= OT_STATE.ON_SKILL then
			    local nType, dwSkillID, dwSkillLevel, fProgress = object.GetSkillOTActionState()
                if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
                    xlb:SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel)):DrawOTTitle():SetOTPercentage(fProgress):SetOTState(OT_STATE.START_SKILL)
                end
            end
            if nState == OT_STATE.START_SKILL then                              -- 技能读条开始
                xlb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(0):SetOTState(OT_STATE.ON_SKILL)
            elseif nState == OT_STATE.ON_SKILL then                             -- 技能读条中
			    local nType, dwSkillID, dwSkillLevel, fProgress = object.GetSkillOTActionState()
                if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
                    xlb:SetOTPercentage(fProgress):SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel))
                else
                    xlb:SetOTPercentage(1):SetOTState(OT_STATE.SUCCEED)
                end
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
            local szRelation = D.GetRelation(dwID)
            if szRelation ~= tab.szRelation then
                XLifeBar(object):Remove():Create()
                CheckInvalidRect(dwType, dwID, me, true)
            end
        elseif not bNoCreate then
            if dwType == TARGET.PLAYER
            or object.CanSeeName()
            or (object.dwTemplateID == 46140 and (not MY.IsShieldedVersion() or D.GetRelation(object) ~= "Enemy")) -- 清绝歌影
            or Config.bShowSpecialNpc then
                XLifeBar(object):Create()
                CheckInvalidRect(dwType, dwID, me, true)
            end
        end
    elseif OBJECT_INFO_CACHE[dwID] then
        XLifeBar(object):Remove()
    end
end

function XLifeBar.OnFrameBreathe()
    if not IsMapEnabled() then
        return
    end
    local me = GetClientPlayer()
    if not me then
        return
    end

    -- local _, _, fPitch = Camera_GetRTParams()
    for k , v in pairs(NPC_CACHE) do
        CheckInvalidRect(TARGET.NPC, k, me)
    end

    for k , v in pairs(PLAYER_CACHE) do
        CheckInvalidRect(TARGET.PLAYER, k, me)
    end

    if me.bFightState ~= LAST_FIGHT_STATE then
        LAST_FIGHT_STATE = me.bFightState
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
        local tab = OBJECT_INFO_CACHE[dwID]
        local nFrame = MY.GetChannelSkillFrame(dwSkillID) or 0
        local object = MY.GetObject(dwID)
        if object then
            XLifeBar(object):StartOTBar(skill.szSkillName, nFrame, true)
        end
    end
end)
-- 读条打断事件响应
MY.RegisterEvent("OT_ACTION_PROGRESS_BREAK", function()
    if OBJECT_INFO_CACHE[arg0] then
        local object = MY.GetObject(arg0)
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
    NPC_CACHE[arg0] = true
end)

RegisterEvent("NPC_LEAVE_SCENE",function()
    NPC_CACHE[arg0] = nil
    local object = GetNpc(arg0)
    if object then
        XLifeBar(object):Remove()
    end
end)

RegisterEvent("PLAYER_ENTER_SCENE",function()
    PLAYER_CACHE[arg0] = true
end)

RegisterEvent("PLAYER_LEAVE_SCENE",function()
    PLAYER_CACHE[arg0] = nil
    local object = GetPlayer(arg0)
    if object then
        XLifeBar(object):Remove()
    end
end)

RegisterEvent("UPDATE_SELECT_TARGET",function()
    local _, dwID = MY.GetTarget()
    if TARGET_ID == dwID then
        return
    end
    local dwOldTargetID = TARGET_ID
    TARGET_ID = dwID
    if OBJECT_INFO_CACHE[dwOldTargetID] then
        local object = MY.Game.GetObject(dwOldTargetID)
        if object then
            XLifeBar(object):DrawNames():DrawLife()
        end
    end
    if OBJECT_INFO_CACHE[dwID] then
        local object = MY.Game.GetObject(dwID)
        if object then
            XLifeBar(object):DrawNames():DrawLife()
        end
    end
end)

local PS = {}
local function LoadUI(ui)
    ui:children("#WndSliderBox_LifeBarWidth"):value(Config.nLifeWidth)
    ui:children("#WndSliderBox_LifeBarHeight"):value(Config.nLifeHeight)
    ui:children("#WndSliderBox_LifeBarOffsetX"):value(Config.nLifeOffsetX)
    ui:children("#WndSliderBox_LifeBarOffsetY"):value(Config.nLifeOffsetY)
    ui:children("#WndSliderBox_OTBarWidth"):value(Config.nOTBarWidth)
    ui:children("#WndSliderBox_OTBarHeight"):value(Config.nOTBarHeight)
    ui:children("#WndSliderBox_OTBarOffsetX"):value(Config.nOTBarOffsetX)
    ui:children("#WndSliderBox_OTBarOffsetY"):value(Config.nOTBarOffsetY)
    ui:children("#WndSliderBox_OTTitleOffsetX"):value(Config.nOTTitleOffsetX)
    ui:children("#WndSliderBox_OTTitleOffsetY"):value(Config.nOTTitleOffsetY)
    ui:children("#WndSliderBox_FristLineHeight"):value(Config.nLineHeight[1])
    ui:children("#WndSliderBox_SecondLineHeight"):value(Config.nLineHeight[2])
    ui:children("#WndSliderBox_ThirdLineHeight"):value(Config.nLineHeight[3])
    ui:children("#WndSliderBox_LifePerOffsetX"):value(Config.nLifePerOffsetX)
    ui:children("#WndSliderBox_LifePerOffsetY"):value(Config.nLifePerOffsetY)
    ui:children("#WndSliderBox_Distance"):value(math.sqrt(Config.nDistance) / 64)
    ui:children("#WndSliderBox_Alpha"):value(Config.nAlpha)
    ui:children("#WndCheckBox_ShowSpecialNpc"):check(Config.bShowSpecialNpc)
    ui:children("#WndButton_Font"):text(_L("Font: %d", Config.nFont))
end
function PS.OnPanelActive(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()

    local x, y = 10, 10
    local offsety = 40
    -- 开启/关闭
    ui:append("WndCheckBox", {
        x = x, y = y, text = _L["enable/disable"],
        checked = XLifeBar.bEnabled,
        oncheck = function(bChecked) XLifeBar.bEnabled = bChecked D.Reset(true) end,
		tip = function()
			if IsShielded() then
				return _L['Can not use in pubg map!']
			end
		end,
        autoenable = function() return not IsShielded() end,
    })
    x = x + 110
    -- 使用所有角色公共设置
    ui:append("WndCheckBox", {
        w = 180, x = x, y = y, text = _L["use global config"],
        checked = XLifeBar.bUseGlobalConfig,
        oncheck = function(bChecked)
            D.SaveConfig()
            XLifeBar.bUseGlobalConfig = bChecked
            D.LoadConfig()
            LoadUI(ui)
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    x = x + 180
    ui:append("Text", {
        x = x + 5, y = y - 15,
        text = _L['only enable in those maps below'],
        autoenable = function() return IsEnabled() end,
    })
    ui:append("WndCheckBox", {
        x = x, y = y + 5, w = 80, text = _L['arena'],
        checked = XLifeBar.bOnlyInArena,
        oncheck = function(bChecked)
            XLifeBar.bOnlyInArena = bChecked
            D.Reset(true)
        end,
        autoenable = function() return IsEnabled() end,
    })
    x = x + 80
    ui:append("WndCheckBox", {
        x = x, y = y + 5, w = 70, text = _L['battlefield'],
        checked = XLifeBar.bOnlyInBattleField,
        oncheck = function(bChecked)
            XLifeBar.bOnlyInBattleField = bChecked
            D.Reset(true)
        end,
        autoenable = function() return IsEnabled() end,
    })
    x = x + 70
    ui:append("WndCheckBox", {
        x = x, y = y + 5, w = 70, text = _L['dungeon'],
        checked = XLifeBar.bOnlyInDungeon,
        oncheck = function(bChecked)
            XLifeBar.bOnlyInDungeon = bChecked
            D.Reset(true)
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety
    -- <hr />
    ui:append("Image", "Image_Spliter"):find('#Image_Spliter'):pos(10, y-7):size(w - 20, 2):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)

    x, y = 10, 55
    offsety = 22
    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifeBarWidth",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
        text = function(value) return _L("lifebar width: %s px.", value) end, -- 血条宽度
        value = Config.nLifeWidth or Config_Default.nLifeWidth,
        onchange = function(value)
            Config.nLifeWidth = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifeBarHeight",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
        text = function(value) return _L("lifebar height: %s px.", value) end, -- 血条高度
        value = Config.nLifeHeight or Config_Default.nLifeHeight,
        onchange = function(value)
            Config.nLifeHeight = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifeBarOffsetX",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
        text = function(value) return _L("lifebar offset-x: %d px.", value) end, -- 血条水平偏移
        value = Config.nLifeOffsetX or Config_Default.nLifeOffsetX,
        onchange = function(value)
            Config.nLifeOffsetX = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifeBarOffsetY",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("lifebar offset-y: %d px.", value) end, -- 血条竖直偏移
        value = Config.nLifeOffsetY or Config_Default.nLifeOffsetY,
        onchange = function(value)
            Config.nLifeOffsetY = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifePerOffsetX",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
        text = function(value) return _L("life percentage offset-x: %d px.", value) end, -- 血量百分比水平偏移
        value = Config.nLifePerOffsetX or Config_Default.nLifePerOffsetX,
        onchange = function(value)
            Config.nLifePerOffsetX = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_LifePerOffsetY",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("life percentage offset-y: %d px.", value) end, -- 血量百分比竖直偏移
        value = Config.nLifePerOffsetY or Config_Default.nLifePerOffsetY,
        onchange = function(value)
            Config.nLifePerOffsetY = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTBarWidth",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
        text = function(value) return _L("otbar width: %s px.", value) end, -- OT宽度
        value = Config.nOTBarWidth or Config_Default.nOTBarWidth,
        onchange = function(value)
            Config.nOTBarWidth = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTBarHeight",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
        text = function(value) return _L("otbar height: %s px.", value) end, -- OT高度
        value = Config.nOTBarHeight or Config_Default.nOTBarHeight,
        onchange = function(value)
            Config.nOTBarHeight = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTBarOffsetX",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
        text = function(value) return _L("otbar offset-x: %d px.", value) end, -- OT水平偏移
        value = Config.nOTBarOffsetX or Config_Default.nOTBarOffsetX,
        onchange = function(value)
            Config.nOTBarOffsetX = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTBarOffsetY",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("otbar offset-y: %d px.", value) end, -- OT竖直偏移
        value = Config.nOTBarOffsetY or Config_Default.nOTBarOffsetY,
        onchange = function(value)
            Config.nOTBarOffsetY = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTTitleOffsetX",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
        text = function(value) return _L("ot title offset-x: %d px.", value) end, -- OT名称水平偏移
        value = Config.nOTTitleOffsetX or Config_Default.nOTTitleOffsetX,
        onchange = function(value)
            Config.nOTTitleOffsetX = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_OTTitleOffsetY",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("ot title offset-y: %d px.", value) end, -- OT名称竖直偏移
        value = Config.nOTTitleOffsetY or Config_Default.nOTTitleOffsetY,
        onchange = function(value)
            Config.nOTTitleOffsetY = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_FristLineHeight",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("1st line offset-y: %d px.", value) end, -- 第一行字高度
        value = Config.nLineHeight[1] or Config_Default.nLineHeight[1],
        onchange = function(value)
            Config.nLineHeight[1] = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_SecondLineHeight",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("2nd line offset-y: %d px.", value) end, -- 第二行字高度
        value = Config.nLineHeight[2] or Config_Default.nLineHeight[2],
        onchange = function(value)
            Config.nLineHeight[2] = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_ThirdLineHeight",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
        text = function(value) return _L("3rd line offset-y: %d px.", value) end, -- 第三行字高度
        value = Config.nLineHeight[3] or Config_Default.nLineHeight[3],
        onchange = function(value)
            Config.nLineHeight[3] = value
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_Distance",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 300 },
        text = function(value) return value == 0 and _L["Max Distance: Unlimited."] or _L("Max Distance: %s foot.", value) end,
        value = math.sqrt(Config.nDistance or Config_Default.nDistance) / 64,
        onchange = function(value)
            Config.nDistance = value * value * 64 * 64
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndSliderBox", {
        name = "WndSliderBox_Alpha",
        x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_PERCENT, range = { 0, 255 },
        text = function(value) return _L("alpha: %.0f%%.", value) end, -- 透明度
        value = Config.nAlpha or Config_Default.nAlpha,
        onchange = function(value)
            Config.nAlpha = value * 255 / 100
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 右半边
    x, y = 350, 60
    offsety = 33
    local function FillColorTable(opt, relation, tartype)
        local cfg = Config.Color[relation]
        opt.rgb = cfg[tartype]
        opt.bColorTable = true
        opt.fnChangeColor = function(_, r, g, b)
            cfg[tartype] = { r, g, b }
            D.Reset()
        end
        if tartype == "Player" then
            table.insert(opt, {
                szOption = _L['Unified force color'],
                bCheck = true, bMCheck = true,
                bChecked = not cfg.DifferentiateForce,
                fnAction = function(_, r, g, b)
                    cfg.DifferentiateForce = false
                    D.Reset()
                end,
                rgb = cfg[tartype],
                szIcon = 'ui/Image/button/CommonButton_1.UITex',
                nFrame = 69, nMouseOverFrame = 70,
                szLayer = "ICON_RIGHT",
                fnClickIcon = function()
                    XGUI.OpenColorPicker(function(r, g, b)
                        cfg[tartype] = { r, g, b }
                        D.Reset()
                    end)
                end,
            })
            table.insert(opt, {
                szOption = _L['Differentiate force color'],
                bCheck = true, bMCheck = true,
                bChecked = cfg.DifferentiateForce,
                fnAction = function(_, r, g, b)
                    cfg.DifferentiateForce = true
                    D.Reset()
                end,
            })
            table.insert(opt,{ bDevide = true } )
            for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
                table.insert(opt, {
                    szOption = szForceTitle,
                    rgb = cfg[dwForceID],
                    szIcon = 'ui/Image/button/CommonButton_1.UITex',
                    nFrame = 69, nMouseOverFrame = 70,
                    szLayer = "ICON_RIGHT",
                    fnClickIcon = function()
                        XGUI.OpenColorPicker(function(r, g, b)
                            cfg[dwForceID] = { r, g, b }
                            D.Reset()
                        end)
                    end,
                    fnDisable = function()
                        return not cfg.DifferentiateForce
                    end,
                })
            end
        end
        return opt
    end
    local function GeneBooleanPopupMenu(cfgs, szPlayerTip, szNpcTip)
        local t = {}
        if szPlayerTip then
            table.insert(t, { szOption = szPlayerTip, bDisable = true } )
            for relation, cfg in pairs(cfgs) do
                if cfg.Player ~= nil then
                    table.insert(t, FillColorTable({
                        szOption = _L[relation],
                        bCheck = true,
                        bChecked = cfg.Player,
                        fnAction = function()
                            cfg.Player = not cfg.Player
                            D.Reset()
                        end,
                    }, relation, "Player"))
                end
            end
        end
        if szPlayerTip and szNpcTip then
            table.insert(t,{ bDevide = true } )
        end
        if szNpcTip then
            table.insert(t,{ szOption = szNpcTip, bDisable = true } )
            for relation, cfg in pairs(cfgs) do
                if cfg.Npc ~= nil then
                    table.insert(t, FillColorTable({
                        szOption = _L[relation],
                        bCheck = true,
                        bChecked = cfg.Npc,
                        fnAction = function()
                            cfg.Npc = not cfg.Npc
                            D.Reset()
                        end,
                    }, relation, "Npc"))
                end
            end
        end
        return t
    end
    -- 显示名字
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["name display config"],
        menu = function()
            return GeneBooleanPopupMenu(Config.ShowName, _L["player name display"], _L["npc name display"])
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 称号
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["title display config"],
        menu = function()
            return GeneBooleanPopupMenu(Config.ShowTitle, _L["player title display"], _L["npc title display"])
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 帮会
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["tong display config"],
        menu = function()
            return GeneBooleanPopupMenu(Config.ShowTong, _L["player tong display"])
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 血条设置
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["lifebar display config"],
        menu = function()
            local t = GeneBooleanPopupMenu(Config.ShowLife, _L["player lifebar display"], _L["npc lifebar display"])
            table.insert(t, { bDevide = true })
            local t1 = {
                szOption = _L['Draw direction'],
            }
            for _, szDirection in ipairs({ "LEFT_RIGHT", "RIGHT_LEFT", "TOP_BOTTOM", "BOTTOM_TOP" }) do
                table.insert(t1, {
                    szOption = _L.DIRECTION[szDirection],
                    bCheck = true, bMCheck = true,
                    bChecked = Config.szLifeDirection == szDirection,
                    fnAction = function()
                        Config.szLifeDirection = szDirection
                        D.Reset()
                    end,
                })
            end
            table.insert(t, t1)
            return t
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 显示血量%
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["lifepercentage display config"],
        menu = function()
            local t = GeneBooleanPopupMenu(Config.ShowLifePer, _L["player lifepercentage display"], _L["npc lifepercentage display"])
            table.insert(t, { bDevide = true })
            table.insert(t, {
                szOption = _L['hide when unfight'],
                bCheck = true,
                bChecked = Config.bHideLifePercentageWhenFight,
                fnAction = function()
                    Config.bHideLifePercentageWhenFight = not Config.bHideLifePercentageWhenFight
                    D.Reset()
                end,
            })
            table.insert(t, {
                szOption = _L['hide decimal'],
                bCheck = true,
                bChecked = Config.bHideLifePercentageDecimal,
                fnAction = function()
                    Config.bHideLifePercentageDecimal = not Config.bHideLifePercentageDecimal
                    D.Reset()
                end,
            })
            return t
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 显示读条%
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["skillpercentage display config"],
        menu = function()
            local t = GeneBooleanPopupMenu(Config.ShowOTBar, _L["player skillpercentage display"], _L["npc skillpercentage display"])
            table.insert(t, { bDevide = true })
            local t1 = {
                szOption = _L['Draw direction'],
            }
            for _, szDirection in ipairs({ "LEFT_RIGHT", "RIGHT_LEFT", "TOP_BOTTOM", "BOTTOM_TOP" }) do
                table.insert(t1, {
                    szOption = _L.DIRECTION[szDirection],
                    bCheck = true, bMCheck = true,
                    bChecked = Config.szOTBarDirection == szDirection,
                    fnAction = function()
                        Config.szOTBarDirection = szDirection
                        D.Reset()
                    end,
                })
            end
            table.insert(t, t1)
            return t
        end,
        tip = _L['only can see otaction of target and target\'s target'],
        tippostype = ALW.TOP_BOTTOM,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    -- 当前阵营
    ui:append("WndComboBox", {
        x = x, y = y, text = _L["set current camp"],
        menu = function()
            return {{
                szOption = _L['auto detect'],
                bCheck = true, bMCheck = true,
                bChecked = Config.nCamp == -1,
                fnAction = function()
                    Config.nCamp = -1
                    D.Reset()
                end,
            }, {
                szOption = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD],
                bCheck = true, bMCheck = true,
                bChecked = Config.nCamp == CAMP.GOOD,
                fnAction = function()
                    Config.nCamp = CAMP.GOOD
                    D.Reset()
                end,
            }, {
                szOption = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL],
                bCheck = true, bMCheck = true,
                bChecked = Config.nCamp == CAMP.EVIL,
                fnAction = function()
                    Config.nCamp = CAMP.EVIL
                    D.Reset()
                end,
            }, {
                szOption = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL],
                bCheck = true, bMCheck = true,
                bChecked = Config.nCamp == CAMP.NEUTRAL,
                fnAction = function()
                    Config.nCamp = CAMP.NEUTRAL
                    D.Reset()
                end,
            }}
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety
    offsety = 32

    ui:append("WndCheckBox", {
        x = x, y = y, text = _L['show special npc'],
        checked = Config.bShowSpecialNpc,
        oncheck = function(bChecked)
            Config.bShowSpecialNpc = bChecked
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety - 10

    ui:append("WndCheckBox", {
        x = x, y = y, text = _L['adjust index'],
        checked = Config.bAdjustIndex,
        oncheck = function(bChecked)
            Config.bAdjustIndex = bChecked
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety - 10

    ui:append("WndCheckBox", {
        x = x, y = y, text = _L['show distance'],
        checked = Config.bShowDistance,
        oncheck = function(bChecked)
            Config.bShowDistance = bChecked
            D.Reset()
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety

    ui:append("WndButton", {
        x = x, y = y, text = _L("Font: %d",Config.nFont),
        onclick = function()
            MY.UI.OpenFontPicker(function(nFont)
                Config.nFont = nFont
                D.Reset()
                ui:children("#WndButton_Font"):text(_L("Font: %d",Config.nFont))
            end)
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety - 10

    ui:append("WndButton", {
        x = x, y = y, w = 120, text = _L['reset config'],
        onclick = function()
            MessageBox({
                szName = "XLifeBar_Reset",
                szMessage = _L['Are you sure to reset config?'], {
                    szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
                        Config = clone(Config_Default)
                        D.Reset()
                        LoadUI(ui)
                    end
                }, {szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
            })
        end,
        autoenable = function() return IsEnabled() end,
    })
    y = y + offsety
end
MY.RegisterPanel("XLifeBar", _L["x lifebar"], _L['General'], "UI/Image/LootPanel/LootPanel.UITex|74", {255,127,0,200}, PS)

local function onSwitch()
    XLifeBar.bEnabled = not XLifeBar.bEnabled
    D.Reset(true)
end
MY.Game.RegisterHotKey("MY_XLifeBar_S", _L["x lifebar"], onSwitch)
