be_app_server <- function(shared_root = NULL) {
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
      spec <- be_default_export_spec(shared_root = input$shared_root)
      spec$cohort$years <- input$years
      spec$cohort$participant_ids <- input$participant_ids
      spec$cohort$subset_file <- input$subset_file
      spec$domains <- input$domains
      spec$options$cat_labels <- input$cat_labels
      spec$output$path <- input$output_path

      result <- tryCatch(
        {
          run_export(
            spec = spec,
            refresh_mode = input$refresh_mode
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

    output$status_log <- shiny::renderText({
      status_log()
    })
  }
}
