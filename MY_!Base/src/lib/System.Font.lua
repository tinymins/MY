--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·字体
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Font')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.GetFontList()
	local aList, tExist = {}, {}
	-- 插件字体包
	local FR = _G[X.NSFormatString('{$NS}_FontResource')]
	if X.IsTable(FR) and X.IsFunction(FR.GetList) then
		for _, p in ipairs(FR.GetList()) do
			local szFile = p.szFile:gsub('/', '\\')
			local szKey = szFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = p.szName,
					szFile = p.szFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 系统字体
	for _, p in X.ipairs_r(Font.GetFontPathList() or {}) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			table.insert(aList, 1, {
				szName = p.szName,
				szFile = szFile,
			})
			tExist[szKey] = true
		end
	end
	-- 按照描述文件添加字体
	local CUSTOM_FONT_DIR = X.FormatPath({'font/', X.PATH_TYPE.GLOBAL})
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_FONT_DIR)) do
		local info = szFile:lower():find('%.jx3dat$') and X.LoadLUAData(CUSTOM_FONT_DIR .. szFile, { passphrase = false })
		if info and info.szName and info.szFile then
			local szFontFile = info.szFile:gsub('^%./', CUSTOM_FONT_DIR):gsub('/', '\\')
			local szKey = szFontFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = info.szName,
					szFile = szFontFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 纯字体文件
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_FONT_DIR)) do
		if szFile:lower():find('%.[to]tf$') then
			local szFontFile = (CUSTOM_FONT_DIR .. szFile):gsub('/', '\\')
			local szKey = szFontFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = szFile,
					szFile = szFontFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 删除不存在的字体
	for i, p in X.ipairs_r(aList) do
		if not IsFileExist(p.szFile) then
			table.remove(aList, i)
		end
	end
	return aList
end

-- 获取某个字体的颜色
-- (bool) X.GetFontColor(number nFont)
do
local CACHE, el = {}, nil
function X.GetFontColor(nFont)
	if not CACHE[nFont] then
		if not el or not X.IsElement(el) then
			el = X.UI.GetTempElement('Text', X.NSFormatString('{$NS}Lib__GetFontColor'))
		end
		el:SetFontScheme(nFont)
		CACHE[nFont] = X.Pack(el:GetFontColor())
	end
	return X.Unpack(CACHE[nFont])
end
end

function X.GetFontScale(nOffset)
	return 1 + (nOffset or Font.GetOffset()) * 0.07
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
