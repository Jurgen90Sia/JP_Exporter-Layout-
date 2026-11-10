require 'minitest/autorun'
require_relative 'support/sketchup_mock'
require_relative '../jp_exporter_layout/geometry/extractor'
require_relative '../jp_exporter_layout/core'
class ExtractionTest < Minitest::Test
  def test_face_mesh_is_optional_and_transformed_once_with_mirrored_instances
    face = Sketchup::Face.new([])
    face.define_singleton_method(:entityID) { 80 }
    mesh = Object.new
    mesh.define_singleton_method(:polygons) { [[1,-2,3]] }
    mesh.define_singleton_method(:point_at) { |i| Geom::Point.new(*[[0,0,0],[1,0,0],[0,1,0]][i-1]) }
    face.define_singleton_method(:mesh) { |_flags| mesh }
    instance = Sketchup::ComponentInstance.new(2,Sketchup::Definition.new([face]),Geom::Transformation.new([-1,2,1],[10,0,0]))
    s = JPExporter::Layout::Geometry::Extractor.new.call([instance],Geom::Transformation.new,include_faces:true)
    assert_equal 1,s[:triangles].length
    assert_equal [[254.0,0.0,0.0],[228.6,0.0,0.0],[254.0,50.8,0.0]],s[:triangles][0][:points]
    refute extract([instance]).key?(:triangles)
  end
  def edge(id = 1)
    Sketchup::Edge.new(id, [0,0,0], [1,2,3])
  end
  def extract(entities, transform = Geom::Transformation.new)
    JPExporter::Layout::Geometry::Extractor.new.call(entities, transform)
  end
  def test_nested_scale_translation_and_inches_to_mm
    inner = Sketchup::Group.new(2, Sketchup::Definition.new([edge]),
                               Geom::Transformation.new([2,-1,3],[1,0,0]))
    outer = Sketchup::ComponentInstance.new(3, Sketchup::Definition.new([inner]),
                                            Geom::Transformation.new([1,2,1],[10,0,0]))
    snapshot = extract([outer], Geom::Transformation.new([1,1,1],[0,5,0]))
    assert_equal [279.4,127.0,0.0], snapshot[:edges][0][:points][0]
    assert_equal [330.2,25.4,228.6], snapshot[:edges][0][:points][1]
    result = JPExporter::Layout::Projection.call(snapshot, 'front')
    assert_equal [330.2,228.6], result[:edges][0][:points][1]
  end
  def test_reused_definitions_are_not_deduplicated_across_instances
    definition = Sketchup::Definition.new([edge])
    snapshot = extract([Sketchup::ComponentInstance.new(2,definition,Geom::Transformation.new),
                        Sketchup::ComponentInstance.new(3,definition,Geom::Transformation.new)])
    assert_equal 2, snapshot[:edges].length
    refute_equal snapshot[:edges][0][:id], snapshot[:edges][1][:id]
  end
  def test_shared_edges_are_deduplicated_within_context
    e = edge
    assert_equal 1, extract([e, Sketchup::Face.new([e])])[:edges].length
  end
  def test_hidden_edges_are_excluded
    assert_empty extract([Sketchup::Edge.new(1,[0,0,0],[1,0,0],true)])[:edges]
  end
  def test_recursive_definitions_raise_without_hanging
    definition = Sketchup::Definition.new([])
    instance = Sketchup::ComponentInstance.new(2,definition,Geom::Transformation.new)
    definition.entities << instance
    assert_raises(JPExporter::Layout::ValidationError) { extract([instance]) }
  end
  def test_budget_raises_instead_of_partial_drawing
    extractor = JPExporter::Layout::Geometry::Extractor.new(1)
    assert_raises(JPExporter::Layout::ValidationError) { extractor.call([edge(1),edge(2)],Geom::Transformation.new) }
  end
  def test_rotation_composed_before_parent_translation
    rotation = Geom::Transformation.new(nil,nil,[[0,-1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]])
    instance = Sketchup::ComponentInstance.new(2,Sketchup::Definition.new([edge]),rotation)
    result = extract([instance],Geom::Transformation.new([1,1,1],[10,0,0]))
    assert_equal [254.0,0.0,0.0],result[:edges][0][:points][0]
    [203.2,25.4,76.2].zip(result[:edges][0][:points][1]).each { |a,b| assert_in_delta a,b,0.000001 }
  end
  def test_tag_invisible_parent_suppresses_children
    instance = Sketchup::ComponentInstance.new(2,Sketchup::Definition.new([edge]),Geom::Transformation.new)
    def instance.layer; Struct.new(:visible?).new(false); end
    assert_empty extract([instance])[:edges]
  end
  def test_furniture_panel_bounds_for_each_view
    vertices = [[0,0,0],[600,0,0],[600,400,0],[0,400,0],
                [0,0,18],[600,0,18],[600,400,18],[0,400,18]]
    pairs = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
    edges = pairs.each_with_index.map do |(a,b),id|
      Sketchup::Edge.new(id,vertices[a].map { |n| n/25.4 },vertices[b].map { |n| n/25.4 })
    end
    snapshot = extract(edges)
    expected = {'front'=>[600,18],'rear'=>[600,18],'left'=>[400,18],
                'right'=>[400,18],'top'=>[600,400],'bottom'=>[600,400]}
    expected.each do |view,size|
      drawing = JPExporter::Layout::Projection.call(snapshot,view)
      bounds = drawing[:bounds]
      assert_in_delta size[0],bounds[2]-bounds[0],0.000001
      assert_in_delta size[1],bounds[3]-bounds[1],0.000001
      assert_equal 8,drawing[:edges].length
    end
  end

  def test_hidden_ancestor_tag_folder_suppresses_enabled_tag
    e = edge
    folder_class = Struct.new(:visible?, :folder)
    parent = folder_class.new(false,nil)
    child = folder_class.new(true,parent)
    tag = folder_class.new(true,child)
    e.define_singleton_method(:layer) { tag }
    assert_empty extract([e])[:edges]
    parent[0] = true
    assert_equal 1,extract([e])[:edges].length
  end

end
