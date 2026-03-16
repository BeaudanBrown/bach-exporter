be_validate_script_release_root <- function(shared_root) {
  release_file <- file.path(shared_root, "CURRENT_RELEASE.txt")
  if (file.exists(release_file)) {
    release_id <- trimws(readLines(release_file, warn = FALSE, n = 1))
    if (nzchar(release_id)) {
      return(file.path(shared_root, "releases", release_id))
    }
  }

  if (file.exists(file.path(shared_root, "DESCRIPTION"))) {
    return(shared_root)
  }

  NULL
}

validate_release <- function(shared_root = ".", allow_dev = FALSE) {
  release_root <- be_validate_script_release_root(shared_root)
  source_root <- if (
    !is.null(release_root) &&
      file.exists(file.path(release_root, "R", "paths.R"))
  ) {
    release_root
  } else {
    normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
  }

  source(file.path(source_root, "R", "paths.R"), local = TRUE)
  source(file.path(source_root, "R", "release_runtime.R"), local = TRUE)

  validation <- be_validate_release_contract(
    shared_root = shared_root,
    allow_dev = allow_dev
  )

  if (isTRUE(validation$ok)) {
    cat(sprintf("Release contract valid: %s\n", validation$paths$release_root))
  } else {
    cat(sprintf("Release contract invalid: %s\n", validation$message))
  }

  validation
}

validate_release_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  shared_root <- if (length(args)) args[[1]] else "."
  allow_dev <- identical(Sys.getenv("BACH_ALLOW_DEV_RELEASE", unset = "0"), "1")

  validation <- validate_release(
    shared_root = shared_root,
    allow_dev = allow_dev
  )
  if (!isTRUE(validation$ok)) {
    quit(status = 1, save = "no")
  }

  invisible(validation)
}

if (sys.nframe() == 0) {
  validate_release_main()
}
