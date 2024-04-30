# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "wasm"

include CodeGen::Targets::Wasm

CodeGen::Targets::Wasm::IntegerType = T.type_alias do
                                              T.any(Type::I32, Type::I64) end

CodeGen::Targets::Wasm::FloatType = T.type_alias do
                                            T.any(Type::F32, Type::F64) end


module CodeGen
  module Targets
  module Wasm
  class Type < T::Enum
  extend T::Sig

  enums do
    I32 = new("i32")
    I64 = new("i64")
    F32 = new("f32")
    F64 = new("f64")
  end

  sig { returns(String) }
  def to_s
    serialize
  end
  end
  end
  end
end
