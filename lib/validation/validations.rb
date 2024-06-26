# typed: strict
# frozen_string_literal: true

require_relative "ssa"
require_relative "typecheck"

module Lilac
  module Validation
    # A definitive list of all validations available in Lilac.
    VALIDATIONS = T.let([
      SSA,
      TypeCheck,
    ].freeze, T::Array[T.class_of(ValidationPass)])
  end
end
