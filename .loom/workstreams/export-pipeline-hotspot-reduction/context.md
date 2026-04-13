# Export Pipeline Hotspot Reduction Context

## Objective

Reduce the main remaining full-export bottlenecks after the shared-context and reusable-targets refactor, without changing the researcher-facing export contract and without focusing on parallelisation yet.

## Why this lane exists

A follow-up performance review on 2026-03-27 found that the first refactor removed repeated whole-snapshot preparation, but broad exports still pay large structural costs:

1. Many simple REDCap-backed domains independently split and rescan the full filtered event frame.
2. Final assembly still relies on repeated serial wide `merge()` calls as domain columns accumulate.
3. The app still defaults to `targets` execution even though the current runtime work is largely serial, so there may be fixed orchestration overhead before any real parallel benefit exists.
4. Once the generic hotspots are reduced, heavier specialized domains such as biomarkers, medications, and PSG powerspec will likely become the next dominant costs.

## Current workstream

- Beads epic: `coordinator-jor`
- Branch: `master`
- Repo-local docs for this lane:
  - `.loom/workstreams/export-pipeline-hotspot-reduction/context.md`
  - `.loom/workstreams/export-pipeline-hotspot-reduction/handoff.md`
  - `.loom/workstreams/export-pipeline-hotspot-reduction/prompt.md`

## Progress so far

1. Shared event-level reductions landed for the simple field-map and participant-year domains.
2. Final assembly now uses keyed accumulators and scaffold attachment instead of repeated serial wide merges.
3. The exporter now uses the hidden `targets` pipeline exclusively, with the local store keyed by both `build_id` and `shared_root`.
4. Specialized heavy-domain tightening landed for biomarkers, medications, and PSG powerspec, replacing the previous split-heavy regroup/merge shape with keyed reduction and attachment paths.

## Current direction

1. `coordinator-jor.5` is complete; next should profile fixed bootstrap cost versus repeated shared snapshot/scaffold reads before defining the next optimization slice.
2. Keep the specialized heavy-domain regressions in place so later setup/IO work does not regress the cheaper keyed builder paths.
3. If profiling shows manifest path overhead, extend split metadata inputs before changing assembly semantics.

## Constraints

- Keep the UI workflow unchanged.
- Keep `run_export()` as the stable backend entrypoint.
- Do not expose `targets` internals to researchers.
- Use the repo dev environment via `bash ./bin/in-env ...`.
- Preserve correctness and keep the full test suite green.
