# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

class CodeGen::Generator
  extend T::Sig

  include CodeGen

  sig { params(transformer: ILTransformer, cfg_program: IL::CFGProgram).void }
  def initialize(transformer, cfg_program)
    @transformer = transformer
    @program = cfg_program
  end
end
