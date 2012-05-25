module Conveyor
  module Output
    class Campfire
      include Singleton
      
      def initialize
        @config = Conveyor::Foreman.instance.config[:campfire]
        if enabled?
          @campfire = Tinder::Campfire.new @config[:subdomain], :token => @config[:token]
        end
      end
      
      def write(name, msgtype, *msg)
        return false if !enabled? or msgtype != :announce
        
        room = @campfire.find_room_by_name(@config[:room])
        room.speak msg.join("\n")
      end
      
      def enabled?
        !@config[:subdomain].empty? && !@config[:token].empty? && !@config[:room].empty?
      end
    end
  end
end