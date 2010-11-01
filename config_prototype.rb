class Config
  class Entry
    attr_accessor :klass, :name, :options

    def initialize(klass, name)
      @klass, @name = klass, name
      @options = {}
    end

    def add_option(name, default, description)
      name = name.to_s
      @options[name] = [default, description]
      klass.class_eval(%{
        attr_writer :#{name}
        def #{name}
          @#{name}.nil? ? Config.current.#{@name}.#{name} : @#{name}
        end
      })
    end

    def to_s
      @options.keys.sort.map do |name|
        "config.#{@name}.#{name} = #{@options[name][0]} # #{@options[name][1]}"
      end.join("\n")
    end

    def method_missing(name, *args)
      name = name.to_s
      if name[-1,1] == '=' && option = @options[name[0..-1]]
        option[0] = args[0]
      elsif option = @options[name]
        option[0]
      else
        super
      end
    end
  end

  def self.current
    @current ||= new
  end

  attr_accessor :entries

  def initialize
    @entries = {}
  end

  def add_entry(klass, name)
    name = name.to_s
    entry = Entry.new(klass, name)
    yield entry
    @entries[name] = entry
  end

  def to_s
    @entries.keys.sort.map do |name|
      @entries[name].to_s
    end.join("\n")
  end

  def method_missing(entry)
    @entries[entry.to_s] || super
  end
end

module Kernel
  def config
    Config.current
  end
end

class Formatter
  Config.current.add_entry(self, :formatter) do |entry|
    entry.add_option(:use_inspect, true, "Call inspect on the object")
    entry.add_option(:auto_indent, true, "Automatically indent code")
  end
end

puts config

f = Formatter.new
p f.use_inspect
f.use_inspect = false
p f.use_inspect
p f.auto_indent
