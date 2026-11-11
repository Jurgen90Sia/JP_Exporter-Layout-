# Command status at audit

| Command/capability | Status | Connection |
|---|---|---|
| JP Exporter Layout — Preview | IMPLEMENTED / runtime UNVERIFIED in this session | Extensions menu → PreviewDialog.show |
| Preview current selection | IMPLEMENTED / runtime UNVERIFIED in this session | JS click → preview callback → extractor → projection → receive |
| Front/Rear/Left/Right/Top/Bottom | IMPLEMENTED | Validated view selector and projection basis |
| Occlusion, sections, dimensions, paper sheets, editor, native LayOut, furniture/material analysis, PDF/DXF, project persistence | MISSING | No enabled fake commands |

No known BROKEN preview command at baseline. Windows package checks were BROKEN independently of preview. Updated functionality is recorded in docs/execution-report.md rather than rewriting this historical audit.
