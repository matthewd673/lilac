# typed: strict
require_relative "ansi"

extend T::Sig

sig { void }
def main
  puts(ANSI.fmt256("lilac", ANSI::LILAC_256, bold: true))
end

if $PROGRAM_NAME == __FILE__
  main
end
