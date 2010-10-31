# MacRuby implementation of IRB.
#
# This file is covered by the Ruby license. See COPYING for more details.
# 
# Copyright (C) 2009-2010, Eloy Duran <eloy.de.enige@gmail.com>

module IRB
  class << self
    attr_accessor :formatter
  end
  
  class Formatter
    DEFAULT_PROMPT = "irb(%s):%03d:%d> "
    SIMPLE_PROMPT  = ">> "
    NO_PROMPT      = ""
    RESULT_PREFIX  = "=>"
    SYNTAX_ERROR   = "SyntaxError: compile error\n(irb):%d: %s"
    SOURCE_ROOT    = Regexp.new("^#{File.expand_path('../../../', __FILE__)}")
    
    attr_writer   :prompt
    attr_accessor :inspect
    attr_reader   :filter_from_backtrace
    
    def initialize
      @prompt  = :default
      @inspect = true
      @filter_from_backtrace = [SOURCE_ROOT]
    end

    def indentation(level)
      '  ' * level
    end
    
    def prompt(context, indent = false)
      prompt = case @prompt
      when :default then DEFAULT_PROMPT % [context.object.inspect, context.line, context.source.level]
      when :simple  then SIMPLE_PROMPT
      else
        NO_PROMPT
      end
      indent ? (prompt + indentation(context.source.level)) : prompt
    end
    
    def inspect_object(object)
      if @inspect
        result = object.respond_to?(:pretty_inspect) ? object.pretty_inspect : object.inspect
        result.strip!
        result
      else
        minimal_inspect_object(object)
      end
    end

    def minimal_inspect_object(object)
      address = object.__id__ * 2
      address += 0x100000000 if address < 0
      "#<#{object.class}:0x%x>" % address
    end

    def reindent_last_line_in_source(source)
      old_level = source.level
      yield
      new_line  = indentation(source.level < old_level ? source.level : old_level)
      new_line += source.buffer[-1].lstrip
      source.buffer[-1] = new_line
    end

    # Returns +true+ if adding the +line+ to the context’s source decreases the indentation level.
    def add_input_to_context(context, line)
      source = context.source
      level_before = source.level
      source << line
      if source.level < level_before
        source.buffer[-1] = indentation(context) + line
        true
      end
    end

    def reindent_last_input(context)
      line = context.source.buffer.last
      indentation(context, -1) + line
    end
    
    def result(object)
      "#{RESULT_PREFIX} #{inspect_object(object)}"
    end
    
    def syntax_error(line, message)
      SYNTAX_ERROR % [line, message]
    end
    
    def exception(exception)
      backtrace = $DEBUG ? exception.backtrace : filter_backtrace(exception.backtrace)
      "#{exception.class.name}: #{exception.message}\n\t#{backtrace.join("\n\t")}"
    end
    
    def filter_backtrace(backtrace)
      backtrace.reject do |line|
        @filter_from_backtrace.any? { |pattern| pattern.match(line) }
      end
    end
  end
end

IRB.formatter = IRB::Formatter.new
