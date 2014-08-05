local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."XLifeBar/lang/")
local _Cache = {}

-- 这个只是默认配置 改这里没用的 会修改的话 修改data文件
local Config_Default = {
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
    
    nAlpha = 200,
    nFont = 16,
    nDistance = 24,
}
local Config = clone(Config_Default)

XLifeBar = {}
XLifeBar.bEnabled = false
XLifeBar.bUseGlobalConfig = false
RegisterCustomData("XLifeBar.bEnabled")
RegisterCustomData("XLifeBar.bUseGlobalConfig")
local _XLifeBar = {
    dwVersion = 0x0000700,
    szConfig = "userdata/XLifeBar/CFG",
    tObject = {},
    tTongList = {},
    tNpc = {},
    tPlayer = {},
    dwTargetID = 0,
}

_XLifeBar.GetName = function(tar)
    local szName = tar.szName
    if szName == "" and not IsPlayer(tar.dwID) then
        szName = string.gsub(Table_GetNpcTemplateName(tar.dwTemplateID), "^%s*(.-)%s*$", "%1")
        if szName == "" then
            szName = tar.dwID
        end
    end
    if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) then
        local emp = GetPlayer(tar.dwEmployer)
        if not emp then
            szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
        else
            szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
        end
    end
    return szName
end


_XLifeBar.GetObject = function(dwID)
    local Object
    if IsPlayer(dwID) then
        Object = GetPlayer(dwID)
    else
        Object = GetNpc(dwID)
    end
    return Object
end
_XLifeBar.GetNz = function(nZ,nZ2)
    return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

_XLifeBar.GetForce = function(dwID)
    local me = GetClientPlayer()
    if not me then
        return "Neutrality"
    end
    if dwID == me.dwID then
        return "Self"
    end
    if IsParty(me.dwID, dwID) then
        return "Party"
    end
    if IsNeutrality(me.dwID,dwID) then
        return "Neutrality"
    end
    if IsEnemy(me.dwID,dwID) then -- 敌对关系
        local r,g,b = GetHeadTextForceFontColor(dwID,me.dwID)
        if r == 255 and g == 255 and b == 0 then
            return "Neutrality"
        else
            return "Enemy"
        end
    end
    if IsAlly(me.dwID, dwID) then -- 相同阵营
        return "Ally"
    end
    
    return "Neutrality" -- "Other"
end

_XLifeBar.Reset = function(bNoSave)
    _XLifeBar.tObject = {}
    _XLifeBar.Frame:Lookup("",""):Clear()
    if not bNoSave then
        if XLifeBar.bUseGlobalConfig then
            MY.Sys.SaveLUAData(_XLifeBar.szConfig, Config)
        else
            MY.Sys.SaveUserData(_XLifeBar.szConfig, Config)
        end
    end
end

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
MY.RegisterInit(_XLifeBar.Reload)

local HP = class()

function HP:ctor(object) -- KGobject
    self.self = object
    self.dwID = object.dwID
    self.force = _XLifeBar.GetForce(object.dwID)
    return self
end
-- 创建
function HP:Create()
    -- Create handle
    local frame = _XLifeBar.Frame
    if not frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
    end
    local handle = frame:Lookup("",tostring(self.dwID))
    local lifeper = self.self.nCurrentLife / self.self.nMaxLife
    if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
    
    _XLifeBar.tObject[self.dwID] = {
        Lifeper = lifeper,
        handle = handle,
        Force = self.force,
    }
    if not handle:Lookup(string.format("bg_%s",self.dwID)) then
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"name_%s\"</shadow>",self.dwID) )
        self:DrawBorder(Config.nAlpha)
        self:DrawName()
    end
    --绘制血条
    self:DrawLife(lifeper)
    return self
end


-- 删除
function HP:Remove()
    local frame = _XLifeBar.Frame
    if frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:RemoveItem(frame:Lookup("",tostring(self.dwID)))        
    end
    _XLifeBar.tObject[self.dwID] = nil
    return self
end

function HP:DrawName(col)
    local nAlpha = Config.nAlpha
    local tab = _XLifeBar.tObject[self.dwID]
    local handle = tab.handle
    local sha = handle:Lookup(string.format("name_%s",self.dwID))

    
    local cfgName = Config.bShowName.Player[self.force]
    local cfgTitle = Config.bShowTitle.Player[self.force]
    local cfgTong = Config.bShowTong.Player[self.force]
    local cfgLifePer = Config.bShowLifePer.Player[self.force]
    local cfgOTTitle = Config.bShowOTBar.Player[self.force]
    local r,g,b = unpack(Config.Col.Player[self.force])
    
    if not IsPlayer(self.dwID) then
        cfgName = Config.bShowName.Npc[self.force]
        cfgTitle = Config.bShowTitle.Npc[self.force]
        cfgTong = false
        cfgLifePer = Config.bShowLifePer.Npc[self.force]
        cfgOTTitle = Config.bShowOTBar.Npc[self.force]
        r,g,b = unpack(Config.Col.Npc[self.force])
    end
    local szName, szTitle, szTong, szLifePer, szOTTitle
    if cfgName  then szName  = _XLifeBar.GetName(self.self) end
    if cfgTitle and self.self.szTitle and self.self.szTitle~="" then szTitle = "<" .. self.self.szTitle .. ">" end
    if cfgTong and self.self.dwTongID ~= 0 then
        if not _XLifeBar.tTongList[self.self.dwTongID] then
            if GetTongClient().ApplyGetTongName(self.self.dwTongID) then
                _XLifeBar.tTongList[self.self.dwTongID] = GetTongClient().ApplyGetTongName(self.self.dwTongID)
            end
        end
        if _XLifeBar.tTongList[self.self.dwTongID] then
            szTong = "[" .. _XLifeBar.tTongList[self.self.dwTongID] .. "]"
        end
    end
    if cfgLifePer then szLifePer = string.format("%.1f", 100 * tab.Lifeper) end
    if cfgOTTitle and tab.szOTTitle~="" then szOTTitle = tab.szOTTitle end
    
    if type(col) == "table" then
        r,g,b = unpack(col)
    elseif type(col) == "function" then
        r,g,b = col(r,g,b)
    elseif type(col) == "number" then
        r,g,b = math.ceil(r/col),math.ceil(g/col),math.ceil(b/col)
    end
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    if szLifePer then
        sha:AppendCharacterID(self.dwID,true,r,g,b,nAlpha,{0,0,0,0,- Config.nPerHeight},Config.nFont,string.format("%.1f", 100 * tab.Lifeper),1,1)
    end
    if szOTTitle then
        sha:AppendCharacterID(self.dwID,true,r,g,b,nAlpha,{0,0,0,0,- Config.nOTTitleHeight},Config.nFont,tab.szOTTitle,1,1)
    end
    local i = #Config.nLineHeight
    if szTong then
        sha:AppendCharacterID(self.dwID,true,r,g,b,nAlpha,{0,0,0,0,- Config.nLineHeight[i]},Config.nFont,szTong,1,1)
        i = i - 1
    end
    if szTitle then
        sha:AppendCharacterID(self.dwID,true,r,g,b,nAlpha,{0,0,0,0,- Config.nLineHeight[i]},Config.nFont,szTitle,1,1)
        i = i - 1
    end
    if szName then
        sha:AppendCharacterID(self.dwID,true,r,g,b,nAlpha,{0,0,0,0,- Config.nLineHeight[i]},Config.nFont,szName,1,1)
        i = i - 1
    end
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(nAlpha)
    local tab = _XLifeBar.tObject[self.dwID]
    local handle = tab.handle
    
    local cfgLife = Config.bShowLife.Npc[self.force]
    if IsPlayer(self.dwID) then
        cfgLife = Config.bShowLife.Player[self.force]
    end
    
    
    if cfgLife then
        -- 绘制外边框
        local sha = handle:Lookup(string.format("hp_bg_%s",self.dwID))
        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()
        local bcX,bcY = - Config.nLifeWidth / 2 ,(- Config.nLifeHeight) - Config.nLifeOffsetY

        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nLifeWidth,bcY})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nLifeWidth,bcY+Config.nLifeHeight})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+Config.nLifeHeight})

        -- 绘制内边框
        local sha = handle:Lookup(string.format("hp_bg2_%s",self.dwID))
        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()        
        local bcX,bcY = - (Config.nLifeWidth / 2 - 1),(- (Config.nLifeHeight - 1)) - Config.nLifeOffsetY

        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nLifeWidth - 2),bcY})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nLifeWidth - 2),bcY+(Config.nLifeHeight - 2)})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(Config.nLifeHeight - 2)})        
    end
    return self
end


-- 填充边框 默认200的nAlpha
function HP:DrawOTBarBorder(nAlpha)
    local tab = _XLifeBar.tObject[self.dwID]
    local handle = tab.handle
    
    local cfgOTBar = Config.bShowOTBar.Npc[self.force]
    if IsPlayer(self.dwID) then
        cfgOTBar = Config.bShowOTBar.Player[self.force]
    end
    
    
    if cfgOTBar then
        -- 绘制外边框
        local sha = handle:Lookup(string.format("ot_bg_%s",self.dwID))
        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()
        local bcX,bcY = - Config.nOTBarWidth / 2 ,(- Config.nOTBarHeight) - Config.nOTBarOffsetY

        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nOTBarWidth,bcY})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nOTBarWidth,bcY+Config.nOTBarHeight})
        sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+Config.nOTBarHeight})

        -- 绘制内边框
        local sha = handle:Lookup(string.format("ot_bg2_%s",self.dwID))
        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()        
        local bcX,bcY = - (Config.nOTBarWidth / 2 - 1),(- (Config.nOTBarHeight - 1)) - Config.nOTBarOffsetY

        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nOTBarWidth - 2),bcY})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nOTBarWidth - 2),bcY+(Config.nOTBarHeight - 2)})
        sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(Config.nOTBarHeight - 2)})        
    end
    return self
end

-- 填充血条
function HP:DrawLife(Lifeper,col)
    local tab = _XLifeBar.tObject[self.dwID]
    local handle = tab.handle
    
    local r,g,b = unpack(Config.Col.Player[self.force])
    local cfgLife = Config.bShowLife.Player[self.force]
    if not IsPlayer(self.dwID) then
        cfgLife = Config.bShowLife.Npc[self.force]
        r,g,b = unpack(Config.Col.Npc[self.force])
    end
    if type(col)=="table" then
        r,g,b = unpack(col)
    elseif type(col)=="function" then
        r,g,b = col(r,g,b)
    end

    if cfgLife then
        --绘制血条
        local sha = handle:Lookup(string.format("hp_%s",self.dwID))

        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()

        local bcX,bcY = - (Config.nLifeWidth / 2 - 2),(- (Config.nLifeHeight - 2)) - Config.nLifeOffsetY
        local Lifeper = Lifeper or tab.Lifeper
        local Life = (Config.nLifeWidth - 4) * Lifeper

        
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX+Life,bcY})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX+Life,bcY+(Config.nLifeHeight - 4)})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX,bcY+(Config.nLifeHeight - 4)})
    end
    return self
end

-- 填充头顶读条
function HP:DrawOTBar(Lifeper,col)
    local tab = _XLifeBar.tObject[self.dwID]
    local handle = tab.handle
    
    local r,g,b = unpack(Config.Col.Player[self.force])
    local cfgOTBar = Config.bShowOTBar.Player[self.force]
    if not IsPlayer(self.dwID) then
        cfgOTBar = Config.bShowOTBar.Npc[self.force]
        r,g,b = unpack(Config.Col.Npc[self.force])
    end
    if type(col)=="table" then
        r,g,b = unpack(col)
    elseif type(col)=="function" then
        r,g,b = col(r,g,b)
    end

    if cfgOTBar then
        --绘制技能读条
        local sha = handle:Lookup(string.format("ot_%s",self.dwID))

        sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
        sha:SetD3DPT(D3DPT.TRIANGLEFAN)
        sha:ClearTriangleFanPoint()

        local bcX,bcY = - (Config.nOTBarWidth / 2 - 2),(- (Config.nOTBarHeight - 2)) - Config.nOTBarOffsetY
        local Lifeper = Lifeper or tab.Lifeper
        local Life = (Config.nOTBarWidth - 4) * Lifeper

        
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX,bcY})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX+Life,bcY})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX+Life,bcY+(Config.nOTBarHeight - 4)})
        sha:AppendCharacterID(self.dwID,true,r,g,b,Config.nAlpha,{0,0,0,bcX,bcY+(Config.nOTBarHeight - 4)})
    end
    return self
end


XLifeBar.Create = function(...)
    local self = HP.new(...)
    return self
end
setmetatable(XLifeBar, { __call = function(me, ...) return me.Create(...) end, __metatable = true })

function XLifeBar.OnFrameCreate()
    _XLifeBar.Frame = this
end

function XLifeBar.OnFrameBreathe()
    if not XLifeBar.bEnabled then return end
    local me = GetClientPlayer()
    if not me then return end
    local fnHighLight = function(r,g,b) return 255-(255-r)*0.3, 255-(255-g)*0.3, 255-(255-b)*0.3 end
    -- local _, _, fPitch = Camera_GetRTParams()
    for k , v in pairs(_XLifeBar.tNpc) do
        local object = GetNpc(k)
        if GetCharacterDistance(me.dwID,k) / 64 < Config.nDistance --[[ 这是镜头补偿判断 但是不好用先不加 and (fPitch > -0.8 or _XLifeBar.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)]] then
            if not _XLifeBar.tObject[k] then
                if object.CanSeeName() or Config.bShowSpecialNpc then
                    XLifeBar(object):Create()
                end
            else
                local tab = _XLifeBar.tObject[k]
                -- 血量判定
                local lifeper = object.nCurrentLife / object.nMaxLife
                if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
                if lifeper ~= tab.Lifeper then
                    tab.Lifeper = lifeper
                    XLifeBar(object):DrawLife(lifeper):DrawName() -- 血量变动的时候重绘名字 
                end
                -- 读条判定
                local otper = 0
                local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = object.GetSkillPrepareState()
                if bIsPrepare then
                    otper = fProgress
                    tab.szOTTitle = Table_GetSkillName(dwSkillID, dwSkillLevel)
                else
                    otper = 0
                    tab.szOTTitle = nil
                end
                if otper ~= tab.Otper then
                    if tab.Otper==0 then
                        XLifeBar(object):DrawOTBarBorder(Config.nAlpha):DrawName() -- 读条状态变动的时候重绘名字 
                    elseif otper==0 then
                        XLifeBar(object):DrawOTBarBorder(0):DrawName() -- 读条状态变动的时候重绘名字 
                    end
                    tab.Otper = otper
                    XLifeBar(object):DrawOTBar(otper)
                    -- 当前目标
                    if _XLifeBar.dwTargetID == object.dwID then
                        XLifeBar(object):DrawOTBar(otper, fnHighLight)
                    else
                        XLifeBar(object):DrawOTBar(otper)
                    end
                end
                
                -- 势力切换
                local Force = _XLifeBar.GetForce(k)
                if Force ~= tab.Force then
                    XLifeBar(object):Remove():Create()
                end
                -- 当前目标
                if _XLifeBar.dwTargetID == object.dwID then
                    XLifeBar(object):DrawLife(lifeper,fnHighLight):DrawName(fnHighLight) -- 暂定 
                end
                
                    -- 死亡判定
                if object.nMoveState == MOVE_STATE.ON_DEATH then
                    if _XLifeBar.dwTargetID == object.dwID then
                        XLifeBar(object):DrawLife(0):DrawName(2.2)
                    else
                        XLifeBar(object):DrawLife(0):DrawName(2.5)
                    end
                end
            end
        elseif _XLifeBar.tObject[k] then
            XLifeBar(object):Remove()
        end
    end
    
    for k , v in pairs(_XLifeBar.tPlayer) do
        local object = GetPlayer(k)
        if object.szName ~= "" then
            if GetCharacterDistance(me.dwID,k) / 64 < Config.nDistance --[[ 这是镜头补偿判断 但是不好用先不加 and (fPitch > -0.8 or _XLifeBar.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)]] then
                if not _XLifeBar.tObject[k] then
                    XLifeBar(object):Create():DrawBorder(255)
                else
                    local tab = _XLifeBar.tObject[k]
                    -- 血量判定
                    local lifeper = object.nCurrentLife / object.nMaxLife
                    if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
                    if lifeper ~= tab.Lifeper then
                        tab.Lifeper = lifeper
                        XLifeBar(object):DrawLife(lifeper):DrawName() -- 血量变动的时候重绘名字 
                    end
                    -- 读条判定
                    local otper = 0
                    if object.GetOTActionState()==1 then
                        MY.Player.SetTempTarget(TARGET.PLAYER, k)
                        local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = object.GetSkillPrepareState()
                        otper = fProgress
                        tab.szOTTitle = Table_GetSkillName(dwSkillID, dwSkillLevel)
                        MY.Player.ResumeTarget()
                    else
                        otper = 0
                        tab.szOTTitle = nil
                    end
                    if otper ~= tab.Otper then
                        if tab.Otper==0 then
                            XLifeBar(object):DrawOTBarBorder(Config.nAlpha):DrawName() -- 读条状态变动的时候重绘名字 
                        elseif otper==0 then
                            XLifeBar(object):DrawOTBarBorder(0):DrawName() -- 读条状态变动的时候重绘名字 
                        end
                        tab.Otper = otper
                        -- 当前目标
                        if _XLifeBar.dwTargetID == object.dwID then
                            XLifeBar(object):DrawOTBar(otper, fnHighLight)
                        else
                            XLifeBar(object):DrawOTBar(otper)
                        end
                    end
                    
                    -- 势力切换
                    local Force = _XLifeBar.GetForce(k)
                    if Force ~= tab.Force then
                        XLifeBar(object):Remove():Create()
                    end
                    
                    -- 当前目标
                    if _XLifeBar.dwTargetID == object.dwID then
                        XLifeBar(object):DrawLife(lifeper,fnHighLight):DrawName(fnHighLight) -- 暂定 
                    end
                    
                    -- 死亡判定
                    if object.nMoveState == MOVE_STATE.ON_DEATH then
                        if _XLifeBar.dwTargetID == object.dwID then
                            XLifeBar(object):DrawLife(0):DrawName(2.2)
                        else
                            XLifeBar(object):DrawLife(0):DrawName(2.5)
                        end
                    end
                    
                end
            elseif _XLifeBar.tObject[k] then
                XLifeBar(object):Remove()
            end
        end
    end
    
end

RegisterEvent("NPC_ENTER_SCENE",function()
    _XLifeBar.tNpc[arg0] = true
end)

RegisterEvent("NPC_LEAVE_SCENE",function()
    _XLifeBar.tNpc[arg0] = nil
    local object = GetNpc(arg0)
    XLifeBar(object):Remove()
end)

RegisterEvent("PLAYER_ENTER_SCENE",function()
    _XLifeBar.tPlayer[arg0] = true
end)

RegisterEvent("PLAYER_LEAVE_SCENE",function()
    _XLifeBar.tPlayer[arg0] = nil
    local object = GetPlayer(arg0)
    XLifeBar(object):Remove()
end)

RegisterEvent("UPDATE_SELECT_TARGET",function()
    local dwID,_ = Target_GetTargetData()
    if _XLifeBar.dwTargetID == dwID then
        return
    end
    if _XLifeBar.tObject[_XLifeBar.dwTargetID] then
        XLifeBar(_XLifeBar.GetObject(_XLifeBar.dwTargetID)):DrawLife():DrawName()
    end
    _XLifeBar.dwTargetID = dwID
end)

-- RegisterEvent("CALL_LUA_ERROR", function()
    -- Output(arg0)
-- end)

-- RegisterEvent("FIRST_LOADING_END", function()
--     Player_AppendAddonMenu({function() return {_XLifeBar.GetMenu()} end})
--     -- Wnd.ToggleWindow("CombatTextWnd")
--     -- Wnd.ToggleWindow("CombatTextWnd")
-- end)
Wnd.OpenWindow("interface/MY/XLifeBar/XLifeBar.ini","XLifeBar")

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    local x, y = 20, 20
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
        ui:children("#WndSliderBox_Distance"):value(Config.nDistance)
        ui:children("#WndSliderBox_Alpha"):value(Config.nAlpha)
        ui:children("#WndCheckBox_ShowSpecialNpc"):check(Config.bShowSpecialNpc)
        ui:children("#WndButton_Font"):text(_L("Font: %d",Config.nFont))
    end
    -- 开启/关闭
    ui:append("WndCheckBox_Switcher", "WndCheckBox"):children("#WndCheckBox_Switcher")
      :pos(x,y):text(_L["enable/disable"])
      :check(function(bChecked) XLifeBar.bEnabled = bChecked _XLifeBar.Reset(true) end)
      :check(XLifeBar.bEnabled)
    -- 使用所有角色公共设置
    ui:append("WndCheckBox_GlobalConfig", "WndCheckBox"):children("#WndCheckBox_GlobalConfig")
      :pos(x+110,y):text(_L["use global config"])
      :check(function(bChecked)
        XLifeBar.bUseGlobalConfig = bChecked
        _XLifeBar.Reload()
        fnLoadUI(ui)
      end)
      :check(XLifeBar.bEnabled)
    y = y + offsety
    -- <hr />
    ui:append('Image_Spliter','Image'):find('#Image_Spliter'):pos(x,y-7):size(w-x*2,2):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)
    
    x, y = 20, 80
    offsety = 33
    ui:append("WndSliderBox_LifebarWidth", "WndSliderBox"):children("#WndSliderBox_LifebarWidth")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("lifebar width: %s px.", value) end)--血条长度
      :change(function(value) Config.nLifeWidth = value;_XLifeBar.Reset() end)
      :value(Config.nLifeWidth)
    y = y + offsety
    
    ui:append("WndSliderBox_LifebarHeight", "WndSliderBox"):children("#WndSliderBox_LifebarHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("lifebar height: %s px.", value) end)--血条高度
      :change(function(value) Config.nLifeHeight = value;_XLifeBar.Reset() end)
      :value(Config.nLifeHeight)
    y = y + offsety
    
    ui:append("WndSliderBox_LifeHeight", "WndSliderBox"):children("#WndSliderBox_LifeHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("lifebar offset-y: %d px.", value) end)--血条高度偏移
      :change(function(value) Config.nLifeOffsetY = value;_XLifeBar.Reset() end)
      :value(Config.nLifeOffsetY)
    y = y + offsety
    
    ui:append("WndSliderBox_PerHeight", "WndSliderBox"):children("#WndSliderBox_PerHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("percentage offset-y: %d px.", value) end)--百分比高度
      :change(function(value) Config.nPerHeight = value;_XLifeBar.Reset() end)
      :value(Config.nPerHeight)
    y = y + offsety
    
    ui:append("WndSliderBox_OTBarWidth", "WndSliderBox"):children("#WndSliderBox_OTBarWidth")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("otbar width: %s px.", value) end)--OT长度
      :change(function(value) Config.nOTBarWidth = value;_XLifeBar.Reset() end)
      :value(Config.nOTBarWidth)
    y = y + offsety
    
    ui:append("WndSliderBox_OTBarHeight", "WndSliderBox"):children("#WndSliderBox_OTBarHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(5,150)
      :text(function(value) return _L("otbar height: %s px.", value) end)--OT高度
      :change(function(value) Config.nOTBarHeight = value;_XLifeBar.Reset() end)
      :value(Config.nOTBarHeight)
    y = y + offsety
    
    ui:append("WndSliderBox_OTHeight", "WndSliderBox"):children("#WndSliderBox_OTHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("otbar offset-y: %d px.", value) end)--OT高度偏移
      :change(function(value) Config.nOTBarOffsetY = value;_XLifeBar.Reset() end)
      :value(Config.nOTBarOffsetY)
    y = y + offsety
    
    ui:append("WndSliderBox_OTTitleHeight", "WndSliderBox"):children("#WndSliderBox_OTTitleHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("ot title offset-y: %d px.", value) end)--OT名称高度
      :change(function(value) Config.nOTTitleHeight = value;_XLifeBar.Reset() end)
      :value(Config.nOTTitleHeight)
    y = y + offsety
    
    ui:append("WndSliderBox_FristHeight", "WndSliderBox"):children("#WndSliderBox_FristHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("1st line offset-y: %d px.", value) end)--第一行字高度
      :change(function(value) Config.nLineHeight[1] = value;_XLifeBar.Reset() end)
      :value(Config.nLineHeight[1])
    y = y + offsety
    
    ui:append("WndSliderBox_SecondHeight", "WndSliderBox"):children("#WndSliderBox_SecondHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("2nd line offset-y: %d px.", value) end)--第二行字高度
      :change(function(value) Config.nLineHeight[2] = value;_XLifeBar.Reset() end)
      :value(Config.nLineHeight[2])
    y = y + offsety
    
    ui:append("WndSliderBox_ThirdHeight", "WndSliderBox"):children("#WndSliderBox_ThirdHeight")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,150)
      :text(function(value) return _L("3rd line offset-y: %d px.", value) end)--第三行字高度
      :change(function(value) Config.nLineHeight[3] = value;_XLifeBar.Reset() end)
      :value(Config.nLineHeight[3])
    y = y + offsety
    
    -- 右半边
    x, y = 350, 80
    ui:append("WndSliderBox_Distance", "WndSliderBox"):children("#WndSliderBox_Distance")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_VALUE):range(0,300)
      :text(function(value) return _L("Max Distance: %s foot.", value) end)
      :change(function(value) Config.nDistance = value;_XLifeBar.Reset() end)
      :value(Config.nDistance)
    y = y + offsety
    
    ui:append("WndSliderBox_Alpha", "WndSliderBox"):children("#WndSliderBox_Alpha")
      :pos(x,y):sliderStyle(MY.Const.UI.Slider.SHOW_PERCENT):range(0,255)
      :text(function(value) return _L("alpha: %.0f%%.", value) end)--透明度
      :change(function(value) Config.nAlpha = value*255/100;_XLifeBar.Reset() end)
      :value(Config.nAlpha)
    y = y + offsety
    offsety = 38
    -- 显示名字
    ui:append("WndComboBox_Name", "WndComboBox"):children("#WndComboBox_Name")
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
    ui:append("WndComboBox_Title", "WndComboBox"):children("#WndComboBox_Title")
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
    ui:append("WndComboBox_Tong", "WndComboBox"):children("#WndComboBox_Tong")
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
    ui:append("WndComboBox_Lifebar", "WndComboBox"):children("#WndComboBox_Lifebar")
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
    ui:append("WndComboBox_LifePercentage", "WndComboBox"):children("#WndComboBox_LifePercentage")
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
        return t
      end)
    y = y + offsety
    
    -- 显示读条%
    ui:append("WndComboBox_SkillPercentage", "WndComboBox"):children("#WndComboBox_SkillPercentage")
      :pos(x,y):text(_L["skillpercentage display config"])
      :menu(function()
        local t = {}
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
    
    ui:append("WndCheckBox_ShowSpecialNpc", "WndCheckBox"):children("#WndCheckBox_ShowSpecialNpc")
      :pos(x,y):text(_L['show special npc'])
      :check(function(bChecked) Config.bShowSpecialNpc = not Config.bShowSpecialNpc;_XLifeBar.Reset() end)
      :check(Config.bShowSpecialNpc)
    y = y + offsety
    
    ui:append("WndButton_Font", "WndButton"):children("#WndButton_Font")
      :pos(x,y):text(_L("Font: %d",Config.nFont))
      :click(function()
        MY.UI.OpenFontPicker(function(nFont)
            Config.nFont = nFont;_XLifeBar.Reset()
            ui:children("#WndButton_Font"):text(_L("Font: %d",Config.nFont))
        end)
      end)
    x = x + 150
    
    ui:append("WndButton_Reset", "WndButton"):children("#WndButton_Reset")
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
MY.RegisterPanel( "XLifeBar", _L["x lifebar"], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = nil } )
