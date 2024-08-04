namespace Lilac.CodeGen;

public abstract class Generator {
  protected Component RootComp { get; }

  public Generator(Component rootComp) {
    RootComp = rootComp;
  }

  public abstract String Generate();
}