require 'conveyor/output/console'
require 'conveyor/output/email'
require 'conveyor/output/logfile'

module Conveyor
  module Output
    MSGLVLS = {
      :debug    => 1, 
      :info     => 10, 
      :warning  => 20, 
      :error    => 30
    }

    def should_log?(lvl, maxlvl = nil)
      if maxlvl.nil? && @loglvl.nil?
        loglvl :debug
        should_log? lvl
      elsif maxlvl.nil?
        MSGLVLS[lvl.to_sym] >= @loglvl
      else
        MSGLVLS[lvl.to_sym] >= MSGLVLS[maxlvl.to_sym]
      end
    end

    def loglvl(lvl)
      @loglvl = MSGLVLS[lvl.to_sym] || MSGLVLS[:debug]
    end

    # Overrite this method to control logfile used
    def logfile
      nil
    end

    # Override this method to control name used
    def name
      nil
    end

    def say(*msg)
      output(:info, *msg)
    end

    def info(*msg)
      output(:info, *msg)
    end
    
    def warning(*msg)
      output(:warning, *msg)
    end
    
    def error(*msg)
      output(:error, *msg)
    end

    def debug(*msg)
      output(:debug, *msg)
    end
    
    def output(msgtype, *msg)
      Console.send(msgtype, *msg) if should_log?(msgtype)
      Logfile.write(logfile, name, msgtype, *msg) if !logfile.nil? && should_log?(msgtype)
      Email.send(msgtype, *msg) if should_log?(msgtype, :error)
    end
    
    def send_notifications
      Email.mail
    end

    def notify(*emails)
      Conveyor::Foreman.instance.notify_list << emails
    end
  end
end