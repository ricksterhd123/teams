local TeamDatabase = teamDatabase("sqlite", "teams.db")
local ranks = {["owner"] = 1, ["member"] = 2}
local invites = {} -- Player invites

-- Player creates team and becomes its owner
addEvent("teams:onCreate", true)
addEventHandler("teams:onCreate", root,
function (name, colour)
    if client == source and getElementType(source) == "player" then 
        local ownerAcc = getPlayerAccount(source)
        if not isGuestAccount(ownerAcc) then
            local owner = getAccountName(ownerAcc)
            local clanName = TeamDatabase:getPlayerClanName(source)
            if not clanName then
                if TeamDatabase:createClan(owner, name, colour) then
                    outputChatBox("#00FF00[Teams] #FFFFFFYou have successfully created a team, please refer to F9 for useful information", source, 255, 255, 255, true)
                    setPlayerTeam(source, createTeam(name, HexToRGB(colour)))
                    outputServerLog("[Teams] "..getAccountName(ownerAcc).." created new team '"..name.."'")
                end
            elseif clanName == name then
                outputChatBox("#00FF00[Teams] #FF0000Team already exists, please use an original team name", source, 255, 255, 255, true)
            else
                outputChatBox("#00FF00[Teams] #FF0000You are already a team member", source, 255, 255, 255, true)
            end
        end
    end
end)

-- Owner kicks selected player
addEvent("teams:onKick", true)
addEventHandler("teams:onKick", root, 
function (accName)
    if client == source then
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["owner"] then
            local clanName = TeamDatabase:getAccountClanName(accName)
            if clanName then
                TeamDatabase:removeClanMember(accName)
                local team = getTeamFromName(clanName)
                if team and countPlayersInTeam(team) <= 1 then
                    destroyElement(team)
                    setPlayerTeam(source, nil)
                end
                triggerClientEvent(client, "teams:updatePanel", TeamDatabase:getOnlineClanMembers(clanName))
            end
        end
    end
end)

-- Owner deletes team
addEvent("teams:onDisband", true)
addEventHandler("teams:onDisband", root, 
function ()
    if client == source then
        local clanName = TeamDatabase:getPlayerClanName(source)
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["owner"] then
            TeamDatabase:removeClan(clanName)
            destroyElement(getTeamFromName(clanName))
            triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
        end
    end
end)

-- Member leaves team
addEvent("teams:onLeave", true)
addEventHandler("teams:onLeave", root, 
function ()
    if client == source then
        local clanName = TeamDatabase:getPlayerClanName(source)
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["member"] then
            TeamDatabase:removeClanMember(getAccountName(getPlayerAccount(source)))
            local team = getTeamFromName(clanName)
            if countPlayersInTeam(team) <= 1 then
                destroyElement(team)
            end
            triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
        end
    end
end)

-- Member opens panel
addCommandHandler("team", 
function (thePlayer)
    local acc = getPlayerAccount(thePlayer)
    if not isGuestAccount(acc) then
        local name = TeamDatabase:getPlayerClanName(thePlayer)
        -- Is the player a clan member?
        if name then
            local members = TeamDatabase:getClanMembers(name)
            local colour = TeamDatabase:getColourFromClanName(name)
            local rank = TeamDatabase:getPlayerRank(thePlayer)
            triggerClientEvent(thePlayer, "teams:openPanel", resourceRoot, {name=name, colour=colour, members=members, owner=rank==ranks["owner"], thisAccName=getAccountName(acc)})
        end
    end
end)

-- User requests to create team
addCommandHandler("registerteam", 
function (thePlayer)
    return not isGuestAccount(getPlayerAccount(thePlayer)) and not TeamDatabase:getPlayerClanName(thePlayer) and triggerClientEvent(thePlayer, "teams:openCreator", resourceRoot)
end)

addCommandHandler("teaminvite",
function (thePlayer, cmd, playerName)
    local clanName = TeamDatabase:getPlayerClanName(thePlayer)
    local player = getPlayerFromPartialName(playerName)
    if clanName and TeamDatabase:getPlayerRank(thePlayer) == ranks["owner"] and player and player ~= thePlayer and not isGuestAccount(getPlayerAccount(player)) then
        local isNotTeamMember = not TeamDatabase:getPlayerClanName(player)
        if isNotTeamMember and not invites[player] then
            invites[player] = clanName
            outputChatBox("#00FF00[Teams] #FFFFFF"..tostring(getPlayerName(thePlayer):gsub("#%x%x%x%x%x%x", "")).." has invited you to join '"..clanName.."'", player, 255, 255, 255, true)
            outputChatBox("#00FFF0[Teams] #FFFFFFYou have 10 seconds to type /teamaccept to accept", player, 255, 255, 255, true)
            setTimer(function(player) invites[player] = nil end, 10000, 1)
        end
    end
end)

addCommandHandler("teamaccept", 
function (thePlayer)
    local account = getPlayerAccount(thePlayer)
    local clanName = invites[thePlayer]
    if not isGuestAccount(account) and clanName then
        if TeamDatabase:addClanMember(account, clanName, ranks["member"]) then
            outputChatBox("#00FF00[Teams] #FFFFFFWelcome to '"..clanName.."'!", thePlayer, 255, 255, 255, true)
        end
    end
end)

addEventHandler("onPlayerLogin", root, 
function ()
    local name = TeamDatabase:getPlayerClanName(source)
    -- Is the player a clan member?
    if name then
        local team = getTeamFromName(name)
        if not team then
            team = createTeam(name, HexToRGB(TeamDatabase:getColourFromClanName(name)))
        end
        setPlayerTeam(source, team)
    end
end)

addEventHandler("onPlayerLogout", root, 
function ()
    local team = getPlayerTeam(source)
    if team then
        if countPlayersInTeam(team) <= 1 then
            destroyElement(team)
        end
    end
    setPlayerTeam(source, nil)
end)

addEventHandler("onPlayerQuit", root, 
function ()
    local team = getPlayerTeam(source)
    if team then
        if countPlayersInTeam(team) <= 1 then
            destroyElement(team)
        end
    end
end)