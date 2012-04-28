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

        Array.new(msg).each do |m|
          @channel.push [msgtype, sprintf(format, Time.now, name, msgtype, m)]
        end
      end
    end
  end
end