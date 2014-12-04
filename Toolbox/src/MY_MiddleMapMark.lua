-- 
-- 中地图标记
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20141204
--
-- 主要功能: 记录所有NPC和Doodad位置 提供搜索和显示
-- 

MY_MiddleMapMark = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _Cache = {}
local Data = {}
local SZ_CACHE_PATH = "cache/npc_doodad_rec"
local MAX_DISTINCT_DISTANCE = 4 -- 最大独立距离4尺（低于该距离的两个实体视为同一个）
MAX_DISTINCT_DISTANCE = MAX_DISTINCT_DISTANCE * MAX_DISTINCT_DISTANCE * 64 * 64

-- HOOK MAP SWITCH
if not MiddleMap._MY_MMM_ShowMap then
    MiddleMap._MY_MMM_ShowMap = MiddleMap.ShowMap
end
MiddleMap.ShowMap = function(...)
    if MiddleMap._MY_MMM_ShowMap then
        MiddleMap._MY_MMM_ShowMap(...)
    end
    MY_MiddleMapMark.Search(_Cache.szKeyword)
end
-- HOOK OnEditChanged
if not MiddleMap._MY_MMM_OnEditChanged then
    MiddleMap._MY_MMM_OnEditChanged = MiddleMap.OnEditChanged
end
MiddleMap.OnEditChanged = function()
    if this:GetName() == 'Edit_Search' then
        MY_MiddleMapMark.Search(this:GetText())
    end
    if MiddleMap._MY_MMM_OnEditChanged then
        MiddleMap._MY_MMM_OnEditChanged()
    end
end
-- HOOK OnMouseEnter
if not MiddleMap._MY_MMM_OnMouseEnter then
    MiddleMap._MY_MMM_OnMouseEnter = MiddleMap.OnMouseEnter
end
MiddleMap.OnMouseEnter = function()
    if this:GetName() == 'Edit_Search' then
        local x, y = this:GetAbsPos()
        local w, h = this:GetSize()
        OutputTip(
            GetFormatText(_L['Type to search, use comma to split.'], nil, 255, 255, 0),
            w,
            {x - 10, y, w, h},
            MY.Const.UI.Tip.POS_TOP
        )
    end
    if MiddleMap._MY_MMM_OnMouseEnter then
        MiddleMap._MY_MMM_OnMouseEnter()
    end
end
-- HOOK OnMouseLeave
if not MiddleMap._MY_MMM_OnMouseLeave then
    MiddleMap._MY_MMM_OnMouseLeave = MiddleMap.OnMouseLeave
end
MiddleMap.OnMouseLeave = function()
    if this:GetName() == 'Edit_Search' then
        HideTip()
    end
    if MiddleMap._MY_MMM_OnMouseLeave then
        MiddleMap._MY_MMM_OnMouseLeave()
    end
end

-- start search
MY_MiddleMapMark.Search = function(szKeyword)
    local ui = MY.UI("Topmost1/MiddleMap")
    local player = GetClientPlayer()
    if ui:count() == 0 or not ui:visible() or not player then
        return
    end
    
    local uiHandle = ui:item("#Handle_MY_MMM")
    if uiHandle:count() == 0 then
        uiHandle = ui:append('Handle_MY_MMM', 'Handle'):item('#Handle_MY_MMM')
          :pos(ui:item('#Handle_Map'):pos())
    end
    uiHandle:clear()
    
    _Cache.szKeyword = szKeyword
    if not szKeyword or szKeyword == '' then
        return
    end

    local dwMapID = tostring(MiddleMap.dwMapID or player.GetMapID())
    local tKeyword = MY.String.Split(szKeyword, ',')
    -- check if data exist
    if not Data[dwMapID] then
        return
    end
    
    -- render npc mark
    for _, npc in ipairs(Data[dwMapID].Npc) do
        local bMatch = false
        for _, kw in ipairs(tKeyword) do
            if string.find(npc.szName, kw) or
            string.find(npc.szTitle, kw) then
                bMatch = true
                break
            end
        end
        if bMatch then
            uiHandle:append('Image_Npc_' .. npc.dwID, 'Image'):item('#Image_Npc_' .. npc.dwID)
              :image('ui/Image/Minimap/MapMark.UITex|95')
              :size(13, 13)
              :pos(MiddleMap.LPosToHPos(npc.nX, npc.nY, 13, 13))
              :tip(npc.szName ..
                ((npc.nLevel and npc.nLevel > 0 and ' lv.' .. npc.nLevel) or '') ..
                ((npc.szTitle ~= '' and '\n<' .. npc.szTitle .. '>') or ''),
              MY.Const.UI.Tip.POS_TOP)
        end
    end
    
    -- render doodad mark
    for _, doodad in ipairs(Data[dwMapID].Doodad) do
        local bMatch = false
        for _, kw in ipairs(tKeyword) do
        if string.find(doodad.szName, kw) then
                bMatch = true
                break
            end
        end
        if bMatch then
            uiHandle:append('Image_Doodad_' .. doodad.dwID, 'Image'):item('#Image_Doodad_' .. doodad.dwID)
              :image('ui/Image/Minimap/MapMark.UITex|95')
              :size(13, 13)
              :pos(MiddleMap.LPosToHPos(doodad.nX, doodad.nY, 13, 13))
              :tip(doodad.szName, MY.Const.UI.Tip.POS_TOP)
        end
    end
end

MY_MiddleMapMark.LoadData = function()
    Data = MY.Json.Decode(MY.LoadLUAData(SZ_CACHE_PATH)) or {}
end

MY_MiddleMapMark.SaveData = function()
    MY.SaveLUAData(SZ_CACHE_PATH, MY.Json.Encode(Data))
end

MY.RegisterEvent("NPC_ENTER_SCENE",    "MY_MiddleMapMark", function()
    local npc = GetNpc(arg0)
    local player = GetClientPlayer()
    if not (npc and player) then
        return
    end
    -- avoid player's pets
    if npc.dwEmployer and npc.dwEmployer ~= 0 then
        return
    end
    -- avoid full number named npc
    local szName = MY.GetObjectName(npc)
    if tonumber(szName) then
        return
    end
    -- switch map
    local dwMapID = tostring(player.GetMapID())
    if not Data[dwMapID] then
        Data[dwMapID] = {
            Npc = {},
            Doodad = {},
        }
    end
    -- keep data distinct
    for i = #Data[dwMapID].Npc, 1, -1 do
        local p = Data[dwMapID].Npc[i]
        if p.dwID == npc.dwID or
        p.dwTemplateID == npc.dwTemplateID and
        math.pow(npc.nX - p.nX, 2) + math.pow(npc.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
            table.remove(Data[dwMapID].Npc, i)
        end
    end
    -- add rec
    table.insert(Data[dwMapID].Npc, {
        nX = npc.nX,
        nY = npc.nY,
        dwID = npc.dwID,
        nLevel  = npc.nLevel,
        szName  = MY.GetObjectName(npc),
        szTitle = npc.szTitle,
        dwTemplateID = npc.dwTemplateID,
    })
end)
MY.RegisterEvent("DOODAD_ENTER_SCENE", "MY_MiddleMapMark", function()
    local doodad = GetDoodad(arg0)
    local player = GetClientPlayer()
    if not (doodad and player) then
        return
    end
    -- avoid full number named doodad
    local szName = MY.GetObjectName(doodad)
    if tonumber(szName) then
        return
    end
    -- switch map
    local dwMapID = tostring(player.GetMapID())
    if not Data[dwMapID] then
        Data[dwMapID] = {
            Npc = {},
            Doodad = {},
        }
    end
    -- keep data distinct
    for i = #Data[dwMapID].Doodad, 1, -1 do
        local p = Data[dwMapID].Doodad[i]
        if p.dwID == doodad.dwID or
        p.dwTemplateID == doodad.dwTemplateID and
        math.pow(doodad.nX - p.nX, 2) + math.pow(doodad.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
            table.remove(Data[dwMapID].Doodad, i)
        end
    end
    -- add rec
    table.insert(Data[dwMapID].Doodad, {
        nX = doodad.nX,
        nY = doodad.nY,
        dwID = doodad.dwID,
        szName  = MY.GetObjectName(doodad),
        szTitle = doodad.szTitle,
        dwTemplateID = doodad.dwTemplateID,
    })
end)
MY.RegisterEvent('LOGIN_GAME', MY_MiddleMapMark.LoadData)
MY.RegisterEvent('PLAYER_ENTER_GAME', MY_MiddleMapMark.LoadData)
MY.RegisterEvent('GAME_EXIT', MY_MiddleMapMark.SaveData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_MiddleMapMark.SaveData)