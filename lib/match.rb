class Match
  attr_accessor :filename

  def initialize(glob, &block)
    @glob = escape_glob(glob)
    @block = block
  end

  # Causes a reload of the worker scripts
  def reload!
    say "RELOADING!"
    Conveyor.instance.reload!
  end
  
  # Forward on the msg to the Conveyor
  def say(msg)
    Conveyor.instance.say(msg)
  end
  
  # TODO wrap this in some sort of popen3 call 
  def run(cmd)
    say `#{cmd}`
  end

  def start(path, file)
    @filename = File.join(path, file)
    
    if @glob =~ filename
      @source = filename
      instance_exec(filename, &@block) 
    end
  end

  def like(name)
    dir = File.dirname(name)
    @source = Dir.glob(File.join(dir, File.basename(name, '.*') + '.*'))
  end

  def copy(*args)
    if(args.count == 1) 
      @destination = args.first
    elsif args.count > 1
      @destination = args.pop
      @source = args.flatten
    end

    if @source && @destination
      say "Copying #{@source.inspect} to #{@destination}"
      FileUtils.mkdir_p(@destination)
      FileUtils.cp_r(@source, @destination)
    end
  end

  def source(name=[])
    @source = name
    @destination
  end
  alias_method :from, :source

  def destination(name)
    raise "Could not find #{name}" unless File.exists?(name)
    @destination = name
  end
  alias_method :to, :destination

  def filename(args = nil)
    @filename
  end
  
  protected
  
  def escape_glob(glob)
    if glob.class == String 
      Regexp.new(Regexp.escape(glob))
    else 
      glob
    end
  end  
end