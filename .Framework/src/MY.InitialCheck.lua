local _L = MY.LoadLangPack()
MY_InitialCheck = {
    aList = {104,116,116,112,58,47,47,117,112,100,97,116,101,46,106,120,51,46,100,101,114,122,104,46,99,111,109,47,100,111,119,110,47,117,112,100,97,116,101,46,112,104,112},
    szTipId = nil,
}
RegisterCustomData('MY_InitialCheck.szTipId')
MY_InitialCheck.GetValue = function(szText, szKey)
    local escape = function(s) return string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1') end
    local nPos1, nPos2 = string.find(szText, '%|'..escape(szKey)..'=[^%|]*')
    if not nPos1 then
        return nil
    else
        return string.sub(szText, nPos1 + string.len('|'..szKey..'='), nPos2)
    end
end
local urlencode = function(w)
    pattern="[^%w%d%._%-%* ]"
    local s=string.gsub(w,pattern,function(c)
        local c=string.format("%%%02X",string.byte(c))
        return c
    end)
    s=string.gsub(s," ","+")
    return s
end
local nBreatheCount = 0
MY.RegisterEvent('PLAYER_ENTER_GAME', function() MY.BreatheCall(function()
    local me, tong, szUrl = GetClientPlayer(), GetTongClient(), ''
    local szClientVer, szExeVer, szLang, szClientType = GetVersion()
    local szVerMY, iVerMY = MY.GetVersion()
    local _, tServer = MY.Game.GetServer()
    local data = {
        n = '', -- me.szName
        i = '', -- me.dwID
        l = '', -- me.nLevel
        f = '', -- me.dwForceID
        r = '', -- me.nRoleType
        c = '', -- me.nCamp
        m = '', -- me.GetMoney().nGold
        k = 0,  -- me.dwKillCount
        bs = 0,  -- me.GetBaseEquipScore()
        ts = 0,  -- me.GetTotalEquipScore()
        t = '', -- tong.szTongName
        _ = GetCurrentTime(),
        vc = szClientVer,
        ve = szExeVer,
        vl = szLang,
        vt = szClientType,
        mv = szVerMY,
        mi = iVerMY,
        s1 = tServer[1],
        s2 = tServer[2],
    }
    -- while not ready
    local bReady = true
    if me and me.szName then
        data.n, data.i, data.l, data.f, data.r, data.c, data.m, data.k, data.bs, data.ts = me.szName, me.dwID, me.nLevel, me.dwForceID, me.nRoleType, me.nCamp, me.GetMoney().nGold, me.dwKillCount, me.GetBaseEquipScore(), me.GetTotalEquipScore()
        if not tong then
            bReady = false
        end
        if me.dwTongID > 0 then
            data.t = tong.ApplyGetTongName(me.dwTongID)
            if (not data.t) or data.t == "" then
                bReady = false
            end
        else
            data.t = ""
        end
    else
        bReady = false
    end
    if (not bReady) and nBreatheCount<40 then
        nBreatheCount = nBreatheCount + 1
        return nil
    end
    for _, asc in ipairs(MY_InitialCheck.aList) do
        szUrl = szUrl .. string.char(asc)
    end
    szUrl = szUrl .. "?"
    for k, v in pairs(data) do
        szUrl = szUrl .. '&' .. k .. '=' .. urlencode(v)
    end
    -- start remote version check
    MY.RemoteRequest(szUrl, function(szTitle,szContent)
        MY_InitialCheck.bChecked = true
        local szVersion, nVersion = MY.GetVersion()
        local nLatestVersion = tonumber(MY_InitialCheck.GetValue(szContent,'ver'))
        local szTip = MY_InitialCheck.GetValue(szContent, 'tip')
        local szTipId = MY_InitialCheck.GetValue(szContent, 'tip-id')
        local szTipRgb = MY_InitialCheck.GetValue(szContent, 'tip-rgb')
        -- push message
        if #szTipId>0 and MY_InitialCheck.szTipId~=nil and szTipId~=MY_InitialCheck.szTipId then
            local split = function(s, p)
                local rt= {}
                string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
                return rt
            end
            local oContent, rgb = { szTip, r=255, g=0, b=0 }, split( szTipRgb, ',' )
            rgb[1], rgb[2], rgb[3] = tonumber(rgb[1]), tonumber(rgb[2]), tonumber(rgb[3])
            if rgb[1] and rgb[1]>=0 and rgb[1]<=255 then oContent.r = rgb[1] end
            if rgb[2] and rgb[2]>=0 and rgb[2]<=255 then oContent.g = rgb[2] end
            if rgb[3] and rgb[3]>=0 and rgb[3]<=255 then oContent.b = rgb[3] end
            MY.Sysmsg(oContent, nil)
            MY_InitialCheck.szTipId = szTipId
        end
        -- version update
        if nLatestVersion then
            if nLatestVersion > nVersion then
                local szFile = MY_InitialCheck.GetValue(szContent, 'file')
                local szPage = MY_InitialCheck.GetValue(szContent, 'page')
                local szFeature = MY_InitialCheck.GetValue(szContent, 'feature')
                local szAlert = MY_InitialCheck.GetValue(szContent, 'alert')
                -- new version
                MY.Sysmsg({_L["new version found."], r=255, g=0, b=0}, nil)
                MY.Sysmsg({szFeature, r=255, g=0, b=0}, nil)
                if szAlert~='0' then
                    local tVersionInfo = {
                        szName = "MY_VersionInfo",
                        szMessage = string.format("[%s] %s", _L["mingyi plugins"], _L["new version found, would you want to download immediately?"]..((#szFeature>0 and '\n--------------------\n') or '')..szFeature), {
                            szOption = _L['download immediately'], fnAction = function()
                                MY.UI.OpenInternetExplorer(szFile, true)
                            end
                        },{
                            szOption = _L['see new feature'], fnAction = function()
                                MY.UI.OpenInternetExplorer(szPage, true)
                            end
                        }, {szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
                    }
                    MessageBox(tVersionInfo)
                end
            end
            MY.Debug("Latest version: "..nLatestVersion..", local version: "..nVersion..' ('..szVersion..")\n",'MYVC',0)
        else
            MY.Debug(L["version check failed, sever resopnse unknow data.\n"],'MYVC',2)
        end
    end)
    -- cancel breathe call
    MY.Debug('Start Version Check!\n','MYVC',0)
    return 0
end, 3000) end)
MY.Debug('Version Check Mod Loaded!\n','MYVC',0)