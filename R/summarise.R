
##' Summarise results from (potentially parallel) reverse-dependency check
##'
##' @title Summarisse results from a reverse-dependency check
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @param dbfile A character variable for an optional override which, if
##' present, is used over \sQuote{package} and \sQuote{directory}.
##' @param extended A boolean variable to select extended analysis of
##' failures, default is \code{FALSE} which skips this.
##' @param foghorn A boolean variable to invoke the \CRANpkg{foghorn} to
##' retrieve and review CRAN result status, default is \code{FALSE} which
##' skips this.
##' @return NULL, invisibly
##' @author Dirk Eddelbuettel
summariseQueue <- function(package, directory, dbfile="", extended=FALSE, foghorn=FALSE) {
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
    meta <- dbGetQuery(con, "select * from metadata")
    dbDisconnect(con)

    if (nrow(res) == 0) {		    # if started before any results logged
       return(invisible(res))
    }

    cat("Test of", meta[1,"package"], meta[1,"version"], "had",
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
        print(jobs[status=="READY",], nrows=20, topn=10)
    } else {
        cat("None still scheduled\n")
    }

    if (extended && (res[result==0,.N] > 0)) {
        ext <- .runExtended(res, foghorn)
        invisible(return(list(res=res, ext=ext)))
    }
    invisible(res)
}

.checkfile <- function(wd, pkg) file.path(wd, paste0(pkg, ".Rcheck"), "00check.log")

.installfile <- function(wd, pkg) file.path(wd, paste0(pkg, ".Rcheck"), "00install.out")

.grepMissing <- function(wd, pkg) {
    file <- .checkfile(wd, pkg)
    if (!file.exists(file)) return("")
    lines <- readLines(file)
    ind <- grep("there is no package called", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
    gsub(".*there is no package called ", "", ll)
}

.grepRequired <- function(wd, pkg) {
    file <- .checkfile(wd, pkg)
    if (!file.exists(file)) return("")
    lines <- readLines(file)
    if (any(lines == "Packages required but not available:")) {
        ind <- which("Packages required but not available:" == lines)
        return(lines[ind+1])
    }
    ind <- grep("Package.* required but not available", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
    gsub(".*but not available: ", "", ll)
}

.grepNeeded <- function(wd, pkg) {
    file <- .checkfile(wd, pkg)
    if (!file.exists(file)) return("")
    lines <- readLines(file)
    ind <- grep("package.* need.*", lines)
    if (length(ind) == 0) return("")
    if (length(ind) >= 2) ind <- ind[1]
    ll <- lines[ind]
}

.grepInstallationFailed <- function(wd, pkg) {
    file <- .checkfile(wd, pkg)
    if (!file.exists(file)) return(FALSE)
    lines <- readLines(file)
    ind <- any(grepl("Installation failed", lines))
}

.runExtended <- function(res, foghorn=FALSE) {

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
                   hasInstallLog=file.exists(.installfile(wd, package))),
           by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE, missingPkg:=.grepMissing(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==FALSE, missingPkg:=.grepRequired(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE & missingPkg=="", missingPkg:=.grepNeeded(wd, package), by=package]

    failed[hasCheckLog==TRUE & hasInstallLog==TRUE & missingPkg=="", badInstall:=.grepInstallationFailed(wd, package), by=package]

    if (foghorn && requireNamespace("foghorn", quietly=TRUE)) {
        failed[badInstall==FALSE,
	       c("error", "fail", "warn", "note", "ok", "hasOtherIssue") :=
	         data.frame( foghorn::cran_results(pkg=package)[1,-1], src="crandb" ),
	       by=package]
    }

    cat("\nError summary:\n")
    print(failed[, -c(2:3)])
    invisible(failed)
}

## make R CMD check happy
globalVariables(c(".", ".N", "result", "starttime", "endtime",
                  "times", "runtime", "runner", "status",
                  ":=", "badInstall", "hasCheckLog", "hasInstallLog",
                  "missingPkg", "package"))
