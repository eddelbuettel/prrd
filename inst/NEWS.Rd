\name{NEWS}
\title{News for Package \pkg{prrd}}
\newcommand{\ghpr}{\href{https://github.com/eddelbuettel/prrd/pull/#1}{##1}}
\newcommand{\ghit}{\href{https://github.com/eddelbuettel/prrd/issues/#1}{##1}}

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
