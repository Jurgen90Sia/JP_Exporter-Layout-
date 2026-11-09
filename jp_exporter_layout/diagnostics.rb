# frozen_string_literal: true
require 'logger'
require 'tmpdir'
module JPExporter
  module Layout
    module Diagnostics
      module_function
      def logger
        @logger ||= Logger.new(File.join(Dir.tmpdir, 'jp_exporter_layout.log'), 3, 1_048_576)
      rescue StandardError
        @logger ||= Logger.new($stderr)
      end
      def report(error)
        logger.error("#{error.class}: #{error.message}\n#{Array(error.backtrace).first(12).join("\n")}")
      end
    end
  end
end
