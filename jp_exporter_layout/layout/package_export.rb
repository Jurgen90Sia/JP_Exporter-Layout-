# frozen_string_literal: true
require 'json'
require 'digest'
require 'fileutils'
require 'time'
require_relative 'source_export'
require_relative 'document_export'
require_relative '../atomic_file'
module JPExporter
  module Layout
    module Native
      module PackageExport
        module_function
        def call(model,directory,paper:'A3',orientation:'landscape',scale:'auto',api:DocumentExport.host_api)
          directory = File.expand_path(directory)
          raise ValidationError, 'Choose a new package folder; existing folders are never replaced.' if File.exist?(directory)
          created = false
          begin
            Dir.mkdir(directory)
            created = true
            data = File.join(directory,'drawing_Data')
            Dir.mkdir(data)
            sources = SourceExport.call(model,data)
            result = DocumentExport.call(File.join(directory,'drawing.layout'),sources,
              paper:paper,orientation:orientation,scale:scale,api:api)
            manifest = {project:'JP Exporter Layout',schema_version:1,created_at:Time.now.utc.iso8601,
              document:'drawing.layout',pdf:'drawing.pdf',page_count:result[:page_count],
              limitations:['Experimental host adapter; visual PDF scale, camera crop and moved-folder references need runtime validation.',
                           'Four orthographic vector viewports per object; no native dimensions or sections yet.'],
              sources:sources.map { |source| {path:'drawing_Data/'+File.basename(source[:path]),name:source[:name],
                sha256:Digest::SHA256.file(source[:path]).hexdigest} }}
            AtomicFile.write(File.join(directory,'JP-package.json'),JSON.pretty_generate(manifest))
            result.merge(package_path:directory)
          rescue StandardError
            # This directory was created exclusively by this invocation. Never
            # remove a pre-existing folder or follow a replacement symlink.
            FileUtils.remove_entry_secure(directory) if created && File.directory?(directory) && !File.symlink?(directory)
            raise
          end
        end
      end
    end
  end
end
