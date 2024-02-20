# typed: strict
require "sorbet-runtime"
require_relative "debugger"
require_relative "ansi"
require_relative "../il"
require_relative "../visitor"
require_relative "../optimization/bb"

class Debugger::PrettyPrinter
  extend T::Sig

  sig { void }
  def initialize
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
  end

  sig { params(program: IL::Program).void }
  def print_program(program)
    num_col_len = program.length.to_s.length
    program.each_stmt_with_index { |s, i|
      padi = left_pad(i.to_s, num_col_len, " ")
      # TODO: bright green probably only looks good with solarized dark
      puts("#{ANSI.fmt(padi, color: ANSI::GREEN_BRIGHT)} #{@visitor.visit([s])}")
    }
  end

  sig { params(blocks: T::Array[BB::Block]).void }
  def print_blocks(blocks)
    blocks.each { |b|
      puts(ANSI.fmt("[BLOCK (len=#{b.length})]", bold: true))
      b.each_stmt_with_index { |s, i|
        puts(@visitor.visit([s]))
      }
    }
  end

  protected

  VISIT_TYPE = T.let(-> (v, o) {
    ANSI.fmt(o[0].to_s, color: ANSI::YELLOW)
  }, Visitor::Lambda)

  VISIT_VALUE = T.let(-> (v, o) {
    ANSI.fmt(o[0].to_s, color: ANSI::MAGENTA)
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o) {
    ANSI.fmt(o[0].to_s, color: ANSI::BLUE)
  }, Visitor::Lambda)

  VISIT_EXPRESSION = T.let(-> (v, o) {
    o[0].to_s # don't format
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o) {
    "#{v.visit([o[0].left])} #{ANSI.fmt(o[0].op, color: ANSI::GREEN)} #{v.visit([o[0].right])}"
  }, Visitor::Lambda)

  VISIT_STATEMENT = T.let(-> (v, o) {
    o[0].to_s # don't format
  }, Visitor::Lambda)

  VISIT_DECLARATION = T.let(-> (v, o) {
    "#{v.visit([o[0].type])} #{v.visit([o[0].id])} = #{v.visit([o[0].rhs])}"
  }, Visitor::Lambda)

  VISIT_ASSIGNMENT = T.let(-> (v, o) {
    "#{v.visit([o[0].id])} = #{v.visit([o[0].rhs])}"
  }, Visitor::Lambda)

  VISIT_LABEL = T.let(-> (v, o) {
    ANSI.fmt(o[0].to_s, color: ANSI::CYAN)
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o) {
    "#{ANSI.fmt("jmp", color: ANSI::RED)} #{ANSI.fmt(o[0].target, color: ANSI::CYAN)}"
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o) {
    "#{ANSI.fmt("jz", color: ANSI::RED)} #{v.visit([o[0].cond])} #{ANSI.fmt(o[0].target, color: ANSI::CYAN)}"
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o) {
    "#{ANSI.fmt("jnz", color: ANSI::RED)} #{v.visit([o[0].cond])} #{ANSI.fmt(o[0].target, color: ANSI::CYAN)}"
  }, Visitor::Lambda)


  VISIT_LAMBDAS = T.let({
    IL::Type => VISIT_TYPE,
    IL::Value => VISIT_VALUE,
    IL::ID => VISIT_ID,
    IL::Expression => VISIT_EXPRESSION,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::Statement => VISIT_STATEMENT,
    IL::Declaration => VISIT_DECLARATION,
    IL::Assignment => VISIT_ASSIGNMENT,
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
