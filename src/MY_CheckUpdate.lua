local _L = MY.LoadLangPack()
MY_CheckUpdate = {
    szUrl = "http://j3my.sinaapp.com/interface/my/latest_version.html",
}
MY_CheckUpdate.bChecked = false
MY_CheckUpdate.GetValue = function(szText, szKey)
    local nPos1, nPos2 = string.find(szText, '%|'..szKey..'=[^%|]*')
    if not nPos1 then
        return nil
    else
        return string.sub(szText, nPos1 + string.len('|'..szKey..'='), nPos2)
    end
end
MY.RegisterEvent("LOADING_END", function() if MY_CheckUpdate.bChecked then return end MY.RemoteRequest(string.format("%s?_=%i", MY_CheckUpdate.szUrl, GetCurrentTime()), function(szTitle,szContent)
    MY_CheckUpdate.bChecked = true
    local szVersion, nVersion = MY.GetVersion()
    local nLatestVersion = tonumber(MY_CheckUpdate.GetValue(szContent,'ver'))
    if nLatestVersion then
        if nLatestVersion > nVersion then
            -- new version
            local szFile = MY_CheckUpdate.GetValue(szContent, 'file')
            local szPage = MY_CheckUpdate.GetValue(szContent, 'page')
            local szFeature = MY_CheckUpdate.GetValue(szContent, 'feature')
            MY.Sysmsg(_L["new version found."]..'\n', nil, { 255, 0, 0})
            MY.Sysmsg(szFeature..'\n', nil, { 255, 0, 0})
            local tVersionInfo = {
                szName = "MY_VersionInfo",
                szMessage = string.format("[%s] %s", _L["mingyi plugins"], _L["new version found, would you want to download immediately?"]), {
                    szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
                        MY.UI.OpenInternetExplorer(szPage, true)
                    end
                },{szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
            }
            MessageBox(tVersionInfo)
        end
        MY.Debug("Latest version: "..nLatestVersion..", local version: "..nVersion..' ('..szVersion..")\n",'MYVC',0)
    else
        MY.Debug(L["version check failed, sever resopnse unknow data.\n"],'MYVC',2)
    end
end) MY.Debug('Start Version Check!\n','MYVC',0) end)
MY.Debug('Version Check Mod Loaded!\n','MYVC',0)