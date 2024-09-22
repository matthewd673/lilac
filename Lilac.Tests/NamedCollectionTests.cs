using Lilac.IL;

namespace Lilac.Tests;

public class NamedCollectionTests {
  [Fact]
  public void Count() {
    NamedCollection<IL.ID> collection = [];
    collection.Add(new LocalID("a"));
    collection.Add(new LocalID("b"));
    collection.Add(new LocalID("c"));

    Assert.Equal(3, collection.Count);
  }

  [Fact]
  public void AddRange() {
    List<LocalID> range = [new("a"), new("b"), new("c")];
    NamedCollection<LocalID> collection = [];
    collection.AddRange(range);
    Assert.Equal(range, [.. collection]);
  }

  [Fact]
  public void AddWithDuplicatesThrowsException() {
    NamedCollection<LocalID> collection = [];
    Assert.Throws<ArgumentException>(
      () => { collection.AddRange([new("a"), new("b"), new("a"), new("c")]); }
    );
  }

  [Fact]
  public void GetIsEqualToInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("local");
    collection.Add(id);
    Assert.Equivalent(id, collection["local"]); // Shallow equality check
  }

  [Fact]
  public void GetOrDefaultIsEqualToInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("local");
    collection.Add(id);
    // Shallow equality check
    Assert.Equivalent(id, collection.GetOrDefault("local", null));
  }

  [Fact]
  public void GetOrDefaultIsEqualToDefaultWhenNotInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID defaultId = new("default");
    // Shallow equality check
    Assert.Equivalent(defaultId, collection.GetOrDefault("fake", defaultId));
  }

  [Fact]
  public void TryGetValueIsEqualToValueWhenInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("a");
    collection.Add(id);
    Assert.True(collection.TryGetValue("a", out LocalID got));
    Assert.Equivalent(id, got); // Shallow equality check
  }

  [Fact]
  public void TryGetValueIsFalseWhenNotInserted() {
    NamedCollection<LocalID> collection = [];
    Assert.False(collection.TryGetValue("a", out LocalID got));
  }

  [Fact]
  public void ContainsNameIsTrueWhenInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("local");
    collection.Add(id);
    Assert.True(collection.ContainsName("local"));
  }

  [Fact]
  public void ContainsNameIsFalseWhenNotInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("local");
    Assert.False(collection.ContainsName("local"));
  }

  [Fact]
  public void Clear() {
    NamedCollection<LocalID> collection = [];
    collection.AddRange([new("a"), new("b"), new("c")]);
    Assert.Equal(3, collection.Count);

    collection.Clear();

    Assert.Empty(collection);
  }

  [Fact]
  public void ContainsTrueWhenInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("a");
    collection.Add(id);
    Assert.Contains(id, collection);
  }

  [Fact]
  public void ContainsFalseWhenNotInserted() {
    NamedCollection<LocalID> collection = [];
    LocalID id = new("a");
    Assert.DoesNotContain(id, collection);
  }

  [Fact]
  public void CopyTo() {
    LocalID[] items = [new("a"), new("b"), new("c")];
    NamedCollection<LocalID> collection = new();
    collection.AddRange(items);

    LocalID[] copied = new LocalID[3];
    collection.CopyTo(copied, 0);

    Assert.Equal(items, copied);
  }

  [Fact]
  public void Remove() {
    NamedCollection<LocalID> collection = [];
    LocalID a = new("a");

    collection.AddRange([a, new("b"), new("c")]);
    Assert.Equal(3, collection.Count);
    Assert.True(collection.ContainsName("a"));

    collection.Remove(a);
    Assert.Equal(2, collection.Count);
    Assert.False(collection.ContainsName("a"));
  }

  [Fact]
  public void EqualsIsFalseForNull() {
    NamedCollection<LocalID> collection = [new("a"), new("b"), new("c")];
    Assert.False(collection.Equals(null));
  }

  [Fact]
  public void EqualsIsFalseForDifferentType() {
    NamedCollection<LocalID> collection = [new("a"), new("b"), new("c")];
    Assert.False(collection.Equals(new Dictionary<string, LocalID>()));
  }

  [Fact]
  public void EqualsIsFalseForDifferentContents() {
    NamedCollection<LocalID> a = [new("a"), new("b"), new("c")];
    NamedCollection<LocalID> b = [new("d"), new("e"), new("f")];
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void EqualsIsTrueForDeepEquality() {
    NamedCollection<LocalID> a = [new("a"), new("b"), new("c")];
    NamedCollection<LocalID> b = [new("a"), new("b"), new("c")];
    Assert.Equal(a, b);
  }

  // TODO: GetHashCode test (not implemented yet).
}
