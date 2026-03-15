# BACH Exporter Specs

This folder defines the target architecture and delivery plan for the new BACH exporter system.

These documents started as a fresh-implementation brief. They now also serve as a running status record for the in-repo implementation.

## Document index

- [`system-spec.md`](/home/beau/documents/projects/bach-exporter/specs/system-spec.md): full architecture and product specification
- [`implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md): step-by-step plan for building the system from this blank repository

## Core decisions

- The end-user experience will be a local Shiny app, launched from a thin local R script.
- The thin launcher will locate a shared-drive root and then load the current backend release from that shared drive.
- The first-run experience will include a small bootstrap Shiny window with a `Browse` control to select the shared-drive root path.
- Researchers will not interact with `targets` directly.
- `targets` will be retained as a hidden backend cache/orchestration layer.
- Researchers will normally consume shared data snapshots, not call the REDCap API directly from their own machines.
- The REDCap API token will not be stored in a shared folder readable by all researchers if the goal is to keep it secret from them.
- API refresh will be handled by an admin-only refresh process that writes snapshots to the shared drive.
- The admin refresh path will use `redcapAPI`, with token storage handled through `unlockREDCap()` keyrings rather than plain-text config values.
- The live package library and live `targets` store will be local per user, not shared on the network drive.

## Current implementation status

- Shared-root bootstrap, shared-release launcher, and local runtime install path are implemented.
- Shared snapshot readers are implemented for REDCap, PSG, biomarkers, and sidecar metadata.
- Admin REDCap refresh is implemented through `redcapAPI` with keyring-backed auth.
- The admin refresh can write:
  - schema snapshots
  - typed REDCap record snapshots
  - single-record probe snapshots via env/config flags
- The direct non-`targets` export path currently supports:
- The targets-backed export pipeline is now active for the currently implemented domains, with the direct path retained as a debugging fallback.
- The currently implemented export domains are:
  - `participants`
  - `participant_screening`
  - `similarities`
  - `prose_passages`
  - `cognitive_screening`
  - `medications`
- Repeated medications now export in two shapes:
  - standalone `medications` export stays long at one row per medication instance
  - combined exports widen medication repeat instances to preserve one row per participant/year

## Design intent

The system should preserve the current researcher workflow:

1. Launch a simple tool.
2. Tick desired domains/options.
3. Choose an output file path.
4. Produce a CSV for downstream analysis scripts.

The system should not require researchers to understand R package management, `targets`, or REDCap export details.
