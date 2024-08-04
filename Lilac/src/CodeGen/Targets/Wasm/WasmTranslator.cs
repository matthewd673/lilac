using Lilac.Analysis;
using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

public class WasmTranslator : Translator<WasmInstruction> {
  private SymbolTable symbols;

  private int loopCt;
  private int blockCt;

  private string? _startFunction;
  public string? StartFunction {
    get => _startFunction;
    set {
      _startFunction = value;
      if (CFGProgram.GetFunc(_startFunction) is null) {
        throw new KeyNotFoundException();
      }
    }
  }

  public WasmTranslator(CFGProgram cfgProgram) {
    symbols = new();

    loopCt = 0;
    blockCt = 0;

    StartFunction = null;

    Transformer = new WasmILTransformer(symbols);
    CFGProgram = cfgProgram;
  }

  public override Module Translate() {
    List<WasmComponent> components = [];
    symbols.PushScope(); // always have scope for globals and top-level

    // import all extern functions
    foreach (ExternFuncDef f in CFGProgram.GetExternFuncs()) {
      components.Add(TranslateImport(f));
    }

    // translate all globals
    foreach (GlobalDef g in CFGProgram.GetGlobals()) {
      // add global to top-level scope
      symbols.Add(new(g.Id, g.Type));
      components.Add(TranslateGlobal(g));
    }

    // translate all functions
    foreach (CFGFuncDef f in CFGProgram.GetFuncs()) {
      components.Add(TranslateFunc(f));
    }

    // add start component if a start function has been set
    if (StartFunction is not null) {
      components.Add(new Start(StartFunction));
    }

    return new Module(components);
  }

  private Import TranslateImport(ExternFuncDef externFuncDef) {
    // translate param types for function signature
    List<Type> paramTypes = [];
    foreach (IL.Type t in externFuncDef.ParamTypes) {
      paramTypes.Add(t.ToWasmType());
    }

    List<Type> results = [];
    if (!externFuncDef.RetType.IsVoid()) {
      results.Add(externFuncDef.RetType.ToWasmType());
    }

    return new Import(externFuncDef.Source,
                      externFuncDef.Name,
                      paramTypes,
                      results);
  }

  private Global TranslateGlobal(GlobalDef globalDef) {
    Type type = globalDef.Type.ToWasmType();
    string name = globalDef.Id.Name;
    List<WasmInstruction> rhs = Transformer.Transform(globalDef.Rhs);

    if (rhs.Count == 0 || rhs[0] is not Const) {
      throw new Exception("RHS of GlobalDef did not translate to a Wasm Const");
    }

    // TODO: optimization to make some globals not mutable
    return new Global(type, name, (Const)rhs[0], true);
  }

  private Func TranslateFunc(CFGFuncDef cfgFuncDef) {
    List<Local> @params = []; // list of params for functions signature

    // create a new scope with func params
    symbols.PushScope();
    foreach (FuncParam p in cfgFuncDef.Params) {
      symbols.Add(new(p.Id, p.Type));

      // also mark this down for the function signature
      Type paramType = p.Type.ToWasmType();
      string paramName = p.Id.Name;
      @params.Add(new Local(paramType, paramName));
    }

    // find all locals in the function
    Dictionary<Type, List<Local>> locals = FindLocals(cfgFuncDef.CFG);

    // translate instructions and pop the scope we used
    List<WasmInstruction> instructions = TranslateInstructions(cfgFuncDef.CFG);
    symbols.PopScope();
    instructions.Add(new End()); // every func ends with End

    // construct func with appropriate params and return type
    // if return type is void then result is simply null
    List<Type> results = [];
    if (!cfgFuncDef.RetType.IsVoid()) {
      results.Add(cfgFuncDef.RetType.ToWasmType());
    }

    string? exportName = cfgFuncDef.Exported ? cfgFuncDef.Name : null;
    return new Func(cfgFuncDef.Name,
                    @params,
                    results,
                    locals,
                    instructions,
                    exportName);
  }

  private Dictionary<Type, List<Local>> FindLocals(CFG cfg) {
    Dictionary<Type, List<Local>> locals = new();

    // scan forwards to build a symbol table of all locals and their types
    // NOTE: assume that our caller has pushed a new scope for us
    foreach (BB n in cfg.GetNodes()) {
      // scan each block for definitions and log them
      // assume that there are no inconsistent types
      foreach (Statement s in n.StmtList) {
        if (s is not Definition d) {
          continue;
        }

        // avoid redefining globals, params, or ids used more than once
        if (symbols[d.Id] is not null) {
          continue;
        }

        // log in symbol table
        symbols.Add(new(d.Id, d.Type));

        // push declaration
        Type type = d.Type.ToWasmType();
        Local newLocal = new(type, d.Id.Name);

        if (!locals.TryGetValue(type, out List<Local>? typeList)) {
          locals.Add(type, [newLocal]);
        }
        else {
          typeList.Add(newLocal);
        }
      }
    }

    return locals;
  }

  private List<WasmInstruction> TranslateInstructions(CFG cfg) {
    // create a relooper instance for the cfg
    Relooper relooper = new(cfg);

    List<WasmInstruction> instructions = [];

    // run relooper, translate the WasmBlocks, and then return that
    WasmBlock root = relooper.Translate();
    instructions.AddRange(TranslateWasmBlock(root));

    return instructions;
  }

  private List<WasmInstruction> TranslateWasmBlock(WasmBlock block) {
    switch (block) {
      case WasmIfBlock ifBlock: {
        List<WasmInstruction> instructions = [];

        // translate all the conditional stuff
        foreach (Statement s in ifBlock.BB.StmtList) {
          instructions.AddRange(Transformer.Transform(s));
        }

        // push the conditional and create the if
        CondJump? bbExit = ifBlock.BB.Exit as CondJump;
        if (bbExit is null) {
          throw new Exception("Basic block did not have an exit");
        }

        instructions.Add(PushValue(bbExit.Cond));
        if (bbExit is JumpZero) {
          IL.Type condIlType =
            ((WasmILTransformer)Transformer).GetILType(bbExit.Cond);

          // handle integer or non-integer IL type
          if (condIlType.IsInteger()) {
            instructions.Add(new EqualZero(condIlType.ToWasmType()));
          }
          else if (condIlType.IsFloat()) {
            Type type = condIlType.ToWasmType();
            instructions.Add(new Const(type, "0.0"));
            instructions.Add(new Equal(type));
          }
          else {
            throw new ArgumentOutOfRangeException();
          }
        }

        instructions.Add(new If());

        // no true branch = invalid WasmIfBlock
        if (ifBlock.TrueBranch is null) {
          throw new NullReferenceException();
        }

        // translate true branch
        List<WasmInstruction> ifTrueBranch =
          TranslateWasmBlock(ifBlock.TrueBranch);
        instructions.AddRange(ifTrueBranch);

        // fill in empty type if true branch is empty
        if (ifTrueBranch.Count == 0) {
          instructions.Add(new EmptyType());
        }

        // false branch if optional
        if (ifBlock.FalseBranch is not null) {
          // create the else
          instructions.Add(new Else());

          // translate false branch
          List<WasmInstruction> ifFalseBranch =
            TranslateWasmBlock(ifBlock.FalseBranch);
          instructions.AddRange(ifFalseBranch);

          // fill in empty type if false branch is empty
          instructions.Add(new EmptyType());
        }

        // end the if statement
        instructions.Add(new End());

        // translate the next blocks
        if (block.NextBlock is not null) {
          instructions.AddRange(TranslateWasmBlock(block.NextBlock));
        }

        return instructions;
      }
      case WasmLoopBlock loopBlock: {
        List<WasmInstruction> instructions = [];
        string blockLabel = AllocBlockLabel();
        string loopLabel = AllocLoopLabel();

        // translate all the conditional stuff
        // this will be placed at the beginning of the _block_ and the end of
        // the _loop_
        List<WasmInstruction> condInsts = [];
        foreach (Statement s in loopBlock.BB.StmtList) {
          condInsts.AddRange(Transformer.Transform(s));
        }

        CondJump? bbExit = loopBlock.BB.Exit as CondJump;
        if (bbExit is null) {
          throw new NullReferenceException();
        }

        condInsts.Add(PushValue(bbExit.Cond));
        if (bbExit is JumpZero) { // TODO: handle jnz?
          IL.Type condIlType =
            ((WasmILTransformer)Transformer).GetILType(bbExit.Cond);

          // handle integer or non-integer IL type
          if (condIlType.IsInteger()) {
            instructions.Add(new EqualZero(condIlType.ToWasmType()));
          }
          else if (condIlType.IsFloat()) {
            Type type = condIlType.ToWasmType();
            instructions.Add(new Const(type, "0.0"));
            instructions.Add(new Equal(type));
          }
          else {
            throw new ArgumentOutOfRangeException();
          }
        }

        // create the outer block
        instructions.Add(new Block(blockLabel));

        // conditional check before entering the loop
        // (since this is emulating a while, not a do-while)
        instructions.AddRange(condInsts);

        // push conditional branch
        instructions.Add(new BranchIf(blockLabel));

        // create the loop
        instructions.Add(new Loop(loopLabel));

        // translate the inner of the loop (not optional)
        if (loopBlock.Inner is null) {
          throw new NullReferenceException();
        }

        instructions.AddRange(TranslateWasmBlock(loopBlock.Inner));

        // conditional check at end of the loop to see if we should exit
        instructions.AddRange(condInsts);
        instructions.Add(new BranchIf(blockLabel));

        // unconditional jump back after the check
        instructions.Add(new Branch(loopLabel));

        // end the loop and the block
        instructions.Add(new End());
        instructions.Add(new End());

        // translate the next blocks
        if (block.NextBlock is not null) {
          instructions.AddRange(TranslateWasmBlock(block.NextBlock));
        }

        return instructions;
      }
      case WasmBlock: {
        List<WasmInstruction> instructions = [];

        // translate block
        foreach (Statement s in block.BB.StmtList) {
          instructions.AddRange(Transformer.Transform(s));
        }

        // translate the next blocks
        if (block.NextBlock is not null) {
          instructions.AddRange(TranslateWasmBlock(block.NextBlock));
        }

        return instructions;
      }
      default:
        throw new ArgumentOutOfRangeException();
    }
  }

  private WasmInstruction PushValue(Value value) {
    return value switch {
      Constant constant when !constant.Type.IsVoid() =>
        new Const(constant.Type.ToWasmType(),
                  constant.Value.ToString()?? string.Empty),
      Constant => throw new Exception("IL Constant is Void"),
      GlobalID id => new GlobalGet(id.Name),
      ID id => new LocalGet(id.Name),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  private string AllocBlockLabel() {
    string label = $"__block_{blockCt}";
    blockCt += 1;
    return label;
  }

  private string AllocLoopLabel() {
    string label = $"__loop_{loopCt}";
    loopCt += 1;
    return label;
  }
}