#!/usr/bin/env python3
"""Small explicit safety checks; complements Ruby Lint and syntax checks."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
errors = []
for path in (root / 'jp_exporter_layout').rglob('*'):
    if not path.is_file() or path.suffix not in {'.rb', '.js', '.html'}:
        continue
    text = path.read_text()
    patterns = [r'\beval\s*\(', r'\bdocument\.write\s*\(', r'\.innerHTML\s*=',
                r'<script[^>]+src=["\']https?://']
    for pattern in patterns:
        if re.search(pattern, text):
            errors.append(str(path.relative_to(root)) + ': disallowed dynamic code/HTML or remote script')
if errors:
    raise SystemExit('\n'.join(errors))
print('Basic source safety checks passed (not a security audit).')
