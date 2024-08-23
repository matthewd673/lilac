namespace Lilac.IL;

public abstract class ID(string name) : Value {
  public string Name { get; } = name;
}
