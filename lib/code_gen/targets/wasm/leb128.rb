# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # The LEB128 module contains functions to encode and decode integers
        # in Little Endian Base 128.
        module LEB128
          extend T::Sig

          sig { params(int: Integer).returns(T::Array[Integer]) }
          # Encode an unsigned integer in LEB128.
          #
          # @param [Integer] int The unsigned integer to encode.
          # @return [T::Array[Integer]] An array of bytes representing the
          #   LEB128 encoding. Ordered from LSB to MSB.
          def self.encode_unsigned(int)
            # NOTE: adapted from:
            #   https://en.wikipedia.org/wiki/LEB128#C-like_pseudocode

            bytes = []
            loop do
              next_byte = int & 0x7f
              int >>= 7

              # set highest-order bit if more bytes to come
              if int != 0
                next_byte |= 0x80
              end

              bytes.push(next_byte)

              break if int == 0
            end

            bytes
          end

          sig { params(int: Integer).returns(T::Array[Integer]) }
          # Encode an signed integer in LEB128.
          #
          # @param [Integer] int The signed integer to encode.
          # @return [T::Array[Integer]] An array of bytes representing the
          #   LEB128 encoding. Ordered from LSB to MSB.
          def self.encode_signed(int)
            # NOTE: adapted from:
            #   https://en.wikipedia.org/wiki/LEB128#C-like_pseudocode
            negative = int < 0

            # TODO: only supports 32 or 64 bit integers
            size = int <= MAX_INT32 && int >= MIN_INT32 ? 32 : 64

            bytes = []
            loop do
              next_byte = int & 0x7f
              int >>= 7

              # manually sign extend
              if negative
                int |= (~0 << (size - 7))
              end

              if (int == 0 && next_byte & 0x40 == 0) ||
                 (int == -1 && next_byte & 0x40 != 0)
                bytes.push(next_byte)
                break
              else
                bytes.push(next_byte | 0x80)
              end
            end

            bytes
          end

          private

          MAX_INT32 = T.let(2_147_483_647, Integer)
          MIN_INT32 = T.let(-2_147_483_648, Integer)
          private_constant :MAX_INT32
          private_constant :MIN_INT32
        end
      end
    end
  end
end
