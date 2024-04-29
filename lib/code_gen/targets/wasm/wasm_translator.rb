# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../translator"
require_relative "../../instruction"
require_relative "../../../il"
require_relative "../../../symbol_table"
require_relative "wasm_il_transformer"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"
require_relative "../../../analysis/dominators"
require_relative "../../../analysis/dom_tree"
require_relative "relooper"
require_relative "wasm_block"

# A WasmTranslator translates Lilac IL into Wasm instructions.
class CodeGen::Targets::Wasm::WasmTranslator < CodeGen::Translator
  extend T::Sig

  include CodeGen::Targets::Wasm

  sig { params(cfg_program: IL::CFGProgram).void }
  def initialize(cfg_program)
    @symbols = T.let(SymbolTable.new, SymbolTable)
    wasm_translator = CodeGen::Targets::Wasm::WasmILTransformer.new(@symbols)

    @loop_ct = T.let(0, Integer)
    @block_ct = T.let(0, Integer)

    super(wasm_translator, cfg_program)
  end

  sig { override.returns(Components::Module) }
  def translate
    components = []
    @symbols.push_scope # always have scope for globals and top-level

    # import all extern functions
    @program.each_extern_func { |f|
      components.push(translate_import(f))
    }

    # translate all functions
    @program.each_func { |f|
      components.push(translate_func(f))
    }

    # translate instructions for main stmt_list
    main_instructions = translate_instructions(@program.cfg)
    components.push(Components::Func.new("__lilac_main",
                                         [], # no params
                                         nil, # no return type
                                         main_instructions))
    components.push(Components::Start.new("__lilac_main"))

    wasm_module = Components::Module.new(components)

    return wasm_module
  end

  private

  sig { params(extern_funcdef: IL::ExternFuncDef).returns(Components::Import) }
  def translate_import(extern_funcdef)
    # translate param types for function signature
    param_types = []
    extern_funcdef.param_types.each { |t|
      param_types.push(Instructions::to_wasm_type(t))
    }

    # result type for void functions in Wasm is just nil
    if extern_funcdef.ret_type != IL::Type::Void
      result = Instructions::to_wasm_type(T.unsafe(extern_funcdef.ret_type))
    end

    # construct import object
    import = Components::Import.new(extern_funcdef.source,
                                    extern_funcdef.name,
                                    param_types,
                                    result)
    return import
  end

  sig { params(cfg_funcdef: IL::CFGFuncDef).returns(Components::Func) }
  def translate_func(cfg_funcdef)
    params = [] # list of params for function signature

    # create a new scope with func params
    @symbols.push_scope
    cfg_funcdef.params.each { |p|
      @symbols.insert(ILSymbol.new(p.id, p.type))

      # also mark this down for the function signature
      param_type = Instructions::to_wasm_type(p.type)
      param_name = p.id.name
      params.push(Components::FuncParam.new(param_type, param_name))
    }

    # translate instructions and pop the scope we used
    instructions = translate_instructions(cfg_funcdef.cfg)
    @symbols.pop_scope

    # construct func with appropriate params and return type
    # if return type is void then result is simply nil
    if cfg_funcdef.ret_type != IL::Type::Void
      result = Instructions::to_wasm_type(cfg_funcdef.ret_type)
    end
    func = Components::Func.new(cfg_funcdef.name,
                                params,
                                result,
                                instructions)
    return func
  end

  sig { params(cfg: Analysis::CFG)
          .returns(T::Array[Instructions::WasmInstruction]) }
  def translate_instructions(cfg)
    # run relooper on the cfg
    dom_facts = Analysis::Dominators.new(cfg).run
    dom_tree = Analysis::DomTree.new(dom_facts)
    relooper = Relooper.new(cfg, dom_tree)

    instructions = []

    # scan forwards to build a symbol table of all locals and their types.
    # NOTE: assume that our caller has kindly pushed a new scope
    cfg.each_node { |b|
      # scan each block for definitions and log them
      # a previous validation should have already ensured that there are no
      # inconsistent types, so we don't need any checks here.
      b.stmt_list.each { |s|
        if not s.is_a?(IL::Definition)
          next
        end

        # avoid redefining params
        if @symbols.lookup(s.id.key)
          next
        end

        # log in symbol table
        id_symbol = ILSymbol.new(s.id, s.type)
        @symbols.insert(id_symbol)

        # push declaration
        type = Instructions::to_wasm_type(s.type)
        decl = Instructions::Local.new(type, s.id.name)
        instructions.push(decl)
      }
    }

    # translate the WasmBlocks from relooper and return it
    root = relooper.translate
    instructions.concat(translate_wasm_block(root))

    return instructions
  end

  sig { params(block: WasmBlock)
          .returns(T::Array[Instructions::WasmInstruction])}
  def translate_wasm_block(block)
    case block
      when WasmIfBlock
        instructions = []

        # translate all the conditional stuff
        block.bb.stmt_list.each { |s|
          instructions.concat(@transformer.transform(s))
        }

        # push the conditional and create the if
        bb_exit = T.unsafe(block.bb.exit)
        if not bb_exit
          raise "Basic block did not have a exit"
        end
        instructions.push(push_value(bb_exit.cond))
        # TODO: handle jump_zero with non-int conditional value
        if bb_exit.is_a?(IL::JumpZero)
          cond_il_type = T.cast(@transformer, WasmILTransformer)
                          .get_il_type(bb_exit.cond)
          cond_type = Instructions.to_integer_type(cond_il_type)
          instructions.push(Instructions::EqualZero.new(cond_type))
        end
        instructions.push(Instructions::If.new)

        # no true branch = invalid WasmIfBlock
        if not block.true_branch
          raise "WasmIfBlock has no true branch"
        end

        # translate true branch
        if_true_branch = translate_wasm_block(T.unsafe(block.true_branch))
        instructions.concat(if_true_branch)

        # false branch is optional
        if block.false_branch
          # create the else
          instructions.push(Instructions::Else.new)

          # translate false branch
          if_false_branch = translate_wasm_block(T.unsafe(block.false_branch))
          instructions.concat(if_false_branch)
        end

        # end the if else statement
        instructions.push(Instructions::End.new)

        # translate the following blocks
        if block.next_block
          instructions.concat(translate_wasm_block(T.unsafe(block.next_block)))
        end

        return instructions
      when WasmLoopBlock
        instructions = []
        block_label = alloc_block_label
        loop_label = alloc_loop_label

        # translate all the conditional stuff
        # this will be placed at the beginning of the _block_ and
        # the end of the _loop_
        cond_insts = []
        block.bb.stmt_list.each { |s|
          cond_insts.concat(@transformer.transform(s))
        }
        bb_exit = T.unsafe(block.bb.exit)
        if not bb_exit
          raise "Basic block did not have a exit"
        end
        cond_insts.push(push_value(bb_exit.cond))
        # TODO: handle jz with non-int cond value
        if bb_exit.is_a?(IL::JumpZero)
          cond_il_type = T.cast(@transformer, WasmILTransformer)
                          .get_il_type(bb_exit.cond)
          cond_type = Instructions.to_integer_type(cond_il_type)
          cond_insts.push(Instructions::EqualZero.new(cond_type))
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
        if not block.inner
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
          instructions.concat(translate_wasm_block(T.unsafe(block.next_block)))
        end

        return instructions
      when WasmBlock
        instructions = []

        # translate block
        block.bb.stmt_list.each { |s|
          instructions.concat(@transformer.transform(s))
        }

        # translate next block
        if block.next_block
          instructions.concat(translate_wasm_block(T.unsafe(block.next_block)))
        end

        return instructions
    end
  end

  sig { params(value: IL::Value).returns(Instructions::WasmInstruction) }
  def push_value(value)
    case value
    when IL::Constant
      Instructions::Const.new(Instructions.to_wasm_type(value.type),
                              value.value)
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
    return label
  end

  sig { returns(String) }
  def alloc_loop_label
    label = "__lilac_loop_#{@loop_ct}"
    @loop_ct += 1
    return label
  end
end
