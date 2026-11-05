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

  exclusions_source <- file.path(config_root, "exclusions.json")
  writeLines('{"rules":[]}', exclusions_source)
  be_set_admin_exclusions_source(exclusions_source)
  refresh_args_seen <- NULL
  result <- refresh_shared_root_main(
    args = c("--shared-root", shared_root, "--build-id", "build-refresh-test"),
    refresh_runner = function(args) {
      refresh_args_seen <<- args
      expect_true(file.exists(file.path(
        shared_root,
        "config",
        "exclusions.json"
      )))
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

test_that("refresh uses the effective alternate config for publishing and subsequent refresh", {
  root <- tempfile("alternate-refresh-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  config_path <- file.path(root, "alternate.json")
  exclusions_source <- file.path(root, "source.json")
  writeLines('{"rules":[]}', exclusions_source)
  jsonlite::write_json(
    list(shared_root = file.path(root, "old-share")),
    config_path,
    auto_unbox = TRUE
  )
  be_set_admin_exclusions_source(exclusions_source, config_path)
  previous <- Sys.getenv("BACH_EXPORTER_ADMIN_CONFIG", unset = NA_character_)
  on.exit(
    {
      if (is.na(previous)) {
        Sys.unsetenv("BACH_EXPORTER_ADMIN_CONFIG")
      } else {
        Sys.setenv(BACH_EXPORTER_ADMIN_CONFIG = previous)
      }
    },
    add = TRUE
  )
  Sys.setenv(BACH_EXPORTER_ADMIN_CONFIG = config_path)
  options_before <- options(
    bachExporter.local_config_dir = file.path(root, "default-config")
  )
  on.exit(options(options_before), add = TRUE)
  new_share <- file.path(root, "new-share")
  refresh_shared_root_main(
    c("--shared-root", new_share, "--skip-refresh"),
    refresh_runner = function(args) {
      effective <- be_admin_refresh_config()
      expect_equal(
        effective$shared_root,
        normalizePath(new_share, winslash = "/")
      )
      expect_equal(
        effective$exclusions_source,
        normalizePath(exclusions_source, winslash = "/")
      )
      expect_true(file.exists(file.path(
        effective$shared_root,
        "config",
        "exclusions.json"
      )))
      invisible(NULL)
    }
  )
  expect_false(file.exists(be_admin_refresh_config_path()))
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

  exclusions_source <- file.path(config_root, "exclusions.json")
  writeLines('{"rules":[]}', exclusions_source)
  be_set_admin_exclusions_source(exclusions_source)
  refresh_args_seen <- NULL
  refresh_shared_root_main(
    args = c("--shared-root", shared_root, "--init-keyring", "--skip-refresh"),
    refresh_runner = function(args) {
      refresh_args_seen <<- args
      list(mode = "init-keyring", args = args)
    }
  )

  expect_equal(refresh_args_seen, "--init-keyring")
  expect_true(file.exists(file.path(shared_root, "config", "exclusions.json")))
})
