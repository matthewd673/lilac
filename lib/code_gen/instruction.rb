# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  module CodeGen
    # An Instruction is a single instruction in machine dependent code.
    class Instruction
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(Integer) }
      def hash; end

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end
    end
  end
end
