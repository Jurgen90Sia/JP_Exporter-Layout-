# Development execution report — 2026-11-10

## Outcome and audit

Implemented an incremental 0.2.0 development slice, preserving the original selection/transform/mm/wireframe pipeline. This is **not** the complete master specification or a production release. The full local repository was cloned and audited; historical findings are in docs/audit. Base: 0ec59fb10ecd79ff034295d62b48fde6df49c760. Implementation: 76a03cd094da9f4d78d82407a2484b848e62c2c6 on development/project-foundation.

Existing PR: https://github.com/Jurgen90Sia/JP_Exporter-Layout-/pull/1. No merge or official release authorized/performed. Final documentation commit follows the implementation SHA; inspect git log for its exact SHA.

## Reference research

Official LU product pages, official SketchUp/LayOut API references and vendor issue/example material were examined. Evidence, confidence and command/capability distinctions are in docs/research. Six official LayOut Exporter capability headings form the parity denominator. CAD Exporter evidence is tracked separately. Tutorial URL was found, but fetching the official embedded playlist returned Cache miss; no video playback, frames or transcript were inspected. Individual toolbar labels and detailed section interactions remain UNKNOWN. No proprietary code/assets or unverified external runtime dependencies were adopted.

## Implemented commands and behavior

| Capability/command | Implementation | Status |
|---|---|---|
| Existing Preview current selection / six views | core.rb, geometry/extractor.rb, ui/dialog.rb | Preserved; automated regression tests pass |
| Isometric | Orthonormal basis in core.rb, view selector | Implemented and connected; wireframe or opaque-face modes |
| Visible lines / Visible + dashed hidden lines | projection/hidden_line.rb and optional face-mesh extraction | Implemented and connected; segment/triangle interval depth, not bounding-box visibility |
| Overall dimensions | dimensions/overall.rb, checkbox, SVG | Orthographic width/height graphics; scale-aware offsets/symbols; isometric rejected |
| Export drawing DXF | exporters/dxf.rb, command callback/save panel | R2000 model-space mm LINE/TEXT; geometry/hidden/dimension layers; exploded dimensions |
| Save/Open drawing snapshot | project_snapshot.rb, atomic_file.rb, command callback | Versioned validated JSON drawing/annotations, not associative project persistence |
| Fit drawing | Frontend handler | Restores drawing/annotation framing |

All new host operations have contract tests through actual file save/open/export logic. Every enabled new button has a handler. Host callback execution itself still needs real SketchUp validation. Hidden-line processing uses opaque triangles, a 40,000-triangle input budget, one-million comparison budget and 20,000-segment output budget. It does not classify silhouettes, construction/section/soft/coplanar seam roles. Selected edges without selected faces do not supply occluders. All selected faces are treated as opaque.

Dimension values and text are checked against orthographic drawing bounds during snapshot import/export. They are not native LayOut entities, are not associative, and have no manual placement or collision avoidance. Annotation scale does not make the SVG a physical paper sheet. DXF is full-size model-space mm, not a paper-space document. Independent CAD application round-trip has not been run.

## Validation evidence

Environment: Windows, portable Ruby 3.3.10, Node test runner, Python 3.12, ezdxf 1.4.5; source lint target Ruby 2.7. Portable Ruby archive SHA-256 was verified against release asset metadata: 80203102617b216dc0bcdcc8c21cc3889aa3fde7f15860e2e22ee5487480f694. Development tools remain outside the repository and RBZ.

| Check | Observed result |
|---|---|
| Full Ruby suite | 42 tests, 171 assertions, 0 failures/errors/skips |
| Ruby syntax | 22 files passed |
| RuboCop 1.39.0 Lint, Ruby 2.7 target | 22 files, no offenses; newer rubocop-ast emits tooling deprecation warnings |
| JavaScript syntax | Passed |
| Full JS suite | 11 passed, 0 failed/skipped |
| Python suite with independent DXF reader | 5 total: 4 passed, 1 skipped |
| Skipped packaging test | Windows symlink creation unavailable: WinError 1314; explicit capability skip, not PASS |
| Independent DXF integration | AC1015, INSUNITS=4, expected negative coordinates/text sizes/hidden layer, no audit errors or repairs |
| Package manifest | 22 files, two top-level install entries |
| Limited source-safety check / git diff check | Passed; source check is not a security audit |
| Actual browser rendering | Edge headless screenshot with a synthetic 600×800 mm test drawing and dimension/hidden-line graphics inspected; not a SketchUp HtmlDialog test |
| New code review | Independent reviewer reproduced two occlusion precision failures; regression tests then passed after local-coordinate/tolerance corrections; isometric dimensions rejected |
| Ruby 2.7/3.2 execution and GitHub Actions | Not run locally; existing matrix retained, Windows packaging and independent DXF CI added; remote execution not yet established here |

Initial failures were observed and repaired: Windows manifest separators; unsupported symlink fixture capability; missing DXF layer-table handle; new feature tests before implementation; edge-on triangle false occlusion; large-coordinate coplanar false occlusion; isometric dimension ambiguity; supplementary Unicode DXF escaping; inconsistent imported dimension values/text. No unresolved local automated test failure remains. One unavailable symlink test remains skipped.

## Real SketchUp and LayOut runtime status

SketchUp 2021 is installed and running. Computer-use discovery identified its windows, but targeting a test window failed with `FrameArrived timed out: timed out waiting on channel`; refreshing/re-activating and recapturing failed with `window capture timed out: timed out waiting on channel`. Further UI input was stopped. **Real new-feature SketchUp runtime checks: BLOCKED.** No user model was changed, plugin installed into the user's running SketchUp, or runtime PASS fabricated. The owner's earlier successful preview test is acknowledged, but its exact host/build/fixture was not recorded here.

Native LayOut output: **NOT IMPLEMENTED / NOT RUN**. PDF output: **NOT IMPLEMENTED / NOT RUN**. No native editable file or PDF was generated or inspected. Official documentation establishes API capability, not actual compatibility. Windows/macOS SketchUp 2021–2026 require the checklist in compatibility.md; macOS was not available. Development RBZ packaging is not proof of host compatibility.

## Master milestones remaining

| Milestone | State / next work |
|---|---|
| 0 Research/audit | Audit and evidence inventory delivered; detailed video/UI evidence unavailable |
| 1 Geometry | Existing transforms preserved; face triangles added; normals/materials/names/hierarchy/stable references incomplete |
| 2 Views/visibility | Partial: iso and opaque intervals; perspective, local/custom cameras and complete edge classification missing |
| 3 Sections/details | Missing: clipping, contours, holes, hatching, depth, labels and commands |
| 4 Dimensions | Partial overall graphics; native/associative/manual/chain/baseline/styles/collision rules missing |
| 5 Sheets/scales | Missing full paper/sheet/template/title-block model; only annotation sizing implemented |
| 6 Automatic layout | Missing packing/alignment/scale selection/batch allocation |
| 7 Interactive editor | Partial controls/framing; direct manipulation, pan/zoom and EN/SQ localization missing |
| 8 Native LayOut | Missing linked viewports, native dimensions, version-aware document exporter and link portability |
| 9 Furniture/statistics | Missing semantic classification/manual correction/material quantities |
| 10 PDF/DXF | Partial independent LINE/TEXT DXF; PDF, LWPOLYLINE contours, native CAD dimensions and paper-space missing |
| 11 Persistence | Partial drawing snapshots; full project/source references/recovery/migrations missing |
| 12 End-to-end/release | Automated checks and development packaging only; actual host matrix, performance, PDF/CAD round-trip and release license remain gates |

Next priority: unblock actual SketchUp test control and verify face extraction/HtmlDialog on a known panel assembly; implement face-aware section clipping; build real sheet/scale records; then integrate native linked LayOut viewports with native dimension anchors and PDF inspection. Preserve the working wireframe fallback throughout.

## Changed files and artifacts

Research/audit/plan/report documents added under docs; core, extractor, preview/dialog/UI, version/registration, README/CHANGELOG/architecture, CI and package validator updated. New runtime files: atomic_file.rb, drawing.rb, project_snapshot.rb, dimensions/overall.rb, exporters/dxf.rb, projection/hidden_line.rb. New tests: drawing_tools_test.rb, hidden_line_test.rb, output_test.rb, dxf_reader_test.py; existing extraction/host/UI/package tests expanded.

Development RBZ and full source ZIP are built only after the above available checks pass; their integrity and exact filenames are recorded with the delivered artifacts. No official GitHub release is created. Licensing selection remains pending.

Strict verified LU parity remains **0/6 = 0%** because none of the six full reference outcomes meets every native/runtime acceptance gate. Partial useful functionality is recorded above and must not be counted as complete parity.
