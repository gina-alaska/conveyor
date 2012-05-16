module Conveyor
  module Workers
    module Syntax
      
      # Will return a string of any method returned that isn't handled
      # ex: match extension txt => match(extension("foo"))
      def method_missing(method, value = nil)
        return method.to_s
      end      
      
      # Returns a recursive file glob string for the passed in string
      def file(glob)
        "**/#{glob}"
      end
    
      # Returns an extension glob string for passed in string
      def extension(glob)
        "*.#{glob}"
      end

      # Returns a glob string that will match any file
      def any
        '*'
      end
      
      # Returns a list of files that have the same basename but different extension
      # in the same directory
      def like(name)
        dir = File.dirname(name)
        Dir.glob(File.join(dir, File.basename(name, '.*') + '.*'))
      end

      # Returns the filename of the file that triggered the job
      def filename
        @filename
      end
      
      # Which directories to watch for file change events.
      def watch(*args, &block)
        yield
      end

      # Match string/glob for the files that should trigger file change events
      def match(glob, &block)
        yield @filename
      end
      
      # Run the system sync command
      def sync
        run 'sync', :quiet => true
      end
    
      # Change current working directory, optionally takes a block
      # NOTE: Consider removing this as it can cause problems with threaded workers
      def chdir(dir, &block)
        Dir.chdir(File.expand_path(dir), &block)
      end
      
      # Run the system command, and make sure that any errors are caught and returne
      # up the status change
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
      
      # Deletes passed in files
      def delete(files)
        # sync before we delete
        sync
        Array.wrap(files).each do |f|
          info "removing #{f}"
          FileUtils.rm(f)
          error "#{f} wasn't removed" if File.exists?(f)
        end
      end
    
      # Create a new directory
      def mkdir(dir)
        FileUtils.mkdir_p(File.expand_path(dir))      
        @status.fail! unless File.exists?(File.expand_path(dir))
      end

      # Copy files to destination
      def copy(src = [], dest = nil)
        destination = dest unless dest.nil?
        source = src unless src.empty?
      
        if source && destination
          verified_copy(source, destination)
        end      
      end
    
      # Move files to destination
      def move(src=[], dest = nil)
        destination = dest unless dest.nil?
        source = src unless src.empty?
      
        if source && destination
          verified_move(source, destination)
        end
      end
  
      # Scp files to destination
      # See: man scp
      def scp(src, dest)
        run "scp #{Array.wrap(src).join(' ')} #{dest}"
      end
    end
  end
end