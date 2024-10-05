namespace Lilac;

public abstract class Pass<TUnit> {
  public abstract string Id { get; }

  public abstract void Run();

  public override string ToString() {
    return Id;
  }
}
