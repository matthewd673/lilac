# typed: strict
require "sorbet-runtime"
require_relative "wasm"

class CodeGen::Targets::Wasm::Type < T::Enum
  extend T::Sig

  enums do
    # TODO: incomplete
    I32 = new("i32")
  end

  sig { returns(String) }
  def to_s
    serialize
  end
end
