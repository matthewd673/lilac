# typed: strict
require_relative "ansi"
require_relative "analysis/analyses"
require_relative "validation/validations"

# The CLI module contains the CLI tools provided by lilac.
module CLI
  extend T::Sig
  include Kernel

  sig { void }
  # Handles behavior when the lilac CLI is called with no arguments.
  def self.main
    puts(ANSI.fmt256("lilac", ANSI::LILAC_256, bold: true))
    puts("  analyses: list all analyses")
    puts("  validations: list all validations")
  end

  sig { void }
  # Print all available analyses.
  def self.print_analyses
    for a in Analysis::ANALYSES
      puts(a.id)
    end
  end

  sig { void }
  # Print all available validations.
  def self.print_validations
    for v in VALIDATIONS
      puts(v.id)
    end
  end
end

# if lilac is run directly then provide a simple CLI.
if $PROGRAM_NAME == __FILE__
  if ARGV.length == 0 # no args case
    CLI.main
  elsif ARGV[0] == "analyses"
    CLI.print_analyses
  elsif ARGV[0] == "validations"
    CLI.print_validations
  else # unknown args case
    CLI.main
  end
end
