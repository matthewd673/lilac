# typed: strict
require "sorbet-runtime"

module CodeGen::Targets::Wasm::Constructs
  class Construct
    # NOTE: stub
  end

  class Module
    extend T::Sig

    sig { returns(T::Array[Construct]) }
    attr_reader :constructs

    sig { params(constructs: T::Array[Construct]).void }
    def initialize(constructs)
      @constructs = constructs
    end
  end

  class Start < Construct
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end
  end

  # Represents a function in Wat. This is not an instruction.
  class Func < Construct
    extend T::Sig

    include CodeGen::Targets::Wasm::Instructions

    sig { returns(String) }
    attr_reader :name

    sig { returns(T::Array[WasmInstruction]) }
    attr_reader :instructions

    sig { params(name: String, instructions: T::Array[WasmInstruction]).void }
    def initialize(name, instructions)
      @name = name
      @instructions = instructions
    end
  end
end
