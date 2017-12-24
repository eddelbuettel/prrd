
getConnection <- function(file) {
    con <- dbConnect(RSQLite::SQLite(), file)
    dbExecute(con, "PRAGMA busy_timeout = 1000")
    con
}

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
