# typed: true
# NOTE: sorbet doesn't support refinements which are used in Interpreter
require "sorbet-runtime"
require_relative "il"
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
  extend T::Sig
end

module Debugger::PrettyPrinter
  extend T::Sig

  sig { params(program: IL::Program).void }
  def self.print_program(program)
    num_col_len = program.length.to_s.length
    program.each_stmt_with_index { |s, i|
      padi = left_pad(i.to_s, num_col_len, " ")
      # TODO: bright green probably only looks good with solarized dark
      puts("#{ANSI.fmt(padi, color: ANSI::GREEN_BRIGHT)} #{s.colorize}")
    }
  end

  sig { params(blocks: T::Array[BB::Block]).void }
  def self.print_blocks(blocks)
    blocks.each { |b|
      puts(ANSI.fmt("[BLOCK (len=#{b.length})]", bold: true))
      b.each_stmt_with_index { |s, i|
        puts(s.colorize)
      }
    }
    print(ANSI.fmt("")) # reset to default color
  end

  protected

  refine IL::Type do
    sig { params(str: String).returns(String) }
    def self.colorize(str)
      ANSI.fmt(str, color: ANSI::YELLOW)
    end
  end

  refine IL::Value do
    sig { returns(String) }
    def colorize
      ANSI.fmt(to_s, color: ANSI::MAGENTA)
    end
  end

  refine IL::ID do
    sig { returns(String) }
    def colorize
      ANSI.fmt(to_s, color: ANSI::BLUE)
    end
  end

  refine IL::Expression do
    sig { returns(String) }
    def colorize
      ANSI.fmt(to_s) # don't highlight
    end
  end

  refine IL::BinaryOp do
    sig { returns(String) }
    def colorize
      "#{@left.colorize} #{ANSI.fmt(@op, color: ANSI::GREEN)} #{@right.colorize}"
    end
  end

  refine IL::Statement do
    sig { returns(String) }
    def colorize
      ANSI.fmt(to_s) # just print in default color
    end
  end

  refine IL::Declaration do
    sig { returns(String) }
    def colorize
      "#{IL::Type.colorize(@type)} #{@id.colorize} #{ANSI.fmt("=")} #{@rhs.colorize}"
    end
  end

  refine IL::Assignment do
    sig { returns(String) }
    def colorize
      "#{@id.colorize} #{ANSI.fmt("=")} #{@rhs.colorize}"
    end
  end

  refine IL::Label do
    sig { returns(String) }
    def colorize
      "#{ANSI.fmt(to_s, color: ANSI::CYAN)}"
    end
  end

  refine IL::Jump do
    sig { returns(String) }
    def colorize
      "#{ANSI.fmt("jmp", color: ANSI::RED)} #{ANSI.fmt(@target, color: ANSI::CYAN)}"
    end
  end

  refine IL::JumpZero do
    sig { returns(String) }
    def colorize
      "#{ANSI.fmt("jz", color: ANSI::RED)} #{@cond.colorize} #{ANSI.fmt(@target, color: ANSI::CYAN)}"
    end
  end

  refine IL::JumpNotZero do
    sig { returns(String) }
    def colorize
      "#{ANSI.fmt("jnz", color: ANSI::RED)} #{@cond.colorize} #{ANSI.fmt(@target, color: ANSI::CYAN)}"
    end
  end

  private

  sig { params(str: String, len: Integer, pad: String).returns(String) }
  def self.left_pad(str, len, pad)
    while str.length < len
      str = pad + str
    end

    return str
  end
end
