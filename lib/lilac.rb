# typed: true
require_relative "il"

if $PROGRAM_NAME == __FILE__
  puts("lilac")

  id_a = ID.new("a")
  id_b = ID.new("b")
  test = BinaryOp.new(BinaryOp::ADD_OP, id_a, id_b)
  puts("op: " + test.op)
  puts("left: " + test.left.name)
end
