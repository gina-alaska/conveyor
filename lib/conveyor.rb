#!/usr/bin/env ruby
$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'
require 'conveyor'
require 'rubygems'
require 'active_support/core_ext'
require 'singleton'
require 'listen'
require 'yaml'
require 'rainbow'
require 'rb-readline'
require 'fileutils'
require 'eventmachine'
require 'em-websocket'
require "conveyor/version"

module Conveyor
  autoload :Output,     'conveyor/output'
  autoload :Foreman,    'conveyor/foreman'
  autoload :Belt,       'conveyor/belt'
  autoload :Worker,     'conveyor/worker'
  autoload :Status,     'conveyor/status'
  autoload :Input, 		  'conveyor/input'
  autoload :Queue,      'conveyor/queue'
  autoload :Websocket,  'conveyor/websocket'

  def self.stop
    Foreman.instance.stop!
    EventMachine.stop
    exit
  end

  def self.fm
    Foreman.instance
  end

  def self.start
    EventMachine.run do
      trap("TERM") { stop }
      trap("INT") { stop }

      EventMachine.threadpool_size = fm.config[:threadpool] || 20

      fm.info "Starting Conveyor v#{Conveyor::VERSION}"
      fm.start
      fm.info "Waiting for files", :color => :green
      fm.info "Press CTRL-C to stop"
      Conveyor::Websocket.start

      EventMachine::PeriodicTimer.new(1) do
        fm.output_status
      end

      EventMachine::PeriodicTimer.new(1) do
        fm.check
      end
    end
  end
end

def watch(*args, &block)
  fm.watch(*args, &block)
end
