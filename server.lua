local TeamDatabase = false
local ranks = {["owner"] = 1, ["member"] = 2}
local invites = {} -- Player invites

--- Updates online team members panel
-- @param clanName Name of the clan
local function updateTeamPanel(clanName)
    local onlineMembers, onlinePlayers  = TeamDatabase:getOnlineClanMembers(clanName)
    if onlineMembers then
        local allMembers = TeamDatabase:getClanMembers(clanName)
        for _, player in ipairs(onlinePlayers) do
            triggerClientEvent(player, "teams:updatePanel", resourceRoot, allMembers, onlineMembers)
        end
    end
end

--- Get list of players without team that are eligible to become members
local function getPlayersWithoutTeam()
    local players = {}
    
    for i, player in ipairs(getElementsByType("player")) do
        if not (isGuestAccount(getPlayerAccount(player)) or TeamDatabase:getPlayerClanName(player)) then
            table.insert(players, player)
        end
    end
    return players
end

--- Updates player list
local function updatePlayerList()
    local players = getElementsByType("player")
    local playersWithoutTeam = getPlayersWithoutTeam()
    for _, player in ipairs(players) do
        triggerClientEvent(player, "teams:updatePlayerList", resourceRoot, playersWithoutTeam)
    end
end

--- Player creates team and becomes its owner
-- @param name Name of team to creat
-- @param colour Hexademical colour of team to create
-- @usage teams:onCreate handler
local function onCreate(name, colour)
    if getElementType(client) == "player" then 
        local ownerAcc = getPlayerAccount(client)
        if not isGuestAccount(ownerAcc) then
            local owner = getAccountName(ownerAcc)
            local clanName = TeamDatabase:getPlayerClanName(client)
            local id = TeamDatabase:getIDFromClanName(name)

            if not clanName and not id then
                if TeamDatabase:createClan(owner, name, colour) then
                    outputChatBox("#00FF00[Teams] #FFFFFFYou have successfully created a team, please refer to F10 for useful information", client, 255, 255, 255, true)
                    setPlayerTeam(client, createTeam(name, HexToRGB(colour)))
                    updatePlayerList()
                    triggerClientEvent(client, "teams:toggleCreator", resourceRoot)
                    outputServerLog("[Teams] "..getAccountName(ownerAcc).." created new team '"..name.."'")
                end
            elseif id then
                outputChatBox("#00FF00[Teams] #FF0000Team already exists, please use an original team name", client, 255, 255, 255, true)
            else
                outputChatBox("#00FF00[Teams] #FF0000You are already a team member", client, 255, 255, 255, true)
            end
        end
    end
end
addEvent("teams:onCreate", true)
addEventHandler("teams:onCreate", resourceRoot, onCreate)

--- Owner kicks selected player
-- @params accName name of account to kick
-- @usage teams:onKick handler
-- @note must be owner of team
local function onKick(accName)
    local sourceRank = TeamDatabase:getPlayerRank(client)
    if sourceRank == ranks["owner"] then
        local clanName = TeamDatabase:getAccountClanName(accName)
        if clanName then
            TeamDatabase:removeClanMember(accName)
            outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." kicked "..accName.." from "..clanName)
            local team = getTeamFromName(clanName)
            -- edgecase: account name isn't registered so getAccount returns false but account name is in database
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
            updatePlayerList()
        end
    end
end
addEvent("teams:onKick", true)
addEventHandler("teams:onKick", resourceRoot, onKick)

--- Owner deletes team
-- @usage teams:onDisband handler
local function onDisband()
    local clanName = TeamDatabase:getPlayerClanName(client)
    local sourceRank = TeamDatabase:getPlayerRank(client)
    if sourceRank == ranks["owner"] then
        TeamDatabase:removeClan(clanName)
        destroyElement(getTeamFromName(clanName))
        triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
        updatePlayerList()
        outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." deleted "..clanName)
    end
end
addEvent("teams:onDisband", true)
addEventHandler("teams:onDisband", resourceRoot, onDisband)

--- Member leaves team
-- @usage teams:onLeave handler
local function onLeave()
    local clanName = TeamDatabase:getPlayerClanName(client)
    local sourceRank = TeamDatabase:getPlayerRank(client)
    if sourceRank == ranks["member"] then
        TeamDatabase:removeClanMember(getAccountName(getPlayerAccount(client)))
        outputServerLog("[Teams] "..getAccountName(getPlayerAccount(client)).." left "..clanName)
        local team = getTeamFromName(clanName)
        if countPlayersInTeam(team) <= 1 then
            destroyElement(team)
        else
            setPlayerTeam(client, nil)
        end
        triggerClientEvent(client, "teams:closeTeamPanel", resourceRoot)
        
        -- Update panel for online members
        updateTeamPanel(clanName)
        updatePlayerList()
    end
end
addEvent("teams:onLeave", true)
addEventHandler("teams:onLeave", resourceRoot, onLeave)

--- Member opens panel
-- @param thePlayer who opened the panel
-- @usage command handler
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
            triggerClientEvent(thePlayer, "teams:toggleTeamPanel", resourceRoot, {name=name, colour=colour, members=members, onlineMembers=onlineMembers, owner=rank==ranks["owner"], thisAccName=getAccountName(acc)})
        end
    end
end
addCommandHandler("team", openTeamPanel)

--- Player pressed F4
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

--- teaminvite command handler
local function invite(thePlayer, cmd, playerName)
    local clanName = TeamDatabase:getPlayerClanName(thePlayer)
    local player = #playerName > 0 and getPlayerFromPartialName(playerName)
    if clanName then
        if TeamDatabase:getPlayerRank(thePlayer) == ranks["owner"] then 
            if player then
                if player ~= thePlayer then
                    if not isGuestAccount(getPlayerAccount(player)) then
                        local isNotTeamMember = not TeamDatabase:getPlayerClanName(player)
                        if isNotTeamMember then
                            if not invites[player] then
                                invites[player] = {thePlayer, clanName}
                                outputChatBox("#00FF00[Teams] #FFFFFFYou have sent the invite to player '"..getPlayerName(player):gsub("#%x%x%x%x%x%x", ""), thePlayer, 255, 255, 255, true)
                                outputChatBox("#00FF00[Teams] #FFFFFF"..getPlayerName(thePlayer):gsub("#%x%x%x%x%x%x", "").." has invited you to join '"..clanName.."'", player, 255, 255, 255, true)
                                outputChatBox("#00FF00[Teams] #FFFFFFYou have 10 seconds to type /teamaccept to accept", player, 255, 255, 255, true)
                                setTimer(function(player) invites[player] = nil end, 10000, 1, player)
                            else
                                outputChatBox("#00FF00[Teams] #FF0000This player has already been invited, try again later!", thePlayer, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#00FF00[Teams] #FF0000You cannot invite players who already in a team!", thePlayer, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#00FF00[Teams] #FF0000Player must not be guest", thePlayer, 255, 255, 255, true)
                    end
                else
                    outputChatBox("#00FF00[Teams] #FF0000You cannot invite yourself!", thePlayer, 255, 255, 255, true)
                end
            else
                outputChatBox("#00FF00[Teams] #FF0000Player not found", thePlayer, 255, 255, 255, true)
            end
        else
            outputChatBox("#00FF00[Teams] #FF0000You do not have permission to invite players to this team.", thePlayer, 255, 255, 255, true)
        end
    else
        outputChatBox("#00FF00[Teams] #FF0000You must be in a team to use this command!", thePlayer, 255, 255, 255, true)
    end
end
addCommandHandler("teaminvite", invite)

--- teamaccept command handler
-- @note Needs to be verbose
local function acceptInvite(thePlayer)
    local account = getPlayerAccount(thePlayer)
    if invites[thePlayer] then
        local owner, clanName = unpack(invites[thePlayer])
        if not isGuestAccount(account) and clanName and owner then
            if TeamDatabase:addClanMember(getAccountName(account), clanName, ranks["member"]) then
                outputChatBox("#00FF00[Teams] #FFFFFFPlayer accepted invite!", owner, 255, 255, 255, true)
                outputChatBox("#00FF00[Teams] #FFFFFFWelcome to '"..clanName.."'!", thePlayer, 255, 255, 255, true)
                setPlayerTeam(thePlayer, getTeamFromName(clanName))
                updatePlayerList()
                updateTeamPanel(clanName)
            end
        end
    end
end
addCommandHandler("teamaccept", acceptInvite)

--- invite button has been pressed
local function onPlayerInviteButtonPressed()
    triggerClientEvent(client, "teams:openPlayerList", resourceRoot, getPlayersWithoutTeam())
end
addEvent("teams:onInviteButtonPressed", true)
addEventHandler("teams:onInviteButtonPressed", resourceRoot, onPlayerInviteButtonPressed)

--- player has been invited to team
local function onPlayerInvited(playerName)
    invite(client, _, playerName)
end
addEvent("team:onPlayerInvited", true)
addEventHandler("team:onPlayerInvited", resourceRoot, onPlayerInvited)

--- Add player into their team and update the team panel
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
        updateTeamPanel(name)
        -- hacky fix to ensure that empty teams get removed and
        -- team panel gets updated whenever player logouts
        setElementData(source, "team", name)
    end
    bindKey(source, "F4", "down", pressedF4)
end)

--- Remove player from their team and update the team panel
addEventHandler("onPlayerLogout", root, 
function ()
    local name = getElementData(source, "team")

    if name then
        local team = getTeamFromName(name)
        if team then
            if countPlayersInTeam(team) <= 0 then
                destroyElement(team)
            else
                updateTeamPanel(name)
            end
            triggerClientEvent(source, "teams:closeTeamPanel", resourceRoot)
        end
        setElementData(source, "team", false)
    end

    unbindKey(source, "F4", "down", pressedF4)
end)

--- Remove the team from scoreboard if they're the last member before they quit.
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

--- start here on resource start
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
            -- hacky fix to ensure that empty teams get removed and
            -- team panel gets updated whenever player logouts
            setElementData(player, "team", name)
        end
        bindKey(player, "F4", "down", pressedF4)
    end
end)
