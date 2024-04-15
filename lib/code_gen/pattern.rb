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

  # A wildcard for an +IL::UnaryOp+ with any operator.
  class UnaryOpWildcard < IL::Expression
    sig { returns(IL::Value) }
    attr_reader :value

    sig { params(value: IL::Value).void }
    def initialize(value)
      @value = value
    end
  end

  # A wildcard for any +IL::Call+.
  class CallWildcard < IL::Expression
    # NOTE: stub
  end

  # A wildcard for any +IL::Value+.
  class ValueWildcard < IL::Value
    sig { void }
    def initialize
    end
  end

  # A wildcard for any +IL::ID+.
  class IDWildcard < IL::ID
    sig { void }
    def initialize
    end
  end

  # A wildcard for an +IL::Constant+ of any type and with any value.
  class ConstantWildcard < IL::Constant
    sig { void }
    def initialize
    end
  end

  # A wildcard for any +IL::Constant+ with an integer type.
  class IntegerConstantWildcard < IL::Constant
    sig { params(value: T.untyped).void }
    def initialize(value)
      @value = value
    end
  end

  # A wildcard for any +IL::Constant+ with a signed integer type.
  class SignedConstantWildcard < IL::Constant
    sig { params(value: T.untyped).void }
    def initialize(value)
      @value = value
    end
  end

  # A wildcard for any +IL::Constant+ with an unsigned integer type.
  class UnsignedConstantWildcard < IL::Constant
    sig { params(value: T.untyped).void }
    def initialize(value)
      @value = value
    end
  end

  # A wildcard for any +IL::Constant+ with a floating point type (+F32+,
  # +F64+).
  class FloatConstantWildcard < IL::Constant
    sig { params(value: T.untyped).void }
    def initialize(value)
      @value = value
    end
  end

  # A wildcard for the numeric value stored in an +IL::Constant+.
  class ConstantValueWildcard
    # NOTE: stub
  end
end
