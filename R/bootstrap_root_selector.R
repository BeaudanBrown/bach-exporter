be_bootstrap_shared_root_app <- function(on_success = NULL) {
  ui <- shiny::fluidPage(
    theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
    shiny::tags$head(
      shiny::tags$style(
        shiny::HTML(
          ".bootstrap-wrap { max-width: 840px; margin: 40px auto; }
           .status-ok { color: #146c43; }
           .status-bad { color: #b02a37; }"
        )
      )
    ),
    shiny::div(
      class = "bootstrap-wrap",
      shiny::h2("Locate Shared BACH Exporter Folder"),
      shiny::p(
        "Choose the shared-drive root folder. The app will derive the shared app bundle and snapshot paths from this root."
      ),
      shiny::textInput(
        "shared_root",
        "Shared folder root",
        value = be_load_shared_root() %||% ""
      ),
      shinyFiles::shinyDirButton(
        "browse_root",
        "Browse",
        "Choose shared folder"
      ),
      shiny::br(),
      shiny::br(),
      shiny::actionButton("validate_root", "Validate"),
      shiny::actionButton("continue_root", "Continue"),
      shiny::hr(),
      shiny::uiOutput("root_status")
    )
  )

  server <- function(input, output, session) {
    roots <- be_shiny_roots()
    shinyFiles::shinyDirChoose(
      input,
      "browse_root",
      roots = roots,
      session = session
    )

    shiny::observeEvent(input$browse_root, {
      selected <- shinyFiles::parseDirPath(roots, input$browse_root)
      if (length(selected) == 1 && nzchar(selected)) {
        shiny::updateTextInput(session, "shared_root", value = selected)
      }
    })

    validated <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$validate_root, {
      result <- be_validate_shared_root(input$shared_root)
      validated(result)
      if (isTRUE(result$ok)) {
        be_save_shared_root(input$shared_root)
      }
    })

    output$root_status <- shiny::renderUI({
      result <- validated()
      if (is.null(result)) {
        return(shiny::p("No shared root validated yet."))
      }

      css_class <- if (isTRUE(result$ok)) "status-ok" else "status-bad"
      shiny::tagList(
        shiny::p(class = css_class, result$message),
        if (isTRUE(result$ok)) shiny::tags$code(result$paths$app_root)
      )
    })

    shiny::observeEvent(input$continue_root, {
      result <- validated() %||% be_validate_shared_root(input$shared_root)
      if (!isTRUE(result$ok)) {
        validated(result)
        return()
      }

      be_save_shared_root(input$shared_root)
      if (is.function(on_success)) {
        on_success(result$paths$shared_root)
      }
      shiny::stopApp(result$paths$shared_root)
    })
  }

  shiny::shinyApp(ui, server)
}
