# typed: strict
# frozen_string_literal: true

require_relative "validation"
require_relative "id_naming"
require_relative "ssa"
require_relative "typecheck"

# A definitive list of all validations available in Lilac.
Validation::VALIDATIONS = T.let([
  Validation::IDNaming.new,
  Validation::SSA.new,
  Validation::TypeCheck.new,
].freeze, T::Array[Validation::ValidationPass])
