--
-- 战斗统计
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
--
local CHANNEL = { -- 统计类型
	DPS  = 1, -- 输出统计
	HPS  = 2, -- 治疗统计
	BDPS = 3, -- 承伤统计
	BHPS = 4, -- 承疗统计
}
local SZ_CHANNEL_KEY = { -- 统计类型数组名
	[CHANNEL.DPS ] = 'Damage',
	[CHANNEL.HPS ] = 'Heal',
	[CHANNEL.BDPS] = 'BeDamage',
	[CHANNEL.BHPS] = 'BeHeal',
}
local SZ_CHANNEL = {
	[CHANNEL.DPS ] = g_tStrings.STR_DAMAGE_STATISTIC    , -- 伤害统计
	[CHANNEL.HPS ] = g_tStrings.STR_THERAPY_STATISTIC   , -- 治疗统计
	[CHANNEL.BDPS] = g_tStrings.STR_BE_DAMAGE_STATISTIC , -- 承伤统计
	[CHANNEL.BHPS] = g_tStrings.STR_BE_THERAPY_STATISTIC, -- 承疗统计
}
local DISPLAY_MODE = { -- 统计显示
	NPC    = 1, -- 只显示NPC
	PLAYER = 2, -- 只显示玩家
	BOTH   = 3, -- 混合显示
}
local PUBLISH_MODE = {
	EFFECT = 1, -- 只显示有效值
	TOTAL  = 2, -- 只显示总数值
	BOTH   = 3, -- 同时显示有效和总数
}
local SKILL_RESULT = {
	HIT     = 0, -- 命中
	BLOCK   = 1, -- 格挡
	SHIELD  = 2, -- 无效
	MISS    = 3, -- 偏离
	DODGE   = 4, -- 闪避
	CRITICAL= 5, -- 会心
	INSIGHT = 6, -- 识破
}
local SZ_SKILL_RESULT = {
	[SKILL_RESULT.HIT     ] = g_tStrings.STR_HIT_NAME     ,
	[SKILL_RESULT.BLOCK   ] = g_tStrings.STR_IMMUNITY_NAME,
	[SKILL_RESULT.SHIELD  ] = g_tStrings.STR_SHIELD_NAME  ,
	[SKILL_RESULT.MISS    ] = g_tStrings.STR_MSG_MISS     ,
	[SKILL_RESULT.DODGE   ] = g_tStrings.STR_MSG_DODGE    ,
	[SKILL_RESULT.CRITICAL] = g_tStrings.STR_CS_NAME      ,
	[SKILL_RESULT.INSIGHT ] = g_tStrings.STR_MSG_INSIGHT  ,
}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Recount/lang/")
local _C = {
	szCssFile   = 'config/MY_RECOUNT/style.jx3dat',
	szIniRoot   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/',
	szIniFile   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/Recount.ini',
	szIniDetail = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/ShowDetail.ini',
	tRandFrame  = {
		169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182,
		183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193
	},
	tDefaultCss = {
		{
			['Bar'] = {
				[-1                  ] = { r = 255, g = 255, b = 255, a = 150 }, -- NPC
				[FORCE_TYPE.JIANG_HU ] = { r = 255, g = 255, b = 255, a = 255 }, -- 江湖
				[FORCE_TYPE.SHAO_LIN ] = { r = 210, g = 180, b = 0  , a = 144 }, -- 少林
				[FORCE_TYPE.WAN_HUA  ] = { r = 127, g = 31 , b = 223, a = 180 }, -- 万花
				[FORCE_TYPE.TIAN_CE  ] = { r = 160, g = 0  , b = 0  , a = 200 }, -- 天策
				[FORCE_TYPE.CHUN_YANG] = { r = 56 , g = 175, b = 255, a = 144 }, -- 纯阳 56,175,255,232
				[FORCE_TYPE.QI_XIU   ] = { r = 255, g = 127, b = 255, a = 128 }, -- 七秀
				[FORCE_TYPE.WU_DU    ] = { r = 63 , g = 31 , b = 159, a = 128 }, -- 五毒
				[FORCE_TYPE.TANG_MEN ] = { r = 0  , g = 133, b = 144, a = 180 }, -- 唐门
				[FORCE_TYPE.CANG_JIAN] = { r = 255, g = 255, b = 0  , a = 144 }, -- 藏剑
				[FORCE_TYPE.GAI_BANG ] = { r = 205, g = 133, b = 63 , a = 180 }, -- 丐帮
				[FORCE_TYPE.MING_JIAO] = { r = 253, g = 84 , b = 0  , a = 144 }, -- 明教
				[FORCE_TYPE.CANG_YUN ] = { r = 180, g = 60 , b = 0  , a = 255 }, -- 苍云
				[FORCE_TYPE.CHANG_GE ] = { r = 100, g = 250, b = 180, a = 100 }, -- 长歌
				[FORCE_TYPE.BA_DAO   ] = { r = 71 , g = 73 , b = 166, a = 128 }, -- 霸刀
			},
		}, {
			['Bar'] = {
				[-1                  ] = { r = 255, g = 255, b = 255, a = 150 }, -- NPC
				[FORCE_TYPE.JIANG_HU ] = { r = 255, g = 255, b = 255, a = 255 }, -- 江湖
				[FORCE_TYPE.SHAO_LIN ] = { r = 210, g = 180, b = 0  , a = 144 }, -- 少林
				[FORCE_TYPE.WAN_HUA  ] = { r = 100, g = 0  , b = 150, a = 96  }, -- 万花
				[FORCE_TYPE.TIAN_CE  ] = { r = 0  , g = 128, b = 0  , a = 255 }, -- 天策
				[FORCE_TYPE.CHUN_YANG] = { r = 0  , g = 175, b = 230, a = 112 }, -- 纯阳
				[FORCE_TYPE.QI_XIU   ] = { r = 240, g = 80 , b = 240, a = 96  }, -- 七秀
				[FORCE_TYPE.WU_DU    ] = { r = 0  , g = 128, b = 255, a = 144 }, -- 五毒
				[FORCE_TYPE.TANG_MEN ] = { r = 121, g = 183, b = 54 , a = 144 }, -- 唐门
				[FORCE_TYPE.CANG_JIAN] = { r = 215, g = 241, b = 74 , a = 144 }, -- 藏剑
				[FORCE_TYPE.GAI_BANG ] = { r = 205, g = 133, b = 63 , a = 180 }, -- 丐帮
				[FORCE_TYPE.MING_JIAO] = { r = 240, g = 70 , b = 96 , a = 180 }, -- 明教
				[FORCE_TYPE.CANG_YUN ] = { r = 180, g = 60 , b = 0  , a = 255 }, -- 苍云
				[FORCE_TYPE.CHANG_GE ] = { r = 100, g = 250, b = 180, a = 150 }, -- 长歌
				[FORCE_TYPE.BA_DAO   ] = { r = 71 , g = 73 , b = 166, a = 128 }, -- 霸刀
			},
		}, {
			['Bar'] = {
				[-1                  ] = { image = "ui/Image/Common/Money.UITex", frame = 215 }, -- NPC
				[FORCE_TYPE.JIANG_HU ] = { image = "ui/Image/Common/Money.UITex", frame = 210 }, -- 大侠
				[FORCE_TYPE.SHAO_LIN ] = { image = "ui/Image/Common/Money.UITex", frame = 203 }, -- 少林
				[FORCE_TYPE.WAN_HUA  ] = { image = "ui/Image/Common/Money.UITex", frame = 205 }, -- 万花
				[FORCE_TYPE.TIAN_CE  ] = { image = "ui/Image/Common/Money.UITex", frame = 206 }, -- 天策
				[FORCE_TYPE.CHUN_YANG] = { image = "ui/Image/Common/Money.UITex", frame = 209 }, -- 纯阳
				[FORCE_TYPE.QI_XIU   ] = { image = "ui/Image/Common/Money.UITex", frame = 204 }, -- 七秀
				[FORCE_TYPE.WU_DU    ] = { image = "ui/Image/Common/Money.UITex", frame = 208 }, -- 五毒
				[FORCE_TYPE.TANG_MEN ] = { image = "ui/Image/Common/Money.UITex", frame = 207 }, -- 唐门
				[FORCE_TYPE.CANG_JIAN] = { image = "ui/Image/Common/Money.UITex", frame = 168 }, -- 藏剑
				[FORCE_TYPE.GAI_BANG ] = { image = "ui/Image/Common/Money.UITex", frame = 234 }, -- 丐帮
				[FORCE_TYPE.MING_JIAO] = { image = "ui/Image/Common/Money.UITex", frame = 232 }, -- 明教
				[FORCE_TYPE.CANG_YUN ] = { image = "ui/Image/Common/Money.UITex", frame = 26  }, -- 苍云
				[FORCE_TYPE.CHANG_GE ] = { image = "ui/Image/Common/Money.UITex", frame = 30  }, -- 长歌
				[FORCE_TYPE.BA_DAO   ] = { image = "ui/Image/Common/Money.UITex", frame = 35  }, -- 霸刀
			},
		}, {
			['Bar'] = {
				[-1                  ] = { image = "ui/Image/Common/Money.UITex", frame = 220 }, -- NPC
				[FORCE_TYPE.JIANG_HU ] = { image = "ui/Image/Common/Money.UITex", frame = 220 }, -- 大侠
				[FORCE_TYPE.SHAO_LIN ] = { image = "ui/Image/Common/Money.UITex", frame = 216 }, -- 少林
				[FORCE_TYPE.WAN_HUA  ] = { image = "ui/Image/Common/Money.UITex", frame = 212 }, -- 万花
				[FORCE_TYPE.TIAN_CE  ] = { image = "ui/Image/Common/Money.UITex", frame = 215 }, -- 天策
				[FORCE_TYPE.CHUN_YANG] = { image = "ui/Image/Common/Money.UITex", frame = 218 }, -- 纯阳
				[FORCE_TYPE.QI_XIU   ] = { image = "ui/Image/Common/Money.UITex", frame = 211 }, -- 七秀
				[FORCE_TYPE.WU_DU    ] = { image = "ui/Image/Common/Money.UITex", frame = 213 }, -- 五毒
				[FORCE_TYPE.TANG_MEN ] = { image = "ui/Image/Common/Money.UITex", frame = 214 }, -- 唐门
				[FORCE_TYPE.CANG_JIAN] = { image = "ui/Image/Common/Money.UITex", frame = 217 }, -- 藏剑
				[FORCE_TYPE.GAI_BANG ] = { image = "ui/Image/Common/Money.UITex", frame = 233 }, -- 丐帮
				[FORCE_TYPE.MING_JIAO] = { image = "ui/Image/Common/Money.UITex", frame = 228 }, -- 明教
				[FORCE_TYPE.CANG_YUN ] = { image = "ui/Image/Common/Money.UITex", frame = 219 }, -- 苍云
				[FORCE_TYPE.CHANG_GE ] = { image = "ui/Image/Common/Money.UITex", frame = 30  }, -- 长歌
				[FORCE_TYPE.BA_DAO   ] = { image = "ui/Image/Common/Money.UITex", frame = 35  }, -- 霸刀
			},
		},
	},
}
_C.tCustomCss = MY.LoadLUAData(_C.szCssFile) or _C.tDefaultCss

-- 新的战斗数据时
MY.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function()
	if not _C.bHistoryMode then
		MY_Recount.DisplayData(0)
	end
end)

MY_Recount = MY_Recount or {}
MY_Recount.bEnable       = false                -- 是否启用
MY_Recount.nCss          = 1                    -- 当前样式表
MY_Recount.nChannel      = CHANNEL.DPS          -- 当前显示的统计模式
MY_Recount.bAwayMode     = true                 -- 计算DPS时是否减去暂离时间
MY_Recount.bSysTimeMode  = false                -- 使用官方战斗统计计时方式
MY_Recount.bShowPerSec   = true                 -- 显示为每秒数据（反之显示总和）
MY_Recount.bShowEffect   = true                 -- 显示有效伤害/治疗
MY_Recount.bSaveRecount  = false                -- 退出游戏时保存战斗记录
MY_Recount.nDisplayMode  = DISPLAY_MODE.BOTH    -- 统计显示模式（显示NPC/玩家数据）（默认混合显示）
MY_Recount.nPublishLimit = 30                   -- 发布到聊天频道数量
MY_Recount.nPublishMode  = PUBLISH_MODE.EFFECT  -- 发布模式
MY_Recount.nDrawInterval = GLOBAL.GAME_FPS / 2  -- UI重绘周期（帧）
MY_Recount.bShowNodataTeammate = false  -- 显示没有数据的队友
MY_Recount.anchor = { x=0, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" } -- 默认坐标
RegisterCustomData("MY_Recount.bEnable", 1)
RegisterCustomData("MY_Recount.nCss")
RegisterCustomData("MY_Recount.nChannel")
RegisterCustomData("MY_Recount.bAwayMode")
RegisterCustomData("MY_Recount.bSysTimeMode")
RegisterCustomData("MY_Recount.bShowPerSec")
RegisterCustomData("MY_Recount.bShowEffect")
RegisterCustomData("MY_Recount.bSaveRecount")
RegisterCustomData("MY_Recount.nDisplayMode")
RegisterCustomData("MY_Recount.nPublishLimit")
RegisterCustomData("MY_Recount.nPublishMode")
RegisterCustomData("MY_Recount.nDrawInterval")
RegisterCustomData("MY_Recount.bShowNodataTeammate")
RegisterCustomData("MY_Recount.anchor")

local m_frame
MY_Recount.Open = function()
	-- open
	m_frame = Wnd.OpenWindow(_C.szIniFile, 'MY_Recount')
	-- pos
	MY.UI(m_frame):anchor(MY_Recount.anchor)
	MY.RegisterEvent('UI_SCALED.MY_RECOUNT', function()
		MY.UI(m_frame):anchor(MY_Recount.anchor)
	end)
	-- draw
	MY_Recount.DrawUI()
end


MY_Recount.Close = function()
	Wnd.CloseWindow(m_frame)
	MY.RegisterEvent('UI_SCALED.MY_RECOUNT')
end

MY.RegisterInit('MY_RECOUNT', function()
	if MY_Recount.bSaveRecount then
		MY_Recount.Data.LoadData()
	end
	MY_Recount.LoadCustomCss()
	if MY_Recount.bEnable then
		MY_Recount.Open()
	else
		MY_Recount.Close()
	end
end)

MY.RegisterExit(function()
	if MY_Recount.bSaveRecount then
		MY_Recount.Data.SaveData()
	end
end)

-- ########################################################################## --
--                               #         #               #             #    --
--                               #       #   #         #   #             #    --
--   # #     # # # # # # #     #       #       #       # # # # #   #     #    --
--     #     #       #       #     # #           #   #     #       #     #    --
--     #     #       #       # # #     # # # # #     # # # # # # # #     #    --
--     #     #       #           #                         #       #     #    --
--     #     #       #         #                       # # # # #   #     #    --
--     #     #       #       # # #   # # # # # # #     #   #   #   #     #    --
--     #     #       #                   #             #   #   #   #     #    --
--       # #     # # # # #       #     #       #       #   #   #         #    --
--                           # #     # # # # # # #     #   # # #         #    --
--                                               #         #         # # #    --
-- ########################################################################## --
MY_Recount.LoadCustomCss = function(nCss)
	if not nCss then
		nCss = MY_Recount.nCss
	else
		MY_Recount.nCss = nCss
	end
	_C.Css = _C.tCustomCss[nCss] or _C.tDefaultCss[1]
end

-- 切换绑定显示记录
-- MY_Recount.DisplayData(number nHistory): 显示第nHistory条历史记录 当nHistory等于0时显示当前记录
-- MY_Recount.DisplayData(table  data): 显示数据为data的历史记录
MY_Recount.DisplayData = function(data)
	if type(data) == 'number' then
		data = MY_Recount.Data.Get(data)
	end
	_C.bHistoryMode = (data ~= MY_Recount.Data.Get(0))
	
	if type(data) == 'table' then
		DataDisplay = data
		MY_Recount.DrawUI()
	end
end

MY_Recount.DrawUI = function(data)
	if not data then
		data = DataDisplay
	end
	if not (m_frame and data) then
		return
	end

	m_frame:Lookup('Wnd_Title', 'Text_Title'):SetText(SZ_CHANNEL[MY_Recount.nChannel])
	m_frame:Lookup('Wnd_Main', 'Handle_List'):Clear()
	m_frame:Lookup('Wnd_Main', 'Handle_Me').bInited = nil

	MY_Recount.UpdateUI(data)
end

MY_Recount.UpdateUI = function(data)
	if not data then
		data = DataDisplay
	end

	if not m_frame then
		return
	end

	-- 获取统计数据
	local tRecord, szUnit
	if MY_Recount.nChannel == CHANNEL.DPS then       -- 伤害统计
		tRecord, szUnit = data.Damage  , 'DPS'
	elseif MY_Recount.nChannel == CHANNEL.HPS then   -- 治疗统计
		tRecord, szUnit = data.Heal    , 'HPS'
	elseif MY_Recount.nChannel == CHANNEL.BDPS then  -- 承伤统计
		tRecord, szUnit = data.BeDamage, 'DPS'
	elseif MY_Recount.nChannel == CHANNEL.BHPS then  -- 承疗统计
		tRecord, szUnit = data.BeHeal  , 'HPS'
	end
	
	-- 计算战斗时间
	local nTimeCount = MY_Recount.Data.GeneFightTime(data, nil, MY_Recount.bSysTimeMode and SZ_CHANNEL_KEY[MY_Recount.nChannel])
	local szTimeCount = MY.FormatTimeCount('M:ss', nTimeCount)
	if MY.IsInArena() then
		szTimeCount = MY.GetFightTime("M:ss")
	end
	-- 自己的记录
	local tMyRec
	
	-- 整理数据 生成要显示的列表
	local nMaxValue, aResult, tIDs = 0, {}, {}
	for id, rec in pairs(tRecord) do
		if MY_Recount.nDisplayMode == DISPLAY_MODE.BOTH or  -- 确定显示模式（显示NPC/显示玩家/全部显示）
		(MY_Recount.nDisplayMode == DISPLAY_MODE.NPC    and type(id) == 'string') or
		(MY_Recount.nDisplayMode == DISPLAY_MODE.PLAYER and type(id) == 'number') then
			tRec = {
				id           = id                                    ,
				szMD5        = rec.szMD5                             ,
				szName       = MY_Recount.Data.GetNameAusID(id, data),
				dwForceID    = data.Forcelist[id] or -1              ,
				nValue       = rec.nTotal         or  0              ,
				nEffectValue = rec.nTotalEffect   or  0              ,
			}
			tIDs[id] = true
			-- 计算战斗时间
			if MY_Recount.bAwayMode then -- 删去死亡时间 && 防止计算DPS时除以0
				tRec.nTimeCount = math.max(MY_Recount.Data.GeneFightTime(data, id, MY_Recount.bSysTimeMode and SZ_CHANNEL_KEY[MY_Recount.nChannel]), 1)
			else -- 不删去暂离时间
				tRec.nTimeCount = math.max(nTimeCount, 1)
			end
			-- 计算每秒数据
			if MY_Recount.bShowPerSec then
				tRec.nValuePS       = tRec.nValue / tRec.nTimeCount
				tRec.nEffectValuePS = tRec.nEffectValue / tRec.nTimeCount
				nMaxValue = math.max(nMaxValue, tRec.nValuePS, tRec.nEffectValuePS)
			else
				nMaxValue = math.max(nMaxValue, tRec.nValue, tRec.nEffectValue)
			end
			table.insert(aResult, tRec)
		end
	end
	-- 全程没数据的队友
	if MY.IsInParty() and MY_Recount.bShowNodataTeammate then
		local list = GetClientTeam().GetTeamMemberList()
		for _, dwID in ipairs(list) do
			local info = GetClientTeam().GetMemberInfo(dwID)
			if not tIDs[dwID] then
				table.insert(aResult, {
					id             = dwID                   ,
					-- szMD5          = info.szMD5             ,
					szName         = info.szName            ,
					dwForceID      = info.dwForceID         ,
					nValue         = 0                      ,
					nEffectValue   = 0                      ,
					nTimeCount     = math.max(nTimeCount, 1),
					nValuePS       = 0                      ,
					nEffectValuePS = 0                      ,
				})
				tIDs[dwID] = true
			end
		end
	end
	
	-- 列表排序
	local szSortKey = 'nValue'
	if MY_Recount.bShowEffect and MY_Recount.bShowPerSec then
		szSortKey = 'nEffectValuePS'
	elseif MY_Recount.bShowEffect then
		szSortKey = 'nEffectValue'
	elseif MY_Recount.bShowPerSec then
		szSortKey = 'nValuePS'
	end
	table.sort(aResult, function(p1, p2)
		return p1[szSortKey] > p2[szSortKey]
	end)
	
	-- 渲染列表
	local hList = m_frame:Lookup('Wnd_Main', 'Handle_List')
	for i, p in pairs(aResult) do
		-- 自己的记录
		if p.id == UI_GetClientPlayerID() then
			tMyRec = p
			tMyRec.nRank = i
		end
		local hItem = hList:Lookup('Handle_LI_' .. (p.szMD5 or p.id))
		if not hItem then
			hItem = hList:AppendItemFromIni(_C.szIniFile, 'Handle_Item')
			hItem.OnItemRefreshTip = MY_Recount.OnItemRefreshTip
			hItem:SetName('Handle_LI_' .. (p.szMD5 or p.id))
			local css = _C.Css.Bar[p.dwForceID] or {}
			if css.image and css.frame then -- uitex, frame
				hItem:Lookup('Image_PerFore'):FromUITex(css.image, css.frame)
				hItem:Lookup('Image_PerBack'):FromUITex(css.image, css.frame)
				hItem:Lookup('Shadow_PerFore'):Hide()
				hItem:Lookup('Shadow_PerBack'):Hide()
			else -- r, g, b
				hItem:Lookup('Shadow_PerFore'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_PerBack'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Image_PerFore'):Hide()
				hItem:Lookup('Image_PerBack'):Hide()
			end
			hItem:Lookup('Image_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Image_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Shadow_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Shadow_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Text_L'):SetText(p.szName)
			hItem.id = p.id
		end
		if hItem:GetIndex() ~= i - 1 then
			hItem:ExchangeIndex(i - 1)
		end
		-- 排名
		if _C.tRandFrame[i] then
			hItem:Lookup('Text_Rank'):Hide()
			hItem:Lookup('Image_Rank'):Show()
			hItem:Lookup('Image_Rank'):SetFrame(_C.tRandFrame[i])
		else
			hItem:Lookup('Text_Rank'):SetText(i .. '.')
			hItem:Lookup('Text_Rank'):Show()
			hItem:Lookup('Image_Rank'):Hide()
		end
		-- 色块长度
		local fPerBack, fPerFore = 0, 0
		if nMaxValue > 0 then
			if MY_Recount.bShowPerSec then
				fPerBack = p.nValuePS / nMaxValue
				fPerFore = p.nEffectValuePS / nMaxValue
			else
				fPerBack = p.nValue / nMaxValue
				fPerFore = p.nEffectValue / nMaxValue
			end
			hItem:Lookup('Image_PerBack'):SetPercentage(fPerBack)
			hItem:Lookup('Image_PerFore'):SetPercentage(fPerFore)
			hItem:Lookup('Shadow_PerBack'):SetW(fPerBack * hItem:GetW())
			hItem:Lookup('Shadow_PerFore'):SetW(fPerFore * hItem:GetW())
		end
		-- 死亡/离线 特殊颜色
		local tAway = data.Awaytime[p.id]
		local bAway = tAway and #tAway > 0 and not tAway[#tAway][2]
		if hItem.bAway ~= bAway then
			if bAway then
				hItem:Lookup('Text_L'):SetFontColor(192, 192, 192)
				hItem:Lookup('Text_R'):SetFontColor(192, 192, 192)
			else
				hItem:Lookup('Text_L'):SetFontColor(255, 255, 255)
				hItem:Lookup('Text_R'):SetFontColor(255, 255, 255)
			end
		end
		-- 数值显示
		if MY_Recount.bShowEffect then
			if MY_Recount.bShowPerSec then
				hItem:Lookup('Text_R'):SetText(math.floor(p.nEffectValue / p.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_R'):SetText(p.nEffectValue)
			end
		else
			if MY_Recount.bShowPerSec then
				hItem:Lookup('Text_R'):SetText(math.floor(p.nValue / p.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_R'):SetText(p.nValue)
			end
		end
		hItem.data = p
	end
	hList.szUnit     = szUnit
	hList.nTimeCount = nTimeCount
	hList:FormatAllItemPos()
	
	-- 渲染底部自己的统计
	local hItem = m_frame:Lookup('Wnd_Main', 'Handle_Me')
	-- 初始化颜色
	if not hItem.bInited then
		hItem.OnItemRefreshTip = MY_Recount.OnItemRefreshTip
		local dwForceID = (MY.Player.GetClientInfo() or {}).dwForceID
		if dwForceID then
			local css = _C.Css.Bar[dwForceID] or {}
			if css.image and css.frame then -- uitex, frame
				hItem:Lookup('Image_Me_PerFore'):FromUITex(css.image, css.frame)
				hItem:Lookup('Image_Me_PerBack'):FromUITex(css.image, css.frame)
				hItem:Lookup('Shadow_Me_PerFore'):Hide()
				hItem:Lookup('Shadow_Me_PerBack'):Hide()
				hItem:Lookup('Image_Me_PerFore'):Show()
				hItem:Lookup('Image_Me_PerBack'):Show()
			else -- r, g, b
				hItem:Lookup('Shadow_Me_PerFore'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_Me_PerBack'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_Me_PerFore'):Show()
				hItem:Lookup('Shadow_Me_PerBack'):Show()
				hItem:Lookup('Image_Me_PerFore'):Hide()
				hItem:Lookup('Image_Me_PerBack'):Hide()
			end
			hItem:Lookup('Image_Me_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Image_Me_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Shadow_Me_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Shadow_Me_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem.bInited = true
		end
	end
	if tMyRec then
		local fPerBack, fPerFore = 0, 0
		if nMaxValue > 0 then
			if MY_Recount.bShowPerSec then
				fPerBack = tMyRec.nValuePS / nMaxValue
				fPerFore = tMyRec.nEffectValuePS / nMaxValue
			else
				fPerBack = tMyRec.nValue / nMaxValue
				fPerFore = tMyRec.nEffectValue / nMaxValue
			end
			hItem:Lookup('Image_Me_PerBack'):SetPercentage(fPerBack)
			hItem:Lookup('Image_Me_PerFore'):SetPercentage(fPerFore)
			hItem:Lookup('Shadow_Me_PerBack'):SetW(fPerBack * hItem:GetW())
			hItem:Lookup('Shadow_Me_PerFore'):SetW(fPerFore * hItem:GetW())
		else
			hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
			hItem:Lookup('Image_Me_PerFore'):SetPercentage(1)
			hItem:Lookup('Shadow_Me_PerBack'):SetW(hItem:GetW())
			hItem:Lookup('Shadow_Me_PerFore'):SetW(hItem:GetW())
		end
		-- 左侧战斗计时
		hItem:Lookup('Text_Me_L'):SetText('[' .. tMyRec.nRank .. '] ' .. szTimeCount)
		-- 右侧文字
		if MY_Recount.bShowEffect then
			if MY_Recount.bShowPerSec then
				hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nEffectValue / tMyRec.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_Me_R'):SetText(tMyRec.nEffectValue)
			end
		else
			if MY_Recount.bShowPerSec then
				hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nValue / tMyRec.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_Me_R'):SetText(tMyRec.nValue)
			end
		end
	else
		hItem:Lookup('Text_Me_L'):SetText(szTimeCount)
		hItem:Lookup('Text_Me_R'):SetText('')
		hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
		hItem:Lookup('Image_Me_PerFore'):SetPercentage(0)
		hItem:Lookup('Shadow_Me_PerBack'):SetW(hItem:GetW())
		hItem:Lookup('Shadow_Me_PerFore'):SetW(0)
	end
end

-- ########################################################################## --
--                                     #                 #         #          --
--                           # # # # # # # # # # #       #   #     #          --
--   # #     # # # # # # #       #     #     #         #     #     #          --
--     #     #       #           # # # # # # #         #     # # # # # # #    --
--     #     #       #                 #             # #   #       #          --
--     #     #       #         # # # # # # # # #       #           #          --
--     #     #       #                 #       #       #           #          --
--     #     #       #       # # # # # # # # # # #     #   # # # # # # # #    --
--     #     #       #                 #       #       #           #          --
--       # #     # # # # #     # # # # # # # # #       #           #          --
--                                     #               #           #          --
--                                   # #               #           #          --
-- ########################################################################## --
-- 周期重绘
MY_Recount.OnFrameBreathe = function()
	if this.nLastRedrawFrame and
	GetLogicFrameCount() - this.nLastRedrawFrame > 0 and
	GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
		return
	end
	this.nLastRedrawFrame = GetLogicFrameCount()
	
	-- 不进战时不刷新UI
	if not _C.bHistoryMode and not MY.Player.GetFightUUID() then
		return
	end
	
	MY_Recount.UpdateUI()
end

MY_Recount.OnFrameDragEnd = function()
	this:CorrectPos()
	MY_Recount.anchor = MY.UI(this):anchor()
end

-- ShowDetail界面时间相应
_C.OnDetailFrameBreathe = function()
	if this.nLastRedrawFrame and
	GetLogicFrameCount() - this.nLastRedrawFrame > 0 and
	GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
		return
	end
	this.nLastRedrawFrame = GetLogicFrameCount()
	
	local id        = this.id
	local szChannel = this.szChannel
	if tonumber(id) then
		id = tonumber(id)
	end
	-- 获取数据
	local tData = DataDisplay[szChannel][id]
	if not tData then
		this:Lookup('WndScroll_Detail', 'Handle_DetailList'):Clear()
		this:Lookup('WndScroll_Skill' , 'Handle_SkillList' ):Clear()
		this:Lookup('WndScroll_Target', 'Handle_TargetList'):Clear()
		return
	end
	
	local szPrimarySort   = this.szPrimarySort or 'Skill'
	local szSecondarySort = (szPrimarySort == 'Skill' and 'Target') or 'Skill'
	
	--------------- 一、技能列表更新 -----------------
	-- 数据收集
	local aResult, nTotalEffect = {}, tData.nTotalEffect
	if szPrimarySort == 'Skill' then
		for szSkillName, p in pairs(tData.Skill) do
			table.insert(aResult, {
				szKey        = szSkillName   ,
				szName       = szSkillName   ,
				nCount       = p.nCount      ,
				nTotalEffect = p.nTotalEffect,
			})
		end
	else
		for id, p in pairs(tData.Target) do
			table.insert(aResult, {
				szKey        = id                              ,
				szName       = MY_Recount.Data.GetNameAusID(id),
				nCount       = p.nCount                        ,
				nTotalEffect = p.nTotalEffect                  ,
			})
		end
	end
	table.sort(aResult, function(p1, p2)
		return p1.nTotalEffect > p2.nTotalEffect
	end)
	-- 默认选中第一个
	if this.bFirstRendering then
		if aResult[1] then
			if szPrimarySort == 'Skill' then
				this.szSelectedSkill  = aResult[1].szKey
			else
				this.szSelectedTarget = aResult[1].szKey
			end
		end
		this.bFirstRendering = nil
	end
	local szSelected
	local szSelectedSkill  = this.szSelectedSkill
	local szSelectedTarget = this.szSelectedTarget
	if szPrimarySort == 'Skill' then
		szSelected = this.szSelectedSkill
	else
		szSelected = this.szSelectedTarget
	end
	-- 界面重绘
	local hSelectedItem
	this:Lookup('WndScroll_Skill'):SetSize(480, 112)
	this:Lookup('WndScroll_Skill', ''):SetSize(480, 112)
	this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
	local hList = this:Lookup('WndScroll_Skill', 'Handle_SkillList')
	hList:SetSize(480, 90)
	hList:Clear()
	for i, p in ipairs(aResult) do
		local hItem = hList:AppendItemFromIni(_C.szIniDetail, 'Handle_SkillItem')
		hItem:Lookup('Text_SkillNo'):SetText(i)
		hItem:Lookup('Text_SkillName'):SetText(p.szName)
		hItem:Lookup('Text_SkillCount'):SetText(p.nCount)
		hItem:Lookup('Text_SkillTotal'):SetText(p.nTotalEffect)
		hItem:Lookup('Text_SkillPercentage'):SetText(nTotalEffect > 0 and _L('%.1f%%', math.floor(p.nTotalEffect / nTotalEffect * 100)) or ' - ')
		
		if szPrimarySort == 'Skill' and szSelectedSkill == p.szKey or
		szPrimarySort == 'Target' and szSelectedTarget == p.szKey then
			hSelectedItem = hItem
			hItem:Lookup('Shadow_SkillEntry'):Show()
		end
		hItem.szKey = p.szKey
		hItem.OnItemLButtonDown = _C.OnDetailItemLButtonDown
	end
	hList:FormatAllItemPos()
	
	if szSelected and tData[szPrimarySort][szSelected] then
		this:Lookup('', 'Handle_Spliter'):Show()
		--------------- 二、技能释放结果列表更新 -----------------
		-- 数据收集
		local aResult, nTotalEffect, nCount = {}, tData[szPrimarySort][szSelected].nTotalEffect, tData[szPrimarySort][szSelected].nCount
		for nSkillResult, p in pairs(tData[szPrimarySort][szSelected].Detail) do
			table.insert(aResult, {
				nCount     = p.nCount    ,
				nMinEffect = p.nMinEffect,
				nAvgEffect = p.nAvgEffect,
				nMaxEffect = p.nMaxEffect,
				nTotalEffect = p.nTotalEffect,
				szSkillResult = SZ_SKILL_RESULT[nSkillResult],
			})
		end
		table.sort(aResult, function(p1, p2)
			return p1.nAvgEffect > p2.nAvgEffect
		end)
		-- 界面重绘
		this:Lookup('WndScroll_Detail'):Show()
		local hList = this:Lookup('WndScroll_Detail', 'Handle_DetailList')
		hList:Clear()
		for i, p in ipairs(aResult) do
			local hItem = hList:AppendItemFromIni(_C.szIniDetail, 'Handle_DetailItem')
			hItem:Lookup('Text_DetailNo'):SetText(i)
			hItem:Lookup('Text_DetailType'):SetText(p.szSkillResult)
			hItem:Lookup('Text_DetailMin'):SetText(p.nMinEffect)
			hItem:Lookup('Text_DetailAverage'):SetText(p.nAvgEffect)
			hItem:Lookup('Text_DetailMax'):SetText(p.nMaxEffect)
			hItem:Lookup('Text_DetailCount'):SetText(p.nCount)
			hItem:Lookup('Text_DetailPercent'):SetText(nCount > 0 and _L('%.1f%%', math.floor(p.nCount / nCount * 100)) or ' - ')
		end
		hList:FormatAllItemPos()
		
		-- 调整滚动条 增强用户体验
		if hSelectedItem and not this:Lookup('WndScroll_Target'):IsVisible() then
			-- 说明是刚从未选择状态切换过来 滚动条滚动到选中项
			local hScroll = this:Lookup('WndScroll_Skill/Scroll_Skill_List')
			hScroll:SetScrollPos(math.ceil(hScroll:GetStepCount() * hSelectedItem:GetIndex() / hSelectedItem:GetParent():GetItemCount()))
		end
		
		--------------- 三、技能释放结果列表更新 -----------------
		-- 数据收集
		local aResult, nTotalEffect = {}, tData[szPrimarySort][szSelected].nTotalEffect
		if szPrimarySort == 'Skill' then
			for id, p in pairs(tData.Skill[szSelectedSkill].Target) do
				table.insert(aResult, {
					nHitCount      = p.Count[SKILL_RESULT.HIT] or 0,
					nMissCount     = p.Count[SKILL_RESULT.MISS] or 0,
					nCriticalCount = p.Count[SKILL_RESULT.CRITICAL] or 0,
					nMaxEffect     = p.nMaxEffect,
					nTotalEffect   = p.nTotalEffect,
					szName         = MY_Recount.Data.GetNameAusID(id, DataDisplay),
				})
			end
		else
			for szSkillName, p in pairs(tData.Target[szSelectedTarget].Skill) do
				table.insert(aResult, {
					nHitCount      = p.Count[SKILL_RESULT.HIT] or 0,
					nMissCount     = p.Count[SKILL_RESULT.MISS] or 0,
					nCriticalCount = p.Count[SKILL_RESULT.CRITICAL] or 0,
					nMaxEffect     = p.nMaxEffect,
					nTotalEffect   = p.nTotalEffect,
					szName         = szSkillName,
				})
			end
		end
		table.sort(aResult, function(p1, p2)
			return p1.nTotalEffect > p2.nTotalEffect
		end)
		-- 界面重绘
		this:Lookup('WndScroll_Target'):Show()
		local hList = this:Lookup('WndScroll_Target', 'Handle_TargetList')
		hList:Clear()
		for i, p in ipairs(aResult) do
			local hItem = hList:AppendItemFromIni(_C.szIniDetail, 'Handle_TargetItem')
			hItem:Lookup('Text_TargetNo'):SetText(i)
			hItem:Lookup('Text_TargetName'):SetText(p.szName)
			hItem:Lookup('Text_TargetTotal'):SetText(p.nTotalEffect)
			hItem:Lookup('Text_TargetMax'):SetText(p.nMaxEffect)
			hItem:Lookup('Text_TargetHit'):SetText(p.nHitCount)
			hItem:Lookup('Text_TargetCritical'):SetText(p.nCriticalCount)
			hItem:Lookup('Text_TargetMiss'):SetText(p.nMissCount)
			hItem:Lookup('Text_TargetPercent'):SetText((nTotalEffect > 0 and _L('%.1f%%', math.floor(p.nTotalEffect / nTotalEffect * 100)) or ' - '))
		end
		hList:FormatAllItemPos()
	else
		this:Lookup('WndScroll_Skill'):SetSize(480, 348)
		this:Lookup('WndScroll_Skill', ''):SetSize(480, 348)
		this:Lookup('WndScroll_Skill', 'Handle_SkillList'):SetSize(480, 332)
		this:Lookup('WndScroll_Skill', 'Handle_SkillList'):FormatAllItemPos()
		this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
		this:Lookup('WndScroll_Detail'):Hide()
		this:Lookup('WndScroll_Target'):Hide()
		this:Lookup('', 'Handle_Spliter'):Hide()
	end
	
end
_C.OnDetailLButtonClick = function()
	local name = this:GetName()
	if name == 'Btn_Close' then
		MY.RegisterEsc(this:GetRoot():GetTreePath())
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Switch' then
		if this:GetRoot().szPrimarySort == 'Skill' then
			this:GetRoot().szPrimarySort = 'Target'
		else
			this:GetRoot().szPrimarySort = 'Skill'
		end
		this:GetRoot().nLastRedrawFrame = 0
	elseif name == 'Btn_Unselect' then
		this:GetRoot().szSelectedSkill  = nil
		this:GetRoot().szSelectedTarget = nil
		this:GetRoot().nLastRedrawFrame = 0
	end
end
_C.OnDetailItemLButtonDown = function()
	local name = this:GetName()
	if name == 'Handle_SkillItem' then
		if this:GetRoot().szPrimarySort == 'Skill' then
			this:GetRoot().szSelectedSkill = this.szKey
		else
			this:GetRoot().szSelectedTarget = this.szKey
		end
		this:GetRoot().nLastRedrawFrame = 0
	end
end

MY_Recount.OnItemLButtonClick = function()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = UI_GetClientPlayerID()
		name = 'Handle_LI_' .. UI_GetClientPlayerID()
	end
	name:gsub('Handle_LI_(.+)', function()
		local szChannel = SZ_CHANNEL_KEY[MY_Recount.nChannel]
		if not Station.Lookup('Normal/MY_Recount_' .. id .. '_' .. szChannel) then
			local frm = Wnd.OpenWindow(_C.szIniDetail, 'MY_Recount_' .. id .. '_' .. szChannel)
			frm.id = id
			frm.bFirstRendering = true
			frm.szChannel = szChannel
			frm.szPrimarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Skill') or 'Target'
			frm.szSecondarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Target') or 'Skill'
			frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
			frm.OnFrameBreathe = _C.OnDetailFrameBreathe
			frm.OnItemLButtonDown = _C.OnDetailItemLButtonDown
			frm:Lookup('', 'Text_Default'):SetText(MY_Recount.Data.GetNameAusID(id, DataDisplay) .. ' ' .. SZ_CHANNEL[MY_Recount.nChannel])
			MY.RegisterEsc(frm:GetTreePath(), function()
				if Station.Lookup('Normal/MY_Recount_' .. id .. '_' .. szChannel) then
					return true
				else
					MY.RegisterEsc('MY_Recount_' .. id .. '_' .. szChannel)
				end
			end, function()
				if frm.szSelectedSkill or frm.szSelectedTarget then
					frm.szSelectedSkill  = nil
					frm.szSelectedTarget = nil
				else
					MY.RegisterEsc(frm:GetTreePath())
					MY.UI(frm):remove()
				end
			end)
			
			MY.UI(frm):children('Btn_Close'):click(_C.OnDetailLButtonClick)
		end
	end)
end

MY_Recount.OnItemRefreshTip = function()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = UI_GetClientPlayerID()
		name = 'Handle_LI_' .. UI_GetClientPlayerID()
	end
	name:gsub('Handle_LI_(.+)', function()
		if tonumber(id) then
			id = tonumber(id)
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local tRec = DataDisplay[SZ_CHANNEL_KEY[MY_Recount.nChannel]][id]
		if tRec then
			local szXml = ''
			local szColon = g_tStrings.STR_COLON
			local t = {}
			for szSkillName, p in pairs(tRec.Skill) do
				table.insert(t, { szName = szSkillName, rec = p })
			end
			table.sort(t, function(p1, p2)
				return p1.rec.nTotal > p2.rec.nTotal
			end)
			for _, p in ipairs(t) do
				szXml = szXml .. GetFormatText(p.szName .. "\n", nil, 255, 150, 0)
				szXml = szXml .. GetFormatText(_L['total: '] .. p.rec.nTotal .. ' ' .. _L['effect: '] .. p.rec.nTotalEffect .. "\n")
				for _, nSkillResult in ipairs({
					SKILL_RESULT.HIT     ,
					SKILL_RESULT.INSIGHT ,
					SKILL_RESULT.CRITICAL,
					SKILL_RESULT.MISS    ,
				}) do
					local nCount = 0
					if p.rec.Detail[nSkillResult] then
						nCount = p.rec.Detail[nSkillResult].nCount
					end
					szXml = szXml .. GetFormatText(SZ_SKILL_RESULT[nSkillResult] .. szColon, nil, 255, 202, 126)
					szXml = szXml .. GetFormatText(string.format('%2d', nCount) .. ' ')
				end
				szXml = szXml .. GetFormatText('\n')
			end
			if DataDisplay.Awaytime[id] then
				szXml = szXml .. GetFormatText(_L(
					'away count: %d, away time: %ds',
					#DataDisplay.Awaytime[id],
					MY_Recount.Data.GeneAwayTime(DataDisplay, id, MY_Recount.bSysTimeMode)
				), nil, 255, 191, 255)
			end
			OutputTip(szXml, 500, {x, y, w, h})
		end
	end)
end

MY_Recount.OnItemMouseLeave = function()
	HideTip()
end

MY_Recount.OnLButtonClick = function()
	local name = this:GetName()
	if name == 'Btn_Right' then
		if MY_Recount.nChannel == CHANNEL.DPS then
			MY_Recount.nChannel = CHANNEL.HPS
		elseif MY_Recount.nChannel == CHANNEL.HPS then
			MY_Recount.nChannel = CHANNEL.BDPS
		elseif MY_Recount.nChannel == CHANNEL.BDPS then
			MY_Recount.nChannel = CHANNEL.BHPS
		elseif MY_Recount.nChannel == CHANNEL.BHPS then
			MY_Recount.nChannel = CHANNEL.DPS
		end
		MY_Recount.DrawUI()
	elseif name == 'Btn_Left' then
		if MY_Recount.nChannel == CHANNEL.HPS then
			MY_Recount.nChannel = CHANNEL.DPS
		elseif MY_Recount.nChannel == CHANNEL.BDPS then
			MY_Recount.nChannel = CHANNEL.HPS
		elseif MY_Recount.nChannel == CHANNEL.BHPS then
			MY_Recount.nChannel = CHANNEL.BDPS
		elseif MY_Recount.nChannel == CHANNEL.DPS then
			MY_Recount.nChannel = CHANNEL.BHPS
		end
		MY_Recount.DrawUI()
	elseif name == 'Btn_Option' then
		PopupMenu(MY_Recount.GetMenu())
	elseif name == 'Btn_History' then
		PopupMenu(MY_Recount.GetHistoryMenu())
	elseif name == 'Btn_Empty' then
		MY_Recount.Data.Push()
		MY_Recount.DisplayData(0)
		MY_Recount.DrawUI()
	elseif name == 'Btn_Issuance' then
		PopupMenu(MY_Recount.GetPublishMenu())
	end
end

MY_Recount.OnCheckBoxCheck = function()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		this:GetRoot():Lookup('Wnd_Main'):Hide()
		this:GetRoot():SetSize(280, 30)
		this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Hide()
	end
end

MY_Recount.OnCheckBoxUncheck = function()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		this:GetRoot():Lookup('Wnd_Main'):Show()
		this:GetRoot():SetSize(280, 262)
		this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Show()
	end
end


-- ################################################################################################## --
--         #       #             #           #                 #                         #   #        --
--   # # # # # # # # # # #         #       #             #     #                         #     #      --
--         #       #           # # # # # # # # #         #     #               # # # # # # # # # #    --
--                 # # #       #       #       #         # # # # # # # #       #         #            --
--   # # # # # # #             # # # # # # # # #       #       #               #         #            --
--     #     #       #         #       #       #     #         #               # # # #   #     #      --
--       #     #   #           # # # # # # # # #               #               #     #   #     #      --
--             #                       #                 # # # # # # #         #     #   #   #        --
--   # # # # # # # # # # #   # # # # # # # # # # #             #               #     #     #     #    --
--         #   #   #                   #                       #               #   # #   #   #   #    --
--       #     #     #                 #                       #               #       #       # #    --
--   # #       #       # #             #             # # # # # # # # # # #   #       #           #    --
-- ################################################################################################## --
-- 获取设置菜单
MY_Recount.GetMenu = function()
	local t = {
		szOption = _L["fight recount"],
		{
			szOption = _L['enable'],
			bCheck = true,
			bChecked = MY_Recount.bEnable,
			fnAction = function()
				MY_Recount.bEnable = not MY_Recount.bEnable
				if MY_Recount.bEnable then
					MY_Recount.Open()
				else
					MY_Recount.Close()
				end
			end,
		}, {
			szOption = _L['display as per second'],
			bCheck = true,
			bChecked = MY_Recount.bShowPerSec,
			fnAction = function()
				MY_Recount.bShowPerSec = not MY_Recount.bShowPerSec
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		}, {
			szOption = _L['display effective value'],
			bCheck = true,
			bChecked = MY_Recount.bShowEffect,
			fnAction = function()
				MY_Recount.bShowEffect = not MY_Recount.bShowEffect
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		}, {
			szOption = _L['uncount awaytime'],
			bCheck = true,
			bChecked = MY_Recount.bAwayMode,
			fnAction = function()
				MY_Recount.bAwayMode = not MY_Recount.bAwayMode
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		}, {
			szOption = _L['show nodata teammate'],
			bCheck = true,
			bChecked = MY_Recount.bShowNodataTeammate,
			fnAction = function()
				MY_Recount.bShowNodataTeammate = not MY_Recount.bShowNodataTeammate
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		}, {
			szOption = _L['use system time count'],
			bCheck = true,
			bChecked = MY_Recount.bSysTimeMode,
			fnAction = function()
				MY_Recount.bSysTimeMode = not MY_Recount.bSysTimeMode
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		},
		{   -- 切换统计类型
			szOption = _L['switch recount mode'],
			{
				szOption = _L['display only npc record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.NPC,
				fnAction = function()
					MY_Recount.nDisplayMode = DISPLAY_MODE.NPC
					MY_Recount.DrawUI()
				end,
			}, {
				szOption = _L['display only player record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.PLAYER,
				fnAction = function()
					MY_Recount.nDisplayMode = DISPLAY_MODE.PLAYER
					MY_Recount.DrawUI()
				end,
			}, {
				szOption = _L['display all record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.BOTH,
				fnAction = function()
					MY_Recount.nDisplayMode = DISPLAY_MODE.BOTH
					MY_Recount.DrawUI()
				end,
			}
		}
	}

	-- 过滤短时间记录
	local t1 = {
		szOption = _L['filter short fight'],
		fnDisable = function()
			return not MY_Recount.bEnable
		end,
	}
	for _, i in pairs({ -1, 10, 30, 60, 90, 120, 180 }) do
		local szOption
		if i < 0 then
			szOption = _L['no time limit']
		elseif i < 60 then
			szOption = _L('less than %d second', i)
		elseif i == 90 then
			szOption = _L('less than %d minute and a half', i / 60)
		else
			szOption = _L('less than %d minute', i / 60)
		end
		table.insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.Data.nMinFightTime == i,
			fnAction = function()
				MY_Recount.Data.nMinFightTime = i
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		})
	end
	table.insert(t, t1)

	-- 风格选择
	local t1 = {
		szOption = _L['theme'],
		fnDisable = function()
			return not MY_Recount.bEnable
		end,
	}
	for i, _ in ipairs(_C.tCustomCss) do
		table.insert(t1, {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nCss == i,
			fnAction = function()
				MY_Recount.LoadCustomCss(i)
				MY_Recount.DrawUI()
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		})
	end
	table.insert(t, t1)

	-- 数值刷新周期
	local t1 = {
		szOption = _L['redraw interval'],
		fnDisable = function()
			return not MY_Recount.bEnable
		end,
	}
	for _, i in ipairs({1, GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS, GLOBAL.GAME_FPS * 2}) do
		local szOption
		if i == 1 then
			szOption = _L['realtime refresh']
		else
			szOption = _L('every %.1f second', i / GLOBAL.GAME_FPS)
		end
		table.insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nDrawInterval == i,
			fnAction = function()
				MY_Recount.nDrawInterval = i
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		})
	end
	table.insert(t, t1)

	-- 最大历史记录
	local t1 = {
		szOption = _L['max history'],
		fnDisable = function()
			return not MY_Recount.bEnable
		end,
	}
	for i = 1, 20 do
		table.insert(t1, {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.Data.nMaxHistory == i,
			fnAction = function()
				MY_Recount.Data.nMaxHistory = i
			end,
			fnDisable = function()
				return not MY_Recount.bEnable
			end,
		})
	end
	table.insert(t, t1)

	return t
end

-- 获取历史记录菜单
MY_Recount.GetHistoryMenu = function()
	local t = {{
		szOption = _L["current fight"],
		rgb = (MY_Recount.Data.Get(0) == DataDisplay and {255, 255, 0}) or nil,
		fnAction = function()
			MY_Recount.DisplayData(0)
		end,
	}}
	
	for _, data in ipairs(MY_Recount.Data.Get()) do
		if data.UUID and data.nTimeDuring then
			local t1 = {
				szOption = (data.szBossName or '') .. ' (' .. MY.FormatTimeCount('M:ss', data.nTimeDuring) .. ')',
				rgb = (data == DataDisplay and {255, 255, 0}) or nil,
				fnAction = function()
					MY_Recount.DisplayData(data)
				end,
				szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
				nFrame = 49,
				nMouseOverFrame = 51,
				nIconWidth = 17,
				nIconHeight = 17,
				szLayer = "ICON_RIGHTMOST",
				fnClickIcon = function()
					MY_Recount.Data.Del(data)
					Wnd.CloseWindow('PopupMenuPanel')
				end,
			}
			table.insert(t, t1)
		end
	end
	
	table.insert(t, { bDevide = true })
	table.insert(t, {
		szOption = _L['auto save data while exit game'],
		bCheck = true, bChecked = MY_Recount.bSaveRecount,
		fnAction = function()
			MY_Recount.bSaveRecount = not MY_Recount.bSaveRecount
		end,
	})
	
	return t
end

-- 获取发布菜单
MY_Recount.GetPublishMenu = function()
	local t = {}
	
	local t1 = {
		szOption = _L['publish limit'],
	}
	for _, i in pairs({
		1,2,3,4,5,8,10,15,20,30,50,100
	}) do
		table.insert(t1, {
			szOption = _L('top %d', i),
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishLimit == i,
			fnAction = function()
				MY_Recount.nPublishLimit = i
			end,
		})
	end
	table.insert(t, t1)
	
	-- 发布类型
	table.insert(t, {
		szOption = _L['publish mode'],
		{
			szOption = _L['only effect value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.EFFECT
			end,
		}, {
			szOption = _L['only total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.TOTAL
			end,
		}, {
			szOption = _L['effect and total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.BOTH,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.BOTH
			end,
		}
	})
	
	for nChannel, szChannel in pairs({
		[PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
		[PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
		[PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
	}) do
		table.insert(t, {
			szOption = g_tStrings.tChannelName[szChannel],
			rgb = GetMsgFontColor(szChannel, true),
			fnAction = function()
				local frame = Station.Lookup('Normal/MY_Recount')
				if not frame then
					return
				end
				MY.Talk(
					nChannel,
					'[' .. _L['mingyi plugin'] .. ']' ..
					_L['fight recount'] .. ' - ' ..
					frame:Lookup('Wnd_Title', 'Text_Title'):GetText() ..
					((DataDisplay.szBossName and ' - ' .. DataDisplay.szBossName) or ''),
					nil,
					true
				)
				MY.Talk(nChannel, '------------------------')
				local hList      = frame:Lookup('Wnd_Main', 'Handle_List')
				local szUnit     = (' ' .. hList.szUnit) or ''
				local nTimeCount = hList.nTimeCount or 0
				local aResult = {} -- 收集数据
				local nMaxNameLen = 0
				for i = 0, MY_Recount.nPublishLimit do
					local hItem = hList:Lookup(i)
					if not hItem then
						break
					end
					table.insert(aResult, hItem.data)
					nMaxNameLen = math.max(nMaxNameLen, wstring.len(hItem.data.szName))
				end
				if not MY_Recount.bShowPerSec then
					nTimeCount = 1
					szUnit = ""
				end
				-- 发布数据
				for i, p in ipairs(aResult) do
					local szText = string.format('%02d', i) .. '.[' .. p.szName .. ']'
					for i = wstring.len(p.szName), nMaxNameLen - 1 do
						szText = szText .. g_tStrings.STR_ONE_CHINESE_SPACE
					end
					if MY_Recount.nPublishMode == PUBLISH_MODE.BOTH then
						szText = szText .. _L('%7d%s(Effect) %7d%s(Total)',
							p.nEffectValue / nTimeCount, szUnit,
							p.nValue / nTimeCount, szUnit
						)
					elseif MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT then
						szText = szText .. _L('%7d%s(Effect)',
							p.nEffectValue / nTimeCount, szUnit
						)
					elseif MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL then
						szText = szText .. _L('%7d%s(Total)',
							p.nValue / nTimeCount, szUnit
						)
					end
					
					MY.Talk(nChannel, szText, nil, p.id == p.szName)
				end
				
				MY.Talk(nChannel, '------------------------')
			end
		})
	end
	
	return t
end

MY.RegisterPlayerAddonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)
MY.RegisterTraceButtonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)
