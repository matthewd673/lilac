# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../../analysis/bb"

include CodeGen::Targets::Wasm

# A basic WasmBlock.
class CodeGen::Targets::Wasm::WasmBlock
  extend T::Sig

  include CodeGen::Targets::Wasm

  sig { returns(Analysis::BB) }
  attr_reader :bb

  sig { returns(T.nilable(WasmBlock)) }
  attr_accessor :next_block

  sig { params(bb: Analysis::BB, next_block: T.nilable(WasmBlock)).void }
  def initialize(bb, next_block: nil)
    @bb = bb
    @next_block = next_block
  end
end

# A WasmBlock that represents a true/false conditional.
class CodeGen::Targets::Wasm::WasmIfBlock < WasmBlock
  extend T::Sig

  sig { returns(T.nilable(WasmBlock)) }
  attr_accessor :true_branch

  sig { returns(T.nilable(WasmBlock)) }
  attr_accessor :false_branch

  sig { params(bb: Analysis::BB,
               true_branch: T.nilable(WasmBlock),
               false_branch: T.nilable(WasmBlock)).void }
  def initialize(bb, true_branch: nil, false_branch: nil)
    @bb = bb
    @true_branch = true_branch
    @false_branch = false_branch
  end
end

# A WasmBlock that represents a loop header.
class CodeGen::Targets::Wasm::WasmLoopBlock < WasmBlock
  extend T::Sig

  sig { returns(T.nilable(WasmBlock)) }
  attr_accessor :inner

  sig { params(bb: Analysis::BB, inner: T.nilable(WasmBlock)).void }
  def initialize(bb, inner: nil)
    @bb = bb
    @inner = inner
  end
end
