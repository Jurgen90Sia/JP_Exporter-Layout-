# frozen_string_literal: true
require 'json'
require_relative '../geometry/extractor'
require_relative '../diagnostics'
require_relative '../dimensions/overall'
require_relative '../exporters/dxf'
require_relative '../project_snapshot'
require_relative '../projection/hidden_line'
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
      COMMANDS = %w[export_dxf save_snapshot open_snapshot].freeze
      def command(payload)
        raise ValidationError, 'Invalid command request.' unless payload.is_a?(String) && payload.bytesize <= 1024
        request = JSON.parse(payload)
        unless request.is_a?(Hash) && request['schema_version'] == 1 && COMMANDS.include?(request['command'])
          raise ValidationError, 'Unsupported command.'
        end
        name = request['command']
        if name == 'open_snapshot'
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
