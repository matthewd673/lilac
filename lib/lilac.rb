# typed: strict

# load requirements for external programs
# NOTE: this is not comprehensive
require_relative "optimization/optimization_runner"
require_relative "validation/validation_runner"
require_relative "debugger/pretty_printer"
require_relative "interpreter"

require_relative "ansi"
require_relative "optimization/optimizations"
require_relative "validation/validations"
require_relative "frontend/parser"

# The CLI module contains the CLI tools provided by lilac.
module CLI
  extend T::Sig
  include Kernel

  sig { void }
  # Handles behavior when the lilac CLI is called with no arguments.
  def self.main
    puts(ANSI.fmt256("lilac", ANSI::LILAC_256, bold: true))
    puts("  parse <filename>: parse and pretty print an IL text file")
    puts("  optimizations: list all optimizations")
    puts("  validations: list all validations")
  end

  sig { void }
  # Print all available optimizations.
  def self.print_optimizations
    Optimization::OPTIMIZATIONS.each { |o|
      puts(o.id)
    }
  end

  sig { void }
  # Print all available validations.
  def self.print_validations
    Validation::VALIDATIONS.each { |v|
      puts(v.id)
    }
  end

  sig { params(filename: T.nilable(String)).void }
  def self.parse(filename)
    if not filename
      puts("No filename provided")
      return
    end

    program = Frontend::Parser::parse_file(filename)
    pp = Debugger::PrettyPrinter.new
    pp.print_program(program)
  end
end

# if lilac is run directly then provide a simple CLI.
if $PROGRAM_NAME == __FILE__
  if ARGV.length == 0 # no args case
    CLI.main
  elsif ARGV[0] == "optimizations"
    CLI.print_optimizations
  elsif ARGV[0] == "validations"
    CLI.print_validations
  elsif ARGV[0] == "parse"
    CLI.parse(ARGV[1])
  else # unknown args case
    CLI.main
  end
end
