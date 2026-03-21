be_target_graph <- function(
  spec = NULL,
  shared_root = NULL,
  refresh_mode = "auto"
) {
  if (is.null(spec) || is.null(shared_root)) {
    return(list(
      targets::tar_target(
        config_release_id,
        "dev"
      ),
      targets::tar_target(
        source_mode,
        "snapshot"
      )
    ))
  }

  list(
    targets::tar_target(
      export_spec,
      spec,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_shared_root,
      shared_root,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_refresh_mode,
      refresh_mode,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_data,
      be_assemble_export(
        spec = export_spec,
        shared_root = export_shared_root
      )
    ),
    targets::tar_target(
      snapshot_metadata,
      be_collect_snapshot_metadata(export_shared_root)
    ),
    targets::tar_target(
      export_manifest,
      be_build_export_manifest(
        spec = export_spec,
        shared_root = export_shared_root,
        refresh_mode = export_refresh_mode,
        snapshot_metadata = snapshot_metadata,
        execution_mode = "targets"
      )
    )
  )
}
