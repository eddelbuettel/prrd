
.pkgenv <- new.env(parent=emptyenv())

##' @rdname getDataDirectory
runSanityChecks <- function() {

    isLinux <- .onLinux <- .Platform$OS.type == "unix" && unname(Sys.info()["sysname"]) == "Linux"

    .pkgenv[["xvfb"]] <- ""             # default is nothing here

    if (isLinux) {
        if (unname(Sys.which("xvfb-run")) == "") {
            stop("Please install xvfb-run; it should be available from of your Linuxdistribution.",
                 call.=FALSE)
        }
        .pkgenv[["xvfb"]] <- "xvfb-run --server-args=\"-screen 0 1024x768x24\""

        if (unname(Sys.which("xvfb-run-safe")) == "")
            stop("Please install xvfb-run-safe (from the scripts/ directory) in the PATH.",
                 call.=FALSE)
        .pkgenv[["xvfb"]] <- "xvfb-run-safe --server-args=\"-screen 0 1024x768x24\""
    }

    NULL

}


##' @rdname getDataDirectory
runEnqueueSanityChecks <- function() {
    cran <- getOption("repos")[["CRAN"]]
    if (cran == "@CRAN@") {
        stop("\tNo default CRAN mirror set, so cannot download package information.\n\t",
             "See 'help(\"setRepositories\")' as well as 'help(\"option\")' for its 'cran' entry.",
             call.=FALSE)
    }

    NULL
}
