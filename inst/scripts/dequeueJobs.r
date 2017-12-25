#!/usr/bin/env r

suppressMessages({
    library(prrd)
    library(liteq)
    library(docopt)
    library(data.table)
    library(crayon)
})

## configuration for docopt
doc <- "Usage: dequeueJobs.r [-h] [-x] PACKAGE

-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt(doc)			# docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  dequeueJobs.r

dequeueJobs.r is part of prrd.r which may one day grow to become a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/...TBD.... for more information.\n")
    q("no")
}

pkg <- opt$PACKAGE

check()                                 # checks for xvfb-run-safe

## setting repos now in local/setup.R

db <- getQueueFile(pkg)
q <- ensure_queue("jobs", db = db)

con <- getDatabaseConnection(db)        # we re-use the liteq db for our results
createTable(con)

pid <- Sys.getpid()
hostname <- Sys.info()[["nodename"]]
wd <- cwd <- getwd()
debug <- verbose <- FALSE

if (!is.null(cfg <- getConfig())) {
    if ("setup" %in% names(cfg)) source(cfg$setup)
    if ("workdir" %in% names(cfg)) wd <- cfg$workdir
    if ("libdir" %in% names(cfg)) Sys.setenv("R_LIBS_USER"=cfg$libdir)
    if ("verbose" %in% names(cfg)) verbose <- cfg$verbose == "true"
    if ("debug" %in% names(cfg)) debug <- cfg$debug == "true"
}

good <- bad <- 0

## work down messages, if any
while (!is.null(msg <- try_consume(q))) {
    starttime <- Sys.time()
    if (debug) print(msg)

    cat(msg$message, "started at", format(starttime), "")

    tok <- strsplit(msg$message, "_")[[1]]      # now have package and version in tok[1:2]
    pkgfile <- paste0(msg$message, ".tar.gz")

    ## deal with exclusion set here or in enqueue ?
    setwd(wd)

    if (file.exists(pkgfile)) {
        if (verbose) cat("Seeing file", pkgfile, "\n")
    } else {
        ##download.file(pathpkg, pkg, quiet=TRUE)
        dl <- download.packages(tok[1], ".", method="wget", quiet=TRUE)
        pkgfile <- basename(dl[,2])
        if (verbose) cat("Downloaded ", pkgfile, "\n")
    }

    cmd <- paste("xvfb-run-safe --server-args=\"-screen 0 1024x768x24\" ",
                 "R",  #rbinary,         # R or RD
                 " CMD check --no-manual --no-vignettes ", pkgfile, " 2>&1 > ",
                 pkgfile, ".log", sep="")
    if (debug) print(cmd)
    rc <- system(cmd)
    if (debug) print(rc)

    setwd(cwd)
    endtime <- Sys.time()

    if (rc == 0) {
        ##if (verbose) cat("Success with", tok[1], "\n")
        good <- good + 1
        cat(green("success"), "at", format(endtime), good, "/", bad, "\n")
        ack(msg)
    } else {
        ##if (verbose) cat("Nope with", tok[1], "\n")
        bad <- bad + 1
        cat(red("failure"), "at", format(endtime), good, "/", bad, "\n")
        nack(msg)
    }

    row <- data.frame(package=tok[1],
                      version=tok[2],
                      result=rc,
                      starttime=format(starttime),
                      endtime=format(endtime),
                      runtime=as.numeric(difftime(endtime, starttime, units="secs")),
                      runner=pid,
                      host=hostname)
    if (debug) print(row)

    insertRow(con, row)
}
requeue_failed_messages(q)
print(list_messages(q))
