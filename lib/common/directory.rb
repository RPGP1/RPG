# coding: UTF-8

unless __FILE__ == $0
  
  module RPG
    def self.dir(path)
      Dir.mkdir(path) unless Dir.exist?(path)
      Dir.chdir(path) do
        yield if block_given?
      end
    end
    
    dir File.dirname($0) do
      dir '..' do
        dir 'data' do
          dir 'image' do
            dir 'tileset'
          end
          dir 'map' do
            dir 'tileset'
            dir 'map'
          end
        end
      end
    end
  end
  
end
