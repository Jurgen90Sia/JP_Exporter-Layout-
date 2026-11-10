# frozen_string_literal: true
require_relative 'core'
require_relative 'dimensions/overall'
module JPExporter
  module Layout
    module Drawing
      module_function
      def validate!(drawing)
        unless drawing.is_a?(Hash) && drawing[:schema_version] == 1 && drawing[:units] == 'mm' &&
               %w[wireframe visible hidden].include?(drawing[:render_mode]) && Projection::VIEWS.key?(drawing[:view])
          raise ValidationError, 'Unsupported drawing format.'
        end
        b = drawing[:bounds]
        unless b.is_a?(Array) && b.length == 4 && b.all? { |n| finite?(n) } && b[2] >= b[0] && b[3] >= b[1]
          raise ValidationError, 'Invalid drawing bounds.'
        end
        edges = drawing[:edges]
        unless edges.is_a?(Array) && !edges.empty? && edges.length <= 20_000
          raise ValidationError, 'Drawing needs 1 to 20,000 edges.'
        end
        edges.each do |edge|
          unless edge.is_a?(Hash) && pair?(edge[:points]) && %w[visible hidden].include?(edge.fetch(:role,'visible')) && edge[:points].all? { |p|
            p[0] >= b[0]-0.000001 && p[0] <= b[2]+0.000001 && p[1] >= b[1]-0.000001 && p[1] <= b[3]+0.000001
          }
            raise ValidationError, 'Invalid edge or bounds do not enclose geometry.'
          end
        end
        dimensions = drawing.fetch(:dimensions, [])
        unless dimensions.is_a?(Array) && dimensions.length <= 2
          raise ValidationError, 'Invalid dimensions.'
        end
        dimensions.each do |d|
          unless d.is_a?(Hash) && d[:type] == 'dimension' && %w[horizontal vertical].include?(d[:axis]) &&
                 finite?(d[:value_mm]) && d[:value_mm].positive? && pair?(d[:anchors]) && pair?(d[:line]) &&
                 point?(d[:text_at]) && d[:text].is_a?(String) && d[:text].bytesize <= 100 && !d[:text].match?(/[\r\n\x00]/) &&
                 (!d.key?(:text_height_mm) || (finite?(d[:text_height_mm]) && d[:text_height_mm].positive?))
            raise ValidationError, 'Invalid dimension record.'
          end
          expected_anchors = d[:axis] == 'horizontal' ? [[b[0],b[1]],[b[2],b[1]]] : [[b[0],b[1]],[b[0],b[3]]]
          expected_value = d[:axis] == 'horizontal' ? b[2]-b[0] : b[3]-b[1]
          match = /\A[0-9]+(?:\.([0-9]{1,6}))? mm\z/.match(d[:text])
          precision = match && match[1] ? match[1].length : 0
          unless drawing[:view] != 'isometric' && d[:anchors] == expected_anchors &&
                 (d[:value_mm]-expected_value).abs < 0.000001 && match &&
                 d[:text] == format("%.#{precision}f mm",expected_value)
            raise ValidationError, 'Overall dimension measurement does not match drawing bounds.'
          end
        end
        drawing
      end
      def finite?(value)
        value.is_a?(Numeric) && value.finite? && value.abs <= 1.0e12
      end
      def point?(value)
        value.is_a?(Array) && value.length == 2 && value.all? { |n| finite?(n) }
      end
      def pair?(value)
        value.is_a?(Array) && value.length == 2 && value.all? { |p| point?(p) }
      end
    end
  end
end
