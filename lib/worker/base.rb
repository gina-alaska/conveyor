module Worker 
  class Base
    attr_accessor :path, :filename, :belt
    
    def initialize(path, filename, belt, &block)
      @path = path
      @filename = filename
      @belt = belt
      
      instance_eval(&block) if block_given?
    end    
    
    def from
      File.join(path, filename)      
    end
    
    def to
      File.join(belt.to, filename)
    end
    
    def diff
      puts "Diff method not implemented for #{self.class}"
    end
    
    def run
      puts "Run method not implemented for #{self.class}"
    end
  end 
end
