# typed: strict
require "sorbet-runtime"

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
