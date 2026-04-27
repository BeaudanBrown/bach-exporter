be_set_button_busy_state <- function(
  session,
  id,
  busy,
  idle_label,
  busy_label
) {
  session$sendCustomMessage(
    "be-set-button-state",
    list(
      id = id,
      disabled = isTRUE(busy),
      label = if (isTRUE(busy)) busy_label else idle_label
    )
  )
}

be_update_domain_selection <- function(session, selected) {
  shiny::updateCheckboxGroupInput(
    session,
    "domains",
    selected = selected
  )
}

be_update_output_path <- function(session, value) {
  shiny::updateTextInput(session, "output_path", value = value)
}

be_send_live_log_line <- function(session, line, id = "live_log") {
  session$sendCustomMessage(
    "be-append-log-line",
    list(id = id, line = line)
  )
  flush_react <- tryCatch(
    get("flushReact", envir = asNamespace("shiny")),
    error = function(err) NULL
  )
  if (is.function(flush_react)) {
    tryCatch(flush_react(), error = function(err) NULL)
  }
  invisible(line)
}

be_export_runner_accepts_log_callback <- function(export_runner) {
  runner_args <- names(formals(export_runner))
  "..." %in% runner_args || "log_callback" %in% runner_args
}

be_call_export_runner <- function(
  export_runner,
  spec,
  refresh_mode,
  parallel_workers = 1L,
  log_callback = NULL
) {
  args <- list(
    spec = spec,
    refresh_mode = refresh_mode
  )
  runner_args <- names(formals(export_runner))
  if ("..." %in% runner_args || "parallel_workers" %in% runner_args) {
    args$parallel_workers <- parallel_workers
  }
  if (
    is.function(log_callback) &&
      isTRUE(be_export_runner_accepts_log_callback(export_runner))
  ) {
    args$log_callback <- log_callback
  }

  do.call(export_runner, args)
}

be_resolve_output_save_path <- function(selected) {
  if (is.null(selected) || !nrow(selected)) {
    return(NULL)
  }

  name <- if ("name" %in% names(selected)) selected$name[[1]] else ""
  datapath <- if ("datapath" %in% names(selected)) {
    selected$datapath[[1]]
  } else {
    ""
  }
  path <- if ("path" %in% names(selected)) selected$path[[1]] else ""

  if (nzchar(datapath)) {
    if (nzchar(name) && identical(basename(datapath), name)) {
      return(datapath)
    }
    if (!nzchar(name)) {
      return(datapath)
    }
    return(file.path(datapath, name))
  }

  if (nzchar(path) && nzchar(name)) {
    return(file.path(path, name))
  }

  if (nzchar(path)) {
    return(path)
  }

  NULL
}

be_app_server <- function(
  shared_root = NULL,
  export_runner = run_export,
  notification_runner = shiny::showNotification
) {
  function(input, output, session) {
    roots <- be_shiny_roots()
    shinyFiles::shinyFileSave(
      input,
      "browse_output",
      roots = roots,
      session = session,
      filetypes = c("csv")
    )

    status_log <- shiny::reactiveVal("App started.")
    live_log <- shiny::reactiveVal("App started.")
    export_busy <- shiny::reactiveVal(FALSE)
    export_busy_message <- shiny::reactiveVal(NULL)
    export_error_message <- shiny::reactiveVal(NULL)

    resolved_shared_root <- shared_root %||% be_load_shared_root() %||% ""
    be_update_output_path(session, be_default_output_path())

    shiny::observeEvent(input$browse_output, {
      selected <- shinyFiles::parseSavePath(roots, input$browse_output)
      output_path <- be_resolve_output_save_path(selected)
      if (!is.null(output_path) && nzchar(output_path)) {
        be_update_output_path(session, output_path)
      }
    })

    shiny::observeEvent(input$select_all_domains_btn, {
      be_update_domain_selection(session, unname(be_domain_choices()))
    })

    shiny::observeEvent(input$run_export_btn, {
      if (isTRUE(export_busy())) {
        status_log("Export request ignored: an export is already running.")
        return()
      }

      spec <- be_default_export_spec(shared_root = resolved_shared_root)
      spec$cohort$years <- input$years
      spec$cohort$participant_ids <- input$participant_ids
      spec$domains <- input$domains
      spec$options$cat_labels <- input$cat_labels
      spec$output$path <- input$output_path
      parallel_workers <- suppressWarnings(as.integer(input$parallel_workers))
      if (length(parallel_workers) != 1L || is.na(parallel_workers)) {
        parallel_workers <- 1L
      }

      export_busy(TRUE)
      live_log("Export started.")
      be_send_live_log_line(session, "Export started.")
      export_busy_message(
        "Export in progress. Keep this window open until the result appears."
      )
      export_error_message(NULL)
      status_log(
        "Export started. Preparing shared snapshots and export output."
      )
      append_live_log <- function(line) {
        lines <- c(strsplit(live_log(), "\n", fixed = TRUE)[[1]], line)
        live_log(paste(tail(lines, 300), collapse = "\n"))
        be_send_live_log_line(session, line)
        invisible(line)
      }
      log_callback <- function(entry, log_path) {
        append_live_log(be_format_export_log_entry(entry))
      }
      be_set_button_busy_state(
        session = session,
        id = "run_export_btn",
        busy = TRUE,
        idle_label = "Run export",
        busy_label = "Export running..."
      )
      on.exit(
        {
          export_busy(FALSE)
          export_busy_message(NULL)
          be_set_button_busy_state(
            session = session,
            id = "run_export_btn",
            busy = FALSE,
            idle_label = "Run export",
            busy_label = "Export running..."
          )
        },
        add = TRUE
      )

      result <- tryCatch(
        {
          shiny::withProgress(
            message = "Running export",
            detail = "Preparing export inputs.",
            value = 0,
            {
              shiny::incProgress(
                0.2,
                detail = "Reading snapshots and assembling the export."
              )
              result <- be_call_export_runner(
                export_runner = export_runner,
                spec = spec,
                refresh_mode = input$refresh_mode,
                parallel_workers = parallel_workers,
                log_callback = log_callback
              )
              shiny::incProgress(
                0.8,
                detail = "Finalizing files and manifest."
              )
              result
            }
          )
        },
        error = function(err) err
      )

      if (inherits(result, "error")) {
        error_message <- conditionMessage(result)
        export_error_message(error_message)
        status_log(sprintf("Export failed: %s", error_message))
        append_live_log(sprintf("Export failed: %s", error_message))
        notification_runner(
          ui = paste("Export failed:", error_message),
          type = "error",
          duration = 10
        )
      } else {
        export_error_message(NULL)
        status_log(sprintf("Export completed: %s", result$output))
        if (!is.null(result$log) && file.exists(result$log)) {
          live_log(paste(be_read_export_log(result$log), collapse = "\n"))
        } else {
          append_live_log(sprintf("Export completed: %s", result$output))
        }
      }
    })

    output$export_busy_banner <- shiny::renderUI({
      if (!isTRUE(export_busy())) {
        return(NULL)
      }
      shiny::div(
        class = "busy-banner",
        shiny::span(class = "busy-banner__spinner"),
        shiny::span(export_busy_message())
      )
    })

    output$export_error_banner <- shiny::renderUI({
      message <- export_error_message()
      if (is.null(message) || !nzchar(message)) {
        return(NULL)
      }

      shiny::div(
        class = "error-banner",
        shiny::strong("Export failed."),
        shiny::span(message)
      )
    })

    output$status_log <- shiny::renderText({
      status_log()
    })

    output$live_log <- shiny::renderText({
      live_log()
    })
  }
}
