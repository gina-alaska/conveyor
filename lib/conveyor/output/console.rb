module Conveyor
  module Output
    class Console
      class << self
        def say(*msg)
          options = msg.extract_options!
          options[:color] ||= :default
          options[:tab] ||= 0

          format = "\t"*options[:tab]
          msg = msg.join("\n#{format}") if msg.class == Array
          format << '%s'

          puts sprintf(format, msg).color(options[:color])
        end
      end
    end
  end
end