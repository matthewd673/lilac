# typed: true
require "sorbet-runtime"

module Type
  I32 = "i32"
end

class Value
  # TODO: stub
end

class Constant < Value
  extend T::Sig

  attr_reader :type
  attr_reader :value

  sig { params(type: String, value: T.untyped).void }
  def initialize(type, value)
    @type = type
    @value = value
  end

  def to_s
    "#{@value}"
  end
end

class ID < Value
  extend T::Sig

  attr_reader :name

  sig {params(name: String).void}
  def initialize(name)
    @name = name
  end

  sig { returns(String) }
  def to_s
    "#{@name}"
  end
end

class Expression
  # TODO: stub
end

class BinaryOp < Expression
  extend T::Sig

  ADD_OP = "+"
  SUB_OP = "-"
  MUL_OP = "*"
  DIV_OP = "/"

  attr_reader :op
  attr_reader :left
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

class Statement
  # TODO: stub
end

class Declaration < Statement
  extend T::Sig

  attr_reader :type
  attr_reader :id
  attr_reader :rhs

  sig { params(type: String, id: ID, rhs: T.any(Expression, Value)).void }
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

  attr_reader :id
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

class Program
  extend T::Sig

  sig { void }
  def initialize
    @stmt_list = []
  end

  sig { params(stmt: Statement).void }
  def push_stmt(stmt)
    @stmt_list.push(stmt)
  end

  def each
    for stmt in @stmt_list
      yield(stmt)
    end
  end
end
