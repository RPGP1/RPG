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
      
      hash = {new: '新規作成', save: '保存', pass: '通行設定', land: '着陸設定', walk: '歩行設定', through: 'すり抜け設定', exit: '終了'}
      
      hash.each do |key, caption|
        str = key.to_s
        add_control(WS::WSImageButton.new(nil,nil,Image.load('./icon/' + str + '.png')), ('icon_' + str).to_sym).tap{|ctl|
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
      self.add_handler(:exit){TileSetEditor.exit_editor}
      self.add_handler(:pass){TileSetEditor.change_mode(:pass)}
      self.add_handler(:land){TileSetEditor.change_mode(:land)}
      self.add_handler(:walk){TileSetEditor.change_mode(:walk)}
      self.add_handler(:through){TileSetEditor.change_mode(:through)}
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
        
        @@alpha_hash = {true => 255, false => 160}
        
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
          @img = Image.new(@width, @height).draw(2, 2, @symbol_img).box(0, 0, @width - 1, @height - 1, C_WHITE)
        end
        
        def info_render(&b)
          return @info_render unless b
          @info_render = b
        end
        
        def render
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
        self.image.bgcolor = [0,0,0]
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
      
      def bgcolor
        self.image.bgcolor
      end
      
      def bgcolor=(v)
        self.image.bgcolor = v
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
    def initialize(viewer, tw, th, bgcolor, scale = 1)
      super(nil, nil, nil, th * scale + 4)
      self.image = RenderTarget.new(tw * scale + 4, th * scale + 4)
      self.image.bgcolor = bgcolor
      
      @viewer = viewer
      @scale = scale
    end
    
    def render
      self.image.draw_box(0,0,self.image.width - 1, self.image.height - 1, C_WHITE)
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
      end
      
      yield if block_given?
      
      main_area = @main_area
      if main_area
        add_control(@main_area, :main_area)
        main_area.focusable = true
      end
      
      layout(:hbox) do
        self.set_margin 3, 3, 3, 3
        self.space = 3
        
        add tilesetview
        main_area ? (add main_area) : layout
      end
      
      main_area.activate if main_area
    end
  end
  
  class EditPass < EditModeBase
    def initialize
      super('通行設定')
    end
    
    def set_tileset(tileset)
      #タイルセットが選択されていないなら何もしない
      return unless tileset
      
      old_tileset = @tileset
      super do
        next if old_tileset
        
        timg = tileset.symbol_ary
        tw = timg[0].width
        th = timg[0].height
        
        def tile
          tilesetview.tile
        end
        def symbol_img
          tilesetview.symbol_img
        end
        
        image1 = EditTilePreview.new(self, tw, th, tilesetview.client.bgcolor)
        image2 = EditTilePreview.new(self, tw, th, tilesetview.client.bgcolor, 3)
        
        space_ctl = WS::WSControl.new(nil,nil,nil, 5)
        
        label1 = EditBoolLabel.new(self, :pass, '通行', :walk, '歩行')
        label2 = EditBoolLabel.new(self, :pass, '通行', :boat, '小舟')
        label3 = EditBoolLabel.new(self, :pass, '通行', :ship, '船舶')
        label4 = EditBoolLabel.new(self, :pass, '通行', :float, '浮遊')
        label5 = EditBoolLabel.new(self, :pass, '通行', :plane, '飛行機')
        
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
        
        def change_pass(name)
          return unless tile
          ary = tile.info[:pass]
          ary << name unless ary.delete(name)
        end
        
        add_key_handler(K_Q){change_pass(:walk)}
        add_key_handler(K_W){change_pass(:boat)}
        add_key_handler(K_E){change_pass(:ship)}
        add_key_handler(K_R){change_pass(:float)}
        add_key_handler(K_T){change_pass(:plane)}
      end
    end
  end
  
  class EditLand < EditModeBase
    def initialize
      super('着陸設定')
    end
    
    def set_tileset(tileset)
      #タイルセットが選択されていないなら何もしない
      return unless tileset
      
      old_tileset = @tileset
      super do
        next if old_tileset
        
        timg = tileset.symbol_ary
        tw = timg[0].width
        th = timg[0].height
        
        def tile
          tilesetview.tile
        end
        def symbol_img
          tilesetview.symbol_img
        end
        
        image1 = EditTilePreview.new(self, tw, th, tilesetview.client.bgcolor)
        image2 = EditTilePreview.new(self, tw, th, tilesetview.client.bgcolor, 3)
        
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
        
        def change_land(name)
          return unless tile
          ary = tile.info[:land]
          ary << name unless ary.delete(name)
        end
        
        add_key_handler(K_R){change_land(:float)}
        add_key_handler(K_T){change_land(:plane)}
      end
    end
  end
  
  class EditWalk < WS::WSLightContainer
  end
  
  class EditThrough < WS::WSLightContainer
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
  end
  
  def self.change_tileset(i)
    @@tslist.cursor = i
    tileset_list_to_s #@@tileset_listを更新
    if @@editing_tileset != (@@editing_tileset = TileSet.__send__(@@tileset_list[i]))
      @@editing_controls[@@editing_mode].set_tileset(@@editing_tileset) if @@editing_controls[@@editing_mode]
    end
  end
  
  @@editing_mode = nil
  @@editing_controls = {pass: EditPass.new, land: EditLand.new}
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
