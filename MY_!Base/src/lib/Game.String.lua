--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.String')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local function PatternReplacer(szContent, tVar, bKeepNMTS, bReplaceSensitiveWord)
	-- 由于涉及缓存，所以该函数仅允许替换静态映射关系
	if szContent == 'me' then
		return X.GetClientPlayerName()
	end
	if X.IsTable(tVar) then
		if not X.IsNil(tVar[szContent]) then
			return tVar[szContent]
		end
		if szContent:match('^%d+$') then
			return tVar[tonumber(szContent)]
		end
	end
	local szType = szContent:sub(1, 1)
	local aValue = X.SplitString(szContent:sub(2), ',')
	for k, v in ipairs(aValue) do
		aValue[k] = tonumber(v)
	end
	if szType == 'N' then
		return X.GetNpcTemplateName(aValue[1])
	end
	if szType == 'D' then
		return X.GetDoodadTemplateName(aValue[1])
	end
	if szType == 'S' then
		return X.GetSkillName(aValue[1], aValue[2])
	end
	if szType == 'B' then
		return X.GetBuffName(aValue[1], aValue[2])
	end
	if szType == 'I' then
		if #aValue == 1 then
			return X.GetItemNameByUIID(aValue[1])
		end
		local KItemInfo = GetItemInfo(aValue[1], aValue[2])
		if KItemInfo then
			return X.GetItemNameByItemInfo(KItemInfo, aValue[3])
		end
	end
	if szType == 'M' then
		local map = X.GetMapInfo(aValue[1])
		if map then
			return map.szName
		end
	end
	-- keep none-matched template string
	if bKeepNMTS then
		if bReplaceSensitiveWord then
			szContent = X.ReplaceSensitiveWord(szContent)
		end
		return '{$' .. szContent .. '}'
	end
end
local CACHE, CACHE_KEY, MAX_CACHE = {}, {}, 100
function X.RenderTemplateString(szTemplate, tVar, nMaxLen, bReplaceSensitiveWord, bKeepNMTS)
	if not szTemplate then
		return
	end
	local szKey = X.EncodeLUAData({szTemplate, tVar, nMaxLen, bReplaceSensitiveWord, bKeepNMTS})
	if not CACHE[szKey] then
		local szText = ''
		local nOriginLen, nLen, nPos = string.len(szTemplate), 0, 1
		local szPart, nStart, nEnd, szContent
		while nPos <= nOriginLen do
			szPart, nStart, nEnd, szContent = nil, nil, nil, nil
			nStart = X.StringFindW(szTemplate, '{$', nPos)
			if nStart then
				nEnd = X.StringFindW(szTemplate, '}', nStart + 2)
				if nEnd then
					szContent = szTemplate:sub(nStart + 2, nEnd - 1)
				end
			end
			if not nStart then
				szPart = szTemplate:sub(nPos)
				nPos = nOriginLen + 1
			elseif not nEnd then
				szPart = szTemplate:sub(nPos, nStart + 1)
				nPos = nStart + 2
			elseif nStart > nPos then
				szPart = szTemplate:sub(nPos, nStart - 1)
				nPos = nStart
			end
			if szPart then
				if bReplaceSensitiveWord then
					szPart = X.ReplaceSensitiveWord(szPart)
				end
				if nMaxLen and nMaxLen > 0 and nLen + X.StringLenW(szPart) > nMaxLen then
					szPart = X.StringSubW(szPart, 1, nMaxLen - nLen)
					szText = szText .. szPart
					nLen = nMaxLen
					break
				else
					szText = szText .. szPart
					nLen = nLen + X.StringLenW(szPart)
				end
			end
			if szContent then
				szPart = PatternReplacer(szContent, tVar, bKeepNMTS, bReplaceSensitiveWord)
				if szPart then
					szText = szText .. szPart
				end
				nPos = nEnd + 1
			end
		end
		if #CACHE_KEY >= MAX_CACHE then
			CACHE[table.remove(CACHE_KEY, 1)] = nil
		end
		CACHE[szKey] = szText
		table.insert(CACHE_KEY, szKey)
	end
	return CACHE[szKey]
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
