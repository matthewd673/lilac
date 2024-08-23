namespace Lilac.IL;

public class ExternFuncDef(string source,
                           string name,
                           List<Type> paramTypes,
                           Type retType)
  : Component {
  public string Source { get; } = source;
  public string Name { get; } = name;
  public List<Type> ParamTypes { get; } = paramTypes;
  public Type RetType { get; } = retType;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ExternFuncDef)) {
      return false;
    }

    ExternFuncDef other = (ExternFuncDef)obj;
    return Source.Equals(other.Source) && Name.Equals(other.Name) &&
           ParamTypes.SequenceEqual(other.ParamTypes) &&
           RetType.Equals(other.RetType);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Source, Name, ParamTypes, RetType);
  }

  public override ExternFuncDef Clone() =>
    new(Source, Name, ParamTypes, RetType);

  public override string ToString() =>
    $"(ExternFuncParam Source={Source} Name={Name} " +
    $"ParamTypes={String.Join(", ", ParamTypes)} RetType={RetType})";
}
