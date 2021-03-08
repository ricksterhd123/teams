local TeamDatabase = false
local ranks = {["owner"] = 1, ["member"] = 2}
local invites = {} -- Player invites

--[[
    Updates team panel for all online members
    [string] clanName - name of the clan
]]
local function updateTeamPanel(clanName)
    local onlineMembers, onlinePlayers  = TeamDatabase:getOnlineClanMembers(clanName)
    if onlineMembers then
        local allMembers = TeamDatabase:getClanMembers(clanName)
        for _, player in ipairs(onlinePlayers) do
            triggerClientEvent(player, "teams:updatePanel", resourceRoot, allMembers, onlineMembers)
        end
    end
end

-- Player creates team and becomes its owner
local function onCreate(name, colour)
    if client == source and getElementType(source) == "player" then 
        local ownerAcc = getPlayerAccount(source)
        if not isGuestAccount(ownerAcc) then
            local owner = getAccountName(ownerAcc)
            local clanName = TeamDatabase:getPlayerClanName(source)
            local id = TeamDatabase:getIDFromClanName(name)

            if not clanName and not id then
                if TeamDatabase:createClan(owner, name, colour) then
                    outputChatBox("#00FF00[Teams] #FFFFFFYou have successfully created a team, please refer to F10 for useful information", source, 255, 255, 255, true)
                    setPlayerTeam(source, createTeam(name, HexToRGB(colour)))
                    triggerClientEvent(source, "teams:toggleCreator", resourceRoot)
                    outputServerLog("[Teams] "..getAccountName(ownerAcc).." created new team '"..name.."'")
                end
            elseif id then
                outputChatBox("#00FF00[Teams] #FF0000Team already exists, please use an original team name", source, 255, 255, 255, true)
            else
                outputChatBox("#00FF00[Teams] #FF0000You are already a team member", source, 255, 255, 255, true)
            end
        end
    end
end
addEvent("teams:onCreate", true)
addEventHandler("teams:onCreate", root, onCreate)

-- Owner kicks selected player
local function onKick(accName)
    if client == source then
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["owner"] then
            local clanName = TeamDatabase:getAccountClanName(accName)
            if clanName then
                TeamDatabase:removeClanMember(accName)
                outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." kicked "..accName.." from "..clanName)

                local team = getTeamFromName(clanName)
                local player = getAccountPlayer(getAccount(accName))

                if team and player then
                    if countPlayersInTeam(team) <= 1 then
                        destroyElement(team)
                    else
                        setPlayerTeam(player, nil)
                    end
                    triggerClientEvent(player, "teams:closeTeamPanel", resourceRoot)
                end
                
                -- Update panel for online members
                updateTeamPanel(clanName)
            end
        end
    end
end
addEvent("teams:onKick", true)
addEventHandler("teams:onKick", root, onKick)

-- Owner deletes team
local function onDisband()
    if client == source then
        local clanName = TeamDatabase:getPlayerClanName(source)
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["owner"] then
            TeamDatabase:removeClan(clanName)
            destroyElement(getTeamFromName(clanName))
            triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
            outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." deleted "..clanName)
        end
    end
end
addEvent("teams:onDisband", true)
addEventHandler("teams:onDisband", root, onDisband)

-- Member leaves team
local function onLeave()
    if client == source then
        local clanName = TeamDatabase:getPlayerClanName(source)
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["member"] then
            TeamDatabase:removeClanMember(getAccountName(getPlayerAccount(source)))
            outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." left "..clanName)

            local team = getTeamFromName(clanName)
            if countPlayersInTeam(team) <= 1 then
                destroyElement(team)
            else
                setPlayerTeam(source, nil)
            end
            triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
            
            -- Update panel for online members
            updateTeamPanel(clanName)
        end
    end
end
addEvent("teams:onLeave", true)
addEventHandler("teams:onLeave", root, onLeave)

-- Member opens panel
local function openTeamPanel(thePlayer)
    local acc = getPlayerAccount(thePlayer)
    if not isGuestAccount(acc) then
        local name = TeamDatabase:getPlayerClanName(thePlayer)
        -- Is the player a clan member?
        if name then
            local members = TeamDatabase:getClanMembers(name)
            local onlineMembers = TeamDatabase:getOnlineClanMembers(name)
            local colour = TeamDatabase:getColourFromClanName(name)
            local rank = TeamDatabase:getPlayerRank(thePlayer)
            triggerClientEvent(thePlayer, "teams:openPanel", resourceRoot, {name=name, colour=colour, members=members, onlineMembers=onlineMembers, owner=rank==ranks["owner"], thisAccName=getAccountName(acc)})
        end
    end
end
addCommandHandler("team", openTeamPanel)

-- Player pressed F4
local function pressedF4(thePlayer)
    local acc = getPlayerAccount(thePlayer)
    if not isGuestAccount(acc) then
        local name = TeamDatabase:getPlayerClanName(thePlayer)
        if name then
            local members = TeamDatabase:getClanMembers(name)
            local onlineMembers = TeamDatabase:getOnlineClanMembers(name)
            local colour = TeamDatabase:getColourFromClanName(name)
            local rank = TeamDatabase:getPlayerRank(thePlayer)
            triggerClientEvent(thePlayer, "teams:toggleTeamPanel", resourceRoot, {name=name, colour=colour, members=members, onlineMembers=onlineMembers, owner=rank==ranks["owner"], thisAccName=getAccountName(acc)})
        else
            triggerClientEvent(thePlayer, "teams:toggleCreator", resourceRoot)
        end
    end
end

-- teaminvite command
-- Needs to be verbose
local function invite(thePlayer, cmd, playerName)
    local clanName = TeamDatabase:getPlayerClanName(thePlayer)
    local player = getPlayerFromPartialName(playerName)
    if clanName and TeamDatabase:getPlayerRank(thePlayer) == ranks["owner"] and player and player ~= thePlayer and not isGuestAccount(getPlayerAccount(player)) then
        local isNotTeamMember = not TeamDatabase:getPlayerClanName(player)
        if isNotTeamMember and not invites[player] then
            invites[player] = {thePlayer, clanName}
            outputChatBox("#00FF00[Teams] #FFFFFFYou have sent the invite to player '"..getPlayerName(player):gsub("#%x%x%x%x%x%x", ""), thePlayer, 255, 255, 255, true)
            outputChatBox("#00FF00[Teams] #FFFFFF"..getPlayerName(thePlayer):gsub("#%x%x%x%x%x%x", "").." has invited you to join '"..clanName.."'", player, 255, 255, 255, true)
            outputChatBox("#00FF00[Teams] #FFFFFFYou have 10 seconds to type /teamaccept to accept", player, 255, 255, 255, true)
            setTimer(function(player) invites[player] = nil end, 10000, 1, player)
        end
    end
end
addCommandHandler("teaminvite", invite)

-- teamaccept command
-- Needs to be verbose
local function acceptInvite(thePlayer)
    local account = getPlayerAccount(thePlayer)
    if invites[thePlayer] then
        local owner, clanName = unpack(invites[thePlayer])
        if not isGuestAccount(account) and clanName and owner then
            if TeamDatabase:addClanMember(getAccountName(account), clanName, ranks["member"]) then
                outputChatBox("#00FF00[Teams] #FFFFFFPlayer accepted invite!", owner, 255, 255, 255, true)
                outputChatBox("#00FF00[Teams] #FFFFFFWelcome to '"..clanName.."'!", thePlayer, 255, 255, 255, true)
                setPlayerTeam(thePlayer, getTeamFromName(clanName))
            end
        end
    end
end
addCommandHandler("teamaccept", acceptInvite)

addEventHandler("onResourceStart", resourceRoot,
function ()
    TeamDatabase = teamDatabase("sqlite", "teams.db")
    for _, player in ipairs(getElementsByType("player")) do
        local name = TeamDatabase:getPlayerClanName(player)
        -- Is the player a clan member?
        if name then
            local team = getTeamFromName(name)
            if not team then
                team = createTeam(name, HexToRGB(TeamDatabase:getColourFromClanName(name)))
            end
            setPlayerTeam(player, team)
        end
        bindKey(player, "F4", "down", pressedF4)
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
    bindKey(source, "F4", "down", pressedF4)
end)

addEventHandler("onPlayerLogout", root, 
function ()
    local team = getPlayerTeam(source)
    -- This team might not be created by this script, so I should check
    -- Should also update panel for online members
    if team then
        if countPlayersInTeam(team) <= 1 then
            destroyElement(team)
        else
            setPlayerTeam(source, nil)
        end
        triggerClientEvent(source, "teams:closeTeamPanel", resourceRoot)
    end
    unbindKey(source, "F4", "down", pressedF4)
end)

addEventHandler("onPlayerQuit", root, 
function ()
    local team = getPlayerTeam(source)
    -- This team might not be created by this script, so I should check
    -- Should also update panel for online members
    if team then
        if countPlayersInTeam(team) <= 1 then
            destroyElement(team)
        end
    end
end)
