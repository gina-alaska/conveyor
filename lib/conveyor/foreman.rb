module Conveyor
  # Handle the incoming watch requests and assign the workers
  class Foreman
    include Singleton
    include Conveyor::Output

    attr_accessor :workers, :channel

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
      @config["websocket"]["enable"] ||= true
      @config["websocket"]["host"] ||= "0.0.0.0"
      @config["websocket"]["port"] ||= 8080

      @config.symbolize_keys!
      @config[:websocket].symbolize_keys!
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
      EM.threadpool_size = @config[:threadpool] || 20
      EM.run do
        @channel = EM::Channel.new

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

        if @config[:websocket][:enable]
          EventMachine::WebSocket.start(@config[:websocket]) do |ws|
            ws.onopen {
              sid = @channel.subscribe { |msg| ws.send msg }
              info "#{sid} connected to websocket!"
              ws.onclose {
                @channel.unsubscribe(sid)
              }
            }
          end
        end
      end

      info "Stopping Monitor", :color => :green
    end

    def output_status
      status = @belts.collect { |dir, b| "#{b.name}: #{b.count}" }
      print "\r#{status.join(', ')}"
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
