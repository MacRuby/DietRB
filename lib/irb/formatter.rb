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
    INDENTATION    = "  "
    SYNTAX_ERROR   = "SyntaxError: compile error\n(irb):%d: %s"
    SOURCE_ROOT    = Regexp.new("^#{File.expand_path('../../../', __FILE__)}")
    
    attr_writer   :prompt
    attr_accessor :inspect
    attr_accessor :auto_indent
    attr_reader   :filter_from_backtrace
    
    def initialize
      @prompt      = :default
      @inspect     = true
      @auto_indent = false
      @filter_from_backtrace = [SOURCE_ROOT]
    end

    def indentation(level)
      INDENTATION * level
    end
    
    def prompt(context, ignore_auto_indent = false)
      prompt = case @prompt
      when :default then DEFAULT_PROMPT % [context.object.inspect, context.line, context.level]
      when :simple  then SIMPLE_PROMPT
      else
        NO_PROMPT
      end
      @auto_indent && !ignore_auto_indent ? (prompt + indentation(context.level)) : prompt
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
      unless @auto_indent
        yield
        nil
      else
        old_level = source.level
        yield
        line      = source.buffer[-1]
        new_line  = indentation(source.level < old_level ? source.level : old_level)
        new_line += line.lstrip
        source.buffer[-1] = new_line unless new_line == line
      end
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
