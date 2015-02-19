-----------------------------------------------
-- @Desc  : 中地图标记
--  记录所有NPC和Doodad位置 提供搜索和显示
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-12-04 11:51:31
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-02-19 22:04:05
-----------------------------------------------
MY_MiddleMapMark = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_MiddleMapMark/lang/")
local _C = {}
local _Cache = { tMapDataChanged = {} }
local Data = {}
local SZ_CACHE_PATH = "cache/NPC_DOODAD_REC/"
local MAX_DISTINCT_DISTANCE = 4 -- 最大独立距离4尺（低于该距离的两个实体视为同一个）
MAX_DISTINCT_DISTANCE = MAX_DISTINCT_DISTANCE * MAX_DISTINCT_DISTANCE * 64 * 64

-- HOOK MAP SWITCH
if MiddleMap._MY_MMM_ShowMap == nil then
	MiddleMap._MY_MMM_ShowMap = MiddleMap.ShowMap or false
end
MiddleMap.ShowMap = function(...)
	if MiddleMap._MY_MMM_ShowMap then
		MiddleMap._MY_MMM_ShowMap(...)
	end
	MY_MiddleMapMark.Search(_Cache.szKeyword)
	-- for mapid changing
	local dwMapID = MiddleMap.dwMapID
	MY.DelayCall(function()
		if dwMapID ~= MiddleMap.dwMapID then
			MY_MiddleMapMark.Search(_Cache.szKeyword)
		end
	end, 200)
end

-- HOOK OnEditChanged
if MiddleMap._MY_MMM_OnEditChanged == nil then
	MiddleMap._MY_MMM_OnEditChanged = MiddleMap.OnEditChanged or false
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
if MiddleMap._MY_MMM_OnMouseEnter == nil then
	MiddleMap._MY_MMM_OnMouseEnter = MiddleMap.OnMouseEnter or false
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
if MiddleMap._MY_MMM_OnMouseLeave == nil then
	MiddleMap._MY_MMM_OnMouseLeave = MiddleMap.OnMouseLeave or false
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
		uiHandle = ui:append("Handle", "Handle_MY_MMM"):item('#Handle_MY_MMM')
		  :pos(ui:item('#Handle_Map'):pos())
	end
	uiHandle:clear()
	
	_Cache.szKeyword = szKeyword
	if not szKeyword or szKeyword == '' then
		return
	end

	local dwMapID = MiddleMap.dwMapID or player.GetMapID()
	local tKeyword = MY.String.Split(szKeyword, ',')
	-- check if data exist
	local data = MY_MiddleMapMark.GetMapData(dwMapID)
	if not data then
		return
	end
	
	-- render npc mark
	for _, npc in ipairs(data.Npc) do
		local bMatch = false
		for _, kw in ipairs(tKeyword) do
			if string.find(npc.szName, kw) or
			string.find(npc.szTitle, kw) then
				bMatch = true
				break
			end
		end
		if bMatch then
			uiHandle:append('Image', 'Image_Npc_' .. npc.dwID):item('#Image_Npc_' .. npc.dwID)
			  :image('ui/Image/Minimap/MapMark.UITex|95')
			  :size(13, 13)
			  :pos(MiddleMap.LPosToHPos(npc.nX, npc.nY, 13, 13))
			  :tip(function()
			  	local szTip = npc.szName ..
			  	((npc.nLevel and npc.nLevel > 0 and ' lv.' .. npc.nLevel) or '') ..
			  	((npc.szTitle ~= '' and '\n<' .. npc.szTitle .. '>') or '')
			  	if IsCtrlKeyDown() then
			  		szTip = szTip .. ((npc.dwTemplateID and '\nNpc Template ID: ' .. npc.dwTemplateID))
			  	end
			  	return szTip
			  end,
			  MY.Const.UI.Tip.POS_TOP)
		end
	end
	
	-- render doodad mark
	for _, doodad in ipairs(data.Doodad) do
		local bMatch = false
		for _, kw in ipairs(tKeyword) do
		if string.find(doodad.szName, kw) then
				bMatch = true
				break
			end
		end
		if bMatch then
			uiHandle:append('Image', 'Image_Doodad_' .. doodad.dwID):item('#Image_Doodad_' .. doodad.dwID)
			  :image('ui/Image/Minimap/MapMark.UITex|95')
			  :size(13, 13)
			  :pos(MiddleMap.LPosToHPos(doodad.nX, doodad.nY, 13, 13))
			  :tip(function()
			  	local szTip = doodad.szName
			  	if IsCtrlKeyDown() then
			  		szTip = szTip .. ((doodad.dwTemplateID and '\nDoodad Template ID: ' .. doodad.dwTemplateID))
			  	end
			  	return szTip
			  end,
			  MY.Const.UI.Tip.POS_TOP)
		end
	end
end

MY_MiddleMapMark.GetMapData = function(dwMapID)
	-- if data not loaded, load it now
	if not Data[dwMapID] then
		MY_MiddleMapMark.StartDelayUnloadMapData(dwMapID)
		local data = MY.Json.Decode(MY.LoadLUAData(SZ_CACHE_PATH .. dwMapID)) or {
			Npc = {},
			Doodad = {},
		}
		for i = #data.Npc, 1, -1 do
			if ( data.Npc[i].dwTemplateID and
				_C.NpcTpl[data.Npc[i].dwTemplateID]
			) or MY.String.Trim(data.Npc[i].szName) == '' then
				table.remove(data.Npc, i)
				_Cache.tMapDataChanged[dwMapID] = true
			end
		end
		for i = #data.Doodad, 1, -1 do
			if ( data.Doodad[i].dwTemplateID and
				_C.DoodadTpl[data.Doodad[i].dwTemplateID]
			) or MY.String.Trim(data.Doodad[i].szName) == '' then
				table.remove(data.Doodad, i)
				_Cache.tMapDataChanged[dwMapID] = true
			end
		end
		Data[dwMapID] = data
		MY.Debug(Table_GetMapName(dwMapID) .. '(' .. dwMapID .. ') map data loaded.', 'MY_MiddleMapMark', 0)
	end
	return Data[dwMapID]
end

-- 开始指定地图的延时数据卸载时钟
MY_MiddleMapMark.StartDelayUnloadMapData = function(dwMapID)
	-- breathe until unload data
	MY.BreatheCall('MY_MiddleMapMark_DataUnload_' .. dwMapID, function()
		local player = GetClientPlayer()
		if player and player.GetMapID() ~= dwMapID and MiddleMap.dwMapID ~= dwMapID then
			MY_MiddleMapMark.UnloadMapData(dwMapID)
			return 0
		end
	end, 60000)
end

MY_MiddleMapMark.UnloadMapData = function(dwMapID)
	MY.Debug(Table_GetMapName(dwMapID) .. '(' .. dwMapID .. ') map data unloaded.', 'MY_MiddleMapMark', 0)
	Data[dwMapID] = nil
end

MY_MiddleMapMark.SaveMapData = function()
	for dwMapID, data in pairs(Data) do
		MY_MiddleMapMark.StartDelayUnloadMapData(dwMapID)
		if _Cache.tMapDataChanged[dwMapID] then
			MY.SaveLUAData(SZ_CACHE_PATH .. dwMapID, MY.Json.Encode(data))
		end
	end
end

_Cache.OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = ui:pos()
	local w, h = ui:size()
	
	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1')
	  :pos(20, 35)
	  :size(w - 32, h - 50)
	  :listbox('onlclick', function(text, id, data, selected)
	  	OpenMiddleMap(data.dwMapID, 0)
	  	MY.UI('Topmost1/MiddleMap/Wnd_Tool/Edit_Search'):text(MY.String.PatternEscape(data.szName))
	  	Station.SetFocusWindow('Topmost1/MiddleMap')
	  	if not selected then -- avoid unselect
	  		return false
	  	end
	  end)
	
	local muProgress = ui:append("Image", "Image_Progress"):item('#Image_Progress')
	  :pos(20, 31)
	  :size(w - 30, 4)
	  :image('ui/Image/UICommon/RaidTotal.UITex|45')
	
	ui:append("WndEditBox", "WndEdit_Search"):children('#WndEdit_Search')
	  :pos(18, 10)
	  :size(w - 26, 25)
	  :change(function(v)
	  	if not (v and #v > 0) then
	  		return
	  	end
	  	list:listbox('clear')
	  	local aMap = GetMapList()
	  	local i, N = 1, #aMap
	  	local n, M = 0, 200

	  	MY.BreatheCall('MY_MiddleMapMark_Searching_Threading', function()
	  		for _ = 1, 10 do
	  			local dwMapID = aMap[i]
	  			local data = MY_MiddleMapMark.GetMapData(dwMapID)
	  			local tNames = {}
	  			for _, p in ipairs(data.Npc) do
	  				if not tNames[p.szName]
	  				and (wstring.find(p.szName, v) or
	  				wstring.find(p.szTitle, v)) then
	  					list:listbox('insert', '[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName ..
	  					((p.szTitle and #p.szTitle > 0 and '<' .. p.szTitle .. '>') or ''), nil, {
	  						dwMapID = dwMapID ,
	  						szName  = p.szName,
	  					})
	  					n = n + 1
	  					tNames[p.szName] = true
	  				end
	  				if n > M then
	  					return 0
	  				end
	  			end
	  			local tNames = {}
	  			for _, p in ipairs(data.Doodad) do
	  				if not tNames[p.szName] and wstring.find(p.szName, v) then
	  					list:listbox('insert', '[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName, nil, {
	  						dwMapID = dwMapID ,
	  						szName  = p.szName,
	  					})
	  					n = n + 1
	  					tNames[p.szName] = true
	  				end
	  				if n > M then
	  					return 0
	  				end
	  			end
	  			muProgress:width((w - 32) * i / N)

	  			i = i + 1
	  			if i > N then
	  				return 0
	  			end
	  		end
	  	end)
	  end)
end

_C.NpcTpl = {
	[5071 ] = true, -- 气场镇山河的屏幕扰动
	[6888 ] = true, -- 火树银花
	[6889 ] = true, -- 龙凤呈祥
	[6890 ] = true, -- 鞭炮
	[6893 ] = true, -- 窜天猴
	[15398] = true, -- 海誓山盟
	[15608] = true, -- 星月烟花
	[15609] = true, -- 萤火点点
	[15610] = true, -- 幽月凝光
	[15611] = true, -- 追风星辰
	[15618] = true, -- 玉清玄明
	[15619] = true, -- 吞吴
	[15620] = true, -- 轻离
	[15621] = true, -- 幽月乱花
	[15622] = true, -- 流光溢彩
	[15623] = true, -- 鱼跃魅影
	[15624] = true, -- 金宝暮夕
	[15625] = true, -- 初蕾吐蕊
	[15626] = true, -- 蓦然书香
	[15627] = true, -- 蓝色妖姬
	[15628] = true, -- 江枫渔火
	[15629] = true, -- 姹紫嫣红
	[15630] = true, -- 月半黄昏
	[16538] = true, -- 龙门金蛋
	
	[16594] = true, -- 青龙阵眼
	[16595] = true, -- 白虎阵眼
	[16596] = true, -- 朱雀阵眼
	[16597] = true, -- 玄武阵眼
	[16598] = true, -- 重御
	[16599] = true, -- 升景
	[16600] = true, -- 封门
	[16601] = true, -- 连华

	[24023] = true, -- 盗墓贼
	[27447] = true, -- 木武童
	[36921] = true, -- 藏宝洞口
	[36058] = true, -- 遗失的货物
	[39458] = true, -- 无间长情
	[41707] = true, -- 龙门金蛋
	
	[20107] = true, -- 标记点_白
	[20108] = true, -- 标记点_黄
	[20109] = true, -- 标记点_蓝
	[20110] = true, -- 标记点_绿
	[20111] = true, -- 标记点_红
	[36781] = true, -- 标记点_6
	[36782] = true, -- 标记点_7
	[36783] = true, -- 标记点_8
	[36784] = true, -- 标记点_9
	[36785] = true, -- 标记点_10
	
	-- 各种花盆老纸也是醉了 = =
	[14467] = true, -- 翠云草（花盆内用）
	[14468] = true, -- 风信子（花盆内用）
	[14469] = true, -- 葫芦（花盆内用）
	[14470] = true, -- 马蹄金（花盆内用）
	[14471] = true, -- 牡丹（花盆内用）
	[14472] = true, -- 蔷薇 （花盆内用）
	[14473] = true, -- 黍米（花盆内用）
	[14474] = true, -- 乌蕨（花盆内用） 
	[14475] = true, -- 仙客来（花盆内用）
	[14476] = true, -- 香蕉（花盆内用）
	[14477] = true, -- 香雪兰（花盆内用）
	[14478] = true, -- 萱草（花盆内用）
	[14479] = true, -- 雁来红（花盆内用）
	[14480] = true, -- 月季（花盆内用）
	[14481] = true, -- 紫绒蒿（花盆内用）
	[14482] = true, -- 绣球花（花盆内用）
	[14483] = true, -- 万寿菊（花盆内用）
	[14484] = true, -- 木芙蓉（花盆内用）
	[14485] = true, -- 幼苗一（花盆内用）
	[14486] = true, -- 幼苗二（花盆内用）
	[14487] = true, -- 幼苗三（花盆内用）
	[14488] = true, -- 幼苗四（花盆内用）
	[14489] = true, -- 幼苗五（花盆内用）
	[14490] = true, -- 幼苗六（花盆内用）
	[14491] = true, -- 幼苗七（花盆内用）
	[14492] = true, -- 翠云草幼芽-雨洛玉盆
	[14493] = true, -- 风信子幼芽-雨洛玉盆
	[14494] = true, -- 葫芦幼芽-雨洛玉盆
	[14495] = true, -- 马蹄金幼芽-雨洛玉盆
	[14496] = true, -- 牡丹幼芽-雨洛玉盆
	[14497] = true, -- 蔷薇幼芽-雨洛玉盆
	[14498] = true, -- 黍米幼芽-雨洛玉盆
	[14499] = true, -- 乌蕨幼芽-雨洛玉盆
	[14500] = true, -- 仙客来幼芽-雨洛玉盆
	[14501] = true, -- 香蕉幼芽-雨洛玉盆
	[14502] = true, -- 香雪兰幼芽-雨洛玉盆
	[14503] = true, -- 萱草幼芽-雨洛玉盆 
	[14504] = true, -- 雁来红幼芽-雨洛玉盆
	[14505] = true, -- 月季幼芽-雨洛玉盆
	[14506] = true, -- 紫绒蒿幼芽-雨洛玉盆
	[14507] = true, -- 绣球花幼芽-雨洛玉盆
	[14508] = true, -- 万寿菊幼芽-雨洛玉盆
	[14509] = true, -- 木芙蓉幼芽-雨洛玉盆
	[14510] = true, -- 翠云草幼苗-雨洛玉盆
	[14511] = true, -- 风信子幼苗-雨洛玉盆
	[14512] = true, -- 葫芦幼苗-雨洛玉盆
	[14513] = true, -- 马蹄金幼苗-雨洛玉盆
	
	[18805] = true, -- 车前草（花盆内用）
	[18806] = true, -- 虫草（花盆内用）
	[18807] = true, -- 川贝（花盆内用）
	[18808] = true, -- 大黄（花盆内用）
	[18809] = true, -- 防风（花盆内用）
	[18810] = true, -- 甘草（花盆内用）
	[18811] = true, -- 枸杞（花盆内用）
	[18812] = true, -- 金创小草（花盆内用） 
	[18813] = true, -- 金银花（花盆内用）
	[18814] = true, -- 兰草（花盆内用）
	[18815] = true, -- 麦冬（花盆内用）
	[18816] = true, -- 千里香（花盆内用）
	[18817] = true, -- 芍药（花盆内用）
	[18818] = true, -- 天麻（花盆内用）
	[18819] = true, -- 天名精（花盆内用）
	[18820] = true, -- 田七（花盆内用）
	[18821] = true, -- 五味子（花盆内用）
	[18822] = true, -- 仙茅（花盆内用）
	[18823] = true, -- 相思子（花盆内用）
	[18824] = true, -- 远志（花盆内用）
	[18825] = true, -- 陈一测试
	[18826] = true, -- 水箭
	[18828] = true, -- 车前草幼芽-雨洛玉盆
	[18829] = true, -- 虫草幼芽-雨洛玉盆
	[18830] = true, -- 川贝幼芽-雨洛玉盆
	[18831] = true, -- 大黄幼芽-雨洛玉盆
	[18832] = true, -- 防风幼芽-雨洛玉盆
	[18833] = true, -- 甘草幼芽-雨洛玉盆
	[18834] = true, -- 枸杞幼芽-雨洛玉盆
	[18835] = true, -- 金创小草幼芽-雨洛玉盆
	[18836] = true, -- 金银花幼芽-雨洛玉盆
	[18837] = true, -- 兰草幼芽-雨洛玉盆
	[18838] = true, -- 麦冬幼芽-雨洛玉盆
	[18839] = true, -- 千里香幼芽-雨洛玉盆 
	[18840] = true, -- 芍药幼芽-雨洛玉盆
	[18841] = true, -- 天麻幼芽-雨洛玉盆
	[18842] = true, -- 天名精幼芽-雨洛玉盆
	[18843] = true, -- 田七幼芽-雨洛玉盆
	[18844] = true, -- 五味子幼芽-雨洛玉盆
	[18845] = true, -- 仙茅幼芽-雨洛玉盆
	[18846] = true, -- 相思子幼芽-雨洛玉盆
	[18847] = true, -- 远志幼芽-雨洛玉盆
	[18848] = true, -- 车前草幼苗-雨洛玉盆
	[18849] = true, -- 虫草幼苗-雨洛玉盆
	[18850] = true, -- 川贝幼苗-雨洛玉盆
	[18851] = true, -- 大黄幼苗-雨洛玉盆
	[18852] = true, -- 防风幼苗-雨洛玉盆
	[18853] = true, -- 甘草幼苗-雨洛玉盆
	[18854] = true, -- 枸杞幼苗-雨洛玉盆
	[18855] = true, -- 金创小草幼苗-雨洛玉盆
	[18856] = true, -- 金银花幼苗-雨洛玉盆
	[18857] = true, -- 兰草幼苗-雨洛玉盆
	[18858] = true, -- 麦冬幼苗-雨洛玉盆 
	[18859] = true, -- 千里香幼苗-雨洛玉盆
	[18860] = true, -- 芍药幼苗-雨洛玉盆
	[18861] = true, -- 天麻幼苗-雨洛玉盆
	[18862] = true, -- 天名精幼苗-雨洛玉盆
	[18863] = true, -- 田七幼苗-雨洛玉盆
	[18864] = true, -- 五味子幼苗-雨洛玉盆
	[18865] = true, -- 仙茅幼苗-雨洛玉盆
	[18866] = true, -- 相思子幼苗-雨洛玉盆
	[18867] = true, -- 远志幼苗-雨洛玉盆
	[18868] = true, -- 车前草-雨洛玉盆
	[18869] = true, -- 虫草-雨洛玉盆
	[18870] = true, -- 川贝-雨洛玉盆
	[18871] = true, -- 大黄-雨洛玉盆
	[18872] = true, -- 防风-雨洛玉盆
	[18873] = true, -- 甘草-雨洛玉盆
	[18874] = true, -- 枸杞-雨洛玉盆
	[18875] = true, -- 金创小草-雨洛玉盆
	[18876] = true, -- 金银花-雨洛玉盆
	[18877] = true, -- 兰草-雨洛玉盆
	[18878] = true, -- 麦冬-雨洛玉盆
	[18879] = true, -- 千里香-雨洛玉盆 
	[18880] = true, -- 芍药-雨洛玉盆
	[18881] = true, -- 天麻-雨洛玉盆
	[18882] = true, -- 天名精-雨洛玉盆
	[18883] = true, -- 田七-雨洛玉盆
	[18884] = true, -- 五味子-雨洛玉盆
	[18885] = true, -- 仙茅-雨洛玉盆
	[18886] = true, -- 相思子-雨洛玉盆
	[18887] = true, -- 远志-雨洛玉盆
	
	[18931] = true, -- 车前草幼芽-风清玉盆
	[18932] = true, -- 虫草幼芽-风清玉盆
	[18933] = true, -- 川贝幼芽-风清玉盆
	[18934] = true, -- 大黄幼芽-风清玉盆
	[18935] = true, -- 防风幼芽-风清玉盆
	[18936] = true, -- 甘草幼芽-风清玉盆
	[18937] = true, -- 枸杞幼芽-风清玉盆
	[18938] = true, -- 金创小草幼芽-风清玉盆
	[18939] = true, -- 金银花幼芽-风清玉盆
	[18940] = true, -- 兰草幼芽-风清玉盆
	[18941] = true, -- 麦冬幼芽-风清玉盆
	[18942] = true, -- 千里香幼芽-风清玉盆
	[18943] = true, -- 芍药幼芽-风清玉盆
	[18944] = true, -- 天麻幼芽-风清玉盆
	[18945] = true, -- 天名精幼芽-风清玉盆
	[18946] = true, -- 田七幼芽-风清玉盆
	[18947] = true, -- 五味子幼芽-风清玉盆
	[18948] = true, -- 仙茅幼芽-风清玉盆
	[18949] = true, -- 相思子幼芽-风清玉盆
	[18950] = true, -- 远志幼芽-风清玉盆
	[18951] = true, -- 车前草幼苗-风清玉盆
	[18952] = true, -- 虫草幼苗-风清玉盆
	[18953] = true, -- 川贝幼苗-风清玉盆
	[18954] = true, -- 大黄幼苗-风清玉盆
	[18955] = true, -- 防风幼苗-风清玉盆
	[18956] = true, -- 甘草幼苗-风清玉盆
	[18957] = true, -- 枸杞幼苗-风清玉盆
	[18958] = true, -- 金创小草幼苗-风清玉盆
	[18959] = true, -- 金银花幼苗-风清玉盆
	[18960] = true, -- 兰草幼苗-风清玉盆
	[18961] = true, -- 麦冬幼苗-风清玉盆
	[18962] = true, -- 千里香幼苗-风清玉盆
	[18963] = true, -- 芍药幼苗-风清玉盆
	[18964] = true, -- 天麻幼苗-风清玉盆
	[18965] = true, -- 天名精幼苗-风清玉盆
	[18966] = true, -- 田七幼苗-风清玉盆
	[18967] = true, -- 五味子幼苗-风清玉盆
	[18968] = true, -- 仙茅幼苗-风清玉盆
	[18969] = true, -- 相思子幼苗-风清玉盆
	[18970] = true, -- 远志幼苗-风清玉盆
	[18971] = true, -- 车前草-风清玉盆
	[18972] = true, -- 虫草-风清玉盆
	[18973] = true, -- 川贝-风清玉盆
	[18974] = true, -- 大黄-风清玉盆
	[18975] = true, -- 防风-风清玉盆
	[18976] = true, -- 甘草-风清玉盆
	[18977] = true, -- 枸杞-风清玉盆
	[18978] = true, -- 金创小草-风清玉盆
	[18979] = true, -- 金银花-风清玉盆
	[18980] = true, -- 兰草-风清玉盆
	[18981] = true, -- 麦冬-风清玉盆
	[18982] = true, -- 千里香-风清玉盆
	[18983] = true, -- 芍药-风清玉盆
	[18984] = true, -- 天麻-风清玉盆
	[18985] = true, -- 天名精-风清玉盆
	[18986] = true, -- 田七-风清玉盆
	[18987] = true, -- 五味子-风清玉盆
	[18988] = true, -- 仙茅-风清玉盆
	[18989] = true, -- 相思子-风清玉盆
	[18990] = true, -- 远志-风清玉盆
	[18991] = true, -- 车前草幼芽-云荔玉盆
	[18992] = true, -- 虫草幼芽-云荔玉盆
	[18993] = true, -- 川贝幼芽-云荔玉盆
	[18994] = true, -- 大黄幼芽-云荔玉盆
	[18995] = true, -- 防风幼芽-云荔玉盆
	[18996] = true, -- 甘草幼芽-云荔玉盆
	[18997] = true, -- 枸杞幼芽-云荔玉盆
	[18998] = true, -- 金创小草幼芽-云荔玉盆
	[18999] = true, -- 金银花幼芽-云荔玉盆
	[19000] = true, -- 兰草幼芽-云荔玉盆
	[19001] = true, -- 麦冬幼芽-云荔玉盆
	[19002] = true, -- 千里香幼芽-云荔玉盆
	[19003] = true, -- 芍药幼芽-云荔玉盆
	[19004] = true, -- 天麻幼芽-云荔玉盆
	[19005] = true, -- 天名精幼芽-云荔玉盆
	[19006] = true, -- 田七幼芽-云荔玉盆
	[19007] = true, -- 五味子幼芽-云荔玉盆
	[19008] = true, -- 仙茅幼芽-云荔玉盆
	[19009] = true, -- 相思子幼芽-云荔玉盆
	[19010] = true, -- 远志幼芽-云荔玉盆
	[19011] = true, -- 车前草幼苗-云荔玉盆
	[19012] = true, -- 虫草幼苗-云荔玉盆
	[19013] = true, -- 川贝幼苗-云荔玉盆
	[19014] = true, -- 大黄幼苗-云荔玉盆
	[19015] = true, -- 防风幼苗-云荔玉盆
	[19016] = true, -- 甘草幼苗-云荔玉盆
	[19017] = true, -- 枸杞幼苗-云荔玉盆
	[19018] = true, -- 金创小草幼苗-云荔玉盆
	[19019] = true, -- 金银花幼苗-云荔玉盆
	[19020] = true, -- 兰草幼苗-云荔玉盆
	[19021] = true, -- 麦冬幼苗-云荔玉盆
	[19022] = true, -- 千里香幼苗-云荔玉盆
	[19023] = true, -- 芍药幼苗-云荔玉盆
	[19024] = true, -- 天麻幼苗-云荔玉盆
	[19025] = true, -- 天名精幼苗-云荔玉盆
	[19026] = true, -- 田七幼苗-云荔玉盆
	[19027] = true, -- 五味子幼苗-云荔玉盆
	[19028] = true, -- 仙茅幼苗-云荔玉盆
	[19029] = true, -- 相思子幼苗-云荔玉盆
	[19030] = true, -- 远志幼苗-云荔玉盆
	[19031] = true, -- 车前草-云荔玉盆
	[19032] = true, -- 虫草-云荔玉盆
	[19033] = true, -- 川贝-云荔玉盆
	[19034] = true, -- 大黄-云荔玉盆
	[19035] = true, -- 防风-云荔玉盆
	[19036] = true, -- 甘草-云荔玉盆
	[19037] = true, -- 枸杞-云荔玉盆
	[19038] = true, -- 金创小草-云荔玉盆
	[19039] = true, -- 金银花-云荔玉盆
	[19040] = true, -- 兰草-云荔玉盆
	[19041] = true, -- 麦冬-云荔玉盆
	[19042] = true, -- 千里香-云荔玉盆
	[19043] = true, -- 芍药-云荔玉盆
	[19044] = true, -- 天麻-云荔玉盆
	[19045] = true, -- 天名精-云荔玉盆
	[19046] = true, -- 田七-云荔玉盆
	[19047] = true, -- 五味子-云荔玉盆
	[19048] = true, -- 仙茅-云荔玉盆
	[19049] = true, -- 相思子-云荔玉盆
	[19050] = true, -- 远志-云荔玉盆
	
	[20050] = true, -- 百脉根(花盆内用)
	[20051] = true, -- 紫花苜蓿（花盆内用）
	[20052] = true, -- 甜象草（花盆内用）
	[20053] = true, -- 皇竹草（花盆内用）
	[20054] = true, -- 百脉根-雨洛玉盆
	[20055] = true, -- 紫花苜蓿-雨洛玉盆
	[20056] = true, -- 甜象草-雨洛玉盆
	[20057] = true, -- 皇竹草-雨洛玉盆
	[20058] = true, -- 百脉根-风清玉盆
	[20059] = true, -- 紫花苜蓿-风清玉盆
	[20060] = true, -- 甜象草-风清玉盆
	[20061] = true, -- 皇竹草-风清玉盆
	[20062] = true, -- 百脉根-云荔玉盆
	[20063] = true, -- 紫花苜蓿-云荔玉盆
	[20064] = true, -- 甜象草-云荔玉盆
	[20065] = true, -- 皇竹草-云荔玉盆
	
	[20120] = true, -- 百脉幼芽-雨洛玉盆
	[20121] = true, -- 紫花幼芽-雨洛玉盆
	[20122] = true, -- 甜象草幼芽-雨洛玉盆
	[20123] = true, -- 皇竹草幼芽-雨洛玉盆
	[20124] = true, -- 百脉幼苗-雨洛玉盆
	[20125] = true, -- 紫花苜蓿幼苗-雨洛玉盆
	[20126] = true, -- 甜象草幼苗-雨洛玉盆
	[20127] = true, -- 皇竹草幼苗-雨洛玉盆
	[20128] = true, -- 百脉根幼芽-风清玉盆
	[20129] = true, -- 紫花苜蓿幼芽-风清玉盆
	[20130] = true, -- 甜象草幼芽-风清玉盆
	[20131] = true, -- 皇竹草幼芽-风清玉盆
	[20132] = true, -- 百脉根幼苗-风清玉盆
	[20133] = true, -- 紫花苜蓿幼苗-风清玉盆
	[20134] = true, -- 甜象草幼苗-风清玉盆
	[20135] = true, -- 皇竹草幼苗-风清玉盆
	[20136] = true, -- 百脉根幼芽-云荔玉盆
	[20137] = true, -- 紫花苜蓿幼芽-云荔玉盆
	[20138] = true, -- 甜象草幼芽-云荔玉盆
	[20139] = true, -- 皇竹草幼芽-云荔玉盆
	[20140] = true, -- 百脉根幼苗-云荔玉盆
	[20141] = true, -- 紫花苜蓿幼苗-云荔玉盆
	[20142] = true, -- 甜象草幼苗-云荔玉盆
	[20143] = true, -- 皇竹草幼苗-云荔玉盆

	[20596] = true, -- 海棠（花盆内用）
	[20597] = true, -- 菖蒲（花盆内用）
	[20598] = true, -- 海棠幼芽-雨洛玉盆
	[20599] = true, -- 菖蒲幼芽-雨洛玉盆
	[20600] = true, -- 海棠幼苗-雨洛玉盆
	[20601] = true, -- 菖蒲幼苗-雨洛玉盆
	[20602] = true, -- 海棠-雨洛玉盆
	[20603] = true, -- 菖蒲-雨洛玉盆
	[20604] = true, -- 海棠幼芽-风清玉盆
	[20605] = true, -- 菖蒲幼芽-风清玉盆
	[20606] = true, -- 海棠幼苗-风清玉盆
	[20607] = true, -- 菖蒲幼苗-风清玉盆
	[20608] = true, -- 海棠-风清玉盆
	[20609] = true, -- 菖蒲-风清玉盆
	[20610] = true, -- 海棠幼芽-云荔玉盆
	[20611] = true, -- 菖蒲幼芽-云荔玉盆
	[20612] = true, -- 海棠幼苗-云荔玉盆
	[20613] = true, -- 菖蒲幼苗-云荔玉盆
	[20614] = true, -- 海棠-云荔玉盆
	[20615] = true, -- 菖蒲-云荔玉盆


	[20688] = true, -- 茯苓（花盆内用）
	[20689] = true, -- 茯苓幼芽-雨洛玉盆
	[20690] = true, -- 茯苓幼苗-雨洛玉盆
	[20691] = true, -- 茯苓-雨洛玉盆
	[20692] = true, -- 茯苓幼芽-风清玉盆
	[20693] = true, -- 茯苓幼苗-风清玉盆
	[20694] = true, -- 茯苓-风清玉盆
	[20695] = true, -- 茯苓幼芽-云荔玉盆
	[20696] = true, -- 茯苓幼苗-云荔玉盆
	[20697] = true, -- 茯苓-云荔玉盆

	[22889] = true, -- 月季幼芽-雨洛玉盆
	[22890] = true, -- 月季幼苗-雨洛玉盆
	[22891] = true, -- 月季-雨洛玉盆
	[22892] = true, -- 月季幼芽-风清玉盆
	[22893] = true, -- 月季幼苗-风清玉盆
	[22894] = true, -- 月季-风清玉盆
	[22895] = true, -- 月季幼芽-云荔玉盆
	[22896] = true, -- 月季幼苗-云荔玉盆
	[22897] = true, -- 月季-云荔玉盆

	[25477] = true, -- 石莲花（花盆内用）
	[25478] = true, -- 彼岸花（花盆内用）
	[25479] = true, -- 石莲花幼芽-雨洛玉盆
	[25480] = true, -- 彼岸花幼芽-雨洛玉盆
	[25481] = true, -- 石莲花幼苗-雨洛玉盆
	[25482] = true, -- 彼岸花幼苗-雨洛玉盆
	[25483] = true, -- 石莲花-雨洛玉盆
	[25484] = true, -- 彼岸花-雨洛玉盆
	[25485] = true, -- 石莲花幼芽-风清玉盆
	[25486] = true, -- 彼岸花幼芽-风清玉盆
	[25487] = true, -- 石莲花幼苗-风清玉盆
	[25488] = true, -- 彼岸花幼苗-风清玉盆
	[25489] = true, -- 石莲花-风清玉盆
	[25490] = true, -- 彼岸花-风清玉盆
	[25491] = true, -- 石莲花幼芽-云荔玉盆
	[25492] = true, -- 彼岸花幼芽-云荔玉盆
	[25493] = true, -- 石莲花幼苗-云荔玉盆
	[25494] = true, -- 彼岸花幼苗-云荔玉盆
	[25495] = true, -- 石莲花-云荔玉盆
	[25496] = true, -- 彼岸花-云荔玉盆
}
_C.DoodadTpl = {
	[82   ] = true, -- 切磋用旗帜
	[1673 ] = true, -- 烟火_02
	[1674 ] = true, -- 烟火_03
	[1728 ] = true, -- 书桌
	[1764 ] = true, -- 烟花座
	[1912 ] = true, -- 交易
	[2418 ] = true, -- 仙王古鼎
	[2475 ] = true, -- 碧蝶/天珠/玉蟾
	[4719 ] = true, -- 新埋的土堆
	[4721 ] = true, -- 不起眼的小坑
	[4315 ] = true, -- 芙蓉出水宴
}
local m_nLastRedrawFrame = GetLogicFrameCount()
local MARK_RENDER_INTERVAL = GLOBAL.GAME_FPS * 5
MY.RegisterEvent("NPC_ENTER_SCENE",    "MY_MiddleMapMark", function()
	local npc = GetNpc(arg0)
	local player = GetClientPlayer()
	if not (npc and player) then
		return
	end
	-- avoid special npc
	if _C.NpcTpl[npc.dwTemplateID] then
		return
	end
	-- avoid player's pets
	if npc.dwEmployer and npc.dwEmployer ~= 0 then
		return
	end
	-- avoid full number named npc
	local szName = MY.GetObjectName(npc)
	if not szName or MY.String.Trim(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local data = MY_MiddleMapMark.GetMapData(dwMapID)
	
	-- keep data distinct
	for i = #data.Npc, 1, -1 do
		local p = data.Npc[i]
		if p.dwID == npc.dwID or
		p.dwTemplateID == npc.dwTemplateID and
		math.pow(npc.nX - p.nX, 2) + math.pow(npc.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
			table.remove(data.Npc, i)
		end
	end
	-- add rec
	table.insert(data.Npc, {
		nX = npc.nX,
		nY = npc.nY,
		dwID = npc.dwID,
		nLevel  = npc.nLevel,
		szName  = szName,
		szTitle = npc.szTitle,
		dwTemplateID = npc.dwTemplateID,
	})
	-- redraw ui
	if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
		m_nLastRedrawFrame = GetLogicFrameCount()
		MY_MiddleMapMark.Search(_Cache.szKeyword)
	end
	_Cache.tMapDataChanged[dwMapID] = true
end)
MY.RegisterEvent("DOODAD_ENTER_SCENE", "MY_MiddleMapMark", function()
	local doodad = GetDoodad(arg0)
	local player = GetClientPlayer()
	if not (doodad and player) then
		return
	end
	-- avoid special doodad
	if _C.DoodadTpl[doodad.dwTemplateID] then
		return
	end
	-- avoid full number named doodad
	local szName = MY.GetObjectName(doodad)
	if not szName or MY.String.Trim(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local data = MY_MiddleMapMark.GetMapData(dwMapID)
	
	-- keep data distinct
	for i = #data.Doodad, 1, -1 do
		local p = data.Doodad[i]
		if p.dwID == doodad.dwID or
		p.dwTemplateID == doodad.dwTemplateID and
		math.pow(doodad.nX - p.nX, 2) + math.pow(doodad.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
			table.remove(data.Doodad, i)
		end
	end
	-- add rec
	table.insert(data.Doodad, {
		nX = doodad.nX,
		nY = doodad.nY,
		dwID = doodad.dwID,
		szName  = szName,
		dwTemplateID = doodad.dwTemplateID,
	})
	-- redraw ui
	if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
		m_nLastRedrawFrame = GetLogicFrameCount()
		MY_MiddleMapMark.Search(_Cache.szKeyword)
	end
	_Cache.tMapDataChanged[dwMapID] = true
end)
MY.RegisterEvent('LOADING_END', MY_MiddleMapMark.SaveMapData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_MiddleMapMark.SaveMapData)
MY.RegisterPanel( "MY_MiddleMapMark", _L["middle map mark"], _L['General'],
	"ui/Image/MiddleMap/MapWindow2.UITex|4", {255,255,0,200}, {
		OnPanelActive = _Cache.OnPanelActive
	}
)
