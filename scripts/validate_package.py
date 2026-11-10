#!/usr/bin/env python3
"""Validate the install manifest without creating a release archive."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ["jp_exporter_layout.rb", "jp_exporter_layout/version.rb",
            "jp_exporter_layout/main.rb", "jp_exporter_layout/core.rb",
            "jp_exporter_layout/geometry/extractor.rb", "jp_exporter_layout/ui/dialog.rb",
            "jp_exporter_layout/ui/index.html", "jp_exporter_layout/ui/preview.js",
            "jp_exporter_layout/ui/style.css", "jp_exporter_layout/diagnostics.rb",
            "jp_exporter_layout/drawing.rb", "jp_exporter_layout/atomic_file.rb",
            "jp_exporter_layout/dimensions/overall.rb", "jp_exporter_layout/exporters/dxf.rb",
            "jp_exporter_layout/project_snapshot.rb", "jp_exporter_layout/projection/hidden_line.rb"]

def validate(root):
    for name in REQUIRED:
        path = root / name
        if not path.is_file() or not path.read_bytes():
            raise ValueError("Missing or empty runtime file: " + name)
    files = [root / "jp_exporter_layout.rb"] + sorted((root / "jp_exporter_layout").rglob("*"))
    for path in files:
        if path.is_symlink():
            raise ValueError("Symlinks are not allowed in packages: " + str(path))
        if path.is_file() and path.suffix not in {".rb", ".js", ".css", ".html", ".md", ".svg", ".png"}:
            raise ValueError("Unexpected runtime artifact: " + str(path))
    version = (root / "jp_exporter_layout/version.rb").read_text()
    if not re.search(r"VERSION = '[0-9]+\.[0-9]+\.[0-9]+'", version):
        raise ValueError("Invalid version declaration")
    if "'jp_exporter_layout/main'" not in (root / "jp_exporter_layout.rb").read_text():
        raise ValueError("Invalid extension registration path")
    for asset in ['style.css', 'preview.js']:
        if asset not in (root / 'jp_exporter_layout/ui/index.html').read_text():
            raise ValueError("Missing UI asset reference: " + asset)
    return [path.relative_to(root).as_posix() for path in files if path.is_file()]

if __name__ == '__main__':
    manifest = validate(ROOT)
    print("Package structure valid: %d files, two top-level entries; no RBZ created." % len(manifest))
