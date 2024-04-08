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
      FuncName = new
      End = new
      LeftParen = new
      RightParen = new
      Arrow = new
      Call = new

      # special tokens
      NewLine = new
      EOF = new
    end
  end

  # A TokenDef defines the regular expression for matching a TokenType
  class TokenDef
    extend T::Sig

    sig { returns(TokenType) }
    attr_reader :type

    sig { returns(Regexp) }
    attr_reader :pattern

    sig { params(type: TokenType, pattern: Regexp).void }
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

  TOKEN_DEFS = T.let([
    TokenDef.new(TokenType::Type, /u8|i16|i32|i64|f32|f64/),
    TokenDef.new(TokenType::IntConst, /[0-9]+/),
    TokenDef.new(TokenType::FloatConst, /([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+)/),
    # NOTE: pretty much anything goes for ID names, this is just a
    # reasonably-broad subset of what the internal IL checks will actually
    # allow
    TokenDef.new(TokenType::ID, /[\w!@$^&*()\-+=\[\]:;"',.?\/<>]+#[0-9]+/),
    TokenDef.new(TokenType::Register, /%[0-9]+/),
    TokenDef.new(TokenType::BinaryOp, /\+|-|\*|\/|==|!=|<|>|<=|>=|\|\||\&\&/),
    # NOTE: -@ isn't really standard anywhere else but it will make things
    # much easier here
    TokenDef.new(TokenType::UnaryOp, /-@/),
    TokenDef.new(TokenType::Phi, /phi/),
    TokenDef.new(TokenType::Assignment, /=/),
    # NOTE: again, actual permitted label names are very broad in the IL
    # (broader than ID names, in fact)
    TokenDef.new(TokenType::Label, /[\w!@$^&*()\-+=\[\]:;"',.?\/<>]+:/),
    TokenDef.new(TokenType::Jump, /jmp/),
    TokenDef.new(TokenType::JumpZero, /jz/),
    TokenDef.new(TokenType::JumpNotZero, /jnz/),
    TokenDef.new(TokenType::Return, /ret/),
    TokenDef.new(TokenType::Func, /func/),
    # NOTE: parentheses are absent here to make parsing easier (but of course
    # that isn't actually enforced in the IL)
    TokenDef.new(TokenType::FuncName, /[\w!@$^&*\-+=\[\]:;"',.?\/<>]+/),
    TokenDef.new(TokenType::End, /end/),
    TokenDef.new(TokenType::LeftParen, /\(/),
    TokenDef.new(TokenType::RightParen, /\)/),
    TokenDef.new(TokenType::Arrow, /->/),
    TokenDef.new(TokenType::Call, /call/),
    # NOTE: TokenType::NewLine and ::EOF are special and do not need a TokenDef
  ], T::Array[TokenDef])
end
