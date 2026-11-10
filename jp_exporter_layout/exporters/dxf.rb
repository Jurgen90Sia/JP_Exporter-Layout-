# frozen_string_literal: true
require_relative '../drawing'
require_relative '../atomic_file'
module JPExporter
  module Layout
    module Exporters
      # ASCII R2000 model-space wireframe. Dimensions are exploded LINE/TEXT graphics.
      module DXF
        module_function
        def generate(drawing)
          Drawing.validate!(drawing)
          values = [0,'SECTION',2,'HEADER',9,'$ACADVER',1,'AC1015',9,'$INSUNITS',70,4,0,'ENDSEC',
                    0,'SECTION',2,'TABLES',0,'TABLE',2,'LTYPE',5,'101',100,'AcDbSymbolTable',70,1,
                    0,'LTYPE',5,'102',330,'101',100,'AcDbSymbolTableRecord',100,'AcDbLinetypeTableRecord',
                    2,'JP_DASHED',70,0,3,'Hidden lines',72,65,73,2,40,9.0,49,6.0,74,0,49,-3.0,74,0,
                    0,'ENDTAB',0,'TABLE',2,'LAYER',5,'100',100,'AcDbSymbolTable',70,3,
                    0,'LAYER',5,'103',330,'100',100,'AcDbSymbolTableRecord',100,'AcDbLayerTableRecord',
                    2,'JP_GEOMETRY',70,0,62,7,6,'CONTINUOUS',
                    0,'LAYER',5,'104',330,'100',100,'AcDbSymbolTableRecord',100,'AcDbLayerTableRecord',
                    2,'JP_HIDDEN',70,0,62,8,6,'JP_DASHED',
                    0,'LAYER',5,'105',330,'100',100,'AcDbSymbolTableRecord',100,'AcDbLayerTableRecord',
                    2,'JP_DIMENSIONS',70,0,62,3,6,'CONTINUOUS',0,'ENDTAB',0,'ENDSEC',
                    0,'SECTION',2,'ENTITIES']
          drawing[:edges].each { |edge| line(values, edge[:points], edge[:role] == 'hidden' ? 'JP_HIDDEN' : 'JP_GEOMETRY') }
          drawing.fetch(:dimensions, []).each do |d|
            line(values, d[:line], 'JP_DIMENSIONS')
            2.times { |i| line(values, [d[:anchors][i],d[:line][i]], 'JP_DIMENSIONS') }
            # Diagonal ticks; symbol/text size is supplied in model mm for this export.
            tick = d.fetch(:text_height_mm,3.0) / 3.0
            d[:line].each { |p| line(values, [[p[0]-tick,p[1]-tick],[p[0]+tick,p[1]+tick]], 'JP_DIMENSIONS') }
            values.concat([0,'TEXT',100,'AcDbEntity',8,'JP_DIMENSIONS',100,'AcDbText',10,d[:text_at][0],20,d[:text_at][1],30,0,
                           40,d.fetch(:text_height_mm,3.0),1,ascii_text(d[:text]),50,d[:axis] == 'vertical' ? 90 : 0,
                           100,'AcDbText'])
          end
          values.concat([0,'ENDSEC',0,'EOF'])
          values.map { |v| v.is_a?(Float) ? format('%.9f',v).sub(/0+$/, '').sub(/\.$/, '.0') : v.to_s }.join("\r\n") + "\r\n"
        end
        def line(values, points, layer)
          a,b = points
          values.concat([0,'LINE',100,'AcDbEntity',8,layer,100,'AcDbLine',10,a[0],20,a[1],30,0,11,b[0],21,b[1],31,0])
        end
        def ascii_text(text)
          text.each_char.map do |char|
            char.ord.between?(32,126) ? char : char.encode('UTF-16BE').unpack('n*').map { |unit| format('\\U+%04X',unit) }.join
          end.join
        end
        def save(path, drawing)
          AtomicFile.write(path, generate(drawing))
        end
      end
    end
  end
end
