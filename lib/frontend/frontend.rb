# typed: strict
require "sorbet-runtime"
require_relative "../il"

# The Frontend module contains tools for parsing IL from text files.
module Frontend
  extend T::Sig

  # TokenType is an enum of all the tokens in the grammar.
  class TokenType < T::Enum
    extend T::Sig

    enums do
      None = new("None")

      Type = new("Type")
      UIntConst = new("UIntConst")
      IntConst = new("IntConst")
      FloatConst = new("FloatConst")
      ID = new("ID")
      Register = new("Register")
      BinaryOp = new("BinaryOp")
      UnaryOp = new("UnaryOp")
      Phi = new("Phi")
      Assignment = new("Assignment")
      Label = new("Label")
      JumpTarget = new("JumpTarget")
      Jump = new("Jump")
      JumpZero = new("JumpZero")
      JumpNotZero = new("JumpNotZero")
      Return = new("Return")
      Func = new("Func")
      FuncName = new("FuncName")
      End = new("End")
      LeftParen = new("LeftParen")
      RightParen = new("RightParen")
      Arrow = new("Arrow")
      Call = new("Call")
      Comma = new("Comma")

      # special tokens
      NewLine = new("NewLine")
      EOF = new("EOF")
    end

    sig { returns(String) }
    def to_s
      serialize
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

    sig { returns(String) }
    def to_s
      "(#{@row}, #{@col})"
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

    sig { returns(String) }
    def to_s
      "#{@type}"
    end
  end

  TOKEN_DEFS = T.let([
    # keywords
    TokenDef.new(TokenType::Type, /u8|i16|i32|i64|f32|f64/),
    TokenDef.new(TokenType::BinaryOp, /\+|-|\*|\/|==|!=|<=|>=|<|>|\|\||\&\&/),
    # NOTE: -@ isn't really standard anywhere else but it will make things
    # much easier here
    TokenDef.new(TokenType::UnaryOp, /-@/),
    TokenDef.new(TokenType::Phi, /phi/),
    TokenDef.new(TokenType::Assignment, /=/),
    TokenDef.new(TokenType::Jump, /jmp/),
    TokenDef.new(TokenType::JumpZero, /jz/),
    TokenDef.new(TokenType::JumpNotZero, /jnz/),
    TokenDef.new(TokenType::Return, /ret/),
    TokenDef.new(TokenType::Func, /func/),
    TokenDef.new(TokenType::End, /end/),
    TokenDef.new(TokenType::LeftParen, /\(/),
    TokenDef.new(TokenType::RightParen, /\)/),
    TokenDef.new(TokenType::Arrow, /->/),
    TokenDef.new(TokenType::Call, /call/),
    TokenDef.new(TokenType::Comma, /,/),

    # other
    TokenDef.new(TokenType::UIntConst, /[0-9]+u8/),
    TokenDef.new(TokenType::IntConst, /-?[0-9]+(i16|i32|i64)/),
    TokenDef.new(TokenType::FloatConst,
                 /-?(([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))(f32|f64)/),
    # NOTE: pretty much anything goes for ID names, this is just a
    # reasonably-broad subset of what the internal IL checks will actually
    # allow
    TokenDef.new(TokenType::ID, /[\w!@$^&*()\-+=\[\]:;"',.?\/<>]+#[0-9]+/),
    TokenDef.new(TokenType::Register, /%[0-9]+/),
    # NOTE: again, actual permitted label names are very broad in the IL
    # (broader than ID names, in fact)
    TokenDef.new(TokenType::Label, /[\w!@$^&*()\-+=\[\];"',.?\/<>]+:/),
    # just a modified version of the label regex
    TokenDef.new(TokenType::JumpTarget, /[\w!@$^&*()\-+=\[\];"',.?\/<>]+/),
    # NOTE: parentheses are absent here to make parsing easier (but of course
    # that isn't actually enforced in the IL)
    TokenDef.new(TokenType::FuncName, /[\w!@$^&*\-+=\[\]:;"',.?\/<>]+/),

    # NOTE: TokenType::NewLine and ::EOF are special and do not need a TokenDef
  ], T::Array[TokenDef])
end
