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
    con <- dbConnect(RSQLite::SQLite(), file)
    dbExecute(con, "PRAGMA busy_timeout = 1000")
    con
}

##' @rdname getDatabaseConnection
createTable <- function(con) {
    dbExecute(con, "BEGIN EXCLUSIVE")
    sql <- 'CREATE TABLE IF NOT EXISTS results (
       package   TEXT,
       version   TEXT,
       result    INTEGER,
       starttime TIMESTAMP,
       endtime   TIMESTAMP,
       runtime   NUMERIC,
       runner    INTEGER,
       host      TEXT);'
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
