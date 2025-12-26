--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 浮动文本
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.HandlePool')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local D = {}
local PRESET_ANIMATION_KEY_FRAME = {
	ZOOM_IN_FADE_IN_OUT = {
		[0] = {
			nOffsetX = 0,
			nOffsetY = 0,
			nAlpha = 0,
			fScale = 0,
		},
		[0.2] = {
			nOffsetX = 0,
			nOffsetY = 0,
			nAlpha = 255,
			fScale = 1,
		},
		[0.7] = {
			nOffsetX = 0,
			nOffsetY = 0,
			nAlpha = 255,
			fScale = 1,
		},
		[1] = {
			nOffsetX = 0,
			nOffsetY = 0,
			nAlpha = 0,
			fScale = 1,
		},
	},
}
local FLOAT_TEXT_LIST = {}

function D.FormatKeyFrames(tKf)
	local aKf = {}
	for fPercent, kf in pairs(tKf) do
		table.insert(aKf, { fPercent, kf })
	end
	table.sort(aKf, function(kf1, kf2) return kf2[1] > kf1[1] end)
	tKf = {}
	local kfPrev
	for _, v in ipairs(aKf) do
		local fPercent = v[1]
		local kf = X.Clone(v[2])
		if kfPrev then
			for k, v in pairs(kfPrev) do
				if X.IsNil(kf[k]) then
					kf[k] = v
				end
			end
		else
			kf.nOffsetX = kf.nOffsetX or 0
			kf.nOffsetY = kf.nOffsetY or 0
			kf.nAlpha = kf.nAlpha or 255
			kf.fScale = kf.fScale or 1
		end
		kfPrev = kf
		tKf[fPercent] = kf
	end
	return tKf
end

for k, v in pairs(PRESET_ANIMATION_KEY_FRAME) do
	PRESET_ANIMATION_KEY_FRAME[k] = D.FormatKeyFrames(v)
end

function D.GetLinearValue(nPrev, nNext, fProgress)
	if not nPrev then
		return
	end
	if not nNext then
		return nPrev
	end
	return (nNext - nPrev) * fProgress + nPrev
end

function D.OnFrameRender()
	local hTotal = X.UI.GetShadowHandle(X.NSFormatString('{$NS}.UI.FloatText'))
	if not hTotal then
		return
	end
	for i, ft in X.ipairs_r(FLOAT_TEXT_LIST) do
		-- 计算锚点坐标
		local nX, nY = 0, 0
		local nScreenW, nScreenH = Station.GetClientSize()
		if ft.szAnchor == 'TOPLEFT' then
			nX, nY = 0, 0
		elseif ft.szAnchor == 'TOPCENTER' then
			nX, nY = nScreenW / 2, 0
		elseif ft.szAnchor == 'TOPRIGHT' then
			nX, nY = nScreenW, 0
		elseif ft.szAnchor == 'CENTERLEFT' then
			nX, nY = 0, nScreenH / 2
		elseif ft.szAnchor == 'CENTER' then
			nX, nY = nScreenW / 2, nScreenH / 2
		elseif ft.szAnchor == 'CENTERRIGHT' then
			nX, nY = nScreenW, nScreenH / 2
		elseif ft.szAnchor == 'BOTTOMLEFT' then
			nX, nY = 0, nScreenH
		elseif ft.szAnchor == 'BOTTOMCENTER' then
			nX, nY = nScreenW / 2, nScreenH
		elseif ft.szAnchor == 'BOTTOMRIGHT' then
			nX, nY = nScreenW, nScreenH
		end
		nX = nX + ft.nOffsetX
		nY = nY + ft.nOffsetY
		-- 通过关键帧计算当前帧数据
		local nTime = GetTime() - ft.nStartTime
		local fProgress = nTime / ft.nDuration
		local kfPrev, kfNext, fKfPrevProgress, fKfNextProgress
		for fKfProgress, kf in pairs(ft.tKeyFrame) do
			if fKfProgress <= fProgress and (not fKfPrevProgress or fKfPrevProgress < fKfProgress) then
				kfPrev = kf
				fKfPrevProgress = fKfProgress
			elseif fKfProgress > fProgress and (not fKfNextProgress or fKfNextProgress > fKfProgress) then
				kfNext = kf
				fKfNextProgress = fKfProgress
			end
		end
		local cf
		if kfPrev then
			if kfNext then
				local fProgress = (fProgress - fKfPrevProgress) / (fKfNextProgress - fKfPrevProgress)
				cf = {
					nOffsetX = D.GetLinearValue(kfPrev.nOffsetX, kfNext.nOffsetX, fProgress),
					nOffsetY = D.GetLinearValue(kfPrev.nOffsetY, kfNext.nOffsetY, fProgress),
					nAlpha = D.GetLinearValue(kfPrev.nAlpha, kfNext.nAlpha, fProgress),
					fScale = D.GetLinearValue(kfPrev.fScale, kfNext.fScale, fProgress),
				}
			else
				cf = kfPrev
			end
		end
		-- 初始化文本
		if not ft.txt then
			hTotal:AppendItemFromString('<text>text=""</text>')
			ft.txt = hTotal:Lookup(hTotal:GetItemCount() - 1)
			ft.txt:SetSize(0, 0)
			ft.txt:SetAbsPos(nX, nY)
			ft.txt:SetRelPos(nX, nY)
			ft.txt:SetText(ft.szText)
			ft.txt:SetFontScheme(ft.nFont)
			ft.txt:SetFontScale(ft.fScale)
			ft.txt:SetFontColor(ft.nR, ft.nG, ft.nB)
			ft.txt:SetHAlign(ft.nHAlign)
			ft.txt:SetVAlign(ft.nVAlign)
		end
		-- 渲染文本动画
		if cf then
			if cf.nOffsetX then
				ft.txt:SetAbsX(nX + cf.nOffsetX * ft.fScale)
				ft.txt:SetRelX(nX + cf.nOffsetX * ft.fScale)
			end
			if cf.nOffsetY then
				ft.txt:SetAbsY(nY + cf.nOffsetY * ft.fScale)
				ft.txt:SetRelY(nY + cf.nOffsetY * ft.fScale)
			end
			if cf.fScale then
				ft.txt:SetFontScale(cf.fScale * ft.fScale)
			end
			if cf.nAlpha then
				ft.txt:SetAlpha(cf.nAlpha)
			end
		else
			ft.txt:SetAbsPos(nX, nY)
			ft.txt:SetRelPos(nX, nY)
			ft.txt:SetFontScale(ft.fScale)
		end
		-- 销毁结束的动画
		if fProgress > 1 then
			ft.txt:GetParent():RemoveItem(ft.txt)
			table.remove(FLOAT_TEXT_LIST, i)
		end
	end
end
X.RenderCall(X.NSFormatString('{$NS}.UI.FloatText'), D.OnFrameRender)

function D.CreateFloatText(szText, nDuration, tOptions)
	local nFont = tOptions.nFont or 19
	local nR = tOptions.nR or 255
	local nG = tOptions.nG or 255
	local nB = tOptions.nB or 255
	local szAnchor = tOptions.szAnchor or 'CENTER'
	local szVAlign = tOptions.szVAlign
	local szHAlign = tOptions.szHAlign
	local nOffsetX = tOptions.nOffsetX or 0
	local nOffsetY = tOptions.nOffsetY or 0
	local fScale = tOptions.fScale or 1
	local tKeyFrame = tOptions.tKeyFrame or {}
	if tOptions.szAnimation then
		tKeyFrame = PRESET_ANIMATION_KEY_FRAME[tOptions.szAnimation] or {}
	end
	if szAnchor == 'TOPLEFT' then
		if not szVAlign then
			szVAlign = 'TOP'
		end
		if not szHAlign then
			szHAlign = 'LEFT'
		end
	elseif szAnchor == 'TOPCENTER' then
		if not szVAlign then
			szVAlign = 'TOP'
		end
		if not szHAlign then
			szHAlign = 'CENTER'
		end
	elseif szAnchor == 'TOPRIGHT' then
		if not szVAlign then
			szVAlign = 'TOP'
		end
		if not szHAlign then
			szHAlign = 'RIGHT'
		end
	elseif szAnchor == 'CENTERLEFT' then
		if not szVAlign then
			szVAlign = 'CENTER'
		end
		if not szHAlign then
			szHAlign = 'LEFT'
		end
	elseif szAnchor == 'CENTER' then
		if not szVAlign then
			szVAlign = 'CENTER'
		end
		if not szHAlign then
			szHAlign = 'CENTER'
		end
	elseif szAnchor == 'CENTERRIGHT' then
		if not szVAlign then
			szVAlign = 'CENTER'
		end
		if not szHAlign then
			szHAlign = 'RIGHT'
		end
	elseif szAnchor == 'BOTTOMLEFT' then
		if not szVAlign then
			szVAlign = 'BOTTOM'
		end
		if not szHAlign then
			szHAlign = 'LEFT'
		end
	elseif szAnchor == 'BOTTOMCENTER' then
		if not szVAlign then
			szVAlign = 'BOTTOM'
		end
		if not szHAlign then
			szHAlign = 'CENTER'
		end
	elseif szAnchor == 'BOTTOMRIGHT' then
		if not szVAlign then
			szVAlign = 'BOTTOM'
		end
		if not szHAlign then
			szHAlign = 'RIGHT'
		end
	end
	local nHAlign, nVAlign = ALIGNMENT.LEFT, ALIGNMENT.TOP
	if szHAlign == 'LEFT' then
		nHAlign = ALIGNMENT.LEFT
	elseif szHAlign == 'CENTER' then
		nHAlign = ALIGNMENT.CENTER
	elseif szHAlign == 'RIGHT' then
		nHAlign = ALIGNMENT.RIGHT
	end
	if szVAlign == 'TOP' then
		nVAlign = ALIGNMENT.TOP
	elseif szVAlign == 'CENTER' then
		nVAlign = ALIGNMENT.CENTER
	elseif szVAlign == 'BOTTOM' then
		nVAlign = ALIGNMENT.BOTTOM
	end
	table.insert(FLOAT_TEXT_LIST, {
		szText = szText,
		nDuration = nDuration,
		nFont = nFont,
		nR = nR,
		nG = nG,
		nB = nB,
		szAnchor = szAnchor,
		nHAlign = nHAlign,
		nVAlign = nVAlign,
		nOffsetX = nOffsetX,
		nOffsetY = nOffsetY,
		fScale = fScale,
		tKeyFrame = D.FormatKeyFrames(tKeyFrame),
		nStartTime = GetTime(),
	})
end
X.UI.CreateFloatText = D.CreateFloatText

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
