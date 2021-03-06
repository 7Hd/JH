-- @Author: Webster
-- @Date:   2016-01-20 06:22:04
-- @Last Modified by:   Webster
-- @Last Modified time: 2016-02-13 08:45:32
local _L   = JH.LoadLangPack
local Chat = {}
GKP_Chat   = {}
function GKP_Chat.OnFrameCreate()
	this:RegisterEvent("DISTRIBUTE_ITEM")
	this:RegisterEvent("DOODAD_LEAVE_SCENE")
	this.box = this:Lookup("", "Box")
end

function GKP_Chat.OnEvent(szEvent)
	if szEvent == "DISTRIBUTE_ITEM" then
		Chat.CloseFrame(GetItem(arg1))
	elseif szEvent == "DOODAD_LEAVE_SCENE" then
		if arg0 == this.box.data.dwDoodadID then
			Wnd.CloseWindow(this)
		end
	end
end

-- OnMsgArrive
function Chat.OnMsgArrive(szMsg)
	local frame = Chat.GetFrame()
	if frame then
		local hScroll = frame:Lookup("WndScroll_Chat")
		local h = hScroll:Lookup("", "")
		szMsg = string.gsub(szMsg, _L["[Team]"], "")
		local AppendText = function()
			local t = TimeToDate(GetCurrentTime())
			return GetFormatText(string.format(" %02d:%02d:%02d ", t.hour, t.minute, t.second), 10, 255, 255, 255)
		end
		szMsg = AppendText() .. szMsg
		if MY and MY.Chat and MY.Chat.RenderLink then
			szMsg =  MY.Chat.RenderLink(szMsg)
		end
		if MY_Farbnamen and MY_Farbnamen.Render then
			szMsg = MY_Farbnamen.Render(szMsg)
		end
		local xml = "<image>path=" .. EncodeComponentsString("UI/Image/Button/ShopButton.uitex") .. " frame=1 eventid=786 w=20 h=20 script=\"this.OnItemLButtonClick=GKP.DistributionItem\nthis.OnItemMouseEnter=function() this:SetFrame(2) end\nthis.OnItemMouseLeave=function() this:SetFrame(1) end\"</<image>>"
		h:AppendItemFromString(xml)
		h:AppendItemFromString(szMsg)
		h:FormatAllItemPos()
		hScroll:Lookup("Scroll_All"):ScrollEnd()
	end
end

function Chat.GetFrame()
	return Station.Lookup("Normal/GKP_Chat")
end

-- 点击锤子图标预览 严格判断
function GKP.DistributionItem()
	local h, i = this:GetParent(), this:GetIndex()
	if not h or not i then
		error("GKP_ERROR -> UI_ERROR")
	end
	local szName = string.match(h:Lookup(i + 3):GetText(), "%[(.*)%]")
	local me     = Station.Lookup("Normal/GKP_Chat")
	local box    = me:Lookup("", "Box")
	local data   = box.data
	local doodad = GetDoodad(data.dwDoodadID)
	local aPartyMember = GKP_Loot.GetaPartyMember(doodad)
	local member = aPartyMember(szName)
	if member then
		GKP_Loot.GetMessageBox(member.dwID, data.dwDoodadID, data.data.dwID, data.data)
	else
		return JH.Alert(_L["No Pick up Object, may due to Network off - line"])
	end
end

function Chat.OpenFrame(item, menu, data)
	local frame = Chat.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(JH.GetAddonInfo().szRootPath .. "GKP/ui/GKP_Chat.ini", "GKP_Chat")
		GUI(frame):Point():RegisterClose(Chat.CloseFrame)
		:Append("WndButton2", { x = 380, y = 38, txt = _L["Stop Bidding"] }):Click(function()
			JH.Talk(_L["--- Stop Bidding ---"])
			JH.DelayCall(function() UnRegisterMsgMonitor(Chat.OnMsgArrive) end, 1000)
		end)
	end
	local box = frame:Lookup("", "Box")
	local txt = frame:Lookup("", "Text")
	txt:SetText(GetItemNameByItem(item))
	txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
	local h = frame:Lookup("WndScroll_Chat"):Lookup("", "")
	h:Clear()
	UpdataItemInfoBoxObject(box, item.nVersion, item.dwTabType, item.dwIndex, (item.nGenre == ITEM_GENRE.BOOK and item.nBookID) or (item.bCanStack and item.nStackNum) or nil)
	RegisterMsgMonitor(Chat.OnMsgArrive, { "MSG_TEAM" })
	box.OnItemLButtonClick = function()
		if IsCtrlKeyDown() or IsAltKeyDown() then
			return
		end
		PopupMenu(menu)
	end
	box.data = data
end

function Chat.CloseFrame(bCheck)
	local frame = Chat.GetFrame()
	if frame then
		if type(bCheck) == "userdata" then
			local box = frame:Lookup("", "Box")
			local nUiId, nVersion, dwTabType, dwIndex = select(2, box:GetObject())
			if bCheck.nUiId ~= nUiId or bCheck.nVersion ~= nVersion or bCheck.dwTabType ~= dwTabType or bCheck.dwIndex ~= dwIndex then
				return
			end
		end
		UnRegisterMsgMonitor(Chat.OnMsgArrive)
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

local ui = {
	OpenFrame = Chat.OpenFrame
}
setmetatable(GKP_Chat, { __index = ui, __newindex = function() end, __metatable = true })
