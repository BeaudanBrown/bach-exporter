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
    shinyFiles::shinyDirChoose(
      input,
      "browse_shared_root",
      roots = roots,
      session = session
    )
    shinyFiles::shinyFileSave(
      input,
      "browse_output",
      roots = roots,
      session = session,
      filetypes = c("csv")
    )

    status_log <- shiny::reactiveVal("App started.")
    export_busy <- shiny::reactiveVal(FALSE)
    export_busy_message <- shiny::reactiveVal(NULL)
    export_error_message <- shiny::reactiveVal(NULL)
    history_nonce <- shiny::reactiveVal(0)

    initial_shared_root <- shared_root %||% be_load_shared_root() %||% ""
    shiny::updateTextInput(session, "shared_root", value = initial_shared_root)

    shiny::observeEvent(input$browse_shared_root, {
      selected <- shinyFiles::parseDirPath(roots, input$browse_shared_root)
      if (length(selected) == 1 && nzchar(selected)) {
        shiny::updateTextInput(session, "shared_root", value = selected)
      }
    })

    shiny::observeEvent(input$browse_output, {
      selected <- shinyFiles::parseSavePath(roots, input$browse_output)
      output_path <- be_resolve_output_save_path(selected)
      if (!is.null(output_path) && nzchar(output_path)) {
        shiny::updateTextInput(
          session,
          "output_path",
          value = output_path
        )
      }
    })

    shiny::observeEvent(input$save_shared_root, {
      validation <- be_validate_shared_root(input$shared_root)
      if (!isTRUE(validation$ok)) {
        status_log(sprintf("Shared root not saved: %s", validation$message))
        return()
      }
      be_save_shared_root(input$shared_root)
      status_log(sprintf("Shared root saved: %s", input$shared_root))
      history_nonce(history_nonce() + 1)
    })

    shiny::observeEvent(
      input$preset,
      {
        preset <- be_default_presets()[[input$preset]]
        if (is.null(preset)) {
          return()
        }
        shiny::updateSelectInput(session, "years", selected = preset$years)
        be_update_domain_selection(session, preset$domains)
      },
      ignoreInit = TRUE
    )

    shiny::observeEvent(input$select_all_domains_btn, {
      be_update_domain_selection(session, unname(be_domain_choices()))
    })

    shiny::observeEvent(input$run_export_btn, {
      if (isTRUE(export_busy())) {
        status_log("Export request ignored: an export is already running.")
        return()
      }

      spec <- be_default_export_spec(shared_root = input$shared_root)
      spec$cohort$years <- input$years
      spec$cohort$participant_ids <- input$participant_ids
      spec$cohort$subset_file <- input$subset_file
      spec$domains <- input$domains
      spec$options$cat_labels <- input$cat_labels
      spec$output$path <- input$output_path

      export_busy(TRUE)
      export_busy_message(
        "Export in progress. Keep this window open until the result appears."
      )
      export_error_message(NULL)
      status_log(
        "Export started. Preparing shared snapshots and export output."
      )
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
              result <- export_runner(
                spec = spec,
                refresh_mode = input$refresh_mode
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
        notification_runner(
          ui = paste("Export failed:", error_message),
          type = "error",
          duration = NULL
        )
      } else {
        export_error_message(NULL)
        status_log(sprintf("Export completed: %s", result$output))
      }
      history_nonce(history_nonce() + 1)
    })

    export_history <- shiny::reactive({
      history_nonce()
      be_read_export_history()
    })

    output$preset_detail <- shiny::renderPrint({
      preset <- be_default_presets()[[input$preset]]
      if (is.null(preset)) {
        return("No preset selected.")
      }
      list(
        note = "Choosing a preset updates the Export tab years and domains; it does not run an export by itself.",
        preset = preset
      )
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

    output$export_history <- shiny::renderTable(
      {
        history <- export_history()
        if (!nrow(history)) {
          return(NULL)
        }

        history[,
          c(
            "completed_at",
            "status",
            "domains",
            "row_count",
            "output_path",
            "build_id"
          ),
          drop = FALSE
        ]
      },
      striped = TRUE,
      bordered = TRUE,
      spacing = "xs"
    )

    output$history_detail <- shiny::renderPrint({
      history <- export_history()
      if (!nrow(history)) {
        return("No local export history recorded yet.")
      }

      as.list(history[1, , drop = FALSE])
    })
  }
}
