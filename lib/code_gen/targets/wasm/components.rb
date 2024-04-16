# typed: strict
require "sorbet-runtime"

module CodeGen::Targets::Wasm::Components
  class Component
    # NOTE: stub
  end

  class Module
    extend T::Sig

    sig { returns(T::Array[Component]) }
    attr_reader :components

    sig { params(components: T::Array[Component]).void }
    def initialize(components)
      @components = components
    end
  end

  # Represents the +start+ component of a module.
  class Start < Component
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end
  end

  # Represents the +func+ component of a module.
  class Func < Component
    extend T::Sig

    include CodeGen::Targets::Wasm::Instructions

    sig { returns(String) }
    attr_reader :name

    sig { returns(T::Array[FuncParam]) }
    attr_reader :params

    sig { returns(T.nilable(Type)) }
    attr_reader :result

    sig { returns(T::Array[WasmInstruction]) }
    attr_reader :instructions

    sig { params(name: String,
                 params: T::Array[FuncParam],
                 result: T.nilable(Type),
                 instructions: T::Array[WasmInstruction]).void }
    def initialize(name, params, result, instructions)
      @name = name
      @params = params
      @result = result
      @instructions = instructions
    end
  end

  # Represents a named +func+ parameter.
  class FuncParam
    extend T::Sig

    include CodeGen::Targets::Wasm

    sig { returns(Type) }
    attr_reader :type

    sig { returns(String) }
    attr_reader :name

    sig { params(type: Type, name: String).void }
    def initialize(type, name)
      @type = type
      @name = name
    end
  end
end
