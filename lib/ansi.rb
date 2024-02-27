# typed: strict
require "sorbet-runtime"

# The ANSI module contains constants and helper functions that can be used
# to format text in the terminal.
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

  LILAC_256 = 147

  sig { params(obj: Object, color: Integer, bold: T::Boolean).returns(String) }
  # Format a String using ANSI codes.
  #
  # @param [Integer] color The foreground color of the String. Should be
  #   one of the constants provided in the module.
  # @param [T::Boolean] bold Determines if the String is bold or not.
  #
  # @return [String] The formatted String which can be printed as normal.
  def self.fmt(obj, color: ANSI::DEFAULT, bold: false)
    "\e[#{color}m#{"\e[1m" unless not bold}#{obj.to_s}\e[0m"
  end

  sig { params(obj: Object, color: Integer, bold: T::Boolean).returns(String) }
  # Format a String using 256-color.
  #
  # @param [Integer] color The number of the color in the xterm-256 color table.
  # @param [T::Boolean] bold Determines if the String is bold or not.
  def self.fmt256(obj, color, bold: false)
    "\e[38;5;#{color}m#{"\e[1m" unless not bold}#{obj.to_s}\e[0m"
  end
end
