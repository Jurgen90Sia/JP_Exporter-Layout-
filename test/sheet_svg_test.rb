# frozen_string_literal: true
require 'minitest/autorun'
require 'rexml/document'
require_relative '../jp_exporter_layout/exporters/sheet_svg'
class SheetSvgTest < Minitest::Test
  def test_physical_paper_and_model_to_paper_coordinates_with_safe_title
    source = {units:'mm',edges:[{id:'a',points:[[2000,0,0],[3000,500,800]]}]}
    text = JPExporter::Layout::Exporters::SheetSVG.generate(source,scale:0.1,title:'Oak <A> & B')
    doc = REXML::Document.new(text)
    assert_equal '420.0mm',doc.root.attributes['width']
    assert_equal '297.0mm',doc.root.attributes['height']
    assert_equal '0 0 420.0 297.0',doc.root.attributes['viewBox']
    assert_includes doc.root.elements.to_a('text').map(&:text),'Oak <A> & B'
    groups = doc.root.elements.to_a('g')
    assert_equal 4,groups.length
    line = groups[0].elements['line']
    assert_in_delta 100,line.attributes['x2'].to_f-line.attributes['x1'].to_f,1e-8
    assert_in_delta(-80,line.attributes['y2'].to_f-line.attributes['y1'].to_f,1e-8)
    assert_includes text,'Wireframe'
    assert_raises(JPExporter::Layout::ValidationError) do
      JPExporter::Layout::Exporters::SheetSVG.generate(source,title:"bad\x00title")
    end
  end
end
