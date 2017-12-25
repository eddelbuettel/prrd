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

AP <- available.packages(contrib.url(r["CRAN"]),filter=list())		# available package at CRAN
pkgset <- tools::dependsOnPkgs(pkg, recursive=FALSE, installed=AP)

AP <- setDT(as.data.frame(AP))
pkgset <- setDT(data.frame(Package=pkgset))

work <- AP[pkgset, on="Package"][,1:2]

db <- getQueueFile(package=pkg, path=dir)
q <- ensure_queue("jobs", db = db)

n <- nrow(work)
for (i in 1:n) {
    ttl <- paste0(work[i,Package])
    msg <- paste(work[i,Package], work[i, Version], sep="_")
    publish(q, title = ttl, message = msg)
}

print(list_messages(q))
