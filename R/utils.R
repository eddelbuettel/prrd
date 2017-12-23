##' This functions create a data directory given a package name and
##' additional optional arguments which can be used to store test
##' meta-data and results.
##'
##' @title Create a data directory
##' @param package Character variable providing the package name.
##' @param date Optional character variable describing a date, default
##'  is current date.
##' @param path Option path, default is current directory.
##' @param sep Optional component separator, default is \dQuote{_}.
##' @return A directory name.
##' @author Dirk Eddelbuettel
getDataDirectory <- function(package, date=format(Sys.Date()), path=".", sep="_") {
    dir <- file.path(path, paste(package, date, sep=sep))
    if (!dir.exists(dir)) {
        if (!dir.create(dir)) stop("Cannot create ", dir, call.=FALSE)
    }
    dir
}

##' @rdname getDataDirectory
getQueueFile <- function(package, date=format(Sys.Date()), path=".", sep="_" ) {
    dir <- getDataDirectory(package, date, path, sep)
    queue <- file.path(dir, "queuefile.sqlite")
    queue
}

getConfig <- function() {
    candidates <- c("~/.R/prrd.yaml", "~/.prrd.yaml", "/etc/R/prrd.yaml")
    for (f in candidates) {
        if (file.exists(f)) {
            #cat("Loading ", f, "\n")
            cfg <- config::get(file=f)
            return(cfg)
        }
    }
    return(NULL)
}
