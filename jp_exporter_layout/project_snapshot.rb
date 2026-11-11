# frozen_string_literal: true
require 'json'
require_relative 'drawing'
require_relative 'atomic_file'
module JPExporter
  module Layout
    # Portable preview snapshot; no source associations or automatic model updates.
    module ProjectSnapshot
      MAX_BYTES = 16 * 1024 * 1024
      module_function
      def save(path, drawing)
        Drawing.validate!(drawing)
        content = JSON.generate(schema_version: 1, kind: 'jp-drawing-snapshot', drawing: drawing)
        raise ValidationError, 'Snapshot exceeds 16 MiB.' if content.bytesize > MAX_BYTES
        AtomicFile.write(path, content)
      end
      def open(path)
        raise ValidationError, 'Snapshot exceeds 16 MiB.' if File.size(path) > MAX_BYTES
        content = File.binread(path, MAX_BYTES + 1)
        raise ValidationError, 'Snapshot exceeds 16 MiB.' if content.bytesize > MAX_BYTES
        document = JSON.parse(content, symbolize_names: true, max_nesting: 32)
        unless document.is_a?(Hash) && document[:schema_version] == 1 && document[:kind] == 'jp-drawing-snapshot'
          raise ValidationError, 'Unsupported snapshot version or type.'
        end
        Drawing.validate!(document[:drawing])
      rescue JSON::ParserError => error
        raise ValidationError, "Invalid snapshot JSON: #{error.message}"
      end
    end
  end
end
