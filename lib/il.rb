# typed: strict
require "sorbet-runtime"

# IL contains a set of classes representing the Lilac Intermediate Language.
module IL
  extend T::Sig

  # ILObject is a Sorbet type alias for any object in the IL that can be
  # "visited". For example, +IL::Value+ is in but +IL::Type+ is out.
  ILObject = T.type_alias { T.any(Value, Expression, Statement) }

  # A Type is an enum of all the possible primitive data types in the IL.
  class Type < T::Enum
    extend T::Sig

    enums do
      # A signed 32-bit integer
      I32 = new
    end

    sig { returns(String) }
    def to_s
      case self
      when I32 then "i32"
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
    attr_reader :name

    sig { params(name: String).void }
    # Construct a new ID.
    #
    # @param [String] name The name of the ID.
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      "#{@name}"
    end
  end

  # A Register is a type of ID used in the IL to keep track of temporary
  # values such as intermediate steps of computation. Registers are numbered,
  # not named (though as IDs they still have a name attribute).
  class Register < ID
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :number

    sig { params(number: Integer).void }
    # Construct a new Register.
    #
    # @param [Integer] number The number of the Register.
    def initialize(number)
      @number = number
      @name = "%#{number}"
    end
  end

  # An Expression is any in-built function in the IL such as common
  # arithmetic operations. Expressions cannot be nested.
  class Expression
    extend T::Sig
    # stub
  end

  # A BinaryOp is an Expression which computes a value from two operands.
  # The two operands must have the same type.
  class BinaryOp < Expression
    extend T::Sig

    # Addition
    ADD_OP = "+"
    # Subtraction
    SUB_OP = "-"
    # Multiplication
    MUL_OP = "*"
    # Division
    DIV_OP = "/"
    # Boolean equality
    EQ_OP  = "=="
    # Boolean less than
    LT_OP  = "<"
    # Boolean greater than
    GT_OP  = ">"
    # Boolean less than equal to
    LEQ_OP = "<="
    # Boolean greater than equal to
    GEQ_OP = ">="
    # Boolean or
    OR_OP  = "||"
    # Boolean and
    AND_OP = "&&"

    sig { returns(String) }
    attr_reader :op
    sig { returns(Value) }
    attr_reader :left
    sig { returns(Value) }
    attr_reader :right

    sig { params(op: String, left: Value, right: Value).void }
    # Construct a new BinaryOp.
    #
    # @param [String] op The binary operator. Must be one of the valid
    # constant operator values.
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
  end

  # A UnaryOp is an Expression which computes a value from one operand.
  class UnaryOp < Expression
    extend T::Sig

    # Unary negation
    NEG_OP = "-"
    # Does nothing
    POS_OP = "+"

    sig { returns(String) }
    attr_reader :op
    sig { returns(Value) }
    attr_reader :value

    sig { params(op: String, value: Value).void }
    # Construct a new UnaryOp.
    #
    # @param [String] op The unary operator. Must be one of the valid
    # constant operator values.
    # @param [Value] value The value being operated on.
    def initialize(op, value)
      @op = op
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@op}#{@value}"
    end
  end

  # A Statement is a single instruction or "line of code" in the IL.
  class Statement
    extend T::Sig
    # stub
  end

  # A Declaration is a Statement that declares a new ID with a type and value.
  class Declaration < Statement
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(ID) }
    attr_reader :id
    sig { returns(T.any(Expression, Value)) }
    attr_reader :rhs

    sig { params(type: Type, id: ID, rhs: T.any(Expression, Value)).void }
    # Construct a new Declaration.
    #
    # @param [Type] type The type of the new ID.
    # @param [ID] id The new ID.
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

  # An Assignment is a Statement that assigns a new value to an existing ID.
  class Assignment < Statement
    extend T::Sig

    sig { returns(ID) }
    attr_reader :id
    sig { returns(T.any(Expression, Value)) }
    attr_reader :rhs

    sig { params(id: ID, rhs: T.any(Expression, Value)).void }
    # Construct a new Assignment.
    #
    # @param [ID] id The ID to assign to.
    # @param [T.any(Expression, Value)] rhs The right hand side of
    # the assignment.
    def initialize(id, rhs)
      @id = id
      @rhs = rhs
    end

    sig { returns(String) }
    def to_s
      "#{@id} = #{@rhs}"
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
    attr_reader :cond

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
    attr_reader :cond

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

  # A Program is a list of Statements.
  class Program
    extend T::Sig

    sig { void }
    # Construct a new Program.
    def initialize
      @stmt_list = T.let([], T::Array[Statement])
    end

    sig { params(stmt_list: T::Array[Statement]).void }
    def concat_stmt_list(stmt_list)
      @stmt_list.concat(stmt_list)
    end

    sig { params(stmt: Statement).void }
    def push_stmt(stmt)
      @stmt_list.push(stmt)
    end

    sig { returns(Integer) }
    def length
      @stmt_list.length
    end

    sig { params(
            block: T.proc.params(arg0: Statement).returns(T.untyped)
          )
          .void
    }
    def each_stmt(&block)
      @stmt_list.each(&block)
    end

    sig { params(
            block: T.proc.params(arg0: Statement, arg1: Integer)
              .returns(T.untyped)
            )
            .void
    }
    def each_stmt_with_index(&block)
      @stmt_list.each_with_index(&block)
    end

    sig { returns(String) }
    def to_s
      str = ""
      each_stmt { |s|
        str += s.to_s + "\n"
      }
      return str
    end
  end
end
