app_env <- new.env(parent = globalenv())
sys.source(file.path("..", "..", "R", "paths.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "export_history.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "app_server.R"), envir = app_env)

test_that("app server uses exported shinyFiles save helper", {
  server_body <- paste(deparse(body(app_env$be_app_server())), collapse = "\n")

  expect_true(is.function(shinyFiles::shinyFileSave))
  expect_match(server_body, "shinyFiles::shinyFileSave")
  expect_false(grepl("shinyFiles::shinySaveFile", server_body, fixed = TRUE))
})

test_that("app server wraps exports in progress feedback and button busy state", {
  button_messages <- list()
  export_calls <- list()

  app_env$be_load_shared_root <- function() NULL
  app_env$be_validate_shared_root <- function(shared_root) {
    list(ok = TRUE, message = "ok")
  }
  app_env$be_save_shared_root <- function(shared_root) NULL
  app_env$be_default_presets <- function() {
    list(baseline_core = list(years = "baseline", domains = "participants"))
  }
  app_env$be_read_export_history <- function(limit = 20, history_path = NULL) {
    data.frame(
      run_id = "run-1",
      status = "success",
      started_at = "2026-03-21T07:59:59Z",
      completed_at = "2026-03-21T08:00:00Z",
      output_path = "/tmp/export.csv",
      row_count = 2L,
      domains = "participants",
      build_id = "build-1",
      error_message = NA_character_,
      log_path = "/tmp/export.log",
      manifest_path = "/tmp/export.csv.manifest.json",
      stringsAsFactors = FALSE
    )
  }
  app_env$be_default_export_spec <- function(shared_root = NULL) {
    list(
      shared = list(root = shared_root),
      cohort = list(years = "baseline", participant_ids = "", subset_file = ""),
      domains = "participants",
      options = list(cat_labels = "named"),
      output = list(path = "", format = "csv")
    )
  }
  app_env$be_set_button_busy_state <- function(
    session,
    id,
    busy,
    idle_label,
    busy_label
  ) {
    button_messages[[length(button_messages) + 1]] <<- list(
      id = id,
      busy = busy,
      idle_label = idle_label,
      busy_label = busy_label
    )
  }

  shiny::testServer(
    app_env$be_app_server(
      export_runner = function(spec, refresh_mode) {
        export_calls[[length(export_calls) + 1]] <<- list(
          spec = spec,
          refresh_mode = refresh_mode
        )
        list(output = "/tmp/export.csv")
      }
    ),
    {
      session$setInputs(
        shared_root = "/tmp/shared-root",
        years = "baseline",
        domains = "participants",
        cat_labels = "named",
        participant_ids = "",
        subset_file = "",
        output_path = "/tmp/export.csv",
        refresh_mode = "auto",
        run_export_btn = 1
      )

      expect_length(export_calls, 1)
      expect_equal(export_calls[[1]]$refresh_mode, "auto")
      expect_equal(export_calls[[1]]$spec$output$path, "/tmp/export.csv")
      expect_equal(
        vapply(button_messages, `[[`, logical(1), "busy"),
        c(TRUE, FALSE)
      )
      expect_equal(output$status_log, "Export completed: /tmp/export.csv")
      expect_match(output$history_detail, "run-1")
    }
  )
})

test_that("app server reports export failures and restores idle button state", {
  button_messages <- list()

  app_env$be_load_shared_root <- function() NULL
  app_env$be_validate_shared_root <- function(shared_root) {
    list(ok = TRUE, message = "ok")
  }
  app_env$be_save_shared_root <- function(shared_root) NULL
  app_env$be_default_presets <- function() {
    list(baseline_core = list(years = "baseline", domains = "participants"))
  }
  app_env$be_read_export_history <- function(limit = 20, history_path = NULL) {
    data.frame(
      run_id = "run-1",
      status = "failed",
      started_at = "2026-03-21T07:59:59Z",
      completed_at = "2026-03-21T08:00:00Z",
      output_path = "/tmp/export.csv",
      row_count = NA_integer_,
      domains = "participants",
      build_id = "build-1",
      error_message = "boom",
      log_path = "/tmp/export.log",
      manifest_path = "/tmp/export.csv.manifest.json",
      stringsAsFactors = FALSE
    )
  }
  app_env$be_default_export_spec <- function(shared_root = NULL) {
    list(
      shared = list(root = shared_root),
      cohort = list(years = "baseline", participant_ids = "", subset_file = ""),
      domains = "participants",
      options = list(cat_labels = "named"),
      output = list(path = "", format = "csv")
    )
  }
  app_env$be_set_button_busy_state <- function(
    session,
    id,
    busy,
    idle_label,
    busy_label
  ) {
    button_messages[[length(button_messages) + 1]] <<- list(
      id = id,
      busy = busy,
      idle_label = idle_label,
      busy_label = busy_label
    )
  }

  shiny::testServer(
    app_env$be_app_server(
      export_runner = function(spec, refresh_mode) {
        stop("boom", call. = FALSE)
      }
    ),
    {
      session$setInputs(
        shared_root = "/tmp/shared-root",
        years = "baseline",
        domains = "participants",
        cat_labels = "named",
        participant_ids = "",
        subset_file = "",
        output_path = "/tmp/export.csv",
        refresh_mode = "auto",
        run_export_btn = 1
      )

      expect_equal(
        vapply(button_messages, `[[`, logical(1), "busy"),
        c(TRUE, FALSE)
      )
      expect_equal(output$status_log, "Export failed: boom")
      expect_match(output$history_detail, "boom")
    }
  )
})
