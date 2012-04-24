require 'conveyor/input/commands'
require 'conveyor/input/console'

module Conveyor
	module Input
		class << self
			def listen
				Conveyor::Input::Console.instance.listen
			end
		end
	end
end