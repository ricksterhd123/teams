local TeamDatabase = teamDatabase("sqlite", "team.db")
local ranks = {["owner"] = 1, ["member"] = 2}

-- Player creates team; becomes owner
addEvent("teams:onCreate", true)
addEventHandler("teams:onCreate", root,
function (name, colour)
    if client == source and getElementType(source) == "player" then 
        local ownerAcc = getPlayerAccount(source)
        if not isGuestAccount(ownerAcc) then
            local owner = getAccountName(ownerAcc)
            local clanName = TeamDatabase:getPlayerClanName(source)
            if not clanName then
                local result = TeamDatabase:createClan(owner, name, colour)
                if result then
                    outputChatBox("#00FF00[Teams] #FFFFFFYou have successfully created a team, please refer to F9 for useful information", source, 255, 255, 255, true)
                else
                    -- TODO LOG
                end
            elseif clanName == name then
                outputChatBox("#00FF00[Teams] #FF0000Team already exists, please use an original team name", source, 255, 255, 255, true)
                -- TODO LOG
            else
                outputChatBox("#00FF00[Teams] #FF0000You are already a team member", source, 255, 255, 255, true)
                -- TODO LOG
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
                -- TODO: update panel for online members
            end
        end
    end
end)

-- Owner deletes team
addEvent("teams:onDisband", true)
addEventHandler("teams:onDisband", root, 
function ()
    if client == source then
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["owner"] then
            local clanName = TeamDatabase:getPlayerClanName(source)
            TeamDatabase:removeClan(clanName)
            -- TODO: destroy panel
        end
    end
end)

-- Member leaves team
addEvent("teams:onLeave", true)
addEventHandler("teams:onLeave", root, 
function ()
    if client == source then
        local sourceRank = TeamDatabase:getPlayerRank(source)
        if sourceRank == ranks["member"] then
            TeamDatabase:removeClanMember(getAccountName(getPlayerAccount(source)))
            -- TODO: destroy panel
        end
    end
end)

-- Member opens panel
addCommandHandler("team", 
function (thePlayer)
    local acc = getPlayerAccount(thePlayer)
    if not isGuestAccount(acc) then
        local name = TeamDatabase:getPlayerClanName(thePlayer)
        if name then
            -- local clanID = TeamDatabase:getIDFromClanName(name)
            local members = TeamDatabase:getClanMembers(name)
            local colour = TeamDatabase:getColourFromClanName(name)
            local rank = TeamDatabase:getPlayerRank(thePlayer)
        
            return triggerClientEvent(thePlayer, "teams:openPanel", resourceRoot, {name=name, colour=colour, members=members, owner=rank==ranks["owner"], thisAccName=getAccountName(acc)})
        end
    end
    return false
end)
