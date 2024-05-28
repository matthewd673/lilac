# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../ansi"
require_relative "../il"
require_relative "../visitor"
require_relative "../analysis/bb"

module Lilac
  module Debugging
    # A PrettyPrinter contains functions that make it easy to pretty-print
    # various internal Lilac data structures, like +IL::Program+, to the
    # terminal.
    class PrettyPrinter
      extend T::Sig

      # A Map representing the color palette used by PrettyPrinter.
      PALETTE = T.let({
        # IL node colors
        IL::Type::Type => ANSI::YELLOW,
        IL::Constant => ANSI::MAGENTA,
        IL::ID => ANSI::BLUE,
        IL::Register => ANSI::BLUE,
        IL::BinaryOp => ANSI::GREEN,
        IL::Label => ANSI::CYAN,
        IL::Jump => ANSI::RED,
        # Additional colors
        :gutter => ANSI::BLACK_BRIGHT,
        :annotation => ANSI::BLACK_BRIGHT,
      }.freeze, T::Hash[T.untyped, Integer])

      sig { void }
      # Construct a new PrettyPrinter.
      def initialize
        @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
      end

      sig { params(program: IL::Program).void }
      # Pretty-print the statements in an +IL::Program+ to the terminal with
      # line numbers and syntax highlighting.
      #
      # @param [IL::Program] program The program to print.
      def print_program(program)
        # approximate total line count for gutter length
        approx_lines = program.stmt_list.length
        program.each_extern_func do |f|
          approx_lines += 1
        end
        program.each_func do |f|
          approx_lines += f.stmt_list.length + 2
        end

        # create context
        gutter_len = approx_lines.to_s.length
        ctx = PrettyPrinterContext.new(gutter_len, 0, 0)

        # print all lines
        program.each_extern_func do |f|
          puts(@visitor.visit(f, ctx:))
          ctx.line_num += 1
        end
        program.each_func do |f|
          puts(@visitor.visit(f, ctx:))
          ctx.line_num += 1
        end
        program.stmt_list.each do |s|
          puts(@visitor.visit(s, ctx:))
          ctx.line_num += 1
        end
      end

      sig { params(blocks: T::Array[Analysis::BB]).void }
      # Pretty-print a collection of basic blocks (+Analysis::BB::Block+)
      # to the terminal with headers for each block and syntax highlighting.
      #
      # @param [T::Array[Analysis::BB::Block]] blocks The array of blocks to
      #   print.
      def print_blocks(blocks)
        blocks.each do |b|
          puts(ANSI.fmt("[#{b.id} (len=#{b.length})]", bold: true))
          b.stmt_list.each_with_index do |s, i|
            puts(@visitor.visit(s))
          end
        end
      end

      private

      # A visit context used internally by the PrettyPrinter Visitor.
      PrettyPrinterContext = Struct.new(:gutter_len, :line_num, :indent)
      private_constant :PrettyPrinterContext

      VISIT_LAMBDAS = T.let({
        IL::Type::Type => lambda { |v, o, c|
          ANSI.fmt(o.to_s, color: PALETTE[IL::Type::Type])
        },
        IL::Constant => lambda { |v, o, c|
          if o.type.eql?(IL::Type::Void)
            ANSI.fmt("void", color: PALETTE[IL::Constant])
          else
            ANSI.fmt(o.to_s, color: PALETTE[IL::Constant])
          end
        },
        IL::ID => lambda { |v, o, c|
          ANSI.fmt(o.name, color: PALETTE[IL::ID])
        },
        IL::Register => lambda { |v, o, c|
          ANSI.fmt(o.name, color: PALETTE[IL::Register])
        },
        IL::BinaryOp => lambda { |v, o, c|
          "#{v.visit(o.left)} "\
          "#{ANSI.fmt(o.op, color: PALETTE[IL::BinaryOp])} "\
          "#{v.visit(o.right)}"
        },
        IL::Call => lambda { |v, o, c|
          s = "#{ANSI.fmt("call", bold: true)} #{o.func_name}("
          o.args.each do |a|
            s += "#{v.visit(a)}, "
          end
          s.chomp!(", ")
          s += ")"
        },
        IL::ExternCall => lambda  { |v, o, c|
          s = "#{ANSI.fmt("extern call", bold: true)} "\
              "#{o.func_source} #{o.func_name}("
          o.args.each do |a|
            s += "#{v.visit(a)}, "
          end
          s.chomp!(", ")
          s += ")"

          s
        },
        IL::Definition => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{v.visit(o.type)} #{v.visit(o.id)} = #{v.visit(o.rhs)}"

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::Label => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += ANSI.fmt("#{o.name}:", color: PALETTE[IL::Label])

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::Jump => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{ANSI.fmt("jmp", color: PALETTE[IL::Jump])} "
          s += ANSI.fmt(o.target, color: PALETTE[IL::Label])

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::JumpZero => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{ANSI.fmt("jz", color: PALETTE[IL::Jump])} "\
               "#{v.visit(o.cond)} "\
               "#{ANSI.fmt(o.target, color: PALETTE[IL::Label])}"

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::JumpNotZero => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{ANSI.fmt("jnz", color: PALETTE[IL::Jump])} "\
               "#{v.visit(o.cond)} "\
               "#{ANSI.fmt(o.target, color: PALETTE[IL::Label])}"

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::Return => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{ANSI.fmt("ret", bold: true)} #{v.visit(o.value)}"

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::VoidCall => lambda { |v, o, c|
          # line number and indent
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          pad = indent(c.indent)
          s = ANSI.fmt(num, color: PALETTE[:gutter]) + pad

          s += "#{ANSI.fmt("void", bold: true)} #{v.visit(o.call)}"

          # annotation
          if o.annotation
            s += ANSI.fmt(" \" #{o.annotation}", color: PALETTE[:annotation])
          end

          s
        },
        IL::FuncDef => lambda { |v, o, c|
          # line number
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          c.line_num += 1
          s = ANSI.fmt(num, color: PALETTE[:gutter])

          s += "#{ANSI.fmt("func", bold: true)} #{o.name}("

          # print params
          o.params.each do |p|
            s += "#{v.visit(p.type)} #{v.visit(p.id)}, "
          end
          s.chomp!(", ")

          s += ") -> #{v.visit(o.ret_type)}\n"

          # print body
          c.indent = 1
          o.stmt_list.each do |stmt|
            s += "#{v.visit(stmt, ctx: c)}\n"
            c.line_num += 1
          end

          # fix line number and indent
          c.line_num -= 1
          c.indent = 0

          # print end
          new_num = left_pad(c.line_num.to_s, c.gutter_len)
          s += "#{ANSI.fmt(new_num, color: PALETTE[:gutter])} "
          s += ANSI.fmt("end", bold: true).to_s

          s
        },
        IL::FuncParam => lambda { |v, o, c|
          "#{v.visit(o.type)} #{v.visit(o.id)}"
        },
        IL::ExternFuncDef => lambda { |v, o, c|
          # line number
          num = "#{left_pad(c.line_num.to_s, c.gutter_len)} "
          c.line_num += 1
          s = ANSI.fmt(num, color: PALETTE[:gutter])

          s += "#{ANSI.fmt("extern func", bold: true)} #{o.source} #{o.name}("

          # print param types
          o.param_types.each do |t|
            s += "#{v.visit(t)}, "
          end
          s.chomp!(", ")

          s += ") -> #{v.visit(o.ret_type)}\n"

          # fix line number and indent
          c.line_num -= 1
          c.indent = 0
          s
        },
      }.freeze, Visitor::LambdaHash)
      private_constant :VISIT_LAMBDAS

      sig { params(str: String, len: Integer, pad: String).returns(String) }
      def self.left_pad(str, len, pad: " ")
        while str.length < len
          str = pad + str
        end

        str
      end

      sig { params(indent: Integer).returns(String) }
      def self.indent(indent)
        str = ""

        (1..indent).each do |i|
          str += "  "
        end

        str
      end
    end
  end
end
