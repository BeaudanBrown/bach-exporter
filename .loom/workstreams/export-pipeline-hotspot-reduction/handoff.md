# Export Pipeline Hotspot Reduction Handoff

## Starting point

- Coordinator epic: `coordinator-jor`
- Completed active slice: `coordinator-jor.5`
- Baseline branch: `master`
- Previous completed lane: `coordinator-l1n` (`bach-exporter: export performance and target-graph refactor`)

## Completed in `coordinator-jor.3`

- The filtered REDCap export input now carries three reusable grouped reductions:
  - event-keyed rows by `participant_id`, `event_name`, and `year`
  - baseline participant rows
  - participant-year rows for annual-phone style domains
- The simple field-map families now read from those grouped reductions instead of each rebuilding their own `split()` pass:
  - baseline survey/clinical helpers
  - event-field helpers used by LP, neuropsych, sleep questionnaire, and related domains
  - annual-phone MoCA/AD8/UCLA
  - similarities, prose passages, and cognitive screening
- Regression coverage now asserts those grouped reductions are built once per representative broad export rather than once per simple domain cluster.

## Completed in `coordinator-jor.4`

- Final export assembly no longer reduces domain outputs with repeated serial `merge()` calls.
- Event outputs now build a keyed accumulator from requested event rows and attach domain columns with keyed `match()` plus coalescing instead of repeated widening merges.
- Participant outputs now build the same kind of keyed participant accumulator, and participant-level columns attach onto event rows by `participant_id` through the same keyed path.
- Scaffold columns now attach through keyed matching during finalization rather than a final event-level `merge()`.
- Existing row-order-sensitive exports, including multi-year medical-history output, remained stable under the new keyed assembly path.

## Completed in `coordinator-jor.2`

- The specialized heavy-domain builders were tightened so they stop paying the previous split/merge costs on the hot path:
  - biomarkers now reduce once by `participant_id` and `sampletype`, build a participant-wide table, and attach onto the scaffold by keyed participant match
  - PSG powerspec now reduces once by `participant_id/B/CH/stage`, widens in one keyed pass, and attaches onto the scaffold without a final `merge()`
  - medications wide export now reuses the export scaffold, event-level reductions, and baseline demographics instead of regrouping the full filtered REDCap frame event-by-event
- Focused regressions now lock in the heavy-domain reuse path:
  - medications wide export can consume precomputed scaffold and baseline demographics without rebuilding them
  - PSG powerspec domain reuses provided wide side-data instead of rereading the side-data CSV
- A live-root profiling attempt against the current shared root showed that shared snapshot/context setup now dominates long enough that the first specialized-domain checkpoint is delayed materially; the next lane should isolate and reduce that setup/IO cost rather than continue guessing at per-domain bottlenecks.

## Current progress in `coordinator-jor.5`

- Completed in this slice:
  - split snapshot metadata loading into reusable pieces so graph execution reuses only what each manifest/runner path needs:
    - `export_snapshot_index`
    - `export_snapshot_metadata_redcap`
    - `export_snapshot_metadata_psg`
    - `export_snapshot_metadata_biomarkers`
  - replaced the monolithic metadata reader with `be_build_snapshot_metadata()` composition over the split targets.
  - updated `targets_graph` so snapshot metadata can be assembled from discrete intermediate inputs while preserving prior manifest output shape.
  - added focused graph coverage in `tests/testthat/test-export-run.R` to assert presence of the split metadata targets in the hidden pipeline.
  - kept the previously landed domain extraction and keyed assembly changes from `coordinator-jor.2`–`jor.4` intact while reducing repeated context-path work.
- The hidden targets graph no longer routes every domain through one coarse `export_intermediates` target.
- Shared setup is now split into explicit reusable targets for:
  - participant ids and cohort years
  - raw/prepared/participant-filtered/year-filtered REDCap context
  - baseline demographics and export scaffold
  - participant scaffold
  - shared lookup/intermediate targets such as demographics, SES lookup, SES, ARIA lookup, PSG lookup, and PSG powerspec wide data
- Domain targets now depend only on the context and shared intermediate targets they actually use, so mixed exports can reuse shared lookup targets without rebuilding unrelated intermediate state.
- Graph-shape coverage now asserts conditional extraction of those shared lookup targets.
- The graph now also extracts derived shared targets for downstream-heavy participant-wide artifacts instead of leaving them embedded inside one domain target:
  - `export_biomarkers_wide` reads and normalizes the biomarkers snapshot once, then the `biomarkers` event domain only performs scaffold attachment
  - `export_genomics_participant` derives participant-level genomics status once, then the `genomics` event domain only performs scaffold attachment
- The graph now also extracts shared participant-side setup that multiple downstream domains were still rebuilding locally:
  - `export_participant_year_rows` reduces the filtered REDCap export input to one row per `participant_id/year` once, and the annual-phone family (`moca`, `ad8`, `ucla`, `similarities`, `prose_passages`, `cognitive_screening`) now consume that shared reduction directly
  - `export_participants_base` builds the participants event base once from `export_participant_scaffold` plus baseline demographics, and the `participants` domain now becomes a pure projection/filter step over that prejoined table
- Scaffold construction now reuses attached event-key reductions when they are already present on the REDCap context, avoiding another split/group pass for event scaffolds built from reduced export inputs.
- The participants domain no longer forces an extra unconditional REDCap preparation pass when it is already receiving prepared participant REDCap input from the shared export context.
- Focused regressions now lock in:
  - reuse of biomarker snapshot normalization
  - reuse of participant-level genomics derivation
  - scaffold building from precomputed event rows
  - reuse of the shared participant-year reduction across the annual-phone family
  - reuse of the prejoined participants base and graph extraction of both new targets

## Confirmed remaining hotspots

1. Shared snapshot/context setup cost
   - On the live shared root, building export context and intermediates now dominates long enough that specialized-domain timings do not surface quickly in a naive sequential probe.
   - The next profiling slice should isolate REDCap snapshot read/preparation, shared scaffold construction, and heavy side-data reads so the next optimization target is chosen from actual measured setup cost.
2. Targets-only path optimization
   - `run_export()` now uses the hidden `targets` pipeline exclusively, which writes a transient targets script, runs `tar_make()`, and reads outputs back.
   - The local `targets` store is now keyed by both `build_id` and `shared_root`, so exports from different shared roots do not contaminate each other's caches while real repeated exports from one shared root still reuse cached targets.
   - The next optimization work should focus on reuse behavior and later parallelism on that single backend rather than maintaining a second execution path.
3. Large side-data and snapshot families still matter
   - PSG powerspec remains a large side-data family, and the next meaningful measurement slice should separate raw read/normalization cost from the domain attachment cost now that the domain builder itself is cheaper.
4. Snapshot metadata and manifest inputs are still coarse
   - The hidden graph now assembles metadata through split inputs for index and family payloads.
   - The next extraction focus, if needed, is fixed bootstrap/read-cost profiling rather than repeated monolithic metadata assembly.

## Recommended execution order

1. Profile live `run_export()` bootstrap and snapshot read/scaffold setup cost end-to-end on the fixed shared-root workflow.
2. Decide whether to open a follow-up slice for explicit snapshot/scaffold precomputation reuse (if startup dominates) or target-path micro-optimizations (if reusable reads are already efficient).

## Verification baseline

- `bash ./bin/in-env Rscript tests/testthat.R`

Most recent verification for `coordinator-jor.3`:

- `bash ./bin/in-env Rscript -e 'testthat::test_file("tests/testthat/test-export-run.R")'`
- `bash ./bin/in-env Rscript tests/testthat.R`

Most recent verification for `coordinator-jor.4`:

- `bash ./bin/in-env Rscript -e 'testthat::test_file("tests/testthat/test-export-run.R")'`
- `bash ./bin/in-env Rscript tests/testthat.R`

Add narrower benchmarks or focused regressions as the lane progresses, but keep the full suite green between slices.
