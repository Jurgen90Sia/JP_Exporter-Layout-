# JP Exporter Layout implementation plan

Goal: selected SketchUp geometry to a millimeter-normalized orthographic preview.
Architecture: SketchUp adapter → immutable edge snapshot → pure projection → JSON → SVG.
Stack: Ruby 2.7-compatible syntax and browser JavaScript, no runtime dependencies.
Spec: ../../architecture.md. Execute inline under the user's autonomous instruction.

1. Write representative extraction, projection, validation and UI contract tests.
2. Implement core and host adapter; verify nested transform order, visibility,
   edit context, repeated component instances, degenerate input and bounded payloads.
3. Register extension and dialog with explicit errors and safe JSON transport.
4. Add specifications, contribution guidance, syntax/static checks and package validation.
5. Run the complete available checks, review changes, commit a development branch.
6. Verify remote default branch and create a PR if GitHub access permits it.

Review focus: unit conversion once; noncommuting transforms; unsupported selections;
invalid bridge requests; projection orientation and browser rendering.
