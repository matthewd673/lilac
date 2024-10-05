namespace Lilac.IL;

public record ExternFuncDef(string FuncSource,
                            string FuncName,
                            List<Type> ParamTypes,
                            Type RetType)
  : Component, INamed<(string, string)> {
  public string FuncSource { get; } = FuncSource;
  public string FuncName { get; } = FuncName;
  public List<Type> ParamTypes { get; } = ParamTypes;
  public Type RetType { get; } = RetType;

  public (string, string) Name => (FuncSource, FuncName);

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), FuncSource, FuncName, ParamTypes, RetType);

  public override string ToString() =>
    $"(ExternFuncParam Source={FuncSource} Name={FuncName} " +
    $"ParamTypes={String.Join(", ", ParamTypes)} RetType={RetType})";
}
