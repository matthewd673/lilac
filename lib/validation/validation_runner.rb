# typed: strict
require "sorbet-runtime"
require_relative "../il"
require_relative "validation"
require_relative "validations"

class ValidationRunner
  extend T::Sig

  sig { returns(IL::Program) }
  attr_reader :program

  sig { params(program: IL::Program).void }
  def initialize(program)
    @program = program
  end

  sig { params(validation: Validation).void }
  def run_pass(validation)
    validation.run(@program)
  end

  sig { params(validation_list: T::Array[Validation]).void }
  def run_passes(validation_list)
    for v in validation_list
      run_pass(v)
    end
  end
end
