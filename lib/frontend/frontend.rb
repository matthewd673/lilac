# typed: strict
require_relative "sorbet-runtime"

# The Frontend module contains tools for parsing IL from text files.
module Frontend
  # TokenType is an enum of all the tokens in the grammar.
  class TokenType < T::Enum
    enums do
      Type = new
      IntConst = new
      FloatConst = new
      ID = new
      Register = new
      BinaryOp = new
      UnaryOp = new
      Phi = new
      Assignment = new
      Label = new
      Jump = new
      JumpZero = new
      JumpNotZero = new
      Return = new
      Func = new
      End = new
      LeftParen = new
      RightParen = new
      Arrow = new
      Call = new
    end
  end

  # A TokenDef defines the regular expression for matching a TokenType
  class TokenDef
    extend T::Sig

    sig { returns(TokenType) }
    attr_reader :type

    sig { returns(String) }
    attr_reader :pattern

    sig { params(type: TokenType, pattern: String).void }
    def initialize(type, pattern)
      @type = type
      @pattern = pattern
    end
  end

  # A Position represents the row and column location of a Token in the source
  # text. The first character in the source text is at position +(0, 0)+.
  class Position
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :row

    sig { returns(Integer) }
    attr_reader :col

    sig { params(row: Integer, col: Integer).void }
    def initialize(row, col)
      @row = row
      @col = col
    end
  end

  # A Token represents a token that has been scanned. It has a TokenType,
  # an image String, and a Position.
  class Token
    extend T::Sig

    sig { returns(TokenType) }
    attr_reader :type

    sig { returns(String) }
    attr_reader :image

    sig { returns(Position) }
    attr_reader :position

    sig { params(type: TokenType, image: String, position: Position).void }
    def initialize(type, image, position)
      @type = type
      @image = image
      @position = position
    end
  end
end
