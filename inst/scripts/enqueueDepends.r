#!/usr/bin/env r

## configuration for docopt
doc <- paste0("Usage: enqueueDepends.r [-q QUEUE] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: ", getOption("prrd.queue_directory", "."), "]
-h --help             show this help text
-x --usage            show help and short example usage")

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  enqueueDepends.r Rcpp

enqueueDepends.r is part of prrd.r which is becoming a parallel rev dep runner.
See https://dirk.eddelbuettel.com/code/prrd.html for more information.\n")
    q("no")
}

prrd::enqueueDepends(opt$PACKAGE, opt$queue)
