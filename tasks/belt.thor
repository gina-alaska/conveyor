path = File.expand_path('../lib', File.dirname(__FILE__)) 
$: << path unless $:.include? path
require 'conveyor_framework'

module Conveyor; class BeltCmd < Thor
  namespace :belt
  include Thor::Actions
  include ::Conveyor::Framework

  desc "list [GLOB]", "List belts"
  def list(file = '*.yml')
    say "Belt Names"
    say "--------------------"
    Belt.all.each do |belt|
      say "  #{belt.name}", :yellow
    end
  end

  desc "add NAME FROM TO", "adds a new conveyor belt"
  def add(name, from, to)
    conf = Belt.to_conf(name)
    if File.exists? conf
      say "The belt #{conf} already exists!", :red
      exit
    end
  
    b = Belt.new(name: name, from: from, to: to)
    b.save

    say "Added belt #{b.name}", :green
  end

  desc "update NAME", "Update conveyor belt"
  method_option :from
  method_option :to
  def update(name)
    b = Belt.where(name)
    b.update_attributes(options)
    b.save

    say "Updated belt #{b.name}", :green
  end

  desc "delete NAME", "Remove the conveyro belt"
  def delete(name)
    conf = Belt.to_conf(name)
    if File.exists? conf
      FileUtils.rm(conf) 
    else
      say "Could not find belt #{name}", :red
    end
  end
end; end