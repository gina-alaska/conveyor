require 'singleton'

# Does not persist, do not use any class variables 
class Watch
  include Singleton

  def match(glob, &block) 
    Match.new(glob, &block)
  end
  
  def extension(glob)
    Regexp.new("\.#{glob}$")
  end
  
  def method_missing(method, value = nil)
    return method.to_s
  end
  
  def say(msg, options={})
    Conveyor.instance.say(msg, options)
  end
end