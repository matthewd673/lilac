# typed: strict
# frozen_string_literal: true

require_relative "validation"
require_relative "id_naming"
require_relative "ssa"
require_relative "typecheck"

# A definitive list of all validations available in Lilac.
Validation::VALIDATIONS = T.let([
  IDNaming.new,
  Validation::SSA.new,
  TypeCheck.new,
].freeze, T::Array[ValidationPass])
