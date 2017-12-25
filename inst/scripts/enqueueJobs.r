#!/usr/bin/env r

suppressMessages({
    library(prrd)
    library(liteq)
    library(docopt)
    library(data.table)
})

## configuration for docopt
doc <- "Usage: enqueuJobs.r [-h] [-x] PACKAGE

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

r <- character()
r["CRAN"] <- "http://cran.rstudio.com"
r["BioCsoft"] <- "http://www.bioconductor.org/packages/release/bioc"
options(repos = r)

AP <- available.packages(contrib.url(r["CRAN"]),filter=list())		# available package at CRAN
pkgset <- tools::dependsOnPkgs(pkg, recursive=FALSE, installed=AP)

AP <- setDT(as.data.frame(AP))
pkgset <- setDT(data.frame(Package=pkgset))

work <- AP[pkgset, on="Package"][,1:2]
#print(work)

db <- getQueueFile(pkg)
q <- ensure_queue("jobs", db = db)
##print(q)

n <- nrow(work)
for (i in 1:n) {
    ttl <- paste0(work[i,Package])
    msg <- paste(work[i,Package], work[i, Version], sep="_")
    #cat(ttl, "--", msg, "\n")
    publish(q, title = ttl, message = msg)
}

#publish(q, title = "Second message", message = "Hello again!")
print(list_messages(q))
