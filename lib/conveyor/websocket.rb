module Conveyor
  class Websocket
    class << self
      def start
        if config[:disable]
          fm.info "Websocket disabled"
          return
        end
        return

        fm.info "Starting websocket on #{@config[:host]}:#{@config[:port]}", :color => :green

        EM::WebSocket.start(config) do |ws|
          ws.onopen {
            sid = fm.channel.subscribe { |type,msg| ws.send msg }
            fm.info "#{sid} connected to websocket!"
            ws.onclose {
              fm.channel.unsubscribe(sid)
            }
          }
        end
      end

      def stop
        return
        EM::WebSocket.stop unless config[:disable]
      end

      def fm
        Conveyor::Foreman.instance
      end

      def config
        fm.config[:websocket]
      end
    end
  end
end