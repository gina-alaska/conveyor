class BasicBelt
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  attr_accessor :attributes

  def initialize(p = {})
    self.include_root_in_json = false
    @attributes = p.stringify_keys!
  end

  def read_attribute_for_serialization(key)
    self.send(key)
  end

  def read_attribute_for_validation(key)
    self.send(key)
  end

  def read_attribute(key)
    attributes[key.to_s]
  end

  def write_attribute(key, value)
    attributes[key.to_s] = value
  end

  def update_attributes(attrs)
    attrs.each do |k,v|
      self.send("#{k}=", v)
    end
  end

  def to_conf
    self.class.to_conf(attributes["name"])
  end

  def save
    
    File.open(to_conf, 'w') do |fp|
      fp << attributes.to_yaml
    end
  end

  class << self
    def config_root=(path)
      @config_root = path
    end

    def config_root
      @config_root || ''
    end

    def all(glob = '*.yml')
      items = []
      Dir.glob(File.join(config_root, glob)) do |f|
        items << load(f)
      end
      items
    end

    def where(name)
      load(to_conf(name)) 
    end

    def load(filename)
      if File.exists? filename
        new(YAML.load_file(filename)) 
      else
        raise "File not found #{filename}"
      end
    end

    def to_conf(name)
      File.join(config_root, "#{name.underscore}.yml")
    end

    def define_fields(*fields)
      fields.each do |f|
        define_method f do           # def name
          read_attribute(f)          #   read_attribute(:name)
        end                          # end

        define_method "#{f}=" do |v| # def name=(v)
          write_attribute(f,v)       #   write_attribute(:name, v)
        end                          # end
      end
    end
  end
end

class Belt < BasicBelt
  define_fields :name, :from, :to, :type
  validates_presence_of :name

  def from=(value)
    write_attribute(:from, fspath(value))
  end

  def to=(value)
    write_attribute(:to, fspath(value))
  end

  protected

  def fspath(value)
    File.exists?(value) ? File.expand_path(value) : value
  end
end
