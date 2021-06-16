--- PlayerList GUI component
-- @author Exile
-- @usage GUI component lets user search and select player from list.


local PlayerList = {
    window = nil,
    gridlist = nil,
    editbox = nil,
    selectbtn = nil,
    cancelbtn = nil,
    visible = false,
    players = {}
}

--- Create PlayerList GUI component
-- @param width The width of the window
-- @param height The height of the window
-- @usage called to show GUI, destroy with :destroy() after finished 
function PlayerList:create(width, height)
    if self.visible then return false end

    local screenW, screenH = guiGetScreenSize()
    self.window = guiCreateWindow(screenW/2-(width/2), screenH/2-(height/2), width, height, "Invite player to team", false)
    self.editbox = guiCreateEdit(10, 30, width-10, 20, "", false, self.window)
    self.gridlist = guiCreateGridList(10, 60, width-10, height-100, false, self.window)
    self.selectbtn = guiCreateButton(10, height-35, 60, 20, "Invite", false, self.window)
    self.cancelbtn = guiCreateButton(75, height-35, 60, 20, "Cancel", false, self.window)

    guiGridListAddColumn(self.gridlist, "Player", 0.8)

    addEventHandler("onClientGUIChanged", self.editbox, function()
        local text = guiGetText(source)
        self.updateGridList(self, text)
    end, false)

    addEventHandler("onClientGUIClick", self.selectbtn, function()
        local gridList = self.gridlist
        local rowID, colID = guiGridListGetSelectedItem(gridList)
        local player = guiGridListGetItemText(gridList, rowID, colID)
        if player and #player > 0 then
            self.invite(self, player)
        end
    end, false)

    addEventHandler("onClientGUIClick", self.cancelbtn, function()
        self.destroy(self)
    end, false)

    guiSetInputMode("no_binds_when_editing")
    self.visible = true
end

--- Updates the state of gridlist given a filter
-- @param filter An optional param when given will filter the player list to match.
function PlayerList:updateGridList(filter)
    filter = filter or "" -- make it an optional param
    guiGridListClear(self.gridlist)
    for i, player in ipairs(self.players) do
        local playerName = getPlayerName(player)
        if string.find(playerName:lower(), filter:lower()) then
            -- strip hex from player name
            local name = playerName:gsub("#%x%x%x%x%x%x", "")
            guiGridListAddRow(self.gridlist, name)
        end
    end
end

--- Update state of PlayerList
-- @param players Table of player names
function PlayerList:update(players)
    self.players = players
    self:updateGridList() -- update gridList
end

--- Request server to invite player to team
-- @param player Player name to send invite
function PlayerList:invite(player)
    triggerServerEvent("team:onPlayerInvited", resourceRoot, player)
end

--- Tidy up
function PlayerList:destroy()
    destroyElement(self.window)
    self.window = nil
    self.gridlist = nil
    guiSetInputMode("allow_binds")
    self.visible = false
end

-- todo: oop
playerList = PlayerList
