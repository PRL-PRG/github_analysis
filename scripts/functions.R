if (! is.null(DB_USER))
    DB_USER = "js"
if (! is.null(DB_PASSWORD))
    DB_PASSWORD = "js"
if (! is.null(DB_HOST))
    DB_HOST = "localhost"

# -------------------------------------------------------------------------------------------------
# high-level functions
# -------------------------------------------------------------------------------------------------

importDataset <- function(dbName, inputFolder, dbUser = DB_USER, dbPassword = DB_PASSWORD, host = DB_HOST) {
    sql.connect(username = dbUser, password = dbPassword, dbName = dbName, host = DB_HOST)
    importCommonData(inputFolder)
    createCommonIndices()
    calculateProjectSizes()
    sql.disconnect()
}

importJSExtras <- function(dbName, inputFolder, dbUser = DB_USER, dbPassword = DB_PASSWORD, host = DB_HOST) {
    sql.connect(username = dbUser, password = dbPassword, dbName = dbName, host = DB_HOST)
    importJSData(inputFolder)
    sql.disconnect()
}

importAndCreateJS_NPM <- function(dbName, dbOrigin, inputFolder, dbUser = DB_USER, dbPassword = DB_PASSWORD, host = DB_HOST) {
    sql.connect(username = dbUser, password = dbPassword, dbName = dbOrigin, host = DB_HOST)
    importNPMInfo(inputFolder)
    sql.switchDb(dbName)
    createNonNPMDataset(dbOrigin)
    sql.disconnect()
}

exportCloneFinderData <- function(dbName, outputFolder, threshold = 0, dbUser = DB_USER, dbPassword = DB_PASSWORD, host = DB_HOST) {
    sql.connect(username = dbUser, password = dbPassword, dbName = dbOrigin, host = DB_HOST)
    println("exporting clone finder input data")
    println("  creating clone finder's input...")
    sql.query("SELECT projectId, totalTokens, tokenHash FROM files JOIN stats ON files.fileHash = stats.fileHash WHERE totalTokens > ",threshold," INTO OUTFILE \"", outputFolder, "/clone_finder.csv\" FIELDS TERMINATED BY ','");
    sql.disconnect()
}

importCloneFinderData <- function(dbName, inputFolder, numThreads, dbUser = DB_USER, dbPassword = DB_PASSWORD, host = DB_HOST) {
    sql.connect(username = dbUser, password = dbPassword, dbName = dbOrigin, host = DB_HOST)
    println("  creating cf table projectClones")
    println("    dropping if exists", sql.dropTable("projectClones"))
    println("    creating", sql.createTable("projectClones","
        cloneId INT UNSIGNED NOT NULL,
        cloneClonedFiles INT UNSIGNED NOT NULL,
        cloneTotalFiles INT UNSIGNED NOT NULL,
        cloneCloningPercent DECIMAL(6,3) NOT NULL,
        hostId INT UNSIGNED NOT NULL,
        hostAffectedFiles INT UNSIGNED NOT NULL,
        hostTotalFiles INT UNSIGNED NOT NULL,
        hostAffectedPercent DECIMAL(6,3) NOT NULL,
        PRIMARY KEY (cloneId, hostId)"))
    
    println("    loading chunks...")
    for (i in 0:(numThreads - 1)) {
        filename = paste(inputFolder, "/project_clones.", i, ".csv", sep = "")
        println("      ", sql.loadTable("projectClones", filename))
    }
    
    println("    creating indices...")
    println("      ", sql.createIndex("projectClones", "cloneId", unique = F))
    println("      ", sql.createIndex("projectClones", "cloneTotalFiles", unique = F))
    println("      ", sql.createIndex("projectClones", "cloneCloningPercent", unique = F))
    println("      ", sql.createIndex("projectClones", "hostId", unique = F))
    println("      ", sql.createIndex("projectClones", "hostTotalFiles", unique = F))
    println("      ", sql.createIndex("projectClones", "hostAffectedPercent", unique = F))
    sql.disconnect()    
}

# -------------------------------------------------------------------------------------------------
# All Datasets
# -------------------------------------------------------------------------------------------------

# creates projects, files and stats tables in given database and populates them from the selected folder, which must contain the appropriate output files from the downloader (projects.txt, files.txt and stats.txt)
importCommonData <- function(inputFolder) {
    println("  removing existing tables...")
    println("    ", sql.dropTable("projects"))
    println("    ", sql.dropTable("files"))
    println("    ", sql.dropTable("stats"))
    
    println("  creating tables...")
    println("    ", sql.createTable("projects", "
        projectId INT UNSIGNED NOT NULL,
        projectPath VARCHAR(4000) NOT NULL,
        projectUrl VARCHAR(4000) NOT NULL,
        PRIMARY KEY (projectId)"))
    println("    ", sql.createTable("files", "
        fileId BIGINT UNSIGNED NOT NULL,
        projectId INT UNSIGNED NOT NULL,
        relativeUrl VARCHAR(4000) NOT NULL,
        fileHash BIGINT NOT NULL,
        PRIMARY KEY (fileId)"))
    println("    ", sql.createTable("stats","
        fileHash BIGINT NOT NULL,
        fileBytes INT NOT NULL,
        fileLines INT NOT NULL,
        fileLOC INT NOT NULL,
        fileSLOC INT NOT NULL,
        totalTokens INT NOT NULL,
        uniqueTokens INT NOT NULL,
        tokenHash BIGINT NOT NULL,
        PRIMARY KEY (fileHash)"))
    
    println("  loading tables...")
    println("    ", sql.loadTable("projects", paste(inputFolder, "projects.txt", sep = "/")))
    println("    ", sql.loadTable("files", paste(inputFolder, "files.txt.h2i", sep = "/")))
    println("    ", sql.loadTable("stats", paste(inputFolder, "stats.txt.h2i", sep = "/")))
    
}

# creates indices on projects, files and stats tables. Assumes the database containing the tables has already been selected
createCommonIndices <- function() {
    println("  creating indices...")
    println("    ", sql.createIndex("projects", "projectId"))
    println("    ", sql.createIndex("files", "fileId"))
    println("    ", sql.createIndex("files", "projectId", unique = F))
    println("    ", sql.createIndex("stats", "fileHash"))
    println("    ", sql.createIndex("stats", "tokenHash", unique = F))
}

# augments the projects table with files column and counts for each project number of files it contains 
calculateProjectSizes <- function() {
    println("calculating project sizes...")
    sql.query("ALTER TABLE projects ADD COLUMN files INT UNSIGNED NOT NULL DEFAULT 0")
    println("  added column files to projects table")
    sql.query("CREATE TABLE projects_files SELECT COUNT(*) AS files, projectId AS pid FROM files GROUP BY files.projectId")
    println("  file counts calculated")
    sql.query("UPDATE projects JOIN projects_files ON projects.projectId = projects_files.pid SET projects.files = projects_files.files")
    println("  projects table updated")
    sql.query("DROP TABLE projects_files;")
    println("  deleted temporary tables")
}

# -------------------------------------------------------------------------------------------------
# JavaScript
# -------------------------------------------------------------------------------------------------

# Imports Javascript extra data. Alters projects with time of creation and commit at which the project has been tokenized. Alters files with the time of creation, which can be used for originals detection. Loads the data from files_extra and projects_extra files produced by the JS tokenizer. The data is added as extra columns to the files and projects table, which saves space in the database (as opposed to having an extra table) while not breaking any compatibility, the extra columns simply do not have to be used. 
importJSData <- function(inputFolder) {
    println("importing JS specific data...")
    println("  creating tables...")
    println("    ", sql.createTable("projects_extra", "
        projectId INT UNSIGNED NOT NULL,
        createdAt INT UNSIGNED NOT NULL,
        commit CHAR(40) NOT NULL,
        PRIMARY KEY (projectId)"))
    println("    ", sql.createTable("files_extra", "
        fileId BIGINT NOT NULL,
        createdAt INT UNSIGNED NOT NULL,
        PRIMARY KEY (fileId)"))
    
    println("  loading tables...")
    println("    ", sql.loadTable("projects_extra", paste(inputFolder, "projects_extra.txt", sep = "/")))
    println("    ", sql.loadTable("files_extra", paste(inputFolder, "files_extra.txt", sep = "/")))
    
    println("  merging information...")
    sql.query("ALTER TABLE projects ADD COLUMN createdAt INT UNSIGNED NOT NULL")
    println("    createdAt added to projects")
    sql.query("ALTER TABLE projects ADD COLUMN commit CHAR(40) NOT NULL")
    println("    commit added to projects")
    sql.query("UPDATE projects JOIN projects_extra ON projects.projectId = projects_extra.projectId 
SET projects.createdAt = projects_extra.createdAt, projects.commit = projects_extra.commit")
    println("    projects table updated")
    sql.query("ALTER TABLE files ADD COLUMN createdAt INT UNSIGNED NOT NULL")
    println("    createdAt added to files")
    sql.query("UPDATE files JOIN files_extra ON files.fileId = files_extra.fileId SET files.createdAt = files_extra.createdAt")
    println("    files table updated")
    
    println("  deleting temporary tables")
    println("    ", sql.dropTable("projects_extra"))
    println("    ", sql.dropTable("files_extra"))
}


# Augments the files table with the information whether the file belongs to an NPM package or not.
importNPMInfo <- function(inputFolder) {
    println("importing NPM & file origin information")
    println("  creating files_nm table...")
    sql.dropTable("files_nm")
    sql.createTable("files_nm", "
        fileId BIGINT UNSIGNED NOT NULL,
        pathDepth SMALLINT UNSIGNED NOT NULL,
        npmDepth SMALLINT UNSIGNED NOT NULL,
        test TINYINT NOT NULL,
        locale TINYINT NOT NULL,
        moduleName VARCHAR(255) NOT NULL,
        blameModule VARCHAR(255) NOT NULL,
        fileName VARCHAR(1000) NOT NULL,
        fileExt VARCHAR(255) NOT NULL,
        inModuleName VARCHAR(4000) NOT NULL,
        PRIMARY KEY (fileId)")
    println("  loading table...")
    println("    ", sql.loadTable("files_nm", paste(inputFolder, "files_nm.csv", sep = "/")))
    
    # now alter the files table, add package and test categories
    println("  altering files table")
    sql.query("ALTER TABLE files ADD COLUMN npm TINYINT NOT NULL")
    println("    npm column")
    sql.query("ALTER TABLE files ADD COLUMN test TINYINT NOT NULL")
    
    # and merge the information from the files_nm table
    println("  updating the files table...")
    sql.query("UPDATE files JOIN files_nm ON files.fileId = files_nm.fileId SET files.npm = IF(files_nm.npmDepth > 0, 1, 0), files.test = files_nm.test")
    
    # we keep everything in the files_nm table as well, it might be useful in the future?    
}

# Takes the origin database (which should have npm info already present) and creates projects files & stats tables in current database containing only those not in npm modules 
createNonNPMDataset <- function(origin) {
    println("switching to database", database)
    sql.switchDb(database)
    println("copying only NPM data...")
    sql.query("CREATE TABLE projects AS SELECT projectId, projectUrl, createdAt, commit FROM ", origin, ".projects")
    println("  projects")
    sql.query("CREATE TABLE files AS SELECT fileId, projectId, relativeUrl, fileHash, createdAt, test FROM ", origin, ".files")
    println("  files")
    sql.query("CREATE TABLE stats AS SELECT * FROM ", origin, ".stats WHERE fileHash IN (SELECT UNIQUE fileHash FROM files)")
    println("  stats")
    createCommonIndices()
    calculateProjectSizes()
}









