# Python script for batch reformatting of FRP team sqlite database
# Removes from source db: duplicates/ NULL members/cases where owner is not a member
import sqlite3

RANKS = {"OWNER": 1, "MEMBER": 2}

# Create tables for sink db
def createTables(snkConn):
    c = snkConn.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS `teams` (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(32), colour VARCHAR(8), UNIQUE(name)) ")
    c.execute("CREATE TABLE IF NOT EXISTS `members` (account VARCHAR(32) PRIMARY KEY,  team_id INTEGER, rank_id INTEGER, FOREIGN KEY (team_id) REFERENCES teams(id))")

# Converts 
# |~|MaikinRD|~|oscardiaz|~|Andrea|~|Atr-gabo|~|alfercrack2019|~|Jose.2424|~|guada|~|Laura_Xx
# into ['MaikinRD', 'oscardiaz', 'Andrea', 'Atr-gabo', 'alfercrack2019', 'Jose.2424', 'guada', 'Laura_Xx']
def membersTXTToList(txt):
    if txt is not None:
        #print(type(txt))
        return txt.decode().split('|~|')[1:]
    else:
        return []

# Get data from source db
def sourceData(srcConn):
    teams = []
    c = srcConn.cursor()
    c.execute("SELECT * FROM teams")
    for row in c:
        name, owner, colour, members = row[0], row[1], row[2], membersTXTToList(row[3])
        try:
            if owner:
                members.insert(0, members.pop(members.index(owner.decode())))
                teams.append((name.decode(), colour.decode(), members))
        except ValueError:
                continue

    return teams

# Insert row into sink
def insertTeam(snkConn, name, colour, members):
    c = snkConn.cursor()
    c.execute("INSERT INTO `teams` VALUES (NULL, ?, ?)", (name, colour))
    teamID = c.lastrowid
    for i in range(len(members)):
        c.execute("INSERT INTO `members` VALUES (?, ?, ?)", (members[i], teamID, 
            RANKS['OWNER'] if i == 0 else RANKS['MEMBER']))

# Insert each row from source to sink
# try-except prevents duplicates
def sourceToSink(srcConn, snkConn):
    for team in sourceData(srcConn):
        try:
            insertTeam(snkConn, team[0], team[1], team[2])
        except (sqlite3.IntegrityError, sqlite3.OperationalError):
            continue

if __name__ == "__main__":
    srcConn = sqlite3.connect('teams.db')
    srcConn.text_factory = bytes
    snkConn = sqlite3.connect('../teams.db')
    #snkConn.text_factory = str
    print("Creating tables")
    createTables(snkConn)
    print("Transferring data")
    sourceToSink(srcConn, snkConn)
    print("Finished")
    snkConn.commit()
    srcConn.close()
    snkConn.close()
