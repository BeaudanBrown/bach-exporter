be_validate_script_app_root <- function(shared_root) {
  app_root <- file.path(shared_root, "app")
  if (dir.exists(app_root)) {
    return(app_root)
  }

  if (file.exists(file.path(shared_root, "DESCRIPTION"))) {
    return(shared_root)
  }

  NULL
}

validate_release <- function(shared_root = ".", allow_dev = FALSE) {
  app_root <- be_validate_script_app_root(shared_root)
  source_root <- if (
    !is.null(app_root) &&
      file.exists(file.path(app_root, "R", "paths.R"))
  ) {
    app_root
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
    cat(sprintf("Release contract valid: %s\n", validation$paths$app_root))
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
