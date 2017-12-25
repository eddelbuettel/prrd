#!/usr/bin/env r

suppressMessages({
    library(prrd)
    library(liteq)
    library(docopt)
    library(data.table)
    library(crayon)
})

## configuration for docopt
doc <- "Usage: dequeueJobs.r [-q QUEUE] [-e EXCP] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: .]
-e --exclude EXCL     exclusion set filename [default: ]
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
dir <- opt$queue

check()                                 # checks for xvfb-run-safe

## setting repos now in local/setup.R

db <- getQueueFile(package=pkg, path=dir)
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

exclset <- if (opt$excl != "") getExclusionSet(opt$excl) else character()

good <- bad <- skipped <- 0

## work down messages, if any
while (!is.null(msg <- try_consume(q))) {
    starttime <- Sys.time()
    if (debug) print(msg)

    cat(msg$message, "started at", format(starttime), "")

    tok <- strsplit(msg$message, "_")[[1]]      # now have package and version in tok[1:2]
    pkgfile <- paste0(msg$message, ".tar.gz")

    if (tok[1] %in% exclset) {
        rc <- 2

    } else {

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
    }
    endtime <- Sys.time()

    if (rc == 0) {
        good <- good + 1
        cat(green("success"))
        ack(msg)
    } else if (rc == 2) {
        skipped <- skipped + 1
        cat(green("skipped"))
        ack(msg)
    } else {
        bad <- bad + 1
        cat(red("failure"))
        ack(msg)
    }
    cat("", "at", format(endtime),
        paste0("(",green(good), "/", blue(skipped), "/", red(bad), ")"),
        "\n")

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
if (verbose) print(list_messages(q))
