module Conveyor
  # Does not persist, do not use any class variables 
  class Belt
    SETTLE_TIME = 30

    include Conveyor::Output

    attr_reader :command_file
    
    def initialize(watch_path, command_file)#, opts = {})
      @work_dir = watch_path
      @command_file = command_file
      @queue = Conveyor::Queue.new
    end

    def count
      @queue.count
    end

    def name
      File.basename(@command_file, '.worker')
    end

    def touch(files)
      files.each do |f|
        @queue.push(f)
      end
    end
    
    def check
      job = @queue.pop
      # puts job.inspect
      if job && (Time.now - job[:updated_at]) > SETTLE_TIME
        Worker.new(job[:file], @command_file).start
      else
        @queue.unpop(job) unless job.nil?
      end
    rescue => e
      puts e.message
      puts e.backtrace
    end

    private

    def process(file)
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