namespace Lilac.CodeGen;

public abstract class Generator(Component rootComp) {
  protected Component RootComp { get; } = rootComp;

  public abstract string Generate();
}
