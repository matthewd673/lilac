# typed: strict
require_relative "sorbet-runtime"
require_relative "../../code_gen"
require_relative "../../instruction"

module CodeGen::Targets::Wasm::Instructions
  include CodeGen

  # Used to declare numbers
  class Const < Instruction
    extend T::Sig

    sig { returns(CodeGen::Targets::Wasm::Type) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: CodeGen::Targets::Wasm::Type, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end
  end
end
