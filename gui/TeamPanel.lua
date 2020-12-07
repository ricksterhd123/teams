local screenW, screenH = guiGetScreenSize()
local TeamPanel = {
    button = {},
    window = {},
    gridlist = {},
    fns = {},   -- functions which handle leave, kick and delete
    info = {    -- Information about the team
        clanName = "",
        members = {},
        membersOnline = {},
        isOwner = false,
        thisAccName = ""
    },
    opened = false,
    -- The buttons' function changes depending on the state
    mainBtnStates = {"Leave", "Kick", "Delete"},
    mainBtnState  = 1,
}

function TeamPanel:update(clanName, members, membersOnline, isOwner, thisAccName)
    self.info.clanName = clanName or self.info.clanName
    self.info.members = members or self.info.members
    self.info.membersOnline = membersOnline or self.info.membersOnline
    self.info.isOwner = isOwner or self.info.isOwner
    self.info.thisAccName = thisAccName or self.info.thisAccName

    -- TODO: Use a better GUI?
    if self.info.isOwner then
        if #self.info.members > 1 then
            self.mainBtnState = 2
        else
            self.mainBtnState = 3
        end
    else
        self.mainBtnState = 1 
    end

    if self.opened then
        guiSetText(self.button[1], self.mainBtnStates[self.mainBtnState])
        local handlers = getEventHandlers("onClientGUIClick", self.gridlist[1])
        for _, v in ipairs(handlers) do
            removeEventHandler("onClientGUIClick", self.gridlist[1], v)
        end
        destroyElement(self.gridlist[1])
        teamPanel:createGridList()
    end
end

function TeamPanel:createGridList()
    self.gridlist[1] = guiCreateGridList(12, 28, 450, 450, false, self.window[1])
    guiGridListAddColumn(self.gridlist[1], "Player", 0.9)
    
    -- Player creation
    for i = 1, #self.info.members do
        local id = guiGridListAddRow(self.gridlist[1])
        local accName = self.info.members[i].account
        guiGridListSetItemText(self.gridlist[1], id, 1, accName, false, false)

        for i, v in ipairs(self.info.membersOnline) do
            if accName == v then
                guiGridListSetItemColor(self.gridlist[1], id, 1, 255, 255, 255)
            end
        end

        if accName == self.info.thisAccName then
            guiGridListSetItemColor(self.gridlist[1], id, 1, 0, 255, 0)
        else
            guiGridListSetItemColor(self.gridlist[1], id, 1, 150, 0, 0)
        end
    end

    addEventHandler("onClientGUIClick", self.gridlist[1], function()
        local rid, cid = guiGridListGetSelectedItem(source)
        local selectedAcc = guiGridListGetItemText(source, rid, cid)
        if TeamPanel.mainBtnState == 2 then
            guiSetEnabled(TeamPanel.button[1], rid ~= -1 and selectedAcc ~= TeamPanel.info.thisAccName)
        else
            guiSetEnabled(TeamPanel.button[1], true)
        end
    end, false)
end

function TeamPanel:create(leave, kick, delete)
    if not self.opened then
        self.window[1] = guiCreateWindow((screenW - 600) / 2, (screenH - 500) / 2, 600, 500, self.info.clanName, false)
        guiWindowSetSizable(self.window[1], false)
        self.button[1] = guiCreateButton(470, 30, 110, 35, self.mainBtnStates[self.mainBtnState], false, self.window[1])
        guiSetEnabled(self.button[1], self.mainBtnState == 1 or self.mainBtnState == 3)   
        self.button[2] = guiCreateButton(470, 440, 110, 35, "Close", false, self.window[1])
        self.fns = {leave, kick, delete}
        self:createGridList()

        addEventHandler("onClientGUIClick", self.button[1], function()
            local fid = TeamPanel.mainBtnState
            local f = TeamPanel.fns[fid]
            iprint(fid)
            if fid == 2 then
                local gridlist = TeamPanel.gridlist[1]
                local rid, cid = guiGridListGetSelectedItem(gridlist)
                local selectedAcc = guiGridListGetItemText(gridlist, rid, cid)
                iprint(selectedAcc)
                f(selectedAcc)  -- kick selected player
            else
                f() -- leave/delete clan
            end
        end, false)

        addEventHandler("onClientGUIClick", self.button[2], function() TeamPanel:destroy() end, false)
        
        self.opened = true
        
        if not isCursorShowing() then
            showCursor(true)
        end
    end
end

function TeamPanel:destroy()
    if self.opened then
        if isCursorShowing() then
            showCursor(false)
        end

        destroyElement(self.window[1])
        self.opened = false
        self.members = {}
        self.mainBtnState = 1
        self.info = {
            clanName = "",
            members = {},
            isOwner = false,
            thisAccName = ""
        }
    end
end

teamPanel = TeamPanel