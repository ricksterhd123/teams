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
    teamCreate:create(
        function (name, colour)
            triggerServerEvent("teams:onCreate", localPlayer, name, colour)
        end
    )
end)

addEvent("teams:closeTeamPanel", true)
addEventHandler("teams:closeTeamPanel", resourceRoot,
function ()
    teamPanel:destroy()
end)

addEvent("teams:updatePanel", true)
addEventHandler("teams:updatePanel", root, 
function (clanMembers)
    teamPanel:update(_, clanMembers)
end)

-- Server requests source's client to open panel
addEvent("teams:openPanel", true)
addEventHandler("teams:openPanel", resourceRoot, 
function (data)
    teamPanel:update(data.name, data.members, data.owner, data.thisAccName)
    teamPanel:create(onTeamMemberLeave, onTeamMemberKick, onTeamMemberDisband)
end)