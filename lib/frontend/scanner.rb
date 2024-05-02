# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "frontend"

module Frontend
  # A Scanner tokenizes an input string. NOTE: Scanner is adapted from Newt's
  # Scanner class.
  class Scanner
    extend T::Sig

    include Frontend

    sig { params(string: String).void }
    def initialize(string)
      @string = string

      @scan_row = T.let(0, Integer)
      @scan_col = T.let(0, Integer)
    end

    sig { returns(Token) }
    def scan_next
      # strip whitespace
      saw_nl = strip_whitespace
      pos = Position.new(@scan_row, @scan_col)

      # return newline if it was stripped
      # this is necessary because newlines are used to denote end of statement
      if saw_nl
        return Token.new(TokenType::NewLine, "\n", pos)
      end

      # return end of file once we reach it
      if @string.empty?
        return Token.new(TokenType::EOF, "$$", pos)
      end

      # find best possible token match from defs list
      best = T.let(nil, T.nilable(Token))
      TOKEN_DEFS.each do |t|
        # find first match
        m = t.pattern.match(@string)

        # skip if no match or match is not at beginning of string
        if !m || !m[0] || m.begin(0) > 0
          next
        end

        # something is always better than nothing
        unless best
          best = Token.new(t.type, T.unsafe(m[0]), pos)
          next
        end

        # check if this is better than current best (longer is better)
        if m.length > best.image.length
          best = Token.new(t.type, T.unsafe(m[0]), pos)
        end
      end

      unless best
        raise("Invalid symbol: '#{@string[0]}'") # TODO: nicer errors
      end

      # trim best match from string and return
      @string.delete_prefix!(best.image)
      @scan_row += best.image.length

      best
    end

    private

    sig { returns(T::Boolean) }
    def strip_whitespace
      saw_nl = T.let(false, T::Boolean)
      loop do
        if @string.start_with?(" ")
          @string.delete_prefix!(" ")
          @scan_row += 1
        elsif @string.start_with?("\n")
          @string.delete_prefix!("\n")
          @scan_row = 0
          @scan_col += 1
          saw_nl = true
        elsif @string.start_with?("\r")
          @string.delete_prefix!("\r")
        elsif @string.start_with?("\t")
          @string.delete_prefix!("\t")
          @scan_row += 1 # NOTE: assume tab size = 1
        # trim annotations
        elsif @string.start_with?("\"")
          while !@string.empty? && @string[0] != "\n"
            @string = T.unsafe(@string[1..])

            # stop if @string turns nil, which Sorbet says is possible
            unless @string
              return saw_nl
            end
          end
        else
          break
        end
      end
      saw_nl
    end
  end
end
