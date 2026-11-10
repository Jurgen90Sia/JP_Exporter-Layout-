require 'minitest/autorun'
require 'tmpdir'
require_relative '../jp_exporter_layout/core'

class OutputTest < Minitest::Test
  Core = JPExporter::Layout
  def drawing
    Core::Projection.call({units:'mm',edges:[{id:'a',points:[[-100,0,-20],[500,0,800]]}]},'front')
  end
  def test_dxf_preserves_negative_model_mm_and_explains_dimension_representation
    require_relative '../jp_exporter_layout/exporters/dxf'
    text = Core::Exporters::DXF.generate(drawing)
    pairs = text.lines.map(&:strip).each_slice(2).to_a
    assert_includes pairs, ['9','$INSUNITS']
    assert_includes pairs, ['70','4']
    assert_includes pairs, ['10','-100.0']
    assert_includes pairs, ['21','800.0']
    assert_equal 1, (pairs.count { |pair| pair == ['0','LINE'] })
    assert_equal ['0','EOF'], pairs.last
  end
  def test_snapshot_roundtrip_is_validated_and_unknown_versions_rejected
    require_relative '../jp_exporter_layout/project_snapshot'
    Dir.mktmpdir do |dir|
      path = File.join(dir,'test.jpdraw')
      Core::ProjectSnapshot.save(path,drawing)
      loaded = Core::ProjectSnapshot.open(path)
      assert_equal drawing[:bounds], loaded[:bounds]
      assert_equal drawing[:edges], loaded[:edges]
      File.write(path,'{"schema_version":99,"drawing":{}}')
      assert_raises(Core::ValidationError) { Core::ProjectSnapshot.open(path) }
      File.write(path,'[1,2]')
      assert_raises(Core::ValidationError) { Core::ProjectSnapshot.open(path) }
    end
  end
  def test_invalid_drawing_does_not_replace_existing_file
    require_relative '../jp_exporter_layout/project_snapshot'
    Dir.mktmpdir do |dir|
      path = File.join(dir,'keep.jpdraw')
      File.write(path,'keep')
      bad = drawing.merge(edges:[{points:[[Float::INFINITY,0],[1,1]]}])
      assert_raises(Core::ValidationError) { Core::ProjectSnapshot.save(path,bad) }
      assert_equal 'keep',File.read(path)
      assert_equal ['keep.jpdraw'],Dir.children(dir)
    end
  end
  def test_dxf_dimensions_are_measured_values_and_graphics_not_dimension_entities
    require_relative '../jp_exporter_layout/exporters/dxf'
    require_relative '../jp_exporter_layout/dimensions/overall'
    d = drawing
    d[:dimensions] = Core::Dimensions::Overall.call(d)
    pairs = Core::Exporters::DXF.generate(d).lines.map(&:strip).each_slice(2).to_a
    assert_includes pairs,['1','600 mm']
    assert_includes pairs,['1','820 mm']
    assert_equal 2,(pairs.count { |p| p == ['0','TEXT'] })
    refute_includes pairs,['0','DIMENSION']
  end
  def test_snapshot_rejects_dimensions_whose_measurement_or_text_disagrees_with_anchors
    require_relative '../jp_exporter_layout/drawing'
    require_relative '../jp_exporter_layout/dimensions/overall'
    d = drawing
    d[:dimensions] = Core::Dimensions::Overall.call(d)
    d[:dimensions][0][:value_mm] = 5
    assert_raises(Core::ValidationError) { Core::Drawing.validate!(d) }
    d[:dimensions] = Core::Dimensions::Overall.call(d)
    d[:dimensions][0][:text] = '5 mm'
    assert_raises(Core::ValidationError) { Core::Drawing.validate!(d) }
  end
  def test_dxf_unicode_uses_utf16_surrogates_for_supplementary_characters
    require_relative '../jp_exporter_layout/exporters/dxf'
    assert_equal 'P\\U+00EBrmas\\U+00EB\\U+D83D\\U+DE00',Core::Exporters::DXF.ascii_text("Përmasë😀")
  end
end
