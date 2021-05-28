#!/usr/bin/env r

## configuration for docopt
doc <- paste0("Usage: dequeueJobs.r [-q QUEUE] [-e EXCP] [-h] [-x] PACKAGE

-q --queue QUEUE      set queue directory [default: ", getOption("prrd.queue_directory", "."), "]
-e --exclude EXCL     exclusion set filename [default: ]
-d --date DATE        exclusion set filename [default: ", format(Sys.Date()), "]
-h --help             show this help text
-x --usage            show help and short example usage")

opt <- docopt::docopt(doc)              # docopt parsing

if (opt$usage) {
    cat(doc, "\n\n")
    cat("Examples:
  dequeueJobs.r

dequeueJobs.r is part of prrd.r which is becoming a parallel rev dep runner.
See https://dirk.eddelbuettel.com/code/prrd.html for more information.\n")
    q("no")
}

prrd::dequeueJobs(opt$PACKAGE, opt$queue, opt$exclude, opt$date)
