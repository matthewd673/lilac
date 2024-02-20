# typed: true
require_relative "il"
require_relative "interpreter"
require_relative "debugger"
require_relative "analysis/bb"

include IL

if $PROGRAM_NAME == __FILE__
  program = Program.new
  program.push_stmt(Declaration.new(Type::I32,
                                    ID.new("a"),
                                    BinaryOp.new(BinaryOp::ADD_OP,
                                                 Constant.new(Type::I32,
                                                              2),
                                                 Constant.new(Type::I32,
                                                              3))))
  program.push_stmt(Declaration.new(Type::I32,
                                    ID.new("b"),
                                    Constant.new(Type::I32,
                                                 10)))

  program.push_stmt(Declaration.new(Type::I32,
                                    ID.new("c"),
                                    BinaryOp.new(BinaryOp::MUL_OP,
                                                 ID.new("a"),
                                                 ID.new("b"))))

  program.push_stmt(Assignment.new(ID.new("c"),
                                   BinaryOp.new(BinaryOp::SUB_OP,
                                                ID.new("c"),
                                                ID.new("b"))))

  Interpreter.interpret(program)

  blocks = BB.create_blocks(program)
  pretty_printer = Debugger::PrettyPrinter.new
  pretty_printer.print_blocks(blocks)
end
