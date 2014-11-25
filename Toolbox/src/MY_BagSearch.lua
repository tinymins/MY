--[[
#######################################################################################################
            #                         #             #               #                 # # # #     
          #   #             # # # # # # # # # #       #             #     #           #           
        #       #           #                                       #       #   # # # # # # # #   
      #           #         #       #                     # # # # # # #         #     #       #   
  # #               # #     # # # # # # # # # #   # # #             #           #     # # #       
      # # # # # #           #     #                   #     #       #     #     # # # #       #   
      #         #           #   #     #               #       #     #       #   #       # # # #   
      #         #           #   # # # # # # #         #       #     #           #     #           
      #         #           #         #               #             #           #       #         
      #     # #     #       # # # # # # # # # #       #         # # #       #   #   #       #     
      #             #       #         #             #   #                 #     # #   #   #   #   
        # # # # # # #     #           #           #       # # # # # # #       #       # # #       
#######################################################################################################
]]
MY_BagSearch = {}
MY_BagSearch.bEnable = true
RegisterCustomData("MY_BagSearch.bEnable")
local _Cache = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
_Cache.OnBreathe = function()
    -- bag
    local chks = {
        Station.Lookup("Normal/BigBagPanel/CheckBox_Totle"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Task"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Equipment"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Drug"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Material"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Book"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Grey"),
    }
    local chkLtd = Station.Lookup("Normal/BigBagPanel/CheckBox_TimeLtd")
    local iptKwd = Station.Lookup("Normal/BigBagPanel/WndEditBox_KeyWord")
    if not MY_BagSearch.bEnable then
        if chkLtd then
            chkLtd:Destroy()
            iptKwd:Destroy()
        end
    elseif chks[7] then
        if not chkLtd then
            local nX, nY = chks[7]:GetRelPos()
            local w, h = chks[7]:GetSize()
            for _, chk in ipairs(chks) do
                chk.OnCheckBoxUncheck = function() _Cache.bBagTimeLtd = false end
            end
            chkLtd = MY.UI("Normal/BigBagPanel")
              :append("CheckBox_TimeLtd", "WndRadioBox"):children("#CheckBox_TimeLtd")
              :text(_L['Time Limited']):size(w,h):pos(nX + chks[7]:Lookup("",""):GetSize(), nY)
              :check(function(bChecked)
                if bChecked then
                    for _, chk in ipairs(chks) do
                        chk:Check(false)
                    end
                    MY.UI(this):check(false)
                end
                _Cache.bBagTimeLtd = bChecked
                _Cache.DoFilterBag()
              end):raw(1)
            MY.UI(chkLtd):item("#Text_Default"):left(20)
        end
        if not iptKwd then
            iptKwd = MY.UI("Normal/BigBagPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_Cache.szBagFilter or ""):size(100,21):pos(60, 30):placeholder(_L['Search'])
              :change(function(txt)
                _Cache.szBagFilter = txt
                _Cache.DoFilterBag()
              end):raw(1)
        end
    end
    -- bank
    local frmBank = Station.Lookup("Normal/BigBankPanel")
    local chkLtd = Station.Lookup("Normal/BigBankPanel/CheckBox_TimeLtd")
    local iptKwd = Station.Lookup("Normal/BigBankPanel/WndEditBox_KeyWord")
    if not MY_BagSearch.bEnable then
        if chkLtd then
            chkLtd:Destroy()
            iptKwd:Destroy()
        end
    elseif frmBank then
        if not chkLtd then
            chkLtd = MY.UI("Normal/BigBankPanel")
              :append("CheckBox_TimeLtd", "WndCheckBox"):children("#CheckBox_TimeLtd")
              :text(_L['Time Limited']):pos(277, 56):check(_Cache.bBankTimeLtd or false)
              :check(function(bChecked)
                _Cache.bBankTimeLtd = bChecked
                _Cache.DoFilterBank()
              end):alpha(200):raw(1)
            _Cache.DoFilterBank()
        end
        if not iptKwd then
            iptKwd = MY.UI("Normal/BigBankPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_Cache.szBankFilter or ""):size(100,21):pos(280, 80):placeholder(_L['Search'])
              :change(function(txt)
                _Cache.szBankFilter = txt
                _Cache.DoFilterBank()
              end):raw(1)
            _Cache.DoFilterBank()
        end
    end
    -- guild bank
    local frmBank = Station.Lookup("Normal/GuildBankPanel")
    local iptKwd = Station.Lookup("Normal/GuildBankPanel/WndEditBox_KeyWord")
    if not MY_BagSearch.bEnable then
        if iptKwd then
            iptKwd:Destroy()
        end
    elseif frmBank then
        if not iptKwd then
            iptKwd = MY.UI("Normal/GuildBankPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_Cache.szGuildBankFilter or ""):size(100,21):pos(60, 25):placeholder(_L['Search'])
              :change(function(txt)
                _Cache.szGuildBankFilter = txt
                _Cache.DoFilterGuildBank()
              end):raw(1)
            _Cache.DoFilterGuildBank()
        end
    end
end
-- 过滤背包
_Cache.DoFilterBag = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _Cache.szBagFilter or _Cache.bBagTimeLtd then
        _Cache.FilterPackage("Normal/BigBagPanel/", _Cache.szBagFilter, _Cache.bBagTimeLtd)
        if _Cache.szBagFilter == "" then
            _Cache.szBagFilter = nil
        end
    end
end
-- 过滤仓库
_Cache.DoFilterBank = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _Cache.szBankFilter or _Cache.bBankTimeLtd then
        _Cache.FilterPackage("Normal/BigBankPanel/", _Cache.szBankFilter, _Cache.bBankTimeLtd)
        if _Cache.szBankFilter == "" then
            _Cache.szBankFilter = nil
        end
    end
end
-- 过滤帮会仓库
_Cache.DoFilterGuildBank = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _Cache.szGuildBankFilter then
        _Cache.FilterGuildPackage("Normal/GuildBankPanel/", _Cache.szGuildBankFilter)
        if _Cache.szGuildBankFilter == "" then
            _Cache.szGuildBankFilter = nil
        end
    end
end
-- 过滤背包原始函数
_Cache.FilterPackage = function(szTreePath, szFilter, bTimeLtd)
    szFilter = szFilter or ""
    local me = GetClientPlayer()
    MY.UI(szTreePath):find(".Box"):each(function(ui)
        if this.bBag then return end
        local dwBox, dwX, bMatch = this.dwBox, this.dwX, true
        local item = me.GetItem(dwBox, dwX)
        if not item then return end
        if not string.find(item.szName, szFilter) then
            bMatch = false
        end
        if bTimeLtd and item:GetLeftExistTime() == 0 then
            bMatch = false
        end
        if bMatch then
            this:SetAlpha(255)
        else
            this:SetAlpha(50)
        end
    end)
end
-- 过滤帮会仓库原始函数
_Cache.FilterGuildPackage = function(szTreePath, szFilter)
    szFilter = szFilter or ""
    local me = GetClientPlayer()
    MY.UI(szTreePath):find(".Box"):each(function(ui)
        local uIID, _, nPage, dwIndex = this:GetObjectData()
        if uIID < 0 then return end
        if not string.find(GetItemNameByUIID(uIID), szFilter) then
            this:SetAlpha(50)
        else
            this:SetAlpha(255)
        end
    end)
end
-- 事件注册
MY.RegisterEvent("BAG_ITEM_UPDATE", _Cache.DoFilterBag)
MY.RegisterEvent("BAG_ITEM_UPDATE", _Cache.DoFilterBank)
MY.RegisterEvent("BAG_ITEM_UPDATE", _Cache.DoFilterGuildBank)
MY.RegisterInit(function() MY.BreatheCall(_Cache.OnBreathe, 130) end)