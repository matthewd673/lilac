# typed: strict
require "sorbet-runtime"
require_relative "../../component"

module CodeGen::Targets::Wasm::Components
  class WasmComponent < CodeGen::Component
    # NOTE: stub
  end

  class Module < WasmComponent
    extend T::Sig

    sig { returns(T::Array[WasmComponent]) }
    attr_reader :components

    sig { params(components: T::Array[WasmComponent]).void }
    def initialize(components)
      @components = components
    end
  end

  # Represents the +start+ component of a module.
  class Start < WasmComponent
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end
  end

  # Represents the +func+ component of a module.
  class Func < WasmComponent
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

  # Represents an +import+ component in a module.
  class Import < WasmComponent
    extend T::Sig

    include CodeGen::Targets::Wasm

    sig { returns(String) }
    attr_reader :module_name
    sig { returns(String) }
    attr_reader :func_name
    sig { returns(T::Array[Type]) }
    attr_reader :param_types
    sig { returns(T.nilable(Type)) }
    attr_reader :result

    sig { params(module_name: String,
                 func_name: String,
                 param_types: T::Array[Type],
                 result: T.nilable(Type)).void }
    def initialize(module_name, func_name, param_types, result)
      @module_name = module_name
      @func_name = func_name
      @param_types = param_types
      @result = result
    end
  end
end
