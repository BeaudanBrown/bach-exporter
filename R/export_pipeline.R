be_export_manifest_source <- function(source) {
  source_check <- be_researcher_source_spec(source)
  if (!isTRUE(source_check$ok)) {
    return(list(mode = "snapshot"))
  }

  source_check$source
}

be_build_export_manifest <- function(
  spec,
  shared_root,
  refresh_mode = "auto",
  snapshot_metadata = NULL,
  execution_mode = "targets"
) {
  if (is.null(snapshot_metadata)) {
    snapshot_metadata <- be_collect_snapshot_metadata(shared_root)
  }

  shared_paths <- be_shared_paths(shared_root)
  shared_manifest <- be_read_shared_manifest(shared_root)
  app_version <- tryCatch(
    as.character(utils::packageVersion("bachExporter")),
    error = function(err) "0.0.1"
  )

  list(
    exported_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    refresh_mode = refresh_mode,
    execution_mode = execution_mode,
    shared_root = spec$shared$root,
    build_id = shared_paths$build_id,
    snapshot_metadata = snapshot_metadata,
    app = list(
      package = "bachExporter",
      version = app_version,
      shared_manifest = shared_manifest
    ),
    platform = list(
      r_version = R.version.string,
      platform = R.version$platform
    ),
    source = be_export_manifest_source(spec$source),
    cohort = spec$cohort,
    domains = spec$domains,
    options = spec$options,
    output = spec$output
  )
}

be_targets_script_path <- function(targets_dir) {
  file.path(targets_dir, "_targets_export.R")
}

be_targets_store_path <- function(targets_dir) {
  file.path(targets_dir, "store")
}

be_export_targets_parent_environment <- function() {
  function_environment <- environment(be_export_targets_parent_environment)
  if (
    isNamespace(function_environment) &&
      !identical(Sys.getenv("TESTTHAT"), "true")
  ) {
    return(function_environment)
  }

  globalenv()
}

be_resolve_export_project_root <- function(project_root = getwd()) {
  candidates <- c(
    project_root,
    file.path(project_root, ".."),
    file.path(project_root, "..", "..")
  )
  candidates <- normalizePath(
    candidates,
    winslash = "/",
    mustWork = FALSE
  )
  matches <- candidates[dir.exists(file.path(candidates, "R"))]
  if (length(matches)) {
    return(matches[[1]])
  }

  normalizePath(project_root, winslash = "/", mustWork = TRUE)
}

be_default_export_parallel_workers <- function() {
  configured <- Sys.getenv("BACH_EXPORTER_PARALLEL_WORKERS", unset = "")
  if (!nzchar(configured)) {
    configured <- getOption("bachExporter.parallel_workers", NULL)
  }

  if (!is.null(configured)) {
    workers <- suppressWarnings(as.integer(configured[[1]]))
    if (length(workers) == 1L && !is.na(workers)) {
      return(max(1L, workers))
    }
  }

  cores <- tryCatch(
    parallel::detectCores(logical = TRUE),
    error = function(err) NA_integer_
  )
  if (is.na(cores) || cores <= 1L) {
    return(1L)
  }

  min(4L, max(1L, as.integer(cores) - 1L))
}

be_normalize_export_parallel_workers <- function(workers = NULL) {
  workers <- workers %||% be_default_export_parallel_workers()

  if (length(workers) != 1L || is.na(workers)) {
    return(1L)
  }

  max(1L, as.integer(workers))
}

be_export_pipeline_uses_crew <- function(parallel_workers) {
  parallel_workers <- be_normalize_export_parallel_workers(parallel_workers)
  parallel_workers > 1L &&
    requireNamespace("crew", quietly = TRUE) &&
    requireNamespace("bachExporter", quietly = TRUE)
}

be_resolve_export_pipeline_project_root <- function(project_root, shared_root) {
  resolved_project_root <- be_resolve_export_project_root(project_root)
  if (dir.exists(file.path(resolved_project_root, "R"))) {
    return(resolved_project_root)
  }

  shared_app_root <- be_shared_runtime_root(shared_root)
  if (
    !is.null(shared_app_root) && dir.exists(file.path(shared_app_root, "R"))
  ) {
    return(normalizePath(shared_app_root, winslash = "/", mustWork = TRUE))
  }

  resolved_project_root
}

be_run_targets_make_with_log <- function(tar_make_args, log_path = NULL) {
  if (isTRUE(tar_make_args$use_crew)) {
    old_r_libs <- Sys.getenv("R_LIBS", unset = NA_character_)
    Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
    on.exit(
      {
        if (is.na(old_r_libs)) {
          Sys.unsetenv("R_LIBS")
        } else {
          Sys.setenv(R_LIBS = old_r_libs)
        }
      },
      add = TRUE
    )
    return(do.call(targets::tar_make, tar_make_args))
  }

  if (is.null(log_path) || !nzchar(log_path)) {
    return(do.call(targets::tar_make, tar_make_args))
  }

  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
  con <- file(log_path, open = "at")
  output_sunk <- FALSE
  message_sunk <- FALSE
  on.exit(
    {
      if (isTRUE(message_sunk)) {
        sink(type = "message")
      }
      if (isTRUE(output_sunk)) {
        sink(type = "output")
      }
      close(con)
    },
    add = TRUE
  )

  sink(con, append = TRUE, split = TRUE)
  output_sunk <- TRUE
  sink(con, type = "message")
  message_sunk <- TRUE

  do.call(targets::tar_make, tar_make_args)
}

be_write_export_targets_script <- function(
  script_path,
  spec,
  shared_root,
  refresh_mode = "auto",
  project_root = getwd(),
  parallel_workers = be_default_export_parallel_workers(),
  prefer_package = isNamespace(be_export_targets_parent_environment()),
  prefer_project_sources = !identical(Sys.getenv("TESTTHAT"), "true")
) {
  quote_r_string <- function(value) {
    encodeString(as.character(value), quote = "\"")
  }

  parallel_workers <- be_normalize_export_parallel_workers(parallel_workers)
  use_crew <- be_export_pipeline_uses_crew(parallel_workers)
  resolved_project_root <- normalizePath(
    project_root,
    winslash = "/",
    mustWork = TRUE
  )
  source_project <- isTRUE(prefer_project_sources) &&
    dir.exists(file.path(resolved_project_root, "R"))
  use_package_imports <- isTRUE(prefer_package) && !isTRUE(source_project)
  spec_lines <- capture.output(dput(spec))
  tar_option_lines <- c("target_packages <- c('jsonlite')")
  if (isTRUE(use_package_imports)) {
    tar_option_lines <- c(
      tar_option_lines,
      "target_imports <- character()",
      "if (requireNamespace('bachExporter', quietly = TRUE)) {",
      "  target_packages <- c(target_packages, 'bachExporter')",
      "  target_imports <- c(target_imports, 'bachExporter')",
      "}"
    )
  } else {
    tar_option_lines <- c(tar_option_lines, "target_imports <- character()")
  }
  tar_option_lines <- c(
    tar_option_lines,
    "targets::tar_option_set(",
    "  packages = target_packages,",
    "  imports = target_imports,",
    "  format = 'qs',",
    "  seed = 20260311"
  )
  if (isTRUE(use_crew)) {
    crew_log_dir <- file.path(dirname(script_path), "crew-logs")
    dir.create(crew_log_dir, recursive = TRUE, showWarnings = FALSE)
    tar_option_lines <- c(
      tar_option_lines,
      sprintf(
        paste(
          "  ,controller = crew::crew_controller_local(",
          paste(
            "workers = %dL, seconds_timeout = 120, crashes_max = 5L,",
            "options_local = crew::crew_options_local(",
            "log_directory = %s, log_join = TRUE)"
          ),
          ")"
        ),
        parallel_workers,
        quote_r_string(crew_log_dir)
      )
    )
  }
  tar_option_lines <- c(tar_option_lines, ")")

  graph_loader_lines <- if (isTRUE(source_project)) {
    c(
      "if (dir.exists(file.path(project_root, 'R'))) {",
      "  for (path in sort(Sys.glob(file.path(project_root, 'R', '*.R')))) {",
      "    source(path, local = TRUE)",
      "  }",
      "  if (!exists('be_target_graph', mode = 'function', inherits = TRUE)) {",
      "    stop('Project R sources did not define be_target_graph.', call. = FALSE)",
      "  }",
      "  be_target_graph <- get('be_target_graph', inherits = TRUE)"
    )
  } else if (isTRUE(prefer_package)) {
    c(
      "if (requireNamespace('bachExporter', quietly = TRUE)) {",
      "  be_target_graph <- get('be_target_graph', envir = asNamespace('bachExporter'))",
      "} else if (exists('be_target_graph', mode = 'function', inherits = TRUE)) {",
      "  be_target_graph <- get('be_target_graph', inherits = TRUE)"
    )
  } else {
    c(
      "if (exists('be_target_graph', mode = 'function', inherits = TRUE)) {",
      "  be_target_graph <- get('be_target_graph', inherits = TRUE)",
      "} else if (requireNamespace('bachExporter', quietly = TRUE)) {",
      "  be_target_graph <- get('be_target_graph', envir = asNamespace('bachExporter'))"
    )
  }

  script_lines <- c(
    "library(targets)",
    tar_option_lines,
    sprintf("project_root <- %s", quote_r_string(resolved_project_root)),
    graph_loader_lines,
    "} else if (dir.exists(file.path(project_root, 'R'))) {",
    "  for (path in sort(Sys.glob(file.path(project_root, 'R', '*.R')))) {",
    "    source(path, local = TRUE)",
    "  }",
    "} else {",
    "  stop('Cannot find bachExporter package or project R sources.', call. = FALSE)",
    "}",
    "spec <-"
  )
  script_lines <- c(script_lines, spec_lines)
  script_lines <- c(
    script_lines,
    sprintf("shared_root <- %s", quote_r_string(shared_root)),
    sprintf("refresh_mode <- %s", quote_r_string(refresh_mode)),
    "be_target_graph(",
    "  spec = spec,",
    "  shared_root = shared_root,",
    "  refresh_mode = refresh_mode",
    ")"
  )

  writeLines(script_lines, con = script_path)
  invisible(script_path)
}

be_run_export_pipeline <- function(
  spec,
  shared_root,
  refresh_mode = "auto",
  build_id = "dev",
  project_root = getwd(),
  parallel_workers = be_default_export_parallel_workers(),
  log_path = NULL,
  log_callback = NULL
) {
  project_root <- be_resolve_export_pipeline_project_root(
    project_root = project_root,
    shared_root = shared_root
  )
  build_id <- build_id %||% "dev"
  parallel_workers <- be_normalize_export_parallel_workers(parallel_workers)
  use_crew <- be_export_pipeline_uses_crew(parallel_workers)
  targets_dir <- file.path(
    be_local_targets_dir(build_id, shared_root = shared_root),
    "export-pipeline"
  )
  dir.create(targets_dir, recursive = TRUE, showWarnings = FALSE)

  script_path <- be_targets_script_path(targets_dir)
  store_path <- be_targets_store_path(targets_dir)

  be_write_export_targets_script(
    script_path = script_path,
    spec = spec,
    shared_root = shared_root,
    refresh_mode = refresh_mode,
    project_root = project_root,
    parallel_workers = parallel_workers
  )

  tar_make_args <- list(
    names = be_export_pipeline_target_names(spec),
    script = script_path,
    store = store_path,
    callr_function = NULL,
    reporter = "timestamp",
    envir = new.env(parent = be_export_targets_parent_environment())
  )

  if (!is.null(log_path) && nzchar(log_path)) {
    be_append_export_log(
      log_path,
      "Targets pipeline prepared.",
      data = list(
        targets_dir = targets_dir,
        store = store_path,
        script = script_path,
        targets = tar_make_args$names,
        parallel_workers = parallel_workers,
        use_crew = use_crew
      ),
      log_callback = log_callback
    )
    be_append_export_log(
      log_path,
      if (isTRUE(use_crew)) {
        "Running targets pipeline with crew."
      } else {
        "Running targets pipeline in serial mode."
      },
      data = list(
        parallel_workers = parallel_workers,
        crew_available = requireNamespace("crew", quietly = TRUE),
        package_available = requireNamespace("bachExporter", quietly = TRUE)
      ),
      log_callback = log_callback
    )
  }

  if (isTRUE(use_crew)) {
    tar_make_args$use_crew <- TRUE
    parallel_result <- tryCatch(
      be_run_targets_make_with_log(tar_make_args, log_path = log_path),
      error = function(err) err
    )
    if (inherits(parallel_result, "error")) {
      if (!is.null(log_path) && nzchar(log_path)) {
        be_append_export_log(
          log_path,
          "Parallel targets export failed. Retrying in serial mode.",
          level = "WARN",
          data = list(
            parallel_workers = parallel_workers,
            error = conditionMessage(parallel_result)
          ),
          log_callback = log_callback
        )
      }
      warning(
        sprintf(
          paste(
            "Parallel targets export failed with %d crew workers.",
            "Retrying in serial mode. Original error: %s"
          ),
          parallel_workers,
          conditionMessage(parallel_result)
        ),
        call. = FALSE
      )
      tar_make_args$use_crew <- FALSE
      tar_make_args$callr_function <- NULL
      be_run_targets_make_with_log(tar_make_args, log_path = log_path)
    }
  } else {
    tar_make_args$use_crew <- FALSE
    be_run_targets_make_with_log(tar_make_args, log_path = log_path)
  }

  if (!is.null(log_path) && nzchar(log_path)) {
    be_append_export_log(
      log_path,
      "Targets pipeline complete.",
      data = list(
        targets_dir = targets_dir,
        store = store_path
      ),
      log_callback = log_callback
    )
  }

  list(
    export_df = targets::tar_read(
      export_data,
      store = store_path
    ),
    manifest = targets::tar_read(
      export_manifest,
      store = store_path
    )
  )
}
