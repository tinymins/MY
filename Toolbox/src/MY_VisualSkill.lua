--------------------------------------------
-- @Desc  : ������ʾ
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-03-02 10:08:45
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-03-05 19:30:02
--------------------------------------------
-- ##########################################################################################################################
--       *         *   *                   *                                   *                           *     *           
--       *         *     *         *       *         * * * * * * * * * * *       *     * * * * *           *     *           
--       * * *     *                 *     *                           *     * * * *   *       *         *       *       *   
--       *         * * * *             *   *                           *           *   *   *   *         *       *     *     
--       *     * * *           *           *           * * * * * *     *         *     *   *   *       * *       *   *       
--   * * * * *     *   *         *         *           *         *     *         * *   *   *   *     *   *       * *         
--   *       *     *   *           *       *           *         *     *       * *   * *   *   *         *       *           
--   *       *     *   *                   * * * *     *         *     *     *   *     *   *   *         *     * *           
--   *       *       *       * * * * * * * *           * * * * * *     *         *       *   *           *   *   *           
--   * * * * *     * *   *                 *           *               *         *       *   *           *       *       *   
--   *           *     * *                 *                           *         *     *     *   *       *       *       *   
--             *         *                 *                       * * *         *   *         * *       *         * * * *   
-- ##########################################################################################################################
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _Cache = {}
MY_VisualSkill = {}
MY_VisualSkill.bEnable = false
MY_VisualSkill.anchorVisualSkill = { x=0, y=-220, s="BOTTOMCENTER", r="BOTTOMCENTER" }
MY_VisualSkill.nVisualSkillBoxCount = 5
RegisterCustomData("MY_VisualSkill.bEnable")
RegisterCustomData("MY_VisualSkill.anchorVisualSkill")
RegisterCustomData("MY_VisualSkill.nVisualSkillBoxCount")
-- ���ؽ���
MY_VisualSkill.Reload = function()
    -- distory ui
    MY.UI("Normal/MY_VisualSkill"):remove()
    -- unbind event
    MY.RegisterEvent("DO_SKILL_CAST", "MY_VisualSkillCast")
    -- create new   
    if MY_VisualSkill.bEnable then
        -- create ui
        local ui = MY.UI.CreateFrame("MY_VisualSkill", {empty = true})
        ui:size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52):anchor(MY_VisualSkill.anchorVisualSkill)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_VisualSkill.anchorVisualSkill)
          end):customMode(_L['visual skill'], function(anchor)
            MY_VisualSkill.anchorVisualSkill = anchor
          end, function(anchor)
            MY_VisualSkill.anchorVisualSkill = anchor
          end):penetrable(true)
        -- draw background
        local uiL = ui:append("WndWindow", "WndWindow_Lowest"):children("#WndWindow_Lowest"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        uiL:append("Image", "Image_Bg_10"):item("#Image_Bg_10"):pos(0,0):size(130, 52):image("ui/Image/UICommon/Skills.UITex", 28)
        uiL:append("Image", "Image_Bg_11"):item("#Image_Bg_11"):pos(130,0):size( 53 * MY_VisualSkill.nVisualSkillBoxCount - 32, 52):image("ui/Image/UICommon/Skills.UITex", 31)
        uiL:append("Image", "Image_Bg_12"):item("#Image_Bg_12"):pos(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32, 0):size(80, 52):image("ui/Image/UICommon/Skills.UITex", 29)
        -- create skill boxes
        local uiN = ui:append("WndWindow", "WndWindow_Normal"):children("#WndWindow_Normal"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        local x = 45
        for i = 1, MY_VisualSkill.nVisualSkillBoxCount do
            uiN:append("Box", "Box_1"..i):item("#Box_1"..i):pos(x+i*53,3):alpha(0)
        end
        uiN:append("Box", "Box_10"):item("#Box_10"):pos(x+MY_VisualSkill.nVisualSkillBoxCount*53+300,3):alpha(0)
        -- draw front mask
        local uiT = ui:append("WndWindow", "WndWindow_Top"):children("#WndWindow_Top"):size(130 + 53 * MY_VisualSkill.nVisualSkillBoxCount - 32 + 80, 52)
        local x = 42
        for i= 1, MY_VisualSkill.nVisualSkillBoxCount do
            uiT:append("Image_1"..i, "Image"):item("#Image_1"..i):pos(x+i*53,0):size(55, 53):image("ui/Image/UICommon/Skills.UITex", 15)
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
    if dwSkillID == 4097 then -- ���
        dwIconID = 1899
    elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- �󷨼���
        or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- ���ͷż���
        -- or dwSkillID == 230     -- (230)  ���˺���ʩ��  �߾���ң��
        -- or dwSkillID == 347     -- (347)  ����������ʩ��  �Ź�������
        -- or dwSkillID == 526     -- (526)  ����������ʩ��  ���������
        -- or dwSkillID == 662     -- (662)  ��߷������ͷ�  ���������
        -- or dwSkillID == 740     -- (740)  ���ַ�����ʩ��  ��շ�ħ��
        -- or dwSkillID == 745     -- (745)  ���ֹ�����ʩ��  ���������
        -- or dwSkillID == 754     -- (754)  ��߹������ͷ�  �����۳���
        -- or dwSkillID == 778     -- (778)  ����������ʩ��  ����������
        -- or dwSkillID == 781     -- (781)  �����˺���ʩ��  ����������
        -- or dwSkillID == 1020    -- (1020) ��������ʩ��  ���Ǿ�����
        -- or dwSkillID == 1866    -- (1866) �ؽ����ͷ�      ��ɽ������
        -- or dwSkillID == 2481    -- (2481) �嶾������ʩ��  ����֯����
        -- or dwSkillID == 2487    -- (2487) �嶾������ʩ��  ���������
        -- or dwSkillID == 3216    -- (3216) �����⹦��ʩ��  ���Ǹ�����
        -- or dwSkillID == 3217    -- (3217) �����ڹ���ʩ��  ǧ���ٱ���
        -- or dwSkillID == 4674    -- (4674) ���̹�����ʩ��  ������ħ��
        -- or dwSkillID == 4687    -- (4687) ���̷�����ʩ��  ����������
        -- or dwSkillID == 5311    -- (5311) ؤ�﹥�����ͷ�  ����������
        -- or dwSkillID == 13228   -- (13228)  �ٴ���ɽ���ͷ�  �ٴ���ɽ��
        -- or dwSkillID == 13275   -- (13275)  ��������ʩ��  ��������
        or dwSkillID == 10         -- (10)    ��ɨǧ��           ��ɨǧ��
        or dwSkillID == 11         -- (11)    ��ͨ����-������    ���Ϲ�
        or dwSkillID == 12         -- (12)    ��ͨ����-ǹ����    ÷��ǹ��
        or dwSkillID == 13         -- (13)    ��ͨ����-������    ���񽣷�
        or dwSkillID == 14         -- (14)    ��ͨ����-ȭ�׹���  ��ȭ
        or dwSkillID == 15         -- (15)    ��ͨ����-˫������  ����˫��
        or dwSkillID == 16         -- (16)    ��ͨ����-�ʹ���    �йٱʷ�
        or dwSkillID == 1795       -- (1795)  ��ͨ����-�ؽ�����  �ļ�����
        or dwSkillID == 2183       -- (2183)  ��ͨ����-��ѹ���  ��ĵѷ�
        or dwSkillID == 3121       -- (3121)  ��ͨ����-������    ��ڷ�
        or dwSkillID == 4326       -- (4326)  ��ͨ����-˫������  ��Į����
        or dwSkillID == 13039      -- (13039) ��ͨ����_�ܵ�����  ��ѩ��
        or dwSkillID == 17         -- (17)    ����-��������-���� ����
        or dwSkillID == 18         -- (18)    ̤�� ̤��
        or dwIconID  == 1817       -- ����
        or dwIconID  == 533        -- ����
        or dwIconID  == 13         -- �Ӽ���
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
