using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Return = Lilac.IL.Return;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

public class WasmILTransformer(SymbolTable symbolTable)
  : ILTransformer<WasmInstruction> {
  private SymbolTable symbolTable = symbolTable;

  public override List<WasmInstruction> Transform(Node node) {
    return node switch {
      // STATEMENT RULES
      InlineInstr inlineInstr =>
        [inlineInstr.Instr as WasmInstruction ??
          throw new InvalidOperationException(),
        ],
      Definition def =>
        [..Transform(def.Rhs),
         def.Id is GlobalID ?
          new GlobalSet(def.Id.Name) :
          new LocalSet(def.Id.Name),
        ],
      VoidCall voidCall =>
        Transform(voidCall.Call),
      // EXPRESSION RULES
      BinaryOp { Op: BinaryOp.Operator.Add } binaryOpAdd =>
        [..Transform(binaryOpAdd.Left),
         ..Transform(binaryOpAdd.Right),
         new Add(GetWasmType(binaryOpAdd.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Sub } binaryOpSub =>
        [..Transform(binaryOpSub.Left),
         ..Transform(binaryOpSub.Right),
         new Subtract(GetWasmType(binaryOpSub.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Mul } binaryOpMul =>
        [..Transform(binaryOpMul.Left),
         ..Transform(binaryOpMul.Right),
         new Multiply(GetWasmType(binaryOpMul.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Div } binaryOpDiv =>
        [..Transform(binaryOpDiv.Left),
         ..Transform(binaryOpDiv.Right),
         GetILType(binaryOpDiv.Left).IsFloat() ?
           new Divide(GetWasmType(binaryOpDiv.Left)) :
           GetILType(binaryOpDiv.Left).IsSigned() ?
             new DivideSigned(GetWasmType(binaryOpDiv.Left)) :
             new DivideUnsigned(GetWasmType(binaryOpDiv.Right)),
        ],
      BinaryOp {
          Op: BinaryOp.Operator.Eq,
          Left: Constant { Type: var leftType, Value: 0 },
        } binaryOpEqZLeft when leftType.IsInteger() =>
        [..Transform(binaryOpEqZLeft.Right),
         new EqualZero(GetWasmType(binaryOpEqZLeft.Right))
        ],
      BinaryOp {
          Op: BinaryOp.Operator.Eq,
          Right: Constant { Type: var rightType, Value: 0 },
        } binaryOpEqZRight when rightType.IsInteger() =>
        [..Transform(binaryOpEqZRight.Left),
         new EqualZero(GetWasmType(binaryOpEqZRight.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Eq } binaryOpEq =>
        [..Transform(binaryOpEq.Left),
         ..Transform(binaryOpEq.Right),
         new Equal(GetWasmType(binaryOpEq.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Neq } binaryOpNeq =>
        [..Transform(binaryOpNeq.Left),
         ..Transform(binaryOpNeq.Right),
         new Equal(GetWasmType(binaryOpNeq.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Gt } binaryOpGt =>
        [..Transform(binaryOpGt.Left),
         ..Transform(binaryOpGt.Right),
         GetILType(binaryOpGt.Left).IsFloat() ?
           new GreaterThan(GetWasmType(binaryOpGt.Left)) :
           GetILType(binaryOpGt.Left).IsSigned() ?
             new GreaterThanSigned(GetWasmType(binaryOpGt.Left)) :
             new GreaterThanUnsigned(GetWasmType(binaryOpGt.Right)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Lt } binaryOpLt =>
        [..Transform(binaryOpLt.Left),
         ..Transform(binaryOpLt.Right),
         GetILType(binaryOpLt.Left).IsFloat() ?
           new LessThan(GetWasmType(binaryOpLt.Left)) :
           GetILType(binaryOpLt.Left).IsSigned() ?
             new LessThanSigned(GetWasmType(binaryOpLt.Left)) :
             new LessThanUnsigned(GetWasmType(binaryOpLt.Right)),
        ],
      IL.Call call =>
        [..call.Args.SelectMany(Transform),
         new Instructions.Call(call.FuncName),
        ],
      Return @return =>
        [..Transform(@return.Value),
         new Instructions.Return()],
      // VALUE RULES
      ID id =>
        [id is GlobalID ?
          new GlobalGet(id.Name) :
          new LocalGet(id.Name),
        ],
      Constant constant =>
        constant.Type.IsVoid() ?
          [] :
          [new Const(ILTypeToWasmType(constant.Type),
                     constant.Value.ToString())],
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  private Type ILTypeToWasmType(IL.Type type) {
    return type switch {
      IL.Type.I32 => Type.I32,
      IL.Type.I64 => Type.I64,
      IL.Type.F32 => Type.F32,
      IL.Type.F64 => Type.F64,
      _ => throw new ArgumentOutOfRangeException(nameof(type), type,
                                                 "IL type not supported in Wasm"
                                                 ),
    };
  }

  private IL.Type GetILType(Expression expr) {
    return expr switch {
      BinaryOp binaryOp => GetILType(binaryOp.Left), // left & right must match
      UnaryOp unaryOp => GetILType(unaryOp.Value),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  private IL.Type GetILType(Value value) {
    return value switch {
      ID id => (symbolTable[id] ?? throw new NullReferenceException()).Type,
      Constant constant => constant.Type,
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  private Type GetWasmType(Value value) {
    return ILTypeToWasmType(GetILType(value));
  }
}