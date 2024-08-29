namespace Lilac;

public interface INamed : INamed<string> {
  // This is the "default" INamed interface.
}

public interface INamed<TName> where TName : notnull {
  public TName Name { get; }
}
