--[[
    Provides a simple API to the SQLite database containing teams and members
    
    Entity Relationship Diagram:

    +------+              +--------+
    | TEAM |-|---------|<-| MEMBER |        [1 to many]
    +------+              +--------+

    Currently there exists only 2 ranks: owner and member.
    Soon the owner will be able to add any number of arbitrary ranks and set permissions for each.
    For now custom ranks and permissions are beyond the scope of 0.1.0.
]]

local team_table = "CREATE TABLE IF NOT EXISTS `teams` (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(32), colour VARCHAR(8), UNIQUE(name))"
local players_table = "CREATE TABLE IF NOT EXISTS `members` (account VARCHAR(32) PRIMARY KEY,  team_id INTEGER, rank_id INTEGER, FOREIGN KEY (team_id) REFERENCES teams(id))"
local ranks = {["owner"] = 1, ["member"] = 2}   -- index -> id

-- beyond the scope of this project... for now
-- local ranks_table = "CREATE TABLE IF NOT EXISTS `team_ranks` (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(32))"

local TeamDatabase = {}
TeamDatabase.__index = TeamDatabase

setmetatable(TeamDatabase, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function TeamDatabase.new(dbType, host, ...)
    local self = setmetatable({}, TeamDatabase)
    self.connection = Connection(dbType, host, ...)
    assert(self.connection:exec(team_table), "Could not create team table")
    assert(self.connection:exec(players_table), "Could not create player table")
    return self
end

-- Team players
function TeamDatabase:addClanMember(account, clanName, rank)
    local id = self:getIDFromClanName(clanName)
    return id and self.connection:exec("INSERT INTO `members` VALUES(?, ?, ?)", account, id, rank)
end

function TeamDatabase:getClanMembersFromID(id)
    local qh = self.connection:query("SELECT * FROM `members` WHERE team_id = ?", id)
    if qh then
        local result = qh:poll(-1)
        return result and #result > 0 and result
    end
end

function TeamDatabase:getClanMembers(clanName)
    local id = self:getIDFromClanName(clanName)
    return id and self:getClanMembersFromID(id)
end

-- TODO: Tidy
function TeamDatabase:getOnlineClanMembers(clanName)
    local members = self:getClanMembers(clanName)
    if members then
        local accountNames = {}
        local players = {}

        for _, member in ipairs(members) do
            local account = getAccount(member.account)
            local player = getAccountPlayer(account)
            if account and player then  -- redundant?
                table.insert(accountNames, member)
                table.insert(players, player)
            end
        end
        return accountNames, players
    end
    return false
end

function TeamDatabase:removeClanMember(accountName)
    return self.connection:exec("DELETE FROM `members` WHERE account = ?", accountName)
end

function TeamDatabase:getPlayerRank(player)
    local account = getPlayerAccount(player)
    if not isGuestAccount(account) then
        local accountName = getAccountName(account)
        local qh = self.connection:query("SELECT rank_id FROM `members` WHERE account = ?", accountName)
        if qh then
            local result = qh:poll(-1)
            return result and #result > 0 and result[1].rank_id
        end
    end
    return false
end

function TeamDatabase:getAccountClanName(accountName)
    local qh = self.connection:query("SELECT team_id from `members` WHERE account = ?", accountName)
    if qh then
        local result = qh:poll(-1)
        return result and #result > 0 and self:getClanNameFromID(result[1].team_id)
    end
end

function TeamDatabase:getPlayerClanName(player)
    local account = getPlayerAccount(player)
    if not isGuestAccount(account) then
        local accountName = getAccountName(account)
        return self:getAccountClanName(accountName)
    end
    return false
end

-- Teams
function TeamDatabase:createClan(owner, name, colour)
    local success = self.connection:exec("INSERT INTO `teams` VALUES (NULL, ?, ?)", name, colour)
    assert(success, "Could not insert team into `teams`")
    return success and self:addClanMember(owner, name, ranks["owner"])
end

function TeamDatabase:getIDFromClanName(name)
    local qh = self.connection:query("SELECT id FROM `teams` WHERE name = ?", name)
    if qh then
        local result = qh:poll(-1)
        return result and #result > 0 and result[1].id
    end
    return false
end

function TeamDatabase:getColourFromClanName(name)
    local qh = self.connection:query("SELECT colour FROM `teams` WHERE name = ?", name)
    if qh then
        local result = qh:poll(-1)
        return result and #result > 0 and result[1].colour
    end
    return false
end

function TeamDatabase:getClanNameFromID(id)
    local qh = self.connection:query("SELECT name FROM `teams` WHERE id = ?", id)
    if qh then
        local result = qh:poll(-1)
        return result and #result > 0 and result[1].name
    end
    return false
end

function TeamDatabase:removeClan(teamName)
    local teamID = self:getIDFromClanName(teamName)
    return self.connection:exec("DELETE FROM `teams` WHERE name = ?", teamName) and self.connection:exec("DELETE FROM `members` WHERE team_id = ?", teamID)
end

teamDatabase = TeamDatabase