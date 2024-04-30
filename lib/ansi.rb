# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

# The ANSI module contains constants and helper functions that can be used
# to format text in the terminal.
module ANSI
  extend T::Sig

  # The terminal's default foreground color.
  DEFAULT = 39
  # Foreground color black (true black).
  BLACK = 30
  # Foreground color red.
  RED = 31
  # Foreground color green.
  GREEN = 32
  # Foreground color yellow.
  YELLOW = 33
  # Foreground color blue.
  BLUE = 34
  # Foreground color magenta.
  MAGENTA = 35
  # Foreground color cyan.
  CYAN = 36
  # Foreground color white ("dark white", light-gray).
  WHITE = 37
  # Foreground color bright black (dark-gray).
  BLACK_BRIGHT = 90
  # Foreground color bright red.
  RED_BRIGHT = 91
  # Foreground color bright green.
  GREEN_BRIGHT = 92
  # Foreground color bright yellow.
  YELLOW_BRIGHT = 93
  # Foreground color bright blue.
  BLUE_BRIGHT = 94
  # Foreground color bright magenta.
  MAGENTA_BRIGHT = 95
  # Foreground color bright cyan.
  CYAN_BRIGHT = 96
  # Foreground color bright white (true white).
  WHITE_BRIGHT = 97

  # A light purple foreground color in 256-color mode.
  # Must be used with +.fmt256+.
  LILAC_256 = 147

  sig do
    params(obj: Object,
           color: T.nilable(Integer),
           bold: T::Boolean)
      .returns(String)
  end
  # Format a String using ANSI codes.
  #
  # @param [T.nilable(Integer)] color The foreground color of the String.
  #   Should be one of the constants provided in the module. If +nil+, then
  #   color will be +ANSI::DEFAULT+.
  # @param [T::Boolean] bold Determines if the String is bold or not.
  #
  # @return [String] The formatted String which can be printed as normal.
  def self.fmt(obj, color: nil, bold: false)
    color ||= ANSI::DEFAULT
    "\e[#{color}m#{"\e[1m" if bold}#{obj.to_s}\e[0m"
  end

  sig { params(obj: Object, color: Integer, bold: T::Boolean).returns(String) }
  # Format a String using 256-color.
  #
  # @param [Integer] color The number of the color in the xterm-256 color table.
  # @param [T::Boolean] bold Determines if the String is bold or not.
  def self.fmt256(obj, color, bold: false)
    "\e[38;5;#{color}m#{"\e[1m" if bold}#{obj.to_s}\e[0m"
  end
end
