require 'minitest/autorun'
require_relative '../jp_exporter_layout/core'

class DrawingToolsTest < Minitest::Test
  Core = JPExporter::Layout
  def snapshot
    {units: 'mm', edges: [{id: 'x', points: [[0,0,0],[100,0,0]]},
      {id: 'y', points: [[0,0,0],[0,100,0]]}, {id: 'z', points: [[0,0,0],[0,0,100]]}]}
  end
  def test_isometric_has_equal_axis_lengths_and_expected_directions
    result = Core::Projection.call(snapshot, 'isometric')
    endpoints = result[:edges].map { |e| e[:points][1] }
    endpoints.each { |p| assert_in_delta 81.64965809, Math.hypot(*p), 0.000001 }
    assert_in_delta 70.71067812, endpoints[0][0], 0.000001
    assert_in_delta(-70.71067812, endpoints[1][0], 0.000001)
    assert_in_delta 81.64965809, endpoints[2][1], 0.000001
    assert_equal 'wireframe', result[:render_mode]
  end
  def test_overall_dimensions_measure_negative_coordinates_without_scaling_values
    require_relative '../jp_exporter_layout/dimensions/overall'
    drawing = {bounds: [-100,-200,500,600], units: 'mm', view: 'front'}
    dimensions = Core::Dimensions::Overall.call(drawing, offset: 12, scale: 0.1, precision: 1)
    assert_equal [600,800], (dimensions.map { |d| d[:value_mm] })
    assert_equal ['600.0 mm','800.0 mm'], (dimensions.map { |d| d[:text] })
    assert_equal [[-100,-320.0],[500,-320.0]], dimensions[0][:line]
    assert_equal [[-220.0,-200],[-220.0,600]], dimensions[1][:line]
  end
  def test_dimensions_skip_zero_span_and_reject_invalid_settings
    require_relative '../jp_exporter_layout/dimensions/overall'
    drawing = {bounds: [0,0,100,0],units:'mm',view:'top'}
    assert_equal 1, Core::Dimensions::Overall.call(drawing).length
    [0,-1,Float::NAN].each do |scale|
      assert_raises(Core::ValidationError) { Core::Dimensions::Overall.call(drawing,scale:scale) }
    end
    assert_raises(Core::ValidationError) { Core::Dimensions::Overall.call(drawing,precision:7) }
    assert_raises(Core::ValidationError) { Core::Dimensions::Overall.call(drawing,offset:-1) }
    assert_raises(Core::ValidationError) { Core::Dimensions::Overall.call({bounds:[2,0,1,1],units:'mm'}) }
    assert_raises(Core::ValidationError) { Core::Dimensions::Overall.call(drawing.merge(view:'isometric')) }
  end
end
