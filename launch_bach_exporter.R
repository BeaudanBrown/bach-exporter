`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

be_launcher_status_text <- function(text) {
  text <- text %||% ""
  paste(as.character(text), collapse = "\n")
}

be_make_tree_user_writable <- function(path) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(invisible(FALSE))
  }

  targets <- c(
    path,
    list.files(
      path,
      all.files = TRUE,
      full.names = TRUE,
      recursive = TRUE,
      include.dirs = TRUE,
      no.. = TRUE
    )
  )
  suppressWarnings(Sys.chmod(targets, mode = "755", use_umask = FALSE))
  invisible(TRUE)
}

be_prepare_overwrite_targets <- function(paths) {
  if (!length(paths)) {
    return(invisible(character()))
  }

  for (path in unique(as.character(paths))) {
    if (!file.exists(path)) {
      next
    }

    if (isTRUE(file.info(path)$isdir)) {
      be_make_tree_user_writable(path)
    } else {
      suppressWarnings(Sys.chmod(path, mode = "644", use_umask = FALSE))
    }
  }

  invisible(paths)
}

be_safe_copy_into_dir <- function(
  from,
  out_dir,
  overwrite = TRUE,
  recursive = FALSE
) {
  dest_paths <- file.path(out_dir, basename(from))
  if (isTRUE(overwrite)) {
    be_prepare_overwrite_targets(dest_paths)
  }

  file.copy(
    from,
    out_dir,
    overwrite = overwrite,
    recursive = recursive,
    copy.mode = FALSE
  )
}

be_patch_bslib_dependency_copies <- function() {
  if (!requireNamespace("bslib", quietly = TRUE)) {
    return(FALSE)
  }

  ns <- asNamespace("bslib")
  if (isTRUE(getOption("bachExporter.bslib_copy_patch_applied", FALSE))) {
    return(TRUE)
  }

  patch_env <- list2env(
    list(be_safe_copy_into_dir = be_safe_copy_into_dir),
    parent = ns
  )

  patched_bs_dependency <- function(
    input = list(),
    theme,
    name,
    version,
    cache_key_extra = NULL,
    .dep_args = list(),
    .sass_args = list()
  ) {
    sass_args <- c(
      list(
        rules = input,
        bundle = theme,
        output = output_template(basename = name, dirname = name),
        write_attachments = TRUE,
        cache_key_extra = cache_key_extra
      ),
      .sass_args
    )
    outfile <- do.call(sass_partial, sass_args)
    dep_args <- list(
      name = name,
      version = version,
      src = dirname(outfile),
      stylesheet = basename(outfile)
    )
    bad_args <- intersect(names(.dep_args), names(dep_args))
    if (length(bad_args)) {
      stop(
        "The following `.dep_args` must be provided as top-level args to `bs_dependency()`: ",
        paste(bad_args, collapse = ", ")
      )
    }
    if ("package" %in% names(.dep_args)) {
      warning(
        "`package` won't have any effect since `src` must be an absolute path"
      )
    }
    script <- .dep_args[["script"]]
    if (length(script)) {
      if (basename(outfile) %in% basename(script)) {
        stop(
          "`script` file basename(s) must all be something other than ",
          basename(outfile)
        )
      }
      success <- be_safe_copy_into_dir(
        script,
        dirname(outfile),
        overwrite = TRUE
      )
      if (!all(success)) {
        stop(
          "Failed to copy the following script(s): ",
          paste(script[!success], collapse = ", "),
          ".\n\n",
          "Make sure script are absolute path(s)."
        )
      }
      .dep_args[["script"]] <- basename(script)
    }
    do.call(htmlDependency, c(dep_args, .dep_args))
  }

  environment(patched_bs_dependency) <- patch_env

  patched_bs_theme_dependencies <- function(
    theme,
    sass_options = sass::sass_options_get(output_style = "compressed"),
    cache = sass::sass_cache_get(),
    jquery = jquerylib::jquery_core(3),
    precompiled = get_precompiled_option("bslib.precompiled", default = TRUE)
  ) {
    theme <- as_bs_theme(theme)
    version <- theme_version(theme)
    if (isTRUE(version >= 5)) {
      register_runtime_package_check(
        "`bs_theme(version = 5)`",
        "shiny",
        "1.7.0"
      )
    }
    if (is.character(cache)) {
      cache <- sass_cache_get_dir(cache)
    }
    out_file <- NULL
    if (
      precompiled &&
        identical(sass_options, sass_options(output_style = "compressed"))
    ) {
      precompiled_css <- precompiled_css_path(theme)
      if (!is.null(precompiled_css)) {
        out_dir <- file.path(tempdir(), paste0("bslib-precompiled-", version))
        if (!dir.exists(out_dir)) {
          dir.create(out_dir)
        }
        out_file <- file.path(out_dir, basename(precompiled_css))
        file.copy(precompiled_css, out_file)
        out_file <- attachDependencies(
          out_file,
          htmlDependencies(as_sass(theme))
        )
        write_file_attachments(as_sass_layer(theme)$file_attachments, out_dir)
      }
    }
    if (is.null(out_file)) {
      contrast_warn <- get_shiny_devmode_option(
        "bslib.color_contrast_warnings",
        default = FALSE,
        devmode_default = TRUE,
        devmode_message = paste(
          "Enabling warnings about low color contrasts found inside `bslib::bs_theme()`.",
          "To suppress these warnings, set `options(bslib.color_contrast_warnings = FALSE)`"
        )
      )
      theme <- bs_add_variables(
        theme,
        `color-contrast-warnings` = contrast_warn
      )
      out_file <- sass(
        input = theme,
        options = sass_options,
        output = output_template(basename = "bootstrap", dirname = "bslib-"),
        cache = cache,
        write_attachments = TRUE,
        cache_key_extra = list(
          get_exact_version(version),
          get_package_version("bslib")
        )
      )
    }
    out_file_dir <- dirname(out_file)
    js_files <- bootstrap_javascript(version)
    js_map_files <- bootstrap_javascript_map(version)
    success_js_files <- be_safe_copy_into_dir(
      c(js_files, js_map_files),
      out_file_dir,
      overwrite = TRUE
    )
    if (any(!success_js_files)) {
      warning(
        "Failed to copy over bootstrap's javascript files into the htmlDependency() directory."
      )
    }
    htmltools::resolveDependencies(
      c(
        if (inherits(jquery, "html_dependency")) list(jquery) else jquery,
        list(
          htmlDependency(
            name = "bootstrap",
            version = get_exact_version(version),
            src = out_file_dir,
            stylesheet = basename(out_file),
            script = basename(js_files),
            all_files = TRUE,
            meta = list(
              viewport = "width=device-width, initial-scale=1, shrink-to-fit=no"
            )
          )
        ),
        htmlDependencies(out_file)
      )
    )
  }

  environment(patched_bs_theme_dependencies) <- patch_env

  unlockBinding("bs_dependency", ns)
  assign("bs_dependency", patched_bs_dependency, envir = ns)
  lockBinding("bs_dependency", ns)

  unlockBinding("bs_theme_dependencies", ns)
  assign("bs_theme_dependencies", patched_bs_theme_dependencies, envir = ns)
  lockBinding("bs_theme_dependencies", ns)

  options(bachExporter.bslib_copy_patch_applied = TRUE)
  TRUE
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

be_launcher_local_library_dir <- function() {
  root <- be_launcher_local_cache_root()
  platform <- paste(
    R.version$platform,
    paste(R.version$major, R.version$minor, sep = "."),
    sep = "-"
  )
  path <- file.path(root, "bootstrap-library", platform)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

be_launcher_use_local_library <- function() {
  library_dir <- be_launcher_local_library_dir()
  .libPaths(unique(c(library_dir, .libPaths())))
  library_dir
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

be_launcher_prepare_tempdir_cleanup <- function(
  current_tempdir = be_launcher_current_tempdir()
) {
  be_make_tree_user_writable(current_tempdir)
  invisible(current_tempdir)
}

be_launcher_tempdir_ready <- function(
  current_tempdir = be_launcher_current_tempdir()
) {
  desired <- be_launcher_tmp_dir()
  identical(current_tempdir, desired) ||
    startsWith(current_tempdir, paste0(desired, "/"))
}

be_launcher_normalize_existing_file <- function(path) {
  if (
    is.null(path) || !length(path) || is.na(path[[1]]) || !nzchar(path[[1]])
  ) {
    return(NULL)
  }

  path <- as.character(path[[1]])
  if (!file.exists(path)) {
    return(NULL)
  }

  normalizePath(path, winslash = "/", mustWork = TRUE)
}

be_launcher_source_path <- function(source_frames = sys.frames()) {
  if (!length(source_frames)) {
    return(NULL)
  }

  for (frame in rev(source_frames)) {
    candidates <- character()
    if (
      is.environment(frame) && exists("ofile", envir = frame, inherits = FALSE)
    ) {
      candidates <- c(candidates, get("ofile", envir = frame, inherits = FALSE))
    }

    srcfile <- attr(frame, "srcfile", exact = TRUE)
    if (
      is.environment(frame) &&
        exists("srcfile", envir = frame, inherits = FALSE)
    ) {
      srcfile <- srcfile %||% get("srcfile", envir = frame, inherits = FALSE)
    }
    if (!is.null(srcfile)) {
      candidates <- c(
        candidates,
        srcfile$filename %||% NULL,
        attr(srcfile, "filename", exact = TRUE) %||% NULL
      )
    }

    for (candidate in candidates) {
      path <- be_launcher_normalize_existing_file(candidate)
      if (!is.null(path)) {
        return(path)
      }
    }
  }

  NULL
}

be_launcher_rstudio_document_path <- function(
  active_document_path = NULL,
  install_rstudioapi = interactive(),
  install_package_runner = utils::install.packages,
  rstudioapi_available = function() {
    requireNamespace("rstudioapi", quietly = TRUE)
  },
  rstudioapi_is_available = function() {
    rstudioapi::isAvailable()
  },
  rstudioapi_path_reader = function() {
    rstudioapi::getActiveDocumentContext()$path
  }
) {
  path <- be_launcher_normalize_existing_file(active_document_path)
  if (!is.null(path)) {
    return(path)
  }

  if (!isTRUE(rstudioapi_available())) {
    if (!isTRUE(install_rstudioapi)) {
      return(NULL)
    }
    message(
      paste(
        "Installing rstudioapi so the launcher can find the open RStudio file."
      )
    )
    install_package_runner("rstudioapi", repos = "https://cloud.r-project.org")
  }

  if (!isTRUE(rstudioapi_available()) || !isTRUE(rstudioapi_is_available())) {
    return(NULL)
  }

  path <- tryCatch(
    rstudioapi_path_reader(),
    error = function(err) NULL
  )
  be_launcher_normalize_existing_file(path)
}

be_launcher_script_path <- function(
  command_args = commandArgs(trailingOnly = FALSE),
  active_document_path = NULL,
  source_frames = sys.frames(),
  install_rstudioapi = interactive(),
  install_package_runner = utils::install.packages,
  required = TRUE
) {
  file_arg <- command_args[grepl("^--file=", command_args)]
  if (length(file_arg)) {
    path <- be_launcher_normalize_existing_file(
      sub("^--file=", "", file_arg[[1]])
    )
    if (!is.null(path)) {
      return(path)
    }
  }

  path <- be_launcher_source_path(source_frames = source_frames)
  if (!is.null(path)) {
    return(path)
  }

  path <- be_launcher_rstudio_document_path(
    active_document_path = active_document_path,
    install_rstudioapi = install_rstudioapi,
    install_package_runner = install_package_runner
  )
  if (!is.null(path)) {
    return(path)
  }

  if (isTRUE(required)) {
    stop(
      paste(
        "Could not resolve launcher script path.",
        "Run with Rscript <path>, open the launcher file in RStudio and run all lines,",
        "or call launch_bach_exporter('/path/to/shared/root')."
      ),
      call. = FALSE
    )
  }

  NULL
}

be_launcher_default_shared_root <- function(
  command_args = commandArgs(trailingOnly = FALSE),
  active_document_path = NULL,
  source_frames = sys.frames(),
  install_rstudioapi = interactive(),
  install_package_runner = utils::install.packages
) {
  script_path <- be_launcher_script_path(
    command_args = command_args,
    active_document_path = active_document_path,
    source_frames = source_frames,
    install_rstudioapi = install_rstudioapi,
    install_package_runner = install_package_runner,
    required = FALSE
  )
  if (is.null(script_path)) {
    return(NULL)
  }

  dirname(script_path)
}

be_launcher_reexec_status <- function(
  command_args = commandArgs(trailingOnly = FALSE),
  trailing_args = commandArgs(trailingOnly = TRUE),
  current_tempdir = be_launcher_current_tempdir(),
  active_document_path = NULL,
  source_frames = sys.frames(),
  install_rstudioapi = interactive(),
  install_package_runner = utils::install.packages,
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
  script_path <- be_launcher_script_path(
    command_args = command_args,
    active_document_path = active_document_path,
    source_frames = source_frames,
    install_rstudioapi = install_rstudioapi,
    install_package_runner = install_package_runner
  )
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

launch_bach_exporter <- function(shared_root = NULL) {
  be_launcher_use_tmp_dir()
  on.exit(be_launcher_prepare_tempdir_cleanup(), add = TRUE)
  bootstrap_library <- be_launcher_use_local_library()

  ensure_bootstrap_package <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(
        pkg,
        lib = bootstrap_library,
        repos = "https://cloud.r-project.org"
      )
    }
  }

  ensure_bootstrap_package("jsonlite")

  shared_root <- shared_root %||%
    be_launcher_default_shared_root() %||%
    be_launcher_load_shared_root()
  validation <- be_launcher_validate_shared_root(shared_root %||% "")

  if (!isTRUE(validation$ok)) {
    bootstrap_packages <- c(
      "shiny",
      "shinyFiles",
      "bslib"
    )
    invisible(lapply(bootstrap_packages, ensure_bootstrap_package))
    be_patch_bslib_dependency_copies()
  }

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
