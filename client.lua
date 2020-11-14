--[[
    Kick, leave and disband
]]

function onTeamMemberKick(selectedAcc)
    triggerServerEvent("teams:onKick", localPlayer, selectedAcc)
end

function onTeamMemberLeave()
    triggerServerEvent("teams:onLeave", localPlayer)
end

function onTeamMemberDisband()
    triggerServerEvent("teams:onDisband", localPlayer)
end

addEvent("teams:openCreator", true)
addEventHandler("teams:openCreator", resourceRoot,
function ()
    local createTeam = function (name, colour)
        triggerServerEvent("teams:onCreate", localPlayer, name, colour)
    end
    teamCreate:create(createTeam)
end)

addEvent("teams:closeCreator", true)
addEventHandler("teams:closeCreator", resourceRoot,
function ()
    teamCreate:destroy()
end)

addEvent("teams:updatePanel", true)
addEventHandler("teams:updatePanel", root, 
function ()

end)

-- Server requests source's client to open panel
addEvent("teams:openPanel", true)
addEventHandler("teams:openPanel", resourceRoot, 
function (data)
    local clanName = data.name
    local clanMembers = data.members
    local isOwner = data.owner
    local thisAccountName = data.thisAccName

    teamPanel:update(clanName, clanMembers, isOwner, thisAccountName)
    teamPanel:create(onTeamMemberLeave, onTeamMemberKick, onTeamMemberDisband)
end)