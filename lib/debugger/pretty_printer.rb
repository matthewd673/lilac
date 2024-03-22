# typed: strict
require "sorbet-runtime"
require_relative "debugger"
require_relative "../ansi"
require_relative "../il"
require_relative "../visitor"
require_relative "../analysis/bb"

# A PrettyPrinter contains functions that make it easy to pretty-print various
# internal lilac data structures, like +IL::Program+, to the terminal.
class Debugger::PrettyPrinter
  extend T::Sig

  sig { void }
  # Construct a new PrettyPrinter.
  def initialize
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
  end

  sig { params(program: IL::Program).void }
  # Pretty-print the statements in an +IL::Program+ to the terminal with line
  # numbers and syntax highlighting.
  #
  # @param [IL::Program] program The program to print.
  def print_program(program)
    num_col_len = program.length.to_s.length
    program.item_list.each_with_index { |item, i|
      padi = left_pad(i.to_s, num_col_len, " ")
      # TODO: bright green probably only looks good with solarized dark
      puts("#{ANSI.fmt(padi, color: ANSI::GREEN_BRIGHT)} #{@visitor.visit(item)}")
    }
  end

  sig { params(blocks: T::Array[Analysis::BB::Block]).void }
  # Pretty-print a collection of basic blocks (+Analysis::BB::Block+)
  # to the terminal with headers for each block and syntax highlighting.
  #
  # @param [T::Array[Analysis::BB::Block]] blocks The array of blocks to print.
  def print_blocks(blocks)
    blocks.each { |b|
      puts(ANSI.fmt("[BLOCK (len=#{b.length})]", bold: true))
      b.each_stmt_with_index { |s, i|
        puts(@visitor.visit(s))
      }
    }
  end

  protected

  VISIT_TYPE = T.let(-> (v, o, c) {
    ANSI.fmt(o.to_s, color: ANSI::YELLOW)
  }, Visitor::Lambda)

  VISIT_VALUE = T.let(-> (v, o, c) {
    ANSI.fmt(o.to_s, color: ANSI::MAGENTA)
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o, c) {
    "#{ANSI.fmt(o.name, color: ANSI::BLUE)}##{o.number}"
  }, Visitor::Lambda)

  VISIT_REGISTER = T.let(-> (v, o, c) {
    "#{ANSI.fmt(o.name, color: ANSI::BLUE)}"
  }, Visitor::Lambda)

  VISIT_EXPRESSION = T.let(-> (v, o, c) {
    o.to_s # don't format
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o, c) {
    "#{v.visit(o.left)} #{ANSI.fmt(o.op, color: ANSI::GREEN)} #{v.visit(o.right)}"
  }, Visitor::Lambda)

  VISIT_STATEMENT = T.let(-> (v, o, c) {
    o.to_s # don't format
  }, Visitor::Lambda)

  VISIT_DEFINITION = T.let(-> (v, o, c) {
    "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}#{ANSI.fmt(" \" #{o.annotation}", color: ANSI::GREEN_BRIGHT) unless not o.annotation}"
  }, Visitor::Lambda)

  VISIT_LABEL = T.let(-> (v, o, c) {
    "#{ANSI.fmt("#{o.name}:", color: ANSI::CYAN)}#{ANSI.fmt(" \" #{o.annotation}", color: ANSI::GREEN_BRIGHT) unless not o.annotation}"
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o, c) {
    "#{ANSI.fmt("jmp", color: ANSI::RED)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}#{ANSI.fmt(" \" #{o.annotation}", color: ANSI::GREEN_BRIGHT) unless not o.annotation}"
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o, c) {
    "#{ANSI.fmt("jz", color: ANSI::RED)} #{v.visit(o.cond)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}#{ANSI.fmt(" \" #{o.annotation}", color: ANSI::GREEN_BRIGHT) unless not o.annotation}"
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o, c) {
    "#{ANSI.fmt("jnz", color: ANSI::RED)} #{v.visit(o.cond)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}#{ANSI.fmt(" \" #{o.annotation}", color: ANSI::GREEN_BRIGHT) unless not o.annotation}"
  }, Visitor::Lambda)


  VISIT_LAMBDAS = T.let({
    IL::Type => VISIT_TYPE,
    IL::Value => VISIT_VALUE,
    IL::ID => VISIT_ID,
    IL::Register => VISIT_REGISTER,
    IL::Expression => VISIT_EXPRESSION,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::Statement => VISIT_STATEMENT,
    IL::Definition => VISIT_DEFINITION,
    IL::Label => VISIT_LABEL,
    IL::Jump => VISIT_JUMP,
    IL::JumpZero => VISIT_JUMPZERO,
    IL::JumpNotZero => VISIT_JUMPNOTZERO,
  }, Visitor::LambdaHash)

  private

  sig { params(str: String, len: Integer, pad: String).returns(String) }
  def left_pad(str, len, pad)
    while str.length < len
      str = pad + str
    end

    return str
  end
end
