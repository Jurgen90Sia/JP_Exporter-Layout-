# frozen_string_literal: true
require 'sketchup.rb'
require_relative 'version'
require_relative 'diagnostics'
require_relative 'ui/dialog'
module JPExporter
  module Layout
    unless file_loaded?(__FILE__)
      ::UI.menu('Extensions').add_item('JP Exporter Layout — Preview') do
        begin
          @preview ||= PreviewDialog.new
          @preview.show
        rescue StandardError => error
          Diagnostics.report(error)
          ::UI.messagebox('JP Exporter Layout could not open. See jp_exporter_layout.log in the temporary directory.')
        end
      end
      file_loaded(__FILE__)
    end
  end
end
