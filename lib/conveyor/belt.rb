module Conveyor
  # Does not persist, do not use any class variables 
  class Belt
    include Conveyor::Output
    
    attr_reader :worker_def
    attr_reader :worker
    
    def initialize(worker_def)
      @worker_def = worker_def
    end

    def match(glob, &block) 
      @worker = Worker.new(worker_def, glob, &block)
    end
    
    def extension(glob)
      Regexp.new("\.#{glob}$")
    end
  
    def method_missing(method, value = nil)
      return method.to_s
    end
  end
end