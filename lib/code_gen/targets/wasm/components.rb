# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../component"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # The Wasm::Components module contains Wasm component definitions.
        module Components
          # A generic Wasm component.
          class WasmComponent < CodeGen::Component
            # NOTE: stub
          end

          # Represents a Wasm +module+.
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

            include CodeGen::Targets::Wasm::Instructions

            sig { returns(T::Hash[Type, T::Array[Local]]) }
            attr_reader :locals_map

            sig { returns(T::Array[WasmInstruction]) }
            attr_reader :instructions

            sig do
              params(locals_map: T::Hash[Type, T::Array[Local]],
                     instructions: T::Array[WasmInstruction])
                .void
            end
            def initialize(locals_map, instructions)
              @locals_map = locals_map
              @instructions = instructions
            end
          end

          # Represents the +func+ component of a module.
          class Func < WasmComponent
            extend T::Sig

            include CodeGen::Targets::Wasm::Instructions

            sig { returns(String) }
            attr_reader :name

            sig { returns(T::Array[Local]) }
            attr_reader :params

            sig { returns(T::Array[Type]) }
            attr_reader :results

            sig { returns(T::Hash[Type, T::Array[Local]]) }
            attr_reader :locals_map

            sig { returns(T::Array[WasmInstruction]) }
            attr_reader :instructions

            sig { returns(T.nilable(String)) }
            attr_accessor :export

            sig do
              params(name: String,
                     params: T::Array[Local],
                     results: T::Array[Type],
                     locals_map: T::Hash[Type, T::Array[Local]],
                     instructions: T::Array[WasmInstruction],
                     export: T.nilable(String)).void
            end
            def initialize(name,
                           params,
                           results,
                           locals_map,
                           instructions,
                           export: nil)
              @name = name
              @params = params
              @results = results
              @locals_map = locals_map
              @instructions = instructions
              @export = export
            end
          end

          # Represents a named +local+ value (including func parameters).
          class Local
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

            sig { returns(T::Array[Type]) }
            attr_reader :results

            sig do
              params(module_name: String,
                     func_name: String,
                     param_types: T::Array[Type],
                     results: T::Array[Type])
                .void
            end
            def initialize(module_name, func_name, param_types, results)
              @module_name = module_name
              @func_name = func_name
              @param_types = param_types
              @results = results
            end
          end
        end
      end
    end
  end
end
