# typed: strict
require_relative "validation"
require_relative "typecheck"

# A definitive list of all validations available in lilac.
VALIDATIONS = T.let([
  TypeCheck.new
], T::Array[Validation])
