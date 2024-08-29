namespace Lilac.IL;

public class ExternFuncDef(string funcSource,
                           string funcName,
                           List<Type> paramTypes,
                           Type retType)
  : Component, INamed<(string, string)> {
  public string FuncSource { get; } = funcSource;
  public string FuncName { get; } = funcName;
  public List<Type> ParamTypes { get; } = paramTypes;
  public Type RetType { get; } = retType;

  public (string, string) Name => (FuncSource, FuncName);

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ExternFuncDef)) {
      return false;
    }

    ExternFuncDef other = (ExternFuncDef)obj;
    return FuncSource.Equals(other.FuncSource) &&
           FuncName.Equals(other.FuncName) &&
           ParamTypes.SequenceEqual(other.ParamTypes) &&
           RetType.Equals(other.RetType);
  }

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), FuncSource, FuncName, ParamTypes, RetType);

  public override ExternFuncDef Clone() =>
    new(FuncSource, FuncName, ParamTypes, RetType);

  public override string ToString() =>
    $"(ExternFuncParam Source={FuncSource} Name={FuncName} " +
    $"ParamTypes={String.Join(", ", ParamTypes)} RetType={RetType})";
}
