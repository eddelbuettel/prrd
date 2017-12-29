##' Enqueue package for subsequent reverse-dependency check
##'
##' This function relies on the \code{\link{available.packages}} function from R
##' along with the \code{liteq} package. The \code{getQueueFile} function is used to
##' determine the queue file directory and name.
##' @title Enqueues reverse-dependent packages
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @return A queue is create as a side effect, its elements are returned invisibly
##' @author Dirk Eddelbuettel
enqueueJobs <- function(package, directory) {

    ## available package at CRAN
    AP <- available.packages(contrib.url(options("repos")$repos[["CRAN"]]), filters=list())
    pkgset <- dependsOnPkgs(package, recursive=FALSE, installed=AP)

    AP <- setDT(as.data.frame(AP))
    pkgset <- setDT(data.frame(Package=pkgset))

    work <- AP[pkgset, on="Package"][,1:2]

    db <- getQueueFile(package=package, path=directory)
    q <- ensure_queue("jobs", db = db)

    n <- nrow(work)
    for (i in 1:n) {
        ttl <- paste0(work[i,Package])
        msg <- paste(work[i,Package], work[i, Version], sep="_")
        publish(q, title = ttl, message = msg)
    }

    list_messages(q)
}

globalVariables(c("Package", "Version")) # pacify R CMD check
