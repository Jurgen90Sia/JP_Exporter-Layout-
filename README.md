# JP Exporter Layout

Original SketchUp extension foundation for technical drawing workflows.
**Development version 0.2.0. Not a production release.** No proprietary plugin
source, assets, or private formats are used.

## Working workflow

Select edges, faces, groups or component instances in SketchUp. Open
**Extensions → JP Exporter Layout — Preview**, choose a view and click
**Preview current selection**. Coordinates are extracted in model space,
converted from SketchUp inches to millimeters, projected, and displayed as SVG.
The views are front, rear, left, right, top, bottom and isometric. Preview uses the
current selection on each click, including the active editing transformation.

The default preview remains **wireframe**: occluded edges are included; hidden entities and
invisible tags are excluded. Unsupported entity types are ignored. Faces supply
their boundary edges; curves are represented by their SketchUp edge segments.
Optional **Visible lines** and **Visible + dashed hidden lines** modes triangulate
selected faces and split edge intervals against real triangle depth. Every face is
treated as opaque. Select faces/groups/components containing faces; edge-only
selections cannot supply occluders. Budget: 40,000 triangles, one million
edge/triangle comparisons and 20,000 output segments. Large assemblies receive an
explicit error rather than a partial result. Transparency, sections, silhouettes,
coplanar seam merging and soft/mesh-edge filtering are not implemented.

Enable **Overall dimensions** then generate a preview for horizontal/vertical mm
measurements. Annotation scale controls physical offset/text sizing; it does not
change geometry units. Isometric dimensions are rejected because projected bounds
are not physical part dimensions. These dimensions are 2D graphics without source
associations; manual dimensions and collision avoidance remain future work.

**Export drawing DXF** saves ASCII R2000 model-space mm LINE/TEXT with geometry,
hidden-line and dimension layers. Dimension graphics are exploded, not native CAD
DIMENSION entities. No paper-space layouts or closed-polyline reconstruction yet.
**Save/Open drawing snapshot** stores validated versioned `.jpdraw` JSON, including
the displayed drawing and annotations. It does not retain model selection, sheets
or associations; it is not the full project persistence system. File writes use a
temporary sibling and replacement after success. **Fit drawing** restores framing.

No source model modifications, sheets, PDF or native editable LayOut export exist
yet. See docs/execution-report.md for evidence and remaining work.

## Development

Requirements: Ruby 2.7+ with Minitest 5.x, Node.js 20+, Python 3. No npm packages
or runtime Ruby gems are needed. Install test tooling with
`gem install minitest -v 5.25.5 --no-document`.

```sh
ruby -Itest -e 'Dir["test/*_test.rb"].sort.each { |f| require File.expand_path(f) }'
node --test test/ui_test.js
python scripts/validate_package.py
python scripts/static_check.py
```

Run packaging regression tests with `python3 -m unittest discover -s test -p "*_test.py"`.

Run Ruby syntax checks with `ruby scripts/check_syntax.rb`. CI also runs RuboCop
Lint using the committed configuration (`gem install rubocop -v 1.39.0 --no-document`, then `rubocop`). Ruby 2.7 syntax is the baseline for the
SketchUp 2021 target. Cloud Ruby/Node tests use API contract doubles and cannot
validate SketchUp itself. See [compatibility](docs/compatibility.md) and
[architecture](docs/architecture.md).

## Load for host testing

Copy **both** `jp_exporter_layout.rb` and the complete `jp_exporter_layout/`
directory into a development SketchUp Plugins folder. Restart SketchUp and
check Extension Manager and the Extensions menu. Do not copy tests or docs into
Plugins. Unsigned development code may require the appropriate host loading
policy. Do not lower a user's security settings automatically.

Package validation checks this two-entry extension structure without generating
an RBZ. No RBZ release is supplied. Runtime validation on Windows/macOS and
license selection remain release gates.

## Project map

- `jp_exporter_layout/geometry/`: SketchUp extraction adapter.
- `core.rb` and `projection/`: projection core and future projection services.
- `ui/`: HtmlDialog controller, HTML/CSS and SVG rendering.
- `layout/`, `dimensions/`, `sheets/`, `exporters/`: specified future subsystems.
- `test/`: pure Ruby, host contract and JavaScript tests.
- `docs/`: technical specifications, compatibility and release gates.
- `scripts/` and `.github/workflows/`: checks and package validation.

Diagnostics rotate in the OS temporary directory as `jp_exporter_layout.log`.
Logs contain exception details; review them before sharing. See LICENSE before
redistribution. Contributions follow [CONTRIBUTING.md](CONTRIBUTING.md).
