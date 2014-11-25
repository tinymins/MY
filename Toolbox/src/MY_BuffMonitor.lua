--[[
#######################################################################################################
                                                          *     *           *         *           
                                                    *     *     *           *           *         
  * * * *     * *     * * * * * * *   * * * * *     *     *     * * * *     *     * * * * * * *   
    *     *     *     *     *     *     *     *     *     *   *           * * *   *           *   
    *     *     *     *     *   *       *   *       *     * *     *         *         *   *       
    * * *       *     *     * * *       * * *             *         *       *       *       *     
    *     *     *     *     *   *       *   *                               * *   *           *   
    *     *     *     *     *           *           * * * * * * * * *     * *       * * * * *     
    *     *     *     *     *           *           *     *   *     *       *           *         
  * * * *         * *     * * *       * * *         *     *   *     *       *           *         
                                                    *     *   *     *       *           *         
                                                  * * * * * * * * * * *   * *     * * * * * * *  
#######################################################################################################
]]
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _DEFAULT_BUFFMONITOR_CONFIG_FILE_ = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon_default"
local _Cache = {}
_Cache.handleBoxs = { Self = {}, Target = {} }
MY_BuffMonitor = MY_BuffMonitor or {}

MY_BuffMonitor.bSelfOn = false
MY_BuffMonitor.bTargetOn = false
MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
MY_BuffMonitor.tBuffList = MY.LoadLUAData(_DEFAULT_BUFFMONITOR_CONFIG_FILE_)
RegisterCustomData("MY_BuffMonitor.bSelfOn")
RegisterCustomData("MY_BuffMonitor.bTargetOn")
RegisterCustomData("MY_BuffMonitor.anchorSelf")
RegisterCustomData("MY_BuffMonitor.anchorTarget")
RegisterCustomData("MY_BuffMonitor.tBuffList")
-- 重置默认设置
MY_BuffMonitor.ReloadDefaultConfig = function()
    MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
    MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
    MY_BuffMonitor.tBuffList = MY.LoadLUAData(_DEFAULT_BUFFMONITOR_CONFIG_FILE_)
    MY_BuffMonitor.ReloadBuffMonitor()
end
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
    MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
    MY.UI("Normal/MY_BuffMonitor_Self"):anchor(MY_BuffMonitor.anchorSelf)
    MY.UI("Normal/MY_BuffMonitor_Target"):anchor(MY_BuffMonitor.anchorTarget)
end)
-- 初始化UI
MY_BuffMonitor.ReloadBuffMonitor = function()
    -- unregister render function
    MY.BreatheCall("MY_BuffMonitor_Render_Self")
    MY.BreatheCall("MY_BuffMonitor_Render_Target")
    MY.UI("Normal/MY_BuffMonitor_Self"):remove()
    MY.UI("Normal/MY_BuffMonitor_Target"):remove()
    -- get kungfu id
    local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
    -- functions
    local refreshObjectBuff = function(target, tBuffMonList, handleBoxs)
        local me = GetClientPlayer()
        local nCurrentFrame = GetLogicFrameCount()
        if target then
            -- update buff info
            for _, buff in ipairs(MY.Player.GetBuffList(target)) do
                buff.szName = Table_GetBuffName(buff.dwID, buff.nLevel)
                local nBuffTime, _ = GetBuffTime(buff.dwID, buff.nLevel)
                for _, mon in ipairs(tBuffMonList) do
                    if buff.szName == mon.szName and (buff.dwSkillSrcID == me.dwID or target.dwID == me.dwID) and mon.bOn then
                        mon.nRenderFrame = nCurrentFrame
                        mon.dwIconID = Table_GetBuffIconID(buff.dwID, buff.nLevel)
                        local box = handleBoxs[mon.szName]

                        local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - GetLogicFrameCount()) / 16)

                        box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
                        box:SetOverTextFontScheme(1, 15)
                        box:SetOverText(1, nTimeLeft.."'")

                        if buff.nStackNum == 1 then
                            box:SetOverText(0, "")
                        else
                            box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
                            box:SetOverTextFontScheme(0, 15)
                            box:SetOverText(0, buff.nStackNum)
                        end

                        box:SetObject(1,0)
                        box:SetObjectIcon(mon.dwIconID)

                        local dwPercent = nTimeLeft / ( nBuffTime / 16 )
                        box:SetCoolDownPercentage(dwPercent)
                        
                        if dwPercent < 0.5 and dwPercent > 0.3 then
                            if box.dwPercent ~= 0.5 then
                                box.dwPercent = 0.5
                                box:SetObjectStaring(true)
                            end
                        elseif dwPercent < 0.3 and dwPercent > 0.1 then
                            if box.dwPercent ~= 0.3 then
                                box.dwPercent = 0.3
                                box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 17)
                            end
                        elseif dwPercent < 0.1 then
                            if box.dwPercent ~= 0.1 then
                                box.dwPercent = 0.1
                                box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 20)
                            end
                        else
                            box:SetObjectStaring(false)
                            box:ClearExtentAnimate()
                        end
                    end
                end
            end
        end
        -- update missed buff info
        for _, mon in ipairs(tBuffMonList) do
            if mon.nRenderFrame and mon.nRenderFrame >= 0 and mon.nRenderFrame ~= nCurrentFrame then
                mon.nRenderFrame = -1
                local box = handleBoxs[mon.szName]
                box.dwPercent = 0
                box:SetCoolDownPercentage(0)
                box:SetOverText(0, "")
                box:SetOverText(1, "")
                box:SetObjectStaring(false)
                box:ClearExtentAnimate()
                box:SetObjectSparking(true)
            end
        end
    end
    -- check if enable
    if MY_BuffMonitor.bSelfOn then
        -- create frame
        local ui = MY.UI.CreateFrame("MY_BuffMonitor_Self", true):drag(false)
        -- draw boxes
        local nCount = 0
        for _, mon in ipairs(MY_BuffMonitor.tBuffList[dwKungFuID].Self) do
            if mon.bOn then
                ui:append("Image_Mask_"..mon.szName, "Image"):item("#Image_Mask_"..mon.szName):pos(52 * nCount,0):size(50, 50):image("UI/Image/Common/Box.UITex", 43)
                local box = ui:append("Box_"..mon.szName, "Box"):item("#Box_"..mon.szName):pos(52 * nCount + 3, 3):size(44,44):raw(1)
                
                box:SetObject(1,0)
                box:SetObjectIcon(mon.dwIconID)
                box:SetObjectCoolDown(1)
                box:SetOverText(0, "")
                box:SetOverText(1, "")
                box.dwPercent = 0
                
                _Cache.handleBoxs.Self[mon.szName] = box
                
                nCount = nCount + 1
            end
        end
        ui:size(nCount * 52, 52):anchor(MY_BuffMonitor.anchorSelf)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_BuffMonitor.anchorSelf)
          end):customMode(_L['mingyi self buff monitor'], function(anchor)
            MY_BuffMonitor.anchorSelf = anchor
          end, function(anchor)
            MY_BuffMonitor.anchorSelf = anchor
          end):breathe(function()
            -- register render function
            refreshObjectBuff(GetClientPlayer(), MY_BuffMonitor.tBuffList[dwKungFuID].Self, _Cache.handleBoxs.Self)
        end)
    end
    if MY_BuffMonitor.bTargetOn then
        -- create frame
        local ui = MY.UI.CreateFrame("MY_BuffMonitor_Target", true):drag(false)
        -- draw boxes
        local nCount = 0
        for _, mon in ipairs(MY_BuffMonitor.tBuffList[dwKungFuID].Target) do
            if mon.bOn then
                ui:append("Image_Mask_"..mon.szName, "Image"):item("#Image_Mask_"..mon.szName):pos(52 * nCount,0):size(50, 50):image("UI/Image/Common/Box.UITex", 44)
                local box = ui:append("Box_"..mon.szName, "Box"):item("#Box_"..mon.szName):pos(52 * nCount + 3, 3):size(44,44):raw(1)
                
                box:SetObject(1,0)
                box:SetObjectIcon(mon.dwIconID)
                box:SetObjectCoolDown(1)
                box:SetOverText(0, "")
                box:SetOverText(1, "")

                _Cache.handleBoxs.Target[mon.szName] = box
                
                nCount = nCount + 1
            end
        end
        ui:size(nCount * 52, 52):anchor(MY_BuffMonitor.anchorTarget)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_BuffMonitor.anchorTarget)
          end):customMode(_L['mingyi target buff monitor'], function(anchor)
            MY_BuffMonitor.anchorTarget = anchor
          end, function(anchor)
            MY_BuffMonitor.anchorTarget = anchor
          end):breathe(function()
            -- register render function
            refreshObjectBuff(MY.GetObject(MY.GetTarget()), MY_BuffMonitor.tBuffList[dwKungFuID].Target, _Cache.handleBoxs.Target)
        end)
    end
end
MY.RegisterInit(MY_BuffMonitor.ReloadBuffMonitor)
MY.RegisterEvent('SKILL_MOUNT_KUNG_FU', MY_BuffMonitor.ReloadBuffMonitor)