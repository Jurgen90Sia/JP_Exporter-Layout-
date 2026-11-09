require 'minitest/autorun'
require_relative '../jp_exporter_layout/core'

class CoreTest < Minitest::Test
  Core = JPExporter::Layout
  def drawing(view = 'front')
    Core::Projection.call({ units: 'mm', edges: [
      { id: 'a', points: [[0, 0, 0], [600, 400, 800]] },
      { id: 'b', points: [[600, 400, 800], [0, 400, 800]] }
    ] }, view)
  end
  def test_front_is_x_z_in_mm
    result = drawing
    assert_equal [[0.0, 0.0], [600.0, 800.0]], result[:edges][0][:points]
    assert_equal [0.0, 0.0, 600.0, 800.0], result[:bounds]
    assert_equal 'wireframe', result[:render_mode]
  end
  def test_all_six_view_orientations
    expected = {'front'=>[600,800], 'rear'=>[-600,800], 'left'=>[-400,800],
                'right'=>[400,800], 'top'=>[600,400], 'bottom'=>[600,-400]}
    expected.each { |view, point| assert_equal point, drawing(view)[:edges][0][:points][1] }
  end
  def test_rejects_invalid_view_and_units
    assert_raises(Core::ValidationError) { drawing('perspective') }
    assert_raises(Core::ValidationError) { Core::Projection.call({units: 'inches', edges: []}, 'front') }
  end
  def test_rejects_empty_or_nonfinite_geometry
    assert_raises(Core::ValidationError) { Core::Projection.call({units: 'mm', edges: []}, 'front') }
    assert_raises(Core::ValidationError) do
      Core::Projection.call({units: 'mm', edges: [{id: 'x', points: [[Float::NAN,0,0],[1,1,1]]}]}, 'front')
    end
  end
  def test_drops_edges_parallel_to_view_direction
    result = Core::Projection.call({units: 'mm', edges: [
      {id: 'depth', points: [[0,0,0],[0,9,0]]},
      {id: 'width', points: [[0,0,0],[4,0,0]]}]}, 'front')
    assert_equal ['width'], (result[:edges].map { |e| e[:id] })
  end
end
