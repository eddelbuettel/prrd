#!/usr/bin/env r

suppressMessages({
    library(prrd)
    library(liteq)
    library(docopt)
    library(data.table)
})

## configuration for docopt
doc <- "Usage: enqueuJobs.r [-q QUEUE] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: .]
-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt(doc)			# docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  enqueueJobs.r Rcpp

enqueueJobs.r is part of prrd.r which may one day grow to become a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/...TBD.... for more information.\n")
    q("no")
}

pkg <- opt$PACKAGE
dir <- opt$queue

enqueueJobs(pkg, dir)
