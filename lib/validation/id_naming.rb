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

  sig { void }
  def initialize
    @id = "id_naming"
    @description = "Ensure that ID names do not include reserved characters"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    program.item_list.each { |i|
      ids = get_ids(i)
      ids.each { |id|
        # don't check registers since they don't have user-provided names
        # (and necessarily contain a reserved character in their "name")
        if id.is_a?(IL::Register) then next end

        # check for reserved characters (% and #)
        if id.name.include?("%") or id.name.include?("#")
          raise("Reserved character used in ID name '#{id.name}'")
        end
      }
    }
  end

  private

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
    # TODO: support functions
    end

    return []
  end
end
