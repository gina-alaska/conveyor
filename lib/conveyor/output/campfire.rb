module Conveyor
  module Output
    class Campfire
      include Singleton
      
      def initialize
        @config = Conveyor::Foreman.instance.config[:campfire]
        @host = Socket.gethostname
        
        if enabled?
          @campfire = Tinder::Campfire.new @config[:subdomain], :token => @config[:token]
        end
      end
      
      def write(name, msgtype, *msg)
        return false if !enabled? or msgtype != :announce
        
        room = @campfire.find_room_by_name(@config[:room])
        Array(msg).each do |m|
          room.speak "[#{@host}::#{name}] #{m}"
        end
      end
      
      def enabled?
        !@config[:subdomain].empty? && !@config[:token].empty? && !@config[:room].empty?
      end
    end
  end
end