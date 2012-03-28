require 'conveyor/output/console'

module Conveyor
  module Output
    def say(*msg)
      Console.say(*msg)
      # this should pass it on to the logger
    end
  end
end