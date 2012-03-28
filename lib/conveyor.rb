require 'rubygems'
require 'active_support/core_ext'
require 'singleton'
require 'fssm'
require 'yaml'
require 'rainbow'

module Conveyor
  autoload :Output,   'conveyor/output'
  autoload :Foreman,  'conveyor/foreman'
  autoload :Watch,    'conveyor/watch'
  autoload :Worker,   'conveyor/worker'
  
  def self.start
    Foreman.instance.monitor
  end
end

def watch(name, &block)
  Conveyor::Foreman.instance.watch(name, &block)
end
