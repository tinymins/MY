local _L = MY.LoadLangPack()
MY_CheckUpdate = {
    szUrl = "http://jx3_my.jd-app.com/down/update.php",
    szTipId = nil,
}
RegisterCustomData('MY_CheckUpdate.szTipId')
MY_CheckUpdate.GetValue = function(szText, szKey)
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
    s=string.gsub(w,pattern,function(c)
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
    if me and me.szName then
        data.n, data.i, data.l, data.f, data.r, data.c = me.szName, me.dwID, me.nLevel, me.dwForceID, me.nRoleType, me.nCamp
    end
    if tong and tong.szTongName then
        data.t = tong.szTongName
    end
    if (not (me and tong and me.szName and tong.szTongName)) and nBreatheCount<10 then
        nBreatheCount = nBreatheCount + 1
        return nil
    end
    for k, v in pairs(data) do
        szUrl = szUrl .. '&' .. k .. '=' .. urlencode(v)
    end
    szUrl = string.format("%s?%s", MY_CheckUpdate.szUrl, szUrl)
    -- start remote version check
    MY.RemoteRequest(szUrl, function(szTitle,szContent)
        MY_CheckUpdate.bChecked = true
        local szVersion, nVersion = MY.GetVersion()
        local nLatestVersion = tonumber(MY_CheckUpdate.GetValue(szContent,'ver'))
        local szTip = MY_CheckUpdate.GetValue(szContent, 'tip')
        local szTipId = MY_CheckUpdate.GetValue(szContent, 'tip-id')
        local szTipRgb = MY_CheckUpdate.GetValue(szContent, 'tip-rgb')
        -- push message
        if #szTipId>0 and MY_CheckUpdate.szTipId~=nil and szTipId~=MY_CheckUpdate.szTipId then
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
            MY_CheckUpdate.szTipId = szTipId
        end
        -- version update
        if nLatestVersion then
            if nLatestVersion > nVersion then
                local szFile = MY_CheckUpdate.GetValue(szContent, 'file')
                local szPage = MY_CheckUpdate.GetValue(szContent, 'page')
                local szFeature = MY_CheckUpdate.GetValue(szContent, 'feature')
                local szAlert = MY_CheckUpdate.GetValue(szContent, 'alert')
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
end, 1000) end)
MY.Debug('Version Check Mod Loaded!\n','MYVC',0)