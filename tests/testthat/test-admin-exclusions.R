source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))

write_synthetic_exclusions <- function(path, id = "example-rule") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  rules <- if (is.null(id)) {
    list()
  } else {
    list(list(
      id = id,
      participant_id = "123",
      source = "redcap",
      columns = list("synthetic_score"),
      reason = "Synthetic fixture"
    ))
  }
  jsonlite::write_json(list(rules = rules), path, auto_unbox = TRUE)
}

test_that("exclusion source registration validates and preserves admin settings", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  path <- file.path(root, "source.json")
  config_path <- file.path(root, "admin.json")
  write_synthetic_exclusions(path)
  jsonlite::write_json(
    list(shared_root = "existing-root", project_alias = "example"),
    config_path,
    auto_unbox = TRUE
  )
  be_set_admin_exclusions_source(path, config_path)
  config <- be_admin_refresh_config(config_path)
  expect_equal(config$shared_root, "existing-root")
  expect_equal(config$exclusions_source, normalizePath(path, winslash = "/"))
  stored <- readLines(config_path)
  writeLines("broken", path)
  expect_error(
    be_set_admin_exclusions_source(path, config_path),
    "Invalid exclusions"
  )
  expect_equal(readLines(config_path), stored)
  expect_error(
    be_set_admin_exclusions_source(file.path(root, "missing"), config_path),
    "does not exist"
  )
})

test_that("sync installs updates and clears only through a valid explicit source", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  path <- file.path(root, "source.json")
  config <- list(
    shared_root = file.path(root, "share"),
    exclusions_source = path
  )
  destination <- file.path(config$shared_root, "config", "exclusions.json")
  write_synthetic_exclusions(path)
  be_sync_admin_exclusions(config)
  expect_equal(readLines(destination), readLines(path))
  write_synthetic_exclusions(path, "replacement")
  be_sync_admin_exclusions(config)
  expect_equal(be_read_exclusions(config$shared_root)[[1]]$id, "replacement")
  previous <- readLines(destination)
  be_sync_admin_exclusions(list(shared_root = config$shared_root))
  expect_equal(readLines(destination), previous)
  writeLines('{"rules":[{}]}', path)
  expect_error(be_sync_admin_exclusions(config), "Invalid exclusions")
  expect_equal(readLines(destination), previous)
  unlink(path)
  expect_error(be_sync_admin_exclusions(config), "does not exist")
  expect_equal(readLines(destination), previous)
  write_synthetic_exclusions(path, NULL)
  be_sync_admin_exclusions(config)
  expect_length(be_read_exclusions(config$shared_root), 0L)
  config$exclusions_source <- destination
  expect_no_error(be_sync_admin_exclusions(config))
  expect_length(be_read_exclusions(config$shared_root), 0L)
})

test_that("data refresh syncs before API execution but dry run and keyring do not sync", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  old_wd <- setwd(file.path("..", ".."))
  on.exit(setwd(old_wd), add = TRUE)
  env <- new.env(parent = environment())
  sys.source("scripts/refresh_snapshots.R", envir = env)
  path <- file.path(root, "source.json")
  config <- list(
    shared_root = file.path(root, "share"),
    exclusions_source = path,
    package = "redcapAPI",
    config_path = file.path(root, "admin.json")
  )
  destination <- file.path(config$shared_root, "config", "exclusions.json")
  calls <- 0L
  runtime <- list(
    load_dotenv = function() FALSE,
    read_config = function() config,
    validate_config = function(config) list(ok = TRUE),
    build_plan = be_admin_refresh_plan,
    package_available = function(package) TRUE,
    init_keyring = function(config) invisible(NULL),
    execute_refresh = function(config) {
      calls <<- calls + 1L
      expect_equal(readLines(destination), readLines(path))
      stop("mock refresh reached")
    },
    inform = function(...) invisible(NULL)
  )
  expect_no_error(env$refresh_snapshots_main(character(), runtime))
  expect_no_error(env$refresh_snapshots_main("--init-keyring", runtime))
  expect_false(file.exists(destination))
  expect_error(
    env$refresh_snapshots_main("--execute", runtime),
    "does not exist"
  )
  expect_equal(calls, 0L)
  write_synthetic_exclusions(path)
  expect_error(
    env$refresh_snapshots_main("--execute", runtime),
    "mock refresh reached"
  )
  expect_equal(calls, 1L)
})
