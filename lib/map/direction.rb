# coding: UTF-8

module RPG
  module UP
    def self.opposite
      DOWN
    end
    
    def self.vector
      [0, -1]
    end
    
    def self.index
      0
    end
  end
  
  module RIGHT
    def self.opposite
      LEFT
    end
    
    def self.vector
      [1, 0]
    end
    
    def self.index
      1
    end
  end
  
  module DOWN
    def self.opposite
      UP
    end
    
    def self.vector
      [0, 1]
    end
    
    def self.index
      2
    end
  end
  
  module LEFT
    def self.opposite
      RIGHT
    end
    
    def self.vector
      [-1, 0]
    end
    
    def self.index
      3
    end
  end
  
  class Direction
    def initialize(all = nil, up: nil, down: nil, left: nil, right: nil)
      all    =        (all   ? true : nil)
      @up    = all || (up    ? true : nil)
      @down  = all || (down  ? true : nil)
      @left  = all || (left  ? true : nil)
      @right = all || (right ? true : nil)
    end
    
    def up?;       @up;                       end
    def up=(v);    @up    = (v ? true : nil); end
    
    def down?;     @down;                     end
    def down=(v);  @down  = (v ? true : nil); end
    
    def left?;     @left;                     end
    def left=(v);  @left  = (v ? true : nil); end
    
    def right?;    @right;                    end
    def right=(v); @right = (v ? true : nil); end
    
    def able?(d)
      i = d.respond_to?(:index) ? d.index : d
      [@up, @right, @down, @left][i]
    end
    
    def inspect
      ary = []
      ary << "UP" if @up
      ary << "DOWN" if @down
      ary << "LEFT" if @left
      ary << "RIGHT" if @right
      ary *= ", "
      
      "#<Direction:0x" + self.object_id.to_s(16) + " #{ary}>"
    end
  end
end
