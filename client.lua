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

bindKey("F4", "down", function ()
    if teamCreate.opened then
        teamCreate:destroy()
    else
        teamCreate:create(
            function (name, colour)
                triggerServerEvent("teams:onCreate", localPlayer, name, colour)
            end
        )
    end
end)

addEvent("teams:closeTeamPanel", true)
addEventHandler("teams:closeTeamPanel", resourceRoot,
function ()
    teamPanel:destroy()
end)

addEvent("teams:updatePanel", true)
addEventHandler("teams:updatePanel", resourceRoot, 
function (members, onlineMembers)
    teamPanel:update(_, members, onlineMembers)
end)

-- Server requests source's client to open panel
addEvent("teams:openPanel", true)
addEventHandler("teams:openPanel", resourceRoot, 
function (data)
    teamPanel:update(data.name, data.members, data.onlineMembers, data.owner, data.thisAccName)
    teamPanel:create(onTeamMemberLeave, onTeamMemberKick, onTeamMemberDisband)
end)