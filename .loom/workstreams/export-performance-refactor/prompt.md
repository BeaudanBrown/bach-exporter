# Export Performance Refactor

Work on the `bach-exporter` export performance lane tracked by coordinator epic `coordinator-l1n`.

## Objective

Remove the main structural inefficiencies in the current export path while preserving the existing researcher-facing contract.

## Required outcomes

1. Shared export context so the REDCap snapshot is prepared and filtered once per export.
2. Reusable scaffold/lookup intermediates for domains that currently rebuild the same inputs.
3. Registry-driven two-phase assembly instead of the long serial merge chain.
4. Hidden `targets` graph reshaped around reusable intermediate/domain targets.
5. Focused tests and docs that prevent regression to repeated whole-snapshot preparation.

## Constraints

- Keep the UI workflow unchanged.
- Keep `run_export()` as the stable backend entrypoint.
- Do not expose `targets` internals to researchers.
- Use the repo dev environment via `bash ./bin/in-env ...`.
- Preserve correctness and keep the full test suite green.

## Initial focus

Continue from `coordinator-l1n.4`: keep the researcher-facing contract stable while the hidden `targets` graph mirrors the reusable runtime structure through explicit context, intermediate, per-domain, and final-assembly targets.
