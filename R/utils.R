##' These functions create a data directory name given a package name
##' and additional optional arguments which can be used to store test
##' meta-data and results, return a queue file name, return the
##' configuration object (retrieved from several standard locations)
##' and load the exclusion set.
##'
##' Additional helper functions get particular directories, config settings or
##' check some assumptions about files in \code{PATH} and alike,
##'
##' @section Config File:
##' An optional config file can be used to set several configuration variables.
##' Currently supported are
##' \describe{
##'   \item{setup}{The path to an R file that will be \code{source}'ed.}
##'   \item{workdir}{The directory used for the parallel run of reverse depends.}
##'   \item{libdir}{The directory passed to \code{.libPaths} allow for additonal
##' build-dependencies.}
##'   \item{debug}{A boolean switch to enable more debugging output.}
##'   \item{verbose}{A boolean switch to enable more verbose output.}
##' }
##' The \code{setup} field is particularly useful as the file being sourced
##' can contain other R expressions setting environment variables or options.
##' It is (currently) searched in the four locations \dQuote{.prrd.yaml},
##' \dQuote{~/.R/prrd.yaml}, \dQuote{~/.prrd.yaml},  and \dQuote{/etc/R/prrd.yaml}.
##' The first file found ends the search and is used, content is not merged from
##' several files.
##' @title Various Helper Functions
##' @param package Character variable providing the package name.
##' @param date Optional character variable describing a date, default
##'  is current date.
##' @param path Optional path, default is current directory.
##' @param sep Optional character with component separator, default is \dQuote{_}.
##' @param debug Optional boolean
##' @param exclusionfile Character variable with path and file for an optional
##' exclusion set.
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

##' @rdname getDataDirectory
getConfig <- function(debug=FALSE) {
    candidates <- c(".prrd.yaml", "~/.R/prrd.yaml", "~/.prrd.yaml", "/etc/R/prrd.yaml")
    for (f in candidates) {
        if (file.exists(f)) {
            if (debug) cat("Loading ", f, "\n")
            cfg <- config::get(file=f)
            return(cfg)
        }
    }
    return(NULL)
}

##' @rdname getDataDirectory
getExclusionSet <- function(exclusionfile) {
    if (!file.exists(exclusionfile)) stop("File ", exclusionfile, " not found", call.=FALSE)
    exclset <- read.csv(exclusionfile, stringsAsFactors=FALSE, comment.char="#")[,1]
    exclset
}
