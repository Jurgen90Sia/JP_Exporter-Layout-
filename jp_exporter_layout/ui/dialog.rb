# frozen_string_literal: true
require 'json'
require_relative '../geometry/extractor'
require_relative '../diagnostics'
require_relative '../dimensions/overall'
require_relative '../exporters/dxf'
require_relative '../project_snapshot'
require_relative '../projection/hidden_line'
require_relative '../geometry/selection_analysis'
require_relative '../exporters/sheet_svg'
require_relative '../layout/package_export'
require 'securerandom'
module JPExporter
  module Layout
    class PreviewDialog
      def show
        if @dialog && @dialog.visible?
          @dialog.bring_to_front
          return
        end
        @dialog = ::UI::HtmlDialog.new(dialog_title: 'JP Exporter Layout',
          preferences_key: 'JPExporter.Layout.Preview', scrollable: true,
          resizable: true, width: 1000, height: 720, style: ::UI::HtmlDialog::STYLE_DIALOG)
        @dialog.set_file(File.join(__dir__, 'index.html'))
        @dialog.add_action_callback('preview') { |_context, payload| preview(payload) }
        @dialog.add_action_callback('command') { |_context, payload| command(payload) }
        @dialog.set_on_closed { @dialog = nil }
        @dialog.show
      end
      private
      def preview(payload)
        raise ValidationError, 'Invalid preview request.' unless payload.is_a?(String) && payload.bytesize <= 1024
        request = JSON.parse(payload)
        raise ValidationError, 'Invalid preview request.' unless request.is_a?(Hash) && request['schema_version'] == 1
        view = request['view']
        raise ValidationError, 'Unsupported view.' unless Projection::VIEWS.key?(view)
        mode = request.fetch('render_mode','wireframe')
        raise ValidationError, 'Unsupported line mode.' unless %w[wireframe visible hidden].include?(mode)
        dimensions = request.fetch('dimensions', false)
        raise ValidationError, 'Dimensions must be true or false.' unless [true,false].include?(dimensions)
        scale = request.fetch('scale',1.0)
        unless scale.is_a?(Numeric) && scale.finite? && scale.positive? && scale >= 0.000001 && scale <= 1000
          raise ValidationError, 'Choose a positive drawing scale between 1:1000000 and 1000:1.'
        end
        model = Sketchup.active_model
        raise ValidationError, 'No active SketchUp model.' unless model
        raise ValidationError, 'Select edges, faces, groups or components first.' if model.selection.empty?
        snapshot = Geometry::Extractor.new.call(model.selection.to_a, model.edit_transform,include_faces:mode != 'wireframe')
        drawing = mode == 'wireframe' ? Projection.call(snapshot, view) : HiddenLine.call(snapshot,view,mode)
        drawing[:dimensions] = Dimensions::Overall.call(drawing, scale: scale) if dimensions
        @drawing = Drawing.validate!(drawing)
        send_result(ok: true, drawing: @drawing)
      rescue ValidationError, JSON::ParserError => error
        @drawing = nil
        send_result(ok: false, error: error.message)
      rescue StandardError => error
        @drawing = nil
        Diagnostics.report(error)
        send_result(ok: false, error: 'Preview failed. See jp_exporter_layout.log in the temporary directory.')
      end
      COMMANDS = %w[export_dxf save_snapshot open_snapshot analyze_materials export_materials export_sheet_svg export_native].freeze
      def command(payload)
        raise ValidationError, 'Invalid command request.' unless payload.is_a?(String) && payload.bytesize <= 1024
        request = JSON.parse(payload)
        unless request.is_a?(Hash) && request['schema_version'] == 1 && COMMANDS.include?(request['command'])
          raise ValidationError, 'Unsupported command.'
        end
        name = request['command']
        if name == 'export_native'
          api = Native::DocumentExport.host_api
          model = Sketchup.active_model
          raise ValidationError, 'No active SketchUp model.' unless model
          unless model.selection.to_a.length.between?(1,100) && model.selection.to_a.all? { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
            raise ValidationError, 'Select one to 100 groups or components for native export.'
          end
          parent = ::UI.select_directory(title:'Choose a parent folder for a new JP LayOut package')
          return send_result(ok:true,message:'Export cancelled.') unless parent
          directory = File.join(parent,"JP_Layout_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{SecureRandom.hex(4)}")
          result = Native::PackageExport.call(model,directory,paper:request.fetch('paper','A3'),
            orientation:request.fetch('orientation','landscape'),scale:request.fetch('sheet_scale','auto'),api:api)
          send_result(ok:true,message:"Created experimental native package: #{result[:package_path]}. Keep drawing_Data alongside it; inspect all view crops and PDF scale before use.")
        elsif name == 'export_sheet_svg'
          model = Sketchup.active_model
          raise ValidationError, 'No active SketchUp model.' unless model
          raise ValidationError, 'Select geometry first.' if model.selection.empty?
          source = Geometry::Extractor.new.call(model.selection.to_a,model.edit_transform)
          content = Exporters::SheetSVG.generate(source,paper:request.fetch('paper','A3'),
            orientation:request.fetch('orientation','landscape'),scale:request.fetch('sheet_scale','auto'))
          path = ::UI.savepanel('Export scaled wireframe sheet SVG',nil,'sheet.svg')
          return send_result(ok:true,message:'Save cancelled.') unless path
          AtomicFile.write(path,content)
          send_result(ok:true,message:'Saved four-view wireframe SVG sheet. Print at 100% to preserve paper scale.')
        elsif %w[analyze_materials export_materials].include?(name)
          model = Sketchup.active_model
          raise ValidationError, 'No active SketchUp model.' unless model
          raise ValidationError, 'Select faces, groups or components first.' if model.selection.empty?
          active_path = model.respond_to?(:active_path) ? model.active_path : nil
          inherited = (active_path || []).reverse.map(&:material).find { |material| material }
          analysis = Geometry::SelectionAnalysis.new.call(model.selection.to_a,model.edit_transform,root_material:inherited)
          if name == 'export_materials'
            path = ::UI.savepanel('Export JP material surface report',nil,'materials.json')
            return send_result(ok:true,message:'Save cancelled.') unless path
            report = {project:'JP Exporter Layout',schema_version:1,analysis:analysis,
                      policy:'Visible face surfaces; front and back separate. Not purchasing quantities or solid volume.'}
            AtomicFile.write(path,JSON.pretty_generate(report))
          end
          send_result(ok:true,analysis:analysis,message:name == 'export_materials' ? 'Saved material surface report.' : 'Selection analysis complete.')
        elsif name == 'open_snapshot'
          path = ::UI.openpanel('Open JP drawing snapshot',nil,'JP drawing|*.jpdraw||')
          return send_result(ok:true,message:'Open cancelled.') unless path
          drawing = ProjectSnapshot.open(path)
          @drawing = drawing
          send_result(ok:true,drawing:drawing)
        else
          raise ValidationError, 'Generate or open a drawing first.' unless @drawing
          dxf = name == 'export_dxf'
          path = ::UI.savepanel(dxf ? 'Export drawing DXF' : 'Save JP drawing snapshot',nil,
                                dxf ? 'drawing.dxf' : 'drawing.jpdraw')
          return send_result(ok:true,message:'Save cancelled.') unless path
          if dxf
            Exporters::DXF.save(path,@drawing)
          else
            ProjectSnapshot.save(path,@drawing)
          end
          send_result(ok:true,message:dxf ? 'Saved model-space mm DXF (dimensions are exploded graphics).' :
                      'Saved drawing snapshot. Source-model associations are not stored.')
        end
      rescue ValidationError, JSON::ParserError => error
        send_result(ok:false,error:error.message,preserve_drawing:true)
      rescue StandardError => error
        Diagnostics.report(error)
        send_result(ok:false,error:'File operation failed. Check the path and local log.',preserve_drawing:true)
      end
      def send_result(result)
        # Pass JSON as a JS string, never interpolate untrusted strings as code.
        @dialog.execute_script("window.JPPreview.receive(JSON.parse(#{JSON.generate(JSON.generate(result))}));") if @dialog
      end
    end
  end
end
