# coding: UTF-8

require_relative './direction'

module DXRuby
  class Image
    def self.dispose(*args)
      args.each do |obj|
        if Array === obj
          self.dispose(*obj) unless obj.empty?
        else
          next unless obj.respond_to?(:dispose)
          (next if obj.disposed?) if obj.respond_to?(:disposed?)
          obj.dispose
        end
      end
      
      nil
    end
  end
  
  class RenderTarget
    def self.dispose(*args)
      args.each do |obj|
        if Array === obj
          self.dispose(*obj) unless obj.empty?
        else
          next unless obj.respond_to?(:dispose)
          (next if obj.disposed?) if obj.respond_to?(:disposed?)
          obj.dispose
        end
      end
      
      nil
    end
  end
end

module RPG
  module Tile
    class Base
      #全てのタイルの基本
      
      ############################################
      #indexとset_imageとsizeをサブクラスで用意すること
      #(代替となるモジュールをincludeしてもよし)
      #       AutotileTile, SetPatternTile, WaterFallTile, OneImageTile
      ############################################
      
      attr_reader :symbol, :image, :size, :layer, :info
      
      def initialize(**opt)
        @info = {}
        
        set_layer(**opt) #層を設定
        set_info(**opt)
        
        @info[:refreshable] = false
      end
      
      #tileが周囲に配置された時、selfを同じタイルとみなすか
      def ===(tile)
        self == tile
      end
      
      def refreshable
        @info[:refreshable]
      end
      
      #メモリ節約のため、使用しない時はsleepしておく
      def sleep
        Image.dispose(@symbol, @image)
        @symbol = @image = nil
        
        nil
      end
      
      def awake(image, **opt)
        set_image(image, **opt)
        
        self
      end
      
      #Marshal対応
      def marshal_dump
        Marshal.dump(@info)
      end
      
      def marshal_load(str)
        @info = Marshal.load(str)
        #これの後に@layer設定がされることを想定
        
        self
      end
      
      def inspect
        cname = self.class.name
        
        id = "0x" + self.object_id.to_s(16)
        
        symbol = "<##{@symbol.class.name}:0x#{@symbol.object_id.to_s(16)}>" if @symbol
        symbol ||= @symbol.inspect
        
        r = rand.to_s #self置き換え用のランダム文字列
        rayer = @layer.dup.map do |t|
          t == self ? r : #selfはrに
          (Base === t ? "<##{t.class.name}:0x#{t.object_id.to_s(16)}>" :
           t)
        end
        rayer = rayer.inspect.gsub('"' + r + '"', "self") #rを"self"に
        
        info = @info.inspect
        
        "\#<" + cname + ":" + id + " " + symbol + " (layer:" + rayer + " info:" + info + ")>"
      end
      
      private
      
      #ユーザはレイヤー設定で基本はココをいじる
      def set_layer(**opt)
        #defaultでは下層に自身のみ配置
        
        @layer = [self, :none, nil, nil]
        #この様に@layer ([下層, 中層, 上層, すり抜け層])
        #  を設定すればいい
        #selfを含め、Tileオブジェクトを設定
        #  nilにすると何もしない
        #  :noneとすると削除する
        #別の画像を一つのタイルに設定したい場合は
        #  別のTileオブジェクトを用意する
        
        self
      end
      
      #ユーザは追加情報設定で基本はココをいじる
      def set_info(**opt)
        #defaultでは移動設定・属性付与・タグ付
        
        set_walkable(**opt)
        set_attribute(**opt)
        set_tag(**opt)
        
        self
      end
      
      #ユーザは移動設定で基本はココをいじる
      def set_walkable(**opt)
        #defaultでは
        #歩行・浮遊・飛行機が通行可
        #浮遊・飛行機が着陸可
        #全方向に移動可能
        
        #移動手段と対応するSymbol
        #  歩行 :walk
        #  小舟 :boat
        #  船舶 :ship
        #  浮遊 :float
        #  飛行機 :plane
        @info[:pass] = [:walk, :float, :plane]
        @info[:land] = [:float, :plane]
        #:pass 通行可能な(=そのマスに乗れる)移動手段の配列
        #:land 飛行系のみ。着陸可能な(=歩行に戻れる)移動手段の配列
        
        @info[:move] = Direction.new(true)
        #:move 地上系のみに影響。移動できる方向のDirection
        #      Directionクラスについては./direction.rbを参照
        
        self
      end
      
      def set_attribute(**opt)
        #属性付与
        #  梯子 :ladder
        #  茂み :bush
        #  カウンター :counter
        #  ダメージ床 :damage
        @info[:attribute] = []
        
        self
      end
      
      def set_tag(**opt)
        #地形タグ
        @info[:tag] = 0
        
        self
      end
    end
    
    ############################################
    #indexとset_imageとsizeの代替モジュール群
    ############################################
    module AutotileTile
      @@num_i = [Complex(1,0),
        Complex(0,1),
        Complex(0,-1),
        Complex(-1,0)]
      @@i_num = {Complex(1,0) => 0,
        Complex(0,1) => 1,
        Complex(0,-1) => 2,
        Complex(-1,0) => 3}
      @@result = [586,
        286,
        456,
        31,
        156,
        598,
        298,
        453,
        468,
        28,
        153,
        43,
        168,
        612,
        262,
        312,
        482,
        7,
        57,
        132,
        182,
        620,
        624,
        270,
        320,
        274,
        324,
        475,
        490,
        479,
        494,
        0,
        50,
        125,
        175,
        15,
        65,
        140,
        190,
        4,
        54,
        129,
        179,
        19,
        69,
        144,
        194]
      @@part = [[8, 11, 20, 23],
        [8, 11, 12, 15],
        [8, 9, 20, 21],
        [8, 9, 12, 7],
        [8, 9, 12, 13],
        [16, 19, 20, 23],
        [16, 19, 12, 15],
        [16, 3, 20, 21],
        [16, 17, 20, 21],
        [16, 3, 12, 7],
        [16, 3, 12, 13],
        [16, 17, 12, 7],
        [16, 17, 12, 13],
        [10, 11, 22, 23],
        [10, 11, 6, 15],
        [10, 11, 14, 15],
        [10, 9, 22, 21],
        [10, 9, 6, 7],
        [10, 9, 14, 7],
        [10, 9, 6, 13],
        [10, 9, 14, 13],
        [2, 19, 22, 23],
        [18, 19, 22, 23],
        [2, 19, 6, 15],
        [2, 19, 14, 15],
        [18, 19, 6, 15],
        [18, 19, 14, 15],
        [2, 3, 22, 21],
        [2, 17, 22, 21],
        [18, 3, 22, 21],
        [18, 17, 22, 21],
        [2, 3, 6, 7],
        [2, 3, 14, 7],
        [2, 3, 6, 13],
        [2, 3, 14, 13],
        [2, 17, 6, 7],
        [2, 17, 14, 7],
        [2, 17, 6, 13],
        [2, 17, 14, 13],
        [18, 3, 6, 7],
        [18, 3, 14, 7],
        [18, 3, 6, 13],
        [18, 3, 14, 13],
        [18, 17, 6, 7],
        [18, 17, 14, 7],
        [18, 17, 6, 13],
        [18, 17, 14, 13]]
      
      #[左上から右方向に右下まで、自分を除いた8マスの===結果]
      #ary#######
      #0#1#2#
      #######
      #3#@#4#
      #######
      #5#6#7#
      #######
      def index(ary)
        side = {Complex(1,0) => ary[3],
          Complex(0,1) => ary[1],
          Complex(-1,0) => ary[4],
          Complex(0,-1) => ary[6]}
        apex = {Complex(1,0) => ary[0],
          Complex(0,1) => ary[2],
          Complex(-1,0) => ary[7],
          Complex(0,-1) => ary[5]}
        
        @@result.index(
                       Array.new(4){|i|
                       num = @@num_i[i]
                       pos = 0
                       pos += 1 if side[num]
                       pos += 2 if side[num * 1.i]
                       pos -= 4 if pos == 3 && !apex[num]
                       pos = ((pos != -1) ? @@i_num[@@num_i[pos] * num] : -1) + 1
                       pos * (5 ** i)
                       }.inject(&:+)
                       )
      end
      
      def size
        47
      end
      
      private
      def set_image(image, **opt)
        ary = image.sliceTiles(4,6)
        part_width = ary[0].width
        part_height = ary[1].height
        width = part_width * 2
        height = part_height * 2
        
        @symbol = image.slice(0,0,width,height)
        @image = @@part.map{|part|
          img = Image.new(width, height)
          part.each.with_index{|index, i|
            img.draw((i % 2) * part_width, (i / 2) * part_height, ary[index])
          }
          img
        }
        
        [@symbol, @image]
      end
    end
    
    module SetPatternTile
      @@num_i = [Complex(1,0),
        Complex(0,1),
        Complex(0,-1),
        Complex(-1,0)]
      @@i_num = {Complex(1,0) => 0,
        Complex(0,1) => 1,
        Complex(0,-1) => 2,
        Complex(-1,0) => 3}
      @@result = [228,
        245,
        238,
        255,
        160,
        177,
        170,
        187,
        68,
        85,
        78,
        95,
        0,
        17,
        10,
        27]
      @@part = [[0, 3, 12, 15],
        [2, 3, 14, 15],
        [8, 11, 12, 15],
        [10, 11, 14, 15],
        [0, 1, 12, 13],
        [2, 1, 14, 13],
        [8, 9, 12, 13],
        [10, 9, 14, 13],
        [0, 3, 4, 7],
        [2, 3, 6, 7],
        [8, 11, 4, 7],
        [10, 11, 6, 7],
        [0, 1, 4, 5],
        [2, 1, 6, 5],
        [8, 9, 4, 5],
        [10, 9, 6, 5]]
      
      def index(ary)
        side = {Complex(1,0) => ary[3],
          Complex(0,1) => ary[1],
          Complex(-1,0) => ary[4],
          Complex(0,-1) => ary[6]}
        
        @@result.index(
                       Array.new(4){|i|
                       num = @@num_i[i]
                       pos = 0
                       pos += 1 if side[num]
                       pos += 2 if side[num * 1.i]
                       pos = @@i_num[@@num_i[pos] * num]
                       pos * (4 ** i)
                       }.inject(&:+)
                       )
      end
      
      def size
        16
      end
      
      private
      def set_image(image, **opt)
        ary = image.sliceTiles(4,4)
        part_width = ary[0].width
        part_height = ary[1].height
        width = part_width * 2
        height = part_height * 2
        
        @image = @@part.map{|part|
          img = Image.new(width, height)
          part.each.with_index{|index, i|
            img.draw((i % 2) * part_width, (i / 2) * part_height, ary[index])
          }
          img
        }
        @symbol = @image[0]
        
        [@symbol, @image]
      end
    end
    
    module WaterFallTile
      @@part = [[0, 3], #孤立
        [0, 1], #右だけ
        [2, 3], #左だけ
        [2, 1]] #左右
      
      def index(ary)
        result = 0
        result += 1 if ary[3]
        result += 2 if ary[4]
        result
      end
      
      def size
        4
      end
      
      private
      def set_image(image, **opt)
        ary = image.sliceTiles(4,1)
        part_width = ary[0].width
        width = part_width * 2
        height = ary[0].height
        
        @image = @@part.map{|part|
          img = Image.new(width, height)
          part.each.with_index{|index, i|
            img.draw(i * part_width, 0, ary[index])
          }
          img
        }
        @symbol = @image[0]
        
        [@symbol, @image]
      end
    end
    
    module OneImageTile
      def index(ary)
        0
      end
      
      def size
        1
      end
      
      private
      def set_image(image, **opt)
        @image = [@symbol = image]
        [@symbol, @image]
      end
    end
    
    #######################################################################
    #タイルをアニメーションさせるモジュール
    #!!!index/set_image定義の代替モジュールの後にincludeすること!!!
    #
    #<使い方>
    #initialize時にアニメーション送りのフレーム数をIntegerで渡す
    #set_image時にアニメーション1枚ずつに分割したImageを必要分渡す
    #######################################################################
    module AnimationTile
      def initialize(animation_count, **opt)
        super(**opt)
        
        @info[:refreshable] = true
        @info[:default_animation_count] = animation_count
      end
      
      def set_image(image, **opt)
        @symbol_image_ary = [] #@symbol, @imageに使用する画像の配列
        
        image.each do |img| #渡された画像を順に
          super(img, **opt) #autotileとして処理
          
          @symbol_image_ary << [@symbol, @image] #配列にそのまま追加
        end
        
        @symbol_image_cycle = @symbol_image_ary.cycle
        @symbol, @image = @symbol_image_cycle.next
        
        @animation_count = @info[:default_animation_count]
        @refreshed = false
        
        self
      end
      
      def refresh
        @refreshed = false
        @animation_count -= 1
        return if @animation_count > 0
        
        @animation_count = @info[:default_animation_count]
        
        @symbol, @image = @symbol_image_cycle.next
        @refreshed = true
        
        nil
      end
      
      def refreshed?
        @refreshed
      end
      
      def sleep
        Image.dispose(*@symbol_image_ary)
        @symbol = @image = @symbol_image_cycle = @symbol_image_ary = nil
        
        nil
      end
    end
    
    ################################################################################
    #         以下、サブクラス
    ################################################################################
    
    class Parts1 < Base
      #パーツ1(TileSetA1)に有るタイル(深海を除く)のクラス
      #境界を作らないのでその判定用に括る
      
      def ===(tile)
        Parts1 === tile
      end
    end
    
    class Water < Parts1
      #海タイル(TileSetA1-A), 水タイル(TileSetA1-D)
      
      include AutotileTile
      include AnimationTile
      
      def initialize(**opt)
        super(23, **opt)
      end
      
      private
      
      def set_walkable(**opt)
        @info[:pass] = [:boat, :ship, :float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class DeepSea < Base
      #深海タイル(TileSetA1-B)
      #sea:に海タイルが渡されることを想定
      
      include AutotileTile
      include AnimationTile
      
      def initialize(**opt)
        super(23, **opt)
      end
      
      private
      
      def set_layer(sea: nil, **opt)
        @layer = [sea, self, nil, nil]
        
        self
      end
      
      def set_walkable(**opt)
        @info[:pass] = [:ship, :float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class Rock < Base
      #岩礁タイル(TileSetA1-C)
      #sea:に海タイルが渡されることを想定
      
      include AutotileTile
      
      private
      def set_layer(sea: nil, **opt)
        @layer = [sea, self, nil, nil]
      end
      
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class WaterFall < Parts1
      include WaterFallTile
      include AnimationTile
      
      def initialize(**opt)
        super(20, **opt)
      end
      
      private
      def set_image(image, **opt)
        super(image.sliceTiles(1,3), **opt)
      end
      
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(down: true)
        
        self
      end
    end
    
    class Ground < Base
      #地面タイル(TileSetA2-A(Left))
      include AutotileTile
    end
    
    class OnGround < Base
      #ground:に地面タイルが渡されることを想定
      
      include AutotileTile
      
      private
      def set_layer(ground: nil, **opt)
        @layer = [ground, self, nil, nil]
      end
    end
    
    class Decoration < Base
      #装飾タイル(TileSetA2-B)
      
      include AutotileTile
      
      private
      def set_layer(**opt)
        @layer = [nil, self, nil, nil]
      end
    end
    
    class Bush < OnGround
      #VXの茂みタイル(TileSetA2-A(center))
      #ground:に地面タイルが渡されることを想定
      
      private
      def set_walkable(**opt)
        @info[:pass] = [:walk, :float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
      end
      
      def set_attribute(**opt)
        @info[:attribute] = [:bush]
      end
    end
    
    class Block < OnGround
      #VXの障害タイル(TileSetA2-A(right))
      #ground:に地面タイルが渡されることを想定
      
      private
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
      end
    end
    
    class Buildings < Base
      #下層に配置するが地面では無いタイルを括る
      
      def ===(tile)
        #Buildingsの子孫で無いか同じクラスならtrue
        !(Buildings === tile) || (tile.class == self.class)
      end
    end
    
    class Pavement < Base
      include AutotileTile
      #境界を基本作らないタイル(TileSetA2-A(right;エリアタイプ), VX:TileSetA2-B)
      
      def ===(tile)
        !(Buildings === tile) || (tile.class == self.class)
      end
    end
    
    class Counter < Pavement
      #VXのカウンタータイル(VX:TileSetA2-C)
      
      private
      def set_attribute(**opt)
        @info[:attribute] = [:counter]
      end
      
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
      end
    end
    
    class Outside < Buildings
      #建物の外観タイル(TileSetA3)
      
      include SetPatternTile
      
      private
      def set_layer(**opt)
        @layer = [self, :none, nil, nil]
        
        self
      end
      
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class WallTop < Buildings
      #壁上部タイル(TileSetA4-Upper)
      
      include AutotileTile
      
      private
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class Wall < Buildings
      #壁タイル(TileSetA4-Below)
      
      include SetPatternTile
      
      private
      def set_walkable(**opt)
        @info[:pass] = [:float, :plane]
        @info[:land] = []
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class Floor < Base
      #床タイル(TileSetA5)
      
      include OneImageTile
      
      private
      def set_walkable(**opt)
        @info[:pass] = [:walk, :float, :plane]
        @info[:land] = [:float, :plane]
        @info[:move] = Direction.new(true)
        
        self
      end
    end
    
    class Upper < Base
      #上層タイル(TileSetB~E)
      #walk:にtrue/Directionオブジェクトを渡すと歩けるようになる
      #through:に真を渡すとすり抜けるようになる
      #  (それと同時に歩けるようになる)
      
      include OneImageTile
      
      private
      def set_layer(through: nil, **opt)
        @info[:through] = through unless @info.key?(:through)
        @layer = (@info[:through] ? [nil, nil, nil, self] : [nil, nil, self, :none])
        
        self
      end
      
      def set_walkable(walk: nil, **opt)
        walk = Direction.new(true) if walk == true #trueならDirection.new(true)
        walk = nil unless Direction === walk #Direction以外のobjectをnilに統一
        walk ||= Direction.new(true) if @info[:through] #すり抜けなら歩行可
        
        pass = [:float, :plane]
        pass << :walk if walk
        @info[:pass] = pass
        
        land = []
        land << :float << :plane if walk
        @info[:land] = land
        
        @info[:move] = (walk ? walk : Direction.new(true))
        
        self
      end
      
      public
      
      def through
        @info[:through]
      end
      def through=(v)
        @info[:through] = (v ? true : false)
        set_layer
        
        @info[:through]
      end
    end
  end
end
