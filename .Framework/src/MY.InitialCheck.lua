local _L = MY.LoadLangPack()
local _C = {
	aData = {
		0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x75, 0x70, 0x64, 0x61, 0x74, 0x65, 0x2E, 0x6A, 0x78,
		0x33, 0x2E, 0x64, 0x65, 0x72, 0x7A, 0x68, 0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x64, 0x6F, 0x77, 0x6E,
		0x2F, 0x75, 0x70, 0x64, 0x61, 0x74, 0x65, 0x2E, 0x70, 0x68, 0x70,
	},
	nBreatheCount = 0,
}
MY_InitialCheck = {}
MY_InitialCheck.szTipId = nil
RegisterCustomData('MY_InitialCheck.szTipId')

MY.RegisterInit(function()
	MY.BreatheCall(function()
		local me, tong = GetClientPlayer(), GetTongClient()
		local szClientVer, szExeVer, szLang, szClientType = GetVersion()
		local szVerMY, iVerMY = MY.GetVersion()
		local _, tServer = MY.Game.GetServer()
		local data = {
			n = '', -- me.szName
			i = '', -- me.dwID
			l = '', -- me.nLevel
			f = '', -- me.dwForceID
			r = '', -- me.nRoleType
			c = '', -- me.nCamp
			m = '', -- me.GetMoney().nGold
			k = 0,  -- me.dwKillCount
			bs = 0,  -- me.GetBaseEquipScore()
			ts = 0,  -- me.GetTotalEquipScore()
			t = '', -- tong.szTongName
			_ = GetCurrentTime(),
			vc = szClientVer,
			ve = szExeVer,
			vl = szLang,
			vt = szClientType,
			mv = szVerMY,
			mi = iVerMY,
			s1 = tServer[1],
			s2 = tServer[2],
		}
		
		-- while not ready
		local bReady = true
		if me and me.szName and tong then
			data.n, data.i, data.l, data.f, data.r, data.c, data.m, data.k, data.bs, data.ts = me.szName, me.dwID, me.nLevel, me.dwForceID, me.nRoleType, me.nCamp, me.GetMoney().nGold, me.dwKillCount, me.GetBaseEquipScore(), me.GetTotalEquipScore()
			if me.dwTongID > 0 then
				data.t = tong.ApplyGetTongName(me.dwTongID)
				if (not data.t) or data.t == "" then
					bReady = false
				end
			else
				data.t = ""
			end
		else
			bReady = false
		end
		if (not bReady) and _C.nBreatheCount < 40 then
			_C.nBreatheCount = _C.nBreatheCount + 1
			return
		end
		
		-- start remote version check
		MY.RemoteRequest(string.format('%s?vl=%s&mi=%s&data=%s', string.char(unpack(_C.aData)), data.vl, data.mi, MY.String.SimpleEcrypt(MY.Json.Encode(data))), function(szTitle, szContent)
			-- decode data
			local data = MY.Json.Decode(szContent)
			if not data then
				MY.Debug(L["version check failed, sever resopnse unknow data.\n"],'MYVC',2)
				return
			end
			
			-- push message
			if data.tip and (data.tip.id ~= MY_InitialCheck.szTipId or data.tip.id == '') then
				-- sysmsg
				MY.Sysmsg({
					data.tip.content,
					r = data.tip.r or 255,
					g = data.tip.g or   0,
					b = data.tip.b or   0,
				})
				-- alert
				if data.tip.alert then
					MessageBox({
						szName = "MY_InitialCheck_Tips",
						szMessage = data.tip.content, {
							szOption = _L['got it'], fnAction = function()
								MY_InitialCheck.szTipId = data.tip.id
							end
						}, { szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end },
					})
				else
					MY_InitialCheck.szTipId = data.tip.id
				end
			end
			
			-- version update check
			local szVersion, nVersion = MY.GetVersion()
			if data.version > nVersion then
				-- new version msg
				MY.Sysmsg({ _L["new version found."], r=255, g=0, b=0 })
				MY.Sysmsg({ data.feature, r=255, g=0, b=0 })
				-- alert
				if data.alert then
					MessageBox({
						szName = "MY_VersionInfo",
						szMessage = string.format(
							"[%s] %s", _L["mingyi plugins"],
							_L["new version found, would you want to download immediately?"] ..
							((#data.feature > 0 and ('\n--------------------\n' .. data.feature)) or '')
						), {
							szOption = _L['download immediately'], fnAction = function()
								MY.UI.OpenInternetExplorer(data.file, true)
							end
						},{
							szOption = _L['see new feature'], fnAction = function()
								MY.UI.OpenInternetExplorer(data.page, true)
							end
						}, { szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end },
					})
				end
			end
			MY.Debug("Latest version: " .. data.version .. ", local version: " .. nVersion .. ' (' .. szVersion .. ")\n", 'MYVC', 0)
		end)
		
		-- cancel breathe call
		MY.Debug('Start Version Check!\n', 'MYVC', 0)
		return 0
	end, 3000)
end)
MY.Debug('Version Check Mod Loaded!\n', 'MYVC', 0)
