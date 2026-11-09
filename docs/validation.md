# Cloud validation — 2026-11-09

Executed on Linux, Ruby 3.3.8, Node.js 24.22.1 and Python 3.
Ruby and lint tooling were extracted from authenticated Debian packages into a
user-local directory outside the repository; no toolchain files are committed.
REXML 3.4.0 was obtained over verified HTTPS and checked against RubyGems checksum
metadata. System installation and RubyGems index access were unavailable; these
are Cloud setup constraints, not repository test failures.

| Check | Result |
|---|---|
| Ruby core/extraction/host-contract/registration suite | 21 tests, 88 assertions, 0 failures/errors/skips |
| Ruby syntax | 13 files passed |
| RuboCop 1.39.0 Lint, Ruby 2.7 parse target | 13 files, no offenses |
| JavaScript syntax | Passed |
| Node test runner | 8 passed, 0 failed/skipped |
| Python packaging regressions | 4 passed |
| Package manifest validation | 16 runtime/documentation files, two install entries |
| Basic source safety checks | Passed; not a security audit |
| SketchUp runtime / native HtmlDialog browser | Not run; unavailable on Linux |
| Ruby 2.7 and 3.2 execution | Not run locally; configured CI matrix |
| GitHub Actions | Configured; execution results not observed in Cloud |

The review found hidden tag-folder inheritance and stale SVG on request failure.
Regression tests reproduced both failures, then passed after the fixes. The first
lint run found ambiguous test block association; it was corrected and rerun clean.
No unresolved automated test failure is known. No RBZ was generated.

Host contract doubles validate our adapter's behavior, not the native API's
implementation. Rendering tests inspect SVG node construction through a DOM
contract double; they do not prove browser paint, font metrics or CSP behavior.
Follow compatibility.md before claiming host support or releasing.
