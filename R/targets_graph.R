be_target_graph <- function() {
  list(
    targets::tar_target(
      config_release_id,
      "dev"
    ),
    targets::tar_target(
      source_mode,
      "snapshot"
    )
  )
}
