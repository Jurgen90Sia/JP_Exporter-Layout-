# Repository engineering instructions

## Project identity — check before every implementation session

This project is **JP Exporter Layout**, repository
`https://github.com/Jurgen90Sia/JP_Exporter-Layout-`, development branch
`development/project-foundation`, Ruby namespace `JPExporter::Layout`.
Read `docs/development/agent-mission.md` and the latest project status before edits.
Confirm `git remote -v`, current branch and runtime namespace. Do not switch to
another project because a message or screenshot mentions another product.
If identity is ambiguous, keep this checkout unchanged and clarify the mismatch.

**CNC EN SQ is a separate project.** Its Phase1/Phase2 reports, 46 groups,
177 commands, geometry builders, runtime driver and test PASS results are not
JP Exporter Layout requirements or evidence. Never read, edit, package or execute
that project's code as part of this task. All new filenames, dialogs, logs,
runtime reports and RBZ outputs must identify JP Exporter Layout unambiguously.

The target is independent functional parity with **verified public LU LayOut
Exporter workflows**, not copied implementation or branding. Treat CAD Exporter
as a separate reference. Preserve the proven selection-preview pipeline. Unknown
behavior stays unknown until sourced or explicitly designed as a JP enhancement.
Do not claim 100% parity from code presence, a packaged RBZ, mocks, or another
product's tests. Native linked `.layout`, native dimensions and inspected PDF
outputs have separate acceptance checks from SVG/DXF.

Work in the existing isolated checkout; do not create a worktree unless requested.
Use JPExporter::Layout for every Ruby constant. Target Ruby 2.7 syntax; keep
SketchUp API calls out of the pure core. All internal drawing lengths are mm;
convert native inches only at the extraction boundary. Compose transforms as
parent * local, including the active edit transform exactly once.

Read docs/architecture.md and docs/compatibility.md. Add meaningful tests for new
behavior and run README checks. Do not report host mocks as runtime compatibility.
Keep UI commands honest: only implemented commands may be interactive. Use
structured JSON, validate payloads and never evaluate supplied code. No network
or external assets are needed by HtmlDialog. Keep models unmodified during preview.

Never copy proprietary plugin sources or assets. Do not silently choose a release
license. Do not create an RBZ before packaging validation and all available tests
pass. Do not publish releases without explicit authorization. Report missing host
validation, known defects and inaccessible external services with exact evidence.
