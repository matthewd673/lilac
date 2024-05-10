# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "instruction"

module Lilac
  module CodeGen
    # A Generator is used to turn a root component of some machine-dependent
    # code into a valid string representation of that component.
    class Generator
      extend T::Sig
      extend T::Helpers

      abstract!

      include CodeGen

      sig { params(root_component: Component).void }
      def initialize(root_component)
        @root_component = root_component
      end

      sig { abstract.returns(String) }
      def generate; end
    end
  end
end
