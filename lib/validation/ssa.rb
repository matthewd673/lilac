# typed: strict
require "sorbet-runtime"
require "set"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"

include Validation

# The SSA validation ensures that the program is in valid SSA form.
class Validation::SSA < ValidationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = "ssa"
    @description = "Ensure the program is in valid SSA form"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    key_set = Set[]

    program.each_stmt { |s|
      # only definitions are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      # NOTE: unsafe to workaroudn Sorbet expecting T.noreturn (???)
      if T.unsafe(key_set).include?(s.id.key)
        raise("Multiple definitions of ID '#{s.id.key}'")
      end

      T.unsafe(key_set).add(s.id.key)
    }
  end
end
