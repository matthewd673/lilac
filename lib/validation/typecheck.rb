# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"

include Validation

# The type-check validation ensures that there are no definitions or
# expressions with mismatched types in the program.
class Validation::TypeCheck < ValidationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = "typecheck"
    @description = "Detect type mismatch errors"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    symbols = {} # id -> type

    program.each_stmt { |s|
      # only declarations and assignments are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      # register id in symbol table every time (since this is SSA)
      symbols[s.id.key] = s.type

      # find the type of the rhs
      if s.rhs.is_a?(IL::Constant)
        rhs_type = T.cast(s.rhs, IL::Constant).type
      elsif s.rhs.is_a?(IL::ID)
        rhs_type = symbols[T.cast(s.rhs, IL::ID).key]
      elsif s.rhs.is_a?(IL::Expression)
        rhs_type = get_expr_type(T.cast(s.rhs, IL::Expression), symbols)
      end

      # check for a mismatch
      if not rhs_type
        raise("Type mismatch in expression: '#{s.rhs}'")
      end

      if symbols[s.id.key] != rhs_type
        raise("Type mismatch in statement: '#{s}'")
      end
    }
  end

  private

  sig { params(expr: IL::Expression,
               symbols: T::Hash[String, IL::Type])
        .returns(T.nilable(IL::Type)) }
  def get_expr_type(expr, symbols)
    if expr.is_a?(IL::BinaryOp)
      # get type of left
      if expr.left.is_a?(IL::Constant)
        lconst = T.cast(expr.left, IL::Constant)
        ltype = lconst.type
      elsif expr.left.is_a?(IL::ID)
        lid = T.cast(expr.left, IL::ID)
        ltype = symbols[lid.key]
      else
        raise("Unsupported left value class: #{expr.left.class}")
      end

      # get type of right
      if expr.right.is_a?(IL::Constant)
        rconst = T.cast(expr.right, IL::Constant)
        rtype = rconst.type
      elsif expr.right.is_a?(IL::ID)
        rid = T.cast(expr.right, IL::ID)
        rtype = symbols[rid.key]
      else
        raise("Unsupported right value class: #{expr.right.class}")
      end

      # return if they match, otherwise nil
      if ltype == rtype then return ltype end
      return nil
    elsif expr.is_a?(IL::UnaryOp)
      # get type of value
      if expr.value.is_a?(IL::Constant)
        vconst = T.cast(expr.value, IL::Constant)
        vtype = vconst.type
      elsif expr.value.is_a?(IL::ID)
        vid = T.cast(expr.value, IL::ID)
        vtype = symbols[vid.key]
      else
        raise("Unsupported value class: #{expr.value.class}")
      end

      return vtype # no need to check for mismatch
    end

    raise("Unsupported expression class: #{expr.class}")
  end
end
