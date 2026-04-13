be_local_export_dir <- function() {
  path <- file.path(be_local_data_dir(), "exports")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_export_history_path <- function() {
  file.path(be_local_export_dir(), "history.jsonl")
}

be_make_run_id <- function(now = Sys.time()) {
  timestamp <- format(
    as.POSIXct(now, tz = "UTC"),
    "%Y%m%dT%H%M%OS3Z",
    tz = "UTC"
  )
  timestamp <- gsub("[^0-9TZ]", "", timestamp)
  sprintf("%s-%s", timestamp, Sys.getpid())
}

be_export_log_path <- function(run_id) {
  file.path(be_local_log_dir(), sprintf("export-%s.log", run_id))
}

be_export_history_sanitize_value <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }

  if (is.atomic(value) && length(value) <= 1) {
    return(unname(value))
  }

  if (is.atomic(value)) {
    return(as.vector(value))
  }

  if (is.data.frame(value)) {
    return(lapply(seq_len(nrow(value)), function(i) {
      as.list(value[i, , drop = FALSE])
    }))
  }

  if (is.list(value)) {
    return(lapply(value, be_export_history_sanitize_value))
  }

  as.character(value)
}

be_append_export_log <- function(
  log_path,
  message,
  level = "INFO",
  data = NULL,
  log_callback = NULL
) {
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)

  entry <- list(
    at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    level = level,
    message = message
  )
  if (!is.null(data)) {
    entry$data <- be_export_history_sanitize_value(data)
  }

  cat(
    jsonlite::toJSON(entry, auto_unbox = TRUE, null = "null"),
    "\n",
    file = log_path,
    append = TRUE,
    sep = ""
  )

  if (is.function(log_callback)) {
    tryCatch(
      log_callback(entry = entry, log_path = log_path),
      error = function(err) NULL
    )
  }

  invisible(entry)
}

be_format_export_log_entry <- function(entry) {
  if (is.null(entry)) {
    return(character())
  }

  if (is.character(entry) && length(entry) == 1L) {
    parsed <- tryCatch(
      jsonlite::fromJSON(entry, simplifyVector = FALSE),
      error = function(err) NULL
    )
    if (!is.null(parsed)) {
      entry <- parsed
    } else {
      return(entry)
    }
  }

  at <- as.character(entry$at %||% "")
  level <- as.character(entry$level %||% "INFO")
  message <- as.character(entry$message %||% "")
  prefix <- paste(c(at, sprintf("[%s]", level)), collapse = " ")
  prefix <- trimws(prefix)

  if (is.null(entry$data)) {
    return(trimws(paste(prefix, message)))
  }

  data_text <- tryCatch(
    jsonlite::toJSON(entry$data, auto_unbox = TRUE, null = "null"),
    error = function(err) NULL
  )
  if (is.null(data_text) || !nzchar(data_text)) {
    return(trimws(paste(prefix, message)))
  }

  trimws(paste(prefix, message, data_text))
}

be_read_export_log <- function(log_path, limit = 200) {
  if (is.null(log_path) || !nzchar(log_path) || !file.exists(log_path)) {
    return(character())
  }

  lines <- readLines(log_path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) {
    return(character())
  }

  if (!is.null(limit) && length(lines) > limit) {
    lines <- tail(lines, limit)
  }

  vapply(lines, be_format_export_log_entry, character(1))
}

be_append_export_history_record <- function(record, history_path = NULL) {
  history_path <- history_path %||% be_local_export_history_path()
  dir.create(dirname(history_path), recursive = TRUE, showWarnings = FALSE)

  cat(
    jsonlite::toJSON(record, auto_unbox = TRUE, null = "null"),
    "\n",
    file = history_path,
    append = TRUE,
    sep = ""
  )

  invisible(record)
}

be_read_export_history <- function(limit = 20, history_path = NULL) {
  history_path <- history_path %||% be_local_export_history_path()
  if (!file.exists(history_path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  lines <- readLines(history_path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  records <- lapply(lines, function(line) {
    tryCatch(
      jsonlite::fromJSON(line, simplifyVector = FALSE),
      error = function(err) NULL
    )
  })
  records <- Filter(Negate(is.null), records)
  if (!length(records)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  if (!is.null(limit) && length(records) > limit) {
    records <- tail(records, limit)
  }
  records <- rev(records)

  rows <- lapply(records, function(record) {
    data.frame(
      run_id = as.character(record$run_id %||% NA_character_),
      status = as.character(record$status %||% NA_character_),
      started_at = as.character(record$started_at %||% NA_character_),
      completed_at = as.character(record$completed_at %||% NA_character_),
      output_path = as.character(record$output_path %||% NA_character_),
      row_count = suppressWarnings(as.integer(
        record$row_count %||% NA_integer_
      )),
      domains = paste(record$domains %||% character(), collapse = ", "),
      build_id = as.character(record$build_id %||% NA_character_),
      error_message = as.character(record$error_message %||% NA_character_),
      log_path = as.character(record$log_path %||% NA_character_),
      manifest_path = as.character(record$manifest_path %||% NA_character_),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

be_build_export_history_record <- function(
  manifest,
  output_path,
  manifest_path,
  log_path,
  status,
  started_at,
  completed_at,
  row_count = NA_integer_,
  error_message = NULL
) {
  list(
    run_id = manifest$run$run_id %||% NULL,
    status = status,
    started_at = started_at,
    completed_at = completed_at,
    output_path = output_path,
    manifest_path = manifest_path,
    log_path = log_path,
    row_count = row_count,
    domains = manifest$domains,
    years = manifest$cohort$years %||% NULL,
    participant_ids = manifest$cohort$participant_ids %||% NULL,
    build_id = manifest$build_id %||% NULL,
    execution_mode = manifest$execution_mode %||% NULL,
    refresh_mode = manifest$refresh_mode %||% NULL,
    error_message = error_message
  )
}

be_finalize_export_manifest <- function(
  manifest,
  run_id,
  log_path,
  started_at,
  completed_at,
  output_path,
  row_count
) {
  manifest$run <- list(
    run_id = run_id,
    started_at = started_at,
    completed_at = completed_at,
    duration_seconds = as.numeric(
      difftime(
        as.POSIXct(completed_at, tz = "UTC"),
        as.POSIXct(started_at, tz = "UTC"),
        units = "secs"
      )
    ),
    log_path = log_path
  )
  manifest$output$path <- output_path
  manifest$output$manifest_path <- paste0(output_path, ".manifest.json")
  manifest$output$row_count <- row_count
  manifest
}
