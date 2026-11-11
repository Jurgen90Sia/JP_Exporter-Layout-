# Official tutorial evidence — 2026-11-10

Original independent JP implementation only. Official channel:
https://www.youtube.com/@lustudio99. Valid playlist:
https://www.youtube.com/playlist?list=PLe2r1dYOkQhk, linked by
https://lustudio.vn/plugins/layout-exporter. The short playlist ID was not a
truncation. Direct public HTML retrieval recovered video descriptions and public
storyboards after the web fetcher returned cache misses. Caption metadata existed,
but timed-text requests returned empty bodies. No complete transcript or full
video viewing is claimed. Descriptions establish advertised behavior, not accuracy.

| Source | Confirmed vendor description; JP requirement | JP status |
|---|---|---|
| https://www.youtube.com/watch?v=X2hFObJb1l4 — v3.1, 2:14 | **Trích chi tiết**: select a region, create enlarged detail, place on page; auto dimensions move with detail; additional manual dimensions | OPEN |
| https://www.youtube.com/watch?v=Y81yYePkhNk — v3.0, 2:42 | Modes **Màu**, **Đen trắng**, **Thang xám**, **Vector**; first three image modes offer **Nét cao**; section hatch style/color/display configurable | OPEN; experimental JP native vector output alone is not four-mode parity |
| https://www.youtube.com/watch?v=QJjvwY2csUI — v3.0, 2:40 | In **Dàn trang**: manual/whole-chain dimensions, alignment to existing rows, select/edit/delete dimensions, arrow annotations, standalone text/frame adjustment, eraser | OPEN; existing JP overall graphics are not this editor |
| https://www.youtube.com/watch?v=8RyxaL6gMEQ — v3.0, 2:54 | Assign doors a Tag; **Mặt đứng bỏ cánh**, choose hidden Tag; multiple L/U cabinet elevations, optional individual pages, automatic dimensions | OPEN |
| https://www.youtube.com/watch?v=HwWXNw2AUyI — v2.8, 3:08 | Manual page splitting, add/remove projections, move projections between pages, reposition layouts | OPEN; JP deterministic grid is only a foundation |
| https://www.youtube.com/watch?v=0m_tAWbHeEM — v2.7, 4:13 | Section-position indicators, font/size, logo sizing, batch enable/disable sections | OPEN |
| https://www.youtube.com/watch?v=NmdHf0cZubA — v2.5.5, 1:59 | Vendor example: 15 objects/pages in about 3m30; editable LayOut/PDF, plan/elevation/side/section/perspective/basic dimensions | OPEN; vendor timing is not a JP benchmark |
| https://www.youtube.com/watch?v=uksRNV7PIxo — base export, 2:45 | Base workflow reference; no additional control details reliably recovered | UNKNOWN details |
| https://www.youtube.com/watch?v=2I81WP1Pcuk — 1:20 | LayOut's native Style Tool, shortcut B, samples dimension styling | Not an exporter-specific sync command; do not invent one |

Actual visual samples: render/hatch video approximately 72–88 seconds, showing
dimensioned cabinet linework and overlays CHUYỂN VECTOR, ZOOM THOẢI MÁI,
NÉT VẪN GỌN, DIM CHI TIẾT. Arrangement video approximately 90–106 seconds,
showing cabinet projections and a page with several views. These were sampled
storyboard frames; resolution was insufficient to transcribe small controls.
No timestamp is assigned to description-only evidence.

Still unknown: complete menu labels/defaults, preset/template names/count/schema,
render-mode native/image internals, dimension association semantics, complete
section controls, handling of difficult source geometry and performance envelope.
Do not convert those unknowns into presumed copied behavior. Next research should
inspect individual workflow sequences at legible resolution and record input,
action, parameters, result and host separately for every feature.
