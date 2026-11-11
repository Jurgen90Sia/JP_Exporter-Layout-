require 'minitest/autorun'
# Satisfy host requires without shipping fake API files in the runtime package.
$LOADED_FEATURES << 'sketchup.rb' unless $LOADED_FEATURES.include?('sketchup.rb')
$LOADED_FEATURES << 'extensions.rb' unless $LOADED_FEATURES.include?('extensions.rb')
$jp_loaded_files = {}
def file_loaded?(path); $jp_loaded_files[path]; end
def file_loaded(path); $jp_loaded_files[path] = true; end
class SketchupExtension
  attr_accessor :description, :version, :creator, :copyright
  attr_reader :name, :loader
  def initialize(name, loader); @name, @loader = name, loader; end
end
module Sketchup
  def self.register_extension(extension, enabled)
    (@jp_registered ||= []) << [extension, enabled]
  end
  def self.jp_registered; @jp_registered || []; end
end
class RegistrationTest < Minitest::Test
  def test_entrypoint_registers_once_with_resolvable_loader_and_version
    file = File.expand_path('../jp_exporter_layout.rb',__dir__)
    2.times { load file }
    entries = Sketchup.jp_registered
    assert_equal 1, entries.length
    extension, enabled = entries.first
    assert enabled
    assert_equal JPExporter::Layout::VERSION, extension.version
    assert File.file?(File.expand_path('../'+extension.loader+'.rb',__dir__))
  end
end
