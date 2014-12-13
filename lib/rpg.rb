# coding: UTF-8

$dxruby_no_include = true
require 'dxruby'

module RPG
  include DXRuby
end

Dir.chdir(File.dirname(__FILE__)) do
  Dir.mkdir('../data') unless Dir.exist?('../data')
  Dir.mkdir('../data/tileset') unless Dir.exist?('../data/tileset')
  Dir.mkdir('../data/map') unless Dir.exist?('../data/map')
end

require_relative './common/exception'
require_relative './common/image_marshal'
require_relative './map/map'

include RPG unless $dxruby_rpg_no_include
