# Agent Execution Prompt

You are implementing this application incrementally.

## Primary objective

Inspect [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md), identify the **next most important uncompleted task**, and deliver it end-to-end.

## Required read order

1. `AGENTS.md`
2. [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md)
3. The most relevant section of [`specs/system-spec.md`](/home/beau/documents/projects/bach-exporter/specs/system-spec.md) for the selected task
4. [`specs/README.md`](/home/beau/documents/projects/bach-exporter/specs/README.md)
5. Relevant source files already implementing the current slice

## Required process

1. Read [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md) and choose one task:
   - highest priority by phase order,
   - not blocked by unmet dependencies,
   - self-contained enough to complete in one cycle.
2. Read only the most relevant context documents for that task:
   - architecture and behavior: [`specs/system-spec.md`](/home/beau/documents/projects/bach-exporter/specs/system-spec.md)
   - current implementation state: [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md)
   - current code in `R/`, `scripts/`, `_targets.R`, and launcher files as needed
3. Implement the selected task completely.
4. Add or update tests for any new logic introduced.
5. Run verification appropriate to the changed scope.
   - At minimum, run an R parse/syntax check across changed R files.
   - Run relevant unit or integration tests when test scaffolding exists.
   - Run any additional validation needed for launcher, Shiny, path/config, or `targets` changes.
6. Update [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md):
   - mark the task or phase status accurately,
   - add brief completion notes,
   - record any new handoff information the next agent will need.
7. Keep changes focused on the selected task.
8. Commit the changes when the selected task or a coherent milestone is complete.

## Constraints

- Do not duplicate or redefine standards already documented in `AGENTS.md` or the spec files.
- Keep changes focused on one plan task or one coherent milestone.
- Do not mark a task as complete unless the implementation and verification actually support that claim.
- Do not expose `targets` directly to researchers in the UI.
- Preserve the agreed architecture:
  - thin local launcher
  - shared-drive backend release
  - local per-user library/cache
  - researcher-facing Shiny UI
  - snapshot-based researcher workflow
- Do not rely on a researcher-readable shared REDCap token as a secrecy mechanism.
- Do not remove the current `dev` shared-root fallback unless shared-release packaging is fully implemented.
- If requirements are ambiguous or a blocker is real, stop and ask a targeted question.
- Do not rewrite git history unless explicitly instructed.

## Output expectation per cycle

- One completed plan task or one coherent milestone slice.
- Verification run for the changed scope.
- Updated [`specs/implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md).
- One commit.

## Current implementation context

The repository already contains an initial scaffold. Before choosing the next task, assume the following are already present and verify in code:

- package/runtime skeleton
- self-contained `launch_bach_exporter.R`
- shared-root bootstrap selector with `Browse`
- minimal Shiny shell
- placeholder export path
- `_targets.R` skeleton
- updated implementation plan with handoff notes

The next agent should usually continue from that scaffold rather than redesigning it.
