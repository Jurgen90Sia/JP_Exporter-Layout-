# Only contracts consumed by the extractor; not a SketchUp emulator.
module Geom
  class Transformation
    attr_reader :matrix
    def initialize(scale = [1,1,1], shift = [0,0,0], matrix = nil)
      @matrix = matrix || [[scale[0],0,0,shift[0]], [0,scale[1],0,shift[1]],
                           [0,0,scale[2],shift[2]], [0,0,0,1]]
    end
    def *(other)
      product = Array.new(4) { |i| Array.new(4) { |j| (0...4).inject(0) { |s,k| s + matrix[i][k]*other.matrix[k][j] } } }
      Transformation.new(nil,nil,product)
    end
    def apply(point)
      vector = point.to_a + [1]
      values = matrix.first(3).map { |row| row.zip(vector).inject(0) { |s,(a,b)| s+a*b } }
      Point.new(*values)
    end
  end
  Point = Struct.new(:x,:y,:z) do
    def transform(t); t.apply(self); end
  end
end
module Sketchup
  Vertex = Struct.new(:position)
  class Edge
    attr_reader :start, :end, :entityID
    def initialize(id, a, b, hidden = false)
      @entityID, @start, @end, @hidden = id, Vertex.new(Geom::Point.new(*a)), Vertex.new(Geom::Point.new(*b)), hidden
    end
    def hidden?; @hidden; end
    def valid?; true; end
    def layer; Struct.new(:visible?).new(true); end
  end
  Definition = Struct.new(:entities)
  class ComponentInstance
    attr_reader :definition, :transformation, :entityID
    def initialize(id, definition, transformation)
      @entityID, @definition, @transformation = id, definition, transformation
    end
    def hidden?; false; end
    def valid?; true; end
    def layer; Struct.new(:visible?).new(true); end
  end
  class Group < ComponentInstance
    def entities; definition.entities; end
  end
  Face = Struct.new(:edges)
end
