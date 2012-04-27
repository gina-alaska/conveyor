module Conveyor
  module Output
    class Logfile
      class << self
        def write(logfile, name, msgtype, *msg)
          return false if logfile.nil?
          
          options = msg.extract_options!

          format = '[%s] [%s::%s] %s'

          if msg.class == Array
            msg.each do |m|
              output logfile, 
                      sprintf(format, Time.now, name, msgtype, m)
            end
          else
            output logfile, 
                      sprintf(format, Time.now, name, msgtype, msg)
          end
        end

        def output(logfile, msg = nil, &block)
          FileUtils.mkdir_p(File.dirname(logfile))
          fp = File.open(logfile, 'a')

          if block_given?
            yield fp
          elsif !msg.nil?
            fp << msg + "\n"
          end

          fp.close
        end
      end
    end
  end
end