local _L = JH.LoadLangPack
WebSyncData = {
	tData = {}, --�Ժ�ʵ���Զ�������
}
RegisterCustomData("WebSyncData.tData")

local _WebSyncData = {
	tResult = {},
	key = {},
	tList = {},
	tUnused = nil,
	bSyncWebPage = false,
	tUrl = { -- ��ʱ���������� �벻Ҫ�޸�
		szConfigList = "http://www.j3ui.com/list/game/",
		szConfigList2 = "http://www.j3ui.com/list/game2/",
		szDownload = "http://www.j3ui.com/down/json/",		
		szKeyUrl = "http://www.j3ui.com/analysis/md5/",
	},
}
	
_WebSyncData.Search = function()
	GetUserInput("����aid�����������ֻ��߲��ֱ���",function(txt)
		local t = {}
		local x, y = _WebSyncData.Container:GetAllContentSize()
		for k,v in ipairs(_WebSyncData.tList) do
			if tonumber(txt) and v.aid == txt then
				table.insert(t,v)
				break
			elseif v.title:match(txt) then
				table.insert(t,v)
			elseif v.author:match(txt) then
				table.insert(t,v)
			end
		end
		if #t > 0 then
			_WebSyncData.Container:Clear()
			for i = 1 , #t do 
				_WebSyncData.AppendItem(t[i],t[i].aid,i)
			end
			_WebSyncData.Container:FormatAllContentPos()
		else
			JH.Alert("û�����������")
		end
	end)	
end

_WebSyncData.GetData = function()
	local fnAction = function(szText)
		if szText ~= "" then
			_WebSyncData.SyncTip(_L["Loading..."],{255,255,0})
			local szUrl = _WebSyncData.tUrl.szKeyUrl.. szText .. "&_".. GetCurrentTime()
			JH.RemoteRequest(szUrl,function(szTitle,szDoc)
				local result,err = JH.JsonDecode(JH.UrlDecode(szDoc))
				if not result then
					_WebSyncData.SyncTip(true)
					return JH.Sysmsg2(err)
				else
				-- c 418524171f9f757d9dde6a40aef60e85
					_WebSyncData.SyncTip(true)
					table.insert(_WebSyncData.key,result)
					_WebSyncData.RefreshList()
				end
			end)
		end
	end
	GetUserInput("�������ļ�MD5����վ�ܿ���",fnAction)
end

_WebSyncData.SyncTeam = function()
	if _WebSyncData.bSyncWebPage then
		return
	end
	if not _WebSyncData.tUnused then
		return JH.Alert("��ѡ��һ��������ִ�в���")
	end
	local me = GetClientPlayer()
	if not me.IsInParty() then
		return JH.Alert("��û����ӡ�")
	end
	local team = GetClientTeam()
	local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	if szLeader ~= me.szName then
		return JH.Alert("�㲻���ų���")
	end
	JH.Confirm("ȷ��ͬ���𣿣�������ǰ֪ͨ���ѣ���",function()
		local t = _WebSyncData.tUnused.tData
		JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "WebSyncTean", "WebSyncTean", t.aid, JH.AscIIEncode(t.title), JH.AscIIEncode(t.author), t.dateline, JH.AscIIEncode(t.md5))
	end)
end

JH.RegisterEvent("ON_BG_CHANNEL_MSG",function()
	local data = JH.BgHear("WebSyncTean", true)
	if data then
		if data[1] == "WebSyncTean" and WebSyncData then
			WebSyncData.OpenPanel(data[2], data[3], data[4], data[5], data[6])
		end
		if data[1] == "Load" then
			JH.Sysmsg(arg3 .." ʹ���ˣ�" .. data[2], "�Ŷ�����")
		end
	end
end)

WebSyncData.OnFrameCreate = function()
	local ui = GUI(this)
	ui:Append("WndButton3", { x = 30, y = 630, txt = "ͬ����ȫ��" })
	:Click(_WebSyncData.SyncTeam)
	ui:Append("WndButton3", { x = 180, y = 630, txt = "�Ƽ�����" })
	:Click(_WebSyncData.RefreshList)
	ui:Append("WndButton3", { x = 330, y = 630, txt = "��������" })
	:Click(function()
		_WebSyncData.RefreshList(true)
	end)
	ui:Append("WndButton3", { x = 480, y = 630, txt = "�رո���֪ͨ" })
	:Click(function()
		WebSyncData.tData = {}
		JH.Sysmsg("���´�ѡ������֮ǰ����������ʾ�ˡ�")
		_WebSyncData.RefreshList()
	end)
	ui:Append("WndButton3", { x = 630, y = 630, txt = "����" })
	:Click(_WebSyncData.Search)
	ui:Append("WndButton3", { x = 780, y = 630, txt = "��ȡ˽������" })
	:Click(_WebSyncData.GetData)
	ui:Point():Close(_WebSyncData.ClosePanel)
	_WebSyncData.Container = this:Lookup("PageSet_Menu/Page_FileDownload/WndScroll_FileDownload/WndContainer_FileDownload_List")
end

_WebSyncData.OpenPanel = function( ... )
	local f = Station.Lookup("Normal/WebSyncData") or Wnd.OpenWindow("Interface/JH/RaidGrid_EventScrutiny/ui/WebSyncData.ini", "WebSyncData")
	f:BringToTop()
	_WebSyncData.RefreshList( ... )
end

_WebSyncData.RefreshList = function(aid, title, author, dateline, md5)
	-- if not _WebSyncData.bSyncWebPage then
		_WebSyncData.tUnused = nil
		local nTime = GetCurrentTime()
		local t = TimeToDate(nTime)
		local szDate = t.year .. t.month .. t.day .. t.hour .. t.minute
		_WebSyncData.Container:Clear()
		_WebSyncData.tList = {}
		if aid and title and author and dateline and md5 then
			_WebSyncData.tResult = { aid = aid,title = JH.AscIIDecode(title),author = JH.AscIIDecode(author),dateline = dateline ,md5 = JH.AscIIDecode(md5)}
		else
			_WebSyncData.tResult = {}
		end
		_WebSyncData.SyncTip(_L["Loading..."], { 255, 255, 0 })
		local url = _WebSyncData.tUrl.szConfigList
		if type(aid) == "boolean" then
			url = _WebSyncData.tUrl.szConfigList2
		end
		JH.RemoteRequest(url .. "?_" .. szDate,function(szTitle,szDoc)
			local result,err = JH.JsonDecode(JH.UrlDecode(szDoc))
			if err then
				JH.Sysmsg2(err)
			else
				_WebSyncData.LoadData(result)
				if not IsEmpty(_WebSyncData.tResult) then
					_WebSyncData.ItemRButtonClick(_WebSyncData.tResult, true)
				end
			end
		end)
	-- end
end

_WebSyncData.ClosePanel = function()
	Wnd.CloseWindow(Station.Lookup("Normal/WebSyncData"))
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

-- format time
_WebSyncData.TimeToDate = function(nTime)
	local nNow = GetCurrentTime()
	local nTime = tonumber(nTime) or nNow
	local ndifference = nNow - nTime
	local fn = function(n)
		return string.format("%02d", n)
	end
	if ndifference < 60 then
		return "�ո�"
	elseif ndifference < 3600 then
		return string.format("%d����ǰ", ndifference / 60)
	elseif ndifference < 86400 then
		return string.format("%dСʱǰ", ndifference / 3600)
	else
		return string.format("%d��ǰ", ndifference / 86400)
	end
end


_WebSyncData.AppendItem = function(tData,aid,k)
	local wnd = _WebSyncData.Container:AppendContentFromIni("Interface/JH/RaidGrid_EventScrutiny/ui/Data_ListItem.ini", "WndWindow")
	local item = wnd:Lookup("","")
	if k % 2 == 0 then
		item:Lookup("Image_Line"):Hide()
	end
	
	if item then
		item.tData = tData
		item:Lookup("Text_Author"):SetText(tData.author)
		item:Lookup("Text_Title"):SetText(tData.title)
	
		local nTime = GetCurrentTime()
		local szDate = _WebSyncData.TimeToDate(tData.dateline)
		item:Lookup("Text_Download"):SetText(szDate)
		if (nTime - tData.dateline) < 86400 then
			item:Lookup("Text_Download"):SetFontColor(255,255,0)
		end
		
		item.OnItemMouseEnter = function()
			if not _WebSyncData.bSyncWebPage then
				item:Lookup("Image_CoverBg"):Show()
				local txt = "���⣺" .. this.tData.title .. "\n"
				txt = txt .. "���ߣ�" .. this.tData.author .. "\n"
				txt = txt .. "����ʱ�䣺" .. _WebSyncData.TimeToDate(this.tData.dateline) .. "\n"
				txt = txt .. "���ش�����" .. this.tData.downloads
				_WebSyncData.MenuTip(this, txt)
			end
		end
		item.OnItemMouseLeave = function()
			if not _WebSyncData.bSyncWebPage then
				item:Lookup("Image_CoverBg"):Hide()
			end
		end
		item.OnItemLButtonClick = function()
			if not _WebSyncData.bSyncWebPage then
				if _WebSyncData.tUnused then
					_WebSyncData.tUnused:Lookup("Image_Unused"):Hide()
				end
			end
			this:Lookup("Image_Unused"):Show()
			_WebSyncData.tUnused = this
		end

		if tData.color then
			item:Lookup("Text_Title"):SetFontColor("0x" .. string.sub(tData.color,0,2),"0x" .. string.sub(tData.color,2,4),"0x" .. string.sub(tData.color,4,6))
		end
		local btn = wnd:Lookup("WndButton")
		local btn2 = wnd:Lookup("WndButton2")
		btn.OnLButtonClick = function()
			_WebSyncData.ItemRButtonClick(tData, true)
		end
		btn2.OnLButtonClick = function()
			local url = "http://www.j3ui.com/#file/".. tData.tid
			if tData.url then
				url = "http://" .. tData.url
			end
			OpenInternetExplorer(url)
		end
		if tData.url then
			btn2:Lookup("","Text_Default2"):SetText("�鿴����")
			btn:Hide()
		end
		if WebSyncData.tData.aid and WebSyncData.tData.aid == tData.aid then
			item:Lookup("Text_Title"):SetFontColor(255,255,0)
			if WebSyncData.tData.md5 == tData.md5 then
				btn:Enable(false)
				btn:Lookup("","Text_Default"):SetText("ʹ����")
			else
				btn:Lookup("","Text_Default"):SetText("�и���")
				btn:Lookup("","Text_Default"):SetFontColor(255,255,0)
				JH.Confirm("������3���Ŷ��¼���� ���ݸ�����ʾ\n��鵽��ǰʹ�õ������и��� �Ƿ���£�\n�����ݣ�"..tData.title .. "\n�����������ߣ�" .. tData.author .."�����͵ĸ���,���������������رո��¡�",function()
					_WebSyncData.ItemRButtonClick(tData, true)
				end)
			end
		end
		
	end
end


_WebSyncData.LoadData = function(result)
	local k = 1
	if #_WebSyncData.key > 0 then
		for i = 1 , #_WebSyncData.key do
			_WebSyncData.AppendItem(_WebSyncData.key[i],_WebSyncData.key[i].aid,k)
			k = k + 1
			table.insert(_WebSyncData.tList,_WebSyncData.key[i])
		end
	end
	for i = 1 , #result["top"] do
		_WebSyncData.AppendItem(result["top"][i],result["top"][i].aid,k)
		k = k + 1
		table.insert(_WebSyncData.tList,result["top"][i])
	end
	for i = 1 , #result["usually"] do
		_WebSyncData.AppendItem(result["usually"][i],result["usually"][i].aid,k)
		k = k + 1
		table.insert(_WebSyncData.tList,result["usually"][i])
	end	
	_WebSyncData.Container:FormatAllContentPos()
	_WebSyncData.SyncTip(true)
end

WebSyncData.OnMouseLeave = function()
	HideTip()
end

_WebSyncData.MenuTip = function(hItem, text)
	if not hItem then return end
	local x, y = hItem:GetAbsPos()
	local w, h = hItem:GetSize()
	if text then
		local szXml = GetFormatText(text, 47, 255, 255, 255)
		OutputTip(szXml, 435, {x, y, w - 600, h})
	end
end
_WebSyncData.ItemRButtonClick = function(tData, bSync)
	HideTip()
	local self = tData
	local me = GetClientPlayer()
	if self.aid then
		local fnAction = function(tData)
			local szText = GetFormatText("      ������3���Ŷ��¼���� ���ݸ�����ʾ\n",167,255,255,255)
			szText = szText..GetFormatText("      ���ݣ�".. tData.title .."\n",16)
			local msg = {
				szMessage = szText,
				bRichText = true,
				szName = "RaidGrid_Base_tRecordsClearNew",
				{szOption = "���ǵ���", fnAction = function()
					WebSyncData.tData = tData
					RaidGrid_Base.LoadSettingsFileNew("sync_data_" .. tData.aid, true)
					if me.IsInParty() then JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "WebSyncTean","Load",tData.title) end
					_WebSyncData.RefreshList()
				end},
				{szOption = "�ϲ�����", fnAction = function()
					WebSyncData.tData = tData
					RaidGrid_Base.LoadSettingsFileNew("sync_data_"..tData.aid, false)
					if me.IsInParty() then JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "WebSyncTean","Load",tData.title) end
					_WebSyncData.RefreshList()
				end},
				{szOption = "ȡ��"},
			}
			MessageBox(msg)
			_WebSyncData.SyncTip(true)
		end
		local fnSync = function()
			_WebSyncData.RemoteRequest(_WebSyncData.tUrl.szDownload, self, fnAction)
			_WebSyncData.SyncTip(_L["Loading..."], { 255, 255, 0 })
		end
		if bSync then
			fnSync()
		end
	end
end

_WebSyncData.RemoteRequest = function(szUrl, tData, fnAction)
	JH.RemoteRequest(szUrl..tData.aid.. "?" .. tData.dateline,function(szTitle,szDoc)
		local data = JH.JsonToTable(szDoc)
		local szFile = "Interface/JH/RaidGrid_EventScrutiny/alldat/sync_data_".. tData.aid .. ".jx3dat"
		pcall(SaveLUAData, szFile, data)
		pcall(fnAction, tData)
	end)
end

_WebSyncData.SyncTip = function(szText, col)
	local f = Station.Lookup("Normal/WebSyncData/WndWindow")
	if type(szText) == "boolean" and szText then
		_WebSyncData.bSyncWebPage = false
		f:Hide()
	else
		_WebSyncData.bSyncWebPage = true
		local t = f:Lookup("","Text_Tips_Msg")
		t:SetText(szText)
		t:SetFontColor(unpack(col))
		f:Show()
	end
end


local UIProtect = {
	OpenPanel = _WebSyncData.OpenPanel,
}
setmetatable(WebSyncData, { __index = UIProtect, __metatable = true, __newindex = function() --[[ print("Protect") ]] end } )