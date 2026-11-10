"""Optional independent integration test; install ezdxf==1.4.5 and Ruby to run."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

try:
    import ezdxf
except ImportError:
    ezdxf = None

ROOT = Path(__file__).resolve().parents[1]
RUBY = os.environ.get('JP_TEST_RUBY') or shutil.which('ruby')

@unittest.skipUnless(ezdxf is not None and RUBY, 'Independent DXF test needs ezdxf and Ruby')
class DxfReaderTest(unittest.TestCase):
    def test_model_mm_dimensions_layers_and_structure_need_no_repairs(self):
        script = '''
require_relative 'jp_exporter_layout/exporters/dxf'
require_relative 'jp_exporter_layout/dimensions/overall'
d = JPExporter::Layout::Projection.call({units:'mm',edges:[
  {id:'panel',points:[[-100,0,-20],[500,0,800]]}]},'front')
d[:dimensions] = JPExporter::Layout::Dimensions::Overall.call(d,scale:0.1)
d[:edges][0][:role] = 'hidden'
JPExporter::Layout::Exporters::DXF.save(ARGV[0],d)
'''
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'drawing.dxf'
            subprocess.run([RUBY, '-e', script, str(path)], cwd=ROOT, check=True, capture_output=True)
            drawing = ezdxf.readfile(path)
            audit = drawing.audit()
            self.assertEqual([], audit.errors)
            self.assertEqual([], audit.fixes)
            self.assertEqual('AC1015', drawing.dxfversion)
            self.assertEqual(4, drawing.units)
            model = drawing.modelspace()
            hidden = list(model.query('LINE[layer=="JP_HIDDEN"]'))
            self.assertEqual(1, len(hidden))
            self.assertAlmostEqual(-100, hidden[0].dxf.start.x)
            self.assertAlmostEqual(800, hidden[0].dxf.end.y)
            self.assertEqual('JP_DASHED', drawing.layers.get('JP_HIDDEN').dxf.linetype)
            texts = list(model.query('TEXT'))
            self.assertEqual(['600 mm', '820 mm'], [t.dxf.text for t in texts])
            self.assertTrue(all(t.dxf.height == 30 for t in texts))
            self.assertEqual(0, len(model.query('DIMENSION')))
