# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

module CodeGen
  class Translator
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
end
