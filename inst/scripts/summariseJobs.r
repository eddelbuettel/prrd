#!/usr/bin/env r
#
## configuration for docopt
doc <- "Usage: summarizeJobs.r [-p PACKAGE] [-e] [-f] [-h] [-x] [QUEUEFILE]

-p --package PACKAGE  name used in output text [default: unknown]
-e --extended         run extended summary looking at failures [default: false]
-f --foghorn          if extended, also use 'foghorn' package for detauls [default: false]
-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  summarizeJobs.r queue.sqlite     # explicit queue file
  summarizeJobs.r                  # infers from queue directory and date

summarizeJobs.r is part of prrd.r which is becoming a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/prrd.html for more information.\n")
    q("no")
}

if (is.null(opt$QUEUEFILE)) {
    resdir <- dir(path=getOption("prrd.queue_directory"), pattern=paste0("*", format(Sys.Date())))
    qf <- file.path(path=getOption("prrd.queue_directory"), resdir, "queuefile.sqlite")
    if (!file.exists(qf)) stop("No queue given, and none found.", call. = FALSE)
    opt$QUEUEFILE <- qf
}

prrd::summariseQueue("", "", dbfile=opt$QUEUEFILE, extended=opt$extended, foghorn=opt$foghorn)
