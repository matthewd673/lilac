# typed: strict
require "sorbet-runtime"
require_relative "frontend"
require_relative "scanner"

class Frontend::Parser
  # NOTE: Parser is adapted from Newt's Parser class
  extend T::Sig

  include Frontend

  sig { params(string: String).void }
  def initialize(string)
    @scanner = T.let(Scanner.new(string), Scanner)
    @next_token = T.let(Token.new(TokenType::None, "", Position.new(0, 0)),
                        Token)
  end

  sig { returns(IL::Program) }
  def parse
    @next_token = @scanner.scan_next
    return parse_program
  end

  private

  sig { params(types: TokenType).returns(T::Boolean) }
  def see?(*types)
    types.each { |t|
      if @next_token.type == t
        return true
      end
    }

    return false
  end

  sig { params(types: TokenType).returns(Token) }
  def eat(*types)
    # try to eat any of the possible types
    types.each { |t|
      if @next_token.type == t
        eaten = @next_token
        @next_token = @scanner.scan_next
        return eaten
      end
    }

    raise("Syntax error") # TODO: nice errors
  end

  sig { returns(IL::Program) }
  def parse_program
    program = IL::Program.new
    program.stmt_list.concat(parse_stmt_list)

    eat(TokenType::EOF)

    return program
  end

  sig { returns(T::Array[IL::Statement]) }
  def parse_stmt_list
    raise("Unimplemented")
  end
end
