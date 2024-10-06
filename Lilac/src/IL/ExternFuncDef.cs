namespace Lilac.IL;

public record ExternFuncDef(string FuncSource,
                            string FuncName,
                            DeepEqualList<Type> ParamTypes,
                            Type RetType)
  : Component, INamed<(string, string)> {
  public string FuncSource { get; } = FuncSource;
  public string FuncName { get; } = FuncName;
  public DeepEqualList<Type> ParamTypes { get; } = ParamTypes;
  public Type RetType { get; } = RetType;

  public (string, string) Name => (FuncSource, FuncName);

  public override string ToString() =>
    $"(ExternFuncParam Source={FuncSource} Name={FuncName} " +
    $"ParamTypes={String.Join(", ", ParamTypes)} RetType={RetType})";
}
