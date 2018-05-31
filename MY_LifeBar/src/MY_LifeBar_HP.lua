--------------------------------------------
-- @Desc  : 扁平血条UI操作类
--          只做UI操作 不做任何逻辑判断
-- @Author: 茗伊 @tinymins
-- @Date  : 2015-03-02 10:08:35
-- @Email : admin@derzh.com
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-05-31 11:13:06
--------------------------------------------
local HP = class()
local CACHE = setmetatable({}, {__mode = 'v'})

function HP:ctor(dwType, dwID) -- KGobject
	local hList = XGUI.GetShadowHandle('MY_LifeBar')
	local szName = dwType .. '_' .. dwID
	self.szName = szName
	self.dwType = dwType
	self.dwID = dwID
	self.handle = hList:Lookup(self.szName)
	return self
end

-- 创建
function HP:Create()
	if not self.handle then
		local hList = XGUI.GetShadowHandle('MY_LifeBar')
		hList:AppendItemFromString(FormatHandle(string.format('name="%s"', self.szName)))
		local hItem = hList:Lookup(self.szName)
		hItem:AppendItemFromString('<shadow>name="hp_bg"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp_bg2"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp"</shadow>')
		hItem:AppendItemFromString('<shadow>name="ot_bg"</shadow>')
		hItem:AppendItemFromString('<shadow>name="ot_bg2"</shadow>')
		hItem:AppendItemFromString('<shadow>name="ot"</shadow>')
		hItem:AppendItemFromString('<shadow>name="lines"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp_title"</shadow>')
		hItem:AppendItemFromString('<shadow>name="ot_title"</shadow>')
		self.handle = hItem
	end
	return self
end

-- 删除
function HP:Remove()
	if self.handle then
		local hList = XGUI.GetShadowHandle('MY_LifeBar')
		hList:RemoveItem(self.handle)
		self.handle = nil
	end
	return self
end

function HP:ClearShadow(szShadowName)
	if self.handle then
		local sha = self.handle:Lookup(szShadowName)
		if sha then
			sha:ClearTriangleFanPoint()
		end
	end
	return self
end

-- 绘制名字/帮会/称号 等等 行文字
function HP:DrawTexts(aTexts, nY, nLineHeight, r, g, b, a, f)
	if self.handle then
		nY = nY * Station.GetUIScale()
		nLineHeight = nLineHeight * Station.GetUIScale()
		local sha = self.handle:Lookup('lines')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		for _, szText in ipairs(aTexts) do
			if szText ~= '' then
				sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, 0, -nY}, f, szText, 1, 1)
				nY =  nY + nLineHeight
			end
		end
	end
	return self
end

-- 绘制血量百分比文字（减少重绘次数所以和Wordlines分离）
function HP:DrawLifeText(text, x, y, r, g, b, a, f)
	if self.handle then
		x = x * Station.GetUIScale()
		y = y * Station.GetUIScale()
		local sha = self.handle:Lookup('hp_title')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, x, -y}, f, text, 1, 1)
	end
	return self
end

function HP:ClearLifeText()
	return self:ClearShadow('hp_title')
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(szShadowName, szShadowName2, nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	if self.handle then
		nAlpha = nAlpha or 200
		nWidth = nWidth * Station.GetUIScale()
		nHeight = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		local handle = self.handle

		-- 绘制外边框
		local sha = handle:Lookup(szShadowName)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -nWidth / 2 + nOffsetX, (-nHeight) - nOffsetY

		sha:AppendCharacterID(self.dwID, true, 180, 180, 180, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, 180, 180, 180, nAlpha, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, 180, 180, 180, nAlpha, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, 180, 180, 180, nAlpha, {0, 0, 0, bcX, bcY + nHeight})

		-- 绘制内边框
		local sha = handle:Lookup(szShadowName2)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -(nWidth / 2 - 1) + nOffsetX, (-(nHeight - 1)) - nOffsetY

		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + (nWidth - 2), bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + (nWidth - 2), bcY + (nHeight - 2)})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY + (nHeight - 2)})
	end
	return self
end

-- 填充血条边框 默认200的nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	return self:DrawBorder('hp_bg', 'hp_bg2', nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
end
function HP:ClearLifeBorder()
	self:ClearShadow('hp_bg')
	self:ClearShadow('hp_bg2')
	return self
end

-- 填充矩形（进度条/血条）
-- rgbap: 红,绿,蓝,透明度,进度,绘制方向
function HP:DrawRect(szShadowName, nWidth, nHeight, nOffsetX, nOffsetY, r, g, b, a, p, d)
	if self.handle then
		nWidth = nWidth * Station.GetUIScale()
		nHeight = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		if not p or p > 1 then
			p = 1
		elseif p < 0 then
			p = 0
		end -- fix
		local sha = self.handle:Lookup(szShadowName)

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()

		-- 计算实际绘制宽度高度起始位置
		local bcX, bcY = -(nWidth / 2 - 2) + nOffsetX, (-(nHeight - 2)) - nOffsetY
		if d == 'TOP_BOTTOM' then
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == 'BOTTOM_TOP' then
			bcY = bcY + (nHeight - 4) * (1 - p)
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == 'RIGHT_LEFT' then
			bcX = bcX + (nWidth - 4) * (1 - p)
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		else -- if d == 'LEFT_RIGHT' then
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		end

		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY + nHeight})
	end
	return self
end

-- 填充血条
function HP:DrawLifeBar(nWidth, nHeight, nOffsetX, nOffsetY, r, g, b, a, p, d)
	return self:DrawRect('hp', nWidth, nHeight, nOffsetX, nOffsetY, r, g, b, a, p, d)
end

function HP:ClearLifeBar()
	return self:ClearShadow('hp')
end

function MY_LifeBar_HP(dwType, dwID)
	if dwType == 'clear' then
		CACHE = {}
		XGUI.GetShadowHandle('MY_LifeBar'):Clear()
	else
		local szName = dwType .. '_' .. dwID
		if not CACHE[szName] then
			CACHE[szName] = HP.new(dwType, dwID)
		end
		return CACHE[szName]
	end
end
