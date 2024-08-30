namespace Lilac;

/// <summary>
/// An INamed interface with a <c>string</c> name.
/// </summary>
public interface INamed : INamed<string> {
  // This is the "default" INamed interface.
}

/// <summary>
/// The INamed interface defines a name for an object.
/// </summary>
/// <typeparam name="TName">The type of the object's name.</typeparam>
public interface INamed<TName> where TName : notnull {
  public TName Name { get; }
}
