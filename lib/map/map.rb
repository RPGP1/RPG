# coding: UTF-8

require_relative './direction'
require_relative './tileset'

module RPG
  module Map
    @@current_map = nil
    @@target = nil
    @@draw_z = {lower: -30, middle: -20, upper: -10, high: 10}
    @@map_objects = []
    
    def self.new(width, height, tileset, name)
      begin
        Base.new(width, height, tileset, name)
      rescue => e
        e.set_backtrace(e.backtrace[2..-1])
        raise e
      end
    end
    
    def self.<<(map)
      return unless Base === map
      singleton_class.__send__(:define_method, map.name){map}
      @@map_objects << map.name
    end
    def self.map_objects
      @@map_objects.dup
    end
    def self.[](name)
      name = name.to_sym
      return unless @@map_objects.include?(name)
      self.__send__(name)
    end
    
    def self.set(map)
      raise RPGError, "unexpected #{map.class} object, expected #{Base} object", caller(1) unless Base === map
      @@current_map = map
    end
    def self.get
      @@current_map
    end
    
    def self.target;@@target;end
    def self.target=(v);@@target=v;end
    
    def self.z;@@draw_z;end
    
    def self.draw(tx, ty, layer = [:lower, :middle, :upper, :high])
      return if layer.empty?
      
      target = @@target.nil? ? Window : @@target
      
      @@current_map.draw(tx, ty, target, layer)
    end
    
    class Base
      attr_reader :loop, :name
      
      @@layer = [:lower, :middle, :upper, :high]
      
      #dataファイル内のMapデータを読み込む
      def self.load_data
        Dir.chdir(File.dirname(__FILE__)) do
          Dir['../../data/map/map/*.map'].each do |fname|
            Marshal.load(File.binread(fname))
          end
        end
        
        nil
      end
      
      def initialize(width, height, tileset, name)
        raise RPGError, "invalid size", caller(1) if width <= 0 || height <= 0
        @tileset = tileset
        
        @width = width
        @height = height
        
        raise RPGError, "TileSet has method `#{name}' already", caller(1) if Map.respond_to?(name, true)
        
        @name = name
        Map << self
        @name = name.to_sym
        
        @map = {}
        @info = {}
        @@layer.each do |layer|
          @map[layer] = Array.new(height){Array.new(width)}
          ifo = @info[layer] = {}
          ifo[:pass] = Array.new(height){Array.new(width){[]}}
          ifo[:land] = Array.new(height){Array.new(width){[]}}
          ifo[:move] = Array.new(height){Array.new(width){Direction.new(nil)}}
        end
        
        @loop = {up_down: false, left_right: false}
      end
      
      #tile_index_arysは[y][x]で取り出せるように
      def lay(x_range, y_range, tile_index_arys, autotile = true)
        #@loopに注意して周囲のtileを集める
        #map { tileがnilならtrue, Tile::Baseならsame_kind? }
        #得られた配列をtileのindexに渡し、@mapを書き換え
        backtrace = caller(1)
        
        #x_rangeやy_rangeがRangeでないならRangeにする
        x_range = x_range..x_range unless Range === x_range
        y_range = y_range..y_range unless Range === y_range
        
        x_first = x_range.first
        x_last = x_range.last
        x_size = x_last - x_first + 1
        y_first = y_range.first
        y_last = y_range.last
        y_size = y_last - y_first + 1
        
        #x_range, y_rangeの値とtile_index_arysのサイズが適合するかチェック
        raise RPGError, "invalid size of tile_index_arys", backtrace unless y_size == tile_index_arys.size
        raise RPGError, "invalid size of tile_index_arys", backtrace unless tile_index_arys.all?{|ary| x_size == ary.size}
        
        x_first += @width if x_first < 0
        x_last += @width if x_last < 0
        y_first += @height if y_first < 0
        y_last += @height if y_last < 0
        
        #x_range, y_rangeの端点を取り、全てが適正な値かチェック
        raise RPGError, "invalid x_position in map", backtrace unless x_first.between?(0, @width - 1) && x_last.between?(0, @width - 1)
        raise RPGError, "invalid y_position in map", backtrace unless y_first.between?(0, @height - 1) && y_last.between?(0, @height - 1)
        
        #################################
        #ここから本処理
        #################################
        
        #x_rangeやy_rangeを順に取り、対応するtile_index_arys内の配列と共にイテレータ
        y_range.each.with_index do |y, y_i|
          tile_ary_y = tile_index_arys[y_i]
          
          x_range.each.with_index do |x, x_i|
            tile_ary = tile_ary_y[x_i]
            
            tile_ary.each.with_index do |tile_i, layer_i|
              layer = @@layer[layer_i] #設定するレイヤー
              ifo = @info[layer] #info
              mp = @map[layer] #map
              
              case tile_i
              when Integer
                #tile_indexが適正かチェック
                raise RPGError, "invalid tile's index (y: #{y}, x: #{x})", backtrace unless tile_i.between?(-@tileset.size, @tileset.size-1)
                
                #@mapに配置
                mp[y][x] = tile_i
                
                tile = @tileset[tile_i][0] #Tile::Baseオブジェクトを取り出す
                ifo[:pass][y][x] = tile.info[:pass]
                ifo[:land][y][x] = tile.info[:land]
                ifo[:move][y][x] = tile.info[:move]
                
                stack_autotile(layer, x, y) if autotile
                
              when :none #削除
                #@mapに配置
                mp[y][x] = nil
                
                #@infoを更新
                ifo[:pass][y][x] = []
                ifo[:land][y][x] = []
                ifo[:move][y][x] = Direction.new(nil)
                
                stack_autotile(layer, x, y) if autotile
                
              when nil
                #何もしない
                
              else
                raise RPGError, "unexpected #{tile_i} for tile's index (y: #{y}, x: #{x})", backtrace
                
              end
            end
          end
        end
        
        update_autotile
        
        self
      end
      
      def draw(tx, ty, target, layer)
        basex = basey = 0
        image_arr = image_ary
        image_width = image_arr[0].width
        image_height = image_arr[0].height
        
        startx = (tx + 0.5) * image_width - target.width.fdiv(2)
        endx = startx + target.width - 1
        starty = (ty + 0.5) * image_height - target.height.fdiv(2)
        endy = starty + target.height - 1
        
        limitx = @width * image_width
        limity = @height * image_height
        
        until @loop[:left_right] || startx >= 0
          startx += image_width
          basex += image_width
        end
        until @loop[:left_right] || endx <= limitx
          endx -= image_width
        end
        until @loop[:up_down] || starty >= 0
          starty += image_height
          basey += image_height
        end
        until @loop[:up_down] || endy <= limity
          endy -= image_height
        end
        
        sizex = ((endx - startx) / image_width).ceil
        sizey = ((endy - starty) / image_height).ceil
        
        layer.each do |l|
          target.drawTile(basex, basey, @map[l], image_arr, startx, starty, sizex, sizey, Map.z[l])
        end
      end
      
      def image_ary
        @tileset.image_ary
      end
      
      def symbol_ary
        @tileset.symbol_ary
      end
      
      def save
        Dir.chdir(File.dirname(__FILE__)) do
          File.binwrite('../../data/map/map/' + @name.to_s + '.map', Marshal.dump(self))
        end
        nil
      end
      
      def marshal_dump
        require 'zlib'
        
        Zlib::Deflate.deflate(
                              Marshal.dump(
                                           {tileset: @tileset.name,
                                           name: @name,
                                           map: @map,
                                           info: @info,
                                           loop: @loop,
                                           }
                                           )
                              )
      end
      
      def marshal_load(str)
        require 'zlib'
        
        hash = Marshal.load(Zlib::Inflate.inflate(str))
        
        tileset = hash[:tileset]
        @tileset = (Array === tileset ? tileset.map{|sym| TileSet.__send__(sym)}.inject(:+) : TileSet.__send__(tileset))
        @name = hash[:name]
        Map << self
        @map = hash[:map]
        @info = hash[:info]
        @loop = hash[:loop]
        
        @width = @map[:lower][0].size
        @height = @map[:lower].size
      end
      
      def inspect
        "\#<#{self.class}:0x#{self.object_id.to_s(16)} #{@width} * #{@height} (tileset:#{@tileset})}>"
      end
      
      private
      def stack_autotile(layer, x, y)
        @stacked_autotile ||= []
        x %= @width
        y %= @height
        
        #周囲をそれぞれ考える
        3.times.with_index(x-1) do |_, x|
          3.times.with_index(y-1) do |_, y|
            next unless x >= 0 || @loop[:left_right]
            next unless x < @width || @loop[:left_right]
            next unless y >= 0 || @loop[:up_down]
            next unless y < @height || @loop[:up_down]
            
            @stacked_autotile << [layer, x, y]
          end
        end
      end
      
      def update_autotile
        return unless @stacked_autotile
        
        @stacked_autotile.uniq!
        @stacked_autotile.size.times do
          layer, x, y = @stacked_autotile.shift
          mp = @map[layer]
          
          x %= @width
          y %= @height
          
          next unless mp[y][x]
          tile = @tileset[mp[y][x]][0]
          
          around_tile = []
          3.times.with_index(y-1) do |y_i, y|
            3.times.with_index(x-1) do |x_i, x|
              next if x_i == 1 && y_i == 1
              @loop[:left_right] ? x += @width : (next around_tile << true) if x < 0
              @loop[:left_right] ? x -= @width : (next around_tile << true) if x >= @width
              @loop[:up_down] ? y += @height : (next around_tile << true) if y < 0
              @loop[:up_down] ? y -= @height : (next around_tile << true) if y >= @height
              
              if tile_i = mp[y][x]
                around_tile << (@tileset[tile_i][0] === tile)
              else
                around_tile << false
              end
            end
          end
          
          mp[y][x] = @tileset.index(tile, tile.index(around_tile))
        end
        
        nil
      end
      
    end
  end
end
