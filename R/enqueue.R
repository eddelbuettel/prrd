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
##' @examples
##' td <- tempdir()
##' options(repos=c(CRAN="https://cloud.r-project.org"))
##' jobsdf <- enqueueJobs(package="digest", directory=td)
enqueueJobs <- function(package, directory) {

    if (!is.null(cfg <- getConfig())) {
        if ("setup" %in% names(cfg)) source(cfg$setup)
    }

    ## available package at CRAN and/or elsewhere
    ## use cfg$setup to override/extend with additional (local) repos
    AP <- available.packages(filters=list())

    pkgset <- dependsOnPkgs(package, recursive=FALSE, installed=AP)
    if (length(pkgset) == 0) stop("No dependencies for ", package, call.=FALSE)

    AP <- setDT(as.data.frame(AP))
    pkgset <- data.table(Package=pkgset)

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

##' @rdname enqueueJobs
enqueueDepends <- function(package, directory) {
    if (!is.null(cfg <- getConfig())) {
        if ("setup" %in% names(cfg)) source(cfg$setup)
        if ("libdir" %in% names(cfg)) {
            .libPaths(cfg$libdir)
            Sys.setenv("R_LIBS_USER"=cfg$libdir)
            if (!dir.exists(cfg$libdir)) {
                dir.create(cfg$libdir)
            }
        }
    }

    ## available package at CRAN and/or elsewhere
    ## use cfg$setup to override/extend with additional (local) repos
    AP <- available.packages(filters=list())

    pkgset <- dependsOnPkgs(package, recursive=FALSE, installed=AP)

    AP <- setDT(as.data.frame(AP))
    pkgset <- setDT(data.frame(Package=pkgset))

    work <- AP[pkgset, on="Package"][,1:2]

    deplst <- package_dependencies(as.character(work[[1]]), db=as.matrix(AP), recursive=TRUE)
    deppkg <- unique(sort(do.call(c, deplst)))
    IP <- installed.packages()
    needed <- setdiff(deppkg, IP[, "Package"])

    db <- getQueueFile(package=package, path=directory)
    q <- ensure_queue("depends", db = db)

    n <- length(needed)
    for (i in 1:n) {
        ttl <- paste0(needed[i])
        msg <- paste(needed[i])
        publish(q, title = ttl, message = msg)
    }

    list_messages(q)
}

globalVariables(c("Package", "Version")) # pacify R CMD check
