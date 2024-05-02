# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "../../../../pass"
require_relative "../instructions/instructions"

module CodeGen
  module Targets
    module Wasm
      module Optimization
        # The Tee optimization combines consecutive set and get instructions
        # into a single tee instruction.
        class Tee < Pass
          extend T::Sig

          include CodeGen::Targets::Wasm

          sig { override.returns(String) }
          def id
            "tee"
          end

          sig { override.returns(String) }
          def description
            "Combine set and get instructions into a single tee instruction"
          end

          sig do
            params(instructions: T::Array[Instructions::WasmInstruction]).void
          end
          def initialize(instructions)
            @instructions = instructions
          end

          sig { void }
          def run
            last = T.let(nil, T.nilable(Instructions::WasmInstruction))
            i = 0
            while i < @instructions.length
              # skip first instruction
              if i == 0
                last = @instructions[i]
                i += 1
                next
              end

              # NOTE: Sorbet doesn't require this let but it helped catch a
              # lot of type errors so I'm leaving it in
              inst = T.let(@instructions[i],
                           T.nilable(Instructions::WasmInstruction))

              unless inst # should never happen
                raise "Read a nil instruction"
              end

              # if last was set and this is get, make tee...
              if last.is_a?(Instructions::LocalSet) &&
                 inst.is_a?(Instructions::LocalGet) &&
                 last.variable == inst.variable
                tee = Instructions::LocalTee.new(inst.variable)

                # NOTE: its very important that these are "delete_at"
                # and not "delete" since otherwise multiple instructions
                # can be deleted across the whole array.
                @instructions.insert(i, tee)
                @instructions.delete_at(i - 1)
                @instructions.delete_at(i)

                i -= 2
              end

              last = @instructions[i]
              i += 1
            end
          end
        end
      end
    end
  end
end
