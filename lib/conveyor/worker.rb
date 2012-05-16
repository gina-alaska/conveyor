require 'rubygems'
require 'active_support/core_ext'
require 'open3'
require 'conveyor/workers/syntax'

module Conveyor
  class Worker
    include Conveyor::Output
    include Conveyor::Workers::Syntax
    
    attr_accessor :filename
    attr_reader :status
    attr_reader :worker_def

    def initialize(file, worker_def, log = MSGLVLS[:debug])
      @filename = file
      @loglvl = log
      @worker_def = worker_def
      @notify = []
      # @glob = escape_glob(glob)
    end

    # Return name to be used for logging purposes
    def name(value=nil)
      @name = value unless value.nil?
      @name ||= File.basename(worker_def)
      @name
    end

    # Default log file to be based on worker def name
    def logfile
      dir = File.dirname(worker_def)
      File.expand_path(File.basename(worker_def, '.worker') + '.log', dir)
    end
    
    # Catch any calls to error and set the status fail flags
    def error(*msg)
      opts = msg.extract_options!
      unless msg.flatten.empty?
        @status.fail!
        msg.unshift("Error encountered in #{worker_def}")
        super(*msg, opts)
      end
      @status.success?
    end

    # Start the worker
    def start
      @status = Conveyor::Status.new(@filename)
      info "Starting #{@filename}", :color => :green
      @start = Time.now
      begin
        instance_eval(File.read(@worker_def), worker_def)
      ensure
        @elapsed = "%0.2f"%(Time.now - @start)

        #Check status and send any errors we collected
        if @status.success?
          info "Completed #{@filename}, #{@elapsed}s elapsed", :color => :green
        else
          error "Error(s) encountered in #{@filename}", :color => :red
        end
        send_notifications
      end
    end
  
    protected
    
    def create_dirs_for_cmd(src, dest)
      if src.is_a?(Array) || Array.wrap(src).count > 1 || dest.last == ?/
        mkdir(dest)
      else
        mkdir(File.dirname(dest))
      end
    end
    
    def verified_cmd(cmd, src, dest, &block)
      create_dirs_for_cmd(src, dest)
      dest = File.expand_path(dest)
      
      Array.wrap(src).each do |s|
        run "#{cmd} #{s} #{dest}"
        sync
        
        if block_given?
          result = yield(s, dest)
          @status.fail! unless result
        end
      end
    end
    
    def verified_move(src, dest)
      verified_cmd(:mv, src, dest) do |src,dest|
        verify_move(src,dest)
      end
    end
        
    def verified_copy(src, dest)
      verified_cmd(:cp, src, dest) do |src,dest|
        verify_copy(src,dest)
      end
    end
    
    def verify_copy(src, dest)
      if File.directory? dest
        File.exists?(File.join(dest, File.basename(src)))
      else
        File.exists?(dest)
      end
    end
    
    def verify_move(src, dest)
      if File.directory? dest
        File.exists?(File.join(dest, File.basename(src))) && !File.exists?(src)
      else
        File.exists?(dest) && !File.exists?(src)
      end
    end
  end
end
