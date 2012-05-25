module Conveyor
  module Output
    class Email
      class << self
        def say(*msg)
          # Do nothing
        end
        alias_method :info, :say
        alias_method :debug, :say

        def reset!
          @msg_queue = []
        end
        
        def warning(*msg)
          # Do nothing
        end
        
        def error(*msg)
          @msg_queue ||= []
          options = msg.extract_options!

          msg =  msg.join("\n") if msg.class == Array
          @msg_queue << msg
        end
        
        def write(msgtype, *msg)
          if respond_to?(msgtype)
            self.send(msgtype, *msg)
          end
        end
        
        def mail
          return if @msg_queue.nil? || @msg_queue.empty?
          puts "Sending email to #{Conveyor::Foreman.instance.notify_list}"
          puts @msg_queue
          reset!
        end
      end
    end
  end
end