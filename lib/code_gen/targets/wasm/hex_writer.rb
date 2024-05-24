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
          # Construct a new HexWriter.
          def initialize
            @bytes = T.let([], T::Array[Integer])
          end

          sig { params(bytes: Integer).void }
          # Write an arbitrary number of bytes to the HexWriter string.
          #
          # @param [Integer] bytes The bytes to write.
          def write(*bytes)
            @bytes.concat(bytes)
          end

          sig { params(bytes: T::Array[Integer]).void }
          # Write an array of bytes to the HexWriter string.
          #
          # @param [T::Array[Integer]] bytes The bytes to write.
          def write_all(bytes)
            @bytes.concat(bytes)
          end

          sig { returns(String) }
          # Get a string of the bytes that have been written so far.
          def to_s
            @bytes.pack("C*")
          end
        end
      end
    end
  end
end
