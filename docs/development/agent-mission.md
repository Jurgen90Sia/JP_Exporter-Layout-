# JP Exporter Layout — continuation prompt and operating instructions

## Mission

Continue developing **JP Exporter Layout** to match every verified publicly
documented LU LayOut Exporter workflow through original implementation, then
deliver the explicitly requested JP enhancements. Implement working commands,
test them, update evidence and continue autonomously through ordinary engineering
decisions. Never substitute documentation, dummy geometry or disabled placeholders
for an implemented feature. Never assert full completion prematurely.

## Identity contract

- Repository: https://github.com/Jurgen90Sia/JP_Exporter-Layout-
- Branch: development/project-foundation; base for this continuation: 255365c.
- Existing PR: https://github.com/Jurgen90Sia/JP_Exporter-Layout-/pull/1
- Runtime namespace: JPExporter::Layout; extension entry: jp_exporter_layout.rb.
- Workspace: this repository under a-x20/work/JP_Exporter-Layout-.
- CNC EN SQ and its other chat are unrelated. No 46-group/177-command inventory,
  furniture-construction tool or CNC phase evidence belongs here.
- Work only in this repository. Preserve unrelated local/remote changes.

## Established behavior to preserve

The 0.2 development slice snapshots selected SketchUp geometry, composes nested
transforms and edit context once, converts inches to mm once, projects six
orthographic views plus isometric, and displays SVG. Optional opaque-triangle
interval occlusion, overall orthographic dimension graphics, model-space DXF and
portable drawing snapshots exist. Initial continuation baseline: 42 Ruby tests,
11 JS tests and independent DXF checks. Re-run; these numbers are historical,
not proof for new changes. The owner confirmed the original preview worked in
SketchUp, without a full version/fixture evidence record. No CNC runtime PASS
proves this extension. Strict native-workflow parity was still 0/6.

## Research protocol

Use the official LU site, official public tutorial/channel, accessible screenshots
and transcripts, official SketchUp/LayOut API documentation and vendor issue
tracker. Record source URL, date, exact observed label, input, interactions,
output, host, editability, parameters, limits and confidence. Record video timestamps
only for actually inspected frames/transcripts. Never claim to have watched
unavailable video. Distinguish CONFIRMED, INFERRED, UNKNOWN and JP ENHANCEMENT.
Do not turn a separate CAD Exporter feature into verified LayOut Exporter parity.
No proprietary code, protected assets, private endpoints or licensing bypass.

## Current priorities

Before continuing, read continuation-status.md for the 0.3 implementation and
current acceptance gaps. The baseline numbers above describe the earlier start.

1. Recover more public workflow evidence and expand the command/parity inventory.
2. Add read-only object/material analysis with transformed surface-area quantities,
   per-instance provenance and explicit unpainted/back-material policy. Do not
   equate total face area with purchased panel area or guess solid volume.
3. Implement real paper/scale planning and native editable LayOut output with
   linked SketchUp viewports, batch source data and native dimensions through
   officially supported APIs. Use actual native PDF export and inspect its pages,
   vector geometry, text, scale and reopening links. Never call SVG native output.
4. Implement true section clipping, contours/holes and hatching, followed by
   manual/associative dimensions, sheet/project editing and persistence.
5. Add EN/SQ localization and original functional UI, complete runtime matrix,
   performance/round-trip validation and release readiness.

## Implementation rules

Keep Ruby 2.7 syntax and a dependency-free host runtime. Test mathematical and
document services independently of the host. Use explicit typed command dispatch,
bounded payloads, safe JSON/text transport, honest error messages and atomic
file publication. All drawing lengths are model mm; paper placement is paper mm;
LayOut API's inch boundary requires explicit conversion. Transform order is
parent * local, with active edit transform applied once. Read active model afresh
per command. Never alter or save a user's model during preview/analysis.

Source exports may use a documented temporary transaction only when needed to
preserve selected instance transforms; abort it and verify the original model,
definitions, selection and edit context are restored. Keep linked data alongside
the generated document and verify reopen, not just file existence. Never replace
an existing export package until the entire new package is valid.

## Evidence and reporting

Write tests before implementation, observe the missing-feature failure, implement
and run the full available suite. Distinguish pure tests, host-contract doubles,
native SketchUp, native LayOut and independent file inspections. Bind reports to
project identity, source hashes, exact host/Ruby version, fixture and check IDs.
Keep reproducible packages and checksums. Each feature records connected UI,
module, tests, native evidence, limits and status. No native check is PASS until
observed. Do not borrow evidence from another namespace/project.

Use the existing PR, logical commits and non-destructive remote updates. No auto
merge or official release. License remains the owner's decision. Progress updates
state what was learned, what is implemented and what remains unverified. Deliver
the actual latest tested RBZ/source plus an accurate report; do not promise
future work as if it has run.
