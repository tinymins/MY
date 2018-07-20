--------------------------------------------
-- @Desc  : 扁平血条UI操作类
--          只做UI操作 不做任何逻辑判断
-- @Author: 茗伊 @tinymins
-- @Date  : 2015-03-02 10:08:35
-- @Email : admin@derzh.com
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-05-31 11:13:06
--------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random = math.huge, math.pi, math.random
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsBoolean, IsEmpty, RandomChild = MY.IsNil, MY.IsBoolean, MY.IsEmpty, MY.RandomChild
local IsNumber, IsString, IsTable, IsFunction = MY.IsNumber, MY.IsString, MY.IsTable, MY.IsFunction
---------------------------------------------------------------------------------------------------
local HP = class()
local CACHE = setmetatable({}, {__mode = 'v'})
local REQUIRE_SORT = false

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
		hItem:AppendItemFromString('<shadow>name="lines"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp_title"</shadow>')
		hItem:AppendItemFromString('<sfx>name="sfx"</sfx>')
		REQUIRE_SORT = true
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

function HP:SetPriority(nPriority)
	if self.handle then
		self.handle:SetUserData(nPriority)
		REQUIRE_SORT = true
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
function HP:DrawTexts(aTexts, nY, nLineHeight, r, g, b, a, f, spacing, scale)
	if self.handle then
		local sha = self.handle:Lookup('lines')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		for _, szText in ipairs(aTexts) do
			if szText ~= '' then
				sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, 0, -nY}, f, szText, spacing, scale / MY.GetFontScale())
				nY =  nY + nLineHeight
			end
		end
	end
	return self
end

-- 绘制血量百分比文字（减少重绘次数所以和Wordlines分离）
function HP:DrawLifeText(text, x, y, r, g, b, a, f, spacing, scale)
	if self.handle then
		local sha = self.handle:Lookup('hp_title')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, x, -y}, f, text, spacing, scale / MY.GetFontScale())
	end
	return self
end

function HP:ClearLifeText()
	return self:ClearShadow('hp_title')
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(szShadowName, szShadowName2, nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
	if self.handle then
		nAlpha = nAlpha or 200
		local handle = self.handle

		-- 绘制外边框
		local sha = handle:Lookup(szShadowName)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -(nWidth / 2 + nBorder) + nOffsetX, -(nHeight / 2 + nBorder) - nOffsetY

		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX + nWidth + nBorder * 2, bcY})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX + nWidth + nBorder * 2, bcY + nHeight + nBorder * 2})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX, bcY + nHeight + nBorder * 2})

		-- 绘制内边框
		local sha = handle:Lookup(szShadowName2)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -nWidth / 2 + nOffsetX, -nHeight / 2 - nOffsetY

		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY + nHeight})
	end
	return self
end

-- 填充血条边框 默认200的nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
	return self:DrawBorder('hp_bg', 'hp_bg2', nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
end
function HP:ClearLifeBorder()
	self:ClearShadow('hp_bg')
	self:ClearShadow('hp_bg2')
	return self
end

-- 填充矩形（进度条/血条）
-- rgbap: 红,绿,蓝,透明度,进度,绘制方向
function HP:DrawRect(szShadowName, nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
	if self.handle then
		nWidth = max(0, nWidth - nPadding * 2)
		nHeight = max(0, nHeight - nPadding * 2)
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
		local bcX, bcY = -nWidth / 2 + nOffsetX, -nHeight / 2 - nOffsetY
		if d == 'TOP_BOTTOM' then
			nWidth = nWidth
			nHeight = nHeight * p
		elseif d == 'BOTTOM_TOP' then
			bcY = bcY + nHeight * (1 - p)
			nWidth = nWidth
			nHeight = nHeight * p
		elseif d == 'RIGHT_LEFT' then
			bcX = bcX + nWidth * (1 - p)
			nWidth = nWidth * p
			nHeight = nHeight
		else -- if d == 'LEFT_RIGHT' then
			nWidth = nWidth * p
			nHeight = nHeight
		end

		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY + nHeight})
	end
	return self
end

-- 填充血条
function HP:DrawLifeBar(nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
	return self:DrawRect('hp', nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
end

function HP:ClearLifeBar()
	return self:ClearShadow('hp')
end

-- 设置头顶特效
-- szFile 特效文件
-- fScale 特效缩放
-- nWidth 缩放后的特效UI宽度
-- nHeight 缩放后的特效UI高度
function HP:SetSFX(szFile, fScale, nWidth, nHeight, nOffsetY)
	if self.handle then
		local sfx = self.handle:Lookup('sfx')
		local szKey = 'MY_LIFEBAR_HP_SFX_' .. self.dwType .. '_' .. self.dwID
		local dwCtcType = self.dwType == TARGET.DOODAD and CTCT.DOODAD_POS_2_SCREEN_POS or CTCT.CHARACTER_TOP_2_SCREEN_POS
		if szFile then
			sfx:LoadSFX(szFile)
			sfx:SetModelScale(fScale)
			sfx:Play(true)
			sfx:Show()
			MY.RenderCall(szKey, function()
				if sfx and sfx:IsValid() then
					local nX, nY, bFront = MY.CThreadCoor(dwCtcType, self.dwID)
					nX, nY = Station.AdjustToOriginalPos(nX, nY)
					sfx:SetAbsPos(nX, nY - nHeight / 2 - nOffsetY)
				else
					MY.CThreadCoor(dwCtcType, self.dwID, szKey, false)
					MY.RenderCall(szKey, false)
				end
			end)
			MY.CThreadCoor(dwCtcType, self.dwID, szKey, true)
		else
			sfx:Hide()
			MY.RenderCall(szKey, false)
			MY.CThreadCoor(dwCtcType, self.dwID, szKey, false)
		end
	end
	return self
end

function HP:ClearSFX()
	return self:SetSFX()
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

do local hList
local function onBreathe()
	if REQUIRE_SORT then
		if not (hList and hList:IsValid()) then
			hList = XGUI.GetShadowHandle('MY_LifeBar')
		end
		hList:Sort()
		REQUIRE_SORT = false
	end
end
MY.BreatheCall('MY_LifeBar_HP', onBreathe)
end
