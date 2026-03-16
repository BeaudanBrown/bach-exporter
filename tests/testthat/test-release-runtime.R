source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))

make_release_root <- function() {
  release_root <- tempfile("release-root-")
  dir.create(release_root, recursive = TRUE)
  release_root
}

make_packaged_shared_root <- function(release_id = "2026-03-11") {
  shared_root <- tempfile("shared-root-release-")
  release_root <- file.path(shared_root, "releases", release_id)

  dir.create(
    file.path(release_root, "R"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    file.path(release_root, "scripts"),
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

  writeLines(release_id, file.path(shared_root, "CURRENT_RELEASE.txt"))
  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(release_root, "NAMESPACE")
  )
  writeLines("{}", file.path(release_root, "renv.lock"))
  jsonlite::write_json(
    list(
      release_id = release_id,
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(release_root, "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(release_root, "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(release_root, "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(release_root, "scripts", "validate_release.R")
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

  shared_root
}

test_that("manifest validation succeeds for matching release metadata", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      release_id = "2026-03-11",
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_true(result$ok)
  expect_equal(result$package$package, "bachExporter")
  expect_equal(result$package$version, "0.0.1")
})

test_that("manifest validation rejects published releases without manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_false(result$ok)
  expect_match(result$message, "manifest is missing")
})

test_that("manifest validation allows missing dev manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
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
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      release_id = "2026-03-11",
      package = list(name = "otherPkg", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_false(result$ok)
  expect_match(result$message, "does not match DESCRIPTION package")
})

test_that("release contract validates realistic packaged release layout", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  result <- be_validate_release_contract(shared_root, allow_dev = FALSE)

  expect_true(result$ok)
  expect_equal(result$paths$release_id, "2026-03-11")
  expect_equal(result$package$package, "bachExporter")
})

test_that("release contract rejects missing required runtime files", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  unlink(
    file.path(
      shared_root,
      "releases",
      "2026-03-11",
      "NAMESPACE"
    )
  )

  result <- be_validate_release_contract(shared_root, allow_dev = FALSE)

  expect_false(result$ok)
  expect_match(result$message, "missing required files")
  expect_true(any(grepl("NAMESPACE", result$missing_paths, fixed = TRUE)))
})

test_that("validate_release script returns success for valid packaged release", {
  shared_root <- make_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  sys.source(
    file.path("..", "..", "scripts", "validate_release.R"),
    envir = environment()
  )
  result <- validate_release(shared_root = shared_root, allow_dev = FALSE)

  expect_true(result$ok)
  expect_equal(result$paths$release_id, "2026-03-11")
})

test_that("launch_from_share can smoke-test packaged release with runtime hooks", {
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
  on.exit(
    options(bachExporter.release_runtime_hooks = old_hooks),
    add = TRUE
  )

  sys.source(
    file.path(
      shared_root,
      "releases",
      "2026-03-11",
      "scripts",
      "launch_from_share.R"
    ),
    envir = environment()
  )
  launch_from_share(shared_root)

  expect_equal(calls$restore$release_id, "2026-03-11")
  expect_equal(calls$install$package_name, "bachExporter")
  expect_equal(calls$launch$package_name, "bachExporter")
  expect_equal(calls$launch$shared_root, shared_root)
})

test_that("installed release launcher errors clearly when run_app is unavailable", {
  expect_error(
    be_launch_installed_release_app("stats", "/tmp/shared-root"),
    "does not expose a usable run_app"
  )
})
