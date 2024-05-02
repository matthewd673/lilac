# typed: strict
# frozen_string_literal: true

require_relative "validation"
require_relative "id_naming"
require_relative "ssa"
require_relative "typecheck"

# A definitive list of all validations available in Lilac.
Validation::VALIDATIONS = T.let([
  Validation::IDNaming,
  Validation::SSA,
  Validation::TypeCheck,
].freeze, T::Array[T.class_of(Validation::ValidationPass)])
