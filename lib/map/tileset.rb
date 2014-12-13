# coding: UTF-8

require_relative './tile'

module RPG
  module TileSet
    #TileSet::Baseを継承したクラスを自動で保持
    @@tileset_classes = []
    @@tileset_objects = []
    def self.<<(tileset)
      @@tileset_classes << tileset if Class === tileset
      if Base === tileset
        singleton_class.__send__(:define_method, tileset.name){tileset}
        @@tileset_objects << tileset.name
      end
    end
    def self.tileset_classes
      @@tileset_classes.dup
    end
    def self.tileset_objects
      @@tileset_objects.dup
    end
    
    #画像を持っているTileSetを保持
    #TileSetが一定数起きたら眠らせる
    @@awake_tilesets = []
    def self.record_awake(tileset)
      @@awake_tilesets << tileset
      
      return TileSet unless @@sleep_limit
      
      if (difference = @@awake_tilesets.size - @@sleep_limit) > 0
        @@awake_tilesets.shift(difference).each(&:sleep)
      end
      
      nil
    end
    def self.remove_awake_record(tileset)
      @@awake_tilesets.delete(tileset)
      
      nil
    end
    
    #TileSetが一定数起きたら眠らせる時の「一定数」
    @@sleep_limit = nil
    def self.sleep_limit
      @@sleep_limit
    end
    def self.sleep_limit=(v)
      if v || v == false
        return if !(Integer === v)
        return if v < 1
      end
      
      @@sleep_limit = v
    end
    
    class Base
      #全てのタイルセットの基本
      
      ############################################
      #set_tileをサブクラスで用意すること
      ############################################
      
      attr_reader :refreshable, :name
      
      #継承されたらTileSetモジュールに保存する
      def self.inherited(subclass)
        TileSet << subclass
      end
      
      #dataファイル内のTileSetBaseデータを読み込む
      def self.load_data
        Dir.chdir(File.dirname(__FILE__)) do
          Dir['../../data/tileset/*.tileset'].each do |fname|
            Marshal.load(File.binread(fname))
          end
        end
        
        nil
      end
      
      #タイルセット画像を渡して生成
      def initialize(image, name)
        begin
          TileSet.method(name)
          raise RPGError, "TileSet has method `#{name}' already", caller(1)
        rescue NameError
        end
        
        @name = name
        TileSet << self
        @name = name.to_sym
        
        @tile = [] #タイル配列
        set_tile(@image = image) #タイルを配列にセット
        
        @size = @tile.inject(0){|result, item| result + item.size}
        def size(type = :image)
          case type
          when :image
            return @size
          when :symbol
            return @tile.size
          end
        end
        
        #refreshableなTileを選別
        refreshable_ary = @tile.select(&:refreshable)
        if @refreshable = !refreshable_ary.empty?
          @refreshable = true
          @refreshable_ary = refreshable_ary
          def refresh
            return if @before == (@before = Window.running_time)
            @refreshable_ary.each(&:refresh)
            @refreshed = @refreshable_ary.any?(&:refreshed?)
          end
          
          def refreshed?
            @refreshed
          end
        end
        
        #後から変更した画像
        @change = {symbol: {}, image: {}}
        @symbol_ary = @image_ary = nil
        
        @initialized = true
        @sleeping = true
      end
      
      #@tileのsymbolの配列
      def symbol_ary
        awake #機能停止中なら戻す
        
        #既に画像を抽出していればそれを返す
        if @symbol_ary
          return @symbol_ary unless @refreshable
          refresh
          return @symbol_ary unless refreshed?
        else
          refresh if @refreshable
        end
        
        #無ければタイル配列から取り出す
        @symbol_ary = @tile.map(&:symbol)
        #変更が有れば反映
        @change[:symbol].each_pair do |i, img|
          @symbol_ary[i] = img
        end
        
        @symbol_ary
      end
      
      #@tileのimageの配列(1次元)
      def image_ary
        awake #機能停止中なら戻す
        
        if @image_ary
          return @image_ary unless @refreshable
          refresh
          return @image_ary unless refreshed?
        else
          refresh if @refreshable
        end
        
        #無ければタイル配列から取り出す
        @image_ary = @tile.flat_map(&:image)
        #変更が有れば反映
        @change[:image].each_pair do |i, img|
          @image_ary[i] = img
        end
        
        @image_ary
      end
      
      #TileとTile内index
      def [](i, type: :image)
        case type
        when :image
          i += @size if i < 0
          return unless i.between?(0, @size-1)
          return unless result1 = @tile.find{|t| (i -= t.size) < 0}
          result2 = i + result1.size
        when :symbol
          i += @tile.size if i < 0
          return unless i.between?(0, @tile.size-1)
          result1 = @tile[i]
          result2 = 0
        end
        return result1, result2
      end
      
      #全体のindex
      def index(tile, tile_i = 0, type: :image)
        return unless @tile.include?(tile)
        ary = @tile.take_while{|t| t != tile}
        
        case type
        when :image
          tile_i += tile.size if tile_i < 0
          return unless tile_i.between?(0, tile.size-1)
          return ary.inject(0){|result, item| result + item.size} + tile_i
        when :symbol
          tile_i += 1 if tile_i < 0
          return unless tile_i == 0
          return ary.size
        end
      end
      
      def replace_image(tile, tile_i, image, type: :image)
        return unless ary = @change[type]
        return i = index(tile, tile_i, type: type)
        
        ary[i] = image
        return self if @sleeping
        
        case type
        when :image
          @image_ary[i] = image
        when :symbol
          @symbol_ary[i] = image
        end
        
        self
      end
      
      def +(other)
        raise TypeError, "#{other} can't be coerced into TileSet::Base or TileSet::Group", caller(1) unless Base === other || Group === other
        
        g = Group.__send__(:allocate)
        g.__send__(:initialize, self, *other.to_a)
        
        g
      end
      
      def to_a
        [self]
      end
      
      #機能停止してメモリ節約
      def sleep
        return if @sleeping
        
        @tile.each(&:sleep)
        TileSet.remove_awake_record(self)
        @sleeping = true
        
        nil
      end
      
      #機能停止から復活
      def awake(record = true)
        return unless @sleeping
        
        set_tile(@image)
        TileSet.record_awake(self) if record #Group内用
        @sleeping = false
        
        nil
      end
      
      def save
        Dir.chdir(File.dirname(__FILE__)) do
          File.binwrite('../../data/tileset/' + @name.to_s + '.tileset', Marshal.dump(self))
        end
        nil
      end
      
      #Marshal対応
      def marshal_dump
        require 'zlib'
        
        Marshal.dump(
                     {image:  @image,
                     tile:   @tile,
                     change: @change,
                     name: @name}
                     )
      end
      
      def marshal_load(str)
        hash = Marshal.load(str)
        
        @image  = hash[:image]
        @tile   = hash[:tile]
        @change = hash[:change]
        @name   = hash[:name]
        TileSet << self
        
        @initialized = true #初期化終了したと見なす
        #↓
        set_tile(@image) #layerを設定
        
        @size = @tile.inject(0){|result, item| result + item.size}
        def size(type = :image)
          case type
          when :image
            return @size
          when :symbol
            return @tile.size
          end
        end
        
        refreshable_ary = @tile.select(&:refreshable)
        if @refreshable = !refreshable_ary.empty?
          @refreshable_ary = refreshable_ary
          def refresh
            return if @before == (@before = Window.running_time)
            @refreshable_ary.each(&:refresh)
            @refreshed = @refreshable_ary.any?(&:refreshed?)
          end
          
          def refreshed?
            @refreshed
          end
        end
        
        @symbol_ary = @image_ary = nil
        @sleeping = true #機能停止中かどうか/最初は止めておく
      end
      
      def inspect
        "\#<#{self.class.name}:0x#{self.object_id.to_s(16)} (size: #{size})>"
      end
      
      private
      
      #set_tile内部処理
      #tile_classにTileのサブクラスを、それに続けて引数を
      def create_tile(tile_class, img, **opt)
        unless @initialized
          #initialize中なら
          
          tile = tile_class.new(**opt) #生成して
          @tile << tile #登録して
          return tile #返す
        end
        
        @cycle ||= @tile.cycle
        #awake中なら:awake
        #marshal_load中なら:set_layer
        tile = @cycle.next
        if @sleeping
          tile.awake(img, **opt)
        else
          tile.__send__(:set_layer, **opt)
        end
        
        return tile
      end
    end
    
    class Group
      #タイルを纏めて扱うクラス
      # TileSet#+ で生成
      
      class << self
        undef :new
      end
      
      attr_reader :refreshable
      
      def initialize(*tilesets)
        @tilesets = tilesets.uniq
        tilesets.each(&:sleep)
        
        @size = @tilesets.inject(0){|result, item| result + item.size}
        @symbol_size = @tilesets.inject(0){|result, item| result + item.size(:symbol)}
        def size(type = :image)
          case type
          when :image
            return @size
          when :symbol
            return @symbol_size
          end
        end
        
        #refreshableなTileSetを選別
        refreshable_ary = @tilesets.select(&:refreshable)
        if @refreshable = !refreshable_ary.empty?
          @refreshable = true
          @refreshable_ary = refreshable_ary
          def refresh
            return if @before == (@before = Window.running_time)
            @refreshable_ary.each(&:refresh)
            @refreshed = @refreshable_ary.any?(&:refreshed?)
          end
          
          def refreshed?
            @refreshed
          end
        end
        
        @symbol_ary = @image_ary = nil
        TileSet.remove_awake_record(self)
        @sleeping = true
      end
      
      #@tilesetsのsymbol_aryの配列
      def symbol_ary
        awake #機能停止中なら戻す
        
        #既に画像を抽出していればそれを返す
        if @symbol_ary
          return @symbol_ary unless @refreshable
          refresh
          return @symbol_ary unless refreshed?
        else
          refresh if @refreshable
        end
        
        #無ければタイル配列から取り出す
        @symbol_ary = @tilesets.map(&:symbol_ary)
      end
      
      #@tilesetsのimage_aryの配列(1次元)
      def image_ary
        awake #機能停止中なら戻す
        
        if @image_ary
          return @image_ary unless @refreshable
          refresh
          return @image_ary unless refreshed?
        else
          refresh if @refreshable
        end
        
        #無ければタイル配列から取り出す
        @image_ary = @tilesets.flat_map(&:image_ary)
      end
      
      #TileとTile内index
      def [](i, type: :image)
        case type
        when :image
          i += @size if i < 0
          return unless i.between?(0, @size-1)
          t_set = @tilesets.find{|ts| (i -= ts.size) < 0}
          return t_set[i + t_set.size, type: type]
        when :symbol
          i += @symbol_size if i < 0
          return unless i.between?(0, @symbol_size-1)
          t_set = @tilesets.find{|ts| (i -= ts.size(:symbol)) < 0}
          return t_set[i + ts.size(:symbol), type: type]
        end
      end
      
      #全体のindex
      def index(tile, tile_i = 0, type: :image)
        result = 0
        success = nil
        @tilesets.each do |ts|
          if i = ts.index(tile, tile_i, type: type)
            result += i
            success = true
            break
          else
            result += ts.size(type)
          end
        end
        return unless success
        result
      end
      
      def +(other)
        raise TypeError, "#{other} can't be coerced into TileSet::Base or TileSet::Group", caller(1) unless Base === other || Group === other
        
        self.__send__(:initialize, *@tilesets, *other.to_a)
        
        self
      end
      
      def replace_image(tile, tile_i, image, type: :image)
        @tilesets.find{|ts| ts.replace_image(tile, tile_i, image, type: type)} ? self : nil
      end
      
      def to_a
        @tilesets
      end
      
      def name
        @tilesets.map(&:name)
      end
      
      def sleep
        return if @sleeping
        
        @tilesets.each(&:sleep)
        TileSet.remove_awake_record(self)
        @sleeping = true
        
        nil
      end
      
      def awake
        return unless @sleeping
        
        @tilesets.each{|ts| ts.awake(false)}
        TileSet.record_awake(self)
        @sleeping = false
        
        nil
      end
    end
    
    class A1 < Base
      private
      
      def set_tile(image)
        #########################
        #  /  / 0# 2#  /  / 4# 5#
        #########################
        #  /  / 1# 3#  /  / 6# 7#
        #########################
        #  /  / 8# 9#  /  /10#11#
        #########################
        #  /  /12#13#  /  /14#15#
        #########################
        
        ary = image.sliceTiles(8, 4)
        
        sea = create_tile(Tile::Water, ary[0..2])
        create_tile(Tile::DeepSea, ary[8..10], sea: sea)
        create_tile(Tile::Rock, ary[3], sea: sea)
        create_tile(Tile::Rock, ary[11], sea: sea)
        [4, 12, 16, 20, 24, 28].each do |i|
          create_tile(Tile::Water, ary[i..(i + 2)])
          create_tile(Tile::WaterFall, ary[i + 3])
        end
        
        self
      end
    end
    
    class A2 < Base
      private
      
      def set_tile(image)
        ary = image.sliceTiles(8, 4)
        
        4.times do |y|
          y *= 8
          2.times do |x|
            x *= 3
            ground = create_tile(Tile::Ground, ary[x + y])
            create_tile(Tile::Bush, ary[x + y + 1])
            create_tile(Tile::Block, ary[x + y + 2])
          end
          
          2.times do |x|
            x += 6
            create_tile(Tile::Pavement, ary[x + y])
          end
        end
        
        self
      end
    end
    
    class A3 < Base
      private
      def set_tile(image)
        ary = image.sliceTiles(8, 4)
        
        2.times do |y|
          y1 = y * 16
          8.times do |x|
            2.times do |y|
              y2 = y * 8
              create_tile(Tile::Outside, ary[x + y1 + y2])
            end
          end
        end
        
        self
      end
    end
    
    class A4 < Base
      private
      
      def set_tile(image)
        ary = image.sliceTiles(8, 3)
        
        width = ary[0].width
        height = ary[0].height
        
        ary.each do |img|
          create_tile(Tile::WallTop, img.slice(0,0,width,(y = height * 3 / 5)))
          create_tile(Tile::Wall, img.slice(0,y,width,height - y))
        end
        
        self
      end
    end
    
    class A5 < Base
      private
      def set_tile(image)
        image.sliceTiles(8, 16).each do |img|
          create_tile(Tile::Floor, img)
        end
        
        self
      end
    end
    
    class B < Base
      private
      
      def set_tile(image)
        ary = image.sliceTiles(16,16)
        
        2.times do |x|
          x1 = x * 8
          16.times do |y|
            y *= 16
            8.times do |x2|
              create_tile(Tile::Upper, ary[x1 + x2 + y])
            end
          end
        end
      end
    end
    
    E = D = C = B
  end
end
