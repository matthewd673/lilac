namespace Lilac;

abstract class Pass {
  public string Id { get; }

  public abstract void Run();

  public override string ToString() {
    return Id;
  }
}
