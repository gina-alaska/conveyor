require 'singleton'

module Conveyor
  # Does not persist, do not use any class variables 
  class Watch
    include Singleton
    include Conveyor::Output

    def match(glob, &block) 
      Worker.new(glob, &block)
    end
    
    def extension(glob)
      Regexp.new("\.#{glob}$")
    end
  
    def method_missing(method, value = nil)
      return method.to_s
    end
  end
end