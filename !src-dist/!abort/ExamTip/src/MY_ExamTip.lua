--
-- 科举助手
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
--
-- 主要功能: 科举助手
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."ExamTip/lang/")
local _Cache = {
    szQueryUrl = "http://jx3-my.aliapp.com/exam/?p=%s",
    tCached = {},
    tLastQA = {},
    szTipContent = nil,
}
MY_ExamTip = {}
MY_ExamTip.bAutoTip = false
RegisterCustomData("MY_ExamTip.bAutoTip")

-- 获取题目和答案
_Cache.BeginQueryData = function(szQues, callback)
    _Cache.szTipContent = _L["Querying, please wait..."]
    MY.RemoteRequest(string.format(szQueryUrl, MY.String.UrlEncode(szQues)), function(szTitle, szContent)
        if szTitle == "F" then
            _Cache.szTipContent = _L["No result found. Here's from open search engine:"].."\n"
        end
        _Cache.szTipContent = _Cache.szTipContent..szContent
    end, function()
        _Cache.szTipContent = _L['Loading failed.']
    end, 10000)
end
-- 提交玩家正确答案 -- 云数据来源
_Cache.BeginSubmitData = function(szQues, szAnsw, callback)
    Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0):GetText()
end
-- 显示结果
_Cache.ShowTip = function()
    
end
-- 注册INIT事件
MY.RegisterInit(function()
    -- 创建菜单
    local tMenu = function() return {
        szOption = _L["exam tip"],
        bCheck = true,
        bChecked = MY_ExamTip.bAutoTip,
    } end
    MY.RegisterPlayerAddonMenu( 'MY_EXAMTIP_MENU', tMenu)
    MY.RegisterTraceButtonMenu( 'MY_EXAMTIP_MENU', tMenu)
end)