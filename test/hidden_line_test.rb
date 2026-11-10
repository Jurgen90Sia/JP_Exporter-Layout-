require 'minitest/autorun'
require_relative '../jp_exporter_layout/core'

class HiddenLineTest < Minitest::Test
  Core = JPExporter::Layout
  def snapshot(y = 10)
    # Front camera is -Y. Triangle at Y=0 covers the middle of the edge behind it.
    {units:'mm',edges:[{id:'shelf',points:[[-2,y,1],[2,y,1]]}],
     triangles:[{points:[[-1,0,0],[1,0,0],[0,0,2]]}]}
  end
  def test_partial_occlusion_splits_edge_at_true_triangle_intersections
    require_relative '../jp_exporter_layout/projection/hidden_line'
    d = Core::HiddenLine.call(snapshot,'front','hidden')
    assert_equal %w[visible hidden visible],(d[:edges].map { |e| e[:role] })
    assert_equal [[-0.5,1.0],[0.5,1.0]],d[:edges][1][:points]
    visible = Core::HiddenLine.call(snapshot,'front','visible')
    assert_equal 2,visible[:edges].length
  end
  def test_foreground_and_coplanar_edges_are_not_hidden
    require_relative '../jp_exporter_layout/projection/hidden_line'
    [-10,0].each do |y|
      d = Core::HiddenLine.call(snapshot(y),'front','hidden')
      assert_equal ['visible'],(d[:edges].map { |e| e[:role] })
    end
  end
  def test_depth_crossing_splits_within_triangle_interior
    require_relative '../jp_exporter_layout/projection/hidden_line'
    s = snapshot
    s[:edges][0][:points] = [[-0.2,-10,1],[0.2,10,1]]
    d = Core::HiddenLine.call(s,'front','hidden')
    assert_equal %w[visible hidden],(d[:edges].map { |e| e[:role] })
    assert_in_delta 0.0,d[:edges][1][:points][0][0],0.000001
  end
  def test_missing_faces_and_excessive_work_are_actionable
    require_relative '../jp_exporter_layout/projection/hidden_line'
    s = snapshot
    s.delete(:triangles)
    assert_raises(Core::ValidationError) { Core::HiddenLine.call(s,'front','visible') }
    s = snapshot
    s[:triangles] *= 1_000_001
    assert_raises(Core::ValidationError) { Core::HiddenLine.call(s,'front','visible') }
  end
  def test_edge_on_triangle_does_not_occlude_isometric_edges_after_translation
    require_relative '../jp_exporter_layout/projection/hidden_line'
    triangle = [[3059.18915735916,3044.743591541431,1117.412761755947],
      [3158.7673489372964,3002.9004268822578,1146.2802752154282],
      [3316.0805674343947,3018.792289142047,1232.8828155938722]]
    edge = [[3152.27952333745,3067.123279401066,1175.1477886749096],
      [3222.990201456105,2996.4126012824113,1175.1477886749096]]
    s = {units:'mm',triangles:[{points:triangle}],edges:[{id:'e',points:edge}]}
    d = Core::HiddenLine.call(s,'isometric','hidden')
    assert_equal ['visible'],(d[:edges].map { |e| e[:role] })
  end
  def test_coplanar_triangle_at_large_world_coordinates_does_not_hide_its_edge
    require_relative '../jp_exporter_layout/projection/hidden_line'
    triangle = [[1000000369.4181864,1000000550.5942731,1000000609.1663915],
      [1000000138.5964772,1000000522.3761846,1000000104.9717112],
      [1000000122.8694537,1000000182.6118678,1000000637.7046473]]
    edge = [[1000000152.242434,1000000321.3394034,1000000475.0309408],
      [1000000275.5168003,1000000505.330606,1000000460.7618129]]
    d = Core::HiddenLine.call({units:'mm',triangles:[{points:triangle}],edges:[{id:'e',points:edge}]},'isometric','hidden')
    assert_equal ['visible'],(d[:edges].map { |e| e[:role] })
  end
end
