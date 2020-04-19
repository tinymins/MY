--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 信息条显示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_InfoTip'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
local _Cache = {
    bFighting = false,
    nLastFightStartTimestarp = 0,
    nLastFightEndTimestarp = 0,
}
local Config_Default = {
    Ping        = { -- 网络延迟
    	bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 95, 255, 95 },
    	anchor = { x = -133, y = -111, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' }, nFont = 48,
    },
    TimeMachine = { -- 倍速显示（显示服务器有多卡……）
        bEnable = false, bShowBg = false, bShowTitle = true, rgb = { 31, 255, 31 },
        anchor  = { x = -276, y = -111, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
    },
    FPS         = { -- FPS
        bEnable = false, bShowBg = true, bShowTitle = true,
    	anchor  = { x = -10, y = -220, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
    },
    Distance    = { -- 目标距离
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 255, 0 },
        anchor  = { x = 203, y = -106, s = 'CENTER', r = 'CENTER' }, nFont = 209,
    },
    SysTime     = { -- 系统时间
        bEnable = false, bShowBg = true, bShowTitle = true,
    	anchor  = { x = 285, y = -18, s = 'BOTTOMLEFT', r = 'BOTTOMLEFT' },
    },
    FightTime   = { -- 战斗计时
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 0, 128 },
        anchor  = { x = 353, y = -117, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' }, nFont = 199,
    },
    LotusTime   = { -- 桂花和藕倒计时
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x = -290, y = -38, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
    },
    GPS         = { -- 角色坐标
        bEnable = false, bShowBg = true, bShowTitle = false, rgb = { 255, 255, 255 },
        anchor  = { x = -21, y = 250, s = 'TOPRIGHT', r = 'TOPRIGHT' }, nFont = 0,
    },
    Speedometer = { -- 角色速度
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 255, 255 },
        anchor  = { x = -10, y = 210, s = 'TOPRIGHT', r = 'TOPRIGHT' }, nFont = 0,
    },
}
local _C = {}
MY_InfoTip = {}
MY_InfoTip.Config = Clone(Config_Default)
_C.tTm = {}
_C.nTmFrameCount = GetLogicFrameCount()
_C.tSm = {}
_C.nSmFrameCount = GetLogicFrameCount()
MY_InfoTip.Cache = {
    Ping         = { -- Ping
        formatString = '', title = _L['ping monitor'], prefix = _L['Ping: '], content = _L['%d'],
        GetContent = function() return string.format(MY_InfoTip.Cache.Ping.formatString, GetPingValue() / 2) end
    },
    TimeMachine  = { -- 倍速显示
        formatString = '', title = _L['time machine'], prefix = _L['Rate: '], content = 'x%.2f',
        GetContent = function()
            local s = 1
            if _C.nTmFrameCount ~= GetLogicFrameCount() then
                local tm = _C.tTm[GLOBAL.GAME_FPS] or {}
                tm.frame = GetLogicFrameCount()
                tm.tick  = GetTickCount()
                for i = GLOBAL.GAME_FPS, 1, -1 do
                    _C.tTm[i] = _C.tTm[i - 1]
                end
                _C.tTm[1] = tm
                _C.nTmFrameCount = GetLogicFrameCount()
            end
            local tm = _C.tTm[GLOBAL.GAME_FPS]
            if tm then
                s = 1000 * (GetLogicFrameCount() - tm.frame) / GLOBAL.GAME_FPS / (GetTickCount() - tm.tick)
            end
            return string.format(MY_InfoTip.Cache.TimeMachine.formatString, s)
        end
    },
    Distance  = { -- 目标距离
        formatString = '', title = _L['target distance'], prefix = _L['Distance: '], content = _L['%.1f Foot'],
        GetContent = function()
            local p, s = LIB.GetObject(LIB.GetTarget()), _L['No Target']
            if p then
                s = string.format(MY_InfoTip.Cache.Distance.formatString, LIB.GetDistance(p))
            end
            return s
        end
    },
    SysTime   = { -- 系统时间
        formatString = '', title = _L['system time'], prefix = _L['Time: '], content = _L['%02d:%02d:%02d'],
        GetContent = function()
            local tDateTime = TimeToDate(GetCurrentTime())
            return string.format(MY_InfoTip.Cache.SysTime.formatString, tDateTime.hour, tDateTime.minute, tDateTime.second)
        end
    },
    FightTime = { -- 战斗计时
        formatString = '', title = _L['fight clock'], prefix = _L['Fight Clock: '], content = '',
        GetContent = function()
            if LIB.GetFightUUID() or LIB.GetLastFightUUID() then
                return MY_InfoTip.Cache.FightTime.formatString .. LIB.GetFightTime('H:mm:ss')
            else
                return _L['Never Fight']
            end
        end
    },
    LotusTime = { -- 莲花和藕倒计时
        formatString = '', title = _L['lotus clock'], prefix = _L['Lotus Clock: '], content = _L['%d:%d:%d'],
        GetContent = function()
            local nTotal = 6*60*60 - GetLogicFrameCount()/16%(6*60*60)
            return string.format(MY_InfoTip.Cache.LotusTime.formatString, math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
        end
    },
    GPS = { -- 角色坐标
        formatString = '', title = _L['GPS'], prefix = _L['Location: '], content = _L['[%d]%d,%d,%d'],
        GetContent = function()
            local player, text = GetClientPlayer(), ''
            if player then
                text = string.format(MY_InfoTip.Cache.GPS.formatString, player.GetMapID(), player.nX, player.nY, player.nZ)
            end
            return text
        end
    },
    Speedometer = { -- 角色速度
        formatString = '', title = _L['speedometer'], prefix = _L['Speed: '], content = _L['%.2f f/s'],
        GetContent = function()
            local s = 0
            local me = GetClientPlayer()
            if me and _C.nSmFrameCount ~= GetLogicFrameCount() then
                local sm = _C.tSm[GLOBAL.GAME_FPS] or {}
                sm.framecount = GetLogicFrameCount()
                sm.x, sm.y, sm.z = me.nX, me.nY, me.nZ
                for i = GLOBAL.GAME_FPS, 1, -1 do
                    _C.tSm[i] = _C.tSm[i - 1]
                end
                _C.tSm[1] = sm
                _C.nSmFrameCount = GetLogicFrameCount()
            end
            local sm = _C.tSm[GLOBAL.GAME_FPS]
            if sm and me then
                s = math.sqrt(math.pow(me.nX - sm.x, 2) + math.pow(me.nY - sm.y, 2) + math.pow((me.nZ - sm.z) / 8, 2)) / 64
                    / (GetLogicFrameCount() - sm.framecount) * GLOBAL.GAME_FPS
            end
            return string.format(MY_InfoTip.Cache.Speedometer.formatString, s)
        end
    },
}
local _SZ_CONFIG_FILE_ = {'config/infotip.jx3dat', PATH_TYPE.ROLE}
local _Cache = {}
local SaveConfig = function() LIB.SaveLUAData(_SZ_CONFIG_FILE_, MY_InfoTip.Config) end
local LoadConfig = function()
    local szOrgFile = LIB.GetLUADataPath({'config/MY_INFO_TIP/{$uid}.{$lang}.jx3dat', PATH_TYPE.DATA})
    local szFilePath = LIB.GetLUADataPath(_SZ_CONFIG_FILE_)
    if IsLocalFileExist(szOrgFile) then
        CPath.Move(szOrgFile, szFilePath)
    end
    local config = LIB.LoadLUAData(szFilePath)
    if config then
        if not MY_InfoTip.Config then
            MY_InfoTip.Config = {}
        end
        for k, v in pairs(config) do
            MY_InfoTip.Config[k] = config[k] or MY_InfoTip.Config[k]
        end
    end
end
LIB.RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT', function()
    for k, v in pairs(Config_Default) do
        MY_InfoTip.Config[k].anchor = v.anchor
    end
    MY_InfoTip.Reload()
end)
-- 显示信息条
MY_InfoTip.Reload = function()
    for id, cache in pairs(MY_InfoTip.Cache) do
        local cfg = MY_InfoTip.Config[id]
        local frm = UI('Normal/MY_InfoTip_'..id)
        if cfg.bEnable then
            if frm:Count()==0 then
                frm = UI.CreateFrame('MY_InfoTip_'..id, {empty = true}):Size(220,30):Event('UI_SCALED', function()
                    UI(this):Anchor(cfg.anchor)
                end):CustomMode(cache.title, function(anchor)
                    UI(this):BringToTop()
                    cfg.anchor = anchor
                    SaveConfig()
                end, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end):Drag(0,0,0,0):Drag(false):Penetrable(true)
                frm:Append('Image', 'Image_Default'):Size(220,30):Image('UI/Image/UICommon/Commonpanel.UITex',86):Alpha(180)
                frm:Append('Text', 'Text_Default'):Size(220,30):Text(cache.title):Font(2)[1]:SetHAlign(1)
                local txt = frm:Find('#Text_Default')
                frm:Breathe(function() txt:Text(cache.GetContent()) end)
            end
            if cfg.bShowBg then
                frm:Find('#Image_Default'):Show()
            else
                frm:Find('#Image_Default'):Hide()
            end
            if cfg.bShowTitle then
                cache.formatString = _L[cache.prefix] .. _L[cache.content]
            else
                cache.formatString = _L[cache.content]
            end
            frm:Children('#Text_Default'):Font(cfg.nFont or 0):Color(cfg.rgb or {255,255,255})
            frm:Anchor(cfg.anchor)
        else
            frm:Remove()
        end
    end
    SaveConfig()
end
-- 注册INIT事件
LIB.RegisterInit('MY_INFOTIP', function()
    LoadConfig()
    MY_InfoTip.Reload()
end)


LIB.RegisterPanel( 'MY_InfoTip', _L['infotip'], _L['System'], 'ui/Image/UICommon/ActivePopularize2.UITex|22', { OnPanelActive = function(wnd)
    local ui = UI(wnd)
    local w, h = ui:Size()
    local x, y = 50, 20

    ui:Append('Text', 'Text_InfoTip')
      :Pos(x, y):Width(350)
      :Text(_L['* infomation tips']):Color(255,255,0)
    y = y + 5

    for id, cache in pairs(MY_InfoTip.Cache) do
        x, y = 55, y + 30

        local cfg = MY_InfoTip.Config[id]
        ui:Append('WndCheckBox', 'WndCheckBox_InfoTip_'..id):Pos(x, y):Width(250)
          :Text(cache.title):Check(cfg.bEnable or false)
          :Check(function(bChecked)
            cfg.bEnable = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 220
        ui:Append('WndCheckBox', 'WndCheckBox_InfoTipTitle_'..id):Pos(x, y):Width(60)
          :Text(_L['title']):Check(cfg.bShowTitle or false)
          :Check(function(bChecked)
            cfg.bShowTitle = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 70
        ui:Append('WndCheckBox', 'WndCheckBox_InfoTipBg_'..id):Pos(x, y):Width(60)
          :Text(_L['background']):Check(cfg.bShowBg or false)
          :Check(function(bChecked)
            cfg.bShowBg = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 70
        ui:Append('WndButton', 'WndButton_InfoTipFont_'..id):Pos(x, y)
          :Width(50):Text(_L['font'])
          :Click(function()
            UI.OpenFontPicker(function(f)
                cfg.nFont = f
                MY_InfoTip.Reload()
            end)
          end)
        x = x + 60
        ui:Append('Shadow', 'Shadow_InfoTipColor_'..id):Pos(x, y)
          :Size(20, 20):Color(cfg.rgb or {255,255,255})
          :Click(function()
            local me = this
            UI.OpenColorPicker(function(r, g, b)
                UI(me):Color(r, g, b)
                cfg.rgb = { r, g, b }
                MY_InfoTip.Reload()
            end)
          end)
    end
end})
