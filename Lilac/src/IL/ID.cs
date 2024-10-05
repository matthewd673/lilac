namespace Lilac.IL;

public abstract record ID(string Name) : Value, INamed {
  public string Name { get; } = Name;
}
