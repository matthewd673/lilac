using System.Collections;
using System.Security.Cryptography;

namespace Lilac;

/// <summary>
/// A NamedCollection of items with <c>string</c> names.
/// </summary>
/// <typeparam name="TItem">
///   The type of item in the collection. Must have a <c>string</c> name.
/// </typeparam>
public class NamedCollection<TItem> : NamedCollection<TItem, string>
  where TItem : INamed {
  // This is the "default" NamedCollection class.
}

/// <summary>
/// A NamedCollection is a collection of items with "names" making it easy to
/// add, remove, lookup, and enumerate them.
/// </summary>
/// <typeparam name="TItem">The type of item in the collection.</typeparam>
/// <typeparam name="TName">
///   The type of name of the items in the collection.
/// </typeparam>
public class NamedCollection<TItem, TName>
  : ICollection<TItem> where TItem : INamed<TName> where TName : notnull {
  private readonly Dictionary<TName, TItem> dict = [];

  public int Count => dict.Count;

  public bool IsReadOnly => false;

  /// <summary>
  /// Add a new item the collection.
  /// </summary>
  /// <param name="item">The item to add.</param>
  /// <exception cref="ArgumentException">
  ///   If an element with the same name already exists in the collection.
  /// </exception>
  public void Add(TItem item) {
    dict.Add(item.Name, item);
  }

  /// <summary>
  /// Enumerate over a collection of items and add them each to the collection.
  /// </summary>
  /// <param name="items">The collection of items to add.</param>
  /// <exception cref="ArgumentException">
  ///   If an element with the same name already exists in the collection.
  /// </exception>
  public void AddRange(IEnumerable<TItem> items) {
    foreach (TItem i in items) {
      Add(i);
    }
  }

  /// <summary>
  /// Get the item in the collection with a given name.
  /// </summary>
  /// <param name="name">The name of the item in the collection.</param>
  /// <returns>The item in the collection with the given name.</returns>
  /// <exception cref="KeyNotFoundException">
  ///   If no item with that name exists in the collection.
  /// </exception>
  public TItem this[TName name] {
    get => dict[name];
  }

  /// <summary>
  /// Get the item with a given name in the collection. If it does not exist,
  /// return a default value instead.
  /// </summary>
  /// <param name="name">The name of the item in the collection.</param>
  /// <param name="default">
  ///   The default value, returned if the item does not exist. May be null.
  /// </param>
  /// <returns>
  ///   The item with the given name in the collection or the provided default.
  /// </returns>
  public TItem? GetOrDefault(TName name, TItem? @default) {
    try {
      return dict[name];
    }
    catch (KeyNotFoundException) {
      return @default;
    }
  }

  /// <summary>
  /// Check if the collection contains an item with the given name.
  /// </summary>
  /// <param name="name">The name of the item to check for.</param>
  /// <returns>
  ///   <c>true</c> if an item with the given name exists.
  ///   <c>false</c> otherwise.
  /// </returns>
  public bool ContainsName(TName name) {
    return dict.ContainsKey(name);
  }

  public IEnumerator<TItem> GetEnumerator() => dict.Values.GetEnumerator();

  IEnumerator IEnumerable.GetEnumerator() => dict.Values.GetEnumerator();

  public void Clear() {
    dict.Clear();
  }

  /// <summary>
  /// Check if the collection contains a given item.
  /// This approaches an O(1) operation.
  /// </summary>
  /// <param name="item">The item to check for in the collection.</param>
  /// <returns>
  ///   <c>true</c> if the item exists in the collection.
  ///   <c>false</c> otherwise.
  /// </returns>
  public bool Contains(TItem item) {
    return dict.TryGetValue(item.Name, out TItem? found) && found.Equals(item);
  }

  public void CopyTo(TItem[] array, int arrayIndex) {
    int index = arrayIndex;
    foreach (TItem v in dict.Values) {
      array[index] = v;
      index += 1;
    }
  }

  public bool Remove(TItem item) => dict.Remove(item.Name);

  public override bool Equals(object? obj) {
    if (obj is null || obj is not NamedCollection<TItem, TName> other) {
      return false;
    }

    return Count.Equals(other.Count) && this.SequenceEqual(other);
  }

  public override int GetHashCode() => throw new NotImplementedException(); // TODO
}
