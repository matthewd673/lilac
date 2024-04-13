# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

module CodeGen::Pattern
  extend T::Sig

  class StatementWildcard < IL::Statement
    # NOTE: stub
  end

  class ExpressionWildcard < IL::Expression
    # NOTE: stub
  end

  class BinaryOpWildcard < IL::Expression
    sig { returns(IL::Value) }
    attr_reader :left
    sig { returns(IL::Value) }
    attr_reader :right

    sig { params(left: IL::Value, right: IL::Value).void }
    def initialize(left, right)
      @left = left
      @right = right
    end
  end

  class UnaryOpWildcard < IL::Expression
    sig { returns(IL::Value) }
    attr_reader :value

    sig { params(value: IL::Value).void }
    def initialize(value)
      @value = value
    end
  end

  class ValueWildcard < IL::Value
    # NOTE: stub
  end

  class IDWildcard < IL::ID
    # NOTE: stub
  end

  class ConstantWildcard < IL::Constant
    # NOTE: stub
  end
end
