# typed: true
require "sorbet-runtime"

class Value
  # TODO: stub
end

class Constant < Value
  # TODO: stub
end

class ID < Value
  extend T::Sig

  attr_reader :name

  sig {params(name: String).void}
  def initialize(name)
    @name = name
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
end
