module Conveyor
  # Handle the incoming watch requests and assign the workers
  class Foreman
    include Singleton
    include Conveyor::Output
  
    def initialize
      @listeners = []
      @config = read_configs
      @workers = {}
      @worker_defs = ARGV.shift
      @worker_defs ||= @config["worker_defs"]
    end


    def workers
      @worker_defs
    end    
  
    def read_configs
      if File.exists?('.conveyor')
        YAML.load(File.open('.conveyor'))
      elsif File.exists?('~/.conveyor')
        YAML.load(File.open('~/.conveyor'))
      else
        { "worker_defs" => File.expand_path('.workers', Dir.pwd) }
      end
    end

    def watch(*args, &block)
      opts = args.extract_options!
      
      opts[:latency] ||= 0.5

      dir = File.expand_path(args.first)
    
      raise "Directory #{dir} not found" unless File.directory? dir

      listener = Listen.to(dir)
      listener.latency(opts[:latency]) if opts[:latency]
      listener.ignore(opts[:ignore]) if opts[:ignore]
      listener.force_polling(opts[:force_polling]) if opts[:force_polling]

      b = Belt.new(dir, @current_worker)
      callback = lambda do |modified, added, removed|
        files = modified + added
        b.start(files.uniq);
      end

      listener.change(&callback)
      @workers[dir] = listener
    rescue => e
      error "ERROR: #{e.message}"
      error e.backtrace
    end
    
    def notify_list
      @notify_list.flatten!
      @notify_list.uniq!
      @notify_list
    end
    
    def start_monitor
      load!
      @workers.each do |k, listener| 
        say "Watching #{k}"
        listener.start(false) 
      end

      say "Waiting for files..."
      loop do
        sleep 1
      end

      say "Stopping Monitor", :color => :green
    end

    def load!
      @workers.each { |dir,l| say "Stopping #{dir} listener"; l.stop }

      @workers = {}
      @notify_list = []
      
      say "Loading workers from #{@worker_defs}"      
      Dir.glob(File.join(@worker_defs, '*.worker')) do |file|
        begin
          @current_worker = File.expand_path(file)
          instance_eval File.read(@current_worker)
        rescue => e
          error [
            "Error loading #{@current_worker}, skipping", 
            e.message, 
            e.backtrace
          ].flatten
        end
      end
    end
  end
end