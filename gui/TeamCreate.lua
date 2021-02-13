local screenW, screenH = guiGetScreenSize()
local TeamCreate = {
    edit = {},
    button = {},
    window = {},
    label = {},
    opened = false,
    name   = "",
    colour = {0,0,0}
}

function closedColorPicker(r,g,b,a)
    teamCreate:setColour(r,g,b)
end

function TeamCreate:create(createTeam)
    if self.opened then return end
    createTeam = createTeam or function (name, colour) iprint(name, colour) return end -- Default value
    self.window[1] = guiCreateWindow((screenW - 368) / 2, (screenH - 123) / 2, 368, 123, "Create team", false)
    guiWindowSetSizable(self.window[1], false)
    self.button[1] = guiCreateButton(20, 86, 100, 27, "Create", false, self.window[1])
    self.button[2] = guiCreateButton(125, 86, 100, 27, "Cancel", false, self.window[1])
    self.edit[1] = guiCreateEdit(95, 24, 263, 26, self.name, false, self.window[1])
    self.edit[2] = guiCreateEdit(95, 55, 263, 26, RGBToHex(self.colour[1], self.colour[2], self.colour[3]), false, self.window[1])
    self.label[1] = guiCreateLabel(8, 25, 77, 15, "Name", false, self.window[1])
    guiLabelSetHorizontalAlign(self.label[1], "center", false)
    guiLabelSetVerticalAlign(self.label[1], "center")
    self.label[2] = guiCreateLabel(8, 56, 77, 15, "Colour", false, self.window[1])
    guiLabelSetHorizontalAlign(self.label[2], "center", false)
    guiLabelSetVerticalAlign(self.label[2], "center")
    guiSetInputMode("no_binds_when_editing")
    showCursor(true)

    addEventHandler("onClientGUIChanged", self.edit[1], function() TeamCreate:setName(guiGetText(source)) end)
    addEventHandler("onClientGUIClick", self.edit[2], colorPicker.openSelect, false)
    addEventHandler("onClientGUIClick", self.button[1], 
    function ()
        if TeamCreate:valid() then
            createTeam(TeamCreate:getName(), TeamCreate:getRGBColour())
        else
            outputChatBox("#00FF00[Teams] #FF0000Invalid name or colour, please try again.", 255, 255, 255, true)
        end
    end, false)
    addEventHandler("onClientGUIClick", self.button[2],
    function ()
        TeamCreate:destroy()
    end, false)

    self.opened = true
end

function TeamCreate:setColour(r,g,b)
    if self.opened then
        guiSetText(self.edit[2], RGBToHex(r,g,b))
    end
    self.colour = {r,g,b}
end

function TeamCreate:setName(name)
    self.name = name
end

function TeamCreate:getName()
    return self.name
end

function TeamCreate:getColour()
    return self.colour
end

function TeamCreate:getRGBColour()
    return RGBToHex(unpack(self.colour))
end

function TeamCreate:valid()
    if not self.opened then return false end
    local tName = guiGetText(self.edit[1])
    local tColour = guiGetText(self.edit[2])
    return #tName > 0 and #tColour > 0
end

function TeamCreate:destroy()
    if not self.opened then return end
    destroyElement(self.window[1])
    showCursor(false)
    self.name = ""
    self.colour = {0, 0, 0}
    self.opened = false
end

teamCreate = TeamCreate