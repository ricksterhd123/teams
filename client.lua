--[[
    Kick, leave and disband
    TODO: these event names are bad and should be improved
]]

addEvent("teams:openCreator", true)
addEventHandler("teams:openCreator", resourceRoot,
function ()
    teamCreate:create(function (name, colour)
        triggerServerEvent("teams:onCreate", resourceRoot, name, colour)
    end)
end)

addEvent("teams:toggleCreator", true)
addEventHandler("teams:toggleCreator", resourceRoot, 
function (data)
    if teamCreate.visible then
        teamCreate:destroy()
    else
        teamCreate:create(function (name, colour)
            triggerServerEvent("teams:onCreate", resourceRoot, name, colour)
        end)
    end
end)

--[[
    Close team panel
]]
addEvent("teams:closeTeamPanel", true)
addEventHandler("teams:closeTeamPanel", resourceRoot,
function ()
    teamPanel:destroy()
end)

--[[
    update team panel
    TODO: seems a little pointless to update client if not visible
]]
addEvent("teams:updatePanel", true)
addEventHandler("teams:updatePanel", resourceRoot, 
function (members, onlineMembers)
    teamPanel:update(_, members, onlineMembers)
end)

--[[
    Client -> Server
    Server -> Client
]]
addEvent("teams:openPlayerList", true)
addEventHandler("teams:openPlayerList", resourceRoot,
function (players)
    playerList:create(300, 400)
    playerList:update(players)
end)

--[[
    Updates player list if someone login/logout/quit or kicked/joined team
]]
addEvent("teams:updatePlayerList", true)
addEventHandler("teams:updatePlayerList", resourceRoot,
function (players)
    if playerList.visible then
        playerList:update(players)
    end
end)

--[[
    Open and close team panel
]]
addEvent("teams:toggleTeamPanel", true)
addEventHandler("teams:toggleTeamPanel", resourceRoot, 
function (data)
    if teamPanel.visible then
        teamPanel:destroy()
    else
        teamPanel:update(data.name, data.members, data.onlineMembers, data.owner, data.thisAccName)
        teamPanel:create()
    end
end)
