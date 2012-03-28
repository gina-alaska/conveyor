module Conveyor
  module Output
    class Email
      class << self
        def say(*msg)
          # Do nothing
        end
        
        def warning(*msg)
          # Do nothing
        end
        
        def error(*msg)
          options = msg.extract_options!

          msg = msg.join("\n") if msg.class == Array
          
          puts "Sending email to #{Conveyor::Foreman.instance.notify_list}"
          puts msg
        end
      end
    end
  end
end