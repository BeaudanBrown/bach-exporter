source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "config.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))
source(file.path("..", "..", "R", "release_management.R"))

load_set_admin_shared_root_script <- function() {
  script_env <- new.env(parent = globalenv())
  old_wd <- setwd(file.path("..", ".."))
  on.exit(setwd(old_wd), add = TRUE)
  sys.source(
    file.path("scripts", "set_admin_shared_root.R"),
    envir = script_env
  )
  script_env
}

test_that("set_admin_shared_root_main updates admin and launcher configs", {
  config_dir <- tempfile("bach-config-")
  shared_root <- tempfile("admin-shared-root-")
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(shared_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(config_dir, recursive = TRUE), add = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  old_config_option <- getOption("bachExporter.local_config_dir")
  options(bachExporter.local_config_dir = config_dir)
  on.exit(
    options(bachExporter.local_config_dir = old_config_option),
    add = TRUE
  )

  script_env <- load_set_admin_shared_root_script()

  expect_message(
    script_env$set_admin_shared_root_main(
      args = c("--shared-root", shared_root)
    ),
    "Admin shared root saved"
  )

  admin_config <- jsonlite::read_json(
    file.path(config_dir, "admin-refresh.json"),
    simplifyVector = TRUE
  )
  shared_config <- jsonlite::read_json(
    file.path(config_dir, "shared-root.json"),
    simplifyVector = TRUE
  )
  normalized_root <- normalizePath(
    shared_root,
    winslash = "/",
    mustWork = FALSE
  )

  expect_equal(admin_config$shared_root, normalized_root)
  expect_equal(shared_config$shared_root, normalized_root)
})
