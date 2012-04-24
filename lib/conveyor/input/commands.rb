module Conveyor
	module Input
		class Commands
			class << self
				def stop(*opts)
					Kernel.exit
				end
				alias_method :exit, :stop

				def listeners(*opts)
					puts "Watching: "
					puts "\t" + Conveyor::Foreman.instance.workers.keys.join("\n\t")
				end

				def unknown(cmd = nil)
					puts "Unknown command #{cmd}"
				end
			end
		end
	end
end