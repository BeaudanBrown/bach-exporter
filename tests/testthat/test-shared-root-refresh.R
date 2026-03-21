source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))
source(file.path("..", "..", "R", "release_management.R"))
old_wd <- setwd(file.path("..", ".."))
on.exit(setwd(old_wd), add = TRUE)
sys.source(file.path("scripts", "refresh_shared_root.R"), envir = environment())

test_that("refresh_shared_root_main stages and publishes the shared app before refresh", {
  shared_root <- tempfile("refresh-shared-root-")
  config_root <- tempfile("refresh-config-root-")
  dir.create(shared_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(config_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(config_root, recursive = TRUE), add = TRUE)

  old_options <- options(
    bachExporter.local_config_dir = file.path(config_root, "config")
  )
  on.exit(options(old_options), add = TRUE)

  refresh_args_seen <- NULL
  result <- refresh_shared_root_main(
    args = c("--shared-root", shared_root, "--build-id", "build-refresh-test"),
    refresh_runner = function(args) {
      refresh_args_seen <<- args
      list(mode = "execute", args = args)
    }
  )

  manifest <- jsonlite::read_json(
    file.path(shared_root, "app", "manifest.json"),
    simplifyVector = TRUE
  )

  expect_equal(refresh_args_seen, "--execute")
  expect_equal(result$publish$build_id, "build-refresh-test")
  expect_equal(manifest$build_id, "build-refresh-test")
  expect_true(file.exists(file.path(
    shared_root,
    "app",
    "scripts",
    "launch_from_share.R"
  )))
})

test_that("refresh_shared_root_main can initialize keyring without forcing snapshot execute", {
  shared_root <- tempfile("refresh-shared-root-")
  config_root <- tempfile("refresh-config-root-")
  dir.create(shared_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(config_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(config_root, recursive = TRUE), add = TRUE)

  old_options <- options(
    bachExporter.local_config_dir = file.path(config_root, "config")
  )
  on.exit(options(old_options), add = TRUE)

  refresh_args_seen <- NULL
  refresh_shared_root_main(
    args = c("--shared-root", shared_root, "--init-keyring", "--skip-refresh"),
    refresh_runner = function(args) {
      refresh_args_seen <<- args
      list(mode = "init-keyring", args = args)
    }
  )

  expect_equal(refresh_args_seen, "--init-keyring")
})
