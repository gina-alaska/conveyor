module Conveyor
  class Queue
    def initialize
      @mutex = Mutex.new
      @queue = []
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

    def peek(file = nil)
      if(file.nil?)
        @queue.first
      else
        find(file)
      end
    end

    def find(file)
      i = @queue.find_index { |j| j[:file] == file }
      @queue[i]
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