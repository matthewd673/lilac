# typed: strict
require_relative "validation"
require_relative "typecheck"

VALIDATIONS = T.let([
  TypeCheck.new
], T::Array[Validation])
