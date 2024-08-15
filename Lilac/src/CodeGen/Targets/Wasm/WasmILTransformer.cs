using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Lilac.IL.Math;
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
      BinaryOp { Op: BinaryOp.Operator.Add } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         new Add(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Sub } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         new Subtract(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Mul } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         new Multiply(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Div } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         GetILType(binaryOp.Left).IsFloat() ?
           new Divide(GetWasmType(binaryOp.Left)) :
           GetILType(binaryOp.Left).IsSigned() ?
             new DivideSigned(GetWasmType(binaryOp.Left)) :
             new DivideUnsigned(GetWasmType(binaryOp.Right)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Mod } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         GetILType(binaryOp.Left).IsSigned() ?
           new RemainderSigned(GetWasmType(binaryOp.Left)) :
           new RemainderUnsigned(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp {
          Op: BinaryOp.Operator.Eq,
          Left: Constant { Type: var leftType,
                           Value: var value }
        } binaryOp when leftType.IsInteger() && InternalMath.IsZero(value) =>
        [..Transform(binaryOp.Right),
         new EqualZero(GetWasmType(binaryOp.Right)),
        ],
      BinaryOp {
          Op: BinaryOp.Operator.Eq,
          Right: Constant { Type: var rightType,
                            Value: var value },
        } binaryOp when rightType.IsInteger() && InternalMath.IsZero(value) =>
        [..Transform(binaryOp.Left),
         new EqualZero(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Eq } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         new Equal(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Neq } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         new Equal(GetWasmType(binaryOp.Left)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Gt } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         GetILType(binaryOp.Left).IsFloat() ?
           new GreaterThan(GetWasmType(binaryOp.Left)) :
           GetILType(binaryOp.Left).IsSigned() ?
             new GreaterThanSigned(GetWasmType(binaryOp.Left)) :
             new GreaterThanUnsigned(GetWasmType(binaryOp.Right)),
        ],
      BinaryOp { Op: BinaryOp.Operator.Lt } binaryOp =>
        [..Transform(binaryOp.Left),
         ..Transform(binaryOp.Right),
         GetILType(binaryOp.Left).IsFloat() ?
           new LessThan(GetWasmType(binaryOp.Left)) :
           GetILType(binaryOp.Left).IsSigned() ?
             new LessThanSigned(GetWasmType(binaryOp.Left)) :
             new LessThanUnsigned(GetWasmType(binaryOp.Right)),
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
                     constant.Value.ToString()
                       ?? throw new InvalidOperationException())],
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