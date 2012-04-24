module Conveyor
  class Status
    attr_reader :success
    attr_accessor :errors
    attr_reader :path
    
    def initialize(path = nil)
      reset!(path)
    end
    
    def reset!(path = nil)
      @path = path
      @success = true
      @errors = []
    end
    
    def fail!(v = false)
      @success &= v
    end
    
    def success!(v=true)
      @success &= v
    end
    
    def success?
      @success
    end
  end
end