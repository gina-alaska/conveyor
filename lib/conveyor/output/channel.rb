module Conveyor
  module Output
    class Channel
      include Singleton

      def initialize
      end

      def write(name, msgtype, *msg)
        @channel = Conveyor::Foreman.instance.channel
        return false if @channel.nil?
        
        options = msg.extract_options!
        format = '[%s] [%s::%s] %s'

        if msg.class == Array
          msg.each do |m|
            @channel.push sprintf(format, Time.now, name, msgtype, m)
          end
        else
          @channel.push sprintf(format, Time.now, name, msgtype, msg)
        end
      end
    end
  end
end