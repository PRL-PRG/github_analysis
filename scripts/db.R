library(RMySQL)

# println + concatenation wrapper
println <- function(...) {
    cat(paste(..., "\n", sep = ""))
}

# SQL functions -------------------------------------------------------------------------------------------------------

DB_CONNECTION_ = NULL
LAST_SQL_TIME_ = NULL

# connects to the given db server and opens the database name, if the database name does not exist, creates it. Keeps the connection alive 
sql.connect <- function(username, password, dbname, host = "localhost") {
    # disconnect first, if we have existing connection
    sql.disconnect()
    tryCatch({
        # now connect to the database
        DB_CONNECTION_ <<- dbConnect(MySQL(), user = username, password = password, host = host, dbname = dbname)
    }, error = function(e) {
        # if the error is the databse does not exist, create it
        if (length(grep("Failed to connect to database: Error: Unknown database", e$message)) > 0) {
            DB_CONNECTION_ <<- dbConnect(MySQL(), user = username, password = password, host = host)
            sql.query("CREATE DATABASE ", dbname)
            println("Creating database ", dbname)
            sql.disconnect()
            sql.connect(username, password, dbname, host)
        } else {
            stop(e)
        }
    })
}

# disconnects from the database
sql.disconnect <- function() {
    if (! is.null(DB_CONNECTION_)) {
        dbDisconnect(DB_CONNECTION_)
        DB_CONNECTION_ <<- NULL
    }
}

# concatenates the arguments into one string and executes it as query, if updateTime is T, stores the time the query took on server
sql.query <- function(..., updateTime = T) {
    result <- 0
    f <- function() {
        res <- dbSendQuery(DB_CONNECTION_, paste(..., sep = ""))         
        result <<- dbFetch(res, n = -1)
        dbClearResult(res)
    }
    if (updateTime) {
        LAST_SQL_TIME_ <<- system.time({
            f()
        })
    } else {
        f()
    }
    result
}

# returns the time in seconds it took the last query to execute on the server
sql.lastTime <- function() {
    if (is.null(LAST_SQL_TIME_))
        0
    else
        LAST_SQL_TIME_[["elapsed"]]
}


# returns the number of rows affected by the last query

sql.affectedRows <- function() {
    sql.query("SELECT ROW_COUNT()", updateTime = F)
}

# returns the table status (the table name, length in rows and number of bytes it occupies). When precise is T, it uses the COUNT(*) which takes a lot of time, when F, uses the SHOW TABLE STATUS which is fast, but only approximate
sql.tableStatus <- function(table, precise = T) {
    x <- sql.query("SHOW TABLE STATUS WHERE NAME='",table,"'")
    if (precise)
        cnt <- sql.query("SELECT COUNT(*) FROM ", table)
    else
        cnt <- x$Rows
    list(name = x$Name, length = cnt, bytes = x$Data_length)
}

# creates (recreates) index on given table and column
sql.createIndex <- function(table, column, unique = T) {
    index = gsub(",", "", column)
    index = gsub(" ", "", index)
    index = paste("index_", index, sep="")
    x <- sql.query("SHOW INDEX FROM ", table, " WHERE KEY_NAME=\"", index, "\"")$Key_name
    if (length(x) > 0)
        sql.query("DROP INDEX ", index, " ON ", table)
    if (unique)
        sql.query("CREATE UNIQUE INDEX ", index, " ON ", table, "(", column, ")")
    else
        sql.query("CREATE INDEX ", index, " ON ", table, "(", column, ")")
    paste("created index ", column, " on table ", table, " in ", sql.lastTime(), "[s]", sep = "")
}

sql.dropTable <- function(name) {
  sql.query("DROP TABLE IF EXISTS ", name)
  name
}

sql.createTable <- function(name, contents) {
  sql.query("CREATE TABLE ", name, " (", contents, ")")
  name
}


sql.loadTable <- function(name, file) {
  sql.query("LOAD DATA LOCAL INFILE \"", file,"\" INTO TABLE ", name, " FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'")
  file
}

# switches the database, creating a new one if the given database does not exist
sql.switchDb <- function(dbName) {
    tryCatch({
        sql.query("USE ", dbName)
    }, error = function(e) {
        # if the error is the databse does not exist, create it
        if (length(grep("Error: Unknown database", e$message)) > 0) {
            sql.query("CREATE DATABASE ", dbname)
            sql.query("USE ", dbName)
        } else {
            stop(e)
        }
    })
}


