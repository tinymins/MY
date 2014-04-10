MY.RegisterEvent("LOADING_END", function() MY.RemoteRequest("https://rawgithub.com/tinymins/JX3MY/master/version.html", function(szTitle,szContent)
    local szVersion, nVersion = MY.GetVersion()
    Output(szTitle) Output(szContent) 
end)end)