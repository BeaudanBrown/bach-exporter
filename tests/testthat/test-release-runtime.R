source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))

source_export_runtime_stack <- function() {
  for (path in c(
    "config.R",
    "source_snapshots.R",
    "normalize_redcap.R",
    "cohort_filters.R",
    "split_events.R",
    "domain_participants.R",
    "assemble_export.R",
    "export_spec.R",
    "export_validate.R",
    "targets_graph.R",
    "export_pipeline.R",
    "export_run.R"
  )) {
    source(file.path("..", "..", "R", path))
  }
}

make_release_root <- function() {
  release_root <- tempfile("release-root-")
  dir.create(release_root, recursive = TRUE)
  release_root
}

make_packaged_shared_root <- function(
  build_id = "build-20260311",
  include_export_fixture = FALSE
) {
  shared_root <- tempfile("shared-root-release-")
  app_root <- file.path(shared_root, "app")

  dir.create(file.path(app_root, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(app_root, "scripts"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    file.path(shared_root, "snapshots", "redcap"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    file.path(shared_root, "snapshots", "sidecars"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(app_root, "DESCRIPTION")
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(app_root, "NAMESPACE")
  )
  writeLines("{}", file.path(app_root, "renv.lock"))
  jsonlite::write_json(
    list(
      build_id = build_id,
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(app_root, "manifest.json"),
    auto_unbox = TRUE
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(app_root, "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(app_root, "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(app_root, "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(app_root, "scripts", "validate_release.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "refresh_snapshots.R"),
    file.path(app_root, "scripts", "refresh_snapshots.R")
  )

  utils::write.csv(
    data.frame(idno = "BACH001", redcap_event_name = "Baseline"),
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = "redcap"),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  if (isTRUE(include_export_fixture)) {
    utils::write.csv(
      data.frame(
        idno = c("BACH001", "BACH002", "BACH002"),
        redcap_event_name = c("Baseline", "Baseline", "Year 2"),
        age = c(70, 71, NA),
        sex = c("F", "M", NA),
        highest_education = c("College", "TAFE", NA),
        education = c(NA, NA, NA),
        pp_date = c("2026-01-01", "2026-01-02", "2027-01-02"),
        stringsAsFactors = FALSE
      ),
      file.path(shared_root, "snapshots", "redcap", "raw.csv"),
      row.names = FALSE
    )
  }

  shared_root
}

test_that("manifest validation succeeds for matching release metadata", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      build_id = "build-20260311",
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "build-20260311"
  )

  expect_true(result$ok)
  expect_equal(result$package$package, "bachExporter")
  expect_equal(result$package$version, "0.0.1")
})

test_that("manifest validation rejects published releases without manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(release_root, "DESCRIPTION")
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "build-20260311"
  )

  expect_false(result$ok)
  expect_match(result$message, "manifest is missing")
})

test_that("manifest validation allows missing dev manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(release_root, "DESCRIPTION")
  )

  result <- be_validate_release_manifest(release_root, release_id = "dev")

  expect_true(result$ok)
  expect_null(result$manifest)
})

test_that("manifest validation catches package mismatch", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      build_id = "build-20260311",
      package = list(name = "otherPkg", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "build-20260311"
  )

  expect_false(result$ok)
  expect_match(result$message, "does not match DESCRIPTION package")
})

test_that("release contract validates realistic packaged app layout", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  result <- be_validate_release_contract(shared_root, allow_dev = FALSE)

  expect_true(result$ok)
  expect_equal(result$paths$build_id, "build-20260311")
  expect_equal(result$package$package, "bachExporter")
})

test_that("release contract rejects missing required runtime files", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  unlink(file.path(shared_root, "app", "NAMESPACE"))

  result <- be_validate_release_contract(shared_root, allow_dev = FALSE)

  expect_false(result$ok)
  expect_match(result$message, "missing required files")
  expect_true(any(grepl("NAMESPACE", result$missing_paths, fixed = TRUE)))
})

test_that("validate_release script returns success for valid packaged app", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  sys.source(
    file.path("..", "..", "scripts", "validate_release.R"),
    envir = environment()
  )
  result <- validate_release(shared_root = shared_root, allow_dev = FALSE)

  expect_true(result$ok)
  expect_equal(result$paths$build_id, "build-20260311")
})

test_that("launch_from_share can smoke-test packaged app with runtime hooks", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  calls <- list()
  old_hooks <- getOption("bachExporter.release_runtime_hooks")
  options(
    bachExporter.release_runtime_hooks = list(
      restore_dependencies = function(...) {
        calls$restore <<- list(...)
        invisible(TRUE)
      },
      install_package = function(...) {
        calls$install <<- list(...)
        invisible(TRUE)
      },
      launch_app = function(package_name, shared_root) {
        calls$launch <<- list(
          package_name = package_name,
          shared_root = shared_root
        )
        invisible(TRUE)
      }
    )
  )
  on.exit(options(bachExporter.release_runtime_hooks = old_hooks), add = TRUE)

  sys.source(
    file.path(shared_root, "app", "scripts", "launch_from_share.R"),
    envir = environment()
  )
  launch_from_share(shared_root)

  expect_equal(calls$restore$release_id, "build-20260311")
  expect_equal(calls$install$package_name, "bachExporter")
  expect_equal(calls$launch$package_name, "bachExporter")
  expect_equal(calls$launch$shared_root, shared_root)
})

test_that("launch_from_share uses a new local library when the shared app build changes", {
  shared_root <- make_packaged_shared_root(build_id = "build-a")
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  capture_launch <- function() {
    calls <- list()
    old_hooks <- getOption("bachExporter.release_runtime_hooks")
    options(
      bachExporter.release_runtime_hooks = list(
        restore_dependencies = function(...) {
          calls$restore <<- list(...)
          invisible(TRUE)
        },
        install_package = function(...) {
          calls$install <<- list(...)
          invisible(TRUE)
        },
        launch_app = function(...) invisible(TRUE)
      )
    )
    on.exit(options(bachExporter.release_runtime_hooks = old_hooks), add = TRUE)

    sys.source(
      file.path(shared_root, "app", "scripts", "launch_from_share.R"),
      envir = environment()
    )
    launch_from_share(shared_root)
    calls
  }

  calls_a <- capture_launch()

  jsonlite::write_json(
    list(
      build_id = "build-b",
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(shared_root, "app", "manifest.json"),
    auto_unbox = TRUE
  )
  calls_b <- capture_launch()

  expect_equal(calls_a$restore$release_id, "build-a")
  expect_equal(calls_b$restore$release_id, "build-b")
  expect_false(identical(
    calls_a$restore$library_dir,
    calls_b$restore$library_dir
  ))
})

test_that("launch_from_share can run a targets-backed export from a packaged app", {
  source_export_runtime_stack()

  shared_root <- make_packaged_shared_root(include_export_fixture = TRUE)
  local_root <- tempfile("release-export-local-")
  output_dir <- tempfile("release-export-output-")
  dir.create(local_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(local_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  old_hooks <- getOption("bachExporter.release_runtime_hooks")
  old_options <- options(
    bachExporter.local_cache_dir = file.path(local_root, "cache"),
    bachExporter.local_config_dir = file.path(local_root, "config"),
    bachExporter.local_data_dir = file.path(local_root, "data")
  )
  on.exit(options(old_options), add = TRUE)

  export_result <- NULL
  options(
    bachExporter.release_runtime_hooks = list(
      restore_dependencies = function(...) invisible(TRUE),
      install_package = function(...) invisible(TRUE),
      launch_app = function(package_name, shared_root) {
        expect_equal(package_name, "bachExporter")

        spec <- be_default_export_spec(shared_root = shared_root)
        spec$output$path <- file.path(output_dir, "participants.csv")
        export_result <<- run_export(
          spec,
          refresh_mode = "auto",
          execution_mode = "targets"
        )

        invisible(TRUE)
      }
    )
  )
  on.exit(options(bachExporter.release_runtime_hooks = old_hooks), add = TRUE)

  sys.source(
    file.path(shared_root, "app", "scripts", "launch_from_share.R"),
    envir = environment()
  )
  launch_from_share(shared_root)

  expect_false(is.null(export_result))
  expect_true(file.exists(export_result$output))
  expect_true(file.exists(export_result$manifest))

  export_df <- utils::read.csv(
    export_result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  manifest <- jsonlite::read_json(export_result$manifest, simplifyVector = TRUE)

  expect_equal(sprintf("%03d", export_df$participant_id), c("001", "002"))
  expect_equal(export_df$session_date, c("2026-01-01", "2026-01-02"))
  expect_equal(export_df$age, c(70, 71))
  expect_equal(manifest$execution_mode, "targets")
  expect_equal(manifest$build_id, "build-20260311")
  expect_equal(manifest$source$mode, "snapshot")

  targets_dir <- file.path(
    be_local_targets_dir("build-20260311"),
    "export-pipeline"
  )
  expect_true(file.exists(be_targets_script_path(targets_dir)))
  expect_true(file.exists(file.path(
    be_targets_store_path(targets_dir),
    "meta",
    "meta"
  )))
})

test_that("installed release launcher errors clearly when run_app is unavailable", {
  expect_error(
    be_launch_installed_release_app("stats", "/tmp/shared-root"),
    "does not expose a usable run_app"
  )
})
