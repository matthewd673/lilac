using Lilac.Analysis;
using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Lilac.IL.Math;
using Load = Lilac.CodeGen.Targets.Wasm.Instructions.Load;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

internal class WasmILTransformer(CFGProgram program, SymbolTable symbolTable)
  : ILTransformer<WasmInstruction>(program) {
  private SymbolTable symbolTable = symbolTable;

  public override List<WasmInstruction> Transform(Node node) {
    return node switch {
      // STATEMENT RULES
      InlineInstr inlineInstr =>
        [inlineInstr.Instr as WasmInstruction ??
          throw new InvalidOperationException(),
        ],
      // the below pattern is more concise than would be possible if
      // StackAlloc was transformed in an independent recursive call
      Definition { Rhs: StackAlloc stackAlloc } def =>
        [new GlobalGet(Runtime.StackPointerName),
         def.Id is GlobalID ? // NOTE: only locals should be stack alloc'd
          new GlobalSet(def.Id.Name) :
          new LocalSet(def.Id.Name),
         def.Id is GlobalID ?
          new GlobalGet(def.Id.Name) :
          new LocalGet(def.Id.Name), // has a chance to become a tee
         ..Transform(stackAlloc.Size),
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
          Type: IL.Type.U64 or IL.Type.I64,
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
      Definition { Rhs: IL.Load { Type: IL.Type.Pointer } load } def =>
        [
          ..Transform(load.Address),
          new Load(Runtime.PointerType),
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
      IL.Return @return =>
        [..Transform(@return.Value),
         new Instructions.Return()],
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
      IL.Store { Type: IL.Type.U64 or IL.Type.I64 } store =>
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
      IL.Store { Type: IL.Type.Pointer } store =>
        [
          ..Transform(store.Address),
          ..Transform(store.Value),
          new Instructions.Store(Runtime.PointerType),
        ],
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
      ValueExpr valueExpr =>
        Transform(valueExpr.Value), // ValueExpr is just a wrapper
      GetFieldOffset getFieldOffset =>
        [
          ..Transform(getFieldOffset.Address),
          new Const(Runtime.PointerType,
                    ComputeStructFieldOffset(
                      Program.Structs[getFieldOffset.StructName]
                        ?? throw new NullReferenceException(),
                      getFieldOffset.Index).ToString()),
          new Add(Runtime.PointerType),
        ],
      // VALUE RULES
      LocalID localId => [new LocalGet(localId.Name)],
      GlobalID globalId => [new GlobalGet(globalId.Name)],
      Constant constant =>
        constant.Type.IsVoid() ?
          [] :
          [new Const(constant.Type.ToWasmType(),
                     ValueEncoder.StringifyValue(constant.Type,
                                                 constant.Value)),
            ],
      SizeOfPrimitive sizeOf =>
        [new Const(Runtime.PointerType,
                   sizeOf.Type.ToWasmType().GetSizeBytes().ToString())],
      SizeOfStruct sizeOf =>
        [new Const(Runtime.PointerType,
                   ComputeStructSize(Program.Structs[sizeOf.StructName])
                     .ToString()),
        ],
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public IL.Type GetILType(Expression expr) {
    return expr switch {
      BinaryOp binaryOp => GetILType(binaryOp.Left), // assume left & right match
      UnaryOp unaryOp => GetILType(unaryOp.Value),
      ValueExpr valueExpr => GetILType(valueExpr.Value),
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

  private int ComputeStructSize(Struct @struct) {
    int size = 0;

    // TODO: no alignment, just trying to get something working
    foreach (IL.Type t in @struct.FieldTypes) {
      size += t.ToWasmType().GetSizeBytes();
    }

    return size;
  }

  private int ComputeStructFieldOffset(Struct @struct, int fieldIndex) {
    // TODO: no alignment yet
    int offset = 0;
    for (int i = 0; i < fieldIndex; i++) {
      offset += @struct.FieldTypes[i].ToWasmType().GetSizeBytes();
    }

    return offset;
  }
}
