# Source evidence — 2026-11-10

Only public descriptions and API documentation were used; no proprietary downloads/code/assets.

| ID | Source | Evidence and limit |
|---|---|---|
| LU | https://lustudio.vn/plugins/layout-exporter | Official product page: selected groups/components; orthographic/section/3-quarter views; linked editable viewports; native dimensions; scale/arrangement; batch; LayOut/PDF; retain model_Data folder. Product description, not inspected button labels. |
| CAD | https://lustudio.vn/plugins/cad-exporter | Separate product: seven projections, hidden-line filtering, scaled dimensions and DXF. Do not count these automatically as LayOut Exporter parity. |
| VIDEO | https://www.youtube.com/embed/videoseries?list=PLe2r1dYOkQhk | Exact tutorial link returned by official LU page. Fetch failed: Cache miss. No frames, audio or transcript inspected. Exact UI labels/interactions UNKNOWN. Search did not resolve an inspectable tutorial. |
| API | https://ruby.sketchup.com/file.LayOut.html | LayOut Ruby API runs inside SketchUp; 2D paper units inches, y downward. |
| DOC | https://ruby.sketchup.com/Layout/Document.html | New/open/save documents, pages, entities and export; PDF support documented from 2020.1. |
| VIEW | https://ruby.sketchup.com/Layout/SketchUpModel.html | Linked model path/bounds, view, perspective, scale, render and model-to-paper conversion. |
| DIM | https://ruby.sketchup.com/Layout/LinearDimension.html | Native linear dimensions; native behavior must be tested separately from SVG. |
| PRINT | https://help.sketchup.com/en/create-pdf | Official multi-page PDF workflow. |
| EXAMPLES | https://extensions.sketchup.com/developers/layout_c_api/layout/index.html | Official SDK example descriptions. No code imported or license assumed. |
| ISSUE | https://github.com/SketchUp/api-issue-tracker/issues/589 | Vendor issue tracker describes viewport creation/deletion instability; not proof of current version behavior. |

Searches included official tutorials, YouTube demonstrations, community API discussions and official GitHub examples. No accessible independent LU review or licensed reusable algorithm was adopted. Public marketing is evidence of advertised outcomes, not independent verification of accuracy.
