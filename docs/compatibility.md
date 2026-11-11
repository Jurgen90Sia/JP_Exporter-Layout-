# Compatibility and host validation

Targets, not verified claims: SketchUp 2021, 2022, 2023, 2024, 2025 and 2026 on
supported Windows/macOS versions for each host. Ruby 2.7-compatible source is the
minimum; CI exercises Ruby 2.7, 3.2 and 3.3. Do not equate those CI versions with
a specific SketchUp release's embedded build. Verify actual RUBY_VERSION and
Sketchup.version in each manual session. HtmlDialog availability alone does not
prove browser API behavior or extension compatibility.

| Host | Windows runtime | macOS runtime |
|---|---|---|
| SketchUp 2021 | Not run | Not run |
| SketchUp 2022 | Not run | Not run |
| SketchUp 2023 | Not run | Not run |
| SketchUp 2024 | Not run | Not run |
| SketchUp 2025 | Not run | Not run |
| SketchUp 2026 | Not run | Not run |

Cloud Linux cannot execute SketchUp. API doubles cover consumed contracts only.
Record OS, host version, embedded Ruby version, model fixture and exact observations
for each manual check:

1. Install two-entry extension structure; ensure one Extension Manager/menu entry
   across restarts. Disable/re-enable and verify registration behavior.
2. Select a known 600 × 400 × 800 mm box. Verify all six view extents and directions.
3. Place nested rotated, translated, mirrored and nonuniformly scaled components;
   compare endpoints with independently measured model coordinates.
4. Open nested editing context; select an edge and confirm edit transform once.
5. Select face and edge together; verify no duplicated edge. Repeat a definition
   at two placements and ensure both are drawn.
6. Hide entities and tags; verify documented visibility policy. Test soft edges,
   active section cuts and scenes to confirm documented wireframe limitations.
7. Empty/unsupported selection, deletion, new active model and budget exceedance
   produce errors without model changes or stale preview.
8. Repeated clicks, dialog close/reopen, browser callback readiness and timeout
   recover without duplicate dialogs or callbacks. Verify SVG rendering and CSP
   in oldest target HtmlDialog engine.
9. Check large assemblies for UI stalls and set a measured safe preview budget.

No RBZ release until available checks and package validation pass. Public release
additionally requires license approval, host records, signing/loading-policy review,
clean-room install, version consistency and owner approval. Signing is not performed
by this foundation's CI. CI does not publish artifacts or releases.
