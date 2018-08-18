#!/usr/bin/env r
#
## configuration for docopt
doc <- "Usage: summarizeJobs.r [-p PACKAGE] [-e] [-f] [-h] [-x] QUEUEFILE

-p --package PACKAGE  name used in output text [default: unknown]
-e --extended         run extended summary looking at failures [default: false]
-f --foghorn          if extended, also use 'foghorn' package for detauls [default: false]
-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  summarizeJobs.r queue.sqlite

summarizeJobs.r is part of prrd.r which is becoming a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/prrd.html for more information.\n")
    q("no")
}

prrd::summariseQueue(opt$package, "", dbfile=opt$QUEUEFILE, extended=opt$extended, foghorn=opt$foghorn)
