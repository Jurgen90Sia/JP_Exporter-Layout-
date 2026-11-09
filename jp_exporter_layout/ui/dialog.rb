# frozen_string_literal: true
require 'json'
require_relative '../geometry/extractor'
require_relative '../diagnostics'
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
        model = Sketchup.active_model
        raise ValidationError, 'No active SketchUp model.' unless model
        raise ValidationError, 'Select edges, faces, groups or components first.' if model.selection.empty?
        snapshot = Geometry::Extractor.new.call(model.selection.to_a, model.edit_transform)
        send_result(ok: true, drawing: Projection.call(snapshot, view))
      rescue ValidationError, JSON::ParserError => error
        send_result(ok: false, error: error.message)
      rescue StandardError => error
        Diagnostics.report(error)
        send_result(ok: false, error: 'Preview failed. See jp_exporter_layout.log in the temporary directory.')
      end
      def send_result(result)
        # Pass JSON as a JS string, never interpolate untrusted strings as code.
        @dialog.execute_script("window.JPPreview.receive(JSON.parse(#{JSON.generate(JSON.generate(result))}));") if @dialog
      end
    end
  end
end
