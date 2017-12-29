
##' Summarise results from (potentially parallel) reverse-dependency check
##'
##' @title Summarisse results from a reverse-dependency check
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @return NULL, invisibly
##' @author Dirk Eddelbuettel
summariseQueue <- function(package, directory) {
    db <- getQueueFile(package=package, path=directory)
    con <- getDatabaseConnection(db)        # we re-use the liteq db for our results

    res <- dbGetQuery(con, "select result from results")

    cat("Test of", package, "had",
        sum(res==0), "successes,",
        sum(res==1), "failures, and",
        sum(res==2), "skipped packages.",
        "\n")
    times <- dbGetQuery(con, "select min(starttime), max(endtime) from results")
    st <- as.POSIXct(times[1,1])
    et <- as.POSIXct(times[1,2])
    dtf <- format(round(difftime(et,st), digits=3))
    dts <- as.numeric(difftime(et,st,units="secs"))
    cat("Ran from", times[1,1], "to", times[1,2], "for", dtf, "and",
        round(dts/nrow(res), digits=3), "average\n")
    NULL
}
