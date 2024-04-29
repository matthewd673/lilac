# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "instruction"

class CodeGen::Generator
  extend T::Sig
  extend T::Helpers

  abstract!

  include CodeGen

  sig { params(root_component: Component).void }
  def initialize(root_component)
    @root_component = root_component
  end

  sig { abstract.returns(String) }
  def generate; end
end
