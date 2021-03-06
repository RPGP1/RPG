# coding: ASCII

#ASCIIで実行してください

module DXRuby
  class Image
    def to_binary
      require 'zlib'
      
      image_data = []
      for y in 0...height
        image_data.push(0)
        for x in 0...width
          temp = self[x,y]
          temp.push(temp.shift) # ARGB→RGBA
          image_data.concat(temp)
        end
      end
      def chunk(type, data)
        [data.size, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
      end
      "\x89PNG\r\n\x1a\n" + 
      chunk("IHDR", [width, height, 8, 6, 0, 0, 0].pack("NNCCCCC")) + 
      chunk("IDAT", Zlib::Deflate.deflate(image_data.pack("C*"))) + 
      chunk("IEND", "")
    end
    
    alias :marshal_dump :to_binary
    
    def marshal_load(str)
      img = Image.loadFromFileInMemory(str)
      self.__send__(:initialize_copy, img)
      img.dispose
    end
  end
end
