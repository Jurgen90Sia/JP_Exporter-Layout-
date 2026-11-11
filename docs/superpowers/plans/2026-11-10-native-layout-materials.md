# Native drawing documents and selection analysis plan

> Execute inline under the user's standing autonomous instruction. Use TDD,
> executing-plans, independent review and verification-before-completion.

**Goal:** advance the existing JP selection preview to real native drawing output,
with explicit paper scale, linked sources and traceable material quantities.
**Architecture:** keep the original extractor/projector; add a pure sheet planner,
a version/capability-checked native LayOut backend, a transactional source-package
writer and a separate read-only analysis adapter. UI commands consume validated
options and current selection. No external runtime libraries.
**Spec:** docs/development/agent-mission.md, docs/architecture.md and owner's master prompt.

## Decisions

Extend current modules instead of rewriting. Prioritize the linked native output
documented by LU, rather than only adding SVG decorations. Native export initially
supports selected Groups/ComponentInstances, one sheet per selected object and
Front/Right/Top/Isometric orthographic viewports; unsupported selection types get
an explicit error. A fixed paper scale must fit or fail; automatic scale chooses
a common fitting ratio. Section/perspective parity remains open. Source packages
must preserve world transformations and material inheritance without permanent
user-model changes. The owner has authorized routine decisions and ongoing
implementation; no extra design approval pause is needed.

## Tasks

1. Record identity guard and continuation prompt, baseline and new public evidence.
2. Test pure paper/viewport planning: ISO paper, margins, shared scale, deterministic
   placements, physical 1000 mm at1:10→100 mm, invalid/extreme inputs.
3. Implement planner. Write failing native contract tests for linked sources,
   page/view/scale setup, native dimensions and failure-safe output.
4. Implement native adapter and source export transaction using documented APIs.
   Probe actual SketchUp21/LayOut capabilities using JP-only reports and fixtures.
5. Independently implement/test selection/material analysis, then integrate its
   callback and UI. Report actual transformed face areas and count repeated
   instances; do not claim panel yield or unsupported volume.
6. Connect native export options and UI commands; extend tests. Validate real
   native files/PDF externally if runtime control permits. Keep explicit blockers.
7. Update research, parity matrix, compatibility and command status; run complete
   checks, independent review, commit, update PR/CI and package development output.

## Review focus

No cross-project artifacts/evidence; instance/edit transforms; paper/model units;
no partial export replacing existing files; linked-source portability; native API
version differences; surface area vs purchasable material; no fabricated runtime.

## Current execution checkpoint

Identity/prompt/research, paper planning, material analysis/UI, physical SVG sheet,
native source/document/package adapters and experimental UI are implemented with
automated contract tests. Native dimensions and real host/native PDF acceptance
remain outstanding. Do not mark tasks 4/6 or the whole plan complete until actual
native output, restoration, scale, framing and link-portability evidence exists.
SVG sheet export was added as a usable independent paper-planning checkpoint;
it is explicitly excluded from native-output acceptance.
