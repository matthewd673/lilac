# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../table"
require_relative "type"
require_relative "instructions"

class CodeGen::Targets::Wasm::Table < CodeGen::Table
  extend T::Sig

  include CodeGen
  include CodeGen::Targets::Wasm

  sig { void }
  def initialize
    super
    define_rules
  end

  private

  sig { void }
  def define_rules
    # statement rules
    add_rule(Pattern::DefinitionWildcard.new(Pattern::RhsWildcard.new),
             0,
             -> (object, recurse) {
               type = il_type_to_wasm_type(object.type)
               rhs = recurse.call(object.rhs)
               [rhs,
                Instructions::LocalSet.new(object.id.name)] # TODO: temp
             })
    # value rules
    add_rule(Pattern::ConstantWildcard.new,
             0,
             -> (object, recurse) {
               type = il_type_to_wasm_type(object.type)
               [Instructions::Const.new(type, object.value)]
             })
  end

  sig { params(il_type: IL::Type).returns(Type) }
  def il_type_to_wasm_type(il_type)
    case il_type
    when IL::Type::I32 then Type::I32
    when IL::Type::I64 then Type::I64
    when IL::Type::F32 then Type::F32
    when IL::Type::F64 then Type::F64
    else
      raise("IL type #{il_type} is not supported by Wasm")
    end
  end
end
