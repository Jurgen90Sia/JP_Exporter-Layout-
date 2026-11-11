# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../jp_exporter_layout/sheets/plan'
class SheetPlanTest < Minitest::Test
  def snapshot
    {units: 'mm', edges: [{id: 'box', points: [[0,0,0],[1000,500,800]]}]}
  end
  def test_shared_scale_and_centered_non_overlapping_views
    plan = JPExporter::Layout::Sheets::Plan.call(snapshot)
    assert_equal [420.0,297.0], plan[:paper_mm]
    assert_equal %w[front right top isometric],(plan[:views].map { |v| v[:view] })
    assert_equal 0.1,plan[:scale]
    plan[:views].each do |view|
      x,y,w,h = view[:cell_mm]
      bx,by,bw,bh = view[:drawing_mm]
      assert_operator bx,:>=,x
      assert_operator by,:>=,y
      assert_operator bx+bw,:<=,x+w
      assert_operator by+bh,:<=,y+h
      assert_in_delta x+w/2,bx+bw/2,1e-9
    end
    assert_equal 100.0,plan[:views][0][:drawing_mm][2]
  end
  def test_fixed_scale_rejects_overflow_and_does_not_mutate_snapshot
    source = snapshot
    before = Marshal.dump(source)
    assert_raises(JPExporter::Layout::ValidationError) { JPExporter::Layout::Sheets::Plan.call(source,scale:1.0) }
    plan = JPExporter::Layout::Sheets::Plan.call(source,paper:'A4',orientation:'portrait',scale:0.05,views:['front'])
    assert_equal [210.0,297.0],plan[:paper_mm]
    assert_equal before,Marshal.dump(source)
  end
  def test_invalid_options_and_unrenderable_views_fail_explicitly
    [{paper:'B0'},{orientation:'diagonal'},{scale:0},{scale:Float::NAN},{views:[]},
     {views:['front','front']},{views:['bad']}].each do |options|
      assert_raises(JPExporter::Layout::ValidationError) { JPExporter::Layout::Sheets::Plan.call(snapshot,**options) }
    end
  end
end
