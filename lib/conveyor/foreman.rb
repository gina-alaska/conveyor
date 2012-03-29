module Conveyor
  # Handle the incoming watch requests and assign the workers
  class Foreman
    include Singleton
    include Conveyor::Output
  
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

    def watch(name, &block)
      name = File.expand_path(name)
    
      raise "Directory #{name} not found" unless File.directory? name
      if @directories.include? name
        warning "Already watching #{name}!",
                "Ignoring additional watch for #{name} in #{@current_worker}"
        return
      else
        say "Watching #{name}"
      end

      @directories[name] ||= []
      @current_directory = @directories[name]

      # make a new belt and added it to the conveyor
      belt = Belt.new(@current_worker)
      belt.instance_eval(&block)
      @current_directory << belt
    end
    
    def notify_list
      @notify_list.flatten!
      @notify_list.uniq!
      @notify_list
    end
    
    def monitor
      reload!

      say "Starting Monitor"
      @fssm = FSSM::Monitor.new

      @directories.keys.each do |watch_dir|
        @fssm.path(watch_dir) do
          update do |path,filename| 
            Foreman.instance.dispath(watch_dir, path, filename)  
          end
          create do |path,filename| 
            Foreman.instance.dispath(watch_dir, path, filename)  
          end
        end
      end
    
      say "Started Monitor", :color => :green
      @running = true
      @fssm.run
    end

    def dispath(watch_dir, path, filename)
      # Skip directories we are no longer watching
      return if @directories[watch_dir].nil?
      
      @directories[watch_dir].each do |belt|
        belt.worker.start(path, filename)
      end
    end

    def reload!
      @directories = {}
      @notify_list = []
      
      say "Loading workers from #{@worker_defs}"      
      Dir.glob(File.join(@worker_defs, '*.worker')) do |file|
        begin
          @current_worker = File.expand_path(file)
          load @current_worker
        rescue => e
          error [
            "Error loading #{@current_worker}, skipping", 
            e.message.capitalize, 
            e.backtrace
          ].flatten
        end
      end
    end
  end
end