
--[[
##########################################################################################################################
      *         *   *                   *                                   *                           *     *           
      *         *     *         *       *         * * * * * * * * * * *       *     * * * * *           *     *           
      * * *     *                 *     *                           *     * * * *   *       *         *       *       *   
      *         * * * *             *   *                           *           *   *   *   *         *       *     *     
      *     * * *           *           *           * * * * * *     *         *     *   *   *       * *       *   *       
  * * * * *     *   *         *         *           *         *     *         * *   *   *   *     *   *       * *         
  *       *     *   *           *       *           *         *     *       * *   * *   *   *         *       *           
  *       *     *   *                   * * * *     *         *     *     *   *     *   *   *         *     * *           
  *       *       *       * * * * * * * *           * * * * * *     *         *       *   *           *   *   *           
  * * * * *     * *   *                 *           *               *         *       *   *           *       *       *   
  *           *     * *                 *                           *         *     *     *   *       *       *       *   
            *         *                 *                       * * *         *   *         * *       *         * * * *   
##########################################################################################################################
]]
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _Cache = {}
MY_VisualSkill = {}
MY_VisualSkill.bEnable = false
MY_VisualSkill.anchorVisualSkill = { x=0, y=-220, s="BOTTOMCENTER", r="BOTTOMCENTER" }
MY_VisualSkill.nVisualSkillBoxCount = 5
RegisterCustomData("MY_VisualSkill.bEnable")
RegisterCustomData("MY_VisualSkill.anchorVisualSkill")
RegisterCustomData("MY_VisualSkill.nVisualSkillBoxCount")
-- 加载界面
MY_VisualSkill.Reload = function()
    -- distory ui
    MY.UI("Normal/MY_VisualSkill"):remove()
    -- unbind event
    MY.RegisterEvent("DO_SKILL_CAST", "MY_VisualSkillCast")
    -- create new   
    if MY_VisualSkill.bEnable then
        -- create ui
        local ui = MY.UI.CreateFrame("MY_VisualSkill", true)
        ui:size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52):anchor(MY_VisualSkill.anchorVisualSkill)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_VisualSkill.anchorVisualSkill)
          end):customMode(_L['visual skill'], function(anchor)
            MY_VisualSkill.anchorVisualSkill = anchor
          end, function(anchor)
            MY_VisualSkill.anchorVisualSkill = anchor
          end):penetrable(true)
        -- draw background
        local uiL = ui:append("WndWindow_Lowest", "WndWindow"):children("#WndWindow_Lowest"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        uiL:append("Image_Bg_10", "Image"):item("#Image_Bg_10"):pos(0,0):size(130, 52):image("ui/Image/UICommon/Skills.UITex", 28)
        uiL:append("Image_Bg_11", "Image"):item("#Image_Bg_11"):pos(130,0):size( 53 * MY_VisualSkill.nVisualSkillBoxCount - 32, 52):image("ui/Image/UICommon/Skills.UITex", 31)
        uiL:append("Image_Bg_12", "Image"):item("#Image_Bg_12"):pos(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32, 0):size(80, 52):image("ui/Image/UICommon/Skills.UITex", 29)
        -- create skill boxes
        local uiN = ui:append("WndWindow_Normal", "WndWindow"):children("#WndWindow_Normal"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        local y = 45
        for i= 1, MY_VisualSkill.nVisualSkillBoxCount do
            uiN:append("Box_1"..i, "Box"):item("#Box_1"..i):pos(y+i*53,3):alpha(0)
        end
        uiN:append("Box_10", "Box"):item("#Box_10"):pos(y+MY_VisualSkill.nVisualSkillBoxCount*53+300,3):alpha(0)
        -- draw front mask
        local uiT = ui:append("WndWindow_Top", "WndWindow"):children("#WndWindow_Top"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        local y = 42
        for i= 1, MY_VisualSkill.nVisualSkillBoxCount do
            uiT:append("Image_1"..i, "Image"):item("#Image_1"..i):pos(y+i*53,0):size(55, 53):image("ui/Image/UICommon/Skills.UITex", 15)
        end
        -- init data and bind event
        _Cache.nVisualSkillBoxIndex = 0
        MY.RegisterEvent("DO_SKILL_CAST", "MY_VisualSkillCast", function()
            local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
            if dwID == GetClientPlayer().dwID then
                MY_VisualSkill.OnSkillCast(dwSkillID, dwSkillLevel)
            end
        end)
    end
end
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    MY_VisualSkill.anchorVisualSkill = { x=0, y=-220, s="BOTTOMCENTER", r="BOTTOMCENTER" }
    MY.UI('Normal/MY_VisualSkill'):anchor(MY_VisualSkill.anchorVisualSkill)
end)
MY_VisualSkill.OnSkillCast = function(dwSkillID, dwSkillLevel)
    local ui = MY.UI("Normal/MY_VisualSkill/WndWindow_Normal")
    if ui:count()==0 then
        return
    end
    -- get name
    local szSkillName, dwIconID = MY.Player.GetSkillName(dwSkillID, dwSkillLevel)
    if dwSkillID == 4097 then -- 骑乘
        dwIconID = 1899
    elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- 阵法技能
        or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- 阵法释放技能
        -- or dwSkillID == 230     -- (230)  万花伤害阵法施放  七绝逍遥阵
        -- or dwSkillID == 347     -- (347)  纯阳气宗阵法施放  九宫八卦阵
        -- or dwSkillID == 526     -- (526)  七秀治疗阵法施放  花月凌风阵
        -- or dwSkillID == 662     -- (662)  天策防御阵法释放  九襄地玄阵
        -- or dwSkillID == 740     -- (740)  少林防御阵法施放  金刚伏魔阵
        -- or dwSkillID == 745     -- (745)  少林攻击阵法施放  天鼓雷音阵
        -- or dwSkillID == 754     -- (754)  天策攻击阵法释放  卫公折冲阵
        -- or dwSkillID == 778     -- (778)  纯阳剑宗阵法施放  北斗七星阵
        -- or dwSkillID == 781     -- (781)  七秀伤害阵法施放  九音惊弦阵
        -- or dwSkillID == 1020    -- (1020) 万花治疗阵法施放  落星惊鸿阵
        -- or dwSkillID == 1866    -- (1866) 藏剑阵法释放      依山观澜阵
        -- or dwSkillID == 2481    -- (2481) 五毒治疗阵法施放  妙手织天阵
        -- or dwSkillID == 2487    -- (2487) 五毒攻击阵法施放  万蛊噬心阵
        -- or dwSkillID == 3216    -- (3216) 唐门外功阵法施放  流星赶月阵
        -- or dwSkillID == 3217    -- (3217) 唐门内功阵法施放  千机百变阵
        -- or dwSkillID == 4674    -- (4674) 明教攻击阵法施放  炎威破魔阵
        -- or dwSkillID == 4687    -- (4687) 明教防御阵法施放  无量光明阵
        -- or dwSkillID == 5311    -- (5311) 丐帮攻击阵法释放  降龙伏虎阵
        -- or dwSkillID == 13228   -- (13228)  临川列山阵释放  临川列山阵
        -- or dwSkillID == 13275   -- (13275)  锋凌横绝阵施放  锋凌横绝阵
        or dwSkillID == 10         -- (10)    横扫千军           横扫千军
        or dwSkillID == 11         -- (11)    普通攻击-棍攻击    六合棍
        or dwSkillID == 12         -- (12)    普通攻击-枪攻击    梅花枪法
        or dwSkillID == 13         -- (13)    普通攻击-剑攻击    三柴剑法
        or dwSkillID == 14         -- (14)    普通攻击-拳套攻击  长拳
        or dwSkillID == 15         -- (15)    普通攻击-双兵攻击  连环双刀
        or dwSkillID == 16         -- (16)    普通攻击-笔攻击    判官笔法
        or dwSkillID == 1795       -- (1795)  普通攻击-重剑攻击  四季剑法
        or dwSkillID == 2183       -- (2183)  普通攻击-虫笛攻击  大荒笛法
        or dwSkillID == 3121       -- (3121)  普通攻击-弓攻击    罡风镖法
        or dwSkillID == 4326       -- (4326)  普通攻击-双刀攻击  大漠刀法
        or dwSkillID == 13039      -- (13039) 普通攻击_盾刀攻击  卷雪刀
        or dwSkillID == 17         -- (17)    江湖-防身武艺-打坐 打坐
        or dwSkillID == 18         -- (18)    踏云 踏云
        or dwIconID  == 1817       -- 闭阵
        or dwIconID  == 533        -- 打坐
        or dwIconID  == 13         -- 子技能
        or not szSkillName
        or szSkillName == ""
    then
        return
    end
    
    local nAnimateFrameCount, nStartFrame = 8, GetLogicFrameCount()
    -- box enter
    local i = _Cache.nVisualSkillBoxIndex
    local boxEnter = ui:item("#Box_1"..i)
    boxEnter:raw(1):SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
    boxEnter:raw(1):SetObjectIcon(dwIconID)
    local nEnterDesLeft = MY_VisualSkill.nVisualSkillBoxCount*53 + 45
    boxEnter:fadeTo(nAnimateFrameCount * 75, 255)
    MY.BreatheCall(function()
        local nLeft = boxEnter:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxEnter:left(nLeft - (nLeft - nEnterDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxEnter:left(nEnterDesLeft)
            return 0
        end
    end, "#Box_1"..i)
    MY.DelayCall(function()
        boxEnter:fadeTo(nAnimateFrameCount * 75, 0)
    end, "#Box_1"..i, 15000)
    
    -- box leave
    i = ( i + 1 ) % (MY_VisualSkill.nVisualSkillBoxCount + 1)
    local boxLeave = ui:item("#Box_1"..i)
    boxLeave:raw(1):SetObjectCoolDown(0)
    local nLeaveDesLeft = -200
    boxLeave:fadeTo(nAnimateFrameCount * 75, 0)
    MY.BreatheCall(function()
        local nLeft = boxLeave:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxLeave:left(nLeft - (nLeft - nLeaveDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxLeave:left(45+MY_VisualSkill.nVisualSkillBoxCount*53+300)
            return 0
        end
    end, "#Box_1"..i)
    
    -- box middle
    for j = 2, MY_VisualSkill.nVisualSkillBoxCount do
        i = ( i + 1 ) % (MY_VisualSkill.nVisualSkillBoxCount + 1)
        local box, nDesLeft = ui:item("#Box_1"..i), j*53-8
        MY.BreatheCall(function()
            local nLeft = box:left()
            local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
            if nSpentFrameCount < nAnimateFrameCount then
                box:left(nLeft - (nLeft - nDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
            else
                box:left(nDesLeft)
                return 0
            end
        end, "#Box_1"..i)
    end
    
    -- update index
    _Cache.nVisualSkillBoxIndex = ( _Cache.nVisualSkillBoxIndex + 1 ) % (MY_VisualSkill.nVisualSkillBoxCount + 1)
end
MY.RegisterInit(MY_VisualSkill.Reload)