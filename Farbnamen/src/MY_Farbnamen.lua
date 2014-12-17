--
-- 聊天窗口名称染色插件
-- By 茗伊@双梦镇@荻花宫
-- ZhaiYiMing.CoM
-- 2014年5月19日05:07:02
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Farbnamen/lang/")
local _SUB_ADDON_FOLDER_NAME_ = "Farbnamen"
---------------------------------------------------------------
-- 设置和数据
---------------------------------------------------------------
MY_Farbnamen = MY_Farbnamen or {
    bEnabled = true,
}
RegisterCustomData("Account\\MY_Farbnamen.bEnabled")
local SZ_CONFIG_PATH = "config/PLAYER_FORCE_COLOR"
local SZ_CACHE_PATH = "cache/PLAYER_INFO/" .. (MY.Game.GetServer())
local Config_Default = {
    nMaxCache= 200,
    tForceColor  = MY.LoadLUAData(SZ_CONFIG_PATH, true) or {
        [0]  = { 255, 255, 255 },       --江湖
        [1]  = { 255, 178, 95  },       --少林
        [2]  = { 196, 152, 255 },       --万花
        [3]  = { 255, 111, 83  },       --天策
        [4]  = { 89 , 224, 232 },       --纯阳
        [5]  = { 255, 129, 176 },       --七秀
        [6]  = { 55 , 147, 255 },       --五毒
        [7]  = { 121, 183, 54  },       --唐门
        [8]  = { 214, 249, 93  },       --藏剑
        [9]  = { 205, 133, 63  },       --丐帮
        [10] = { 240, 70 , 96  },       --明教
        [21] = { 180, 60 , 0   },       --苍云
    },
}
local Config = clone(Config_Default)
local _MY_Farbnamen = {
    tForceString = {},
    tRoleType    = {
        [1] = _L['man'],
        [2] = _L['woman'],
        [5] = _L['boy'],
        [6] = _L['girl'],
    },
    tCampString  = {},
    tPlayerCache = {},
    aPlayerQueu = {},
}
for k, v in pairs(g_tStrings.tForceTitle) do
    _MY_Farbnamen.tForceString[k] = v
end
for k, v in pairs(g_tStrings.STR_GUILD_CAMP_NAME) do
    _MY_Farbnamen.tCampString[k] = v
end
setmetatable(_MY_Farbnamen.tForceString, { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tRoleType,    { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tCampString,  { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
-- 插入聊天内容的 HOOK （过滤、加入时间 ）
MY.Chat.HookChatPanel(function(h, szMsg)
    if not MY_Farbnamen.bEnabled then
        return nil
    end
    szMsg = MY_Farbnamen.Render(szMsg)
    
    return szMsg
end)
--[[ 开放的名称染色接口
    (userdata) MY_Farbnamen.Render(userdata namelink)    处理namelink染色 namelink是一个姓名Text元素
    (string) MY_Farbnamen.Render(string szMsg)           格式化szMsg 处理里面的名字
]]
MY_Farbnamen.Render = function(szMsg)
    if type(szMsg) == 'string' then
        -- <text>text="[就是个阵眼]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=515</text><text>text="说：" font=10 r=255 g=255 b=255 </text><text>text="[茗伊]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=771</text><text>text="\n" font=10 r=255 g=255 b=255 </text>
        local xml = MY.Xml.Decode(szMsg)
        if xml then
            for _, ele in ipairs(xml) do
                if ele[''].name and ele[''].name:sub(1, 9) == 'namelink_' then
                    local szName = string.gsub(ele[''].text, '[%[%]]', '')
                    local tInfo = MY_Farbnamen.GetAusName(szName)
                    if tInfo then
                        ele[''].r = tInfo.rgb[1]
                        ele[''].g = tInfo.rgb[2]
                        ele[''].b = tInfo.rgb[3]
                        ele[''].eventid = 883
                        if ele[''].script then
                            ele[''].script = ele[''].script .. '\n'
                        else
                            ele[''].script = ''
                        end
                        ele[''].script = ele[''].script .. 'this.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end'
                    end
                end
            end
            szMsg = MY.Xml.Encode(xml)
        end
        -- szMsg = string.gsub( szMsg, '<text>([^<]-)text="([^<]-)"([^<]-name="namelink_%d-"[^<]-)</text>', function (szExtra1, szName, szExtra2)
        --     szName = string.gsub(szName, '[%[%]]', '')
        --     local tInfo = MY_Farbnamen.GetAusName(szName)
        --     if tInfo then
        --         szExtra1 = string.gsub(szExtra1, '[rgb]=%d+', '')
        --         szExtra2 = string.gsub(szExtra2, '[rgb]=%d+', '')
        --         szExtra1 = string.gsub(szExtra1, 'eventid=%d+', '')
        --         szExtra2 = string.gsub(szExtra2, 'eventid=%d+', '')
        --         return string.format(
        --             '<text>%stext="[%s]"%s eventid=883 script="this.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end" r=%d g=%d b=%d</text>',
        --             szExtra1, szName, szExtra2, tInfo.rgb[1], tInfo.rgb[2], tInfo.rgb[3]
        --         )
        --     end
        -- end)
    elseif type(szMsg) == 'table' and type(szMsg.GetName) == 'function' and szMsg:GetName():sub(1, 8) == 'namelink' then
        local namelink = szMsg
        local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
        local tInfo = MY_Farbnamen.GetAusName(szName)
        if tInfo then
            -- 名称 等级
            local szTip = string.format('%s(%d)', tInfo.szName, tInfo.nLevel)
            -- 称号
            if tInfo.szTitle and #tInfo.szTitle > 0 then
                szTip = string.format('%s\n%s', szTip, tInfo.szTitle)
            end
            -- 帮会
            if tInfo.szTongID and #tInfo.szTongID > 0 then
                szTip = string.format('%s\n[%s]', szTip, tInfo.szTongID)
            end
            -- 门派 体型 阵营
            szTip = string.format('%s\n%s·%s·%s', szTip, _MY_Farbnamen.tForceString[tInfo.dwForceID], _MY_Farbnamen.tRoleType[tInfo.nRoleType], _MY_Farbnamen.tCampString[tInfo.nCamp])
            -- 绑定tip提示
            MY.UI(namelink):tip(szTip, MY.Const.UI.Tip.POS_TOP):color(tInfo.rgb)
        end
    end
    
    return szMsg
end
-- 显示Tip
MY_Farbnamen.ShowTip = function(namelink)
    local x, y, w, h = 0, 0, 0, 0
    namelink = namelink or this
    if not namelink then
        return
    end
    local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
    x, y = namelink:GetAbsPos()
    w, h = namelink:GetSize()
    
    local tInfo = MY_Farbnamen.GetAusName(szName)
    if tInfo then
        local tTip = {}
        -- 名称 等级
        table.insert(tTip, string.format('%s(%d)', tInfo.szName, tInfo.nLevel))
        -- 称号
        if tInfo.szTitle and #tInfo.szTitle > 0 then
            table.insert(tTip, tInfo.szTitle)
        end
        -- 帮会
        if tInfo.szTongID and #tInfo.szTongID > 0 then
            table.insert(tTip, '[' .. tInfo.szTongID .. ']')
        end
        -- 门派 体型 阵营
        table.insert(tTip, string.format('%s·%s·%s', _MY_Farbnamen.tForceString[tInfo.dwForceID], _MY_Farbnamen.tRoleType[tInfo.nRoleType], _MY_Farbnamen.tCampString[tInfo.nCamp]))
        
        local bAuthor = false
        for i, v in pairs(MY.GetAddonInfo().tAuthor) do
            if tInfo.dwID == i and tInfo.szName == v then
                bAuthor = true
                break
            end
        end

        if MY_Anmerkungen then
            local tPlayerNote = MY_Anmerkungen.GetPlayerNote(tInfo.dwID)
            if tPlayerNote then
                table.insert(tTip, tPlayerNote.szContent)
            end
        end

        local szTip
        if bAuthor then
            szTip = GetFormatText(_L['[mingyi plugins]'], 11, 0, 255, 0)
                 .. GetFormatText(' ', 136)
                 .. GetFormatText(_L['author']..'\n', 230, 0, 255, 0)
                 .. GetFormatText('     ' .. table.concat(tTip, '\n     '), 136)
        else
            szTip = GetFormatText(table.concat(tTip, '\n'), 136, nil, nil, nil)
        end

        OutputTip(szTip, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
    end
end
-- 处理插件冲突
function MY_Farbnamen.DoConflict()
    if MY_Farbnamen.bEnabled and Chat and Chat.bColor then
        Chat.bColor = false
        MY.Sysmsg({_L['plugin conflict detected,duowan force color has been forced down.'], r=255, g=0, b=0},_L['MingYiPlugin - Farbnamen'])
    end
end
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
-- 通过szName获取信息
function MY_Farbnamen.GetAusName(szName)
    return MY_Farbnamen.GetAusID(_MY_Farbnamen.tPlayerCache[szName])
end
-- 通过dwID获取信息
function MY_Farbnamen.GetAusID(dwID)
    MY_Farbnamen.AddAusID(dwID)
    -- deal with return data
    local result =  clone(_MY_Farbnamen.tPlayerCache[dwID])
    if result then
        result.rgb = Config.tForceColor[result.dwForceID] or {255, 255, 255}
    end
    return result
end
-- 保存指定dwID的玩家
function MY_Farbnamen.AddAusID(dwID)
    local player = GetPlayer(dwID)
    if player and player.szName and player.szName~='' then
        local tPlayer = {
            dwID      = player.dwID,
            dwForceID = player.dwForceID,
            szName    = player.szName,
            nRoleType = player.nRoleType,
            nLevel    = player.nLevel,
            szTitle   = player.szTitle,
            nCamp     = player.nCamp,
            szTongID  = GetTongClient().ApplyGetTongName(player.dwTongID),
            dwTime    = GetCurrentTime(),
        }
        
        _MY_Farbnamen.tPlayerCache[player.dwID  ] = tPlayer
        _MY_Farbnamen.tPlayerCache[player.szName] = player.dwID
        return true
    else
        return false
    end
end
-- 保存用户设置
function _MY_Farbnamen.SaveCustomData()
    local t = {}
    t.tForceColor = Config.tForceColor
    MY.Sys.SaveUserData(SZ_CONFIG_PATH, t)
end
-- 加载用户配置
function _MY_Farbnamen.LoadCustomData()
    local t = MY.Sys.LoadUserData(SZ_CONFIG_PATH) or {}
    if t.tForceColor then
        for k, v in pairs(t.tForceColor) do
            Config.tForceColor[k] = v
        end
    end
end
-- 保存配置
function MY_Farbnamen.SaveData()
    local t = {
        ['aCached']   = {}                      ,     -- 保存的用户表
        ['nMaxCache'] = Config.nMaxCache        ,     -- 最大缓存数量
    }
    for dwID, data in pairs(_MY_Farbnamen.tPlayerCache) do
        if type(dwID)=='number' then
            table.insert(t.aCached, data)
        end
    end
    if #t.aCached > t.nMaxCache then
        table.sort(t.aCached, function(a, b) return a.dwTime < b.dwTime end)
        for i=t.nMaxCache+1, #t.aCached, 1 do
            table.remove(t.aCached)
        end
    end
    MY.SaveLUAData(SZ_CACHE_PATH, MY.Json.Encode(t))
end
-- 加载配置
function MY_Farbnamen.LoadData()
    -- 读取数据文件
    local data = MY.LoadLUAData(SZ_CACHE_PATH) or {}
    -- 如果是Json格式的数据 则解码
    if type(data)=="string" then
        data = MY.Json.Decode(data) or {}
    end
    -- 解析数据
    local t = {
        ['aCached']   = data.aCached   or {} ,    -- 保存的用户表
        ['nMaxCache'] = data.nMaxCache or 100,    -- 最大缓存数量
    }
    -- 转移旧版本数据
    for i=1, #data, 1 do
        -- 插入缓存列表
        table.insert(t.aCached, data[i])
    end
    
    -- 添加加载的数据
    for _, p in ipairs(t.aCached) do
        _MY_Farbnamen.tPlayerCache[p.dwID] = p
    end
    Config.nMaxCache = t.nMaxCache or Config.nMaxCache
end
--------------------------------------------------------------
-- 数据统计
--------------------------------------------------------------
function MY_Farbnamen.AnalyseForceInfo()
	local t = { }
    -- 统计各门派人数
	for k, v in pairs(_MY_Farbnamen.tPlayerCache) do
		if type(v)=='table' and type(v.dwForceID)=='number' then
			t[v.dwForceID] = ( t[v.dwForceID] or 0 ) + 1
		end
	end
	-- 对table值进行排序
	local t2, nCount = {}, 0
	for k, v in pairs(t) do
		table.insert(t2, {K = k, V = v})
        nCount = nCount + v
	end
	table.sort (t2, function(a, b) return a.V > b.V end)

    -- 输出
	MY.Sysmsg({_L('%d player(s) data cached:', nCount)}, _L['Farbnamen'])
	for k, v in pairs(t2) do
		if type(v.K) == "number" then
			MY.Sysmsg({string.format("%s\t(%s)\t%d", GetForceTitle(v.K), string.format("%02d%%", 100 * (v.V / nCount)), v.V)}, '')
		end
	end
end

--------------------------------------------------------------
-- 菜单
--------------------------------------------------------------
MY_Farbnamen.GetMenu = function()
    local t = {
        szOption = _L["Farbnamen"],
        fnAction = function()
            MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
        end,
        bCheck = true,
        bChecked = MY_Farbnamen.bEnabled
    }
    table.insert(t, {
        szOption = _L['customize color'],
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    for nForce, szForce in pairs(_MY_Farbnamen.tForceString) do
        table.insert(t[#t], {
            szOption = szForce,
            rgb = Config.tForceColor[nForce],
            bColorTable = true,
            fnChangeColor = function(_,r,g,b)
                Config.tForceColor[nForce] = {r,g,b}
                _MY_Farbnamen.SaveCustomData()
            end,
        })
    end
    table.insert(t[#t], { bDevide = true })
    table.insert(t[#t], {
        szOption = _L['load default setting'],
        fnAction = function()
            Config.tForceColor = clone(Config_Default.tForceColor)
            _MY_Farbnamen.SaveCustomData()
        end,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    table.insert(t, {
        szOption = _L["set max cache count"],
        fnAction = function()
            GetUserInputNumber(
                Config.nMaxCache,
                999999, nil,
                function(num)
                    if num > 5000 then
                        MessageBox({
                            szName = "MY_Farbnamen_HighCache",
                            szMessage = _L("Are you sure you want to set cache limit to %d?\nThis may cause some performance problem, please make sure your computer is strong enough.", num),
                            {szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() Config.nMaxCache = num end},
                            {szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end},
                        })
                    else
                        Config.nMaxCache = num
                    end
                end,
                function() end,
                function() end
            )
        end,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    table.insert(t, {
        szOption = _L["analyse data"],
        fnAction = MY_Farbnamen.AnalyseForceInfo,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    table.insert(t, {
        szOption = _L["reset data"],
        fnAction = function()
            _MY_Farbnamen.tPlayerCache = {}
            MY.Sysmsg({_L['cache data deleted.']}, _L['Farbnamen'])
        end,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    return t
end
MY.RegisterPlayerAddonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
MY.RegisterTraceButtonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
--------------------------------------------------------------
-- 注册事件
--------------------------------------------------------------
-- MY.RegisterEvent('LOGIN_GAME', MY_Farbnamen.LoadData)
-- MY.RegisterEvent('PLAYER_ENTER_GAME', MY_Farbnamen.LoadData)
MY.RegisterEvent('FIRST_LOADING_END', MY_Farbnamen.LoadData)
MY.RegisterEvent('FIRST_LOADING_END', _MY_Farbnamen.LoadCustomData)
-- MY.RegisterEvent('GAME_EXIT', MY_Farbnamen.SaveData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_Farbnamen.SaveData)
-- MY.RegisterEvent("PLAYER_ENTER_SCENE", MY_Farbnamen.DoConflict)
MY.RegisterEvent("PLAYER_ENTER_SCENE", function(...)
    if MY_Farbnamen.bEnabled then
        local dwID = arg0
        local nRetryCount = 0
        MY.BreatheCall( function()
            if MY_Farbnamen.AddAusID(dwID) or nRetryCount > 5 then
                return 0
            end
            nRetryCount = nRetryCount + 1
        end, 500 )
    end
end)