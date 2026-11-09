# Repository engineering instructions

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
