#!/usr/bin/Rscript

setwd(tempdir())

library(prrd)

### Seven reverse dependencies which themselves have dependencies
##enqueueJobs("RcppGSL", ".")
##dequeueJobs("RcppGSL", ".")

## Just one
inqueue <- enqueueJobs("RcppClassic", ".")
outqueue <- dequeueJobs("RcppClassic", ".")
