# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/il"
require_relative "../lib/frontend/parser"
require_relative "../lib/frontend/generator"

class ILGenerationTest < Minitest::Test
  extend T::Sig

  include Lilac

  sig { void }
  def test_generates_il
    # attempt to parse each frontend test program and then generate it back
    Dir["test/programs/frontend/*"].each do |f|
      program = Frontend::Parser.parse_file(f)
      generator = Frontend::Generator.new(program)
      assert generator.generate
    end
  end
end
