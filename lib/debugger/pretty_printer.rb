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

  # A Map representing the color palette used by PrettyPrinter.
  PALETTE = T.let({
    # IL node colors
    IL::Type => ANSI::YELLOW,
    IL::Constant => ANSI::MAGENTA,
    IL::ID => ANSI::BLUE,
    IL::Register => ANSI::BLUE,
    IL::BinaryOp => ANSI::GREEN,
    IL::Label => ANSI::CYAN,
    IL::Jump => ANSI::RED,
    # Additional colors
    :gutter => ANSI::GREEN_BRIGHT, # TODO: only looks good with solarized dark
    :annotation => ANSI::GREEN_BRIGHT,
  }, T::Hash[T.untyped, Integer])

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
    gutter_len = program.stmt_list.length.to_s.length
    ctx = PrettyPrinterContext.new(gutter_len, 0, 0)
    program.each_func { |f|
      puts(@visitor.visit(f, ctx: ctx))
      ctx.line_number += 1 # TODO: is this right?
    }
    program.stmt_list.each { |s|
      puts(@visitor.visit(s, ctx: ctx))
      ctx.line_num += 1
    }
  end

  sig { params(blocks: T::Array[Analysis::BB]).void }
  # Pretty-print a collection of basic blocks (+Analysis::BB::Block+)
  # to the terminal with headers for each block and syntax highlighting.
  #
  # @param [T::Array[Analysis::BB::Block]] blocks The array of blocks to print.
  def print_blocks(blocks)
    blocks.each { |b|
      puts(ANSI.fmt("[BLOCK (len=#{b.length})]", bold: true))
      b.stmt_list.each_with_index { |s, i|
        puts(@visitor.visit(s))
      }
    }
  end

  protected

  # A visit context used internally by the PrettyPrinter Visitor.
  PrettyPrinterContext = Struct.new(:gutter_len, :line_num, :indent)

  VISIT_TYPE = T.let(-> (v, o, c) {
    ANSI.fmt(o.to_s, color: PALETTE[IL::Type])
  }, Visitor::Lambda)

  VISIT_VALUE = T.let(-> (v, o, c) {
    o.to_s # NOTE: stub, don't format
  }, Visitor::Lambda)

  VISIT_CONSTANT = T.let(-> (v, o, c) {
    ANSI.fmt(o.to_s, color: PALETTE[IL::Constant])
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o, c) {
    "#{ANSI.fmt(o.name, color: PALETTE[IL::ID])}##{o.number}"
  }, Visitor::Lambda)

  VISIT_REGISTER = T.let(-> (v, o, c) {
    "#{ANSI.fmt(o.name, color: PALETTE[IL::Register])}"
  }, Visitor::Lambda)

  VISIT_EXPRESSION = T.let(-> (v, o, c) {
    o.to_s # NOTE: stub, don't format
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o, c) {
    s = "#{v.visit(o.left)} "
    s += "#{ANSI.fmt(o.op, color: PALETTE[IL::BinaryOp])} "
    s += v.visit(o.right)
    return s
  }, Visitor::Lambda)

  VISIT_CALL = T.let(-> (v, o, c) {
    s = "#{ANSI.fmt(o.func_name, bold: true)} ("
    o.args.each { |a|
      s += "#{v.visit(a)}, "
    }
    s.chomp!(", ")
    s += ")"
  }, Visitor::Lambda)

  VISIT_STATEMENT = T.let(-> (v, o, c) {
    o.to_s # NOTE: stub, don't format
  }, Visitor::Lambda)

  VISIT_DEFINITION = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}"

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_LABEL = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += ANSI.fmt("#{o.name}:", color: PALETTE[IL::Label])

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += "#{ANSI.fmt("jmp", color: PALETTE[IL::Jump])} "
    s += ANSI.fmt(o.target, color: PALETTE[IL::Label])

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += "#{ANSI.fmt("jz", color: PALETTE[IL::Jump])} "
    s += "#{v.visit(o.cond)} #{ANSI.fmt(o.target, color: PALETTE[IL::Label])}"

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += "#{ANSI.fmt("jnz", color: PALETTE[IL::Jump])} "
    s += "#{v.visit(o.cond)} #{ANSI.fmt(o.target, color: PALETTE[IL::Label])}"

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_RETURN = T.let(-> (v, o, c) {
    # line number and indent
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    pad = indent(c.indent)
    s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

    s += "#{ANSI.fmt("ret", bold: true)} #{v.visit(o.value)}"

    # annotation
    if o.annotation
      s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
    end

    return s
  }, Visitor::Lambda)

  VISIT_FUNCDEF = T.let(-> (v, o, c) {
    # line number
    num = left_pad(c.line_num.to_s, c.gutter_len) + " "
    c.line_num += 1
    s = ANSI.fmt(num, color: PALETTE[:gutter])

    s += "#{ANSI.fmt(o.name, bold: true)} ("

    # print params
    o.params.each { |p|
      s += "#{v.visit(p.type)} #{v.visit(p.id)}, "
    }
    s.chomp!(", ")

    s += ") -> #{v.visit(o.ret_type)}:\n"

    # print body
    c.indent = 1
    o.stmt_list.each { |stmt|
      s += "#{v.visit(stmt, ctx: c)}\n"
      c.line_num += 1
    }

    # fix line number and indent
    c.line_num -= 1
    c.indent = 0
    return s
  }, Visitor::Lambda)

  VISIT_FUNCPARAM = T.let(-> (v, o, c) {
    "#{v.visit(o.type)} #{v.visit(o.id)}"
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    IL::Type => VISIT_TYPE,
    IL::Constant => VISIT_CONSTANT,
    IL::ID => VISIT_ID,
    IL::Register => VISIT_REGISTER,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::Call => VISIT_CALL,
    IL::Statement => VISIT_STATEMENT,
    IL::Definition => VISIT_DEFINITION,
    IL::Label => VISIT_LABEL,
    IL::Jump => VISIT_JUMP,
    IL::JumpZero => VISIT_JUMPZERO,
    IL::JumpNotZero => VISIT_JUMPNOTZERO,
    IL::Return => VISIT_RETURN,
    IL::FuncDef => VISIT_FUNCDEF,
    IL::FuncParam => VISIT_FUNCPARAM,
  }, Visitor::LambdaHash)

  private

  sig { params(str: String, len: Integer, pad: String).returns(String) }
  def self.left_pad(str, len, pad: " ")
    while str.length < len
      str = pad + str
    end

    return str
  end

  sig { params(indent: Integer).returns(String) }
  def self.indent(indent)
    str = ""

    for i in 1..indent
      str += "  "
    end

    return str
  end
end
