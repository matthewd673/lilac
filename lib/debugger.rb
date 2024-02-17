# typed: true
require "sorbet-runtime"
require_relative "il"

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

  sig { params(str: String, color: Integer).returns(String) }
  def self.colorize(str, color = ANSI::DEFAULT)
    "\e[#{color}m#{str}"
  end
end

module IL::Type
  def self.colorize(str)
    ANSI.colorize(str, ANSI::YELLOW)
  end
end

class IL::Value
  def colorize
    ANSI.colorize(to_s, ANSI::MAGENTA)
  end
end

class IL::ID
  def colorize
    ANSI.colorize(to_s, ANSI::BLUE)
  end
end

class IL::Expression
  def colorize
    ANSI.colorize(to_s)
  end
end

class IL::BinaryOp
  def colorize
    "#{@left.colorize} #{ANSI.colorize(@op, ANSI::GREEN)} #{@right.colorize}"
  end
end

class IL::Statement
  # just print like normal
  def colorize
    ANSI.colorize(to_s)
  end
end

class IL::Declaration
  def colorize
    "#{IL::Type.colorize(@type)} #{@id.colorize} #{ANSI.colorize("=")} #{@rhs.colorize}"
  end
end

class IL::Assignment
  def colorize
    "#{@id.colorize} #{ANSI.colorize("=")} #{@rhs.colorize}"
  end
end

class IL::Label
  def colorize
    "#{ANSI.colorize(to_s, ANSI::CYAN)}"
  end
end

class IL::Jump
  def colorize
    "#{ANSI.colorize("jmp", ANSI::RED)} #{ANSI.colorize(@target, ANSI::CYAN)}"
  end
end

class IL::JumpZero
  def colorize
    "#{ANSI.colorize("jz", ANSI::RED)} #{@cond.colorize} #{ANSI.colorize(@target, ANSI::CYAN)}"
  end
end

class IL::JumpNotZero
  def colorize
    "#{ANSI.colorize("jnz", ANSI::RED)} #{@cond.colorize} #{ANSI.colorize(@target, ANSI::CYAN)}"
  end
end

module Debugger
  extend T::Sig
  include IL

  sig { params(program: Program).void }
  def self.pretty_print(program)
    program.each_stmt { |s|
      puts(s.colorize)
    }
  end
end
