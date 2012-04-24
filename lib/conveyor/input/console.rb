module Conveyor
	module Input
		class Console
	    include Singleton

	    def initialize
	    end

			def listen
				save_tty_settings
	      while line = Readline.readline('> ', true)
	        handle line
	      end
	    rescue Interrupt => e	
	    	restore_tty_settings
	    	exit
	 		end

			def handle(line)
				cmd = line.split(/\s+/)
        return if cmd.empty?

				if Commands.respond_to? cmd.first
					Commands.send(cmd.shift, cmd.join(' '))
				else
					Commands.unknown(*cmd)
				end
			end

			def save_tty_settings
	      @stty_save = `stty -g`.chomp
			end

			def restore_tty_settings
				system('stty', @stty_save);
			end
		end
	end
end
