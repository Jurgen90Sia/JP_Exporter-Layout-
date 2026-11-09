# frozen_string_literal: true
require_relative '../core'
module JPExporter
  module Layout
    module Geometry
      class Extractor
        INCH_TO_MM = 25.4
        MAX_DEPTH = 64
        def initialize(max_edges = 20_000)
          @max_edges = max_edges
        end
        def call(entities, root_transform)
          @edges, @seen, @visited = [], {}, 0
          walk(entities, root_transform, [], [])
          { units: 'mm', edges: @edges }
        end
        private
        def walk(entities, transform, path, ancestors)
          raise ValidationError, 'Geometry nesting exceeds 64 levels.' if path.length > MAX_DEPTH
          entities.each do |entity|
            @visited += 1
            raise ValidationError, 'Selection is too complex; select a smaller assembly.' if @visited > @max_edges * 20
            next if entity.respond_to?(:valid?) && !entity.valid?
            next if entity.respond_to?(:hidden?) && entity.hidden?
            next if entity.respond_to?(:layer) && !tag_visible?(entity.layer)
            case entity
            when Sketchup::Edge
              add_edge(entity, transform, path)
            when Sketchup::Face
              walk(entity.edges, transform, path, ancestors)
            when Sketchup::Group, Sketchup::ComponentInstance
              definition = entity.definition
              raise ValidationError, 'Recursive component definition detected.' if ancestors.include?(definition.object_id)
              children = entity.is_a?(Sketchup::Group) ? entity.entities : definition.entities
              walk(children, transform * entity.transformation, path + [entity.entityID], ancestors + [definition.object_id])
            end
          end
        end
        def tag_visible?(tag)
          while tag
            return false unless tag.visible?
            tag = tag.respond_to?(:folder) ? tag.folder : nil
          end
          true
        end
        def add_edge(edge, transform, path)
          key = (path + [edge.entityID]).join('/')
          return if @seen[key]
          @seen[key] = true
          raise ValidationError, 'Selection exceeds the 20,000 edge preview budget.' if @edges.length >= @max_edges
          points = [edge.start.position, edge.end.position].map do |point|
            point.transform(transform).to_a.map { |v| v.to_f * INCH_TO_MM }
          end
          @edges << { id: key, points: points }
        end
      end
    end
  end
end
