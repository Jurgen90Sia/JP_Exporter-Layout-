# frozen_string_literal: true
require_relative '../core'
module JPExporter
  module Layout
    module Geometry
      # Read-only native adapter. Areas are visible selected face surfaces, not
      # purchasing quantities. Front and back totals are deliberately separate.
      class SelectionAnalysis
        INCH2_TO_MM2 = 25.4**2
        def initialize(max_faces: 40_000, max_entities: 400_000, max_depth: 64)
          @max_faces, @max_entities, @max_depth = max_faces, max_entities, max_depth
        end
        def call(entities, root_transform, root_material: nil)
          @seen, @materials, @visited = {}, {}.compare_by_identity, 0
          @result = {schema_version: 1, units: 'mm', area_units: 'mm2',
                     group_count: 0, component_instance_count: 0, face_count: 0,
                     front_area_mm2: 0.0, objects: [], materials: []}
          walk(entities, root_transform, [], [], root_material)
          @result[:materials] = @materials.values
          @result
        ensure
          # Never retain live model entities or native materials between calls.
          @seen = @materials = @result = nil
        end
        private
        def walk(entities, transform, path, ancestors, inherited_material)
          raise ValidationError, 'Selection nesting exceeds the analysis depth budget.' if path.length > @max_depth
          entities.each do |entity|
            @visited += 1
            raise ValidationError, 'Selection exceeds the analysis entity budget.' if @visited > @max_entities
            next unless visible?(entity)
            next unless entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            key = path + [entity.entityID]
            next if @seen[key]
            @seen[key] = true
            if entity.is_a?(Sketchup::Face)
              add_face(entity, transform, inherited_material)
            else
              definition = entity.definition
              raise ValidationError, 'Recursive component definition detected.' if ancestors.include?(definition.object_id)
              group = entity.is_a?(Sketchup::Group)
              @result[group ? :group_count : :component_instance_count] += 1
              @result[:objects] << {kind: group ? 'group' : 'component_instance',
                persistent_id: persistent_id(entity), name: entity.name.to_s,
                definition_name: definition.name.to_s,
                path: path + [persistent_id(entity)]}
              children = group ? entity.entities : definition.entities
              walk(children, transform * entity.transformation, path + [persistent_id(entity)],
                   ancestors + [definition.object_id], entity.material || inherited_material)
            end
          end
        end
        def visible?(entity)
          return false if entity.respond_to?(:valid?) && !entity.valid?
          return false if entity.respond_to?(:hidden?) && entity.hidden?
          tag = entity.respond_to?(:layer) ? entity.layer : nil
          seen = {}.compare_by_identity
          while tag
            raise ValidationError, 'Recursive tag folder detected.' if seen[tag]
            seen[tag] = true
            return false unless tag.visible?
            tag = tag.respond_to?(:folder) ? tag.folder : nil
          end
          true
        end
        def persistent_id(entity)
          entity.respond_to?(:persistent_id) ? entity.persistent_id : nil
        end
        def add_face(face, transform, inherited_material)
          raise ValidationError, 'Selection exceeds the analysis face budget.' if @result[:face_count] >= @max_faces
          # Native Face#area(transform) handles arbitrary affine transforms;
          # a scalar determinant cannot represent nonuniformly scaled face area.
          area = face.area(transform).to_f * INCH2_TO_MM2
          raise ValidationError, 'Face area is invalid.' unless area.finite? && area >= 0
          @result[:face_count] += 1
          @result[:front_area_mm2] += area
          add_material(face.material || inherited_material, :front, area)
          add_material(face.back_material || inherited_material, :back, area)
        end
        def add_material(material, side, area)
          # Identity is request-local; names may collide and are only labels.
          key = material || :unpainted
          row = @materials[key] ||= {persistent_id: material ? persistent_id(material) : nil,
            name: material ? material.name.to_s : 'Unpainted', unpainted: material.nil?,
            front_face_count: 0, back_face_count: 0, front_area_mm2: 0.0, back_area_mm2: 0.0}
          row[side == :front ? :front_face_count : :back_face_count] += 1
          row[side == :front ? :front_area_mm2 : :back_area_mm2] += area
        end
      end
    end
  end
end
