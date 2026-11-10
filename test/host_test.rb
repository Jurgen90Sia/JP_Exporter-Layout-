require 'minitest/autorun'
require 'json'
require 'tmpdir'
require_relative 'support/sketchup_mock'
require_relative '../jp_exporter_layout/ui/dialog'

module UI
  class << self
    attr_accessor :jp_test_path
    def savepanel(*_args); jp_test_path; end
    def openpanel(*_args); jp_test_path; end
  end
  class HtmlDialog
    STYLE_DIALOG = 0
    attr_reader :callbacks, :scripts, :file
    def initialize(_options)
      @callbacks, @scripts = {}, []
    end
    def set_file(path); @file = path; end
    def add_action_callback(name, &block); @callbacks[name] = block; end
    def set_on_closed(&block); @closed = block; end
    def show; @visible = true; end
    def visible?; @visible; end
    def bring_to_front; @front = true; end
    def close; @visible = false; @closed.call; end
    def execute_script(script); @scripts << script; end
  end
end
module Sketchup
  class << self
    attr_accessor :active_model
  end
end
class HostTest < Minitest::Test
  def setup
    @controller = JPExporter::Layout::PreviewDialog.new
    @controller.show
    @dialog = @controller.instance_variable_get(:@dialog)
    edge = Sketchup::Edge.new(1,[0,0,0],[10,2,30])
    Sketchup.active_model = Struct.new(:selection,:edit_transform).new([edge],Geom::Transformation.new)
  end
  def teardown
    Sketchup.active_model = nil
    UI.jp_test_path = nil
  end
  def request(payload)
    @dialog.callbacks.fetch('preview').call(nil,payload)
    script = @dialog.scripts.last
    encoded = script.delete_prefix('window.JPPreview.receive(JSON.parse(').delete_suffix('));')
    JSON.parse(JSON.parse(encoded))
  end
  def test_selection_to_dialog_transport
    result = request(JSON.generate(schema_version:1,view:'front'))
    assert result['ok']
    assert_equal [254.0,762.0], result['drawing']['edges'][0]['points'][1]
    assert File.file?(@dialog.file)
  end
  def test_invalid_requests_have_explicit_errors
    ['{', '[]', 'null', 'a'*1025, '{"schema_version":2}', '{"schema_version":1,"view":"bad"}'].each do |payload|
      result = request(payload)
      assert_equal false, result['ok']
      refute_empty result['error']
    end
  end
  def test_empty_selection_and_missing_model
    Sketchup.active_model.selection.clear
    assert_match(/Select/,request('{"schema_version":1,"view":"front"}')['error'])
    Sketchup.active_model = nil
    assert_match(/No active/,request('{"schema_version":1,"view":"front"}')['error'])
  end
  def test_existing_dialog_is_reused_and_closed_dialog_recreated
    @controller.show
    assert_same @dialog, @controller.instance_variable_get(:@dialog)
    @dialog.close
    @controller.show
    refute_same @dialog, @controller.instance_variable_get(:@dialog)
    assert @controller.instance_variable_get(:@dialog).callbacks.key?('preview')
  end
  def test_unexpected_errors_are_logged_and_not_exposed
    broken = Object.new
    def broken.selection; raise 'sensitive model details'; end
    Sketchup.active_model = broken
    result = request('{"schema_version":1,"view":"front"}')
    assert_equal false, result['ok']
    refute_match(/sensitive/,result['error'])
    assert_match(/Preview failed/,result['error'])
  end
  def test_isometric_and_dimensions_are_connected_to_preview
    result = request(JSON.generate(schema_version:1,view:'isometric'))
    assert result['ok']
    assert_equal 'isometric',result['drawing']['view']
    result = request(JSON.generate(schema_version:1,view:'front',dimensions:true,scale:0.1))
    assert_equal 2,result['drawing']['dimensions'].length
  end
  def test_rejects_invalid_dimension_options_before_geometry_access
    [0,-1,'bad',nil].each do |scale|
      result = request(JSON.generate(schema_version:1,view:'front',dimensions:true,scale:scale))
      assert_equal false,result['ok']
    end
  end
  def test_hidden_mode_without_faces_reports_limitation_instead_of_wireframe
    result = request(JSON.generate(schema_version:1,view:'front',render_mode:'hidden'))
    assert_equal false,result['ok']
    assert_match(/faces/,result['error'])
    assert_equal false,request(JSON.generate(schema_version:1,view:'front',render_mode:'fake'))['ok']
  end
  def file_command(name)
    @dialog.callbacks.fetch('command').call(nil,JSON.generate(schema_version:1,command:name))
    encoded = @dialog.scripts.last.delete_prefix('window.JPPreview.receive(JSON.parse(').delete_suffix('));')
    JSON.parse(JSON.parse(encoded))
  end
  def test_file_commands_write_and_reopen_the_actual_drawing
    request(JSON.generate(schema_version:1,view:'front',dimensions:true))
    Dir.mktmpdir do |dir|
      UI.jp_test_path = File.join(dir,'drawing.jpdraw')
      assert file_command('save_snapshot')['ok']
      assert File.file?(UI.jp_test_path)
      assert_equal [254.0,762.0],file_command('open_snapshot')['drawing']['edges'][0]['points'][1]
      UI.jp_test_path = File.join(dir,'drawing.dxf')
      assert file_command('export_dxf')['ok']
      assert_includes File.read(UI.jp_test_path),'$INSUNITS'
    end
  end
  def test_failed_open_and_cancel_preserve_current_drawing_and_invalid_command_fails
    request(JSON.generate(schema_version:1,view:'front'))
    assert_match(/cancelled/,file_command('save_snapshot')['message'])
    Dir.mktmpdir do |dir|
      UI.jp_test_path = File.join(dir,'bad.jpdraw')
      File.write(UI.jp_test_path,'{}')
      result = file_command('open_snapshot')
      assert_equal false,result['ok']
      assert result['preserve_drawing']
      UI.jp_test_path = File.join(dir,'valid.dxf')
      assert file_command('export_dxf')['ok']
    end
    assert_equal false,file_command('not_a_command')['ok']
  end
end
