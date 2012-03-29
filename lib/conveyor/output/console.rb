module Conveyor
  module Output
    class Console
      class << self
        def say(*msg)
          options = msg.extract_options!
          options[:color] ||= :default
          options[:tab] ||= 0

          format = "\t"*options[:tab]
          format << '[%s] %s'
          if msg.class == Array
            msg.each do |m|
              puts sprintf(format, Time.now, m).color(options[:color])              
            end
          else
            puts sprintf(format, Time.now, msg).color(options[:color])              
          end
        end
        
        def warning(*msg)
          options = msg.extract_options!
          options[:color] ||= :yellow
          msg.flatten!
          say(*msg, options)
        end
                
        def error(*msg)
          options = msg.extract_options!
          options[:color] ||= :red
          msg.flatten!
          say(*msg, options)
        end
      end
    end
  end
end