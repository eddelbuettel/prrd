
options("width"=200,
        "digits.secs"=2)

r <- character()
r["CRAN"] <- "https://cran.r-project.org"
options(repos = r)

if (exists("opt") &&
    "exclude" %in% names(opt) &&
    is.null(opt$exclude) &&
    file.exists("~/git/rcpp-logs/data/blacklist.csv")) {
    opt$exclude <- "~/git/rcpp-logs/data/blacklist.csv"
}

Sys.setenv("MAKE"="make")

Sys.setenv("BOOSTLIB"="/usr/include")   # for the borked src/Makevars of ExactNumCI
Sys.setenv("RGL_USE_NULL"="TRUE")       # Duncan Murdoch on r-package-devel on 12 Aug 2015#
Sys.setenv("VDIFFR_RUN_TESTS"="false")  # Xavier Robin to not have pROC run extra tests on 2019-11-10
Sys.setenv("_R_CHECK_TESTS_NLINES_"="0")# Xihui blog 2017-12-15 (and Michael Chirico re-post)

if (file.exists("~/git/rcpp-logs/data/dot.Makevars")) {
    Sys.setenv("R_MAKEVARS_USER"="~/git/rcpp-logs/data/dot.Makevars")
}
