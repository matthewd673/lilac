using Lilac.CodeGen.Targets.Wasm.Instructions;
using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

namespace Lilac.CodeGen.Targets.Wasm;

public class WatGenerator(WasmComponent rootComponent)
  : Generator(rootComponent) {
  public override string Generate() {
    return GenerateComponent(rootComponent);
  }

  private string GenerateRange(List<WasmComponent> compList,
                               string indent = "") {
    string str = "";
    foreach (WasmComponent c in compList) {
      str += $"{GenerateComponent(c, indent)}\n";
    }

    return str.TrimEnd();
  }

  private string GenerateRange(List<WasmInstruction> instList,
                               string indent = "") {
    string str = "";
    foreach (WasmInstruction i in instList) {
      str += $"{GenerateInstruction(i, indent)}\n";
    }

    str = str.TrimEnd();

    if (str.EndsWith("end")) {
      str = str.Remove(str.Length - 3);
    }

    return str;
  }

  private string GenerateComponent(WasmComponent comp, string indent = "") {
    return comp switch {
      Module module => GenerateModule(module, indent),
      Import import => GenerateImport(import, indent),
      Global global => GenerateGlobal(global, indent),
      Local local => GenerateLocal(local, indent),
      Start start => GenerateStart(start, indent),
      Func func => GenerateFunc(func, indent),
      _ => throw new ArgumentOutOfRangeException(nameof(comp), comp,
                                                 "Cannot generate component"),
    };
  }

  private string GenerateModule(Module module, string indent = "") =>
    $"{indent}(module\n{GenerateRange(module.Components, "  ")}\n)";

  private string GenerateImport(Import import, string indent = "") =>
    $"{indent}(func ${import.FuncName} " +
    $"(import \"{import.ModuleName}\" \"{import.FuncName}\")" +
    $"{StringifyParamTypes(import.ParamTypes)}" +
    $"{StringifyResultTypes(import.Results)}";

  private string GenerateGlobal(Global global, string indent = "") =>
    $"{indent}(global ${global.Name} " +
    $"{(global.Mutable ?
          $"(mut ${GenerateType(global.Type)}"
          : global.Type)} " +
    $"({GenerateInstruction(global.DefaultValue)})";

  private string GenerateLocal(Local local, string indent = "") =>
    $"{indent}(local ${local.Name} {GenerateType(local.Type)})";

  private string GenerateStart(Start start, string indent = "") =>
    $"{indent}(start ${start.Name})";

  private string GenerateFunc(Func func, string indent = "") =>
    $"{indent}(func ${func.Name}" +
    $"{(func.Export is not null ? $"(export \"{func.Export}\") " : " ")}" +
    $"{StringifyParams(func.Params)}{StringifyResultTypes(func.Results)}\n" +
    $"{StringifyLocals(func.LocalsDict, indent + "  ")}" +
    $"{GenerateRange(func.Instructions, indent + "  ")}\n{indent})";

  private string GenerateInstruction(WasmInstruction instruction,
                                     string indent = "") =>
    $"{indent}{instruction.Wat}";

  private string GenerateType(Type type, string indent = "") => type switch {
    Type.I32 => "i32",
    Type.I64 => "i64",
    Type.F32 => "f32",
    Type.F64 => "f64",
    _ => throw new ArgumentOutOfRangeException(),
  };

  private string StringifyParams(List<Local> @params) {
    string str = "";
    foreach (Local p in @params) {
      str += $"(param ${p.Name} {GenerateType(p.Type)}) ";
    }

    return str.TrimEnd();
  }

  private string StringifyLocals(Dictionary<Type, List<Local>> localsDict,
                                 string indent = "") {
    string str = "";
    foreach (List<Local> l in localsDict.Values) {
      str += $"{GenerateRange([..l], indent + "  ")}\n";
    }

    return str;
  }

  private string StringifyParamTypes(List<Type> paramTypes) {
    string str = " ";
    foreach (Type t in paramTypes) {
      str += $"(param {GenerateType(t)}) ";
    }

    return str.TrimEnd();
  }

  private string StringifyResultTypes(List<Type> resultTypes) {
    string str = "";
    foreach (Type t in resultTypes) {
      str += $" (result {GenerateType(t)})";
    }

    return str;
  }
}