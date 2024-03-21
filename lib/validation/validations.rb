# typed: strict
require_relative "validation"
require_relative "ssa"
require_relative "typecheck"

# A definitive list of all validations available in Lilac.
Validation::VALIDATIONS = T.let([
  SSA.new,
  TypeCheck.new,
], T::Array[ValidationPass])
