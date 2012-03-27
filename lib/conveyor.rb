require 'singleton'
require 'fssm'
require 'yaml'
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
    if File.exists?('.Conveyor')
      YAML.load(File.open('.Conveyor'))
    elsif File.exists?('~/.Conveyor')
      YAML.load(File.open('~/.Conveyor'))
    else
      { "worker_defs" => File.expand_path('../workers/', File.dirname(__FILE__)) }
    end
  end
  
  def say(msg)
    puts(msg)
    # this should pass it on to the logger
  end
  
  def log(msg)
    # Do the work of passing it on to some logger object handler
  end

  def watch(name, &block)
    name = File.expand_path(name)
    
    raise "Directory #{name} not found" unless File.directory? name
    if @directories.include? name
      say '**************************'
      say "Already watching #{name}!!"
      say 'Ignoring second watch'
      say '**************************'
      return
    else
      say "Watching #{name}"
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
      load file
    end
  end
end

def watch(name, &block)
  Conveyor.instance.watch(name, &block)
end
