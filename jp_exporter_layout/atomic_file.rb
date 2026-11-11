# frozen_string_literal: true
require 'tempfile'
module JPExporter
  module Layout
    module AtomicFile
      module_function
      def write(path, content)
        temp = Tempfile.new(['.jp-export-', '.tmp'], File.dirname(File.expand_path(path)))
        begin
          temp.binmode
          temp.write(content)
          temp.flush
          temp.fsync
          temp.close
          File.rename(temp.path, path)
        ensure
          temp.close!
        end
      end
    end
  end
end
