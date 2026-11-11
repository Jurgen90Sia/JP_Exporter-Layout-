# frozen_string_literal: true
require 'minitest/autorun'
require 'tmpdir'
require_relative 'analysis_test'
require_relative '../jp_exporter_layout/layout/source_export'
require_relative '../jp_exporter_layout/layout/package_export'
require_relative 'native_layout_test'
class SourceExportTest < Minitest::Test
  class ExportDefinition
    attr_reader :entityID,:entities,:instances
    def initialize(id,fail_save=false)
      @entityID,@fail_save = id,fail_save
      @instances = []
      @entities = Object.new
      instances = @instances
      @entities.define_singleton_method(:add_instance) do |definition,transform|
        instance = Struct.new(:definition,:transformation,:material).new(definition,transform)
        instances << instance
        instance
      end
    end
    def save_as(path)
      raise IOError,'simulated source write failure' if @fail_save
      File.write(path,'SKP-contract-only')
      true
    end
  end
  class Definitions < Array
    attr_accessor :fail_save,:exported
    def add(_name)
      definition = ExportDefinition.new(999,fail_save)
      self << definition
      self.exported = definition
      definition
    end
  end
  class Model
    attr_accessor :selection,:active_path
    attr_reader :entities,:definitions,:edit_transform,:aborted
    def initialize(items,transform)
      @selection,@entities,@definitions,@edit_transform = items,[],Definitions.new,transform
    end
    def modified?; false; end
    def start_operation(*_args); @before = definitions.dup; true; end
    def abort_operation; definitions.replace(@before); @aborted = true; end
  end
  def fixture
    d = JPExporter::Layout::AnalysisDoubles
    definition = d::Definition.new([Sketchup::Edge.new(1,[0,0,0],[1,1,1])],'Part')
    group = d::Group.new(2,definition,Geom::Transformation.new([2,3,4]))
    group.material = d::Material.new(1,'Oak')
    Model.new([group],Geom::Transformation.new([5,6,7]))
  end
  def test_source_preserves_world_transform_paint_and_aborts_temporary_definition
    model = fixture
    Dir.mktmpdir do |dir|
      result = JPExporter::Layout::Native::SourceExport.call(model,dir)
      assert_equal 1,result.length
      assert File.file?(result[0][:path])
      assert model.aborted
      assert_empty model.definitions
      instance = model.definitions.exported.instances.first
      assert_equal 'Oak',instance.material.name
      point = Geom::Point.new(1,1,1).transform(instance.transformation).to_a
      assert_equal [10,18,28],point
      assert_equal [254.0,457.2,711.1999999999999],result[0][:snapshot][:edges][0][:points][1]
    end
  end
  def test_failure_always_aborts_and_does_not_leave_source_files
    model = fixture
    model.definitions.fail_save = true
    Dir.mktmpdir do |dir|
      assert_raises(IOError) { JPExporter::Layout::Native::SourceExport.call(model,dir) }
      assert model.aborted
      assert_empty model.definitions
      assert_empty Dir.children(dir)
    end
  end
  def test_incomplete_rollback_is_detected_even_when_source_save_also_fails
    model = fixture
    model.definitions.fail_save = true
    model.define_singleton_method(:abort_operation) { @aborted = true }
    Dir.mktmpdir do |dir|
      error = assert_raises(JPExporter::Layout::ValidationError) do
        JPExporter::Layout::Native::SourceExport.call(model,dir)
      end
      assert_match(/restore/,error.message)
      assert_empty Dir.children(dir)
    end
  end
  def test_package_is_complete_and_existing_directory_is_never_replaced
    Dir.mktmpdir do |parent|
      directory = File.join(parent,'new-package')
      d = NativeLayoutTest::Document.new
      api = NativeLayoutTest::API.new(Class.new(NativeLayoutTest::Document) { define_singleton_method(:new) { d } },
        NativeLayoutTest::Viewport,NativeLayoutTest::Text,NativeLayoutTest::Bounds,->(_path) { d })
      result = JPExporter::Layout::Native::PackageExport.call(fixture,directory,api:api)
      manifest = JSON.parse(File.read(File.join(directory,'JP-package.json')))
      assert_equal 'JP Exporter Layout',manifest['project']
      assert_equal 1,manifest['page_count']
      assert File.file?(File.join(directory,manifest['sources'][0]['path']))
      assert File.file?(result[:layout_path])
      assert File.file?(result[:pdf_path])
      assert_raises(JPExporter::Layout::ValidationError) do
        JPExporter::Layout::Native::PackageExport.call(fixture,directory,api:api)
      end
      assert File.file?(result[:layout_path])
    end
  end
  def test_package_failure_rolls_back_model_and_removes_only_new_package
    model = fixture
    model.definitions.fail_save = true
    Dir.mktmpdir do |parent|
      directory = File.join(parent,'failed-package')
      File.write(File.join(parent,'keep.txt'),'existing user file')
      assert_raises(IOError) { JPExporter::Layout::Native::PackageExport.call(model,directory,api:nil) }
      assert model.aborted
      refute File.exist?(directory)
      assert_equal 'existing user file',File.read(File.join(parent,'keep.txt'))
    end
  end
end
