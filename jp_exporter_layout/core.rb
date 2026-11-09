# frozen_string_literal: true
module JPExporter
  module Layout
    class ValidationError < StandardError; end

    module Projection
      # Screen-right and drawing-up axes, looking toward the origin.
      VIEWS = {
        'front' => [[1,0,0],[0,0,1]], 'rear' => [[-1,0,0],[0,0,1]],
        'left' => [[0,-1,0],[0,0,1]], 'right' => [[0,1,0],[0,0,1]],
        'top' => [[1,0,0],[0,1,0]], 'bottom' => [[1,0,0],[0,-1,0]]
      }.freeze
      EPSILON_MM = 0.000001
      module_function
      def call(snapshot, view)
        axes = VIEWS[view]
        raise ValidationError, 'Choose a supported orthographic view.' unless axes
        raise ValidationError, 'Geometry must use millimeters.' unless snapshot[:units] == 'mm'
        edges = snapshot[:edges].map do |edge|
          points = edge[:points].map do |point|
            unless point.length == 3 && point.all? { |v| v.is_a?(Numeric) && v.finite? }
              raise ValidationError, 'Geometry contains invalid coordinates.'
            end
            axes.map { |axis| point.zip(axis).inject(0.0) { |sum, (v, a)| sum + v * a } }
          end
          raise ValidationError, 'An edge needs two endpoints.' unless points.length == 2
          next if Math.hypot(points[1][0]-points[0][0], points[1][1]-points[0][1]) < EPSILON_MM
          { id: edge[:id], points: points }
        end.compact
        raise ValidationError, 'No drawable edges in this view. Select geometry or choose another view.' if edges.empty?
        points = edges.flat_map { |edge| edge[:points] }
        xs, ys = points.map(&:first), points.map(&:last)
        { schema_version: 1, units: 'mm', view: view, render_mode: 'wireframe',
          bounds: [xs.min, ys.min, xs.max, ys.max], edges: edges }
      end
    end
  end
end
