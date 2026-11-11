# frozen_string_literal: true
require_relative '../geometry/extractor'
module JPExporter
  module Layout
    module Native
      # A temporary wrapper definition retains selected instance placement and
      # paint. Abort the operation even on I/O errors; never save the user model.
      module SourceExport
        module_function
        def call(model,directory)
          entities = model.selection.to_a.uniq
          unless entities.length.between?(1,100) && entities.all? { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
            raise ValidationError, 'Native batch export needs one to 100 selected groups or components only.'
          end
          raise ValidationError, 'Source directory must already exist.' unless File.directory?(directory)
          active_path = model.active_path || []
          inherited = active_path.reverse.map(&:material).find { |m| m }
          root = model.edit_transform
          sources = entities.each_with_index.map do |entity,index|
            path = File.join(File.expand_path(directory),format('%04d.skp',index+1))
            raise ValidationError, 'Source files already exist; use a new package.' if File.exist?(path)
            label = entity.name.to_s.empty? ? entity.definition.name.to_s : entity.name.to_s
            label = "Object #{index+1}" if label.empty?
            {path:path,name:label,snapshot:Geometry::Extractor.new.call([entity],root)}
          end
          original = state(model)
          started = false
          owned = []
          begin
            begin
              started = model.start_operation('JP Exporter Layout temporary source export',true)
              raise ValidationError, 'Could not begin temporary source export.' unless started
              entities.each_with_index do |entity,index|
                wrapper = model.definitions.add("JP temporary export #{index+1}")
                instance = wrapper.entities.add_instance(entity.definition,root * entity.transformation)
                instance.material = entity.material || inherited
                path = sources[index][:path]
                # Reserve without replacement before native Save As writes it.
                File.open(path,File::WRONLY|File::CREAT|File::EXCL) { |file| file.write('') }
                owned << path
                unless wrapper.save_as(path) && File.file?(path) && File.size(path).positive?
                  raise ValidationError, 'SketchUp did not save the linked source model.'
                end
              end
            ensure
              model.abort_operation if started
              raise ValidationError, 'Source export did not restore the original model state.' unless original == state(model)
            end
            sources
          rescue StandardError
            owned.each { |path| File.delete(path) if File.file?(path) }
            raise
          end
        end
        def state(model)
          {entities:model.entities.map(&:entityID).sort,definitions:model.definitions.map(&:entityID).sort,
           selection:model.selection.map(&:entityID).sort,active_path:(model.active_path || []).map(&:entityID),
           modified:model.modified?}
        end
      end
    end
  end
end
