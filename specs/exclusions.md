# Source-field exclusions

Maintainers can mask known-invalid measurements without deleting participants or editing shared snapshots. Place `exclusions.json` under `<shared-root>/config/`. The exporter reads this file automatically; there is no researcher-facing toggle.

## Configuration

```json
{
  "rules": [
    {
      "id": "example-csf-quality",
      "participant_id": "123",
      "source": "biomarkers",
      "sampletype": "csf",
      "columns": ["AB40_mean_conc", "AB42_mean_conc"],
      "reason": "Example only: invalid sample"
    }
  ]
}
```

This example uses a fictitious participant. Keep real participant-specific configuration on the shared root, not in version control. For local development, `data/local-shared-root/config/exclusions.json` is gitignored.

- `id`: unique, nonempty rule identifier.
- `participant_id`: a string; IDs use the exporter's existing prefix/zero-padding normalisation.
- `source`: `redcap` (main project) or `biomarkers`. Other sources are not supported.
- `sampletype`: optional; only supported for biomarkers, with `csf`, `plasma`, or `dbs`. If omitted, all sample types match.
- `columns`: nonempty array of exact **source snapshot column names**, not renamed export columns. Checkbox fields use the snapshot's expanded column names. Identifiers, event/repeat keys, and sample-type columns cannot be masked.
- `reason`: nonempty maintainer explanation.

All rows matching the participant and optional sample type are covered, across visits and collections. There is no event-specific restriction in this version. Multiple rules can apply to a row.

## Execution and validation

Masking replaces values with `NA` at snapshot ingestion, before cohort filtering, aggregation, and derived calculations. Rows and other values remain intact. Both raw and labelled REDCap snapshots are masked, so switching categorical mode cannot restore excluded fields. A missing labelled snapshot uses the masked raw snapshot.

- Missing configuration file: no exclusions.
- `{"rules": []}`: explicitly no exclusions.
- Malformed JSON, malformed rules, duplicate rule IDs, unsupported sources, and protected-column exclusions: fail the export.
- Column existence: validated against each source representation when that source is loaded, even if a rule matches no participants. A rule for an unused source does not force that snapshot to load.
- Valid rules matching no rows: ignored without warnings or manifest entries.

The targets graph checks the configuration on every run. Adding, changing, or removing the file invalidates dependent source processing and downstream exports. Existing exported CSVs are not rewritten; regenerate them to apply new rules.

## Derived values and audit

Exporter-calculated values use the masked inputs. For example, excluding CSF Aβ40 or Aβ42 makes the exporter-calculated CSF ratio missing. **Already calculated values stored in source snapshots are not recalculated or dependency-traced.** If a REDCap total or other stored derived field must also be excluded, list that source column explicitly.

The export manifest's `exclusions_applied` array contains matched rule IDs, source names, and counts of previously populated values replaced with `NA`. Counts cover the loaded source before cohort filtering; REDCap counts use the raw snapshot only, avoiding duplication from its labelled representation. Overlapping rules count only values not already masked by an earlier rule; a matched rule can therefore report zero. Original values, participant IDs, reasons, and unmatched rules are not copied into this audit array. Maintainers should choose rule IDs appropriate for inclusion in export manifests.

Exclusions do not remove free text or identifying information from other columns. They are a data-quality mechanism, not a general de-identification system.
