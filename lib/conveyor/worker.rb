require 'rubygems'
require 'active_support/core_ext'
require 'open3'

module Conveyor
  class Worker
    include Conveyor::Output
    
    attr_accessor :filename

    def initialize(glob, &block)
      @glob = escape_glob(glob)
      @block = block
    end

    # Causes a reload of the worker scripts
    def reload!
      say "RELOADING!"
      Foreman.instance.reload!
    end
  
    # TODO wrap this in some sort of popen3 call 
    def run(cmd)
      output,error,status = Open3.capture3(cmd)
      say cmd, :color => (status.success? ? :green : :red)
      say output.chomp unless output.chomp.length == 0
      say error unless status.success?
      
      return status.success?
    end

    def start(path, file)
      @filename = File.join(path, file)
    
      if @glob =~ filename
        @source = filename
        
        say "Starting worker for #{path}", :color => :green
        instance_exec(filename, &@block) 
        say "Completed worker for #{path}", :color => :green
      end
    end

    def like(name)
      dir = File.dirname(name)
      @source = Dir.glob(File.join(dir, File.basename(name, '.*') + '.*'))
    end

    def copy(*args)
      if(args.count == 1) 
        @destination = args.first
      elsif args.count > 1
        @destination = args.pop
        @source = args.flatten
      end
      
      if @source && @destination
        @destination = File.expand_path(@destination)

        say "Copying #{@source.inspect} to #{@destination}"
        if @source.class == Array || Array.wrap(@source).count > 1
          FileUtils.mkdir_p(@destination)
          FileUtils.cp_r(@source, @destination)
        else
          FileUtils.mkdir_p(File.dirname(@destination))
          FileUtils.cp(@source, @destination)
        end
      end
    end
  
    def scp(*args)
      if(args.count == 1) 
        @destination = args.first
      elsif args.count > 1
        @destination = args.pop
        @source = args.flatten
      end

      if @source && @destination
        
        run "scp #{Array.wrap(source).join(' ')} #{destination}"
      end    
    end

    def source(name=nil)
      @source = name unless name.nil?
    end
    alias_method :from, :source

    def destination(name=nil)
      @destination = name unless name.nil?
      @destination
    end
    alias_method :to, :destination

    def filename(args = nil)
      @filename
    end
    
    def chdir(dir, &block)
      Dir.chdir(File.expand_path(dir), &block)
    end
  
    protected
  
    def escape_glob(glob)
      if glob.class == String 
        Regexp.new(Regexp.escape(glob))
      else 
        glob
      end
    end  
  end
end