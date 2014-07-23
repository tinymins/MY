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
local _MY_Farbnamen = {
    nMaxCache= 2000,
    szConfigPath = "config/PLAYER_FORCE_COLOR",
    szDataCache  = "cache/PLAYER_INFO/" .. (MY.Game.GetServer()),
    tForceColor  = {},
    tForceString = {
        [0]  = _L['JiangHu'],
        [1]  = _L['ShaoLin'],
        [2]  = _L['WanHua'],
        [3]  = _L['TianCe'],
        [4]  = _L['ChunYang'],
        [5]  = _L['QiXiu'],
        [6]  = _L['WuDu'],
        [7]  = _L['TangMen'],
        [8]  = _L['CangJian'],
        [9]  = _L['GaiBang'],
        [10] = _L['MingJiao'],
    },
    tRoleType    = {
        [1] = _L['man'],
        [2] = _L['woman'],
        [5] = _L['boy'],
        [6] = _L['girl'],
    },
    tCampString  = {
        [0] = _L['ZhongLi'],
        [1] = _L['HaoQiMeng'],
        [2] = _L['ERenGu'],
    },
    tPlayerCache = {},
    aPlayerQueu = {},
}
setmetatable(_MY_Farbnamen.tForceString, { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tRoleType,    { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tCampString,  { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
-- 插入聊天内容的 HOOK （过滤、加入时间 ）
MY.Chat.HookChatPanel(function(h, szMsg)
    if not MY_Farbnamen.bEnabled then return nil end
    -- change name item event binding: binding mouse in-out event
    szMsg = string.gsub(szMsg, 'eventid=515</', 'eventid=771</')
    -- get current item count
    return szMsg, h:GetItemCount()
end, function(h, szMsg, iPos)
    if not MY_Farbnamen.bEnabled then return nil end
    -- if enabled
    -- color each text item
    for i = iPos, h:GetItemCount(), 1 do
        local h2 = h:Lookup(i)
        -- 判断这个Item是不是人名Text 如果是则处理
        if h2 and h2:GetType() == "Text" and string.find(h2:GetName(), '^namelink_%d+$') then
            -- 取发信玩家的ID加入表
            local szID = string.gsub(h2:GetName(), '%D', '')
            local dwID = tonumber(szID)
            MY_Farbnamen.AddAusID(dwID)
            -- 取玩家的名字
            local szName = string.gsub(h2:GetText(), '[%[%]]', '')
            -- 根据名称获取染色颜色
            local tInfo = MY_Farbnamen.GetAusName(szName)
            -- 如果获取成功则染色
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
                local szTip = string.format('%s\n%s·%s·%s', szTip, _MY_Farbnamen.tForceString[tInfo.dwForceID], _MY_Farbnamen.tRoleType[tInfo.nRoleType], _MY_Farbnamen.tCampString[tInfo.nCamp])
                -- 绑定tip提示
                MY.UI(h2):tip(szTip, MY.Const.UI.Tip.POS_TOP):color(tInfo.rgb)
            end
        end
    end
end)

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
        result.rgb = _MY_Farbnamen.tForceColor[result.dwForceID]
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
    end
end
-- 保存配置
function MY_Farbnamen.SaveData()
    local t = {
        ['aCached']   = {}                      ,     -- 保存的用户表
        ['nMaxCache'] = _MY_Farbnamen.nMaxCache ,     -- 最大缓存数量
    }
    for dwID, data in pairs(_MY_Farbnamen.tPlayerCache) do
        if type(dwID)=='number' then
            table.insert(t.aCached, data)
        end
    end
    if #t.aCached > t.nMaxCache then
        table.sort(t.aCached, function(a, b) return a.dwTime > b.dwTime end)
        for i=t.nMaxCache+1, #t.aCached, 1 do
            table.remove(t.aCached)
        end
    end
    MY.SaveLUAData(_MY_Farbnamen.szDataCache, MY.Json.Encode(t))
end
-- 加载配置
function MY_Farbnamen.LoadData()
    -- 读取数据文件
    local data = MY.LoadLUAData(_MY_Farbnamen.szDataCache) or {}
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
    _MY_Farbnamen.tForceColor = MY.LoadLUAData(_MY_Farbnamen.szConfigPath, true) or _MY_Farbnamen.tForceColor
    _MY_Farbnamen.nMaxCache = t.nMaxCache or _MY_Farbnamen.nMaxCache
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
    return { 
        szOption = _L["Farbnamen"],
        fnAction = function()
            MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
        end,
        bCheck = true,
        bChecked = MY_Farbnamen.bEnabled, {
            szOption = _L["set max cache count"],
            fnAction = function()
                GetUserInputNumber(_MY_Farbnamen.nMaxCache, 10000, nil, function(num) _MY_Farbnamen.nMaxCache = num end, function() end, function() end)
            end,
        },  {
            szOption = _L["analyse data"],
            fnAction = MY_Farbnamen.AnalyseForceInfo,
        },{
            szOption = _L["reset data"],
            fnAction = function()
                _MY_Farbnamen.tPlayerCache = {}
                MY.Sysmsg({_L['cache data deleted.']}, _L['Farbnamen'])
            end,
        }
    }
end
MY.RegisterPlayerAddonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
MY.RegisterTraceButtonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
--------------------------------------------------------------
-- 注册事件
--------------------------------------------------------------
MY.RegisterEvent('LOGIN_GAME', MY_Farbnamen.LoadData)
MY.RegisterEvent('PLAYER_ENTER_GAME', MY_Farbnamen.LoadData)
MY.RegisterEvent('GAME_EXIT', MY_Farbnamen.SaveData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_Farbnamen.SaveData)
MY.RegisterEvent("PLAYER_ENTER_SCENE", MY_Farbnamen.DoConflict)
MY.RegisterEvent("PLAYER_ENTER_SCENE", function(...)
    if MY_Farbnamen.bEnabled then
        local dwID = arg0
        MY.DelayCall( function() MY_Farbnamen.AddAusID(dwID) end, 500 )
    end
end)