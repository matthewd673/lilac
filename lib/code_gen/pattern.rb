# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

module CodeGen::Pattern
  extend T::Sig

  # A wildcard for any +IL::Statement+.
  class StatementWildcard < IL::Statement
    # NOTE: stub
  end

  # A wildcard for an +IL::Definition+ with any type and any ID on the
  # left-hand side.
  class DefinitionWildcard < IL::Statement
    sig { returns(IL::Expression) }
    attr_reader :rhs

    sig { params(rhs: IL::Expression).void }
    def initialize(rhs)
      @rhs = rhs
    end
  end

  # A wildcard for any +IL::Expression+ and any +IL::Value+.
  # NOTE: while this class inherits from +IL::Expression+ the internal
  # matching implementation will also accept an  +IL::Value+ as a valid match.
  class RhsWildcard < IL::Expression
    # TODO: stub
  end

  # A wildcard for any +IL::Expression+.
  class ExpressionWildcard < IL::Expression
    # NOTE: stub
  end

  # A wildcard for an +IL::BinaryOp+ object with any operator.
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
    sig { void }
    def initialize
    end
  end
end
