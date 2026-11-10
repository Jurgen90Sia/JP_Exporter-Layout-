# frozen_string_literal: true
require_relative '../core'
module JPExporter
  module Layout
    # Orthographic opaque-triangle interval occlusion. No bbox visibility shortcuts.
    module HiddenLine
      EPS = 0.000001
      module_function
      def call(snapshot, view, mode)
        unless %w[visible hidden].include?(mode) && Projection::VIEWS.key?(view) && snapshot[:units] == 'mm'
          raise ValidationError, 'Unsupported hidden-line request.'
        end
        faces = snapshot[:triangles]
        unless faces.is_a?(Array) && !faces.empty?
          raise ValidationError, 'Hidden-line processing needs selected faces, groups or components containing faces.'
        end
        if faces.length * snapshot[:edges].length > 1_000_000
          raise ValidationError, 'Hidden-line processing exceeds the work budget. Select a smaller assembly or use wireframe.'
        end
        u,v = Projection::VIEWS.fetch(view)
        w = [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
        axes = [u,v,w]
        origin = snapshot[:edges].first && snapshot[:edges].first[:points].first
        raise ValidationError, 'Select drawable geometry.' unless origin
        origin_projection = project(origin,axes)
        triangles = faces.map do |face|
          points = face[:points]
          raise ValidationError, 'Invalid occluder triangle.' unless points.is_a?(Array) && points.length == 3
          points.map { |p| local_project(p,origin,axes) }
        end
        output = []
        snapshot[:edges].each do |edge|
          a,b = edge[:points].map { |p| local_project(p,origin,axes) }
          next if Math.hypot(b[0]-a[0],b[1]-a[1]) < EPS
          intervals = triangles.filter_map { |triangle| occluded_interval(a,b,triangle) }.sort_by(&:first)
          merged = []
          intervals.each do |lo,hi|
            if !merged.empty? && lo <= merged[-1][1]+1e-12
              merged[-1][1] = [merged[-1][1],hi].max
            else
              merged << [lo,hi]
            end
          end
          segments, cursor = [], 0.0
          merged.each do |lo,hi|
            segments << [cursor,lo,'visible'] if lo-cursor > 1e-12
            segments << [lo,hi,'hidden'] if hi-lo > 1e-12
            cursor = hi
          end
          segments << [cursor,1.0,'visible'] if 1.0-cursor > 1e-12
          segments.each_with_index do |(lo,hi,role),index|
            next if mode == 'visible' && role == 'hidden'
            points = [lo,hi].map { |t| [origin_projection[0]+a[0]+(b[0]-a[0])*t,origin_projection[1]+a[1]+(b[1]-a[1])*t] }
            next if Math.hypot(points[1][0]-points[0][0],points[1][1]-points[0][1]) < EPS
            output << {id:"#{edge[:id]}:#{index}",source_id:edge[:id],points:points,role:role}
            raise ValidationError, 'Hidden-line output exceeds 20,000 segments.' if output.length > 20_000
          end
        end
        raise ValidationError, 'No drawable edges remain in this view.' if output.empty?
        points = output.flat_map { |e| e[:points] }
        xs,ys = points.map(&:first),points.map(&:last)
        {schema_version:1,units:'mm',view:view,render_mode:mode,bounds:[xs.min,ys.min,xs.max,ys.max],edges:output}
      end
      def project(point,axes)
        unless point.is_a?(Array) && point.length == 3 && point.all? { |n| n.is_a?(Numeric) && n.finite? }
          raise ValidationError, 'Invalid geometry coordinates.'
        end
        axes.map { |axis| axis.zip(point).inject(0.0) { |s,(a,p)| s+a*p } }
      end
      def local_project(point,origin,axes)
        project(point,axes) # Validate before subtraction.
        project(point.zip(origin).map { |p,o| p-o },axes)
      end
      def weights(p,triangle)
        a,b,c = triangle
        det = (b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
        length = [Math.hypot(a[0]-c[0],a[1]-c[1]),Math.hypot(b[0]-c[0],b[1]-c[1]),1.0].max
        return nil if det.abs <= EPS*length
        x = ((b[1]-c[1])*(p[0]-c[0])+(c[0]-b[0])*(p[1]-c[1]))/det
        y = ((c[1]-a[1])*(p[0]-c[0])+(a[0]-c[0])*(p[1]-c[1]))/det
        [x,y,1-x-y]
      end
      def occluded_interval(a,b,triangle)
        wa,wb = weights(a,triangle),weights(b,triangle)
        return nil unless wa && wb
        lo,hi = 0.0,1.0
        # Clip in barycentric coordinates, then against interpolated occluder depth.
        base = triangle[0][2]
        da = wa.zip(triangle).inject(0.0) { |s,(weight,p)| s+weight*(p[2]-base) }-(a[2]-base)-EPS
        db = wb.zip(triangle).inject(0.0) { |s,(weight,p)| s+weight*(p[2]-base) }-(b[2]-base)-EPS
        wa.zip(wb).push([da,db]).each do |start,finish|
          delta = finish-start
          if delta.abs < 1e-15
            return nil if start < 0 || (start == 0 && da <= 0 && db <= 0)
          elsif delta.positive?
            lo = [lo,-start/delta].max
          else
            hi = [hi,-start/delta].min
          end
          return nil if hi <= lo
        end
        [lo,hi]
      end
    end
  end
end
