#!/usr/bin/env r

## configuration for docopt
doc <- "Usage: dequeueDepends.r [-q QUEUE] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: .]
-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  dequeueDepends.r

dequeueDepends.r is part of prrd.r which is becoming a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/...TBD.... for more information.\n")
    q("no")
}

prrd::dequeueDepends(opt$PACKAGE, opt$queue)
