##' Several Database Connection Helper Functions
##'
##' These functions return a connection, create a table and insert
##' a row of data, respectively.
##' @title Database Helper Functions
##' @param file A character variable pointing to a sqlite3 file
##' @param con A database connection object
##' @param df A one-row data.frame with results to be appended
##' @return A connection object
##' @author Dirk Eddelbuettel
getDatabaseConnection <- function(file) {
    con <- dbConnect(SQLite(), file, synchronous=NULL)
    # Change the journal mode to Write-Ahead Logging (WAL) for better performance
    dbExecute(con, "PRAGMA journal_mode = WAL")
    # Set a busy timeout (in milliseconds) to prevent concurrent locking errors
    dbExecute(con, "PRAGMA busy_timeout = 2000")
    con
}

.createTableSQL <- 'CREATE TABLE IF NOT EXISTS results (
       package   TEXT,
       version   TEXT,
       result    INTEGER,
       starttime TIMESTAMP,
       endtime   TIMESTAMP,
       runtime   NUMERIC,
       runner    INTEGER,
       host      TEXT);'

##' @rdname getDatabaseConnection
createTable <- function(con) {
    dbExecute(con, "BEGIN EXCLUSIVE")
    sql <- .createTableSQL
    dbExecute(con, sql)
    dbExecute(con, "COMMIT")
}


##' @rdname getDatabaseConnection
insertRow <- function(con, df) {
    dbExecute(con, "BEGIN EXCLUSIVE")
    ##sql <- "INSERT INTO results (package, version, result, starttime, endtime,
    ##                              runtime, runner, host)
    ##         VALUES (?package, ?version, ?result, ?starttime, ?endtime,
    ##                 ?runtime, ?runner, ?host)"
    ## cmd <- sqlInterpolate(con, sql,
    ##                       package   = df$package,
    ##                       version   = df$version,
    ##                       result    = df$result,
    ##                       starttime = df$starttime,
    ##                       endtime   = df$endtime,
    ##                       runtime   = df$runtime,
    ##                       runner    = df$runner,
    ##                       host      = df$host)
    ## print(cmd)
    dbWriteTable(con, "results", df, append=TRUE, overwrite=FALSE)
    dbExecute(con, "COMMIT")
    NULL
}

.createRunDataSQL <- 'CREATE TABLE IF NOT EXISTS metadata (
       package   TEXT,
       version   TEXT,
       date      DATE);'

##' @rdname getDatabaseConnection
createRunDataTable <- function(con) {
    dbExecute(con, "BEGIN EXCLUSIVE")
    dbExecute(con, .createRunDataSQL)
    dbExecute(con, "COMMIT")
}


## Borrowed with grateful acknowledgements from liteq 1.2.0
## (which is MIT licensed, and R includes a copy of the MIT license)

#' Start a write transaction
#'
#' We use `BEGIN IMMEDIATE` for every write. A deferred transaction
#' (plain `BEGIN`) that reads first and writes later might fail with
#' "database is locked" right away, without waiting for the busy
#' timeout, because SQLite cannot wait there without risking a deadlock.
#' Unlike `BEGIN EXCLUSIVE`, `BEGIN IMMEDIATE` does not block readers.
#'
#' If `retry` is `TRUE`, then we keep trying until we get the lock.
#' Each try waits for the busy timeout, so this does not spin.
#'
#' @param con DB connection.
#' @param retry Whether to retry if the database is locked.
#'
#' @keywords internal

dbLock <- function(con, retry = TRUE) {
    while (TRUE) {
        ok <- tryCatch( {
            dbExecute(con, "BEGIN IMMEDIATE")
            TRUE
        },
        error = function(e) {
            if (!retry || !grepl("locked", conditionMessage(e))) stop(e)
            FALSE
        })
        if (ok) break
    }
}

##' @rdname getDatabaseConnection
##' @param code Exression to be executed
##' @param retry Boolean value, defaults to \sQuote{TRUE}
dbWithWriteTransaction <- function(con, code, retry = TRUE) {
    dbLock(con, retry = retry)
    tryCatch({
        res <- force(code)
        dbExecute(con, "COMMIT")
        res
    },
    error = function(e) {
        .trySilent(dbExecute(con, "ROLLBACK"))
        stop(e)
    })
}

##' @rdname getDatabaseConnection
##' @param ... Additional parameters, currently unused
dbExecuteLocked <- function(file, code, ...) {
    con <- getDatabaseConnection(file)
    on.exit(dbDisconnect(con))
    dbWithWriteTransaction(con, dbExecute(con, code, ...))
}



## New helpers

.trySilent <- function(x) {
    try(x, silent = TRUE)
}

##' @rdname getDatabaseConnection
dbGetQueryWrapped <- function(file, code) {
    con <- getDatabaseConnection(file)
    on.exit(dbDisconnect(con))
    dbExecute(con, sprintf("PRAGMA busy_timeout = %d", 2000))
    dbGetQuery(con, code)
}

##' @rdname getDatabaseConnection
createTableLocked <- function(file) {
    dbExecuteLocked(file, .createTableSQL)
}

##' @rdname getDatabaseConnection
insertRowLocked <- function(file, df) {
    con <- getDatabaseConnection(file)
    on.exit(dbDisconnect(con))
    dbWithWriteTransaction(con,
                           dbWriteTable(con, "results", df, append=TRUE, overwrite=FALSE),
                           retry = TRUE)
    NULL
}

##' @rdname getDatabaseConnection
createRunDataTableLocked <- function(file) {
    dbExecuteLocked(file, .createRunDataSQL)
}
