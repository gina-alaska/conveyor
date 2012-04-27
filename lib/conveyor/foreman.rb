module Conveyor
  # Handle the incoming watch requests and assign the workers
  class Foreman
    include Singleton
    include Conveyor::Output
  
    attr_accessor :workers
    def initialize
      loglvl(:debug)

      @config = read_configs
      @listeners = {}
      @belts = {}
      @worker_defs = ARGV.shift
      @worker_defs ||= @config["worker_defs"]
    end

    def logfile
      File.expand_path(@config["logfile"])
    end

    def name
      'Foreman'
    end
  
    def read_configs
      if File.exists?('.conveyor')
        YAML.load(File.open('.conveyor'))
      elsif File.exists?('~/.conveyor')
        YAML.load(File.open('~/.conveyor'))
      else
        { 
          "worker_defs" => File.expand_path('.workers', Dir.pwd),
          "logfile" => './log/conveyor.log'
        }
      end
    end

    def watch(*args, &block)
      opts = args.extract_options!
      
      dir = File.expand_path(args.first)
    
      raise "Directory #{dir} not found" unless File.directory? dir

      listener = Listen.to(dir)
      listener.latency(0.5)
      listener.ignore(opts[:ignore]) if opts[:ignore]
      listener.force_polling(opts[:force_polling]) if opts[:force_polling]

      b = @belts[dir] = Belt.new(dir, @current_worker)
      callback = lambda do |modified, added, removed|
        begin
          files = modified + added
          b.touch(files) unless files.empty?
        rescue => e
          puts "Error: " + e.message
          puts e.backtrace
        end
      end

      listener.change(&callback)
      @listeners[dir] = listener
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
      @listeners.each do |k, listener| 
        info "Watching #{k}"
        listener.start(false) 
      end

      info "Waiting for files..."
      # Conveyor::Input.listen
      EM.run do
        p = EM::PeriodicTimer.new(1) do
          output_status
        end

        EM::PeriodicTimer.new(1) do
          @belts.each do |dir, b|
            EM.defer do
              b.check
            end
          end
        end
      end

      info "Stopping Monitor", :color => :green
    end

    def output_status
      status = @belts.collect { |dir, b| "#{b.name}: #{b.count}" }
      print " #{status.join(', ')}\r"
    end

    def load!
      @listeners.each { |dir,l| info "Stopping #{dir} listener"; l.stop }

      @listeners = {}
      @notify_list = []
      
      info "Loading workers from #{@worker_defs}"      
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
