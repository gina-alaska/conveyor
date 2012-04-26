#!/usr/bin/env ruby
$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
#require 'bundler/setup'
require 'conveyor'
require 'rubygems'
require 'active_support/core_ext'
require 'singleton'
require 'listen'
require 'yaml'
require 'rainbow'
require 'rb-readline'
require 'fileutils'

module Conveyor
  autoload :Output,   'conveyor/output'
  autoload :Foreman,  'conveyor/foreman'
  autoload :Belt,     'conveyor/belt'
  autoload :Worker,   'conveyor/worker'
  autoload :Status,   'conveyor/status'
  autoload :Input, 		'conveyor/input'
  autoload :Queue,    'conveyor/queue'
  
  def self.start
    Foreman.instance.start_monitor
  end
end

def watch(*args, &block)
  Conveyor::Foreman.instance.watch(*args, &block)
end

Conveyor.start
