--
-- 科举助手
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
--
-- 主要功能: 科举助手
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."ExamTip/lang/")
local _Cache = {
    szQueryUrl = "http://jx3.derzh.com/exam/?l=%s&q=%s",
    szSubmitUrl = "http://jx3.derzh.com/exam/submit.php?l=%s&d=%s",
    tCached = {},
    tLastQu = "",
}
MY_ExamTip = {}

-- 获取题目和答案
MY_ExamTip.QueryData = function(szQues)
    if _Cache.tLastQu == szQues then
        return nil
    end
    
    _Cache.tLastQu = szQues
    MY_ExamTip.ShowResult(szQues, nil, _L["Querying, please wait..."])
    local _, _, szLang, _ = GetVersion()
    MY.RemoteRequest(string.format(_Cache.szQueryUrl, szLang, MY.String.UrlEncode(szQues)), function(szTitle, szContent)
        local data = MY.Json.Decode(szContent)
        if not data then
            return nil
        end
        
        local szTip = ''
        local UrlDecode = function(szText) return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end) end
        for _, p in ipairs(data.result) do
            szTip = szTip .. p.szQues .. '\n' .. p.szAnsw
        end
        szTip = UrlDecode(szTip)
        
        if #data.result == 0 then
            szTip = _L["No result found. Here's from open search engine:"].."\n" .. szTip
        else
            MY_ExamTip.ShowResult(UrlDecode(data.question), UrlDecode(data.result[1].szAnsw), szTip)
        end
        
    end, function()
        MY_ExamTip.ShowResult(_Cache.tLastQu, nil, _L['Loading failed.'])
        _Cache.tLastQu = ""
    end, 10000)
end
-- 提交玩家正确答案 -- 云数据来源
MY_ExamTip.SubmitData = function()
    local _, _, szLang, _ = GetVersion()
    MY_Anmerkungen.szNotePanelContent = string.format(_Cache.szSubmitUrl, szLang, MY.String.UrlEncode(MY.Json.Encode(_Cache.tCached)))
    MY.RemoteRequest(string.format(_Cache.szSubmitUrl, szLang, MY.String.UrlEncode(MY.Json.Encode(_Cache.tCached))), function(szTitle, szContent)
        local r = MY.Json.Decode(szContent)
        MY.Sysmsg({_L('%s record(s) commited, %s record(s) accepted!', r.received, r.accepted)}, _L['exam tip'])
    end)
end
-- 显示结果
MY_ExamTip.ShowResult = function(szQues, szAnsw, szTip)
    local hQues = Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0)
    local hTxt1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1",'Text_T1No1')
    local hChk1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1")
    local hTxt2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2",'Text_T1No2')
    local hChk2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2")
    local hTxt3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3",'Text_T1No3')
    local hChk3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3")
    local hTxt4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4",'Text_T1No4')
    local hChk4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4")
    
    if hQues:GetText() ~= szQues then
        return false
    end
    hTxt1:SetFontColor(0, 0, 0)
    hTxt2:SetFontColor(0, 0, 0)
    hTxt3:SetFontColor(0, 0, 0)
    hTxt4:SetFontColor(0, 0, 0)
    
    if hTxt1:GetText() == szAnsw then
        hTxt1:SetFontColor(255, 255, 0)
        hChk1:Check(true)
    elseif hTxt2:GetText() == szAnsw then
        hTxt2:SetFontColor(255, 255, 0)
        hChk2:Check(true)
    elseif hTxt3:GetText() == szAnsw then
        hTxt3:SetFontColor(255, 255, 0)
        hChk3:Check(true)
    elseif hTxt4:GetText() == szAnsw then
        hTxt4:SetFontColor(255, 255, 0)
        hChk4:Check(true)
    end
end
-- 收集结果
MY_ExamTip.CollectResult = function()
    local hQues = Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0)
    local hTxt1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1",'Text_T1No1')
    local hChk1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1")
    local hTxt2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2",'Text_T1No2')
    local hChk2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2")
    local hTxt3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3",'Text_T1No3')
    local hChk3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3")
    local hTxt4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4",'Text_T1No4')
    local hChk4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4")
    
    local szQues = hQues:GetText()
    local szAnsw
    
    if hChk1:IsCheckBoxChecked() then
        szAnsw = hTxt1:GetText()
    elseif hChk2:IsCheckBoxChecked() then
        szAnsw = hTxt2:GetText()
    elseif hChk3:IsCheckBoxChecked() then
        szAnsw = hTxt3:GetText()
    elseif hChk4:IsCheckBoxChecked() then
        szAnsw = hTxt4:GetText()
    end
    
    if szQues and szAnsw then
        _Cache.tCached[szQues] = szAnsw
    end
end
-- 时钟监控
_Cache.OnFrameBreathe = function()
    local frame = Station.Lookup("Normal/ExaminationPanel")
    if not (frame and frame:IsVisible()) then
        return nil
    end
    
    local szQues = Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0):GetText()
    MY_ExamTip.QueryData(szQues)
    MY_ExamTip.CollectResult(szQues)
    _Cache.nExamPrintRemainSpace = GetClientPlayer().GetExamPrintRemainSpace()
end
-- 注册INIT事件
MY.RegisterInit(function()
    MY.BreatheCall(_Cache.OnFrameBreathe)
    MY.RegisterEvent("BAG_ITEM_UPDATE", function()
        local item = GetClientPlayer().GetItem(arg0, arg1)
        if item and item.szName == '会试行文' then
            local nExamPrintRemainSpace = _Cache.nExamPrintRemainSpace
            MY.DelayCall(function()
                if nExamPrintRemainSpace - GetClientPlayer().GetExamPrintRemainSpace() == 100  then
                    MY_ExamTip.SubmitData()
                end
            end, 2000)
        end
    end)
end)