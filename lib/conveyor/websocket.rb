module Conveyor
  class Websocket
    class << self
      def start
        if config[:disable]
          fm.info "Websocket disabled"
          return
        end

        fm.info "Starting websocket on #{config[:host]}:#{config[:port]}", :color => :green
        
        EventMachine::start_server(config[:host], config[:port],
          EventMachine::WebSocket::Connection, config) do |ws|
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
        # EM::WebSocket.stop unless config[:disable]
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