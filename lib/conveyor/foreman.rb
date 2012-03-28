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

      # make a new worker and added it to the queue
      @current << Watch.instance.instance_eval(&block)
    end

    def monitor
      reload!

      say "Starting Monitor"
      @fssm = FSSM::Monitor.new

      @directories.keys.each do |dir|
        @fssm.path(dir) do
          update do |path,filename| 
            Foreman.instance.dispath(dir, path, filename)  
          end
          create do |path,filename| 
            Foreman.instance.dispath(dir, path, filename)  
          end

        end
      end
    
      say "Started Monitor"
      @running = true
      @fssm.run
    end

    def dispath(watch_dir, path, filename)
      @directories[watch_dir].each do |worker|
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
end