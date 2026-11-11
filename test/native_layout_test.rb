# frozen_string_literal: true
require 'minitest/autorun'
require 'tmpdir'
require 'json'
require_relative '../jp_exporter_layout/layout/document_export'
class NativeLayoutTest < Minitest::Test
  # Native contract doubles only. Actual files, PDF scale and references require host checks.
  class Bounds
    attr_reader :values
    def initialize(*values); @values = values; end
  end
  class Viewport
    FRONT_VIEW=1; RIGHT_VIEW=2; TOP_VIEW=3; ISO_VIEW=4
    BACK_VIEW=5; LEFT_VIEW=6; BOTTOM_VIEW=7; VECTOR_RENDER=8
    attr_accessor :view,:perspective,:scale,:render_mode,:preserve_scale_on_resize
    attr_reader :path,:bounds
    def initialize(path,bounds); @path,@bounds = path,bounds; end
    def render_needed?; true; end
    def render; true; end
  end
  class Text
    attr_reader :text
    def initialize(text,_bounds); @text = text; end
  end
  class Pages < Array
    def add(name); page = Struct.new(:name,:entities).new(name,[]); self << page; page; end
  end
  class Document
    DECIMAL_MILLIMETERS=4
    attr_reader :pages,:layers,:page_info
    attr_accessor :units
    def initialize
      @pages = Pages.new; @pages.add('Page 1')
      @layers = [Object.new]
      @page_info = Struct.new(:width,:height).new
    end
    def add_entity(entity,_layer,page); page.entities << entity; end
    def save(path); File.write(path,'native-contract-document'); end
    def export(path); File.write(path,'%PDF-contract-only'); end
  end
  API = Struct.new(:document_class,:viewport_class,:text_class,:bounds_class,:open_document)
  def test_two_objects_native_pages_view_settings_inches_and_pdf_contract
    Dir.mktmpdir do |dir|
      skp = File.join(dir,'source.skp'); File.write(skp,'fixture-contract-only')
      document = Document.new
      api = API.new(Class.new(Document) { define_singleton_method(:new) { document } },Viewport,Text,Bounds,
        ->(_path) { document })
      snapshot = {units:'mm',edges:[{id:'a',points:[[0,0,0],[1000,500,800]]}]}
      path = File.join(dir,'result.layout')
      result = JPExporter::Layout::Native::DocumentExport.call(path,
        [{path:skp,name:'Oak A',snapshot:snapshot},{path:skp,name:'Oak B',snapshot:snapshot}],api:api)
      assert_equal 2,document.pages.length
      assert_in_delta 420.0/25.4,document.page_info.width,1e-8
      assert_in_delta 297.0/25.4,document.page_info.height,1e-8
      viewports = document.pages.flat_map(&:entities).grep(Viewport)
      assert_equal 8,viewports.length
      viewports.each { |v| assert_in_delta 0.05,v.scale,1e-10 }
      assert(viewports.all? { |v| v.perspective == false && v.render_mode == Viewport::VECTOR_RENDER })
      assert_equal [1,2,3,4],viewports.first(4).map(&:view)
      assert File.file?(path)
      assert File.file?(result[:pdf_path])
      assert_equal 8,result[:viewport_count]
      assert_raises(JPExporter::Layout::ValidationError) do
        JPExporter::Layout::Native::DocumentExport.call(path,[],api:api)
      end
    end
  end
  def test_refuses_missing_source_before_creating_document_or_overwriting_output
    Dir.mktmpdir do |dir|
      path = File.join(dir,'existing.layout'); File.write(path,'original')
      assert_raises(JPExporter::Layout::ValidationError) do
        JPExporter::Layout::Native::DocumentExport.call(path,[{path:'missing.skp'}],api:nil)
      end
      assert_equal 'original',File.read(path)
    end
  end
  def test_invalid_pdf_and_reopen_failure_leave_no_partial_outputs
    Dir.mktmpdir do |dir|
      source = File.join(dir,'source.skp'); File.write(source,'fixture-contract-only')
      snapshot = {units:'mm',edges:[{id:'a',points:[[0,0,0],[600,400,800]]}]}
      [false,true].each do |bad_pdf|
        document = Document.new
        document.define_singleton_method(:export) { |path| File.write(path,'not a PDF') } if bad_pdf
        api = API.new(Class.new(Document) { define_singleton_method(:new) { document } },Viewport,Text,Bounds,
          ->(_path) { bad_pdf ? document : Struct.new(:pages).new([]) })
        path = File.join(dir,'failed.layout')
        assert_raises(JPExporter::Layout::ValidationError) do
          JPExporter::Layout::Native::DocumentExport.call(path,[{path:source,snapshot:snapshot}],api:api)
        end
        assert_equal ['source.skp'],Dir.children(dir)
      end
    end
  end
end
