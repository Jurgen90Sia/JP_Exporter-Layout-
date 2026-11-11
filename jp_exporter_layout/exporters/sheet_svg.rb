# frozen_string_literal: true
require 'cgi'
require_relative '../sheets/plan'
require_relative '../atomic_file'
module JPExporter
  module Layout
    module Exporters
      module SheetSVG
        module_function
        def generate(snapshot, title: 'JP Exporter Layout', **options)
          unless title.is_a?(String) && title.valid_encoding? && title.length <= 200 && !title.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F]/)
            raise ValidationError, 'Sheet title must be valid text of up to 200 characters.'
          end
          plan = Sheets::Plan.call(snapshot,**options)
          width,height = plan[:paper_mm]
          ratio = plan[:scale]
          xml = [%(<?xml version="1.0" encoding="UTF-8"?>),
                 %(<svg xmlns="http://www.w3.org/2000/svg" width="#{width}mm" height="#{height}mm" viewBox="0 0 #{width} #{height}">),
                 %(<rect x="0" y="0" width="#{width}" height="#{height}" fill="white"/>)]
          plan[:views].each do |view|
            x,y,w,h = view[:cell_mm]
            dx,dy = view[:drawing_mm]
            b = view[:bounds]
            xml << %(<g fill="none" stroke="#111" stroke-width="0.25">)
            view[:edges].each do |edge|
              a,c = edge[:points].map { |p| [dx+(p[0]-b[0])*ratio,dy+(b[3]-p[1])*ratio] }
              xml << %(<line x1="#{a[0]}" y1="#{a[1]}" x2="#{c[0]}" y2="#{c[1]}"/>)
            end
            xml << '</g>'
            xml << %(<text x="#{x+w/2}" y="#{y+h-2}" font-family="sans-serif" font-size="3.5" text-anchor="middle">#{view[:view]}</text>)
          end
          xml << %(<text x="10" y="#{height-14}" font-family="sans-serif" font-size="4">#{CGI.escapeHTML(title)}</text>)
          xml << %(<text x="10" y="#{height-7}" font-family="sans-serif" font-size="3">Wireframe · scale #{format('%.8g',ratio)}:1 · print at 100% · model mm</text>)
          xml << '</svg>'
          xml.join("\n")
        end
        def save(path,snapshot,**options)
          AtomicFile.write(path,generate(snapshot,**options))
        end
      end
    end
  end
end
