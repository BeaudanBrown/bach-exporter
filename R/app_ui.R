be_domain_group_inputs <- function(selected = "participants") {
  groups <- be_domain_group_choices()
  lapply(names(groups), function(group) {
    shiny::tags$details(
      open = group %in% c("Clinical", "Surveys"),
      shiny::tags$summary(group),
      shiny::checkboxInput(
        be_domain_group_toggle_input_id(group),
        sprintf("Select all %s", group),
        value = all(unname(groups[[group]]) %in% selected)
      ),
      shiny::checkboxGroupInput(
        be_domain_group_input_id(group),
        NULL,
        choices = groups[[group]],
        selected = intersect(selected, unname(groups[[group]]))
      )
    )
  })
}

be_app_ui <- function() {
  shiny::fluidPage(
    theme = bslib::bs_theme(version = 5, bootswatch = "minty"),
    shiny::tags$head(
      shiny::tags$style(
        shiny::HTML(
          ".app-shell { max-width: 1200px; margin: 24px auto; }
           .app-note { color: #495057; }
           .busy-banner {
             margin-top: 12px;
             padding: 12px 14px;
             border-radius: 10px;
             background: #e3f6ea;
             border: 1px solid #9fd5b3;
             color: #184b2e;
             display: flex;
             align-items: center;
             gap: 10px;
             font-weight: 600;
           }
           .busy-banner__spinner {
             width: 14px;
             height: 14px;
             border-radius: 999px;
             border: 2px solid rgba(24, 75, 46, 0.25);
             border-top-color: #184b2e;
             animation: be-spin 0.8s linear infinite;
             flex: 0 0 auto;
           }
           .error-banner {
             margin-top: 12px;
             padding: 12px 14px;
             border-radius: 10px;
             background: #fce8e6;
             border: 1px solid #e09b93;
             color: #7a1f17;
             display: flex;
             flex-direction: column;
             gap: 4px;
             font-weight: 600;
           }
           .domain-groups details {
             margin-bottom: 8px;
             padding: 8px 10px;
             border: 1px solid #dee2e6;
             border-radius: 8px;
             background: #fff;
           }
           .domain-groups summary {
             cursor: pointer;
             font-weight: 600;
           }
           .domain-groups .form-group {
             margin-top: 8px;
             margin-bottom: 0;
           }
           @keyframes be-spin {
             from { transform: rotate(0deg); }
             to { transform: rotate(360deg); }
           }"
        )
      ),
      shiny::tags$script(
        shiny::HTML(
          "Shiny.addCustomMessageHandler('be-set-button-state', function(message) {
             var el = document.getElementById(message.id);
             if (!el) return;
             el.disabled = !!message.disabled;
             if (message.label) {
               el.textContent = message.label;
             }
           });"
        )
      )
    ),
    shiny::div(
      class = "app-shell",
      shiny::titlePanel("BACH Exporter"),
      shiny::p(
        class = "app-note",
        "Shared-drive launched export tool. This build supports screening, annual-phone, clinical, neuropsych, sleep, and the first imaging slices from shared REDCap snapshots."
      ),
      shiny::p(
        class = "app-note",
        "Researcher exports read shared snapshots only. REDCap connection and refresh settings stay in the admin workflow."
      ),
      shiny::fluidRow(
        shiny::column(
          width = 6,
          shiny::checkboxGroupInput(
            "years",
            "Years",
            choices = c(
              "Baseline" = "baseline",
              "Year 2" = "year2",
              "Year 3" = "year3",
              "Year 4" = "year4"
            ),
            selected = "baseline"
          ),
          shiny::p(
            class = "app-note",
            "Participants are always included in every export."
          ),
          shiny::actionButton(
            "select_all_domains_btn",
            "Select all optional domains"
          ),
          shiny::div(
            class = "domain-groups",
            be_domain_group_inputs(selected = character())
          ),
          shiny::radioButtons(
            "cat_labels",
            "Categorical labels",
            choices = c("named", "numbered"),
            selected = "named"
          ),
          shiny::textAreaInput(
            "participant_ids",
            "Participant IDs",
            value = "",
            placeholder = "Optional. Enter BACH0007, 0007, 7, etc. separated by commas or new lines.",
            rows = 4
          )
        ),
        shiny::column(
          width = 6,
          shiny::textInput("output_path", "Output CSV path", value = ""),
          shinyFiles::shinySaveButton(
            "browse_output",
            "Browse",
            "Choose output file",
            filetype = list(csv = "csv")
          ),
          shiny::actionButton("run_export_btn", "Run export"),
          shiny::uiOutput("export_busy_banner"),
          shiny::uiOutput("export_error_banner")
        )
      )
    )
  )
}
