using System.Collections;

namespace Lilac;

public class NamedCollection<TItem> : NamedCollection<TItem, string>
  where TItem : INamed<string> {
  // This is the "default" NamedCollection class.
}

public class NamedCollection<TItem, TName>
  : ICollection<TItem> where TItem : INamed<TName> where TName : notnull {
  private readonly Dictionary<TName, TItem> dict = [];

  public int Count => dict.Count;

  public bool IsReadOnly => false;

  public void Add(TItem item) {
    dict.Add(item.Name, item);
  }

  public void AddRange(IEnumerable<TItem> items) {
    foreach (TItem i in items) {
      Add(i);
    }
  }

  public TItem this[TName name] {
    get => dict[name];
  }

  public TItem GetOrDefault(TName key, TItem @default) {
    try {
      return dict[key];
    }
    catch (KeyNotFoundException) {
      return @default;
    }
  }

  public bool ContainsName(TName name) {
    return dict.ContainsKey(name);
  }

  public IEnumerator<TItem> GetEnumerator() => dict.Values.GetEnumerator();

  IEnumerator IEnumerable.GetEnumerator() => dict.Values.GetEnumerator();

  public void Clear() {
    dict.Clear();
  }

  public bool Contains(TItem item) => dict.ContainsValue(item);

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
