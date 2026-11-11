# Technical drawing expansion implementation plan

> Execute inline under the owner's explicit autonomous directive. Use executing-plans, test-driven-development and verification-before-completion.

**Goal:** Extend the working preview incrementally toward the supplied master requirements.
**Architecture:** Preserve extraction and transform composition. Add pure drawing services, validated host commands, and original local UI controls.
**Tech stack:** Ruby 2.7 syntax, dependency-free browser JavaScript; Python packaging tooling.
**Spec:** Owner-supplied “JP EXPORTER LAYOUT — ULTIMATE MASTER DEVELOPMENT PROMPT”, 2026-11-10; docs/architecture.md.

## Global constraints
- Millimeters internally; parent * local transforms; never mutate source models during preview.
- No proprietary code/assets. No fabricated native LayOut output or compatibility claims.
- All enabled commands must execute. No official release or merge.
- Existing isolated checkout, development/project-foundation; preserve unrelated remote changes.

## Approach and ruling
Extend current modules rather than rewrite them. Native LayOut is the preferred final editable-document backend; independent drawing services support preview and DXF. The owner explicitly requested autonomous implementation without intervening approvals, overriding the normal design approval pauses. Work is partial until every master requirement meets its runtime gates.

## Review focus
Negative/mirrored coordinates; singular projected spans; invalid UI data; atomic file replacement; Windows path and symlink behavior. Native runtime and linked-file portability require separate validation.

## Tasks
1. Audit all tracked files; research official products/API and accessible tutorial evidence. Record unknowns and baseline results.
2. Reproduce Windows package failures, normalize manifest paths and make unavailable symlink capability an explicit skip. Run regressions.
3. Test first: isometric equal-axis lengths, directions, mirrored/negative coordinates and unchanged orthographic views. Add basis and UI option.
4. Test first: overall horizontal/vertical dimension measurements, zero spans, precision and scale-independent values. Implement pure dimension records and preview rendering/toggle.
5. Test first: DXF units, geometry, negative coordinates, dimension graphics/text, malformed data and atomic output. Implement documented model-space DXF and host save dialog. Validate with an independent reader.
6. Test first: project snapshot round-trip, malformed/newer schemas and file atomicity; connect explicit save/open commands. Snapshots are not associative native LayOut documents.
7. Add meaningful frontend interaction tests and host contracts; run full available checks, review, commit logical units, update existing PR without merging. Package only if every available automated check passes.
8. Continue with face-aware hidden-line/section, paper sheets and native LayOut integration as feasible; leave exact remaining work and evidence in final report.

## Progress
Baseline: JS 8 pass, package/static checks pass; Python one path failure and one symlink privilege error on Windows. Standalone Ruby initially absent; portable toolchain being prepared. SketchUp 2021 installed, initial window capture timed out. No new runtime PASS asserted.

Tasks 1–7 executed for the bounded drawing-tools slice; see execution-report.md for exact results. Task 8 progressed with optional triangulation and true opaque depth intervals. Sections, paper sheets and native integration remain outstanding; the master objective is not marked complete. Rulings: no projected isometric dimensions; explicit skip when Windows forbids symlinks; no host compatibility claim after capture failures. Reviewer regressions for edge-on and translated coplanar faces were reproduced then repaired. No external toolchain files enter the package.
