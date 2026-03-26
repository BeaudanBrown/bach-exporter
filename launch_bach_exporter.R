`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

be_launcher_status_text <- function(text) {
  text <- text %||% ""
  paste(as.character(text), collapse = "\n")
}

be_launcher_local_cache_root <- function() {
  candidates <- c(
    Sys.getenv("BACH_EXPORTER_LOCAL_CACHE_DIR", unset = ""),
    getOption("bachExporter.local_cache_dir", ""),
    tools::R_user_dir("bachExporter", which = "cache")
  )

  for (candidate in candidates) {
    if (is.null(candidate) || !nzchar(candidate)) {
      next
    }

    ok <- tryCatch(
      {
        dir.create(candidate, recursive = TRUE, showWarnings = FALSE)
        file.access(candidate, mode = 2) == 0
      },
      error = function(err) FALSE
    )

    if (isTRUE(ok)) {
      return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
    }
  }

  stop("Could not resolve a writable local cache directory.", call. = FALSE)
}

be_launcher_tmp_dir <- function() {
  root <- be_launcher_local_cache_root()
  path <- file.path(root, "tmp")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

be_launcher_use_tmp_dir <- function() {
  path <- be_launcher_tmp_dir()
  Sys.setenv(
    TMPDIR = path,
    TMP = path,
    TEMP = path
  )
  path
}

be_launcher_current_tempdir <- function() {
  normalizePath(tempdir(), winslash = "/", mustWork = FALSE)
}

be_launcher_tempdir_ready <- function(
  current_tempdir = be_launcher_current_tempdir()
) {
  desired <- be_launcher_tmp_dir()
  identical(current_tempdir, desired) ||
    startsWith(current_tempdir, paste0(desired, "/"))
}

be_launcher_script_path <- function(
  command_args = commandArgs(trailingOnly = FALSE)
) {
  file_arg <- command_args[grepl("^--file=", command_args)]
  if (!length(file_arg)) {
    stop("Could not resolve launcher script path.", call. = FALSE)
  }

  normalizePath(
    sub("^--file=", "", file_arg[[1]]),
    winslash = "/",
    mustWork = TRUE
  )
}

be_launcher_reexec_status <- function(
  command_args = commandArgs(trailingOnly = FALSE),
  trailing_args = commandArgs(trailingOnly = TRUE),
  current_tempdir = be_launcher_current_tempdir(),
  system2_runner = system2
) {
  if (
    be_launcher_tempdir_ready(
      current_tempdir = current_tempdir
    )
  ) {
    return(NULL)
  }

  desired <- be_launcher_tmp_dir()
  script_path <- be_launcher_script_path(command_args = command_args)
  rscript <- file.path(R.home("bin"), "Rscript")
  status <- system2_runner(
    rscript,
    args = c(script_path, trailing_args),
    env = c(
      sprintf("TMPDIR=%s", desired),
      sprintf("TMP=%s", desired),
      sprintf("TEMP=%s", desired)
    ),
    wait = TRUE
  )

  as.integer(status %||% 0L)
}

be_launcher_config_path <- function() {
  config_dir <- tools::R_user_dir("bachExporter", which = "config")
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  file.path(config_dir, "shared-root.json")
}

be_launcher_load_shared_root <- function(
  config_path = be_launcher_config_path()
) {
  if (!file.exists(config_path)) {
    return(NULL)
  }

  config <- jsonlite::read_json(config_path, simplifyVector = TRUE)
  root <- config$shared_root %||% NULL
  if (is.null(root) || !nzchar(root)) {
    return(NULL)
  }

  root
}

be_launcher_save_shared_root <- function(
  shared_root,
  config_path = be_launcher_config_path()
) {
  jsonlite::write_json(
    list(
      shared_root = normalizePath(
        shared_root,
        winslash = "/",
        mustWork = FALSE
      )
    ),
    path = config_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

be_launcher_preflight_shared_root <- function(shared_root) {
  if (is.null(shared_root) || !nzchar(shared_root)) {
    return(list(ok = FALSE, message = "Shared root path is empty."))
  }
  if (!dir.exists(shared_root)) {
    return(list(
      ok = FALSE,
      message = "Shared root directory does not exist."
    ))
  }

  app_root <- file.path(shared_root, "app")
  if (dir.exists(app_root)) {
    required_files <- c(
      file.path(app_root, "R", "paths.R"),
      file.path(app_root, "R", "release_runtime.R"),
      file.path(app_root, "scripts", "launch_from_share.R"),
      file.path(app_root, "scripts", "validate_release.R")
    )
    build_id <- if (file.exists(file.path(app_root, "manifest.json"))) {
      tryCatch(
        {
          manifest <- jsonlite::read_json(
            file.path(app_root, "manifest.json"),
            simplifyVector = TRUE
          )
          manifest$build_id %||% manifest$release_id %||% "<unknown>"
        },
        error = function(err) "<unknown>"
      )
    } else {
      "<unknown>"
    }
  } else if (
    file.exists(file.path(shared_root, "DESCRIPTION")) &&
      file.exists(file.path(shared_root, "scripts", "launch_from_share.R"))
  ) {
    app_root <- shared_root
    required_files <- c(
      file.path(app_root, "R", "paths.R"),
      file.path(app_root, "R", "release_runtime.R"),
      file.path(app_root, "scripts", "launch_from_share.R"),
      file.path(app_root, "scripts", "validate_release.R")
    )
    build_id <- "dev"
  } else {
    return(list(
      ok = FALSE,
      message = "Shared root is missing app/ and does not look like a direct app root."
    ))
  }

  missing_files <- required_files[!file.exists(required_files)]
  if (length(missing_files)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Release is missing required bootstrap files: %s",
        paste(basename(missing_files), collapse = ", ")
      ),
      missing_paths = missing_files
    ))
  }

  list(
    ok = TRUE,
    message = "Shared root passed bootstrap preflight.",
    paths = list(
      shared_root = shared_root,
      app_root = app_root,
      build_id = build_id,
      release_launcher = file.path(app_root, "scripts", "launch_from_share.R"),
      validate_script = file.path(app_root, "scripts", "validate_release.R")
    )
  )
}

be_launcher_validate_shared_root <- function(shared_root, allow_dev = TRUE) {
  preflight <- be_launcher_preflight_shared_root(shared_root)
  if (!isTRUE(preflight$ok)) {
    return(preflight)
  }

  validator_env <- new.env(parent = baseenv())
  sys.source(preflight$paths$validate_script, envir = validator_env)
  validation_output <- utils::capture.output(
    validation <- validator_env$validate_release(
      shared_root = shared_root,
      allow_dev = allow_dev
    )
  )
  invisible(validation_output)

  validation
}

launch_bach_exporter <- function() {
  be_launcher_use_tmp_dir()

  ensure_bootstrap_package <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }

  bootstrap_packages <- c(
    "shiny",
    "shinyFiles",
    "jsonlite",
    "bslib",
    "renv",
    "remotes"
  )
  invisible(lapply(bootstrap_packages, ensure_bootstrap_package))

  launch_bootstrap <- function(initial_root = NULL) {
    ui <- shiny::fluidPage(
      theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
      shiny::div(
        style = "max-width: 840px; margin: 40px auto;",
        shiny::h2("Locate Shared BACH Exporter Folder"),
        shiny::textInput(
          "shared_root",
          "Shared folder root",
          value = initial_root %||% ""
        ),
        shinyFiles::shinyDirButton(
          "browse_root",
          "Browse",
          "Choose shared folder"
        ),
        shiny::br(),
        shiny::br(),
        shiny::actionButton("validate_root", "Validate"),
        shiny::actionButton("continue_root", "Continue"),
        shiny::hr(),
        shiny::verbatimTextOutput("status")
      )
    )

    server <- function(input, output, session) {
      roots <- if (.Platform$OS.type == "windows") {
        shinyFiles::getVolumes()()
      } else {
        c(
          Home = normalizePath("~", winslash = "/", mustWork = FALSE),
          Root = "/"
        )
      }
      shinyFiles::shinyDirChoose(
        input,
        "browse_root",
        roots = roots,
        session = session
      )

      shiny::observeEvent(input$browse_root, {
        selected <- shinyFiles::parseDirPath(roots, input$browse_root)
        if (length(selected) == 1 && nzchar(selected)) {
          shiny::updateTextInput(session, "shared_root", value = selected)
        }
      })

      current_status <- shiny::reactiveVal(
        "Choose the shared root and validate it."
      )

      shiny::observeEvent(input$validate_root, {
        result <- be_launcher_validate_shared_root(input$shared_root)
        current_status(be_launcher_status_text(result$message))
        if (isTRUE(result$ok)) {
          be_launcher_save_shared_root(result$paths$shared_root)
        }
      })

      shiny::observeEvent(input$continue_root, {
        result <- be_launcher_validate_shared_root(input$shared_root)
        if (!isTRUE(result$ok)) {
          current_status(be_launcher_status_text(result$message))
          return()
        }
        be_launcher_save_shared_root(result$paths$shared_root)
        shiny::stopApp(result)
      })

      output$status <- shiny::renderText(
        be_launcher_status_text(current_status())
      )
    }

    shiny::runApp(
      shiny::shinyApp(ui, server),
      launch.browser = TRUE
    )
  }

  shared_root <- be_launcher_load_shared_root()
  validation <- be_launcher_validate_shared_root(shared_root %||% "")
  if (!isTRUE(validation$ok)) {
    validation <- launch_bootstrap(shared_root)
  }
  if (is.null(validation) || !isTRUE(validation$ok)) {
    stop("No valid shared root was selected.", call. = FALSE)
  }

  source(validation$paths$release_launcher, local = TRUE)
  launch_from_share(validation$paths$shared_root)
}

if (sys.nframe() == 0) {
  reexec_status <- be_launcher_reexec_status()
  if (is.null(reexec_status)) {
    launch_bach_exporter()
  } else {
    quit(save = "no", status = reexec_status)
  }
}
