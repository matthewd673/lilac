using Lilac.CodeGen.Targets.Wasm.Instructions;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

public class WasmGenerator(Module module)
  : Generator(module) {
  private const byte Func = 0x60;
  private readonly Dictionary<Type, byte> TypeMap = new() {
    { Type.I32, 0x7f }, { Type.I64, 0x7e },
    { Type.F32, 0x7d }, { Type.F64, 0x7c },
  };
  private const byte SectionType = 1;
  private const byte SectionImport = 2;
  private const byte SectionFunction = 3;
  private const byte SectionTable = 4;
  private const byte SectionMemory = 5;
  private const byte SectionGlobal = 6;
  private const byte SectionExport = 7;
  private const byte SectionStart = 8;
  private const byte SectionElement = 9;
  private const byte SectionCode = 10;
  private const byte SectionData = 11;
  private const byte SectionDataCount = 12;

  private const byte KindFunc = 0;
  private const byte KindTable = 1;
  private const byte KindMem = 2;
  private const byte KindGlobal = 3;

  private List<Func> functions = [];
  private Dictionary<string, int> funcIndices = [];
  private List<Import> imports = [];
  private List<Global> globals = [];
  private Dictionary<string, int> globalIndices = [];
  private List<Func> exports = [];
  private Start? start = null;

  private HexWriter writer = new();
  private Dictionary<Signature, int> sigDict = [];
  private List<Signature> sigArray = [];

  public override string Generate() {
    // prepare to generate
    CollectComponents();
    CreateSignaturesMap();

    // write header
    WriteMagicNumber();
    WriteVersion();

    WriteTypeSection();
    WriteImportSection();
    WriteFunctionSection();
    WriteGlobalSection();
    WriteExportSection();
    WriteStartSection();
    WriteCodeSection();

    return writer.ToString();
  }

  private void CollectComponents() {
    foreach (WasmComponent c in module.Components) {
      switch (c) {
        case Func func:
          functions.Add(func);
          if (func.Export is not null) {
            exports.Add(func);
          }
          break;
        case Import import:
          imports.Add(import);
          break;
        case Global global:
          globalIndices.Add(global.Name, globals.Count);
          globals.Add(global);
          break;
        case Start start:
          this.start = start;
          break;
      }
    }
  }

  private void CreateSignaturesMap() {
    int num = 0;

    foreach (Import i in imports) {
      Signature signature = new(i.ParamTypes, i.Results);
      if (sigDict.ContainsKey(signature)) {
        continue;
      }

      sigDict.Add(signature, num);
      sigArray.Add(signature);
      num += 1;
    }

    foreach (Func f in functions) {
      Signature signature = new(new(f.Params.Select(p => p.Type)),
                                f.Results);
      if (sigDict.ContainsKey(signature)) {
        continue;
      }

      sigDict.Add(signature, num);
      sigArray.Add(signature);
      num += 1;
    }
  }

  /// <summary>
  /// Give a function an index in the <c>funcIndices</c> table. According to
  /// the WebAssembly spec, "The [function] index space starts at zero with the
  /// function imports (if any) followed by the functions defined within the
  /// module."
  /// (https://github.com/WebAssembly/design/blob/main/Modules.md#function-index-space)
  /// </summary>
  /// <param name="name">The name of the function to index.</param>
  private void MarkFunctionIndex(string name) {
    if (funcIndices.ContainsKey(name)) {
      return;
    }

    funcIndices.Add(name, funcIndices.Count);
  }

  private void WriteMagicNumber() {
    writer.Write(0x00, 0x61, 0x73, 0x6d);
  }

  private void WriteVersion() {
    writer.Write(0x01, 0x00, 0x00, 0x00);
  }

  private void WriteTypeSection() {
    // write section header
    // LAYOUT: id, size, num functions
    writer.Write(SectionType);

    // write all bytes in section to section writer
    HexWriter sw = new();

    // num functions
    sw.Write(LEB128.EncodeUnsigned(sigArray.Count));

    // write all function signatures
    // LAYOUT: FUNC, num params, [param types], num results, [result types]
    foreach (Signature s in sigArray) {
      List<Type> @params = s.Params;
      List<Type> results = s.Results;

      sw.Write(Func);

      // param length and params
      sw.Write(LEB128.EncodeUnsigned(@params.Count));
      foreach (Type p in @params) {
        sw.Write(TypeMap[p]);
      }

      // result length and results
      sw.Write(LEB128.EncodeUnsigned(results.Count));
      foreach (Type r in results) {
        sw.Write(TypeMap[r]);
      }
    }

    // finish by writing section size and then section bytes
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteImportSection() {
    if (imports.Count == 0) {
      return;
    }

    // write section header
    // LAYOUT: id, size, num imports
    writer.Write(SectionImport);

    HexWriter sw = new();

    // num imports
    sw.Write(LEB128.EncodeUnsigned(imports.Count));

    // write all imports
    // LAYOUT: str len, module name, str len, field naem,
    //         import kind, import func sig index
    foreach (Import i in imports) {
      sw.Write(LEB128.EncodeUnsigned(i.ModuleName.Length));
      sw.WriteUtf8(i.ModuleName);

      sw.Write(LEB128.EncodeUnsigned(i.FuncName.Length));
      sw.WriteUtf8(i.FuncName);

      // NOTE: for now, all imports are function imports
      sw.Write(KindFunc);
      MarkFunctionIndex(i.FuncName);

      // signature index
      int index = sigDict[new(i.ParamTypes, i.Results)];
      sw.Write(LEB128.EncodeUnsigned(index));
    }

    // write section size then concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteFunctionSection() {
    // write section header
    // LAYOUT: id, size, num functions
    writer.Write(SectionFunction);

    HexWriter sw = new();

    // num functions
    sw.Write(LEB128.EncodeUnsigned(functions.Count));

    // write all function signatures
    // LAYOUT: signature index
    foreach (Func f in functions) {
      int index = sigDict[new(new(f.Params.Select(p => p.Type)), f.Results)];
      sw.Write(LEB128.EncodeUnsigned(index));
      MarkFunctionIndex(f.Name);
    }

    // write section size then concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteGlobalSection() {
    if (globals.Count == 0) {
      return;
    }

    // write section header
    // LAYOUT: id, size, num globals
    writer.Write(SectionGlobal);

    HexWriter sw = new();

    // num globals
    sw.Write(LEB128.EncodeUnsigned(globals.Count));

    // write all globals
    // LAYOUT: type, mutability, constant (default value), end
    foreach (Global g in globals) {
      sw.Write(TypeMap[g.Type]);
      sw.Write(g.Mutable ? (byte)0x01 : (byte)0x00);
      WriteInstruction(g.DefaultValue, sw);
      WriteInstruction(new End(), sw);
    }

    // write section size then concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteExportSection() {
    if (exports.Count == 0) {
      return;
    }

    // write section header
    // LAYOUT: id, size, num globals
    writer.Write(SectionExport);

    HexWriter sw = new();

    // num exports
    sw.Write(LEB128.EncodeUnsigned(exports.Count));

    // write all exports
    // TODO: support non-function exports
    // LAYOUT: string length, name, kind, func index
    foreach (Func f in exports) {
      sw.Write(LEB128.EncodeUnsigned(f.Name.Length));
      sw.WriteUtf8(f.Name);
      sw.Write(KindFunc); // NOTE: only func exports are supported so far

      int index = sigDict[new(new(f.Params.Select(p => p.Type)), f.Results)];
      sw.Write(LEB128.EncodeUnsigned(index));
    }

    // write section size then concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteStartSection() {
    if (start is null) {
      return;
    }

    // write section header
    // LAYOUT: id, size, start function index
    writer.Write(SectionStart);

    HexWriter sw = new();

    // get start function index
    int index = funcIndices[start.Name];

    sw.Write(LEB128.EncodeUnsigned(index));

    // write section size and concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private void WriteCodeSection() {
    // write section header
    // LAYOUT: id, size, num functions
    writer.Write(SectionCode);

    HexWriter sw = new();

    // num functions
    sw.Write(LEB128.EncodeUnsigned(functions.Count));

    // write all func bodies
    foreach (Func f in functions) {
      HexWriter bw = WriteFuncBody(f);

      // write body size to section writer, then concat body writer contents
      sw.Write(LEB128.EncodeUnsigned(bw.Count));
      sw.WriteFrom(bw);
    }

    // write section size and concat section contents
    writer.Write(LEB128.EncodeUnsigned(sw.Count));
    writer.WriteFrom(sw);
  }

  private HexWriter WriteFuncBody(Func func) {
    HexWriter bw = new();

    // write locals
    // LAYOUT: local decl count, [local type count, local type]
    bw.Write(LEB128.EncodeUnsigned(func.LocalsDict.Count));

    // write local counts and types
    // also, build a map of local name => index to lookup from later
    Dictionary<string, int> localIndices = [];

    // add func params to localIndices first
    foreach (Local p in func.Params) {
      localIndices.Add(p.Name, localIndices.Count);
    }

    foreach (Type t in func.LocalsDict.Keys) {
      List<Local> locals = func.LocalsDict[t];
      bw.Write(LEB128.EncodeUnsigned(locals.Count));
      bw.Write(TypeMap[t]);

      foreach (Local l in locals) {
        localIndices.Add(l.Name, localIndices.Count);
      }
    }

    // write instructions
    foreach (WasmInstruction i in func.Instructions) {
      WriteInstruction(i, bw, localIndices);
    }

    return bw;
  }

  private void WriteInstruction(WasmInstruction instr,
                                 HexWriter hexWriter,
                                 Dictionary<string, int>? localIndices = null) {
    if (localIndices is null) {
      localIndices = [];
    }

    hexWriter.Write(instr.OpCode); // always write opcode

    // we need to write more than just opcode for some instructions
    switch (instr) {
      case Const { Type: Type.I32 } i:
        hexWriter.Write(LEB128.EncodeSigned(Convert.ToInt32(i.Value)));
        break;
      case Const { Type: Type.I64 } i:
        hexWriter.Write(LEB128.EncodeSigned(Convert.ToInt64(i.Value)));
        break;
      case Const { Type: Type.F32 } i:
        throw new NotImplementedException(); // TODO
      case Const { Type: Type.F64 } i:
        throw new NotImplementedException(); // TODO
      case LocalGet i:
        hexWriter.Write(LEB128.EncodeUnsigned(localIndices[i.Variable]));
        break;
      case LocalSet i:
        hexWriter.Write(LEB128.EncodeUnsigned(localIndices[i.Variable]));
        break;
      case LocalTee i:
        hexWriter.Write(LEB128.EncodeUnsigned(localIndices[i.Variable]));
        break;
      case GlobalGet i:
        hexWriter.Write(LEB128.EncodeUnsigned(globalIndices[i.Variable]));
        break;
      case GlobalSet i:
        hexWriter.Write(LEB128.EncodeUnsigned(globalIndices[i.Variable]));
        break;
      case Call i:
        hexWriter.Write(LEB128.EncodeUnsigned(funcIndices[i.FuncName]));
        break;
    }
  }
}
