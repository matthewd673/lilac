namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public class WasmComponent : Component {
  // NOTE: stub
}

public class Module(List<WasmComponent> components) : WasmComponent {
  public List<WasmComponent> Components { get; } = components;
}

public class Start(string name) : WasmComponent {
  public string Name { get; } = name;
}

public class Func(string name,
                  List<Local> @params,
                  List<Type> results,
                  Dictionary<Type, List<Local>> localsDict,
                  List<WasmInstruction> instructions,
                  string? export = null) : WasmComponent {
  public string Name { get; } = name;
  public List<Local> Params { get; } = @params;
  public List<Type> Results { get; } = results;
  public Dictionary<Type, List<Local>> LocalsDict { get; } = localsDict;
  public List<WasmInstruction> Instructions { get; } = instructions;
  public string? Export { get; } = export;
}

public class Local(Type type, string name) : WasmComponent {
  public Type Type { get; } = type;
  public string Name { get; } = name;
}

public class Global(Type type,
                    string name,
                    Const defaultValue,
                    bool mutable) : WasmComponent {
  public Type Type { get; } = type;
  public string Name { get; } = name;
  public Const DefaultValue { get; } = defaultValue;
  public bool Mutable { get; } = mutable;
}

public class Import(string moduleName,
                    string funcName,
                    List<Type> paramTypes,
                    List<Type> results) : WasmComponent {
  public string ModuleName { get; } = moduleName;
  public string FuncName { get; } = funcName;
  public List<Type> ParamTypes { get; } = paramTypes;
  public List<Type> Results { get; } = results;
}