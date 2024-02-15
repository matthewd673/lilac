# typed: true
require "sorbet-runtime"
require_relative "il"

class IL::Value
  sig { params(context: Interpreter::Context).returns(T.untyped) }
  def evaluate(context)
    if self.class == IL::Value
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::Constant
  def evaluate(context)
    return @value
  end
end

class IL::ID
  def evaluate(context)
    if not context.symbols.include?(@name)
      raise("Undefined ID #{@name}")
    end

    return context.symbols[@name].value
  end
end

class IL::Expression
  sig { params(context: Interpreter::Context).returns(T.untyped) }
  def evaluate(context)
    if self.class == IL::Expression
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::BinaryOp
  def evaluate(context)
    lval = @left.evaluate(context)
    rval = @right.evaluate(context)

    case @op
    when IL::BinaryOp::ADD_OP
      return lval + rval
    when IL::BinaryOp::SUB_OP
      return lval - rval
    when IL::BinaryOp::MUL_OP
      return lval * rval
    when IL::BinaryOp::DIV_OP
      return lval / rval
    else
      raise("Invalid binary operator '#{@op}'")
    end
  end
end

class IL::Statement
  sig { params(context: Interpreter::Context).void }
  def interpret(context)
    if self.class == IL::Statement
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::Declaration
  def interpret(context)
    # check for redeclaration
    if context.symbols.include?(@id.name)
      raise("Redeclaration of ID '#{@id.name}'")
    end
    # insert id in symbol table with appropriate type
    rhs_eval = @rhs.evaluate(context)
    context.symbols[@id.name] = Interpreter::SymbolInfo.new(@id.name,
                                                            @type,
                                                            rhs_eval)
  end
end

class IL::Assignment
  # TODO
end

module Interpreter
  include Kernel
  extend T::Sig

  class SymbolInfo
    extend T::Sig

    attr_reader :name
    attr_reader :type
    attr_accessor :value

    sig { params(name: String, type: String, value: T.untyped).void }
    def initialize(name, type, value)
      @name = name
      @type = type
      @value = value
    end
  end

  class Context
    extend T::Sig

    attr_accessor :symbols

    sig { void }
    def initialize
      @symbols = Hash.new
    end
  end

  sig { params(program: IL::Program).void }
  def self.interpret(program)
    context = Context.new

    # interpret each statement in the program
    program.each_stmt { |s|
      puts(s.to_s)
      s.interpret(context)
    }

    # TODO: temp sanity check
    puts("Symbol table state:")
    for k in context.symbols.keys
      puts("#{k} = #{context.symbols[k].value} (#{context.symbols[k].type})")
    end
  end
end
