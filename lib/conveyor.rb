require 'rubygems'
require 'active_support/core_ext'
require 'singleton'
require 'fssm'
require 'yaml'
require 'rainbow'
require 'watch'
require 'match'

# Handle the incoming watch requests and assign the workers
class Conveyor
  include Singleton
  
  def initialize
    @config = read_configs
    @worker_defs = ARGV.shift
    @worker_defs ||= @config["worker_defs"]
  end
  
  def read_configs
    if File.exists?('.conveyor')
      YAML.load(File.open('.conveyor'))
    elsif File.exists?('~/.conveyor')
      YAML.load(File.open('~/.conveyor'))
    else
      { "worker_defs" => File.expand_path('../workers/', File.dirname(__FILE__)) }
    end
  end
  
  def say(*msg)
    options = msg.extract_options!
    console(msg, options)
    # this should pass it on to the logger
  end
  
  def console(msg, options = {})
    options[:color] ||= :default
    options[:tab] ||= 0
    
    format = "\t"*options[:tab]
    msg = msg.join("\n#{format}") if msg.class == Array
    format << '%s'
    
    puts sprintf(format, msg).color(options[:color])
  end
  
  def log(msg)
    # Do the work of passing it on to some logger object handler
  end
  
  def quiet
    @config["quiet"]
  end

  def watch(name, &block)
    name = File.expand_path(name)
    
    raise "Directory #{name} not found" unless File.directory? name
    if @directories.include? name
      say '*** WARNING ***'.bright, :color => :yellow
      say "Already watching #{name}!",
          "Ignoring second watch in #{@current_worker}", :color => :yellow
      return
    else
      say "Watching #{name}", :color => :green
    end

    @directories[name] ||= []
    @current = @directories[name]

    @current << Watch.instance.instance_eval(&block)
  end

  def monitor
    reload!

    say "Starting Monitor"
    @fssm = FSSM::Monitor.new

    @directories.keys.each do |dir|
      @fssm.path(dir) do
        update do |path,filename| 
          Conveyor.instance.dispath(path, filename)  
        end
        create do |path,filename| 
          Conveyor.instance.dispath(path, filename)  
        end

      end
    end
    
    say "Started Monitor"
    @running = true
    @fssm.run
  end

  def dispath(path, filename)
    @directories[path].each do |worker|
      worker.start(path, filename)
    end
  end

  def reload!
    say "Loading workers from #{@worker_defs}"
    @directories = {}
    Dir.glob(File.join(@worker_defs, '*.worker')) do |file|
      begin
        @current_worker = file
        load file
      rescue => e
        say e.message.capitalize, :color => :red
        say e.backtrace, :color => :red, :tab => 1
        say "Error loading #{file}, skipping", :color => :red
      end
    end
  end
end

def watch(name, &block)
  Conveyor.instance.watch(name, &block)
end
