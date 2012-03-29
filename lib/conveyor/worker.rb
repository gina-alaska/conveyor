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
    
    def sync
      run 'sync', :quiet => true
    end
  
    def run(*cmd)
      opts = cmd.extract_options!
      begin
        say cmd.join(' ') unless opts[:quiet]
        output,err,status = Open3.capture3(Array.wrap(cmd).join(' '))
        say output.chomp unless output.chomp.length == 0
        error err unless status.success?

        return status.success?
      rescue => e
        error e.class, e.message, e.backtrace.join("\n")
      end
    end

    def start(path, file)
      @filename = File.join(path, file)
    
      if @glob =~ filename
        say "Starting worker for #{path}"
        instance_exec(filename, &@block) 
        say "Completed worker for #{path}", :color => :green
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
        say "removing #{f}"
        FileUtils.rm(f)
      end
    end
    
    def mkdir(dir)
      FileUtils.mkdir_p(File.expand_path(dir))      
    end

    def copy(src = [], dest = nil)
      destination = dest unless dest.nil?
      source = src unless src.empty?
      
      if source && destination
        verified_copy(source, destination)
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
    
    def create_dirs_for_copy(src, dest)
      if src.is_a?(Array) || Array.wrap(src).count > 1 || dest.last == ?/
        mkdir(dest)
      else
        mkdir(File.dirname(dest))
      end
    end
    
    def verified_copy(src, dest)
      create_dirs_for_copy(src, dest)
      dest = File.expand_path(dest)
      
      success = true
      Array.wrap(src).each do |s|
        if File.directory? s
          error "Tried to copy a directory #{s}, only files are allowed"
          return false
        end
        
        run "cp #{s} #{dest}"
        sync
        success &= verify_copy(s, dest)
      end
      
      success
    end
    
    def verify_copy(src, dest)
      if File.directory? dest
        File.exists?(File.join(dest, File.basename(src)))
      else
        File.exists?(dest)
      end
    end
      
    def escape_glob(glob)
      if glob.class == String 
        Regexp.new(Regexp.escape(glob))
      else 
        glob
      end
    end  
  end
end