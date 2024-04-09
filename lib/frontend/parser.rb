# typed: strict
require "sorbet-runtime"
require_relative "frontend"
require_relative "scanner"

class Frontend::Parser
  # NOTE: Parser is adapted from Newt's Parser class
  extend T::Sig

  include Frontend

  sig { params(filename: String).returns(IL::Program) }
  def self.parse_file(filename)
    fp = File.open(filename, "r")
    source = fp.read
    fp.close

    parser = Parser.new(source)
    return parser.parse
  end

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

    raise("Syntax error at #{@next_token.position}: saw #{@next_token.type}, expected #{types}") # TODO: nice errors
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
    stmt_list = []

    # parse stmts until we reach the end
    while not see?(TokenType::EOF, TokenType::End)
      stmt_list.concat(parse_stmt)
    end

    return stmt_list
  end

  sig { returns(T::Array[IL::Statement]) }
  def parse_stmt
    # empty statement
    if see?(TokenType::NewLine)
      eat(TokenType::NewLine)
      return []
    # definition
    elsif see?(TokenType::Type)
      type_str = eat(TokenType::Type).image
      type = type_from_string(type_str)

      id_str = eat(TokenType::ID).image
      id = id_from_string(id_str)

      eat(TokenType::Assignment)

      rhs = parse_expr_or_value

      eat(TokenType::NewLine)

      return [IL::Definition.new(type, id, rhs)]
    # label
    elsif see?(TokenType::Label)
      label_str = eat(TokenType::Label).image
      label_str.chomp!(":") # remove trailing colon that denotes label token

      eat(TokenType::NewLine)

      return [IL::Label.new(label_str)]
    # jump
    elsif see?(TokenType::Jump)
      eat(TokenType::Jump)
      target_str = eat(TokenType::JumpTarget).image

      eat(TokenType::NewLine)

      return [IL::Jump.new(target_str)]
    # jump zero
    elsif see?(TokenType::JumpZero)
      eat(TokenType::JumpZero)
      value = parse_value
      target_str = eat(TokenType::JumpTarget).image

      eat(TokenType::NewLine)

      return [IL::JumpZero.new(value, target_str)]
    # jump not zero
    elsif see?(TokenType::JumpNotZero)
      eat(TokenType::JumpNotZero)
      value = parse_value
      target_str = eat(TokenType::JumpTarget).image

      eat(TokenType::NewLine)

      return [IL::JumpNotZero.new(value, target_str)]
    # return
    elsif see?(TokenType::Return)
      eat(TokenType::Return)
      value = parse_value
      return [IL::Return.new(value)]
    end

    raise("Unexpected token while parsing statement")
  end

  sig { returns(T.any(IL::Value, IL::Expression)) }
  def parse_expr_or_value
    # value or binop
    if see?(TokenType::UIntConst, TokenType::IntConst, TokenType::FloatConst,
            TokenType::ID, TokenType::Register)
      val_l = parse_value

      # if see a binary op, parse that
      if see?(TokenType::BinaryOp)
        binop_tok = eat(TokenType::BinaryOp)
        val_r = parse_value

        binop = binop_from_token(binop_tok, val_l, val_r)

        return binop
      # if don't see a binary op, this must just be a constant
      else
        return val_l
      end
    # unary op
    elsif see?(TokenType::UnaryOp)
      unop_tok = eat(TokenType::UnaryOp)
      val = parse_value

      unop = unop_from_token(unop_tok, val)

      return unop
    # func call
    elsif see?(TokenType::Call)
      # TODO
      raise("Unimplemented")
    # phi function
    elsif see?(TokenType::Phi)
      # TODO
      raise("Unimplemented")
    end

    raise("Unexpected token while parsing expression")
  end

  sig { returns(IL::Value) }
  def parse_value
    # constant
    if see?(TokenType::UIntConst, TokenType::IntConst, TokenType::FloatConst)
      const_str = eat(TokenType::UIntConst, TokenType::IntConst,
                      TokenType::FloatConst).image
      return constant_from_string(const_str)
    # id
    elsif see?(TokenType::ID)
      id_str = eat(TokenType::ID).image
      return id_from_string(id_str)
    # register
    elsif see?(TokenType::Register)
      register_str = eat(TokenType::Register).image
      return register_from_string(register_str)
    end

    raise("Unexpected token while parsing value")
  end

  sig { params(string: String).returns(IL::Type) }
  def type_from_string(string)
    case string
    when "u8" then return IL::Type::U8
    when "i16" then return IL::Type::I16
    when "i32" then return IL::Type::I32
    when "i64" then return IL::Type::I64
    when "f32" then return IL::Type::F32
    when "f64" then return IL::Type::F64
    end

    raise("Invalid type string \"#{string}\"")
  end

  sig { params(string: String).returns(IL::ID) }
  def id_from_string(string)
    split = string.split("#")
    if (not split[0]) or (not split[1]) or split.length > 2
      raise("Invalid ID string \"#{string}\"")
    end

    name = T.unsafe(split[0])
    number = T.unsafe(split[1]).to_i

    id = IL::ID.new(name)
    id.number = number

    return id
  end

  sig { params(string: String).returns(IL::Register) }
  def register_from_string(string)
    number = T.unsafe(string[1..]).to_i
    return IL::Register.new(number)
  end

  sig { params(string: String).returns(IL::Constant) }
  def constant_from_string(string)
    # find type in constant string
    type_str = string.match(/[uif][0-9]{1,2}/)
    if not type_str
      raise("No type tag in constant")
    end
    type = type_from_string(T.unsafe(type_str[0]))

    return IL::Constant.new(type, string.to_i)
  end

  sig { params(token: Token, left: IL::Value, right: IL::Value)
          .returns(IL::BinaryOp) }
  def binop_from_token(token, left, right)
    op = case token.image
    when "+" then IL::BinaryOp::Operator::ADD
    when "-" then IL::BinaryOp::Operator::SUB
    when "*" then IL::BinaryOp::Operator::MUL
    when "/" then IL::BinaryOp::Operator::DIV
    when "==" then IL::BinaryOp::Operator::EQ
    when "!=" then IL::BinaryOp::Operator::NEQ
    when "<" then IL::BinaryOp::Operator::LT
    when ">" then IL::BinaryOp::Operator::GT
    when "<=" then IL::BinaryOp::Operator::LEQ
    when ">=" then IL::BinaryOp::Operator::GEQ
    when "||" then IL::BinaryOp::Operator::OR
    when "&&" then IL::BinaryOp::Operator::AND
    else
      raise("Invalid BinaryOp token image #{token.image}")
    end

    return IL::BinaryOp.new(op, left, right)
  end

  sig { params(token: Token, value: IL::Value).returns(IL::UnaryOp) }
  def unop_from_token(token, value)
    op = case token.image
    when "-@" then IL::UnaryOp::Operator::NEG
    else
      raise("Invalid UnaryOp token image #{token.image}")
    end

    return IL::UnaryOp.new(op, value)
  end
end
