# frozen_string_literal: true
# Run explicitly in SketchUp Ruby Console. Never runs on extension installation.
require 'json'
require 'digest'
require 'tmpdir'
require 'time'
require_relative '../jp_exporter_layout/geometry/extractor'
require_relative '../jp_exporter_layout/geometry/selection_analysis'
require_relative '../jp_exporter_layout/exporters/sheet_svg'
module JPExporter
  module Layout
    module RuntimeMaterialsSheets
      module_function
      def run
        model = Sketchup.active_model
        raise ValidationError, 'Open a model outside component editing first.' unless model && !model.active_path
        root = File.expand_path('..',__dir__)
        fixture_dir = Dir.mktmpdir('JP_Exporter_Layout_runtime_')
        report = {project:'JP Exporter Layout',started_at:Time.now.utc.iso8601,scope:'materials and paper SVG only',
          sketchup:Sketchup.version,ruby:RUBY_VERSION,checks:{},source_sha256:{}}
        %w[geometry/extractor.rb geometry/selection_analysis.rb sheets/plan.rb exporters/sheet_svg.rb].each do |relative|
          path = File.join(root,'jp_exporter_layout',relative)
          report[:source_sha256][relative] = Digest::SHA256.file(path).hexdigest
        end
        # Check the actual method implementation locations, not installed labels.
        methods = [Geometry::Extractor.instance_method(:call),Geometry::SelectionAnalysis.instance_method(:call),
                   Sheets::Plan.method(:call),Exporters::SheetSVG.method(:generate)]
        check(report,'JP.source_identity') do
          methods.all? { |m| File.expand_path(m.source_location.first).start_with?(root+File::SEPARATOR) }
        end
        original = state(model)
        started = false
        begin
          raise ValidationError, 'Loaded JP source does not match this checkout.' unless report[:checks]['JP.source_identity']
          model.start_operation('JP Exporter Layout temporary runtime fixture',true)
          started = true
          box = model.entities.add_group
          face = box.entities.add_face([0,0,0],[600.mm,0,0],[600.mm,400.mm,0],[0,400.mm,0])
          face.reverse! if face.normal.z < 0
          face.pushpull(800.mm)
          paint = model.materials.add('JP temporary runtime material')
          paint.color = Sketchup::Color.new(180,120,60)
          box.material = paint
          source = Geometry::Extractor.new.call([box],Geom::Transformation.new)
          analysis = Geometry::SelectionAnalysis.new.call([box],Geom::Transformation.new)
          expected_area = 2*(600*400+600*800+400*800)
          check(report,'JP.materials.box_area_mm2') { (analysis[:front_area_mm2]-expected_area).abs < 0.01 }
          check(report,'JP.materials.inherited_paint') do
            analysis[:materials].length == 1 && analysis[:materials][0][:name] == paint.name && analysis[:face_count] == 6
          end
          plan = Sheets::Plan.call(source,scale:0.1)
          check(report,'JP.sheet.front_60x80_paper_mm') do
            rect = plan[:views][0][:drawing_mm]
            (rect[2]-60).abs < 0.000001 && (rect[3]-80).abs < 0.000001
          end
          svg = File.join(fixture_dir,'JP_600x400x800_A3_1to10.svg')
          Exporters::SheetSVG.save(svg,source,scale:0.1)
          report[:svg_path] = svg
          check(report,'JP.sheet.svg_file') { File.file?(svg) && File.read(svg).include?('width="420.0mm"') }
        rescue StandardError => error
          report[:checks]['JP.fixture_execution'] = "#{error.class}: #{error.message}"
        ensure
          begin
            model.abort_operation if started
          rescue StandardError => error
            report[:checks]['JP.rollback'] = "#{error.class}: #{error.message}"
          end
          check(report,'JP.model_restored') { original == state(model) }
        end
        report[:passed] = report[:checks].values.all? { |value| value == true }
        path = File.join(fixture_dir,'JP_Exporter_Layout_materials_sheets_runtime.json')
        AtomicFile.write(path,JSON.pretty_generate(report))
        puts "JP Exporter Layout materials/sheets runtime: #{report[:passed] ? 'PASS' : 'FAIL'}"
        puts path
        report
      end
      def state(model)
        {entities:model.entities.map(&:entityID).sort,definitions:model.definitions.map(&:entityID).sort,
         materials:model.materials.map(&:name).sort,selection:model.selection.map(&:entityID).sort,
         active_path:(model.active_path || []).map(&:entityID),modified:model.modified?}
      end
      def check(report,id)
        report[:checks][id] = yield == true
      rescue StandardError => error
        report[:checks][id] = "#{error.class}: #{error.message}"
      end
    end
  end
end
JPExporter::Layout::RuntimeMaterialsSheets.run
