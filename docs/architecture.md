# Technical architecture and contracts

Status 0.2: foundation plus extraction → orthographic/isometric drawing → SVG;
optional opaque-triangle hidden-line intervals, overall dimension graphics, DXF
LINE/TEXT and drawing snapshots implemented. Original wireframe defaults remain.
The detailed planned sections below describe the full target; they do not imply
that the limited 0.2 services satisfy all those requirements. See execution-report.md.
Everything marked **planned** is a specification, not a shipped capability.
This is an original implementation informed by general technical drawing workflows.

## Design decisions

A host adapter snapshots native geometry; pure Ruby services process numeric
records; HtmlDialog renders versioned JSON. This permits deterministic tests
without SketchUp and keeps host API usage on its main thread. Alternatives were
a host-only monolith (hard to test) and an external rendering service (deployment,
privacy and credential costs). The dependency-free core is the engineering choice
for this foundation, not a claim of user approval of every future subsystem.

Future computational workers may consume snapshots but must never access live
SketchUp objects. Retain no model/entity references after a preview request.
Snapshots are request-owned numeric data; downstream services must not mutate them.
Current drawing records are Ruby Hash/Array values, not deeply frozen objects.

## Extraction and coordinate systems — implemented

Input: current model selection in active editing coordinates plus
`model.edit_transform`. Accept Edge, Face, Group and ComponentInstance. Traverse
faces through boundary edges, groups through their entities and instances through
definition entities. Other types (text, dimensions, images, construction geometry)
are ignored in this slice. Reject empty drawable results with an actionable error.
Skip invalid/deleted, hidden and tag-invisible entities at every traversal level,
including invisibility inherited from ancestor tag folders.
This is entity visibility filtering, not camera or occlusion filtering. Section
plane cuts, scene visibility, soft/smooth edge policy and material opacity are not
applied. A selected face supplies visible boundary edges even if adjacent faces
are outside the selection.

Compose `T_world = T_edit * T_parent * T_local`. Transform each endpoint using the
native Geom API before converting each coordinate by exactly 25.4 mm/inch.
This preserves rotations, translations, mirrors, nonuniform scale and shear as
supported by native transformation multiplication. Never convert translation
components separately or apply `edit_transform` twice. Retain instance-path IDs;
shared definition edges must appear once per instance, and face/edge selection
overlap must not duplicate an edge in the same context. No welding by coordinate:
topologically different edges may coincide. Reject cyclic definitions and depth
above 64; budget 20,000 unique edges and 400,000 visited entities. Exceeding a budget
fails the whole snapshot, never silently truncates it. Budgets are synchronous
safety limits, not a responsiveness guarantee; large selections can block the host.

Snapshot v1: `{units: "mm", edges: [{id: "instance/edge", points: [[x,y,z],[x,y,z]]}]}`.
IDs are transient session identifiers, not persistent document links. Future source
references should include persistent IDs, model GUID and instance path separately.

## Orthographic views — implemented

Right-handed world axes X/Y/Z, drawing coordinates u right and v up:

| View | Camera side | u | v |
|---|---|---|---|
| Front | −Y | X | Z |
| Rear | +Y | −X | Z |
| Left | −X | −Y | Z |
| Right | +X | Y | Z |
| Top | +Z | X | Y |
| Bottom | −Z | X | −Y |

Project by dot product with each basis axis; do not apply drawing scale here.
Reject nonfinite coordinates and unknown view names. Omit projected edges shorter
than 1e−6 mm; reject a view with no surviving edges. Bounds enclose surviving
segments. Drawing v remains up; only the SVG renderer flips v. Current output
has `schema_version: 1`, units, view, `render_mode: "wireframe"`, bounds and edges.
No visible/hidden classification is implied by edge inclusion.

## Isometric projection — planned

Use an orthonormal basis `u=(1,−1,0)/sqrt(2)`,
`v=(−1,−1,2)/sqrt(6)` and depth `w=(1,1,1)/sqrt(3)`.
Offer named camera octants by explicit basis changes, never Euler-angle guessing.
Keep geometry in true mm; scale only during viewport placement. Golden tests must
compare projected cube directions, equal axis lengths and mirrored instances.

## Section views and clipping — planned

Section plane record: world-mm unit normal n, signed offset d, keep-side and
scope. Transform local plane normals with inverse-transpose (including mirrors)
and renormalize. Reject singular transforms. Clip face polygons and segments in
3D before projection using a shared mm tolerance. Generate intersection segments,
weld endpoints within a documented tolerance and assemble closed loops; open
contours are diagnostics, not automatically filled regions. Distinguish cut outlines,
background geometry and hatch regions. Preserve holes and coplanar faces. Tests:
box cut, hole, grazing plane, nested transformed plane and empty result.

## Hidden-edge classification and line rendering — planned

The wireframe slice is not a substitute for this stage. Extend the snapshot with
triangulated faces, normals, material opacity and provenance. Project candidate
edges and occluder triangles, index 2D bounds spatially, split edges at triangle
boundary intersections, compare interpolated depth at each interval with a shared
tolerance, and classify visible/occluded/coplanar intervals. Exclude incident faces
from self-occlusion carefully. Section cap faces must also occlude. Keep independent
policies for silhouettes, feature edges, creases, coplanar seams and soft edges.
Transparent materials need an explicit per-document policy. Deterministic source
ordering must resolve ties. Use line roles (visible, hidden, cut, dimension, hatch),
not hard-coded colors. Hidden lines use physical-paper dash patterns; preview
and exporters share the same style table. Test overlapping boxes, partial occlusion,
coincident faces, through-holes and tolerance boundaries before calling it technical
hidden-line output. Performance must be benchmarked against real furniture models.

## Dimensions — planned

Annotation records reference source anchors plus resolved mm positions. Support
linear aligned, horizontal and vertical measurements first; angle/radius follow.
Manual dimensions select anchors in the projected view, retain source associations
and report orphaned references after model changes. Measurement uses world geometry,
not scaled paper distances. Automatic dimensions first compute overall bounds then
furniture-specific chains with configurable duplicate suppression, minimum length,
clearance and collision rules. Do not guess manufacturing intent from a bounding
box. Store placement offsets in paper mm and values in model mm. Round only formatted
text with document unit/precision rules. Test scale independence, negative axes,
mirrors, near-zero spans, collisions and orphan recovery. Do not create native model
dimensions as a side effect of document drafting.

## Paper, scales and templates — planned

Document owns unit, format version, styles and ordered sheets. Sheet owns paper
width/height in mm, margins, title block and viewports. Initial ISO A4/A3 and custom
sizes must support portrait/landscape. Scale is a positive rational model:paper
ratio (1:10 means one model mm becomes 0.1 paper mm). A viewport contains view basis,
source selection reference, crop, paper rectangle, placement and scale. Fit-to-sheet
is an explicit command and never silently changes a prescribed drawing scale.
Templates contain declarative frames/fields only; no executable Ruby/JavaScript.
Validate printable area and text overflow. Render a known 1000 mm part at 1:10 as
100 paper mm in export tests.

## Multi-sheet management — planned

Use stable document/sheet/viewport UUIDs and immutable command transactions for
add/delete/reorder/duplicate/rename. Validate references and unique IDs on every
load. Persist versioned JSON in an extension-owned model attribute dictionary only
on explicit save within a SketchUp undo operation, with an external JSON export for
recovery. Keep geometry caches outside document data and key them by model revision,
source path, view and clipping options. Define schema migrations with fixtures;
reject newer unsupported formats without overwriting them. Save atomically to a
temporary sibling file then rename for external documents. Reopen must preserve
sheet order, placements, annotations and source references.

## Furniture recognition and statistics — planned

Recognition is opt-in semantic enrichment: inspect instance attributes and user
assigned categories first, then definition names and measured geometry as hints.
Report confidence and provenance; never label a part definitively from its name.
Handle repeated/nested instances, mirrored handedness, grain direction, panel
thickness and hardware separately. Distinguish definition counts from instance
counts and visible selection from whole-model inventory. Statistics use transformed
face areas, watertight-solid volume only when valid, and effective face/instance
material inheritance. Nonuniform scale prevents a single scale-factor area shortcut.
Never report volume for open shells. Units: mm, mm², mm³; UI may format m²/m³ at the
boundary. Test panel assemblies, repeated hardware, painted parent instances,
non-solid components and ambiguous categories.

## PDF and DXF export — planned

Both exporters consume sheet-space drawing primitives, never SVG screenshots or
live SketchUp entities. Preflight validates finite coordinates, page dimensions,
fonts, line roles, scale and annotation references. Export all selected sheets as
one transaction to a chosen path; temporary output is removed on failure and
existing output is replaced only after complete success. No export commands exist
in the current UI.

PDF backend decision is deferred: evaluate a licensed, Ruby-2.7-compatible vector
writer versus the installed LayOut API in a supported host workflow. Map mm to
points by 72/25.4, embed approved fonts, preserve vector strokes/text and page boxes.
LayOut integration cannot be assumed available inside SketchUp. Verify physical
scale using parsed PDF geometry and print checks, not just file existence.

DXF starts with a documented ASCII version (evaluate R2010), mm `$INSUNITS=4`, line
role layers, LINE/LWPOLYLINE/TEXT primitives and explicit per-sheet files or paper
space layouts. Dimension entities require separate interoperability testing;
exploded graphics must be labeled as such. Verify output using an independent
reader and reference CAD application. Include round-trip fixtures, encoding,
origin and extent checks. Third-party backend dependencies require licensing,
checksum and embedded-runtime compatibility review before adoption.

## UI/Ruby communication, validation and recovery — implemented foundation

One local HtmlDialog, one `preview` callback, request
`{schema_version:1, view:"front"}`. Limit request JSON to 1024 bytes; validate root,
version and view before accessing the model. Ruby replies `{ok:true,drawing:...}`
or `{ok:false,error:...}` through double JSON encoding, never code interpolation
of raw labels. Browser validates units, bounds and finite segment endpoints before
building SVG nodes with `createElementNS`. All text uses textContent. CSP disallows
remote resources. No HTML from the model is rendered. Disable the request button
until a result or 30-second timeout; timeout cannot cancel a blocked host operation.
Current callbacks are synchronous and one dialog is used. If workers or multiple
requests are introduced, add request IDs, stale response rejection and cancellation
before enabling them. Closing the dialog clears its reference; reopening rebinds
callbacks. The host owns dialog lifetime and retains a controller reference.

Expected validation errors display actionable text; unexpected exceptions rotate
a local log (three backups, 1 MiB each) and return a generic message. Logs may contain
file paths and must be reviewed before sharing. Preview does not open undo
operations or mutate models. Future document edits need commit/rollback semantics.
Never catch fatal exceptions or disable host security policy. Failed requests clear
stale drawing output. Models switching while a dialog is open are read afresh per
request. Observer-driven automatic refresh is intentionally deferred.

## Acceptance and release gates

Automated tests must cover nested noncommuting transforms, mirrors, units, all six
views, degeneracy, visibility, recursive definitions, duplicate selection paths,
invalid bridge payloads, rendering and safe transport. Host manual cases and
supported OS/version records are in compatibility.md. Before release: owner-approved
license, runtime matrix, UI lifecycle testing, performance benchmarks and verified
package structure. Roadmap modules are directories with explicit scope documents,
not empty classes pretending to implement functionality.
