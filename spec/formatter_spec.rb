require File.expand_path('../spec_helper', __FILE__)

main = self

describe "IRB::Formatter" do
  before do
    @formatter = IRB::Formatter.new
    @context = IRB::Context.new(main)
  end
  
  it "returns a prompt string, displaying line number and code indentation level" do
    @formatter.prompt(@context).should == "irb(main):001:0> "
    @context.instance_variable_set(:@line, 23)
    @formatter.prompt(@context).should == "irb(main):023:0> "
    @context.source << "def foo"
    @formatter.prompt(@context).should == "irb(main):023:1> "
  end
  
  it "describes the context's object in the prompt" do
    o = Object.new
    @formatter.prompt(IRB::Context.new(o)).should == "irb(#{o.inspect}):001:0> "
  end
  
  it "returns a very simple prompt if specified" do
    @formatter.prompt = :simple
    @formatter.prompt(@context).should == ">> "
  end
  
  it "returns no prompt if specified" do
    @formatter.prompt = nil
    @formatter.prompt(@context).should == ""
  end
  
  it "returns a formatted exception message, with the lines, regarding dietrb, filtered out of the backtrace" do
    begin; @context.__evaluate__('DoesNotExist'); rescue NameError => e; exception = e; end
    backtrace = exception.backtrace.reject { |f| f =~ /#{ROOT}/ }
    @formatter.exception(exception).should ==
      "NameError: uninitialized constant IRB::Context::DoesNotExist\n\t#{backtrace.join("\n\t")}"
  end
  
  it "does not filter the backtrace if $DEBUG is true" do
    begin
      stderr, $stderr = $stderr, OutputStub.new
      debug, $DEBUG = $DEBUG, true
      
      begin; @context.__evaluate__('DoesNotExist'); rescue NameError => e; exception = e; end
      @formatter.exception(exception).should ==
        "NameError: uninitialized constant IRB::Context::DoesNotExist\n\t#{exception.backtrace.join("\n\t")}"
    ensure
      $stderr = stderr
      $DEBUG = debug
    end
  end
  
  it "prints the result" do
    @formatter.result(:foo => :foo).should == "=> {:foo=>:foo}"
  end
  
  it "prints the result with object#pretty_inspect, if it responds to it" do
    object = Object.new
    def object.pretty_inspect; "foo"; end
    @formatter.result(object).should == "=> foo"
  end
  
  it "prints only the class name and memory address in `no inspect' mode" do
    @formatter.inspect = false
    
    object = Object.new
    def object.inspect; @inspected = true; "Never called!"; end
    def object.__id__; 2158110700; end
    
    @formatter.result(object).should == "=> #<#{object.class.name}:0x101444fd8>"
    object.instance_variable_get(:@inspected).should_not == true
  end
  
  it "prints that a syntax error occurred on the last line and reset the buffer to the previous line" do
    @formatter.syntax_error(2, "syntax error, unexpected '}'").should ==
      "SyntaxError: compile error\n(irb):2: syntax error, unexpected '}'"
  end

  it "pads the prompt, with indentation whitespace based on the source level, if requested" do
    @formatter.prompt(@context, true).should == "irb(main):001:0> "

    @context.process_line("class A")
    @formatter.prompt(@context, true).should == "irb(main):002:1>   "
    @formatter.prompt(@context).should       == "irb(main):002:1> "

    @context.process_line("def foo")
    @formatter.prompt(@context, true).should == "irb(main):003:2>     "
    @formatter.prompt(@context).should       == "irb(main):003:2> "
  end

  it "reindents the last line in a Source#buffer after execution of the block, and returns the new line" do
    source = @context.source
    lines = [
      ["\tclass A", "class A"],
      ["def foo",   "  def foo"],
      ["    end",   "  end"],
      ["    end",   "end"]
    ]
    lines.each do |line, expected_new_line|
      @formatter.reindent_last_line_in_source(source) { source << line }.should == expected_new_line
    end
    source.to_s.should == lines.map(&:last).join("\n")
  end
end
