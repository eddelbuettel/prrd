## prrd  [![Build Status](https://travis-ci.org/eddelbuettel/prrd.svg)](https://travis-ci.org/eddelbuettel/prrd) [![License](https://eddelbuettel.github.io/badges/GPL2+.svg)](http://www.gnu.org/licenses/gpl-2.0.html) [![CRAN](http://www.r-pkg.org/badges/version/prrd)](https://cran.r-project.org/package=prrd) [![Downloads](http://cranlogs.r-pkg.org/badges/prrd?color=brightgreen)](http://www.r-pkg.org/pkg/prrd)

Parallel Running [of] Reverse Depends

### Motivation

[R](https://www.r-project.org) packages available via the [CRAN](https://cran.r-project.org) mirror
network system are of consistently high quality and tend to "Just Work".  One of the many reasons
for this is a good culture of "do not break other packages" which is controlled for / enacted by the
CRAN maintainers. Package maintainers are expected to do their part---but checking their packages.

To take one example, [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) is package with a pretty
large tail of dependencies: as of this writing in late 2017, about 1270 other packages use it.  So
1270 other packages need to be tested.  This takes time, especially when running serially.  But it
is easy to parallelise.

### How

Previously, a few ad-hoc scripts (available
[here](https://github.com/RcppCore/rcpp-logs/tree/master/scripts)) were used for a number of
packages.  The scripts were one-offs and did their job. But with the idea of running jobs in
parallel, the [liteq](https://cran.r-project.org/package=liteq) package by
[Gabor Csardi](https://github.com/gaborcsardi) fit the requirements nicely.

#### Enqueuing

The first operation is to _enqueue_ jobs. In the simplest form we do (assuming the included script
is in the `PATH`)

```sh
$ enqueueJobs -q queueDirectory Rcpp
```

The same operation can also be done from R itself, see `help(enqueueJobs)`.  A package name has to
be supplied, a directory name (for the queue directory) is optional.  This function uses two base R 
functions to get all available package, and to determine the (non-recursive, first-level) reverse
dependencies of the given package. These are then added to the queue as "jobs".

#### Dequeuing

This is the second operation, and it can be done in parallel.  In other words, in several shells 
do 

```sh
$ dequeueJobs -q queueDirectory Rcpp
```

which will find the (current) queue file in the specified directory for the given package, here
`Rcpp`.  Again, this can also be done from an R prompt if you prefer, see `help(dequeueJobs)`.

Each worker, when idle, goes to the queue and requests a job, which he then labors over by testing
the thus-given reverse depedency.  Once done, the worker is idle and returns to the queue and the
cycle repeats. 

As there is absolutely no interdepedence between the tests, this parallelises easily and up to the
resource level of the machine.

### Performance 

To illustrate, "wall time" for a reverse-dependecy check of
[Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) decreased from 14.91 hours to 3.75 hours (or
almost four-fold) using six workers. An earlier run of
[RcppArmadillo](http://dirk.eddelbuettel.com/code/rcpp.armadillo.html) decreased from 5.87 hours to
1.92 hours (or just over three-fold) using four workers, and to 1.29 hours (or by 4.5) using six
workers (and a fresh `ccache`, see
[here](http://dirk.eddelbuettel.com/blog/2017/11/27#011_faster_package_installation_one) for its
impact).  In all cases the machine was used which was generally not idle.

The following screenshot shows a run for
[RcppArmadillo](http://dirk.eddelbuettel.com/code/rcpp.armadillo.html) with six workers. It shows
the successes in green, skipped jobs in blue (from packages which sometimes would result in runaway tests) and no failures (which would be shown in red).

![](https://github.com/eddelbuettel/prrd/raw/master/local/screenshot_prrd_rcpparmadillo.png)

The split screen, as well as the additional tabls, is thanks to the wonderful
[byobu](http://byobu.co) wrapper around [tmux](https://github.com/tmux/tmux).

### Configuration

The scripts use an internal YAML file access via the
[config](https://cran.r-project.org/package=config) package by JJ. The following locations are
searched: `.prrd.yaml`, `~/.R/prrd.yaml`, `~/.prrd.yaml`, and `/etc/R/prrd.yaml`.  For my initial
tests I used these values:

```
## config for prrd package
default:
  setup: "~/git/prrd/local/setup.R"
  workdir: "/tmp/prrd"
  libdir: "/tmp/prrd/lib"
  debug: "false"
  verbose: "false"
```

The `workdir` and `libdir` variables specify where tests are run, and which additonal library
directory is used.  A more interesting variable is `setup` which points to a helper scripts which
gets sourced.  This permits setting of the CRAN repo address as well as of additonal environment
variables etc as needed for tests. My current script is
[in the repository](https://github.com/eddelbuettel/prrd/blob/master/local/setup.R).


### Status

While the package is new, it has already been used for a few complete reverse depends tests runs.

### Installation

The package is not yet on CRAN, but may be uploaded "soon".

### Authors

Dirk Eddelbuettel

### License

GPL (>= 2)
