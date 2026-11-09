# frozen_string_literal: true
require 'sketchup.rb'
require 'extensions.rb'
require_relative 'jp_exporter_layout/version'
module JPExporter
  module Layout
    unless file_loaded?(__FILE__)
      extension = SketchupExtension.new('JP Exporter Layout', 'jp_exporter_layout/main')
      extension.description = 'Selected geometry to millimeter orthographic wireframe preview.'
      extension.version = VERSION
      extension.creator = 'JP Exporter Layout contributors'
      extension.copyright = 'Copyright 2026 JP Exporter Layout contributors. All rights reserved.'
      Sketchup.register_extension(extension, true)
      file_loaded(__FILE__)
    end
  end
end
