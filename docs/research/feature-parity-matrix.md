# Feature parity matrix

Denominator: six official LU capability headings in command-inventory.md. COMPLETE requires connected implementation, automated verification and real host verification. Partial components earn no completed-feature credit. CAD Exporter and JP enhancements are excluded.

| Verified LU capability | JP module/UI | Status | Tests / runtime / limitations |
|---|---|---|---|
| Technical view set | core.rb, projection/hidden_line.rb, preview | PARTIAL | Six orthographic + iso; optional opaque intervals; missing sections/perspective/full classification; new host runtime blocked |
| Native LayOut viewports | layout/source_export.rb, document_export.rb, package_export.rb; experimental UI | PARTIAL / HOST PENDING | Four linked vector viewports per object implemented against official API; only contract doubles run |
| Automatic scale and layout | sheets/plan.rb, SVG sheet UI, native adapter | PARTIAL | ISO paper/shared scale/grid tested; native camera framing and richer page editing remain open |
| Automatic dimensions | dimensions/overall.rb, preview checkbox | PARTIAL | Orthographic overall graphics implemented; do not satisfy native LayOut outcome |
| Batch export | Native package command | PARTIAL / HOST PENDING | One page and source file per selected group/component; native end-to-end not run |
| LayOut file and PDF | Native document adapter | PARTIAL / HOST PENDING | Save/reopen/page-count/PDF-signature logic contract-tested; no real native file or inspected PDF yet |

Verified complete parity: **0/6 = 0%**. This measures strict end-to-end parity, not the usefulness of the working preview. See validation and execution report for new JP enhancements and actual test results.

The six headings are the historical benchmark, not a claim that LU has only six
commands. Newly recovered workflows in video-workflows.md are additional OPEN
requirements: detail extraction, four display modes, hatch, manual/chain dimensions,
text/arrows/eraser, door-tag hiding, free arrangement, section markers and branding.
