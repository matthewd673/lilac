using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Load = Lilac.CodeGen.Targets.Wasm.Instructions.Load;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

internal class WasmILTransformer(SymbolTable symbolTable)
  : ILTransformer<WasmInstruction> {
  private SymbolTable symbolTable = symbolTable;

  public override List<WasmInstruction> Transform(Node node) {
    return node switch {
      // STATEMENT RULES
      InlineInstr inlineInstr =>
        [inlineInstr.Instr as WasmInstruction ??
          throw new InvalidOperationException(),
        ],
      Definition { Rhs: StackAlloc stackAlloc } def =>
        [new GlobalGet(Runtime.StackPointerName),
         def.Id is GlobalID ? // NOTE: only locals should be stack alloc'd
          new GlobalSet(def.Id.Name) :
          new LocalSet(def.Id.Name),
         def.Id is GlobalID ?
          new GlobalGet(def.Id.Name) :
          new LocalGet(def.Id.Name), // has a change to become a tee
         new Const(Runtime.PointerType,
                   stackAlloc.Type.ToWasmType().GetSizeBytes().ToString()),
         new Add(Runtime.PointerType),
         new GlobalSet(Runtime.StackPointerName),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.U8 } load } def =>
        [
          ..Transform(load.Address),
          new Load8U(def.Type.ToWasmType()),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.I8 } load } def =>
        [
          ..Transform(load.Address),
          new Load8S(def.Type.ToWasmType()),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.U16 } load } def =>
        [
          ..Transform(load.Address),
          new Load16U(def.Type.ToWasmType()),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.I16 } load } def =>
        [
          ..Transform(load.Address),
          new Load16S(def.Type.ToWasmType()),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition {
          Rhs: IL.Load { Type: IL.Type.U32 } load,
          Type: IL.Type.I64,
        } def =>
        [
          ..Transform(load.Address),
          new Load32U(),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition {
          Rhs: IL.Load { Type: IL.Type.I32 } load,
          Type: IL.Type.I64,
        } def =>
        [
          ..Transform(load.Address),
          new Load32S(),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition {
          Rhs: IL.Load { Type: IL.Type.U32 or IL.Type.I32 } load,
          Type: IL.Type.U32 or IL.Type.I32,
        } def =>
        [
          ..Transform(load.Address),
          new Load(Type.I32),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition {
          Rhs: IL.Load { Type: IL.Type.U64 or IL.Type.I64 } load,
          Type: IL.Type.U64 or IL.Type.I32,
        } def =>
        [
          ..Transform(load.Address),
          new Load(Type.I64),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.F32 } load } def =>
        [
          ..Transform(load.Address),
          new Load(Type.F32),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
        ],
      Definition { Rhs: IL.Load { Type: IL.Type.F64 } load } def =>
        [
          ..Transform(load.Address),
          new Load(Type.F64),
          def.Id is GlobalID ?
            new GlobalSet(def.Id.Name) :
            new LocalSet(def.Id.Name),
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
      IL.Return @return =>
        [..Transform(@return.Value),
         new Instructions.Return()],
      ValueExpr valueExpr =>
        Transform(valueExpr.Value), // ValueExpr is just a wrapper
      IL.Store { Type: IL.Type.U8 or IL.Type.I8 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Store8(Type.I32),
        ],
      IL.Store { Type: IL.Type.U16 or IL.Type.I16 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Store16(Type.I32),
        ],
      IL.Store { Type: IL.Type.U32 or IL.Type.I32 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Instructions.Store(Type.I32),
        ],
      IL.Store { Type: IL.Type.U64 or IL.Type.U64 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Instructions.Store(Type.I64),
        ],
      IL.Store { Type: IL.Type.F32 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Instructions.Store(Type.F32),
        ],
      IL.Store { Type: IL.Type.F64 } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Instructions.Store(Type.F64),
        ],
      // VALUE RULES
      ID id =>
        [id is GlobalID ?
          new GlobalGet(id.Name) :
          new LocalGet(id.Name),
        ],
      Constant constant =>
        constant.Type.IsVoid() ?
          [] :
          [new Const(constant.Type.ToWasmType(),
                     constant.Value.ToString())],
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public IL.Type GetILType(Expression expr) {
    return expr switch {
      BinaryOp binaryOp => GetILType(binaryOp.Left), // left & right must match
      UnaryOp unaryOp => GetILType(unaryOp.Value),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public IL.Type GetILType(Value value) {
    return value switch {
      ID id => (symbolTable[id] ?? throw new NullReferenceException()).Type,
      Constant constant => constant.Type,
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  private Type GetWasmType(Value value) {
    return GetILType(value).ToWasmType();
  }
}