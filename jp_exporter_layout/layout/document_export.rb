# frozen_string_literal: true
require 'tempfile'
require_relative '../sheets/plan'
module JPExporter
  module Layout
    module Native
      # Official LayOut API adapter. Contract tests are not native runtime proof.
      # Sources must already exist and stay alongside the generated document.
      module DocumentExport
        API = Struct.new(:document_class,:viewport_class,:text_class,:bounds_class,:open_document)
        VIEW_CONSTANTS = {'front'=>:FRONT_VIEW,'rear'=>:BACK_VIEW,'left'=>:LEFT_VIEW,
                          'right'=>:RIGHT_VIEW,'top'=>:TOP_VIEW,'bottom'=>:BOTTOM_VIEW,'isometric'=>:ISO_VIEW}.freeze
        module_function
        def host_api
          unless defined?(::Layout::Document) && defined?(::Layout::SketchUpModel) && defined?(::Geom::Bounds2d)
            raise ValidationError, 'This SketchUp host does not expose the native LayOut Ruby API.'
          end
          API.new(::Layout::Document,::Layout::SketchUpModel,::Layout::FormattedText,::Geom::Bounds2d,
                  ->(path) { ::Layout::Document.open(path) })
        end
        def call(path,sources,paper:'A3',orientation:'landscape',scale:'auto',api:host_api)
          path = File.expand_path(path)
          pdf = path.sub(/\.layout\z/i,'.pdf')
          unless path.match?(/\.layout\z/i) && !File.exist?(path) && !File.exist?(pdf)
            raise ValidationError, 'Choose new .layout and PDF paths; existing files are never replaced.'
          end
          unless sources.is_a?(Array) && sources.length.between?(1,100) && sources.all? { |s| s.is_a?(Hash) && s[:path].is_a?(String) && File.file?(s[:path]) }
            raise ValidationError, 'Provide one to 100 existing linked SketchUp source files.'
          end
          # Use the complete world bounding box, not a sparse edge sample, for
          # native fitting. Standard ISO octants can differ from the SVG basis;
          # the box envelope has the same extents in every standard ISO octant.
          plans = sources.map { |s| Sheets::Plan.call(bounds_snapshot(s[:snapshot]),paper:paper,orientation:orientation,scale:scale) }
          document = api.document_class.new
          width,height = plans.first[:paper_mm]
          document.page_info.width = width/25.4
          document.page_info.height = height/25.4
          document.units = api.document_class.const_get(:DECIMAL_MILLIMETERS)
          sources.each_with_index do |source,index|
            title = source.fetch(:name,"Object #{index+1}").to_s
            unless title.valid_encoding? && title.length.between?(1,200) && !title.match?(/[\x00-\x1F]/)
              raise ValidationError, 'Object titles must be nonempty text up to 200 characters.'
            end
            page = index.zero? ? document.pages.first : document.pages.add("#{index+1}. #{title}")
            page.name = "#{index+1}. #{title}"
            plan = plans[index]
            plan[:views].each do |view|
              x,y,w,h = view[:cell_mm]
              bounds = api.bounds_class.new(*[x+12,y+12,w-24,h-24].map { |mm| mm/25.4 })
              viewport = api.viewport_class.new(File.expand_path(source[:path]),bounds)
              document.add_entity(viewport,document.layers.first,page)
              viewport.view = api.viewport_class.const_get(VIEW_CONSTANTS.fetch(view[:view]))
              viewport.perspective = false
              viewport.scale = plan[:scale]
              viewport.preserve_scale_on_resize = true
              viewport.render_mode = api.viewport_class.const_get(:VECTOR_RENDER)
              viewport.render if viewport.render_needed?
              label_bounds = api.bounds_class.new(*[x+4,y+h-8,w-8,6].map { |mm| mm/25.4 })
              label = api.text_class.new("#{view[:view]} | scale #{format('%.8g',plan[:scale])}:1",label_bounds)
              document.add_entity(label,document.layers.first,page)
            end
            title_bounds = api.bounds_class.new(*[10,height-20,width-20,10].map { |mm| mm/25.4 })
            document.add_entity(api.text_class.new(title,title_bounds),document.layers.first,page)
          end
          publish(document,api,path,pdf,sources.length)
          {layout_path:path,pdf_path:pdf,page_count:sources.length,viewport_count:sources.length*4}
        end
        def bounds_snapshot(snapshot)
          Projection.call(snapshot,'isometric') # validates units and finite endpoints
          points = snapshot[:edges].flat_map { |edge| edge[:points] }
          ranges = (0..2).map { |axis| points.map { |point| point[axis] }.minmax }
          corners = ranges[0].product(ranges[1],ranges[2])
          edges = corners.combination(2).each_with_index.map { |pair,index| {id:index.to_s,points:pair} }
          {units:'mm',edges:edges}
        end
        def publish(document,api,path,pdf,page_count)
          layout_temp = Tempfile.new(['.jp-layout-','.layout'],File.dirname(path))
          pdf_temp = Tempfile.new(['.jp-layout-','.pdf'],File.dirname(path))
          layout_path,pdf_path = layout_temp.path,pdf_temp.path
          layout_temp.close!; pdf_temp.close!
          published = []
          begin
            document.save(layout_path)
            raise ValidationError, 'Native LayOut save did not produce a document.' unless File.file?(layout_path) && File.size(layout_path).positive?
            reopened = api.open_document.call(layout_path)
            raise ValidationError, 'Native LayOut reopen did not preserve page count.' unless reopened.pages.length == page_count
            document.export(pdf_path)
            unless File.file?(pdf_path) && File.binread(pdf_path,5) == '%PDF-'
              raise ValidationError, 'Native PDF export did not produce a PDF.'
            end
            # Hard links publish without replacement even if a destination appears
            # after preflight. All three files share the chosen output directory.
            File.link(pdf_path,pdf); published << pdf
            File.link(layout_path,path); published << path
          rescue StandardError
            published.each { |file| File.delete(file) if File.file?(file) }
            raise
          ensure
            [layout_path,pdf_path].each { |file| File.delete(file) if File.file?(file) }
          end
        end
      end
    end
  end
end
