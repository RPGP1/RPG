# coding: UTF-8

require_relative '../lib/rpg'
require_relative '../dxrubyws/lib/dxrubyws'
require_relative '../dxrubyws/lib/standardgui'

WS.set_theme('guibasic')


begin #前準備
  
  #使用できる最大のウィンドウサイズに
  Window.resize(*Window.getScreenModes[-7][0..1])
  #全画面化
#  Window.windowed = false
  
  #以前に保存したタイルセットを全て読み込む
  TileSet::Base.load_data
  
end

module WS
  class WSControl
    @@default_font = Font.new(12)
  end
end

#コントロール定義
module TileSetEditor
  
  #ツールバー
  class ToolBar < WS::WSContainer
    include WS::WindowFocus
    
    def initialize
      super(0,0,nil,32)
      self.image.bgcolor = WS::COLOR[:base]
      
      hash = {new: '新規作成', save: '保存', black_white: 'タイル背景色反転', pass: '通行設定', land: '着陸設定', walk: '歩行設定', through: 'すり抜け設定', ladder: '梯子属性設定', bush: '茂み属性設定', counter: 'カウンター属性設定', damage: 'ダメージ床属性設定', tag: '地形タグ設定', exit: '終了'}
      
      hash.each do |key, caption|
        str = key.to_s
        add_control(WS::WSImageButton.new(nil,nil,Image.load('./image/tileseteditor/' + str + '.png')), ('icon_' + str).to_sym).tap{|ctl|
          ctl.hover_text = caption
          ctl.add_handler(:click){self.signal(key)}
          hash[key] = ctl
        }
      end
      
      layout(:hbox) do
        self.space = 4
        self.margin_left= 4
        hash.keys[0..-2].each{|k| add hash[k]}
        layout
        add hash[hash.keys[-1]]
      end
      
      self.add_handler(:new){TileSetEditor.new_tileset}
      self.add_handler(:save){TileSetEditor.save_tileset}
      self.add_handler(:black_white){
        ary = EditModeBase.tile_bgcolor.dup
        ary2 = ary.pop(3).map!{|i| 255 - i}
        EditModeBase.tile_bgcolor = ary + ary2
      }
      self.add_handler(:exit){TileSetEditor.exit_editor}
      add_mode(:pass)
      add_mode(:land)
      add_mode(:walk)
      add_mode(:through)
      add_mode(:ladder)
      add_mode(:bush)
      add_mode(:counter)
      add_mode(:damage)
      add_mode(:tag)
    end
    
    private
    def add_mode(mode)
      self.add_handler(mode){TileSetEditor.change_mode(mode)}
    end
  end
  
  #ツールバーの下のスプリットコンテナ
  class MainArea < WS::WSSplitContainer
    include WS::WindowFocus
    
    def initialize(list, work_area)
      super(nil,nil,nil,nil,:h)
      
      self.space = 4
      add_client(list)
      add_client(work_area)
      
      self.init_layout
    end
  end
  
  #タイルセットオブジェクトのリスト
  class TileSetList < WS::WSListBox
    attr_accessor :cursor
    
    def initialize
      super(0,0,nil,nil)
      @width = 200
      
      @items = TileSetEditor.tileset_list_to_s
      self.add_handler(:select){|_, i|
        TileSetEditor.change_tileset(i)
      }
      @cursor = nil
    end
    
    def update
      set_items(@tilesets_objects) unless @tilesets_objects == (@tilesets_objects = TileSetEditor.tileset_list_to_s)
      super
    end
  end
  
  #エディタの本体
  class WorkArea < WS::WSContainer
    include WS::WindowFocus
    
    def initialize
      super
      self.image.bgcolor = WS::COLOR[:base]
    end
    
    def render
      self.alpha = @active ? 255 : 192
      super
    end
  end
  
  class NewPopup < WS::WSDialogBase
    def initialize
      @font = @@default_font
      
      caption_width = WS::WSWindow::WSWindowTitle.title_font.get_width('新規作成') + default_border_width * 2 + window_title_height + 1
      caption_height = window_title_height
      
      label1 = WS::WSLabel.new(nil,nil,@font.get_width('Class: '),@font.size,'Class: ')
      classes = TileSet.tileset_classes.map(&:name)
      pulldownlist = WS::WSPullDownList.new(nil,nil,classes.map{|str| @font.get_width(str)}.max+17,@font.size+6)
      pulldownlist.list.content = classes
      class_select_width = label1.width + pulldownlist.width + default_border_width * 2 + 20
      class_select_height = @font.size+6
      
      label2 = WS::WSLabel.new(nil,nil,@font.get_width('Image: '),@font.size,'Image: ')
      img_path_textbox = WS::WSTextBox.new(nil,nil,nil,@font.size+6)
      button = WS::WSButton.new(nil,nil,@font.get_width('…')+6,@font.size+6,'…')
      image_select_width = label2.width + 200 + button.width + default_border_width * 2 + 20
      image_select_height = @font.size+6
      
      label3 = WS::WSLabel.new(nil,nil,@font.get_width('Name: '),@font.size,'Name: ')
      name_textbox = WS::WSTextBox.new(nil,nil,nil,@font.size+6)
      name_set_width = label3.width + 100 + default_border_width * 2 + 20
      name_set_height = @font.size+6
      
      submit = WS::WSButton.new(nil,nil,@font.get_width('決定') + 6,@font.size+6,'決定')
      cancel = WS::WSButton.new(nil,nil,@font.get_width('キャンセル') + 6,@font.size+6,'キャンセル')
      submit_cancel_width = submit.width + cancel.width + default_border_width * 2 + 20
      submit_cancel_height = @font.size+6
      
      sx = [caption_width, class_select_width, image_select_width, name_set_width, submit_cancel_width].max
      sy = caption_height + class_select_height + image_select_height + name_set_height + submit_cancel_height + 50 + default_border_width
      tx = (WS.desktop.width - sx) / 2
      ty = (WS.desktop.height - sy) / 2
      
      super(tx,ty,sx,sy,'新規作成',close_button:true)
      
      add_control(label1, :label1)
      add_control(pulldownlist, :pulldownlist)
      add_control(label2, :label2)
      add_control(img_path_textbox, :img_path_textbox)
      add_control(button, :button)
      add_control(label3, :label3)
      add_control(name_textbox, :name_textbox)
      add_control(submit, :submit)
      add_control(cancel, :cancel)
      
      client.layout(:vbox) do
        self.margin_left = self.margin_right = self.margin_top = self.margin_bottom = self.space = 10
        layout(:hbox) do
          layout
          add label1
          add pulldownlist
        end
        layout(:hbox) do
          add label2
          add img_path_textbox
          add button
        end
        layout(:hbox) do
          add label3
          add name_textbox
        end
        layout(:hbox) do
          layout
          add submit
          add cancel
        end
      end
      
      button.add_handler(:click) do
        WS.desktop.add_control(tmp = WS::WSFile.open(WS.desktop.width / 4, WS.desktop.height / 4, WS.desktop.width / 2, WS.desktop.height / 2, [['PNG image', /\.png$/i], ['JPEG image', /\.jpe?g?$/i], ['BMP image', /\.(?:bmp)|(?:dib)$/i], ['GIF image', /\.gif$/i], ['DDS image', /\.dds$/i], ['TGA image', /\.tga$/i], ], "Title", directory: '../data/image/tileset'))
        tmp.add_handler(:submit) do |_, path|
          if path
            img_path_textbox.text = path
            if name_textbox.text == ""
              name_textbox.text = File.basename(path, ".*")
            end
          end
        end
      end
      
      submit.add_handler(:click) do
        ts_class = TileSet.tileset_classes[pulldownlist.index]
        image_path = img_path_textbox.text
        name = name_textbox.text
        
        warning = []
        unless File.exist?(image_path)
          warning << 'Imageが存在しません。' 
        else
          begin
            image = Image.load(image_path)
          rescue DXRubyError
            warning << 'Imageが画像ではありません'
          end
        end
        if name == ''
          warning << 'Nameが未設定です。'
        elsif TileSet.respond_to?(name, true)
          warning << 'そのNameは使用できません。'
        end
        
        if warning.empty?
          #問題なし
          self.close
          ts = ts_class.new(Image.load(image_path), name.to_sym)
          TileSetEditor.change_tileset(TileSet.tileset_objects.index(ts.name))
        else
          #問題あり
          WS.desktop.add_control(WS::WSMessageBox.new(warning * ''))
        end
      end
      
      cancel.add_handler(:click) do
        close
      end
      
      pulldownlist.activate
      
      @old_capture_object = WS.desktop.capture_target || WS.desktop.capture_object
      @old_capture_notify = WS.desktop.capture_notify
      @old_capture_lock = WS.desktop.capture_target ? true : false
      WS.capture(self, true, true)
    end
    
    def close
      WS.release_capture
      WS.capture(@old_capture_object, @old_capture_notify, @old_capture_lock) if @old_capture_object
      super
      TileSetEditor.refresh_mode
    end
  end
  
  class SavePopup < WS::WSDialogBase
    def initialize(tileset)
      @font = @@default_font
      label = WS::WSLabel.new(nil,nil,@font.get_width('しばらくお待ちください'),@font.size,'しばらくお待ちください')
      
      sx = label.width + default_border_width * 2 + 20
      sy = window_title_height + @font.size + default_border_width + 20
      tx = (WS.desktop.width - sx) / 2
      ty = (WS.desktop.height - sy) / 2
      
      super(tx, ty, sx, sy, '保存')
      
      add_control(label)
      client.layout(:hbox) do
        add label
      end
      
      @tileset = tileset
      
      @old_capture_object = WS.desktop.capture_target || WS.desktop.capture_object
      @old_capture_notify = WS.desktop.capture_notify
      @old_capture_lock = WS.desktop.capture_target ? true : false
      WS.capture(self, true, true)
    end
    
    def close
      WS.release_capture
      WS.capture(@old_capture_object, @old_capture_notify, @old_capture_lock) if @old_capture_object
      super
      TileSetEditor.refresh_mode
    end
    
    def render
      @thread ||= Thread.new do
        @tileset.save rescue p $!
        close
      end
      
      super
    end
  end
  
  class ExitPopup < WS::WSConfirmBox
    def initialize
      super("Are you sure to exit?", "保存していない変更は失われます")
      self.add_handler(:yes){exit}
      self.add_handler(:no){TileSetEditor.exit_editor(false)}
    end
  end
  
  
  #####################################################
  #   実際の編集機能の定義
  #####################################################
  
  class TileSetView < WS::WSScrollableContainer
    class TileSetViewClient < WS::WSContainer
      class TileView < WS::WSControl
        attr_reader :tile, :mouse_over, :symbol_img
        
        @@alpha_hash = {true => 255, false => 186}
        
        def self.alpha_hash
          @@alpha_hash
        end
        
        def initialize(tileset, index)
          @tileset = tileset
          @index = index
          @tile = tileset[index, type: :symbol][0]
          @symbol_img = tileset.symbol_ary[index]
          @alpha_hash = @@alpha_hash
          
          w = @symbol_img.width + 4
          h = @symbol_img.height + 4
          super(index % 8 * w, index / 8 * h, w, h)
          
          self.image = RenderTarget.new(w, h)
          set_image
          @info_render = nil
          
          add_handler(:mouse_wheel_up){self.parent.signal(:mouse_wheel_up)}
          add_handler(:mouse_wheel_down){self.parent.signal(:mouse_wheel_down)}
        end
        
        def set_image
          @img.dispose if @img
          @img = Image.new(@width, @height).draw(2, 2, @symbol_img).box(0, 0, @width - 1, @height - 1, EditModeBase.tile_border_color)
        end
        
        def info_render(&b)
          return @info_render unless b
          @info_render = b
        end
        
        def render
          self.image.bgcolor = EditModeBase.tile_bgcolor
          
          old_img = @symbol_img
          @symbol_img = @tileset.symbol_ary[@index]
          if old_img != @symbol_img
            set_image
          end
          
          self.alpha = @alpha_hash[@mouse_over]
          
          super
        end
        
        def draw
          self.image.draw(0, 0, @img)
          self.instance_eval &@info_render if @info_render
          
          super
        end
      end
      
      attr_accessor :pos
      attr_reader :shift_qty, :total_size
      
      def self.alpha_hash
        TileView.alpha_hash
      end
      
      def initialize(tileset)
        super()
        @render_range = Sprite.new
        
        @tileset = tileset
        tileset.size(:symbol).times do |i|
          add_control(TileView.new(tileset, i))
        end
        
        self.width = @children[0].width * 8
        @old_pos = @pos = 0
        @shift_qty = @children[0].height
        @total_size = @children[-1].y + @children[-1].height
        
        @info_render = nil
        
        add_handler(:mouse_wheel_up){self.parent.signal(:mouse_wheel_up)}
        add_handler(:mouse_wheel_down){self.parent.signal(:mouse_wheel_down)}
      end
      
      def resize(width, height)
        super
        @render_range.collision = [0, 0, width - 1, height - 1]
      end
      
      def info_render(&b)
        return @info_render unless b
        @children.each do |ctl|
          ctl.info_render(&b)
        end
        @info_render = b
      end
      
      def tile
        return nil unless ctl = @children.find(&:mouse_over)
        ctl.tile
      end
      
      def symbol_img
        return nil unless ctl = @children.find(&:mouse_over)
        ctl.symbol_img
      end
      
      def update
        if @old_pos != @pos
          diff = @old_pos - @pos
          @children.each do |ctl|
            ctl.y += diff
          end
          @old_pos = @pos
        end
      end
      
      def render
        self.image.bgcolor = EditModeBase.tile_bgcolor
        
        ary = @children#.select(&:visible)
        Sprite.check(@render_range, ary, nil, :render)
        Sprite.check(@render_range, ary, nil, :draw)
      end
    end
    
    @@clients = {}
    @@clients.default_proc = Proc.new do |_, name|
      TileSetViewClient.new(TileSet.__send__(name))
    end
    
    def initialize(tileset)
      client = @@clients[tileset.name]
      super(nil, nil, client.width + 20, nil, client)
      
      vsb.pos = client.pos
      vsb.shift_qty = client.shift_qty
      vsb.total_size = client.total_size
      
      add_handler(:mouse_wheel_up){self.parent.signal(:mouse_wheel_up)}
      add_handler(:mouse_wheel_down){self.parent.signal(:mouse_wheel_down)}
    end
    
    def info_render(&b)
      client.info_render(&b)
    end
    
    def render
      client.pos = vsb.pos
      super
    end
    
    def tile
      client.tile
    end
    
    def symbol_img
      client.symbol_img
    end
  end
  
  class EditBoolLabel < WS::WSLabel
    def initialize(viewer, type, type_caption, name, name_caption)
      @font = @@default_font
      super(nil,nil,nil, @font.size + 2, name_caption + '：')
      
      @viewer = viewer
      @type = type
      @type_caption = type_caption
      @name = name
      @name_caption = name_caption
    end
    
    def update
      tile = @viewer.tile
      if tile
        self.caption = @name_caption + '：' + @type_caption + (tile.info[@type].include?(@name) ? '可' : '不可')
      else
        self.caption = @name_caption + '：'
      end
      
      super
    end
  end
  
  class EditTilePreview < WS::WSImage
    def initialize(viewer, tw, th, scale = 1)
      super(nil, nil, nil, th * scale + 4)
      self.image = RenderTarget.new(tw * scale + 4, th * scale + 4)
      
      @viewer = viewer
      @scale = scale
    end
    
    def render
      self.image.bgcolor = EditModeBase.tile_bgcolor
      
      self.image.draw_box(0,0,self.image.width - 1, self.image.height - 1, EditModeBase.tile_border_color)
      if img = @viewer.symbol_img
        if @scale == 1
          self.image.draw(2, 2, img)
        else
          self.image.drawScale(2, 2, img, @scale, @scale, 0, 0)
        end
      end
      
      super
    end
  end
  
  class EditModeBase < WS::WSLightContainer
    attr_reader :name
    
    @@tile_bgcolor = [0,0,0]
    @@tile_border_color = [255,255,255]
    
    def self.tile_bgcolor
      @@tile_bgcolor
    end
    def self.tile_bgcolor=(v)
      @@tile_bgcolor = v.dup
      ary = v.dup
      ary2 = ary.pop(3).map{|i| 255 - i}
      @@tile_border_color = ary + ary2
      
      TileSetEditor.refresh_mode
    end
    def self.tile_border_color
      @@tile_border_color
    end
    
    def initialize(name)
      super()
      @name = name
      @focusable = true
      
      #ここに本体を入れる
      @main_area = nil
      
      #set_tilesetする前の表示
      str = "現在「#{@name}」モードです。タイルセットを選択するか、新規に作成して下さい。"
      ctl = add_control(WS::WSLabel.new(nil,nil,@font.get_width(str),@font.size + 2,str))
      layout(:hbox){add ctl}
    end
    
    def set_tileset(tileset)
      #タイルセットが選択されていないなら何もしない
      return unless tileset
      
      
      @children.each{|ctl| remove_control(ctl)}
      
      
      old_tileset = @tileset
      @tileset = tileset
      
      tilesetview = add_control(TileSetView.new(tileset), :tilesetview)
      unless old_tileset
        add_handler(:mouse_wheel_up){self.tilesetview.vsb.slide(-self.tilesetview.vsb.shift_qty * 3)}
        add_handler(:mouse_wheel_down){self.tilesetview.vsb.slide(self.tilesetview.vsb.shift_qty * 3)}
        init_editor
      end
      tilesetview.info_render(&(@info_render ||= Proc.new{}))
      
      main_area = @main_area
      if main_area
        add_control(@main_area, :main_area)
      end
      
      layout(:hbox) do
        self.set_margin 3, 3, 3, 3
        self.space = 3
        
        add tilesetview
        main_area ? (add main_area) : layout
      end
    end
    
    def init_editor
      def tile
        tilesetview.tile
      end
      def symbol_img
        tilesetview.symbol_img
      end
      
      def try_change(name)
        change(tile, name) if tile
      end
      
      def change(t, name)
      end
    end
  end
  
  class EditPass < EditModeBase
    def initialize
      super('通行設定')
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      tw = timg[0].width
      th = timg[0].height
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditBoolLabel.new(self, :pass, '通行', :boat, '小舟')
      label2 = EditBoolLabel.new(self, :pass, '通行', :ship, '船舶')
      label3 = EditBoolLabel.new(self, :pass, '通行', :float, '浮遊')
      label4 = EditBoolLabel.new(self, :pass, '通行', :plane, '飛行機')
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.add_control(label2)
      @main_area.add_control(label3)
      @main_area.add_control(label4)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        add label2
        add label3
        add label4
        layout
      end
      
      def change(t, name)
        ary = t.info[:pass]
        ary << name unless ary.delete(name)
      end
      
      add_key_handler(K_Q){try_change(:boat)}
      add_key_handler(K_W){try_change(:ship)}
      add_key_handler(K_E){try_change(:float)}
      add_key_handler(K_R){try_change(:plane)}
    end
  end
  
  class EditLand < EditModeBase
    def initialize
      super('着陸設定')
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      tw = timg[0].width
      th = timg[0].height
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditBoolLabel.new(self, :land, '着陸', :float, '浮遊')
      label2 = EditBoolLabel.new(self, :land, '着陸', :plane, '飛行機')
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.add_control(label2)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        add label2
        layout
      end
      
      def change(t, name)
        ary = t.info[:land]
        ary << name unless ary.delete(name)
      end
      
      add_key_handler(K_E){try_change(:float)}
      add_key_handler(K_R){try_change(:plane)}
    end
  end
  
  class EditWalk < EditModeBase
    class EditDirectionLabel < WS::WSLabel
      def initialize(viewer, type, type_caption, name, name_caption)
        @font = @@default_font
        super(nil,nil,nil, @font.size + 2, name_caption + '：')
        
        @viewer = viewer
        @type = type
        @type_caption = type_caption
        @name = name
        @name_caption = name_caption
      end
      
      def update
        tile = @viewer.tile
        if tile
          self.caption = @name_caption + '：' + @type_caption + (tile.info[@type].__send__(@name) ? '可' : '不可')
        else
          self.caption = @name_caption + '：'
        end
        
        super
      end
    end
    
    def initialize
      super('歩行設定')
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      tw = timg[0].width
      th = timg[0].height
      
      proc = Proc.new do |tw, th, bold, inside, edge|
        Image.new(tw, th).triangleFill(tw / 2 - 1, 0, 0, tw / 2 - 1, tw / 2 - 1, tw / 2 - 1, inside)
        .triangleFill(tw / 2, 0, tw / 2, tw / 2 - 1, tw - 1, tw / 2 - 1, inside)
        .boxFill((tw - bold) / 2, tw / 2 - 1, (tw + bold - 2) / 2, th - 1, inside)
        .line(tw / 2 - 1, 0, 0, tw / 2 - 1, edge)
        .line(0, tw / 2 - 1, (tw - bold) / 2, tw / 2 - 1, edge)
        .line((tw - bold) / 2, tw / 2 - 1, (tw - bold) / 2, th - 1, edge)
        .line(tw / 2, 0, tw - 1, tw / 2 - 1, edge)
        .line(tw - 1, tw / 2 - 1, (tw + bold - 2) / 2, tw / 2 - 1, edge)
        .line((tw + bold - 2) / 2, tw / 2 - 1, (tw + bold - 2) / 2, th - 1, edge)
        .line((tw - bold) / 2, th - 1, (tw + bold - 2) / 2, th - 1, edge)
      end
      
      arrow_img = {true => proc.call((th - 2) / 3, th / 2 - 4, 4, C_WHITE, [0,0,0]), false => proc.call((th - 2) / 3, th / 2 - 4, 4, [0,0,0], C_WHITE)}
      pos_ary = [[(tw * 3 - th + 14) / 6, 3], [tw + 1, (tw * 3 - th + 14) / 6], [(tw * 3 + th + 10) / 6, th + 1], [3, (tw * 3 + th + 10) / 6]]
      @info_render = Proc.new do
        img = arrow_img[self.tile.info[:pass].include?(:walk)]
        pos_ary.each.with_index do |ary, i|
          next unless self.tile.info[:move].able?(i)
          self.image.drawRot(*ary, img, 90 * i, 0, 0)
        end
      end
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditBoolLabel.new(self, :pass, '通行', :walk, '歩行')
      label2 = EditDirectionLabel.new(self, :move, '歩行', :up?, '↑')
      label3 = EditDirectionLabel.new(self, :move, '歩行', :down?, '↓')
      label4 = EditDirectionLabel.new(self, :move, '歩行', :left?, '←')
      label5 = EditDirectionLabel.new(self, :move, '歩行', :right?, '→')
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.add_control(label2)
      @main_area.add_control(label3)
      @main_area.add_control(label4)
      @main_area.add_control(label5)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        add label2
        add label3
        add label4
        add label5
        layout
      end
      
      def change(t, name)
        if name == :able
          ary = t.info[:pass]
          ary << :walk unless ary.delete(:walk)
        else
          direction = t.info[:move]
          direction.__send__(name.to_s + '=', !direction.__send__(name.to_s + '?'))
        end
      end
      
      add_key_handler(K_1){try_change(:able)}
      add_key_handler(K_W){try_change(:up)}
      add_key_handler(K_S){try_change(:down)}
      add_key_handler(K_A){try_change(:left)}
      add_key_handler(K_D){try_change(:right)}
    end
  end
  
  class EditThrough < EditModeBase
    class EditThroughLabel < WS::WSLabel
      def initialize(viewer)
        @font = @@default_font
        super(nil,nil,nil, @font.size + 2, 'すり抜け：')
        
        @viewer = viewer
      end
      
      def update
        tile = @viewer.tile
        if tile
          if tile.respond_to?(:through=)
            self.caption = 'すり抜け：' + (tile.through ? 'する' : 'しない')
          else
            self.caption = 'すり抜け：設定不可'
          end
        else
          self.caption = 'すり抜け：'
        end
        
        super
      end
    end
    
    def initialize
      super('すり抜け設定')
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      tw = timg[0].width
      th = timg[0].height
      
      img_ary = [Image.load('./image/tileseteditor/[].png'), Image.load('./image/tileseteditor/o.png'), Image.load('./image/tileseteditor/x.png'),]
      @info_render = Proc.new do
        img = img_ary[
          self.tile.respond_to?(:through=) ? (self.tile.through ? 1 : 2) : 0
        ]
        self.image.draw((self.image.width - img.width) / 2, (self.image.height - img.height) / 2, img)
      end
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditThroughLabel.new(self)
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        layout
      end
      
      def change(t, name)
        return unless t.respond_to?(:through)
        t.through = !t.through
      end
      
      add_key_handler(K_1){try_change(:through)}
    end
  end
  
  class EditAttributeBase < EditModeBase
    class EditAttributeLabel < WS::WSLabel
      def initialize(viewer, type, caption)
        @font = @@default_font
        @default_caption = caption + '：'
        super(nil,nil,nil, @font.size + 2, @default_caption)
        
        @type = type
        @viewer = viewer
      end
      
      def update
        tile = @viewer.tile
        if tile
          self.caption = @default_caption + (tile.info[:attribute].include?(@type) ? 'On' : 'Off')
        else
          self.caption = @default_caption
        end
        
        super
      end
    end
    
    def initialize(type, name)
      super(name + '設定')
      @type = type
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      type = @type
      tw = timg[0].width
      th = timg[0].height
      
      img_ary = [Image.load('./image/tileseteditor/o.png'), Image.load('./image/tileseteditor/x.png'),]
      @info_render = Proc.new do
        img = img_ary[
          tile.info[:attribute].include?(type) ? 0 : 1
        ]
        self.image.draw((self.image.width - img.width) / 2, (self.image.height - img.height) / 2, img)
      end
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditAttributeLabel.new(self, @type, @name[0..-3])
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        layout
      end
      
      def change(t, name)
        ary = t.info[:attribute]
        ary << @type unless ary.delete(@type)
      end
      
      add_key_handler(K_1){try_change(@type)}
    end
  end
  
  class EditLadder < EditAttributeBase
    def initialize
      super(:ladder, '梯子属性')
    end
  end
  
  class EditBush < EditAttributeBase
    def initialize
      super(:bush, '茂み属性')
    end
  end
  
  class EditCounter < EditAttributeBase
    def initialize
      super(:counter, 'カウンター属性')
    end
  end
  
  class EditDamage < EditAttributeBase
    def initialize
      super(:damage, 'ダメージ床属性')
    end
  end
  
  class EditTag < EditModeBase
    class EditTagLabel < WS::WSLabel
      def initialize(viewer)
        @font = @@default_font
        super(nil,nil,nil, @font.size + 2, '地形タグ：')
        
        @viewer = viewer
      end
      
      def update
        tile = @viewer.tile
        if tile
          self.caption = '地形タグ：' + tile.info[:tag].to_s
        else
          self.caption = 'すり抜け：'
        end
        
        super
      end
    end
    
    def initialize
      super('地形タグ設定')
    end
    
    def init_editor
      super
      
      timg = @tileset.symbol_ary
      tw = timg[0].width
      th = timg[0].height
      
      img_ary = Array.new(10){|i| Image.load('./image/tileseteditor/' + i.to_s + '.png')}
      @info_render = Proc.new do
        tag = self.tile.info[:tag]
        img1 = img_ary[tag.div(10)]
        img2 = img_ary[tag % 10]
        self.image.draw(self.image.width / 2 - img1.width - 1, (self.image.height - img1.height) / 2, img1)
        self.image.draw(self.image.width / 2 + 1, (self.image.height - img2.height) / 2, img2)
      end
      
      image1 = EditTilePreview.new(self, tw, th)
      image2 = EditTilePreview.new(self, tw, th, 3)
      
      space_ctl = WS::WSControl.new(nil,nil,nil, 5)
      
      label1 = EditTagLabel.new(self)
      
      @main_area = WS::WSLightContainer.new
      @main_area.add_control(image1)
      @main_area.add_control(image2)
      @main_area.add_control(space_ctl)
      @main_area.add_control(label1)
      @main_area.layout(:vbox) do
        self.set_margin 2, 2, 2, 2
        self.space = 5
        
        add image1
        add image2
        add space_ctl
        add label1
        layout
      end
      
      def change(t, name)
        tag = t.info[:tag]
        
        case name
        when :plus_1
          tag += 1
        when :minus_1
          tag -= 1
        when :plus_10
          tag += 10
        when :minus_10
          tag -= 10
        end
        
        t.info[:tag] = tag % 100
      end
      
      add_key_handler(K_D){try_change(:plus_1)}
      add_key_handler(K_A){try_change(:minus_1)}
      add_key_handler(K_W){try_change(:plus_10)}
      add_key_handler(K_S){try_change(:minus_10)}
    end
  end
  
  #####################################################
  #   エディタの初期化
  #####################################################
  
  
  @@editing_tileset = nil
  
  @@tileset_list = TileSet.tileset_objects
  @@tileset_list_refresh = true
  def self.tileset_list_to_s
    @@tileset_list_to_s = @@tileset_list.map(&:to_s) if @@tileset_list != (@@tileset_list = TileSet.tileset_objects) || @@tileset_list_refresh
    @@tileset_list_refresh = false
    @@tileset_list_to_s
  end
  
  def self.refresh_list
    @@tileset_list_refresh = true
  end
  
  def self.new_tileset
    WS.desktop.add_control(NewPopup.new)
  end
  
  def self.save_tileset
    return unless @@editing_tileset
    
    WS.desktop.add_control(SavePopup.new(@@editing_tileset))
  end
  
  #ポップアップが複数出ないようにする
  @@exit_popup = nil
  def self.exit_editor(start = true)
    if start && !WS.desktop.capture_object
      @@exit_popup ||= WS.desktop.add_control(ExitPopup.new)
    else
      @@exit_popup = nil
    end
    
    self.refresh_mode unless start
  end
  
  def self.change_tileset(i)
    @@tslist.cursor = i
    tileset_list_to_s #@@tileset_listを更新
    if @@editing_tileset != (@@editing_tileset = TileSet.__send__(@@tileset_list[i]))
      @@editing_controls[@@editing_mode].set_tileset(@@editing_tileset) if @@editing_controls[@@editing_mode]
    end
    self.refresh_mode
  end
  
  @@editing_mode = nil
  @@editing_controls = {pass: EditPass.new, land: EditLand.new, walk: EditWalk.new, through: EditThrough.new, ladder: EditLadder.new, bush: EditBush.new, counter: EditCounter.new, damage: EditDamage.new, tag: EditTag.new}
  def self.change_mode(mode)
    @@work_area.remove_control(@@editing_controls[@@editing_mode]) if @@editing_controls[@@editing_mode]
    @@editing_mode = mode
    if ctl = @@editing_controls[@@editing_mode]
      @@work_area.add_control(ctl)
      @@work_area.layout(:hbox) do
        add ctl
      end
      @@main_area.activate
      @@work_area.activate
      ctl.activate
      ctl.set_tileset(@@editing_tileset)
    end
  end
  def self.refresh_mode
    self.change_mode(@@editing_mode)
  end
  
  #初期化処理
  WS.desktop.add_control(@@toolbar = ToolBar.new)
  WS.desktop.add_control(@@main_area = MainArea.new(@@tslist = TileSetList.new, @@work_area = WorkArea.new))
  
  WS.desktop.layout(:vbox) do
    self.space = 4
    add @@toolbar
    add @@main_area
  end
  
  change_mode(:pass)
end

####################################################
#ここから起動
####################################################

exit if defined?(Ocra)

if __FILE__ == $0
  
  Window.create
  loop do
    TileSetEditor.exit_editor if Input.update
    
    WS.update
    
    Window.sync
    Window.update
  end
  
end
