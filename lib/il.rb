# typed: strict
require "sorbet-runtime"

# IL contains a set of classes representing the Lilac Intermediate Language.
module IL
  extend T::Sig

  # ILObject is a type-alias for any object in the IL that can be
  # "visited". For example, +IL::Value+ is in but +IL::Type+ is out.
  ILObject = T.type_alias { T.any(Value, Expression, Statement) }

  # A Type is an enum of all the possible primitive data types in the IL.
  class Type < T::Enum
    extend T::Sig

    enums do
      # An unsigned 8-bit integer
      U8 = new
      # A signed 16-bit integer
      I16 = new
      # A signed 32-bit integer
      I32 = new
      # A signed 64-bit integer
      I64 = new
      # A 32-bit floating point number
      F32 = new
      # A 64-bit floating point number
      F64 = new
    end

    sig { returns(String) }
    def to_s
      case self
      when U8 then "u8"
      when I16 then "i16"
      when I32 then "i32"
      when I64 then "i64"
      when F32 then "f32"
      when F64 then "f64"
      else
        T.absurd(self)
      end
    end
  end

  # A Value is anything that can correspond to a typed value in the IL
  # such as constants and variables.
  class Value
    extend T::Sig
    # stub
  end

  # A Constant is a constant value of a given type.
  class Constant < Value
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: Type, value: T.untyped).void }
    # Construct a new Constant.
    #
    # @param [Type] type The IL Type of the Constant.
    # @param value The value of the Constant. Not type-checked.
    def initialize(type, value)
      @type = type
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@value}"
    end
  end

  # An ID is the name of a variable. When implemented these will often store
  # a type and a value.
  class ID < Value
    extend T::Sig

    sig { returns(String) }
    # The name of the ID.
    attr_reader :name
    sig { returns(Integer) }
    # The number of the ID. Multiple definitions of the same ID name must
    # have unique numbers.
    attr_reader :number
    sig { returns(String) }
    # The key of the ID. Includes both name and number.
    attr_reader :key

    sig { params(name: String).void }
    # Construct a new ID.
    #
    # @param [String] name The name of the ID.
    def initialize(name)
      @name = name
      @number = T.let(0, Integer)

      @key = T.let(compute_key, String)
    end

    sig { params(value: Integer).void }
    def number=(value)
      @number = value
      compute_key # key must be recomputed whenever number changes
    end

    sig { returns(String) }
    def to_s
      @key
    end

    sig { params(other: ID).returns(T::Boolean) }
    # Returns true if two IDs are equal. IDs are considered equal if they
    # have the same name and same number (by construction this means the same
    # key).
    def eql?(other)
      return (name == other.name and number == other.number)
    end

    private

    sig { returns(String) }
    def compute_key
      "#{name}##{number}"
    end
  end

  # A Register is a type of ID used in the IL to keep track of temporary
  # values such as intermediate steps of computation. Registers are numbered,
  # not named (though as IDs they still have a name attribute).
  class Register < ID
    extend T::Sig

    sig { params(number: Integer).void }
    # Construct a new Register.
    #
    # @param [Integer] number The number of the Register.
    def initialize(number)
      @number = number
      @name = "%#{number}"
      @key = @name
    end
  end

  # An Expression is any in-built function in the IL such as common
  # arithmetic operations. Expressions cannot be nested.
  class Expression
    extend T::Sig

    sig { returns(T.untyped) }
    # Calculate the value of an Expression.
    #
    # @return [T.untyped] The value of the Expression, likely numeric.
    def calculate
      0
    end
  end

  # A BinaryOp is an Expression which computes a value from two operands.
  # The two operands must have the same type.
  class BinaryOp < Expression
    extend T::Sig

    # A +BinaryOp::Operator+ represents all of the possible operators that
    # can be used in a BinaryOp Expression.
    class Operator < T::Enum
      extend T::Sig

      enums do
        ADD = new("+")
        SUB = new("-")
        MUL = new("*")
        DIV = new("/")
        EQ  = new("==")
        NEQ = new("!=")
        LT  = new("<")
        GT  = new(">")
        LEQ = new("<=")
        GEQ = new(">=")
        OR  = new("||")
        AND = new("&&")
      end

      sig { returns(String) }
      def to_s
        self.serialize
      end
    end

    sig { returns(Operator) }
    attr_reader :op
    sig { returns(Value) }
    attr_accessor :left
    sig { returns(Value) }
    attr_accessor :right

    sig { params(op: Operator, left: Value, right: Value).void }
    # Construct a new BinaryOp.
    #
    # @param [Operator] op The binary operator.
    # @param [Value] left The left operand.
    # @param [Value] right The right operand.
    def initialize(op, left, right)
      @op = op
      @left = left
      @right = right
    end

    sig { returns(String) }
    def to_s
      "#{@left} #{@op} #{@right}"
    end

    sig { returns(T.untyped) }
    def calculate
      # calculations can only be performed on constants
      if not @left.is_a?(Constant) or not @right.is_a?(Constant)
        return nil
      end

      left = @left
      right = @right

      case @op
      when Operator::ADD
        left.value + right.value
      when Operator::SUB
        left.value - right.value
      when Operator::MUL
        left.value * right.value
      when Operator::DIV
        left.value / right.value
      when Operator::EQ
        if left.value == right.value then 1 else 0 end
      when Operator::NEQ
        if left.value != right.value then 1 else 0 end
      when Operator::LT
        if left.value < right.value then 1 else 0 end
      when Operator::GT
        if left.value > right.value then 1 else 0 end
      when Operator::LEQ
        if left.value <= right.value then 1 else 0 end
      when Operator::GEQ
        if left.value >= right.value then 1 else 0 end
      when Operator::OR
        if left.value != 0 || right.value != 0 then 1 else 0 end
      when Operator::AND
        if left.value != 0 && right.value != 0 then 1 else 0 end
      else T.absurd(self)
      end
    end
  end

  # A UnaryOp is an Expression which computes a value from one operand.
  class UnaryOp < Expression
    extend T::Sig

    # A +UnaryOp::Operator+ represents all of the possible operators that
    # can be used in a UnaryOp Expression.
    class Operator < T::Enum
      extend T::Sig

      enums do
        NEG = new("-")
      end

      sig { returns(String) }
      def to_s
        self.serialize
      end
    end

    sig { returns(Operator) }
    attr_reader :op
    sig { returns(Value) }
    attr_accessor :value

    sig { params(op: Operator, value: Value).void }
    # Construct a new UnaryOp.
    #
    # @param [Operator] op The unary operator.
    # @param [Value] value The value being operated on.
    def initialize(op, value)
      @op = op
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@op}#{@value}"
    end

    sig { returns(T.untyped) }
    def calculate
      # calculations can only be performed on constants
      if not @value.is_a?(Constant)
        return nil
      end

      value = @value

      case @op
      when Operator::NEG
        0 - value.value
      else T.absurd(self)
      end
    end
  end

  # A Phi function is an Expression that combines multiple possible SSA
  # values at a join node.
  class Phi < Expression
    sig { returns(T::Array[Value]) }
    attr_reader :values

    sig { params(values: T::Array[Value]).void }
    def initialize(values)
      @values = values
    end
  end

  # A Statement is a single instruction or "line of code" in the IL.
  class Statement
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :annotation
  end

  # A Definition is a Statement that defines an ID with a type and value.
  class Definition < Statement
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(ID) }
    attr_reader :id
    sig { returns(T.any(Expression, Value)) }
    attr_accessor :rhs

    sig { params(type: Type, id: ID, rhs: T.any(Expression, Value)).void }
    # Construct a new Definition.
    #
    # @param [Type] type The type of the ID.
    # @param [ID] id The ID.
    # @param [T.any(Expression, Value)] rhs The right hand side of
    # the assignment.
    def initialize(type, id, rhs)
      @type = type
      @id = id
      @rhs = rhs
    end

    sig { returns(String) }
    def to_s
      "#{@type} #{@id} = #{@rhs}"
    end
  end

  # A Label is a Statement that does nothing but can be jumped to by a Jump.
  class Label < Statement
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    # Construct a new Label.
    #
    # @param [String] name The name of the Label.
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      "#{@name}:"
    end
  end

  # A Jump is a Statement that will jump to the target Label unconditionally.
  class Jump < Statement
    extend T::Sig

    sig { returns(String) }
    attr_accessor :target

    sig { params(target: String).void }
    # Construct a new Jump.
    #
    # @param [String] target The name of the target Label of the Jump.
    def initialize(target)
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jmp #{@target}"
    end
  end

  # A JumpZero is a Jump that will jump to the target Label only when its
  # conditional value is equal to +0+.
  class JumpZero < Jump
    extend T::Sig

    sig { returns(Value) }
    attr_accessor :cond

    sig { params(cond: Value, target: String).void }
    # Construct a new JumpZero.
    #
    # @param [Value] cond The value of the JumpZero's condition.
    # @param [String] target The name of the target Label of the JumpZero.
    def initialize(cond, target)
      @cond = cond
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jz #{@cond} #{@target}"
    end
  end

  # A JumpNotZero is a Jump that will jump to the target Label only when its
  # conditional value is _not_ equal to +0+.
  class JumpNotZero < Jump
    extend T::Sig

    sig { returns(Value) }
    attr_accessor :cond

    sig { params(cond: Value, target: String).void }
    # Construct a new JumpNotZero.
    #
    # @param [Value] cond The value of the JumpNotZero's condition.
    # @param [String] target The name of the target Label of the JumpNotZero.
    def initialize(cond, target)
      @cond = cond
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jnz #{@cond} #{@target}"
    end
  end

  # A Return statement is used to return a value from within a FuncDef.
  class Return < Statement
    extend T::Sig

    sig { returns(Value) }
    attr_reader :value

    sig { params(value: Value).void }
    def initialize(value)
      @value = value
    end

    sig { returns(String) }
    def to_s
      "ret #{@value}"
    end
  end

  # A FuncParam defines a parameter accepted by a FuncDef.
  class FuncParam
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(ID) }
    attr_reader :id

    sig { params(type: Type, id: ID).void }
    def initialize(type, id)
      @type = type
      @id = id
    end

    sig { returns(String) }
    def to_s
      "#{@type} #{@id}"
    end
  end

  # A FuncDef is a function definition with a name, params, and body.
  class FuncDef
    extend T::Sig

    sig { returns(String) }
    attr_reader :name
    sig { returns(T::Array[FuncParam]) }
    attr_reader :params
    sig { returns(Type) }
    attr_reader :ret_type
    sig { returns(T::Array[Statement]) }
    attr_reader :stmt_list

    sig { params(name: String,
                 params: T::Array[FuncParam],
                 ret_type: Type,
                 stmt_list: T::Array[Statement])
          .void }
    def initialize(name, params, ret_type, stmt_list)
      @name = name
      @params = params
      @ret_type = ret_type
      @stmt_list = stmt_list
    end

    sig { returns(String) }
    def to_s
      param_str = ""
      @params.each { |p|
        param_str += "#{p}, "
      }
      param_str.chomp!(", ")

      stmt_str = ""
      @stmt_list.each { |s|
        stmt_str += "#{s}\n"
      }

      return "func #{@name}(#{param_str}) -> #{@ret_type}:\n#{stmt_str}\nend"
    end
  end

  # A Call is an Expression that represents a function call.
  class Call < Expression
    extend T::Sig

    sig { returns(String) }
    attr_reader :func_name
    sig { returns(T::Array[Value]) }
    attr_reader :args

    sig { params(func_name: String, args: T::Array[Value]).void }
    def initialize(func_name, args)
      @func_name = func_name
      @args = args
    end

    sig { returns(String) }
    def to_s
      arg_str = ""
      @args.each { |a|
        arg_str += "#{a}, "
      }
      arg_str.chomp!(", ")

      return "call #{@func_name}(#{arg_str})"
    end
  end

  # A Program is a list of Statements.
  class Program
    extend T::Sig

    sig { returns(T::Array[Statement]) }
    attr_reader :stmt_list

    sig { void }
    # Construct a new Program.
    def initialize
      @stmt_list = T.let([], T::Array[Statement])
      @func_map = T.let({}, T::Hash[String, FuncDef])
    end

    sig { returns(Integer) }
    def length
      @stmt_list.length
    end

    sig { params(funcdef: FuncDef).void }
    def register_func(funcdef)
      @func_map[funcdef.name] = funcdef
    end

    sig { params(block: T.proc.params(arg0: FuncDef).void).void }
    def each_func(&block)
      @func_map.keys.each { |k|
        yield T.unsafe(@func_map[k])
      }
    end

    sig { params(name: String).returns(T.nilable(FuncDef)) }
    def get_func(name)
      @func_map[name]
    end

    sig { returns(String) }
    def to_s
      str = ""
      @stmt_list.each { |i|
        str += i.to_s + "\n"
      }
      return str
    end
  end
end
