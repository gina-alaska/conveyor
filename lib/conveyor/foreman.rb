module Conveyor
  # Handle the incoming watch requests and assign the workers
  class Foreman
    include Singleton
    include Conveyor::Output

    attr_accessor :workers, :channel, :config

    def initialize
      loglvl(:debug)
      read_configs

      @listeners = {}
      @belts = {}
      @worker_defs = ARGV.shift
      @worker_defs ||= @config[:worker_defs]

    end

    def logfile
      File.expand_path(@config[:logfile])
    end

    def name
      'Foreman'
    end

    def channel 
      @channel ||= EM::Channel.new
    end
  
    def read_configs
      if File.exists?('.conveyor')
        @config = YAML.load(File.open('.conveyor'))
      elsif File.exists?('~/.conveyor')
        @config = YAML.load(File.open('~/.conveyor'))
      end

      @config["worker_defs"] ||= File.expand_path('.workers', Dir.pwd)
      @config["logfile"] ||= './log/conveyor.log'
      @config["threadpool"] ||= 20

      @config["websocket"] ||= {}
      @config["websocket"]["host"] ||= "0.0.0.0"
      @config["websocket"]["port"] ||= 9876

      @config.symbolize_keys!
      @config[:websocket].symbolize_keys!
    end

    def watch(*args, &block)
      @listener_opts = args.extract_options!
      @listener_dir = File.expand_path(args.first)
      raise "Directory #{@listener_dir} not found" unless File.directory? @listener_dir
      
      @listener_opts[:latency] ||= 1
      # Set a large latency if we force polling, prevents high cpu usage
      @listener_opts[:latency] = 1 if @listener_opts[:latency] < 1 and @listener_opts[:force_polling]
      
      yield
    end
    
    def match(*args, &block)
      opts = args.extract_options!
      debug "Filters: #{args.inspect}"
      
      listener = Listen.to(@listener_dir)
      if @listener_opts[:latency]
      	listener.latency(@listener_opts[:latency])
      else
	      listener.latency(0.5)
      end

      listener.ignore(opts[:ignore]) if @listener_opts[:ignore]
      listener.force_polling(opts[:force_polling]) if @listener_opts[:force_polling]
      listener.filter(*args)

      b = @belts[@listener_dir] = Belt.new(@listener_dir, @current_worker)
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
      @listeners[@listener_dir] = listener
    rescue => e
      error "ERROR: #{e.message}"
      error e.backtrace
    end
    
    def file(glob)
      /#{glob}$/
    end
    
    def extension(glob)
      /\.#{glob}$/
    end

    def any
      '*'
    end
    
    def notify_list
      @notify_list.flatten!
      @notify_list.uniq!
      @notify_list
    end

    def stop!
      @listeners.each { |dir,l| info "Stopping #{dir} listener"; l.stop }
      @listeners = {}
      @notify_list = []      
    end
    
    def start
      load!
      @listeners.each do |k, listener| 
        info "Watching #{k}"
        listener.start(false) 
      end
    end

    def output_status
      status = @belts.collect { |dir, b| "#{b.name}: #{b.count}" }
      print "\r#{status.join(', ')}"
    end

    def check
      @belts.each do |dir, b|
        EM.defer do
          b.check
        end
      end      
    end

    def load!
      stop!
      
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
    
    def method_missing(method, value = nil)
      return method.to_s
    end 
  end
end
