# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

class CodeGen::Translator
  extend T::Sig
  extend T::Helpers

  abstract!

  include CodeGen

  sig { params(transformer: ILTransformer, cfg_program: IL::CFGProgram).void }
  def initialize(transformer, cfg_program)
    @transformer = transformer
    @program = cfg_program
  end

  sig { abstract.returns(Component) }
  def translate; end
end
