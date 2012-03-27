require 'rubygems'
require 'bundler'
Bundler.setup(:default, :cli)

require 'thor'
require 'fssm'
require 'whenever'
require 'active_model'
require 'belt'
require 'worker'

module Conveyor
  module Framework
    def self.source_root
      File.expand_path("..", File.dirname(__FILE__))
    end
  
    CONF_D = File.join(source_root, 'conf.d')
    Belt.config_root = CONF_D
  end
end