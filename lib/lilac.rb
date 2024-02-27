# typed: strict
require_relative "ansi"
require_relative "analysis/analyses"

extend T::Sig

sig { void }
def main
  puts(ANSI.fmt256("lilac", ANSI::LILAC_256, bold: true))
  puts("  analyses: list all analyses")
end

sig { void }
def print_analyses
  for a in ANALYSES
    puts(a.id)
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length > 0 and ARGV[0] == "analyses"
    print_analyses
  else
    main
  end
end
