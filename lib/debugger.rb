# typed: strict
require "sorbet-runtime"
require_relative "il"
require_relative "visitor"
require_relative "analysis/bb"

module ANSI
  extend T::Sig

  DEFAULT = 39
  BLACK = 30
  RED = 31
  GREEN = 32
  YELLOW = 33
  BLUE = 34
  MAGENTA = 35
  CYAN = 36
  WHITE = 37
  BLACK_BRIGHT = 90
  RED_BRIGHT = 91
  GREEN_BRIGHT = 92
  YELLOW_BRIGHT = 93
  BLUE_BRIGHT = 94
  MAGENTA_BRIGHT = 95
  CYAN_BRIGHT = 96
  WHITE_BRIGHT = 97

  sig { params(obj: Object, color: Integer, bold: T::Boolean).returns(String) }
  def self.fmt(obj, color: ANSI::DEFAULT, bold: false)
    "\e[#{color}m#{"\e[1m" unless not bold}#{obj.to_s}\e[0m"
  end
end

module Debugger
  # stub
end

class Debugger::PrettyPrinter
  extend T::Sig

  VISIT_TYPE = T.let(-> (v, o) {
    ANSI.fmt(o.to_s, color: ANSI::YELLOW)
  }, Visitor::LAMBDA)

  VISIT_VALUE = T.let(-> (v, o) {
    ANSI.fmt(o.to_s, color: ANSI::MAGENTA)
  }, Visitor::LAMBDA)

  VISIT_ID = T.let(-> (v, o) {
    ANSI.fmt(o.to_s, color: ANSI::BLUE)
  }, Visitor::LAMBDA)

  VISIT_EXPRESSION = T.let(-> (v, o) {
    o.to_s # don't format
  }, Visitor::LAMBDA)

  VISIT_BINARYOP = T.let(-> (v, o) {
    "#{v.visit(o.left)} #{ANSI.fmt(o.op, color: ANSI::GREEN)} #{v.visit(o.right)}"
  }, Visitor::LAMBDA)

  VISIT_STATEMENT = T.let(-> (v, o) {
    o.to_s # don't format
  }, Visitor::LAMBDA)

  VISIT_DECLARATION = T.let(-> (v, o) {
    "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}"
  }, Visitor::LAMBDA)

  VISIT_ASSIGNMENT = T.let(-> (v, o) {
    "#{v.visit(o.id)} = #{v.visit(o.rhs)}"
  }, Visitor::LAMBDA)

  VISIT_LABEL = T.let(-> (v, o) {
    ANSI.fmt(o.to_s, color: ANSI::CYAN)
  }, Visitor::LAMBDA)

  VISIT_JUMP = T.let(-> (v, o) {
    "#{ANSI.fmt("jmp", color: ANSI::RED)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}"
  }, Visitor::LAMBDA)

  VISIT_JUMPZERO = T.let(-> (v, o) {
    "#{ANSI.fmt("jz", color: ANSI::RED)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}"
  }, Visitor::LAMBDA)

  VISIT_JUMPNOTZERO = T.let(-> (v, o) {
    "#{ANSI.fmt("jnz", color: ANSI::RED)} #{v.visit(o.cond)} #{ANSI.fmt(o.target, color: ANSI::CYAN)}"
  }, Visitor::LAMBDA)


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
  }, Visitor::LAMBDA_HASH)

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
      puts("#{ANSI.fmt(padi, color: ANSI::GREEN_BRIGHT)} #{@visitor.visit(s)}")
    }
  end

  sig { params(blocks: T::Array[BB::Block]).void }
  def print_blocks(blocks)
    blocks.each { |b|
      puts(ANSI.fmt("[BLOCK (len=#{b.length})]", bold: true))
      b.each_stmt_with_index { |s, i|
        puts(@visitor.visit(s))
      }
    }
  end

  private

  sig { params(str: String, len: Integer, pad: String).returns(String) }
  def left_pad(str, len, pad)
    while str.length < len
      str = pad + str
    end

    return str
  end
end
