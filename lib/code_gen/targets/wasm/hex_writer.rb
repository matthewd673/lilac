# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # The HexWriter class makes it easy to write a series of integers
        # representing hex values into a String.
        class HexWriter
          extend T::Sig

          sig { void }
          def initialize
            @bytes = T.let([], T::Array[Integer])
          end

          sig { params(bytes: Integer).void }
          def write(*bytes)
            @bytes.concat(bytes)
          end

          sig { returns(String) }
          def to_s
            @bytes.pack("C*")
          end
        end
      end
    end
  end
end
