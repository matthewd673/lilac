# typed: true
require "sorbet-runtime"
require_relative "il"

module Interpreter
  include Kernel
  extend T::Sig

  sig { params(program: Program).void }
  def self.interpret(program)
    program.each_stmt { |s|
      puts(s) # TODO: temp
    }
  end
end
