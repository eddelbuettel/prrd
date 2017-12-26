
##' @rdname getDataDirectory
runSanityChecks <- function() {
    if (unname(Sys.which("xvfb-run-safe")) == "")
        stop("Please install xvfb-run-safe in PATH", call.=FALSE)
    NULL
}
