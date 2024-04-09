# typed: strict
require "sorbet-runtime"
require_relative "frontend"
require_relative "../il"
require_relative "../visitor"

class Frontend::Generator
  extend T::Sig

  include IL

  sig { params(program: Program).void }
  def initialize(program)
    @program = program
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
  end

  sig { returns(String) }
  def generate
    output = ""

    @program.each_func { |f|
      output += @visitor.visit(f)
    }
    @program.stmt_list.each { |s|
      output += "#{@visitor.visit(s)}\n"
    }

    return output
  end

  private

  VISIT_TYPE = T.let(-> (v, o, c) {
    o.to_s
  }, Visitor::Lambda)

  VISIT_CONSTANT = T.let(-> (v, o, c) {
    "#{o.value}#{v.visit(o.type)}"
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o, c) {
    "#{o.name}##{o.number}"
  }, Visitor::Lambda)

  VISIT_REGISTER = T.let(-> (v, o, c) {
    "%#{o.number}"
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o, c) {
    "#{v.visit(o.left)} #{o.op} #{v.visit(o.right)}"
  }, Visitor::Lambda)

  VISIT_UNARYOP = T.let(-> (v, o, c) {
    "#{o.op} #{v.visit(o.value)}"
  }, Visitor::Lambda)

  VISIT_PHI = T.let(-> (v, o, c) {
    val_str = ""
    o.values.each { |val|
      val_str += "#{v.visit(val)}, "
    }
    val_str.chomp!(", ")

    "phi (#{val_str})"
  }, Visitor::Lambda)

  VISIT_DEFINITION = T.let(-> (v, o, c) {
    "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}"
  }, Visitor::Lambda)

  VISIT_LABEL = T.let(-> (v, o, c) {
    "#{o.name}:"
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o, c) {
    "jmp #{o.target}"
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o, c) {
    "jz #{v.visit(o.cond)} #{o.target}"
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o, c) {
    "jnz #{v.visit(o.cond)} #{o.target}"
  }, Visitor::Lambda)

  VISIT_RETURN = T.let(-> (v, o, c) {
    "ret #{v.visit(o.value)}"
  }, Visitor::Lambda)

  VISIT_FUNCPARAM = T.let(-> (v, o, c) {
    "#{v.visit(o.type)} #{v.visit(o.id)}"
  }, Visitor::Lambda)

  VISIT_FUNCDEF = T.let(-> (v, o, c) {
    param_str = ""
    o.params.each { |p|
      param_str += "#{v.visit(p)}, "
    }
    param_str.chomp!(", ")

    stmt_str = ""
    o.stmt_list.each { |s|
      stmt_str += "\n#{v.visit(s)}" # newline at front make it easier
    }

    "func #{o.name} (#{param_str}) -> #{v.visit(o.ret_type)}#{stmt_str}\nend\n"
  }, Visitor::Lambda)

  VISIT_CALL = T.let(-> (v, o, c) {
    arg_str = ""
    o.args.each { |a|
      arg_str += "#{v.visit(a)}, "
    }
    arg_str.chomp!(", ")

    "call #{o.func_name} (#{arg_str})"
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    IL::Type => VISIT_TYPE,
    IL::Constant => VISIT_CONSTANT,
    IL::ID => VISIT_ID,
    IL::Register => VISIT_REGISTER,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::UnaryOp => VISIT_UNARYOP,
    IL::Phi => VISIT_PHI,
    IL::Definition => VISIT_DEFINITION,
    IL::Label => VISIT_LABEL,
    IL::Jump => VISIT_JUMP,
    IL::JumpZero => VISIT_JUMPZERO,
    IL::JumpNotZero => VISIT_JUMPNOTZERO,
    IL::Return => VISIT_RETURN,
    IL::FuncParam => VISIT_FUNCPARAM,
    IL::FuncDef => VISIT_FUNCDEF,
    IL::Call => VISIT_CALL,
  }, Visitor::LambdaHash)
end
