namespace Lilac.IL;

public abstract class ID : Value {
  public string Name { get; }

  public ID(string name) {
    Name = name;
  }
}
