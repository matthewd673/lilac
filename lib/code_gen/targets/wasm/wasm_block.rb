# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "wasm"
require_relative "../../../analysis/bb"

include CodeGen::Targets::Wasm

# A basic WasmBlock.
module CodeGen
  module Targets
    module Wasm
      class WasmBlock
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
    end
  end
end

# A WasmBlock that represents a true/false conditional.
module CodeGen
  module Targets
    module Wasm
      class WasmIfBlock < WasmBlock
        extend T::Sig

        sig { returns(T.nilable(WasmBlock)) }
        attr_accessor :true_branch

        sig { returns(T.nilable(WasmBlock)) }
        attr_accessor :false_branch

        sig do
          params(bb: Analysis::BB,
                 true_branch: T.nilable(WasmBlock),
                 false_branch: T.nilable(WasmBlock)).void
        end
        def initialize(bb, true_branch: nil, false_branch: nil)
          @bb = bb
          @true_branch = true_branch
          @false_branch = false_branch
        end
      end
    end
  end
end

# A WasmBlock that represents a loop header.
module CodeGen
  module Targets
    module Wasm
      class WasmLoopBlock < WasmBlock
        extend T::Sig

        sig { returns(T.nilable(WasmBlock)) }
        attr_accessor :inner

        sig { params(bb: Analysis::BB, inner: T.nilable(WasmBlock)).void }
        def initialize(bb, inner: nil)
          @bb = bb
          @inner = inner
        end
      end
    end
  end
end
