module Conveyor
  class Queue
    def initialize
      @mutex = Mutex.new
      @queue = []
    end

    def count
      @queue.count
    end

    def touch(file)
      push(file)
    end

    def push(file)
      @mutex.synchronize do
        i = @queue.find_index { |j| j[:file] == file }
        if i.nil?
          @queue.push({ :file => file, :updated_at => Time.now })
        else
          @queue[i][:updated_at] = Time.now
        end
        @queue.sort! { |x,y| x[:updated_at] <=> y[:updated_at] }
      end
    end

    def reserve(file = nil)
      @mutex.synchronize do
        # find first non-reserved job
        i = @queue.find_index { |j| !j[:reserved] }
        @queue[i][:reserved] = true unless i.nil?
        @queue[i] unless i.nil?
      end
    end
    
    def unreserve(job)
      @mutex.synchronize do
        i = find_index(job[:file])
        @queue[i][:reserved] = false unless i.nil?
        @queue[i] unless i.nil?
      end
    end
    
    def find_index(file = nil)
      if file.nil?
        @queue.empty? ? nil : 0
      else
        @queue.find_index { |j| j[:file] == file }
      end
    end

    def find(file)
      i = find_index(file)
      @queue[i] unless i.nil?
    end

    def unpop(job)
      @mutex.synchronize do
        unless find(job[:file])
          @queue.push(job)
          @queue.sort! { |x,y| x[:updated_at] <=> y[:updated_at] }
        end
      end
    end

    def pop(file = nil)
      if file.nil?
        @mutex.synchronize do
          @queue.shift
        end
      else
        @mutex.synchronize do
          j = find(file)
          @queue.delete(j)
        end
      end
    end
  end
end