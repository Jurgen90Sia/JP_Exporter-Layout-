require 'minitest/autorun'
require 'json'
require_relative 'support/sketchup_mock'
# Isolated contract doubles: these tests do not validate the native SketchUp runtime.
module JPExporter
  module Layout
    module AnalysisDoubles
      Material = Struct.new(:persistent_id, :name)
      class Face < Sketchup::Face
        attr_reader :entityID, :material, :back_material, :calls
        attr_accessor :tag, :hidden
        def initialize(id, material = nil, back = nil)
          super([])
          @entityID, @material, @back_material, @calls = id, material, back, []
        end
        def persistent_id; entityID + 1000; end
        def valid?; true; end
        def hidden?; @hidden || false; end
        def layer; @tag; end
        def area(transform)
          @calls << transform
          a = Geom::Point.new(0,0,0).transform(transform).to_a
          b = Geom::Point.new(1,0,0).transform(transform).to_a
          c = Geom::Point.new(0,1,0).transform(transform).to_a
          u, v = b.zip(a).map { |x,y| x-y }, c.zip(a).map { |x,y| x-y }
          cross = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
          Math.sqrt(cross.inject(0) { |s,x| s+x*x })
        end
      end
      module Metadata
        attr_accessor :material
        def persistent_id; entityID + 1000; end
        def name; 'Part'; end
      end
      class Instance < Sketchup::ComponentInstance; include Metadata; end
      class Group < Sketchup::Group; include Metadata; end
      Definition = Struct.new(:entities, :name)
    end
  end
end
require_relative '../jp_exporter_layout/geometry/selection_analysis'
class AnalysisTest < Minitest::Test
  D = JPExporter::Layout::AnalysisDoubles
  def analyze(items, transform = Geom::Transformation.new, **limits)
    JPExporter::Layout::Geometry::SelectionAnalysis.new(**limits).call(items, transform)
  end
  def test_repeated_nested_instances_transform_once_and_material_precedence
    oak, red = D::Material.new(1,'Oak'), D::Material.new(2,'Red')
    face = D::Face.new(10)
    painted = D::Face.new(11,red)
    inner = D::Instance.new(20,D::Definition.new([face,painted],'Panel'),Geom::Transformation.new([-2,3,1]))
    definition = D::Definition.new([inner],'Assembly')
    a = D::Group.new(30,definition,Geom::Transformation.new([1,2,1])); a.material = oak
    b = D::Group.new(31,definition,Geom::Transformation.new)
    result = analyze([a,a,b],Geom::Transformation.new([2,1,1]))
    assert_equal [2,2,4], result.values_at(:group_count,:component_instance_count,:face_count)
    assert_equal 2,face.calls.length
    assert_in_delta 72*25.4**2,result[:front_area_mm2],1e-6
    summaries = result[:materials].to_h { |m| [m[:name],m] }
    assert_in_delta 12*25.4**2,summaries['Unpainted'][:front_area_mm2],1e-6
    assert_in_delta 36*25.4**2,summaries['Red'][:front_area_mm2],1e-6
    assert_equal [1030,1020],result[:objects][1][:path]
    assert_equal 'Assembly',result[:objects][0][:definition_name]
    assert_equal 1, JSON.parse(JSON.generate(result))['schema_version']
  end
  def test_back_material_unpainted_and_duplicate_face
    face = D::Face.new(1,nil,D::Material.new(7,'Back'))
    r = analyze([face,face])
    assert_equal 1,r[:face_count]
    assert_equal ['Unpainted','Back'],(r[:materials].map { |m| m[:name] })
    assert_in_delta 25.4**2,r[:materials][1][:back_area_mm2],1e-6
  end
  def test_active_edit_ancestor_material_is_used_but_face_paint_overrides_it
    ancestor,explicit = D::Material.new(8,'Ancestor'),D::Material.new(9,'Face')
    result = JPExporter::Layout::Geometry::SelectionAnalysis.new.call(
      [D::Face.new(1),D::Face.new(2,explicit)],Geom::Transformation.new,root_material:ancestor)
    assert_equal ['Ancestor','Face'],(result[:materials].map { |m| m[:name] })
    assert_equal 2,result[:materials][0][:back_face_count]
    assert_equal 1,result[:materials][1][:front_face_count]
  end
  def test_inherited_hidden_folder_and_hidden_faces
    face = D::Face.new(1)
    folder = Struct.new(:visible?,:folder).new(false,nil)
    face.tag = Struct.new(:visible?,:folder).new(true,folder)
    assert_equal 0,analyze([face])[:face_count]
    face.tag = nil; face.hidden = true
    assert_equal 0,analyze([face])[:face_count]
  end
  def test_cycles_and_budgets_fail_without_partial_results
    definition = D::Definition.new([],'Cycle')
    instance = D::Instance.new(2,definition,Geom::Transformation.new)
    definition.entities << instance
    assert_raises(JPExporter::Layout::ValidationError) { analyze([instance]) }
    assert_raises(JPExporter::Layout::ValidationError) { analyze([D::Face.new(1)],max_faces:0) }
    assert_raises(JPExporter::Layout::ValidationError) { analyze([D::Face.new(1)],max_entities:0) }
  end
end


class AnalysisTest
  def test_noncommuting_transform_and_child_material_override
    outer_material, inner_material = D::Material.new(1,'Same'), D::Material.new(2,'Same')
    face = D::Face.new(9)
    rotation = Geom::Transformation.new(nil,nil,[[0,-1,0,0],[0,0,-1,0],[1,0,0,0],[0,0,0,1]])
    inner = D::Instance.new(2,D::Definition.new([face],'Inner'),rotation)
    inner.material = inner_material
    outer = D::Group.new(3,D::Definition.new([inner],'Outer'),Geom::Transformation.new([2,3,5]))
    outer.material = outer_material
    result = analyze([outer],Geom::Transformation.new([7,11,13]))
    # Rotation moves the original XY face onto ZX. The root is composed once.
    assert_in_delta 14*65*25.4**2,result[:front_area_mm2],1e-6
    assert_equal [2],(result[:materials].map { |m| m[:persistent_id] })
    assert_nil face.material
    assert_same outer_material,outer.material
    assert_same inner_material,inner.material
  end
  def test_depth_limit_invalid_area_and_request_reuse
    face = D::Face.new(9)
    inner = D::Instance.new(2,D::Definition.new([face],'Inner'),Geom::Transformation.new)
    service = JPExporter::Layout::Geometry::SelectionAnalysis.new(max_depth:0)
    assert_raises(JPExporter::Layout::ValidationError) { service.call([inner],Geom::Transformation.new) }
    face.define_singleton_method(:area) { |_transform| Float::NAN }
    assert_raises(JPExporter::Layout::ValidationError) { analyze([face]) }
    result = service.call([],Geom::Transformation.new)
    assert_equal 0,result[:face_count]
    assert_equal [],result[:materials]
    refute result.key?(:volume_mm3)
  end
end
