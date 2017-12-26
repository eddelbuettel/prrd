
options("width"=100,
        "digits.secs"=2)

r <- character()
r["CRAN"] <- "http://cran.rstudio.com"
#r["BioCsoft"] <- "http://www.bioconductor.org/packages/release/bioc"
options(repos = r)

if (exists("opt") && "exclset" %in% names(opt) && opt$exclset == "") {
    opt$exclset <- "~/git/rcpp-log/data/blacklist.csv"
}

Sys.setenv("MAKE"="make")
