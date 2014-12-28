# coding: UTF-8

$dxruby_no_include = true
require 'dxruby'

module RPG
  include DXRuby
end

require_relative './common/directory'
require_relative './common/exception'
require_relative './common/image_marshal'
require_relative './map/map'

include RPG unless $dxruby_rpg_no_include
