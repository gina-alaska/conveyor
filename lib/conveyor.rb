require 'rubygems'
require 'active_support/core_ext'
require 'singleton'
require 'listen'
require 'yaml'
require 'rainbow'
require 'readline'
require 'fileutils'

module Conveyor
  autoload :Output,   'conveyor/output'
  autoload :Foreman,  'conveyor/foreman'
  autoload :Belt,     'conveyor/belt'
  autoload :Worker,   'conveyor/worker'
  autoload :Status,   'conveyor/status'
  autoload :Input, 		'conveyor/input'
  
  def self.start
    Foreman.instance.start_monitor
  end
end

def watch(*args, &block)
  Conveyor::Foreman.instance.watch(*args, &block)
end
