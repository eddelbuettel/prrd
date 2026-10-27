if (.Platform$OS.type != "windows") {
    db <- tempfile("prrd-lock-test-")
    q <- prrd:::.ensureLockedQueue("jobs", db)

    workers <- parallel::mclapply(seq_len(2), function(worker) {
        q <- prrd:::.ensureLockedQueue("jobs", db)
        for (job in seq_len(120)) {
            prrd:::.publishLocked(q, title=paste(worker, job),
                                 message=paste(worker, job))
        }
        NULL
    }, mc.cores=2)
    stopifnot(all(vapply(workers, is.null, logical(1))))
    stopifnot(nrow(prrd:::.listMessagesLocked(q)) == 240)

    consumed <- 0L
    repeat {
        msg <- prrd:::.tryConsumeLocked(q)
        if (is.null(msg)) break
        prrd:::.ackLocked(msg)
        consumed <- consumed + 1L
    }
    stopifnot(consumed == 240L)
    stopifnot(nrow(prrd:::.listMessagesLocked(q)) == 0L)
}
