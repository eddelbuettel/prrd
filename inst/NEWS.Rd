\name{NEWS}
\title{News for Package \pkg{prrd}}
\newcommand{\ghpr}{\href{https://github.com/eddelbuettel/prrd/pull/#1}{##1}}
\newcommand{\ghit}{\href{https://github.com/eddelbuettel/prrd/issues/#1}{##1}}

\section{Changes in prrd version 0.0.4 (2021-01-23)}{
  \itemize{
    \item Report summary mode is now compact, more robust and reports
    extended CRAN summaries. (Dirk via several changes)
    \item Continuous Integration now uses \code{run.sh} from \pkg{r-ci}
  }
}

 \section{Changes in prrd version 0.0.3 (2020-04-19)}{
  \itemize{
    \item Extended functionality \code{summarise()} with optional use
    of package \code{foghorn} (Dirk)
    \item New scripts \code{enqueueDepends}, \code{dequeueDepends} and
    \code{summmariseJobs} (Dirk) 
    \item Added tweaks and enhancements throughout (Dirk)
    \item The default queue location can now be set via \code{options}
    (Dirk)
    \item Meta-data on package, version and date is now stored, and
    shown on dequeue startup (Dirk)
    \item The README.md was clarified and improved (Dirk, Avraham Adler
    in \ghpr{8}, Robert Nuske in \ghpr{10})
  }
}

\section{Changes in prrd version 0.0.2 (2018-01-24)}{
  \itemize{
    \item The package no longer require \code{wget}.
    \item Enhanced sanity checker function.
    \item Expanded and improved dequeue function.
    \item No longer use \code{$HOME} in \code{xvfb-run-safe} (\ghit{2}).
    \item The use of \code{xvfb-run} use is now conditional on the OS
    (\ghit{3}).
    \item The set of available packages is no longer constrained to
    CRAN, but could be via the local setup script (\ghit{4}).
    \item The \code{dequeue()} function now uses \code{system2()}.
    \item The \code{enqueue()} functions checks if no reverse
    dependencies are found and stops (\ghit{6}).
    \item The \code{enqueue()} functions checks for repository
    information being set (\ghit{5}).
  }
}

\section{Changes in prrd version 0.0.1 (2018-01-09)}{
  \itemize{
    \item Initial CRAN release, for now with 'unix-only' constraint
    \item Functions \code{enqueueJobs}, \code{dequeueJobs} and
    \code{summariseQueue} form the primary interface.
  }
}
