
##' Summarise results from (potentially parallel) reverse-dependency check
##'
##' @title Summarisse results from a reverse-dependency check
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @param dbfile A character variable for an optional override which, if
##' present, is used over \sQuote{package} and \sQuote{directory}.
##' @param extended A boolean variable to select extended analysis of
##' failures, default is \code{FALSE} which skips this.
##' @return NULL, invisibly
##' @author Dirk Eddelbuettel
summariseQueue <- function(package, directory, dbfile="", extended=FALSE) {
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
    cat("\nFailed packages: ", paste(unique(sort(res[result==1, .(package)][[1]])), collapse=", "), "\n")
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

    if (extended) .runExtended(res)

    invisible(res)
}

.checkfile <- function(wd, pkg) file.path(wd, paste0(pkg, ".Rcheck"), "00check.log")

.installfile <- function(wd, pkg) file.path(wd, paste0(pkg, ".Rcheck"), "00install.out")

.grepMissing <- function(wd, pkg) {
    lines <- readLines(.checkfile(wd, pkg))
    ind <- grep("there is no package called", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
    gsub(".*there is no package called ", "", ll)
}

.grepRequired <- function(wd, pkg) {
    lines <- readLines(.checkfile(wd, pkg))
    ind <- grep("Package.* required but not available", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
    gsub(".*but not available: ", "", ll)
}

.grepNeeded <- function(wd, pkg) {
    lines <- readLines(.checkfile(wd, pkg))
    ind <- grep("package.* need.*", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
}

.grepInstallationFailed <- function(wd, pkg) {
    lines <- readLines(.checkfile(wd, pkg))
    ind <- any(grepl("Installation failed", lines))
}

.runExtended <- function(res) {
    options("width"=200)

    if (!is.null(cfg <- getConfig())) {
        if ("setup" %in% names(cfg)) source(cfg$setup)
        if ("workdir" %in% names(cfg)) {
            wd <- cfg$workdir
            if (!dir.exists(wd)) {
                dir.create(wd)
            }
        }
        if ("libdir" %in% names(cfg)) {
            ## setting the environment variable works with littler, but not with RScript
            Sys.setenv("R_LIBS_USER"=cfg$libdir)
            if (!dir.exists(cfg$libdir)) {
                dir.create(cfg$libdir)
            }
            env <- paste0("R_LIBS=\"", cfg$libdir, "\"")
        }
        if ("verbose" %in% names(cfg)) verbose <- cfg$verbose == "true"
        if ("debug" %in% names(cfg)) debug <- cfg$debug == "true"
    }

    failed <- res[result==1, .(package=unique(sort(package)))]

    failed[ , `:=`(hasCheckLog=file.exists(.checkfile(wd, package)),
                   hasInstallLog=file.exists(.installfile(wd, package))), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE, missingPkg:=.grepMissing(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==FALSE, missingPkg:=.grepRequired(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE & missingPkg=="", missingPkg:=.grepNeeded(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE & missingPkg=="", badInstall:=.grepInstallationFailed(wd, package), by=package]

    print(failed[ missingPkg=="" & badInstall==TRUE,])
    ##print(failed[hasCheckLog==TRUE & hasInstallLog==FALSE, ])
    #print(failed)
}

## make R CMD check happy
globalVariables(c(".", ".N", "result", "starttime", "endtime",
                  "times", "runtime", "runner", "status"))
