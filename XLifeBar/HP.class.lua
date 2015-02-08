--
-- ��ƽѪ��UI������
-- ֻ��UI���� �����κ��߼��ж�
--
XLifeBar = XLifeBar or {}
XLifeBar.HP = class()
local HP = XLifeBar.HP

function HP:ctor(dwID, frame, handle) -- KGobject
    self.dwID = dwID
    self.frame = frame
    self.handle = handle
    return self
end
-- ����
function HP:Create()
    -- Create handle
    local frame = self.frame
    if not frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
    end
    
    local handle = frame:Lookup("",tostring(self.dwID))
    if not handle:Lookup(string.format("hp_bg_%s",self.dwID)) then
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"lines_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_title_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_title_%s\"</shadow>",self.dwID) )
    end
    self.handle = handle
    return self
end

-- ɾ��
function HP:Remove()
    local frame = self.frame
    if frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:RemoveItem(frame:Lookup("",tostring(self.dwID)))        
    end
    return self
end

-- ��������/���/�ƺ� �ȵ� ������
-- rgbaf: ��,��,��,͸����,����
-- tWordlines: {[����,�߶�ƫ��],...}
function HP:DrawWordlines(tWordlines, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("lines_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    for _, aWordline in ipairs(tWordlines) do
        sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
    end
    return self
end

-- ����Ѫ���ٷֱ����֣������ػ�������Ժ�Wordlines���룩
function HP:DrawLifePercentage(aWordline, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("hp_title_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
end

-- ���ƶ������ƣ������ػ�������Ժ�Wordlines���룩
function HP:DrawOTTitle(aWordline, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("ot_title_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
    
    return self
end

-- ���߿� Ĭ��200��nAlpha
function HP:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, szShadowName, szShadowName2)
    if not self.handle then
        return
    end
    nAlpha = nAlpha or 200
    local handle = self.handle
    
    -- ������߿�
    local sha = handle:Lookup(string.format(szShadowName,self.dwID))
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()
    local bcX,bcY = - nWidth / 2 ,(- nHeight) - nOffsetY

    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY+nHeight})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+nHeight})

    -- �����ڱ߿�
    local sha = handle:Lookup(string.format(szShadowName2,self.dwID))
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()        
    local bcX,bcY = - (nWidth / 2 - 1),(- (nHeight - 1)) - nOffsetY

    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY+(nHeight - 2)})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(nHeight - 2)})        

    return self
end

-- ���Ѫ���߿� Ĭ��200��nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetY, nAlpha)
    return self:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, "hp_bg_%s", "hp_bg2_%s")
end
-- �������߿� Ĭ��200��nAlpha
function HP:DrawOTBarBorder(nWidth, nHeight, nOffsetY, nAlpha)
    return self:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, "ot_bg_%s", "ot_bg2_%s")
end

-- �����Σ�������/Ѫ����
-- rgbap: ��,��,��,͸����,����
function HP:DrawRect(nWidth, nHeight, nOffsetY, rgbap, szShadowName)
    if not self.handle then
        return
    end
    local r,g,b,a,p = unpack(rgbap)
    if not p or p > 1 then
        p = 1
    elseif p < 0 then
        p = 0
    end -- fix
    local sha = self.handle:Lookup(string.format(szShadowName,self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()
    
    local bcX,bcY = - (nWidth / 2 - 2),(- (nHeight - 2)) - nOffsetY
    nWidth = (nWidth - 4) * p -- ����ʵ�ʻ��ƿ��
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX+nWidth,bcY})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX+nWidth,bcY+(nHeight - 4)})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX,bcY+(nHeight - 4)})
    
    return self
end

-- ���Ѫ��
function HP:DrawLifebar(nWidth, nHeight, nOffsetY, rgbap)
    return self:DrawRect(nWidth, nHeight, nOffsetY, rgbap, "hp_%s")
end

-- ������
function HP:DrawOTBar(nWidth, nHeight, nOffsetY, rgbap)
    return self:DrawRect(nWidth, nHeight, nOffsetY, rgbap, "ot_%s")
end
