# Contributing

Read docs/architecture.md before changing subsystem boundaries. Use a dedicated
branch and a pull request. Keep the Ruby core independent of SketchUp and inject
host contracts through adapters. Add regression tests for coordinate transforms,
units and error cases; run every README check. Use Ruby 2.7-compatible syntax and
browser APIs available in the oldest targeted HtmlDialog Chromium engine.

No proprietary plugin sources, extracted assets, reverse-engineered private
formats or copied marketing claims may enter this repository. Describe workflows
in original language. License selection is pending; discuss contribution rights
with the owner before accepting external contributions for release.

Include changed behavior, verification evidence and host limitations in PRs.
Host-specific changes require manual checks recorded with exact SketchUp version,
OS, sample model, expected result and observed result. Never label API doubles as
SketchUp runtime tests. Do not commit user models, secrets, logs or generated RBZs.
Version changes belong in version.rb and CHANGELOG.md. Packaging must pass the
manifest validator and all available checks before any RBZ is generated; release
also requires the compatibility and licensing gates in docs/compatibility.md.
