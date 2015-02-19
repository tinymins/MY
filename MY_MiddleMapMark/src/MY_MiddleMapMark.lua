-----------------------------------------------
-- @Desc  : �е�ͼ���
--  ��¼����NPC��Doodadλ�� �ṩ��������ʾ
-- @Author: ���� @ ˫���� @ ݶ����
-- @Date  : 2014-12-04 11:51:31
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-02-19 22:04:05
-----------------------------------------------
MY_MiddleMapMark = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_MiddleMapMark/lang/")
local _C = {}
local _Cache = { tMapDataChanged = {} }
local Data = {}
local SZ_CACHE_PATH = "cache/NPC_DOODAD_REC/"
local MAX_DISTINCT_DISTANCE = 4 -- ����������4�ߣ����ڸþ��������ʵ����Ϊͬһ����
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

-- ��ʼָ����ͼ����ʱ����ж��ʱ��
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
	[5071 ] = true, -- ������ɽ�ӵ���Ļ�Ŷ�
	[6888 ] = true, -- ��������
	[6889 ] = true, -- �������
	[6890 ] = true, -- ����
	[6893 ] = true, -- �����
	[15398] = true, -- ����ɽ��
	[15608] = true, -- �����̻�
	[15609] = true, -- ө����
	[15610] = true, -- ��������
	[15611] = true, -- ׷���ǳ�
	[15618] = true, -- ��������
	[15619] = true, -- ����
	[15620] = true, -- ����
	[15621] = true, -- �����һ�
	[15622] = true, -- �������
	[15623] = true, -- ��Ծ��Ӱ
	[15624] = true, -- ��ĺϦ
	[15625] = true, -- ��������
	[15626] = true, -- ��Ȼ����
	[15627] = true, -- ��ɫ����
	[15628] = true, -- �������
	[15629] = true, -- ����̺�
	[15630] = true, -- �°�ƻ�
	[16538] = true, -- ���Ž�
	
	[16594] = true, -- ��������
	[16595] = true, -- �׻�����
	[16596] = true, -- ��ȸ����
	[16597] = true, -- ��������
	[16598] = true, -- ����
	[16599] = true, -- ����
	[16600] = true, -- ����
	[16601] = true, -- ����

	[24023] = true, -- ��Ĺ��
	[27447] = true, -- ľ��ͯ
	[36921] = true, -- �ر�����
	[36058] = true, -- ��ʧ�Ļ���
	[39458] = true, -- �޼䳤��
	[41707] = true, -- ���Ž�
	
	[20107] = true, -- ��ǵ�_��
	[20108] = true, -- ��ǵ�_��
	[20109] = true, -- ��ǵ�_��
	[20110] = true, -- ��ǵ�_��
	[20111] = true, -- ��ǵ�_��
	[36781] = true, -- ��ǵ�_6
	[36782] = true, -- ��ǵ�_7
	[36783] = true, -- ��ǵ�_8
	[36784] = true, -- ��ǵ�_9
	[36785] = true, -- ��ǵ�_10
	
	-- ���ֻ�����ֽҲ������ = =
	[14467] = true, -- ���Ʋݣ��������ã�
	[14468] = true, -- �����ӣ��������ã�
	[14469] = true, -- ��«���������ã�
	[14470] = true, -- ����𣨻������ã�
	[14471] = true, -- ĵ�����������ã�
	[14472] = true, -- Ǿޱ ���������ã�
	[14473] = true, -- ���ף��������ã�
	[14474] = true, -- ��ާ���������ã� 
	[14475] = true, -- �ɿ������������ã�
	[14476] = true, -- �㽶���������ã�
	[14477] = true, -- ��ѩ�����������ã�
	[14478] = true, -- ��ݣ��������ã�
	[14479] = true, -- �����죨�������ã�
	[14480] = true, -- �¼����������ã�
	[14481] = true, -- ������������ã�
	[14482] = true, -- ���򻨣��������ã�
	[14483] = true, -- ���پգ��������ã�
	[14484] = true, -- ľܽ�أ��������ã�
	[14485] = true, -- ����һ���������ã�
	[14486] = true, -- ��������������ã�
	[14487] = true, -- ���������������ã�
	[14488] = true, -- �����ģ��������ã�
	[14489] = true, -- �����壨�������ã�
	[14490] = true, -- ���������������ã�
	[14491] = true, -- �����ߣ��������ã�
	[14492] = true, -- ���Ʋ���ѿ-��������
	[14493] = true, -- ��������ѿ-��������
	[14494] = true, -- ��«��ѿ-��������
	[14495] = true, -- �������ѿ-��������
	[14496] = true, -- ĵ����ѿ-��������
	[14497] = true, -- Ǿޱ��ѿ-��������
	[14498] = true, -- ������ѿ-��������
	[14499] = true, -- ��ާ��ѿ-��������
	[14500] = true, -- �ɿ�����ѿ-��������
	[14501] = true, -- �㽶��ѿ-��������
	[14502] = true, -- ��ѩ����ѿ-��������
	[14503] = true, -- �����ѿ-�������� 
	[14504] = true, -- ��������ѿ-��������
	[14505] = true, -- �¼���ѿ-��������
	[14506] = true, -- ��������ѿ-��������
	[14507] = true, -- ������ѿ-��������
	[14508] = true, -- ���پ���ѿ-��������
	[14509] = true, -- ľܽ����ѿ-��������
	[14510] = true, -- ���Ʋ�����-��������
	[14511] = true, -- ����������-��������
	[14512] = true, -- ��«����-��������
	[14513] = true, -- ���������-��������
	
	[18805] = true, -- ��ǰ�ݣ��������ã�
	[18806] = true, -- ��ݣ��������ã�
	[18807] = true, -- �������������ã�
	[18808] = true, -- ��ƣ��������ã�
	[18809] = true, -- ���磨�������ã�
	[18810] = true, -- �ʲݣ��������ã�
	[18811] = true, -- ��轣��������ã�
	[18812] = true, -- ��С�ݣ��������ã� 
	[18813] = true, -- ���������������ã�
	[18814] = true, -- ���ݣ��������ã�
	[18815] = true, -- �󶬣��������ã�
	[18816] = true, -- ǧ���㣨�������ã�
	[18817] = true, -- ��ҩ���������ã�
	[18818] = true, -- ���飨�������ã�
	[18819] = true, -- ���������������ã�
	[18820] = true, -- ���ߣ��������ã�
	[18821] = true, -- ��ζ�ӣ��������ã�
	[18822] = true, -- ��é���������ã�
	[18823] = true, -- ��˼�ӣ��������ã�
	[18824] = true, -- Զ־���������ã�
	[18825] = true, -- ��һ����
	[18826] = true, -- ˮ��
	[18828] = true, -- ��ǰ����ѿ-��������
	[18829] = true, -- �����ѿ-��������
	[18830] = true, -- ������ѿ-��������
	[18831] = true, -- �����ѿ-��������
	[18832] = true, -- ������ѿ-��������
	[18833] = true, -- �ʲ���ѿ-��������
	[18834] = true, -- �����ѿ-��������
	[18835] = true, -- ��С����ѿ-��������
	[18836] = true, -- ��������ѿ-��������
	[18837] = true, -- ������ѿ-��������
	[18838] = true, -- ����ѿ-��������
	[18839] = true, -- ǧ������ѿ-�������� 
	[18840] = true, -- ��ҩ��ѿ-��������
	[18841] = true, -- ������ѿ-��������
	[18842] = true, -- ��������ѿ-��������
	[18843] = true, -- ������ѿ-��������
	[18844] = true, -- ��ζ����ѿ-��������
	[18845] = true, -- ��é��ѿ-��������
	[18846] = true, -- ��˼����ѿ-��������
	[18847] = true, -- Զ־��ѿ-��������
	[18848] = true, -- ��ǰ������-��������
	[18849] = true, -- �������-��������
	[18850] = true, -- ��������-��������
	[18851] = true, -- �������-��������
	[18852] = true, -- ��������-��������
	[18853] = true, -- �ʲ�����-��������
	[18854] = true, -- �������-��������
	[18855] = true, -- ��С������-��������
	[18856] = true, -- ����������-��������
	[18857] = true, -- ��������-��������
	[18858] = true, -- ������-�������� 
	[18859] = true, -- ǧ��������-��������
	[18860] = true, -- ��ҩ����-��������
	[18861] = true, -- ��������-��������
	[18862] = true, -- ����������-��������
	[18863] = true, -- ��������-��������
	[18864] = true, -- ��ζ������-��������
	[18865] = true, -- ��é����-��������
	[18866] = true, -- ��˼������-��������
	[18867] = true, -- Զ־����-��������
	[18868] = true, -- ��ǰ��-��������
	[18869] = true, -- ���-��������
	[18870] = true, -- ����-��������
	[18871] = true, -- ���-��������
	[18872] = true, -- ����-��������
	[18873] = true, -- �ʲ�-��������
	[18874] = true, -- ���-��������
	[18875] = true, -- ��С��-��������
	[18876] = true, -- ������-��������
	[18877] = true, -- ����-��������
	[18878] = true, -- ��-��������
	[18879] = true, -- ǧ����-�������� 
	[18880] = true, -- ��ҩ-��������
	[18881] = true, -- ����-��������
	[18882] = true, -- ������-��������
	[18883] = true, -- ����-��������
	[18884] = true, -- ��ζ��-��������
	[18885] = true, -- ��é-��������
	[18886] = true, -- ��˼��-��������
	[18887] = true, -- Զ־-��������
	
	[18931] = true, -- ��ǰ����ѿ-��������
	[18932] = true, -- �����ѿ-��������
	[18933] = true, -- ������ѿ-��������
	[18934] = true, -- �����ѿ-��������
	[18935] = true, -- ������ѿ-��������
	[18936] = true, -- �ʲ���ѿ-��������
	[18937] = true, -- �����ѿ-��������
	[18938] = true, -- ��С����ѿ-��������
	[18939] = true, -- ��������ѿ-��������
	[18940] = true, -- ������ѿ-��������
	[18941] = true, -- ����ѿ-��������
	[18942] = true, -- ǧ������ѿ-��������
	[18943] = true, -- ��ҩ��ѿ-��������
	[18944] = true, -- ������ѿ-��������
	[18945] = true, -- ��������ѿ-��������
	[18946] = true, -- ������ѿ-��������
	[18947] = true, -- ��ζ����ѿ-��������
	[18948] = true, -- ��é��ѿ-��������
	[18949] = true, -- ��˼����ѿ-��������
	[18950] = true, -- Զ־��ѿ-��������
	[18951] = true, -- ��ǰ������-��������
	[18952] = true, -- �������-��������
	[18953] = true, -- ��������-��������
	[18954] = true, -- �������-��������
	[18955] = true, -- ��������-��������
	[18956] = true, -- �ʲ�����-��������
	[18957] = true, -- �������-��������
	[18958] = true, -- ��С������-��������
	[18959] = true, -- ����������-��������
	[18960] = true, -- ��������-��������
	[18961] = true, -- ������-��������
	[18962] = true, -- ǧ��������-��������
	[18963] = true, -- ��ҩ����-��������
	[18964] = true, -- ��������-��������
	[18965] = true, -- ����������-��������
	[18966] = true, -- ��������-��������
	[18967] = true, -- ��ζ������-��������
	[18968] = true, -- ��é����-��������
	[18969] = true, -- ��˼������-��������
	[18970] = true, -- Զ־����-��������
	[18971] = true, -- ��ǰ��-��������
	[18972] = true, -- ���-��������
	[18973] = true, -- ����-��������
	[18974] = true, -- ���-��������
	[18975] = true, -- ����-��������
	[18976] = true, -- �ʲ�-��������
	[18977] = true, -- ���-��������
	[18978] = true, -- ��С��-��������
	[18979] = true, -- ������-��������
	[18980] = true, -- ����-��������
	[18981] = true, -- ��-��������
	[18982] = true, -- ǧ����-��������
	[18983] = true, -- ��ҩ-��������
	[18984] = true, -- ����-��������
	[18985] = true, -- ������-��������
	[18986] = true, -- ����-��������
	[18987] = true, -- ��ζ��-��������
	[18988] = true, -- ��é-��������
	[18989] = true, -- ��˼��-��������
	[18990] = true, -- Զ־-��������
	[18991] = true, -- ��ǰ����ѿ-��������
	[18992] = true, -- �����ѿ-��������
	[18993] = true, -- ������ѿ-��������
	[18994] = true, -- �����ѿ-��������
	[18995] = true, -- ������ѿ-��������
	[18996] = true, -- �ʲ���ѿ-��������
	[18997] = true, -- �����ѿ-��������
	[18998] = true, -- ��С����ѿ-��������
	[18999] = true, -- ��������ѿ-��������
	[19000] = true, -- ������ѿ-��������
	[19001] = true, -- ����ѿ-��������
	[19002] = true, -- ǧ������ѿ-��������
	[19003] = true, -- ��ҩ��ѿ-��������
	[19004] = true, -- ������ѿ-��������
	[19005] = true, -- ��������ѿ-��������
	[19006] = true, -- ������ѿ-��������
	[19007] = true, -- ��ζ����ѿ-��������
	[19008] = true, -- ��é��ѿ-��������
	[19009] = true, -- ��˼����ѿ-��������
	[19010] = true, -- Զ־��ѿ-��������
	[19011] = true, -- ��ǰ������-��������
	[19012] = true, -- �������-��������
	[19013] = true, -- ��������-��������
	[19014] = true, -- �������-��������
	[19015] = true, -- ��������-��������
	[19016] = true, -- �ʲ�����-��������
	[19017] = true, -- �������-��������
	[19018] = true, -- ��С������-��������
	[19019] = true, -- ����������-��������
	[19020] = true, -- ��������-��������
	[19021] = true, -- ������-��������
	[19022] = true, -- ǧ��������-��������
	[19023] = true, -- ��ҩ����-��������
	[19024] = true, -- ��������-��������
	[19025] = true, -- ����������-��������
	[19026] = true, -- ��������-��������
	[19027] = true, -- ��ζ������-��������
	[19028] = true, -- ��é����-��������
	[19029] = true, -- ��˼������-��������
	[19030] = true, -- Զ־����-��������
	[19031] = true, -- ��ǰ��-��������
	[19032] = true, -- ���-��������
	[19033] = true, -- ����-��������
	[19034] = true, -- ���-��������
	[19035] = true, -- ����-��������
	[19036] = true, -- �ʲ�-��������
	[19037] = true, -- ���-��������
	[19038] = true, -- ��С��-��������
	[19039] = true, -- ������-��������
	[19040] = true, -- ����-��������
	[19041] = true, -- ��-��������
	[19042] = true, -- ǧ����-��������
	[19043] = true, -- ��ҩ-��������
	[19044] = true, -- ����-��������
	[19045] = true, -- ������-��������
	[19046] = true, -- ����-��������
	[19047] = true, -- ��ζ��-��������
	[19048] = true, -- ��é-��������
	[19049] = true, -- ��˼��-��������
	[19050] = true, -- Զ־-��������
	
	[20050] = true, -- ������(��������)
	[20051] = true, -- �ϻ���ޣ���������ã�
	[20052] = true, -- ����ݣ��������ã�
	[20053] = true, -- ����ݣ��������ã�
	[20054] = true, -- ������-��������
	[20055] = true, -- �ϻ���ޣ-��������
	[20056] = true, -- �����-��������
	[20057] = true, -- �����-��������
	[20058] = true, -- ������-��������
	[20059] = true, -- �ϻ���ޣ-��������
	[20060] = true, -- �����-��������
	[20061] = true, -- �����-��������
	[20062] = true, -- ������-��������
	[20063] = true, -- �ϻ���ޣ-��������
	[20064] = true, -- �����-��������
	[20065] = true, -- �����-��������
	
	[20120] = true, -- ������ѿ-��������
	[20121] = true, -- �ϻ���ѿ-��������
	[20122] = true, -- �������ѿ-��������
	[20123] = true, -- �������ѿ-��������
	[20124] = true, -- ��������-��������
	[20125] = true, -- �ϻ���ޣ����-��������
	[20126] = true, -- ���������-��������
	[20127] = true, -- ���������-��������
	[20128] = true, -- ��������ѿ-��������
	[20129] = true, -- �ϻ���ޣ��ѿ-��������
	[20130] = true, -- �������ѿ-��������
	[20131] = true, -- �������ѿ-��������
	[20132] = true, -- ����������-��������
	[20133] = true, -- �ϻ���ޣ����-��������
	[20134] = true, -- ���������-��������
	[20135] = true, -- ���������-��������
	[20136] = true, -- ��������ѿ-��������
	[20137] = true, -- �ϻ���ޣ��ѿ-��������
	[20138] = true, -- �������ѿ-��������
	[20139] = true, -- �������ѿ-��������
	[20140] = true, -- ����������-��������
	[20141] = true, -- �ϻ���ޣ����-��������
	[20142] = true, -- ���������-��������
	[20143] = true, -- ���������-��������

	[20596] = true, -- ���ģ��������ã�
	[20597] = true, -- ���ѣ��������ã�
	[20598] = true, -- ������ѿ-��������
	[20599] = true, -- ������ѿ-��������
	[20600] = true, -- ��������-��������
	[20601] = true, -- ��������-��������
	[20602] = true, -- ����-��������
	[20603] = true, -- ����-��������
	[20604] = true, -- ������ѿ-��������
	[20605] = true, -- ������ѿ-��������
	[20606] = true, -- ��������-��������
	[20607] = true, -- ��������-��������
	[20608] = true, -- ����-��������
	[20609] = true, -- ����-��������
	[20610] = true, -- ������ѿ-��������
	[20611] = true, -- ������ѿ-��������
	[20612] = true, -- ��������-��������
	[20613] = true, -- ��������-��������
	[20614] = true, -- ����-��������
	[20615] = true, -- ����-��������


	[20688] = true, -- ���ߣ��������ã�
	[20689] = true, -- ������ѿ-��������
	[20690] = true, -- ��������-��������
	[20691] = true, -- ����-��������
	[20692] = true, -- ������ѿ-��������
	[20693] = true, -- ��������-��������
	[20694] = true, -- ����-��������
	[20695] = true, -- ������ѿ-��������
	[20696] = true, -- ��������-��������
	[20697] = true, -- ����-��������

	[22889] = true, -- �¼���ѿ-��������
	[22890] = true, -- �¼�����-��������
	[22891] = true, -- �¼�-��������
	[22892] = true, -- �¼���ѿ-��������
	[22893] = true, -- �¼�����-��������
	[22894] = true, -- �¼�-��������
	[22895] = true, -- �¼���ѿ-��������
	[22896] = true, -- �¼�����-��������
	[22897] = true, -- �¼�-��������

	[25477] = true, -- ʯ�������������ã�
	[25478] = true, -- �˰������������ã�
	[25479] = true, -- ʯ������ѿ-��������
	[25480] = true, -- �˰�����ѿ-��������
	[25481] = true, -- ʯ��������-��������
	[25482] = true, -- �˰�������-��������
	[25483] = true, -- ʯ����-��������
	[25484] = true, -- �˰���-��������
	[25485] = true, -- ʯ������ѿ-��������
	[25486] = true, -- �˰�����ѿ-��������
	[25487] = true, -- ʯ��������-��������
	[25488] = true, -- �˰�������-��������
	[25489] = true, -- ʯ����-��������
	[25490] = true, -- �˰���-��������
	[25491] = true, -- ʯ������ѿ-��������
	[25492] = true, -- �˰�����ѿ-��������
	[25493] = true, -- ʯ��������-��������
	[25494] = true, -- �˰�������-��������
	[25495] = true, -- ʯ����-��������
	[25496] = true, -- �˰���-��������
}
_C.DoodadTpl = {
	[82   ] = true, -- �д�������
	[1673 ] = true, -- �̻�_02
	[1674 ] = true, -- �̻�_03
	[1728 ] = true, -- ����
	[1764 ] = true, -- �̻���
	[1912 ] = true, -- ����
	[2418 ] = true, -- �����Ŷ�
	[2475 ] = true, -- �̵�/����/���
	[4719 ] = true, -- ���������
	[4721 ] = true, -- �����۵�С��
	[4315 ] = true, -- ܽ�س�ˮ��
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
