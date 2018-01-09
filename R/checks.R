
##' @rdname getDataDirectory
runSanityChecks <- function() {
    if (unname(Sys.which("xvfb-run-safe")) == "")
        stop("Please install xvfb-run-safe (from the scripts/ directory) in the PATH", call.=FALSE)
    NULL
}
