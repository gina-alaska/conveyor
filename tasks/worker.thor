path = File.expand_path('../lib', File.dirname(__FILE__)) 
$: << path unless $:.include? path
require 'conveyor_framework'

module Conveyor; class WorkerCmd < Thor
  namespace :worker
  include Thor::Actions
  include ::Conveyor::Framework
  
  desc "list", "Show list of workers"
  def list
    Worker.all.each do |belt|
      say "  #{belt.name}", :yellow
    end
  end
  
  desc "monitor", "Monitor directories"
  def monitor
    mon = FSSM::Monitor.new(:directories => true)
    Belt.all.each do |b|
      mon.path b.from do
        update do |path,file,type| 
          Worker::BarrowWebcam.new(path, file, b).run if type == :file
        end
        
        delete { |path,file,type| puts "deleted #{path} :: #{file} :: #{type}" }
        
        create do |path,file,type| 
          Worker::BarrowWebcam.new(path, file, b).run if type == :file
        end
      end
    end
    
    say "Starting FSSM Monitor", :green
    mon.run
  end
end; end