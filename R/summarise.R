
##' Summarise results from (potentially parallel) reverse-dependency check
##'
##' @title Summarisse results from a reverse-dependency check
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @param dbfile A character variable for an optional override which, if
##' present, is used over \sQuote{package} and \sQuote{directory}.
##' @return NULL, invisibly
##' @author Dirk Eddelbuettel
summariseQueue <- function(package, directory, dbfile="") {
    if (dbfile != "") {
        if (file.exists(dbfile)) {
            db <- dbfile
        } else {
            stop("No file ", dbfile, " found\n", call.=FALSE)
        }
    } else {
        db <- getQueueFile(package=package, path=directory)
    }
    con <- getDatabaseConnection(db)        # we re-use the liteq db for our results
    res <- setDT(dbGetQuery(con, "select * from results"))
    dbDisconnect(con)

    cat("Test of", package, "had",
        sum(res[result==0,.N]), "successes,",
        sum(res[result==1,.N]), "failures, and",
        sum(res[result==2,.N]), "skipped packages.",
        "\n")
    st <- res[, min(starttime)]
    et <- res[, max(endtime)]
    dtf <- format(round(difftime(et,st), digits=3))
    dts <- as.numeric(difftime(et,st,units="secs"))
    cat("Ran from", times[1,1], "to", times[1,2], "for", dtf, "\n")
    cat("Average of", round(dts/nrow(res), digits=3), "secs relative to",
        format(round(res[, mean(runtime)], digits=3)), "using",
        nrow(res[, .N, by=runner]), "runners\n")
    return(res)
}


## make R CMD check happy
globalVariables(c(".N", "result", "starttime", "endtime", "times", "runtime", "runner"))
