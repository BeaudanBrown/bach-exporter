# BACH Exporter Repo Instructions

This repository contains the BACH exporter rewrite: a local Shiny app plus hidden backend/export pipeline for producing researcher-facing CSV exports from shared snapshots.

## Working rules

- Use the Nix dev environment for repo commands.
- For commands agents execute themselves, prefer `bash ./bin/in-env <command>` for R, test, and formatting tasks.
- When instructing the user to run commands, assume their shell is already in the Nix environment via `.envrc`. Show bare commands (for example, `just refresh-data` or `Rscript scripts/refresh_snapshots.R`), never `bash ./bin/in-env` or another Nix environment wrapper. The verification and formatting wrappers below are for agent execution only.
- Treat `specs/system-spec.md` and `specs/implementation-plan.md` as the primary product and implementation references.
- Treat the coordinator Beads epic `coordinator-d6f` as the live work tracker for this repo; do not add backlog/status tracking to repo markdown.
- Keep researcher-facing workflow simple: launch app, choose export options, write CSV output.
- Do not commit or hardcode REDCap secrets, shared-drive credentials, or researcher-specific local paths.

## Key entrypoints

- `app.R`: top-level app entrypoint
- `launch_bach_exporter.R`: thin local launcher
- `R/`: package code for app, export domains, runtime/bootstrap, and snapshot readers
- `_targets.R`: hidden backend pipeline
- `scripts/refresh_snapshots.R`: admin snapshot refresh entrypoint

## Assessing REDCap schema coverage (manual review)

Use this process when checking whether the exporter handles the current REDCap instruments or preparing to implement a new instrument. This is an agent-led assessment, not a deterministic compatibility check. Do not add audit tooling or maintain a backlog in this document as part of the assessment.

### Inputs and safety

- Ask the user for an approved, current schema-only snapshot. The repo-local location used for this work is `data/local-shared-root/snapshots/redcap/schema/`; `data/` is gitignored. Do not assume that location exists or is current.
- Inspect only the approved schema files and source/tests for this assessment. Do not read `.env`, credentials, keyrings, participant snapshots, export CSVs, or cached record data. Do not invoke REDCap or unlock credentials to perform a coverage review.
- Gitignore is not an access-control mechanism. Schema text may itself contain internal information; do not commit raw snapshots or copy their contents into public artifacts without approval.
- If a refresh is needed, ask the user to run it. Existing commands are `Rscript scripts/refresh_snapshots.R` (configuration dry run), `just init-keyring`, and `just refresh-data`. The user must set `BACH_SCHEMA_SNAPSHOT_ONLY=true` in their local configuration/environment, checking that `.env` does not override it, and confirm the intended destination before execution. The default refresh exports records too, and the current entrypoint unlocks both main and PSG connections even in schema-only mode. There is no dedicated `refresh-schema` or audit recipe.
- `just set-admin-shared-root "$PWD/data/local-shared-root"` selects the local destination, but also changes the app/launcher's saved shared root. Warn the user before suggesting this change.

### Assessment procedure

1. Check the snapshot's refresh timestamp in `metadata.json`. Read `instruments.json` for form names/labels and `codebook.json` for field definitions, grouped by `form_name`. **`codebook.json` is the data dictionary; `metadata.json` describes the snapshot.** Use `field-names.json` and `events.json` as supporting context.
2. Compare instruments with `be_supported_export_domains()` and `be_export_domain_registry()` in `R/assemble_export.R`, then trace the relevant builders in `R/domain_*.R`, derived helpers, normalization, and tests. Check UI choices in `R/domain_choices.R` and pipeline wiring in `R/targets_graph.R` where relevant. A builder's existence alone does not establish that it is reachable from an export.
3. Compare actual source fields, not just instrument/domain names. Domains may combine multiple forms or use different names (for example Loneliness → `ucla`, MIND → `minddiet`, and paired memory forms). Inspect generated field names, checkbox expansions, repeated-instrument filters, and visit/year restrictions. Literal search is a discovery aid, not proof of coverage: Similarities, TOPF, and actigraphy construct field names dynamically.
4. Distinguish REDCap instrument coverage from external-data support. MRI, biomarkers, and PSG domains may read separate snapshots or side-data; a similarly named domain does not imply coverage of the corresponding REDCap form. Check legacy and replacement forms separately, especially medication forms with different repeating versus numbered-field layouts.
5. Classify findings as no handling found, partial/summary-only handling, implemented handling, or documented intentional exclusion. Do not infer intentional exclusion merely because a form is administrative, or call summary-only exports broken without checking their intended contract. Highlight expected source fields absent from the current dictionary, schema-definition mismatches, and effects on derived outputs as well as missing instruments.
6. Summarise evidence with exact form names, relevant source paths, important omitted fields, and uncertainty. Do not present literal-reference counts as coverage percentages. State that this is schema-and-code inspection, not validation against participant records or proof of scoring correctness.

### Starting a new instrument

- Use the dictionary to establish field names/types, coded choices, validation, branching logic, and calculation expressions. Confirm the desired output columns, scoring, missing-value rules, and visit alignment rather than assuming the dictionary fully specifies them.
- The current schema sync includes events but not instrument–event mappings or repeating-instrument configuration. Request those details separately when needed; do not infer record layout from field definitions alone.
- Build synthetic fixtures from the approved schema. Follow `specs/implementation-plan.md`: define the source-to-output mapping, implement/test the domain and derived helpers, then integrate validation, assembly, pipeline, and UI. Compare with representative legacy or independently checked results where available and authorised.

## Source-field exclusions

- Maintainer rules live at `<shared-root>/config/exclusions.json`; see `specs/exclusions.md` for the format, validation, and audit semantics. Do not commit participant-specific rules.
- Apply source masking before aggregation/derived calculations, including raw and labelled REDCap representations. Never implement data-quality exclusions by deleting participant rows or merely hiding final output columns.
- Use synthetic fixtures for verification. Missing configuration means no exclusions; malformed configuration fails. Unused-source columns are validated only when the source is loaded, and unmatched valid rules remain silent.

## Verification

- `bash ./bin/in-env Rscript scripts/check-dev-env.R`
- `bash ./bin/in-env Rscript tests/testthat.R`

## Formatting

- Format R files with `bash ./bin/in-env air format <path>`.
