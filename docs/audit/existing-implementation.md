# Existing implementation audit — base 0ec59fb

All tracked project files were inspected before implementation. No redundant runtime files removed.

| Files | Function and observations |
|---|---|
| jp_exporter_layout.rb, version.rb, main.rb | Extension registration, version and single menu entry; load-once guards. |
| geometry/extractor.rb | Selected edges/faces/groups/instances, recursive transforms, edit transform once, inches→mm once, per-instance edge IDs, inherited visibility, budgets. No face triangles/materials/semantic hierarchy in snapshot. |
| core.rb | Pure six-view basis projection, finite checks, degeneracy filtering and bounds. Wireframe only. |
| ui/dialog.rb | Single HtmlDialog lifetime, preview callback, JSON validation, current model read, escaped transport, error logging. |
| ui/index.html, preview.js, style.css | Local CSP-protected UI, view selection, SVG edges, busy/timeout state, stale output clearing. No editor, paper, persistence or export. |
| diagnostics.rb | Rotating log and generic unexpected-error presentation. |
| dimensions/exporters/icons/layout/projection/sheets README.md | Explicit future specifications only, no fake implementations. |
| test/core_test.rb | Six views, units, finite coordinates, bounds and degenerate edges. |
| test/extraction_test.rb, support/sketchup_mock.rb | Adapter contracts for nested/noncommuting/mirror transforms, instance reuse, deduplication, hidden tags/folders, budgets and furniture panel bounds. Doubles are not host validation. |
| test/host_test.rb, registration_test.rb | Dialog/registration contracts and error handling; host doubles. |
| test/ui_test.js | Eight Node DOM-contract tests; no actual browser paint assurance. |
| test/package_test.py | Manifest regressions; Windows baseline exposes separator assertion and unavailable symlink permission. |
| scripts/check_syntax.rb, static_check.py, validate_package.py | Syntax, limited source-safety checks and two-entry runtime manifest. |
| .github/workflows/ci.yml, .rubocop.yml | Ruby 2.7/3.2/3.3, Node, Python, packaging and RuboCop Lint. Remote outcomes require inspection. |
| README, CHANGELOG, CONTRIBUTING, LICENSE, AGENTS, docs/* and prior plan | Honest foundation scope, pending license, architecture/host contract and historical Linux test evidence. |
| .gitignore | Generated artifacts/tools/log exclusions. |

Pipeline preserved: selection → transform traversal → world-mm snapshot → basis projection → bounded drawing → validated JSON → SVG. Owner reports successful SketchUp use, but that alone does not validate all target versions. The current machine has SketchUp 2021 installed; initial capture timed out.
