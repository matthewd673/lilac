# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "../../../visitor"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # A WatGenerator generates valid Wat from Wasm instructions.
        class WatGenerator < CodeGen::Generator
          extend T::Sig

          include CodeGen::Targets::Wasm

          sig { params(root_component: Components::WasmComponent).void }
          def initialize(root_component)
            @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)

            super(root_component)
          end

          sig { override.returns(String) }
          def generate
            @visitor.visit(@root_component)
          end

          private

          VISIT_ARRAY = T.let(lambda { |v, o, c|
            str = ""
            o.each do |element|
              str += "#{v.visit(element, ctx: c)}\n"
            end
            str.chomp!
            str
          }, Visitor::Lambda)

          VISIT_MODULE = T.let(lambda { |v, o, c|
            "(module\n#{v.visit(o.components, ctx: "  ")}\n)"
          }, Visitor::Lambda)

          VISIT_IMPORT = T.let(lambda { |v, o, c|
            import_str = "(import \"#{o.module_name}\" \"#{o.func_name}\")"

            # stringify param types
            params_str = " "
            o.param_types.each do |t|
              params_str += "(param #{t})"
            end
            params_str.chomp!(" ")

            # stringify return type
            result_str = ""
            o.results.each do |r|
              result_str += " (result #{o.result})"
            end

            "#{c}(func $#{o.func_name} #{import_str}#{params_str}#{result_str})"
          }, Visitor::Lambda)

          VISIT_GLOBAL = T.let(lambda { |v, o, c|
            type_str = o.type.to_s
            if o.mutable
              type_str = "(mut #{type_str})"
            end
            "#{c}(global $#{o.name} #{type_str} (#{v.visit(o.default_value)}))"
          }, Visitor::Lambda)

          VISIT_FUNC = T.let(lambda { |v, o, c|
            # stringify export (if it has one)
            export_str = " ".dup
            if o.export
              export_str += "(export \"#{o.export}\") "
            end

            # stringify params
            params_str = "".dup
            o.params.each do |p|
              params_str += "(param $#{p.name} #{p.type})"
            end
            params_str.chomp!(" ")

            # stringify return type
            result_str = "".dup
            o.results.each do |r|
              result_str += " (result #{r})"
            end

            # stringify locals
            locals_str = "".dup
            o.locals_map.each_key do |t|
              locals_str += "#{v.visit(o.locals_map[t], ctx: "#{c}  ")}\n"
            end

            # stringify instructions
            instructions_str = v.visit(o.instructions, ctx: "#{c}  ")
            instructions_str.chomp!
            # don't print the final End instruction since we're using S-exp
            instructions_str.chomp!("end")

            "#{c}(func $#{o.name}#{export_str}#{params_str}#{result_str}\n"\
            "#{locals_str}#{instructions_str}\n#{c})"
          }, Visitor::Lambda)

          VISIT_LOCAL = T.let(lambda { |v, o, c|
            "#{c}(local $#{o.name} #{o.type})"
          }, Visitor::Lambda)

          VISIT_START = T.let(lambda { |v, o, c|
            "#{c}(start $#{o.name})"
          }, Visitor::Lambda)

          VISIT_INSTRUCTION = T.let(lambda { |v, o, c|
            "#{c}#{o.wat}"
          }, Visitor::Lambda)

          VISIT_LAMBDAS = T.let({
            Array => VISIT_ARRAY,
            Components::Module => VISIT_MODULE,
            Components::Import => VISIT_IMPORT,
            Components::Func => VISIT_FUNC,
            Components::Local => VISIT_LOCAL,
            Components::Global => VISIT_GLOBAL,
            Components::Start => VISIT_START,
            Instruction => VISIT_INSTRUCTION,
          }.freeze, Visitor::LambdaHash)

          private_constant :VISIT_ARRAY
          private_constant :VISIT_MODULE
          private_constant :VISIT_IMPORT
          private_constant :VISIT_FUNC
          private_constant :VISIT_LOCAL
          private_constant :VISIT_START
          private_constant :VISIT_INSTRUCTION
          private_constant :VISIT_LAMBDAS
        end
      end
    end
  end
end
