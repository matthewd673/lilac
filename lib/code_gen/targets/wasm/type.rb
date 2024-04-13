# typed: strict
require "sorbet-runtime"
require_relative "wasm"

class CodeGen::Targets::Wasm::Type < T::Enum
  enums do
    # TODO: incomplete
    I32 = new
  end
end
