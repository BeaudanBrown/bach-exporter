app_env <- new.env(parent = globalenv())
sys.source(file.path("..", "..", "R", "paths.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "domain_choices.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "export_spec.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "export_history.R"), envir = app_env)
sys.source(file.path("..", "..", "R", "app_server.R"), envir = app_env)

test_that("app server uses exported shinyFiles save helper", {
  server_body <- paste(deparse(body(app_env$be_app_server())), collapse = "\n")

  expect_true(is.function(shinyFiles::shinyFileSave))
  expect_match(server_body, "shinyFiles::shinyFileSave")
  expect_false(grepl("shinyFiles::shinySaveFile", server_body, fixed = TRUE))
})

test_that("app server save-path resolver avoids duplicating the filename", {
  expect_equal(
    app_env$be_resolve_output_save_path(
      data.frame(
        datapath = "/home/beau/test.csv",
        name = "test.csv",
        stringsAsFactors = FALSE
      )
    ),
    "/home/beau/test.csv"
  )

  expect_equal(
    app_env$be_resolve_output_save_path(
      data.frame(
        path = "/home/beau",
        name = "test.csv",
        stringsAsFactors = FALSE
      )
    ),
    "/home/beau/test.csv"
  )
})

test_that("default output path points to output.csv in the launch directory", {
  expect_equal(
    app_env$be_default_output_path("/home/beau/monash/bach-exporter"),
    "/home/beau/monash/bach-exporter/output.csv"
  )
})

test_that("app server wraps exports in progress feedback and button busy state", {
  button_messages <- list()
  export_calls <- list()
  notifications <- list()

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
      notification_runner = function(ui, type = "default", duration = 5, ...) {
        notifications[[length(notifications) + 1]] <<- list(
          ui = ui,
          type = type,
          duration = duration
        )
        NULL
      },
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
      expect_length(notifications, 0)
      expect_equal(output$status_log, "Export completed: /tmp/export.csv")
      expect_match(output$history_detail, "run-1")
      expect_null(output$export_error_banner)
    }
  )
})

test_that("app server initializes the output path with the default launch path", {
  output_updates <- list()

  app_env$be_load_shared_root <- function() NULL
  app_env$be_validate_shared_root <- function(shared_root) {
    list(ok = TRUE, message = "ok")
  }
  app_env$be_save_shared_root <- function(shared_root) NULL
  app_env$be_default_presets <- function() {
    list(baseline_core = list(years = "baseline", domains = "participants"))
  }
  app_env$be_read_export_history <- function(limit = 20, history_path = NULL) {
    data.frame()
  }
  app_env$be_update_output_path <- function(session, value) {
    output_updates[[length(output_updates) + 1]] <<- value
  }

  shiny::testServer(
    app_env$be_app_server(
      notification_runner = function(...) NULL,
      export_runner = function(spec, refresh_mode) {
        list(output = "/tmp/export.csv")
      }
    ),
    {
      expect_true(length(output_updates) >= 1)
      expect_equal(
        output_updates[[1]],
        app_env$be_default_output_path()
      )
    }
  )
})

test_that("app server select-all control selects every domain", {
  update_calls <- list()

  app_env$be_load_shared_root <- function() NULL
  app_env$be_validate_shared_root <- function(shared_root) {
    list(ok = TRUE, message = "ok")
  }
  app_env$be_save_shared_root <- function(shared_root) NULL
  app_env$be_default_presets <- function() {
    list(baseline_core = list(years = "baseline", domains = "participants"))
  }
  app_env$be_read_export_history <- function(limit = 20, history_path = NULL) {
    data.frame()
  }
  app_env$be_update_domain_selection <- function(session, selected) {
    update_calls[[length(update_calls) + 1]] <<- list(
      selected = selected
    )
  }

  shiny::testServer(
    app_env$be_app_server(
      notification_runner = function(...) NULL,
      export_runner = function(spec, refresh_mode) {
        list(output = "/tmp/export.csv")
      }
    ),
    {
      session$setInputs(select_all_domains_btn = 1)

      expect_length(update_calls, 1)
      expect_setequal(
        update_calls[[1]]$selected,
        unname(app_env$be_domain_choices())
      )
    }
  )
})

test_that("app server reports export failures and restores idle button state", {
  button_messages <- list()
  notifications <- list()

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
      notification_runner = function(ui, type = "default", duration = 5, ...) {
        notifications[[length(notifications) + 1]] <<- list(
          ui = ui,
          type = type,
          duration = duration
        )
        NULL
      },
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
      expect_length(notifications, 1)
      expect_equal(notifications[[1]]$type, "error")
      expect_true(is.null(notifications[[1]]$duration))
      expect_match(notifications[[1]]$ui, "Export failed: boom")
      expect_equal(output$status_log, "Export failed: boom")
      error_banner <- paste(
        as.character(output$export_error_banner),
        collapse = "\n"
      )
      expect_match(error_banner, "Export failed")
      expect_match(error_banner, "boom")
      expect_match(output$history_detail, "boom")
    }
  )
})
