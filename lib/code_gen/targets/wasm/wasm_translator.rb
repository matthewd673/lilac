# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../translator"
require_relative "../../instruction"
require_relative "../../../il"
require_relative "../../../symbol_table"
require_relative "wasm_il_transformer"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"
require_relative "relooper"
require_relative "wasm_block"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # A WasmTranslator translates Lilac IL into Wasm instructions.
        class WasmTranslator < CodeGen::Translator
          extend T::Sig

          include CodeGen::Targets::Wasm

          sig { params(cfg_program: IL::CFGProgram).void }
          def initialize(cfg_program)
            @symbols = T.let(SymbolTable.new, SymbolTable)
            wasm_transformer = WasmILTransformer.new(@symbols)

            @loop_ct = T.let(0, Integer)
            @block_ct = T.let(0, Integer)

            @start_function = T.let(nil, T.nilable(String))

            super(wasm_transformer, cfg_program)
          end

          sig { params(func_name: String).void }
          # Set the function that will be used as the entry point for the
          # Wasm program. If no start function is set then the Wasm program
          # will have no entry point (no Start component in module).
          def set_start_function(func_name)
            unless @program.get_func(func_name)
              raise "Function '#{func_name}' does not exist in Program."
            end

            @start_function = func_name
          end

          sig { override.returns(Components::Module) }
          def translate
            components = []
            @symbols.push_scope # always have scope for globals and top-level

            # import all extern functions
            @program.each_extern_func do |f|
              components.push(translate_import(f))
            end

            # translate all globals
            @program.each_global do |g|
              # add global to top-level scope
              @symbols.insert(ILSymbol.new(g.id, g.type))
              components.push(translate_global(g))
            end

            # translate all functions
            @program.each_func { |f| components.push(translate_func(f)) }

            # add start component if a start function has been set
            if @start_function
              components.push(Components::Start.new(@start_function))
            end

            Components::Module.new(components)
          end

          private

          sig do
            params(extern_funcdef: IL::ExternFuncDef)
              .returns(Components::Import)
          end
          def translate_import(extern_funcdef)
            # translate param types for function signature
            param_types = []
            extern_funcdef.param_types.each do |t|
              param_types.push(Instructions.to_wasm_type(t))
            end

            results = []
            unless extern_funcdef.ret_type.is_a?(IL::Types::Void)
              results.push(Instructions.to_wasm_type(extern_funcdef.ret_type))
            end

            # construct import object
            Components::Import.new(extern_funcdef.source,
                                   extern_funcdef.name,
                                   param_types,
                                   results)
          end

          sig { params(global_def: IL::GlobalDef).returns(Components::Global) }
          def translate_global(global_def)
            type = Instructions.to_wasm_type(global_def.type)
            name = global_def.id.name
            const = @transformer.transform(global_def.rhs)[0]

            unless const.is_a?(Instructions::ConstInteger) ||
                    const.is_a?(Instructions::ConstFloat)
              raise "RHS of GlobalDef did not translate to a ConstInteger or "\
                    "a ConstFloat"
            end

            # TODO: optimization to make some globals not mutable
            Components::Global.new(type, name, const, mutable: true)
          end

          sig { params(cfg_funcdef: IL::CFGFuncDef).returns(Components::Func) }
          def translate_func(cfg_funcdef)
            params = [] # list of params for function signature

            # create a new scope with func params
            @symbols.push_scope
            cfg_funcdef.params.each do |p|
              @symbols.insert(ILSymbol.new(p.id, p.type))

              # also mark this down for the function signature
              param_type = Instructions.to_wasm_type(p.type)
              param_name = p.id.name
              params.push(Components::Local.new(param_type, param_name))
            end

            # find all locals in the function
            locals = find_locals(cfg_funcdef.cfg)

            # translate instructions and pop the scope we used
            instructions = translate_instructions(cfg_funcdef.cfg)
            @symbols.pop_scope
            instructions.push(Instructions::End.new) # every func ends with End

            # construct func with appropriate params and return type
            # if return type is void then result is simply nil
            results = []
            unless cfg_funcdef.ret_type.is_a?(IL::Types::Void)
              results.push(Instructions.to_wasm_type(cfg_funcdef.ret_type))
            end
            export_name = cfg_funcdef.exported ? cfg_funcdef.name : nil
            Components::Func.new(cfg_funcdef.name,
                                 params,
                                 results,
                                 locals,
                                 instructions,
                                 export: export_name)
          end

          sig do
            params(cfg: Analysis::CFG)
              .returns(T::Hash[Type, T::Array[Components::Local]])
          end
          def find_locals(cfg)
            locals = {}

            # scan forwards to build a symbol table of all locals and their
            #   types.
            # NOTE: assume that our caller has kindly pushed a new scope
            cfg.each_node do |b|
              # scan each block for definitions and log them
              # a previous validation should have already ensured that there are
              # no inconsistent types, so we don't need any checks here.
              b.stmt_list.each do |s|
                unless s.is_a?(IL::Definition)
                  next
                end

                # avoid redefining globals, params, or ids used more than once
                if @symbols.lookup(s.id)
                  next
                end

                # log in symbol table
                id_symbol = ILSymbol.new(s.id, s.type)
                @symbols.insert(id_symbol)

                # push declaration
                type = Instructions.to_wasm_type(s.type)
                new_local = Components::Local.new(type, s.id.name)
                if locals[type]
                  locals[type].push(new_local)
                else
                  locals[type] = [new_local]
                end
              end
            end

            locals
          end

          sig do
            params(cfg: Analysis::CFG)
              .returns(T::Array[Instructions::WasmInstruction])
          end
          def translate_instructions(cfg)
            # create a relooper instance for the cfg
            relooper = Relooper.new(cfg)

            instructions = []

            # run relooper, translate the WasmBlocks, and then return that
            root = relooper.translate
            instructions.concat(translate_wasm_block(root))

            instructions
          end

          sig do
            params(block: WasmBlock)
              .returns(T::Array[Instructions::WasmInstruction])
          end
          def translate_wasm_block(block)
            case block
            when WasmIfBlock
              instructions = []

              # translate all the conditional stuff
              block.bb.stmt_list.each do |s|
                instructions.concat(@transformer.transform(s))
              end

              # push the conditional and create the if
              bb_exit = T.unsafe(block.bb.exit)
              unless bb_exit
                raise "Basic block did not have a exit"
              end

              instructions.push(push_value(bb_exit.cond))
              # TODO: handle jump_zero with non-int conditional value
              if bb_exit.is_a?(IL::JumpZero)
                cond_il_type = T.cast(@transformer, WasmILTransformer)
                                .get_il_type(bb_exit.cond)

                # handle integer or non-integer IL type
                if cond_il_type.is_a?(IL::Types::IntegerType)
                  cond_type = Instructions.to_integer_type(cond_il_type)
                  instructions.push(Instructions::EqualZero.new(cond_type))
                elsif cond_il_type.is_a?(IL::Types::FloatType)
                  cond_type = Instructions.to_float_type(cond_il_type)
                  instructions.push(
                    Instructions::ConstFloat.new(cond_type, "0.0")
                  )
                  instructions.push(Instructions::Equal.new(cond_type))
                else # NOTE: I think this never happens
                  raise "Unexpected conditional IL type"
                end
              end
              instructions.push(Instructions::If.new)

              # no true branch = invalid WasmIfBlock
              unless block.true_branch
                raise "WasmIfBlock has no true branch"
              end

              # translate true branch
              if_true_branch = translate_wasm_block(T.unsafe(block.true_branch))
              instructions.concat(if_true_branch)

              # fill in EmptyType if true branch is empty
              if if_true_branch.empty?
                instructions.push(Instructions::EmptyType.new)
              end

              # false branch is optional
              if block.false_branch
                # create the else
                instructions.push(Instructions::Else.new)

                # translate false branch
                block_false_branch = T.unsafe(block.false_branch)
                if_false_branch = translate_wasm_block(block_false_branch)
                instructions.concat(if_false_branch)

                # fill in EmptyType if false branch is empty
                if if_false_branch.empty?
                  instructions.push(Instructions::EmptyType.new)
                end
              end

              # end the if else statement
              instructions.push(Instructions::End.new)

              # translate the following blocks
              if block.next_block
                block_next_block = T.unsafe(block.next_block)
                instructions.concat(translate_wasm_block(block_next_block))
              end

              instructions
            when WasmLoopBlock
              instructions = []
              block_label = alloc_block_label
              loop_label = alloc_loop_label

              # translate all the conditional stuff
              # this will be placed at the beginning of the _block_ and
              # the end of the _loop_
              cond_insts = []
              block.bb.stmt_list.each do |s|
                cond_insts.concat(@transformer.transform(s))
              end
              bb_exit = T.unsafe(block.bb.exit)
              unless bb_exit
                raise "Basic block did not have a exit"
              end

              cond_insts.push(push_value(bb_exit.cond))
              if bb_exit.is_a?(IL::JumpZero) # TODO: handle JumpNotZero?
                cond_il_type = T.cast(@transformer, WasmILTransformer)
                                .get_il_type(bb_exit.cond)

                # handle integer or non-integer IL type
                if cond_il_type.is_a?(IL::Types::IntegerType)
                  cond_type = Instructions.to_integer_type(cond_il_type)
                  cond_insts.push(Instructions::EqualZero.new(cond_type))
                elsif cond_il_type.is_a?(IL::Types::FloatType)
                  cond_type = Instructions.to_float_type(cond_il_type)
                  cond_insts.push(
                    Instructions::ConstFloat.new(cond_type, "0.0")
                  )
                  cond_insts.push(Instructions::Equal.new(cond_type))
                else # NOTE: I think this never happens
                  raise "Unexpected conditional IL type"
                end
              end

              # create the outer block
              instructions.push(Instructions::Block.new(block_label))

              # conditional check before entering the loop
              # (since this is emulating a while, not a do-while)
              instructions.concat(cond_insts)
              # push conditional branch
              instructions.push(Instructions::BranchIf.new(block_label))

              # create the loop
              instructions.push(Instructions::Loop.new(loop_label))

              # translate the inner of the loop (not optional)
              unless block.inner
                raise "WasmLoopBlock has no inner"
              end

              inner = translate_wasm_block(T.unsafe(block.inner))
              instructions.concat(inner)

              # conditional check at end of the loop to see if we should exit
              instructions.concat(cond_insts)
              instructions.push(Instructions::BranchIf.new(block_label))

              # unconditional jump back after the check
              instructions.push(Instructions::Branch.new(loop_label))

              # end the loop and the block
              instructions.push(Instructions::End.new)
              instructions.push(Instructions::End.new)

              # translate the following blocks
              if block.next_block
                block_next_block = T.unsafe(block.next_block)
                instructions.concat(translate_wasm_block(block_next_block))
              end

              instructions
            when WasmBlock
              instructions = []

              # translate block
              block.bb.stmt_list.each do |s|
                instructions.concat(@transformer.transform(s))
              end

              # translate next block
              if block.next_block
                block_next_block = T.unsafe(block.next_block)
                instructions.concat(translate_wasm_block(block_next_block))
              end

              instructions
            end
          end

          sig do
            params(value: IL::Value).returns(Instructions::WasmInstruction)
          end
          def push_value(value)
            case value
            when IL::Constant
              if value.type.is_a?(IL::Types::IntegerType)
                Instructions::ConstInteger.new(
                  Instructions.to_integer_type(value.type),
                  value.value
                )
              elsif value.type.is_a?(IL::Types::FloatType)
                Instructions::ConstFloat.new(
                  Instructions.to_float_type(value.type),
                  value.value
                )
              end

              raise "IL::Constant is neither integer nor float"
            when IL::ID
              Instructions::LocalGet.new(value.name)
            when IL::Value # cannot happen, IL::Value is abstract
              raise "Attempted to push value of stub IL::Value"
            else
              T.absurd(value)
            end
          end

          sig { returns(String) }
          def alloc_block_label
            label = "__lilac_block#{@block_ct}"
            @block_ct += 1
            label
          end

          sig { returns(String) }
          def alloc_loop_label
            label = "__lilac_loop_#{@loop_ct}"
            @loop_ct += 1
            label
          end
        end
      end
    end
  end
end
