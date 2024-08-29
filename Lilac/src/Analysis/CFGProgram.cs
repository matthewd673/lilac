using Lilac.IL;

namespace Lilac.Analysis;

public class CFGProgram : Program<CFGFuncDef> {
  public static CFGProgram FromProgram(Program<FuncDef> program) {
    // Create CFGProgram from main
    CFGProgram cfgProgram = new();

    // Copy over all components that don't need to be changed (e.g.: globals)
    cfgProgram.Globals.AddRange(program.Globals);
    cfgProgram.ExternFuncDefs.AddRange(program.ExternFuncDefs);
    cfgProgram.Structs.AddRange(program.Structs);

    // Convert all FuncDefs to CFGFuncDefs and add them
    cfgProgram.FuncDefs.AddRange(
      program.FuncDefs.Select(CFGFuncDef.FromFuncDef)
    );

    return cfgProgram;
  }
}
