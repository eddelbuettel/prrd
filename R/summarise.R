
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
    jobs <- setDT(dbGetQuery(con, "select * from qqjobs"))
    dbDisconnect(con)

    cat("Test of", package, "had",
        res[result==0,.N], "successes,",
        res[result==1,.N], "failures, and",
        res[result==2,.N], "skipped packages.",
        "\n")
    st <- res[, min(starttime)]
    et <- res[, max(endtime)]
    dtf <- format(round(difftime(et,st), digits=3))
    dts <- as.numeric(difftime(et,st,units="secs"))
    cat("Ran from", st, "to", et, "for", dtf, "\n")
    cat("Average of", round(dts/nrow(res), digits=3), "secs relative to",
        format(round(res[, mean(runtime)], digits=3)), "secs using",
        nrow(res[, .N, by=runner]), "runners\n")
    cat("\nFailed packages: ", paste(res[result==1, .(package)][[1]], collapse=", "), "\n")
    cat("\nSkipped packages: ", paste(res[result==2, .(package)][[1]], collapse=", "), "\n")
    cat("\n")
    if (jobs[status=="WORKING",.N] > 0) {
        print(jobs[status=="WORKING",])
    } else {
        cat("None still working\n")
    }
    cat("\n")
    if (jobs[status=="READY",.N] > 0) {
        print(jobs[status=="READY",])
    } else {
        cat("None still scheduled\n")
    }
    invisible(res)
}


## make R CMD check happy
globalVariables(c(".", ".N", "result", "starttime", "endtime",
                  "times", "runtime", "runner", "status"))
