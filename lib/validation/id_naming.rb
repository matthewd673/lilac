# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"

include Validation

# The ID Naming validation ensures that ID names do not include
# reserved characters. It is very possible for ID names with reserved
# characters to compile fine, but it is introduces unnecessary
# ambiguity.
class Validation::IDNaming < ValidationPass
  extend T::Sig

  sig { override.returns(String) }
  def id
    "id_naming"
  end

  sig { override.returns(String) }
  def description
    "Ensure that ID names do not include reserved characters"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    # scan all funcs
    program.each_func { |f|
      # scan params
      f.params.each { |p|
        # skip registers, which are named automatically
        if p.id.is_a?(IL::Register) then next end

        if not valid?(p.id.name)
          raise("Reserved character in ID name '#{p.id.name}'")
        end
      }

      # check function name
      # (this won't check Calls but you must def a func to call it so...)
      if not valid?(f.name)
        raise("Reserved character in FuncDef name '#{f.name}'")
      end

      # scan contents of function
      scan_items(f.stmt_list)
    }

    # scan program
    scan_items(program.stmt_list)
  end

  private

  sig { params(stmt_list: T::Array[IL::Statement]).void }
  def scan_items(stmt_list)
    stmt_list.each { |s|
      # only defs are relevant
      # (every id must be defined, another validation will check that)
      if not s.is_a?(IL::Definition)
        next
      end

      # skip registers
      if s.id.is_a?(IL::Register)
        next
      end

      if not valid?(s.id.name)
        raise("Reserved character in ID name '#{s.id.name}'")
      end
    }
  end

  sig { params(name: String).returns(T::Boolean) }
  def valid?(name)
    not (name.length == 0 or name.include?("%") or name.include?("#"))
  end

  sig { params(node: T.any(IL::FuncDef,
                           IL::Statement,
                           IL::Expression,
                           IL::Value))
          .returns(T::Array[IL::ID]) }
  def get_ids(node)
    case node
    when IL::Definition
      return [node.id].concat(get_ids(node.rhs))
    when IL::JumpZero
      return get_ids(node.cond)
    when IL::JumpNotZero
      return get_ids(node.cond)
    when IL::BinaryOp
      return get_ids(node.left).concat(get_ids(node.right))
    when IL::UnaryOp
      return get_ids(node.value)
    when IL::ID
      return [node]
    end

    return []
  end
end
