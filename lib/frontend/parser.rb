# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "frontend"
require_relative "scanner"
require_relative "../il"

# A Parser can parse human-readable IL source code in +IL::Program+ objects.
# It provides minimal error reporting as IL source code is not designed to
# be handwritten (though it certainly can be).
module Frontend
  class Parser
    # NOTE: Parser is adapted from Newt's Parser class
    extend T::Sig

    include Frontend

    sig { params(filename: String).returns(IL::Program) }
    # Load a file and parse its contents into a program. This also handles the
    # construction of a Parser internally.
    #
    # @param [String] filename The filename of the file to load.
    # @return [IL::Program] The program represented by the file's source code.
    def self.parse_file(filename)
      fp = File.open(filename, "r")
      source = fp.read
      fp.close

      parser = Parser.new(source)
      parser.parse
    end

    sig { params(string: String).void }
    # Construct a new Parser which will parse IL source code from the given string.
    #
    # @param [String] string The string of IL source code while will be parsed.
    def initialize(string)
      @scanner = T.let(Scanner.new(string), Scanner)
      @next_token = T.let(Token.new(TokenType::None, "", Position.new(0, 0)),
                          Token)
    end

    sig { returns(IL::Program) }
    # Parse the IL source code in the Parser's string.
    #
    # @return [IL::Program] The program represented by the IL source code string.
    def parse
      @next_token = @scanner.scan_next
      parse_program
    end

    private

    sig { params(types: TokenType).returns(T::Boolean) }
    def see?(*types)
      types.each do |t|
        if @next_token.type == t
          return true
        end
      end

      false
    end

    sig { params(types: TokenType).returns(Token) }
    def eat(*types)
      # try to eat any of the possible types
      types.each do |t|
        unless @next_token.type == t
          next
        end

        eaten = @next_token
        @next_token = @scanner.scan_next
        return eaten
      end

      raise("Syntax error at #{@next_token.position}: saw #{@next_token.type}, expected #{types}") # TODO: nice errors
    end

    sig { returns(IL::Program) }
    def parse_program
      program = IL::Program.new

      # parse top level items (which include statements and other components)
      until see?(TokenType::EOF)
        if see?(TokenType::NewLine, TokenType::Type, TokenType::Label,
                TokenType::Jump, TokenType::JumpZero, TokenType::JumpNotZero,
                TokenType::Return, TokenType::VoidConst)
          program.stmt_list.concat(parse_stmt_list)
        # func def
        elsif see?(TokenType::Func)
          program.add_func(parse_func_def)
        # extern func def
        elsif see?(TokenType::Extern)
          program.add_extern_func(parse_extern_func_def)
        end
      end

      eat(TokenType::EOF)

      program
    end

    sig { returns(T::Array[IL::Statement]) }
    def parse_stmt_list
      stmt_list = []

      # parse stmts until we reach the end
      until see?(TokenType::EOF, TokenType::End, TokenType::Func)
        stmt_list.concat(parse_stmt)
      end

      stmt_list
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

        if see?(TokenType::ID)
          id_str = eat(TokenType::ID).image
          id = id_from_string(id_str)
        elsif see?(TokenType::Register)
          register_str = eat(TokenType::Register).image
          id = register_from_string(register_str)
        else
          raise("Expected ID or Register when parsing Definition")
        end

        eat(TokenType::Assignment)

        rhs = parse_expr_or_value

        return [IL::Definition.new(type, id, rhs)]
      # label
      elsif see?(TokenType::Label)
        label_str = eat(TokenType::Label).image
        label_str.chomp!(":") # remove trailing colon that denotes label token

        return [IL::Label.new(label_str)]
      # jump
      elsif see?(TokenType::Jump)
        eat(TokenType::Jump)
        target_str = eat(TokenType::Name).image

        return [IL::Jump.new(target_str)]
      # jump zero
      elsif see?(TokenType::JumpZero)
        eat(TokenType::JumpZero)
        value = parse_value
        target_str = eat(TokenType::Name).image

        return [IL::JumpZero.new(value, target_str)]
      # jump not zero
      elsif see?(TokenType::JumpNotZero)
        eat(TokenType::JumpNotZero)
        value = parse_value
        target_str = eat(TokenType::Name).image

        return [IL::JumpNotZero.new(value, target_str)]
      # return
      elsif see?(TokenType::Return)
        eat(TokenType::Return)
        value = parse_value

        return [IL::Return.new(value)]
      # void call
      elsif see?(TokenType::VoidConst)
        eat(TokenType::VoidConst)
        call = parse_call

        return [IL::VoidCall.new(call)]
      end

      raise("Unexpected token while parsing statement: #{@next_token}")
    end

    sig { returns(T.any(IL::Value, IL::Expression)) }
    def parse_expr_or_value
      # value or binop
      if see?(TokenType::UIntConst, TokenType::IntConst, TokenType::FloatConst,
              TokenType::ID, TokenType::Register)
        val_l = parse_value

        # if see a binary op, parse that
        return val_l unless see?(TokenType::BinaryOp)

        binop_tok = eat(TokenType::BinaryOp)
        val_r = parse_value

        binop = binop_from_token(binop_tok, val_l, val_r)

        return binop
      # if don't see a binary op, this must just be a constant

      # unary op
      elsif see?(TokenType::UnaryOp)
        unop_tok = eat(TokenType::UnaryOp)
        val = parse_value

        unop = unop_from_token(unop_tok, val)

        return unop
      # calls
      elsif see?(TokenType::Call, TokenType::Extern)
        return parse_call
      # phi function
      elsif see?(TokenType::Phi)
        eat(TokenType::Phi)

        # eat id list
        eat(TokenType::LeftParen)
        ids = []
        parse_id_list(ids)
        eat(TokenType::RightParen)

        return IL::Phi.new(ids)
      end

      raise("Unexpected token while parsing expression: #{@next_token}")
    end

    sig { returns(IL::Call) }
    def parse_call
      # func call
      if see?(TokenType::Call)
        # eat func name
        eat(TokenType::Call)
        func_name = eat(TokenType::Name).image

        # eat args
        eat(TokenType::LeftParen)
        args = []
        parse_call_args(args)
        eat(TokenType::RightParen)

        return IL::Call.new(func_name, args)
      # extern func call
      elsif see?(TokenType::Extern)
        # eat func source and name
        eat(TokenType::Extern)
        eat(TokenType::Call)
        func_source = eat(TokenType::Name).image
        func_name = eat(TokenType::Name).image

        # eat args
        eat(TokenType::LeftParen)
        args = []
        parse_call_args(args)
        eat(TokenType::RightParen)

        return IL::ExternCall.new(func_source, func_name, args)
      end

      raise("Unexpected token while parsing call: #{@next_token}")
    end

    sig { returns(IL::Value) }
    def parse_value
      # constant
      if see?(TokenType::UIntConst, TokenType::IntConst, TokenType::FloatConst)
        const_str = eat(TokenType::UIntConst, TokenType::IntConst,
                        TokenType::FloatConst).image
        return constant_from_string(const_str)
      # void constant
      elsif see?(TokenType::VoidConst)
        eat(TokenType::VoidConst)
        return IL::Constant.new(IL::Type::Void, nil)
      # id
      elsif see?(TokenType::ID)
        id_str = eat(TokenType::ID).image
        return id_from_string(id_str)
      # register
      elsif see?(TokenType::Register)
        register_str = eat(TokenType::Register).image
        return register_from_string(register_str)
      end

      raise("Unexpected token while parsing value: #{@next_token}")
    end

    sig { returns(IL::FuncDef) }
    def parse_func_def
      # eat func name
      eat(TokenType::Func)
      name = eat(TokenType::Name).image

      # eat func params
      eat(TokenType::LeftParen)
      func_params = []
      parse_func_params(func_params)
      eat(TokenType::RightParen)

      # eat return type
      eat(TokenType::Arrow)
      ret_type_str = eat(TokenType::Type, TokenType::VoidConst).image
      ret_type = type_from_string(ret_type_str)
      eat(TokenType::NewLine)

      stmt_list = parse_stmt_list

      eat(TokenType::End)

      IL::FuncDef.new(name, func_params, ret_type, stmt_list)
    end

    sig { returns(IL::ExternFuncDef) }
    def parse_extern_func_def
      # eat func source and name
      eat(TokenType::Extern)
      eat(TokenType::Func)
      source = eat(TokenType::Name).image
      name = eat(TokenType::Name).image

      # eat func param types
      eat(TokenType::LeftParen)
      func_param_types = []
      parse_extern_func_param_types(func_param_types)
      eat(TokenType::RightParen)

      # eat return type
      eat(TokenType::Arrow)
      ret_type_str = eat(TokenType::Type, TokenType::VoidConst).image
      ret_type = type_from_string(ret_type_str)
      eat(TokenType::NewLine)

      IL::ExternFuncDef.new(source, name, func_param_types, ret_type)
    end

    sig { params(param_list: T::Array[IL::FuncParam]).void }
    def parse_func_params(param_list)
      # epsilon
      if see?(TokenType::RightParen)
        return
      end

      type_str = eat(TokenType::Type).image
      type = type_from_string(type_str)

      id_str = eat(TokenType::ID).image
      id = id_from_string(id_str)

      param_list.push(IL::FuncParam.new(type, id))

      # if we see a comma then we have to recurse
      return unless see?(TokenType::Comma)

      eat(TokenType::Comma)
      parse_func_params(param_list)
    end

    sig { params(param_type_list: T::Array[IL::Type]).void }
    def parse_extern_func_param_types(param_type_list)
      # epsilon
      if see?(TokenType::RightParen)
        return
      end

      type_str = eat(TokenType::Type).image
      type = type_from_string(type_str)

      param_type_list.push(type)

      # if we see a comma then we have to recurse
      return unless see?(TokenType::Comma)

      eat(TokenType::Comma)
      parse_extern_func_param_types(param_type_list)
    end

    sig { params(arg_list: T::Array[IL::Value]).void }
    def parse_call_args(arg_list)
      # epsilon
      if see?(TokenType::RightParen)
        return
      end

      value = parse_value
      arg_list.push(value)

      # if we see a comma then we have to recurse
      return unless see?(TokenType::Comma)

      eat(TokenType::Comma)
      parse_call_args(arg_list)
    end

    sig { params(id_list: T::Array[IL::ID]).void }
    def parse_id_list(id_list)
      id = nil
      if see?(TokenType::ID)
        id = id_from_string(eat(TokenType::ID).image)
      elsif see?(TokenType::Register)
        id = register_from_string(eat(TokenType::Register).image)
      end

      unless id
        raise("Unexpected token when parsing ID list: #{@next_token}")
      end

      id_list.push(id)

      # parse rest of list
      return unless see?(TokenType::Comma)

      eat(TokenType::Comma)
      parse_id_list(id_list)
    end

    sig { params(string: String).returns(IL::Type) }
    def type_from_string(string)
      case string
      when "void" then return IL::Type::Void
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
      if (!(split[0])) or (!(split[1])) or split.length > 2
        raise("Invalid ID string \"#{string}\"")
      end

      name = T.unsafe(split[0])
      number = T.unsafe(split[1]).to_i

      id = IL::ID.new(name)
      id.number = number

      id
    end

    sig { params(string: String).returns(IL::Register) }
    def register_from_string(string)
      number = T.unsafe(string[1..]).to_i
      IL::Register.new(number)
    end

    sig { params(string: String).returns(IL::Constant) }
    def constant_from_string(string)
      # find type in constant string
      type_str = string.match(/[uif][0-9]{1,2}/)
      unless type_str
        raise("No type tag in constant: \"#{string}\"")
      end

      type = type_from_string(T.unsafe(type_str[0]))

      numeric = string.to_i
      if type == IL::Type::F32 or type == IL::Type::F64
        numeric = string.to_f
      end

      IL::Constant.new(type, numeric)
    end

    sig do
      params(token: Token, left: IL::Value, right: IL::Value)
        .returns(IL::BinaryOp)
    end
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

      IL::BinaryOp.new(op, left, right)
    end

    sig { params(token: Token, value: IL::Value).returns(IL::UnaryOp) }
    def unop_from_token(token, value)
      op = case token.image
           when "-@" then IL::UnaryOp::Operator::NEG
           else
             raise("Invalid UnaryOp token image #{token.image}")
           end

      IL::UnaryOp.new(op, value)
    end
  end
end
