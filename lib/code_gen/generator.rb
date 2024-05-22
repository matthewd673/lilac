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
      # Construct a new Generator.
      #
      # @param [Component] root_component The Component to generate code for.
      def initialize(root_component)
        @root_component = root_component
      end

      sig { abstract.returns(String) }
      # Generate code for the Generator's Component.
      #
      # @return [String] A source code string.
      def generate; end
    end
  end
end
