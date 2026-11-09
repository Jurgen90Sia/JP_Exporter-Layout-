import importlib.util
import tempfile
import shutil
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('validator', ROOT / 'scripts/validate_package.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

class PackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copy(ROOT / 'jp_exporter_layout.rb', self.root)
        shutil.copytree(ROOT / 'jp_exporter_layout', self.root / 'jp_exporter_layout')

    def test_valid_runtime_manifest_excludes_development_files(self):
        files = validator.validate(self.root)
        self.assertIn('jp_exporter_layout/ui/index.html', files)
        self.assertFalse(any(f.startswith(('test/', 'docs/', '.github/')) for f in files))

    def test_missing_loader_fails(self):
        (self.root / 'jp_exporter_layout/main.rb').unlink()
        with self.assertRaises(ValueError):
            validator.validate(self.root)

    def test_symlink_fails(self):
        (self.root / 'jp_exporter_layout/external.rb').symlink_to('/tmp')
        with self.assertRaises(ValueError):
            validator.validate(self.root)

    def test_generated_artifact_fails(self):
        (self.root / 'jp_exporter_layout/output.rbz').write_text('invalid')
        with self.assertRaises(ValueError):
            validator.validate(self.root)
