using Lilac.IL;

namespace Lilac.Analysis;

public class CFGProgram : Program<CFGFuncDef> {
  public static CFGProgram FromProgram(Program<FuncDef> program) {
    // create CFGProgram from main
    CFGProgram cfgProgram = new();

    // add all global definitions
    foreach (GlobalDef g in program.GetGlobals()) {
      cfgProgram.AddGlobal(g);
    }

    // convert all functions to cfg and add them
    foreach (FuncDef f in program.GetFuncs()) {
      List<BB> funcBlocks = BB.FromStmtList(f.StmtList);
      CFG funcCfg = new CFG(funcBlocks);
      CFGFuncDef cfgFuncDef = new CFGFuncDef(f.Name,
                                             f.Params,
                                             f.RetType,
                                             funcCfg,
                                             f.Exported);

      cfgProgram.AddFunc(cfgFuncDef);
    }

    // add all extern functions (which have no body so don't need conversion)
    foreach (ExternFuncDef f in program.GetExternFuncs()) {
      cfgProgram.AddExternFunc(f);
    }

    // add all structs
    foreach (Struct s in program.GetStructs()) {
      cfgProgram.AddStruct(s);
    }

    return cfgProgram;
  }
}
