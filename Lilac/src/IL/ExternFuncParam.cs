namespace Lilac.IL;

public class ExternFuncDef : Component {
  public string Source { get; }
  public string Name { get; }
  public List<Type> ParamTypes { get; }
  public Type RetType { get; }

  public ExternFuncDef(string source,
                       string name,
                       List<Type> paramTypes,
                       Type retType) {
    Source = source;
    Name = name;
    ParamTypes = paramTypes;
    RetType = retType;
  }

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
}
