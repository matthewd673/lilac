using Lilac.IL;

namespace Lilac.Tests;

public class DeepEqualListTests {
  [Fact]
  public void EmptyEqualsEmpty() {
    Assert.False(new List<int>().Equals(new List<int>())); // Control
    Assert.True(new DeepEqualList<int>().Equals(new DeepEqualList<int>()));
  }

  [Fact]
  public void EmptyWithDifferentTypesNotEqual() {
    Assert.False(new DeepEqualList<long>().Equals(new DeepEqualList<int>()));
  }

  [Fact]
  public void PrimitiveElementsEquals() {
    List<int> a = [1, 2, 3, 4, 5];
    List<int> b = [1, 2, 3, 4, 5];
    Assert.False(a.Equals(b)); // Control

    DeepEqualList<int> c = [1, 2, 3, 4, 5];
    DeepEqualList<int> d = [1, 2, 3, 4, 5];
    Assert.True(c.Equals(d));
  }

  [Fact]
  public void ObjectElementsEqual() {
    List<LocalID> a = [new("a"), new("b"), new("c")];
    List<LocalID> b = [new("a"), new("b"), new("c")];
    Assert.False(a.Equals(b)); // Control

    DeepEqualList<LocalID> c = [new("a"), new("b"), new("c")];
    DeepEqualList<LocalID> d = [new("a"), new("b"), new("c")];
    Assert.True(c.Equals(d));
  }

  [Fact]
  public void FromListIsSequenceEqual() {
    List<LocalID> a = [new("a"), new("b"), new("c")];
    DeepEqualList<LocalID> b = new(a);

    Assert.True(Enumerable.SequenceEqual(a, b));
  }
}
