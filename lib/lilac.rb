# typed: true
require_relative "il"

if $PROGRAM_NAME == __FILE__
  puts("lilac")


  program = Program.new
  program.push_stmt(Declaration.new(Type::I32,
                                    ID.new("my_var"),
                                    BinaryOp.new(BinaryOp::ADD_OP,
                                                 ID.new("a"),
                                                 ID.new("b"))))
  program.push_stmt(Assignment.new(ID.new("my_var"),
                                   Constant.new(Type::I32,
                                                23)))

  program.each { |s|
    puts(s)
  }
end
