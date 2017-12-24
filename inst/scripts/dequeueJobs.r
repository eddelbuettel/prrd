#!/usr/bin/env r

suppressMessages({
    library(prrd)
    library(liteq)
    library(docopt)
    library(data.table)
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
r <- character()
r["CRAN"] <- "http://cran.rstudio.com"
r["BioCsoft"] <- "http://www.bioconductor.org/packages/release/bioc"
options(repos = r)

db <- getQueueFile(pkg)
q <- ensure_queue("jobs", db = db)

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
res <- data.frame(pkg=pkg, res=NA, stringsAsFactors=FALSE)
good <- bad <- pi <- 0
set.seed(42)

## work down messages, if any
while (!is.null(msg <- try_consume(q))) {
    pi <- pi + 1
    starttime <- Sys.time()
#    print(msg)
#    print(str(msg))

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

    res[pi, ] <- c(tok[1], rc)
    if (rc == 0) {
        good <<- good + 1
    } else {
        bad <<- bad + 1
    }

    endtime <- Sys.time()
    row <- data.frame(package=tok[1],
                      version=tok[2],
                      result=rc,
                      starttime=format(starttime),
                      endtime=format(endtime),
                      runtime=as.numeric(difftime(endtime, starttime, units="secs")),
                      runner=pid,
                      host=hostname)
    print(row)

    setwd(cwd)


    #sqlcmd <- "insert into results values(", tok[1], tok[2], rc,
    ## set timeout
    ##   dbExecute(con, "PRAGMA busy_timeout = 1000")
    ## set transaction lock equiv
    ##   dbExecute(con, "BEGIN EXCLUSIVE")
    ## run insert
    ## commit
    ##   db_execute(con, "COMMIT")

    if (rc == 0) {
        cat("Success with", tok[1], "\n")
        ack(msg)
    } else {
        cat("Nope with", tok[1], "\n")
        nack(msg)
    }
}
requeue_failed_messages(q)
print(list_messages(q))
print(res)
