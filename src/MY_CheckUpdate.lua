MY.RegisterEvent("LOADING_END", function() MY.RemoteRequest("https://raw.githubusercontent.com/tinymins/Jx3Interface/master/list.json", function(szTitle,szContent)
    local szVersion, nVersion = MY.GetVersion()
    Output(szTitle) Output(szContent) 
end)end)