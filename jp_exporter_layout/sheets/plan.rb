# frozen_string_literal: true
require_relative '../core'
module JPExporter
  module Layout
    module Sheets
      # Paper millimeters. Geometry stays in model millimeters until placement.
      module Plan
        PAPERS = {'A0'=>[841.0,1189.0], 'A1'=>[594.0,841.0], 'A2'=>[420.0,594.0],
                  'A3'=>[297.0,420.0], 'A4'=>[210.0,297.0]}.freeze
        DENOMINATORS = [1,2,5,10,20,25,50,100,200,500,1000,2000,5000,10_000,
                        20_000,50_000,100_000,200_000,500_000,1_000_000].freeze
        module_function
        def call(snapshot, paper: 'A3', orientation: 'landscape', scale: 'auto', views: %w[front right top isometric])
          raise ValidationError, 'Choose ISO paper A0 to A4.' unless PAPERS.key?(paper)
          raise ValidationError, 'Choose portrait or landscape.' unless %w[portrait landscape].include?(orientation)
          unless views.is_a?(Array) && views.length.between?(1,7) && views.uniq == views && views.all? { |v| Projection::VIEWS.key?(v) }
            raise ValidationError, 'Choose one to seven distinct supported views.'
          end
          unless scale == 'auto' || (scale.is_a?(Numeric) && scale.finite? && scale.between?(0.000001,1000))
            raise ValidationError, 'Choose auto scale or a ratio between 1:1000000 and 1000:1.'
          end
          width,height = orientation == 'landscape' ? PAPERS[paper].reverse : PAPERS[paper]
          columns = views.length == 1 ? 1 : 2
          rows = (views.length.to_f/columns).ceil
          cell_width,cell_height = (width-20)/columns,(height-35)/rows
          available_width,available_height = cell_width-24,cell_height-24
          projected = views.map { |view| Projection.call(snapshot,view) }
          fits = projected.map do |drawing|
            b = drawing[:bounds]
            [b[2] == b[0] ? Float::INFINITY : available_width/(b[2]-b[0]),
             b[3] == b[1] ? Float::INFINITY : available_height/(b[3]-b[1])].min
          end.min
          ratio = scale == 'auto' ? DENOMINATORS.map { |d| 1.0/d }.find { |r| r <= fits } : scale.to_f
          raise ValidationError, 'Geometry does not fit this paper at the selected scale.' unless ratio && ratio <= fits
          placed = projected.each_with_index.map do |drawing,index|
            x,y = 10+(index%columns)*cell_width,10+(index/columns)*cell_height
            b = drawing[:bounds]
            dw,dh = (b[2]-b[0])*ratio,(b[3]-b[1])*ratio
            {view:drawing[:view],cell_mm:[x,y,cell_width,cell_height],
             drawing_mm:[x+(cell_width-dw)/2,y+(cell_height-dh)/2,dw,dh],
             bounds:b,edges:drawing[:edges]}
          end
          {schema_version:1,units:'mm',paper:paper,orientation:orientation,paper_mm:[width,height],
           scale:ratio,views:placed}
        end
      end
    end
  end
end
