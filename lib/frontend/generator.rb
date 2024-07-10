# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../il"
require_relative "../visitor"

module Lilac
  module Frontend
    # A Generator generates human-readable IL source code for programs. The
    # output of a Generator can be parsed by a +Parser+ without any
    # modification.
    class Generator
      extend T::Sig

      include IL

      sig { params(program: Program).void }
      # Construct a new Generator for the given program.
      #
      # @param [Program] program The program to generate source code for.
      def initialize(program)
        @program = program
        @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
      end

      sig { returns(String) }
      # Generate a String containing the IL source code of the Generator's
      # program.
      #
      # @return [String] A String containing valid IL source code.
      def generate
        output = ""

        @program.each_global do |g|
          output += @visitor.visit(g)
        end

        @program.each_extern_func do |f|
          output += @visitor.visit(f)
        end

        @program.each_func do |f|
          output += @visitor.visit(f)
        end

        output
      end

      private

      VISIT_TYPE = T.let(lambda { |v, o, c|
        o.to_s
      }, Visitor::Lambda)

      VISIT_CONSTANT = T.let(lambda { |v, o, c|
        "#{o.value}#{v.visit(o.type)}"
      }, Visitor::Lambda)

      VISIT_ID = T.let(lambda { |v, o, c|
        "$#{o.name}"
      }, Visitor::Lambda)

      VISIT_REGISTER = T.let(lambda { |v, o, c|
        "%#{o.number}"
      }, Visitor::Lambda)

      VISIT_GLOBALID = T.let(lambda { |v, o, c|
        "@#{o.name}"
      }, Visitor::Lambda)

      VISIT_BINARYOP = T.let(lambda  { |v, o, c|
        "#{v.visit(o.left)} #{o.op} #{v.visit(o.right)}"
      }, Visitor::Lambda)

      VISIT_UNARYOP = T.let(lambda { |v, o, c|
        "#{o.op} #{v.visit(o.value)}"
      }, Visitor::Lambda)

      VISIT_PHI = T.let(lambda { |v, o, c|
        val_str = "".dup
        o.ids.each do |id|
          val_str += "#{v.visit(id)}, "
        end
        val_str.chomp!(", ")

        "phi (#{val_str})"
      }, Visitor::Lambda)

      VISIT_DEFINITION = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}#{annotation}"
      }, Visitor::Lambda)

      VISIT_LABEL = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "#{o.name}:#{annotation}"
      }, Visitor::Lambda)

      VISIT_JUMP = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "jmp #{o.target}#{annotation}"
      }, Visitor::Lambda)

      VISIT_JUMPZERO = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "jz #{v.visit(o.cond)} #{o.target}#{annotation}"
      }, Visitor::Lambda)

      VISIT_JUMPNOTZERO = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "jnz #{v.visit(o.cond)} #{o.target}#{annotation}"
      }, Visitor::Lambda)

      VISIT_RETURN = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "ret #{v.visit(o.value)}#{annotation}"
      }, Visitor::Lambda)

      VISIT_VOIDCALL = T.let(lambda { |v, o, c|
        annotation = ""
        if o.annotation
          annotation = " \" #{o.annotation}"
        end
        "void #{v.visit(o.call)}#{annotation}"
      }, Visitor::Lambda)

      VISIT_GLOBALDEF = T.let(lambda { |v, o, c|
        "global #{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}"
      }, Visitor::Lambda)

      VISIT_FUNCDEF = T.let(lambda { |v, o, c|
        param_str = "".dup
        o.params.each do |p|
          param_str += "#{v.visit(p)}, "
        end
        param_str.chomp!(", ")

        stmt_str = ""
        o.stmt_list.each do |s|
          stmt_str += "\n#{v.visit(s)}" # newline at front make it easier
        end

        "func #{o.name} (#{param_str}) -> #{v.visit(o.ret_type)}"\
        "#{stmt_str}\nend\n"
      }, Visitor::Lambda)

      VISIT_FUNCPARAM = T.let(lambda { |v, o, c|
        "#{v.visit(o.type)} #{v.visit(o.id)}"
      }, Visitor::Lambda)

      VISIT_EXTERNFUNCDEF = T.let(lambda { |v, o, c|
        param_type_str = ""
        o.param_types.each do |t|
          param_type_str += "#{v.visit(t)}, "
        end
        param_type_str.chomp!(", ")

        "extern func #{o.source} #{o.name} (#{param_type_str}) -> "\
        "#{v.visit(o.ret_type)}\n"
      }, Visitor::Lambda)

      VISIT_CALL = T.let(lambda { |v, o, c|
        arg_str = "".dup
        o.args.each do |a|
          arg_str += "#{v.visit(a)}, "
        end
        arg_str.chomp!(", ")

        "call #{o.func_name} (#{arg_str})"
      }, Visitor::Lambda)

      VISIT_EXTERNCALL = T.let(lambda { |v, o, c|
        arg_str = ""
        o.args.each do |a|
          arg_str += "#{v.visit(a)}, "
        end
        arg_str.chomp!(", ")

        "extern call #{o.func_source} #{o.func_name} (#{arg_str})"
      }, Visitor::Lambda)

      VISIT_INLINEASSEMBLY = T.let(lambda { |v, o, c|
        "asm #{o.gen_format} `#{o.code}`"
      }, Visitor::Lambda)

      VISIT_LAMBDAS = T.let({
        IL::Types::Type => VISIT_TYPE,
        IL::Constant => VISIT_CONSTANT,
        IL::ID => VISIT_ID,
        IL::Register => VISIT_REGISTER,
        IL::GlobalID => VISIT_GLOBALID,
        IL::BinaryOp => VISIT_BINARYOP,
        IL::UnaryOp => VISIT_UNARYOP,
        IL::Phi => VISIT_PHI,
        IL::Definition => VISIT_DEFINITION,
        IL::Label => VISIT_LABEL,
        IL::Jump => VISIT_JUMP,
        IL::JumpZero => VISIT_JUMPZERO,
        IL::JumpNotZero => VISIT_JUMPNOTZERO,
        IL::Return => VISIT_RETURN,
        IL::VoidCall => VISIT_VOIDCALL,
        IL::GlobalDef => VISIT_GLOBALDEF,
        IL::FuncDef => VISIT_FUNCDEF,
        IL::FuncParam => VISIT_FUNCPARAM,
        IL::ExternFuncDef => VISIT_EXTERNFUNCDEF,
        IL::Call => VISIT_CALL,
        IL::ExternCall => VISIT_EXTERNCALL,
      }.freeze, Visitor::LambdaHash)
    end
  end
end
