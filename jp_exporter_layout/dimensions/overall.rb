# frozen_string_literal: true
require_relative '../core'
module JPExporter
  module Layout
    module Dimensions
      # Model-space annotation graphics, with a paper-mm placement offset.
      # These are preview/DXF graphics, not native or associative LayOut entities.
      module Overall
        module_function
        def call(drawing, offset: 10, scale: 1.0, precision: 0)
          if drawing[:view] == 'isometric'
            raise ValidationError, 'Overall dimensions require an orthographic view. Isometric projected spans are not physical part dimensions.'
          end
          bounds = drawing[:bounds]
          unless drawing[:units] == 'mm' && bounds.is_a?(Array) && bounds.length == 4 &&
                 bounds.all? { |v| v.is_a?(Numeric) && v.finite? } &&
                 bounds[2] >= bounds[0] && bounds[3] >= bounds[1]
            raise ValidationError, 'Invalid drawing bounds for dimensions.'
          end
          unless scale.is_a?(Numeric) && scale.finite? && scale.positive? &&
                 offset.is_a?(Numeric) && offset.finite? && offset.positive? &&
                 precision.is_a?(Integer) && (0..6).cover?(precision)
            raise ValidationError, 'Use positive scale/offset and precision from 0 to 6.'
          end
          gap = offset / scale.to_f
          raise ValidationError, 'Dimension offset exceeds numeric range.' unless gap.finite?
          x0,y0,x1,y1 = bounds
          records = []
          if x1-x0 >= Projection::EPSILON_MM
            records << record('horizontal', x1-x0, [[x0,y0],[x1,y0]],
                              [[x0,y0-gap],[x1,y0-gap]], precision)
          end
          if y1-y0 >= Projection::EPSILON_MM
            records << record('vertical', y1-y0, [[x0,y0],[x0,y1]],
                              [[x0-gap,y0],[x0-gap,y1]], precision)
          end
          records.each { |r| r[:text_height_mm] = 3.0 / scale }
        end
        def record(axis, value, anchors, line, precision)
          {type: 'dimension', axis: axis, value_mm: value, text: format("%.#{precision}f mm", value),
           anchors: anchors, line: line, text_at: [(line[0][0]+line[1][0])/2.0, (line[0][1]+line[1][1])/2.0]}
        end
      end
    end
  end
end
