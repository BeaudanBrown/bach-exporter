source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))

test_that("admin refresh config reads local config json", {
  config_dir <- tempfile("admin-config-dir-")
  dir.create(config_dir, recursive = TRUE)
  on.exit(unlink(config_dir, recursive = TRUE), add = TRUE)

  config_path <- file.path(config_dir, "admin-refresh.json")
  jsonlite::write_json(
    list(
      shared_root = "/tmp/shared-root",
      redcap_url = "https://redcap.example.org/api/",
      keyring = "bach-exporter-admin",
      project_alias = "bach-exporter",
      connection_name = "rcon_admin",
      schema_snapshot_only = TRUE,
      record_probe_only = TRUE,
      probe_records = c("10000")
    ),
    config_path,
    auto_unbox = TRUE
  )

  config <- be_admin_refresh_config(config_path = config_path)
  validation <- be_validate_admin_refresh_config(config)
  plan <- be_admin_refresh_plan(config)

  expect_true(validation$ok)
  expect_equal(config$shared_root, "/tmp/shared-root")
  expect_equal(config$keyring, "bach-exporter-admin")
  expect_equal(config$project_alias, "bach-exporter")
  expect_equal(config$connection_name, "rcon_admin")
  expect_true(config$schema_snapshot_only)
  expect_true(config$record_probe_only)
  expect_equal(config$probe_records, "10000")
  expect_equal(
    plan$snapshot_paths$metadata,
    file.path(
      "/tmp/shared-root",
      "snapshots",
      "redcap",
      "schema",
      "metadata.json"
    )
  )
})

test_that("admin refresh config fails clearly when project alias is missing", {
  config <- list(
    config_path = "/tmp/admin-refresh.json",
    shared_root = "/tmp/shared-root",
    redcap_url = "https://redcap.example.org/api/",
    keyring = "bach-exporter-admin",
    project_alias = "",
    connection_name = "rcon_admin"
  )

  validation <- be_validate_admin_refresh_config(config)

  expect_false(validation$ok)
  expect_match(validation$message, "project_alias is not configured")
})

test_that("admin refresh dotenv loader populates environment variables", {
  config_dir <- tempfile("admin-dotenv-dir-")
  dir.create(config_dir, recursive = TRUE)
  on.exit(unlink(config_dir, recursive = TRUE), add = TRUE)

  dotenv_path <- file.path(config_dir, ".env")
  writeLines(
    c(
      "BACH_SHARED_ROOT=/tmp/dotenv-shared-root",
      "BACH_REDCAP_URL=https://dotenv.example.org/api/",
      "BACH_REDCAP_KEYRING=dotenv-keyring",
      "BACH_REDCAP_PROJECT_ALIAS=dotenv-project",
      "BACH_REDCAP_CONNECTION_NAME=dotenv_connection",
      "BACH_SCHEMA_SNAPSHOT_ONLY=false",
      "BACH_RECORD_PROBE_ONLY=true",
      "BACH_PROBE_RECORDS=10000,10001"
    ),
    dotenv_path
  )

  old_env <- Sys.getenv(
    c(
      "BACH_SHARED_ROOT",
      "BACH_REDCAP_URL",
      "BACH_REDCAP_KEYRING",
      "BACH_REDCAP_PROJECT_ALIAS",
      "BACH_REDCAP_CONNECTION_NAME",
      "BACH_SCHEMA_SNAPSHOT_ONLY",
      "BACH_RECORD_PROBE_ONLY",
      "BACH_PROBE_RECORDS"
    ),
    unset = NA_character_
  )
  on.exit(
    {
      for (env_name in names(old_env)) {
        env_value <- old_env[[env_name]]
        if (is.na(env_value)) {
          Sys.unsetenv(env_name)
        } else {
          Sys.setenv(structure(env_value, names = env_name))
        }
      }
    },
    add = TRUE
  )
  Sys.unsetenv(names(old_env))

  expect_true(be_load_admin_dotenv(dotenv_path))

  config <- be_admin_refresh_config(config_path = tempfile("unused-config-"))

  expect_equal(config$shared_root, "/tmp/dotenv-shared-root")
  expect_equal(config$redcap_url, "https://dotenv.example.org/api/")
  expect_equal(config$keyring, "dotenv-keyring")
  expect_equal(config$project_alias, "dotenv-project")
  expect_equal(config$connection_name, "dotenv_connection")
  expect_false(config$schema_snapshot_only)
  expect_true(config$record_probe_only)
  expect_equal(config$probe_records, c("10000", "10001"))
})

test_that("admin schema snapshot paths follow shared-root layout", {
  shared_root <- tempfile("admin-shared-root-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  paths <- be_admin_snapshot_schema_paths(shared_root)

  expect_equal(
    paths$schema_dir,
    file.path(shared_root, "snapshots", "redcap", "schema")
  )
  expect_equal(
    paths$field_names,
    file.path(shared_root, "snapshots", "redcap", "schema", "field-names.json")
  )
  expect_equal(
    paths$codebook,
    file.path(shared_root, "snapshots", "redcap", "schema", "codebook.json")
  )
})

test_that("admin schema snapshot execution writes expected files", {
  shared_root <- tempfile("admin-schema-root-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  config <- list(
    shared_root = shared_root,
    redcap_url = "https://redcap.example.org/api/",
    keyring = "bach-exporter-admin",
    project_alias = "bach-exporter",
    connection_name = "rcon_admin"
  )

  fake_api <- list(
    export_project_info = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      list(
        project_id = 101,
        project_title = "BACH",
        project_pi_firstname = "Private",
        project_pi_lastname = "Person",
        project_pi_email = "private@example.org"
      )
    },
    export_events = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        event_name = c("baseline_arm_1", "year_2_arm_1"),
        arm_num = c(1, 1),
        stringsAsFactors = FALSE
      )
    },
    export_instruments = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        instrument_name = "demographics",
        instrument_label = "Demographics",
        stringsAsFactors = FALSE
      )
    },
    export_field_names = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        original_field_name = c("record_id", "age"),
        export_field_name = c("record_id", "age"),
        stringsAsFactors = FALSE
      )
    },
    export_metadata = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        field_name = c("record_id", "age"),
        form_name = c("participant", "participant"),
        field_type = c("text", "text"),
        field_label = c("Record ID", "Age"),
        stringsAsFactors = FALSE
      )
    }
  )

  unlock_calls <- 0L
  local_env <- new.env(parent = emptyenv())
  unlocker <- function(config, envir = parent.frame()) {
    unlock_calls <<- unlock_calls + 1L
    assign(config$connection_name, list(label = "fake-rcon"), envir = envir)
    invisible(NULL)
  }

  result <- be_admin_execute_schema_snapshot(
    config = config,
    envir = local_env,
    api = fake_api,
    snapshot_time = as.POSIXct("2026-03-12 01:02:03", tz = "UTC"),
    unlocker = unlocker
  )

  metadata <- jsonlite::read_json(result$paths$metadata, simplifyVector = TRUE)
  project_info <- jsonlite::read_json(
    result$paths$project_info,
    simplifyVector = TRUE
  )
  events <- jsonlite::read_json(result$paths$events, simplifyVector = TRUE)
  instruments <- jsonlite::read_json(
    result$paths$instruments,
    simplifyVector = TRUE
  )
  field_names <- jsonlite::read_json(
    result$paths$field_names,
    simplifyVector = TRUE
  )
  codebook <- jsonlite::read_json(
    result$paths$codebook,
    simplifyVector = TRUE
  )

  expect_equal(unlock_calls, 1L)
  expect_equal(metadata$snapshot_type, "schema")
  expect_equal(metadata$refreshed_at, "2026-03-12T01:02:03Z")
  expect_equal(metadata$counts$events, 2)
  expect_equal(metadata$counts$instruments, 1)
  expect_equal(metadata$counts$codebook, 2)
  expect_equal(project_info$project_title, "BACH")
  expect_false("project_pi_firstname" %in% names(project_info))
  expect_false("project_pi_lastname" %in% names(project_info))
  expect_false("project_pi_email" %in% names(project_info))
  expect_equal(events$event_name, c("baseline_arm_1", "year_2_arm_1"))
  expect_equal(instruments$instrument_name, "demographics")
  expect_equal(field_names$export_field_name, c("record_id", "age"))
  expect_equal(codebook$field_name, c("record_id", "age"))
})

test_that("admin full refresh writes schema, records, and snapshot index", {
  shared_root <- tempfile("admin-refresh-root-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  config <- list(
    shared_root = shared_root,
    redcap_url = "https://redcap.example.org/api/",
    keyring = "bach-exporter-admin",
    project_alias = "bach-exporter",
    connection_name = "rcon_admin",
    schema_snapshot_only = FALSE,
    record_probe_only = TRUE,
    probe_records = "10000"
  )

  fake_api <- list(
    export_project_info = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      list(project_id = 101, project_title = "BACH")
    },
    export_events = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        event_name = "Baseline",
        arm_num = 1,
        stringsAsFactors = FALSE
      )
    },
    export_instruments = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        instrument_name = "participant",
        instrument_label = "Participant",
        stringsAsFactors = FALSE
      )
    },
    export_field_names = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        original_field_name = c("idno", "age"),
        export_field_name = c("idno", "age"),
        stringsAsFactors = FALSE
      )
    },
    export_metadata = function(rcon) {
      expect_equal(rcon$label, "fake-rcon")
      data.frame(
        field_name = c("idno", "age"),
        form_name = c("participant", "participant_screening"),
        field_type = c("text", "calc"),
        field_label = c("ID", "Age"),
        stringsAsFactors = FALSE
      )
    },
    export_records_typed = function(
      rcon,
      fields = NULL,
      drop_fields = NULL,
      forms = NULL,
      records = NULL,
      events = NULL,
      survey = TRUE,
      dag = FALSE,
      date_begin = NULL,
      date_end = NULL,
      na = list(),
      validation = list(),
      cast = list(),
      assignment = list(),
      filter_empty_rows = TRUE,
      warn_zero_coded = TRUE,
      ...
    ) {
      expect_equal(rcon$label, "fake-rcon")
      expect_equal(records, "10000")
      expect_false(warn_zero_coded)
      if (identical(cast, redcapAPI::default_cast_character)) {
        expect_identical(validation, redcapAPI::skip_validation)
        return(data.frame(
          idno = "BACH001",
          age = "70",
          sex = "Female",
          stringsAsFactors = FALSE
        ))
      }

      expect_identical(cast, redcapAPI::raw_cast)
      expect_identical(validation, redcapAPI::skip_validation)

      data.frame(
        idno = "BACH001",
        age = "70",
        sex = "1",
        stringsAsFactors = FALSE
      )
    },
    raw_cast = redcapAPI::raw_cast,
    default_cast_character = redcapAPI::default_cast_character,
    skip_validation = redcapAPI::skip_validation
  )

  unlock_calls <- 0L
  local_env <- new.env(parent = emptyenv())
  unlocker <- function(config, envir = parent.frame()) {
    unlock_calls <<- unlock_calls + 1L
    assign(config$connection_name, list(label = "fake-rcon"), envir = envir)
    invisible(NULL)
  }

  result <- be_admin_execute_refresh(
    config = config,
    envir = local_env,
    api = fake_api,
    snapshot_time = as.POSIXct("2026-03-12 04:05:06", tz = "UTC"),
    unlocker = unlocker
  )

  raw <- utils::read.csv(result$records$paths$raw, stringsAsFactors = FALSE)
  labels <- utils::read.csv(
    result$records$paths$labels,
    stringsAsFactors = FALSE
  )
  records_metadata <- jsonlite::read_json(
    result$records$paths$metadata,
    simplifyVector = TRUE
  )
  snapshot_index <- jsonlite::read_json(
    result$snapshot_index$path,
    simplifyVector = TRUE
  )

  expect_equal(unlock_calls, 1L)
  expect_equal(raw$idno, "BACH001")
  expect_equal(raw$sex, 1)
  expect_equal(labels$sex, "Female")
  expect_equal(records_metadata$snapshot_type, "records")
  expect_equal(records_metadata$counts$raw_rows, 1)
  expect_equal(records_metadata$counts$labels_cols, 3)
  expect_true(records_metadata$probe$record_probe_only)
  expect_equal(records_metadata$probe$probe_records, "10000")
  expect_equal(snapshot_index$families, "redcap")
  expect_equal(snapshot_index$snapshots$redcap$metadata, "metadata.json")
  expect_equal(
    snapshot_index$snapshots$redcap$schema_metadata,
    file.path("schema", "metadata.json")
  )
})
