#!/usr/bin/env r

## configuration for docopt
doc <- "Usage: dequeueJobs.r [-q QUEUE] [-e EXCP] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: .]
-e --exclude EXCL     exclusion set filename [default: ]
-h --help             show this help text
-x --usage            show help and short example usage"

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  dequeueJobs.r

dequeueJobs.r is part of prrd.r which may one day grow to become a parallel rev dep runner.
See http://dirk.eddelbuettel.com/code/...TBD.... for more information.\n")
    q("no")
}

prrd::dequeueJobs(opt$PACKAGE, opt$queue, opt$exclude)
