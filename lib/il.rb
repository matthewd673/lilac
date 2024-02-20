# typed: strict
require "sorbet-runtime"

module IL
  class Type < T::Enum
    extend T::Sig

    enums do
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

  class Value
    extend T::Sig
    # stub
  end

  class Constant < Value
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: Type, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@value}"
    end
  end

  class ID < Value
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      "#{@name}"
    end
  end

  class Register < ID
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :number

    sig { params(number: Integer).void }
    def initialize(number)
      @number = number
      @name = "%#{number}"
    end
  end

  class Expression
    extend T::Sig
    # stub
  end

  class BinaryOp < Expression
    extend T::Sig

    ADD_OP = "+"
    SUB_OP = "-"
    MUL_OP = "*"
    DIV_OP = "/"
    EQ_OP  = "=="
    LT_OP  = "<"
    GT_OP  = ">"
    LEQ_OP = "<="
    GEQ_OP = ">="
    OR_OP  = "||"
    AND_OP = "&&"

    sig { returns(String) }
    attr_reader :op
    sig { returns(Value) }
    attr_reader :left
    sig { returns(Value) }
    attr_reader :right

    sig { params(op: String, left: Value, right: Value).void }
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

  class UnaryOp < Expression
    extend T::Sig

    NEG_OP = "-"
    POS_OP = "+"

    sig { returns(String) }
    attr_reader :op
    sig { returns(Value) }
    attr_reader :value

    sig { params(op: String, value: Value).void }
    def initialize(op, value)
      @op = op
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@op}#{@value}"
    end
  end

  class Statement
    extend T::Sig
    # stub
  end

  class Declaration < Statement
    extend T::Sig

    sig { returns(Type) }
    attr_reader :type
    sig { returns(ID) }
    attr_reader :id
    sig { returns(T.any(Expression, Value)) }
    attr_reader :rhs

    sig { params(type: Type, id: ID, rhs: T.any(Expression, Value)).void }
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

  class Assignment < Statement
    extend T::Sig

    sig { returns(ID) }
    attr_reader :id
    sig { returns(T.any(Expression, Value)) }
    attr_reader :rhs

    sig { params(id: ID, rhs: T.any(Expression, Value)).void }
    def initialize(id, rhs)
      @id = id
      @rhs = rhs
    end

    sig { returns(String) }
    def to_s
      "#{@id} = #{@rhs}"
    end
  end

  class Label < Statement
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      "#{@name}:"
    end
  end

  class Jump < Statement
    extend T::Sig

    sig { returns(String) }
    attr_reader :target

    sig { params(target: String).void }
    def initialize(target)
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jmp #{@target}"
    end
  end

  class JumpZero < Jump
    extend T::Sig

    sig { returns(Value) }
    attr_reader :cond

    sig { params(cond: Value, target: String).void }
    def initialize(cond, target)
      @cond = cond
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jz #{@cond} #{@target}"
    end
  end

  class JumpNotZero < Jump
    extend T::Sig

    sig { returns(Value) }
    attr_reader :cond

    sig { params(cond: Value, target: String).void }
    def initialize(cond, target)
      @cond = cond
      @target = target
    end

    sig { returns(String) }
    def to_s
      "jnz #{@cond} #{@target}"
    end
  end

  class Program
    extend T::Sig

    sig { void }
    def initialize
      @stmt_list = T.let([], T::Array[Statement])
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
