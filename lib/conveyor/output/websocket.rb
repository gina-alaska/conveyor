module Conveyor
  module Output
    class Websocket
      def write(name, msgtype, *msg)
        websocket = Conveyor::Foreman.instance.websocket
        return false if websocket.nil?

        options = msg.extract_options!
        format = '[%s] [%s::%s] %s'

        if msg.class == Array
          msg.each do |m|
            websocket.send sprintf(format, Time.now, name, msgtype, m)
          end
        else
          websocket.send sprintf(format, Time.now, name, msgtype, msg)
        end
      end
    end
  end
end