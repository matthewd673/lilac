namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public record WasmComponent : Component {
  // Empty
}

public record Module(DeepEqualList<WasmComponent> Components) : WasmComponent {
  public DeepEqualList<WasmComponent> Components { get; } = Components;
}

public record Start(string Name) : WasmComponent {
  public string Name { get; } = Name;
}

public record Func(string Name,
                   DeepEqualList<Local> Params,
                   DeepEqualList<Type> Results,
                   Dictionary<Type, DeepEqualList<Local>> LocalsDict,
                   DeepEqualList<WasmInstruction> Instructions,
                   string? Export = null) : WasmComponent {
  public string Name { get; } = Name;
  public DeepEqualList<Local> Params { get; } = Params;
  public DeepEqualList<Type> Results { get; } = Results;
  public Dictionary<Type, DeepEqualList<Local>> LocalsDict { get; } = LocalsDict;
  public DeepEqualList<WasmInstruction> Instructions { get; } = Instructions;
  public string? Export { get; } = Export;
}

public record Local(Type Type, string Name) : WasmComponent {
  public Type Type { get; } = Type;
  public string Name { get; } = Name;
}

public record Global(Type Type,
                     string Name,
                     Const DefaultValue,
                     bool Mutable) : WasmComponent {
  public Type Type { get; } = Type;
  public string Name { get; } = Name;
  public Const DefaultValue { get; } = DefaultValue;
  public bool Mutable { get; } = Mutable;
}

public record Import(string ModuleName,
                     string FuncName,
                     DeepEqualList<Type> ParamTypes,
                     DeepEqualList<Type> Results) : WasmComponent {
  public string ModuleName { get; } = ModuleName;
  public string FuncName { get; } = FuncName;
  public DeepEqualList<Type> ParamTypes { get; } = ParamTypes;
  public DeepEqualList<Type> Results { get; } = Results;
}

public record Memory(int Size, string? Name = null) : WasmComponent {
  public int Size { get; } = Size;
  public string? Name { get; } = Name;
}
