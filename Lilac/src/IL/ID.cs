namespace Lilac.IL;

public abstract class ID(string name) : Value, INamed {
  public string Name { get; } = name;
}
