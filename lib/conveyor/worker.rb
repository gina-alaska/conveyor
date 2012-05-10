require 'rubygems'
require 'active_support/core_ext'
require 'open3'

module Conveyor
  class Worker
    include Conveyor::Output
    
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
    
    def file(glob)
      "**/#{glob}"
    end
    
    def extension(glob)
      "*.#{glob}"
    end

    def any
      '*'
    end
  
    def method_missing(method, value = nil)
      return method.to_s
    end    

    def watch(*args, &block)
      yield
    end

    def match(glob, &block)
      debug "#{@filename} matches? #{glob}"
      # puts File.fnmatch(glob, @filename)
      if File.fnmatch(glob, @filename, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        yield @filename
      end
    end

    def name(value=nil)
      @name = value unless value.nil?
      @name ||= File.basename(worker_def)
      @name
    end

    def logfile
      dir = File.dirname(worker_def)
      File.expand_path(File.basename(worker_def, '.worker') + '.log', dir)
    end
    
    def sync
      run 'sync', :quiet => true
    end
    
    def error(*msg)
      opts = msg.extract_options!
      unless msg.flatten.empty?
        @status.fail!
        msg.unshift("Error encountered in #{worker_def}")
        super(*msg, opts)
      end
      @status.success?
    end
    
    def run(*cmd)
      opts = cmd.extract_options!
      begin
        info cmd.join(' ') unless opts[:quiet]
        output,err,thr = Open3.capture3(Array.wrap(cmd).join(' '))
        info output.chomp unless output.chomp.length == 0
				if thr.success?
					if err.chomp.length > 0
						warning "Error output recieved, but no error code recieved"
						warning err.chomp
					end
				else
        	error "Error running: `#{cmd.join(' ')}`", err.chomp 
        	@status.fail!
				end
        
        return thr.success?
      rescue => e
        error e.class, e.message, e.backtrace.join("\n")
      end
    end

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

    def like(name)
      dir = File.dirname(name)
      Dir.glob(File.join(dir, File.basename(name, '.*') + '.*'))
    end
    
    def delete(files)
      # sync before we delete
      sync
      Array.wrap(files).each do |f|
        info "removing #{f}"
        FileUtils.rm(f)
        error "#{f} wasn't removed" if File.exists?(f)
      end
    end
    
    def mkdir(dir)
      FileUtils.mkdir_p(File.expand_path(dir))      
      @status.fail! unless File.exists?(File.expand_path(dir))
    end

    def copy(src = [], dest = nil)
      destination = dest unless dest.nil?
      source = src unless src.empty?
      
      if source && destination
        verified_copy(source, destination)
      end      
    end
    
    def move(src=[], dest = nil)
      destination = dest unless dest.nil?
      source = src unless src.empty?
      
      if source && destination
        verified_move(source, destination)
      end
    end
  
    def scp(src, dest)
      run "scp #{Array.wrap(src).join(' ')} #{dest}"
    end

    def filename
      @filename
    end
    
    def chdir(dir, &block)
      Dir.chdir(File.expand_path(dir), &block)
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
        # say cmd
        # return error "Tried to copy a directory #{s}, only files are allowed" if File.directory? s
        
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
