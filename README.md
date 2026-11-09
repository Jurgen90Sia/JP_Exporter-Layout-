# JP Exporter Layout

Original SketchUp extension foundation for technical drawing workflows.
**Development version 0.1.0. Not a production release.** No proprietary plugin
source, assets, or private formats are used.

## Working workflow

Select edges, faces, groups or component instances in SketchUp. Open
**Extensions → JP Exporter Layout — Preview**, choose a view and click
**Preview current selection**. Coordinates are extracted in model space,
converted from SketchUp inches to millimeters, projected, and displayed as SVG.
The six views are front, rear, left, right, top and bottom. Preview uses the
current selection on each click, including the active editing transformation.

The preview is **wireframe**: occluded edges are included; hidden entities and
invisible tags are excluded. Unsupported entity types are ignored. Faces supply
their boundary edges; curves are represented by their SketchUp edge segments.
No model modifications, automatic dimensions, sheets, PDF or DXF commands exist yet.

## Development

Requirements: Ruby 2.7+ with Minitest 5.x, Node.js 20+, Python 3. No npm packages
or runtime Ruby gems are needed. Install test tooling with
`gem install minitest -v 5.25.5 --no-document`.

```sh
ruby -Itest -e 'Dir["test/*_test.rb"].sort.each { |f| require_relative f }'
node --test test/*_test.js
python3 scripts/validate_package.py
python3 scripts/static_check.py
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
