# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

# load requirements for external programs
# NOTE: this is not comprehensive
require_relative "optimization/optimization_runner"
require_relative "validation/validation_runner"
require_relative "debugging/pretty_printer"
require_relative "debugging/graph_visualizer"
require_relative "analysis/bb"
require_relative "analysis/cfg"
require_relative "ssa"
require_relative "interpreter"
require_relative "frontend/generator"
require_relative "code_gen/targets/wasm/wasm_translator"
require_relative "code_gen/targets/wasm/wat_generator"
require_relative "code_gen/targets/wasm/optimization/tee"

# load requirements for CLI module (may also benefit external programs)
require_relative "ansi"
require_relative "optimization/optimizations"
require_relative "validation/validations"
require_relative "frontend/parser"

# The CLI module contains the CLI tools provided by Lilac.
module CLI
  extend T::Sig
  include Kernel

  sig { void }
  # Handles behavior when the Lilac CLI is called with no arguments.
  def self.main
    puts(ANSI.fmt256("lilac", ANSI::LILAC_256, bold: true))
    puts("  optimizations: list all optimizations")
    puts("  validations: list all validations")
    puts("  parse <filename>: parse and pretty print an IL text file")
    puts("  cfg <filename>: parse an IL text file, compute a CFG, and output a Graphviz graph for it")
  end

  sig { void }
  # Print all available optimizations.
  def self.print_optimizations
    Optimization::OPTIMIZATIONS.each do |o|
      puts(o.id)
    end
  end

  sig { void }
  # Print all available validations.
  def self.print_validations
    Validation::VALIDATIONS.each do |v|
      puts(v.id)
    end
  end

  sig { params(filename: T.nilable(String)).void }
  # Parse a file using +Frontend::Parser+ and pretty-print it.
  #
  # @param [T.nilable(String)] filename The name of the file to parse
  #   (or +nil+ which will be handled nicely).
  def self.parse(filename)
    unless filename
      puts("usage: lilac parse <filename>")
      return
    end

    program = Frontend::Parser.parse_file(filename)
    pp = Debugging::PrettyPrinter.new
    pp.print_program(program)
  end

  sig { params(filename: T.nilable(String)).void }
  # Parse a file using +Frontend::Parser+, build a CFG of its top-level
  # statement list, and print a Graphviz DOT representation of the CFG.
  #
  # @param [T.nilable(String)] filename The name of the file to parse
  #   (or +nil+ which will be handled nicely).
  def self.cfg(filename)
    unless filename
      puts("usage: lilac cfg <filename>")
      return
    end

    program = Frontend::Parser.parse_file(filename)

    func_ct = 0
    program.each_func do |f|
      func_ct += 1
    end

    if func_ct > 0
      puts("// WARNING: #{func_ct} functions were not included in the CFG")
    end

    bb = Analysis::BB.from_stmt_list(program.stmt_list)
    cfg = Analysis::CFG.new(bb)
    graphviz = Debugging::GraphVisualizer.generate_graphviz(cfg)
    puts(graphviz)
  end
end

# if Lilac is run directly then provide a simple CLI.
if $PROGRAM_NAME == __FILE__
  if ARGV.empty? # no args case
    CLI.main
  elsif ARGV[0] == "optimizations"
    CLI.print_optimizations
  elsif ARGV[0] == "validations"
    CLI.print_validations
  elsif ARGV[0] == "parse"
    CLI.parse(ARGV[1])
  elsif ARGV[0] == "cfg"
    CLI.cfg(ARGV[1])
  else # unknown args case
    CLI.main
  end
end
