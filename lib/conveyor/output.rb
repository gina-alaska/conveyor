require 'conveyor/output/console'
require 'conveyor/output/email'

module Conveyor
  module Output
    def say(*msg)
      output(:say, *msg)
    end
    
    def warning(*msg)
      output(:warning, *msg)
    end
    
    def error(*msg)
      output(:error, *msg)
    end
    
    def output(type, *msg)
      Console.send(type, *msg)
      Email.send(type, *msg)
    end
    
    def notify(*emails)
      Conveyor::Foreman.instance.notify_list << emails
    end
  end
end