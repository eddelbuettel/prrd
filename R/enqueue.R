##' Enqueue package for subsequent reverse-dependency check
##'
##' This function relies on the \code{\link{available.packages}} function from R
##' along with the \code{liteq} package. The \code{getQueueFile} function is used to
##' determine the queue file directory and name.
##' @title Enqueues reverse-dependent packages
##' @param package A character variable denoting a package
##' @param directory A character variable denoting a directory
##' @param dbfile Optional character with path to previous runs db file
##' @param addfailed Optional logical swith to add previous failures
##' @return A queue is create as a side effect, its elements are returned invisibly
##' @author Dirk Eddelbuettel
##' @examples
##' \dontrun{
##' td <- tempdir()
##' options(repos=c(CRAN="https://cloud.r-project.org"))
##' jobsdf <- enqueueJobs(package="digest", directory=td)
##' }
enqueueJobs <- function(package, directory, dbfile="", addfailed=FALSE) {

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

    runEnqueueSanityChecks()              # currenly repos only

    if (dbfile != "") {
        if (file.exists(dbfile)) {
            db <- dbfile
        } else {
            stop("No file ", dbfile, " found\n", call. = FALSE)
        }
        con <- getDatabaseConnection(db)        # we re-use the liteq db for our results
        res <- setDT(dbGetQuery(con, "select * from results"))
        dbDisconnect(con)
    }

    ## available package at CRAN and/or elsewhere
    ## use cfg$setup to override/extend with additional (local) repos
    AP <- available.packages(filters=list())

    pkgset <- dependsOnPkgs(package, recursive=FALSE, installed=AP)
    if (length(pkgset) == 0) stop("No dependencies for ", package, call. = FALSE)

    AP <- setDT(as.data.frame(AP))

    if (dbfile == "") {
        pkgset <- data.table(Package=pkgset)
    } else {
        newpkgs <- setdiff(pkgset, res$package)
        if (addfailed) {
            failed <- res[ result == 1, .(package)]
            pkgset <- data.table(Package=unique(sort(c(failed$package, newpkgs))))
        } else {
            pkgset <- data.table(Package=newpkgs)
        }
    }
    work <- AP[pkgset, on="Package"][,1:2]
    db <- getQueueFile(package=package, path=directory)
    q <- ensure_queue("jobs", db = db)

    ## next line just to check .libPaths(), not needed here
    #IP <- installed.packages(filters=list())

    con <- getDatabaseConnection(db)        # we re-use the liteq db for our results
    createRunDataTable(con)
    dat <- data.frame(package=package,
                      version=format(packageVersion(package)),
                      date=format(Sys.Date()))
    dbWriteTable(con, "metadata", dat, append=TRUE)
    dbDisconnect(con)
    
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
