# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/code_gen/targets/wasm/leb128"

class LEB128Test < Minitest::Test
  extend T::Sig

  include Lilac::CodeGen::Targets::Wasm

  sig { void }
  def test_unsigned_624485
    bytes = LEB128.encode_unsigned_int(624_485)
    assert_bytes(bytes, [0xe5, 0x8e, 0x26]) # LSB to MSB
  end

  sig { void }
  def test_signed_n123456
    bytes = LEB128.encode_signed_int(-123_456)
    assert_bytes(bytes, [0xc0, 0xbb, 0x78]) # LSB to MSB
  end

  private

  sig { params(bytes: T::Array[Integer], expected: T::Array[Integer]).void }
  def assert_bytes(bytes, expected)
    assert_equal(bytes.length, expected.length)

    bytes.each_with_index do |b, i|
      assert_equal(expected[i], b)
    end
  end
end
