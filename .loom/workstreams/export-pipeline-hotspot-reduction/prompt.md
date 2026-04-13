# Export Pipeline Hotspot Reduction

Work on the `bach-exporter` export hotspot-reduction lane tracked by coordinator epic `coordinator-jor`.

## Objective

Reduce the main remaining structural inefficiencies in the full export pipeline after the shared-context and reusable-targets refactor, while keeping the researcher-facing contract stable.

## Required outcomes

1. Simple REDCap-backed field-map domains stop independently splitting and rescanning the same full filtered event frame.
2. Final assembly no longer relies on repeated serial wide merges over an ever-growing output table.
3. The repo has a data-backed decision on whether `targets` should remain the default execution mode before any parallel backend lands.
4. Focused profiling and tests identify the next real hotspots after the generic bottlenecks are reduced.

## Constraints

- Keep the UI workflow unchanged.
- Keep `run_export()` as the stable backend entrypoint.
- Do not expose `targets` internals to researchers.
- Use the repo dev environment via `bash ./bin/in-env ...`.
- Preserve correctness and keep the full test suite green.

## Current focus

Work on `coordinator-jor.5`: isolate the remaining shared snapshot/context setup cost now that the specialized heavy-domain builders for biomarkers, medications, and PSG powerspec have been tightened and no longer dominate the same way.
