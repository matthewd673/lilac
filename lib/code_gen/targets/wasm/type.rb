# typed: strict
require_relative "sorbet-runtime"

class CodeGen::Targets::Wasm::Type < T::Enum
  enums do
    I32 = new
  end
end
