# typed: strict
require "sorbet-runtime"
require_relative "wasm"

class CodeGen::Targets::Wasm::Type < T::Enum
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
