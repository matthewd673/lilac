# typed: strict
require_relative "validation"
require_relative "id_naming"
require_relative "ssa"
require_relative "typecheck"

# A definitive list of all validations available in Lilac.
Validation::VALIDATIONS = T.let([
  IDNaming.new,
  Validation::SSA.new,
  TypeCheck.new,
], T::Array[ValidationPass])
