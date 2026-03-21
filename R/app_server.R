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

be_app_server <- function(shared_root = NULL, export_runner = run_export) {
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
      if (nrow(selected) == 1) {
        output_path <- if ("datapath" %in% names(selected)) {
          file.path(selected$datapath[1], selected$name[1])
        } else {
          file.path(selected$path[1], selected$name[1])
        }
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
    })

    shiny::observeEvent(
      input$preset,
      {
        preset <- be_default_presets()[[input$preset]]
        if (is.null(preset)) {
          return()
        }
        shiny::updateSelectInput(session, "years", selected = preset$years)
        shiny::updateCheckboxGroupInput(
          session,
          "domains",
          selected = preset$domains
        )
      },
      ignoreInit = TRUE
    )

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
        status_log(sprintf("Export failed: %s", conditionMessage(result)))
      } else {
        status_log(sprintf("Export completed: %s", result$output))
      }
    })

    output$preset_detail <- shiny::renderPrint({
      preset <- be_default_presets()[[input$preset]]
      if (is.null(preset)) {
        return("No preset selected.")
      }
      preset
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

    output$status_log <- shiny::renderText({
      status_log()
    })
  }
}
