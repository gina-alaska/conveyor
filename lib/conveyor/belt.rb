module Conveyor
  # Does not persist, do not use any class variables 
  class Belt
    include Conveyor::Output

    attr_reader :command_file
    
    def initialize(watch_path, command_file)#, opts = {})
      @work_dir = watch_path
      @command_file = command_file
      @files = {}
      @opts = {}
      @queue = Conveyor::Queue.new
    end

    def reload!
      warning "Reloading workers!"
      Forman.instance.load!
    end

    def watch(*args, &block)
      opts = args.extract_options!
      path = File.expand_path(args.shift)

      if File.fnmatch(path, @work_dir)
        instance_eval(&block) 
      end
    end

    def touch(files)
      files.each do |f|
        @queue.push(f)
      end
    end

    def match(glob, &block)
      if File.fnmatch(glob, @current_file)
        Worker.new(@command_file, @loglvl).start(@current_file, &block)
      end
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
    
    def check
      job = @queue.peek
      if !job.nil? && (Time.now - job[:updated_at]) > 30
        @queue.pop(job[:file])
        process(job[:file])
        true
      else
        false
      end
    rescue => e
      puts e.message
      puts e.backtrace
    end

    private

    def process(file)
      @current_file = file
      self.instance_eval File.read(@command_file)
    end

    def escape_glob(glob)
      if glob.class == String 
        Regexp.new(glob)
      else 
        glob
      end
    end  
  end
end