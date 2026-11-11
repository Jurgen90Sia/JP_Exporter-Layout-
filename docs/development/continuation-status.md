# JP Exporter Layout 0.3.0 development continuation

Project: Jurgen90Sia/JP_Exporter-Layout-, branch development/project-foundation.
Namespace JPExporter::Layout. No CNC code or evidence is part of this delivery.
Prompt/instructions: agent-mission.md and repository AGENTS.md.

## Implemented in this continuation

| Feature / command | Code | Evidence and limits |
|---|---|---|
| analyze_materials / export_materials | geometry/selection_analysis.rb, UI/dialog.rb, preview.js | Visible face counts, per-instance provenance, inherited/explicit front/back materials; transformed mm²; panel m²; atomic JSON export. Nested edit ancestor regression included. Not purchasing/volume/classification. Native unrun. |
| Paper planning | sheets/plan.rb | A0–A4, orientation, deterministic grid, one shared ratio per sheet, auto conventional ratios, fixed overflow rejection; tested translated geometry and physical extents |
| export_sheet_svg | exporters/sheet_svg.rb, UI controls | Current combined selection, front/right/top/isometric, centered physical-mm sheet, escaped labels; independent REXML parsing verifies 1000 mm at 1:10 is 100 paper mm; wireframe/no dimensions |
| export_native (experimental) | layout/source_export.rb, document_export.rb, package_export.rb | Selected groups/components, one source/page per object, four vector viewports, native save/reopen/page count/PDF API calls; no native runtime outcome yet |
| Failure handling | native source/package adapters | Temporary wrapper holds edit*instance transform and inherited paint; abort and limited state comparison on success and failure; incomplete rollback regression; new-folder-only export and cleanup; no existing output replacement |
| Source-bound runtime fixture | scripts/runtime_jp_materials_sheets.rb | Optional SketchUp Ruby Console test: temporary 600×400×800 mm painted box, areas and 1:10 sheet, abort and model restoration check, unique timestamped/hash-bound report. Script has syntax verification only, NOT runtime PASS |
| Reference inventory | research/video-workflows.md | Official descriptions plus sampled storyboard frames; new requirements kept OPEN |

Native backend checks currently use contract doubles, including fake file bytes
clearly labeled in tests. These files are never shipped as example native outputs.
Real linked references, camera framing, PDF geometry/text/physical scale and moving
the package folder have NOT been verified. No native dimensions, sections, hatch,
manual page editor, detail-region tool, doorless elevations or four display modes.
Hard-link file publication needs filesystem support; native source export briefly
uses a model transaction. State comparison covers entity/definition IDs, selection,
active path and modified flag; it cannot prove complete metadata/undo restoration.

## Verification record

Local Ruby 3.3.10: 65 tests / 315 assertions passed. JavaScript: 13 tests passed.
Ruby syntax: 34 files. RuboCop: 34 files, zero offenses (toolchain deprecation
warning recorded separately). Package manifest: 28 runtime files. Independent DXF
and packaging Python suite: five tests, four passed, one Windows symlink privilege
skip. Basic source-safety and diff whitespace checks passed. Host doubles are not SketchUp 2021 validation.
No actual new-feature native document or PDF has been generated or inspected.
Original owner preview success remains acknowledged; CNC runtime results excluded.

Independent review found missing active-edit material inheritance; fixed and
regression-tested. It also found failure-path restoration comparison and stale
runtime-report risks; failure comparison now runs in ensure, and reports use a
new per-run directory and capture fixture/rollback failures. Native API signatures
were checked against official documentation; real host verification remains open.

## Next work, in order

1. Run the JP-only fixture and native package command in a controlled SketchUp
   session. Verify source transforms/paint, complete rollback and undo state,
   page/view counts, camera crop/centering and true paper scale on reopened files.
   Independently parse/render native PDF and move the package to verify links.
2. Add native associative dimensions using the pre-2026 three-argument constructor;
   then true A–A/B–B clipping/caps/holes/hatch with geometry regressions.
3. Implement manual dimensions/chains/text/arrows/eraser, detail-region extraction,
   tag-based door hiding, four display modes and free page/view editing.
4. Full project persistence, templates, EN/SQ localization, representative furniture
   benchmarks and complete host matrix. Never call these completed from stubs.

Strict historical end-to-end LU parity stays 0/6 until native acceptance is met;
the expanded tutorial requirements also remain open. No merge/official release.
