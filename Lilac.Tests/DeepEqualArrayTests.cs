using Lilac.IL;

namespace Lilac.Tests;

public class DeepEqualArrayTests {
  [Fact]
  public void EmptyEqualsEmpty() {
    Assert.False(new int[0].Equals(new int[0])); // Control
    Assert.True(new DeepEqualArray<int>().Equals(new DeepEqualArray<int>()));
  }

  [Fact]
  public void EmptyWithDifferentTypesNotEqual() {
    Assert.False(new DeepEqualArray<int>().Equals(new DeepEqualArray<float>()));
  }

  [Fact]
  public void PrimitiveElementsEquals() {
    int[] a = [1, 2, 3, 4, 5];
    int[] b = [1, 2, 3, 4, 5];
    Assert.False(a.Equals(b)); // Control

    DeepEqualArray<int> c = new([1, 2, 3, 4, 5]);
    DeepEqualArray<int> d = new([1, 2, 3, 4, 5]);
    Assert.True(c.Equals(d));
  }

  [Fact]
  public void ObjectElementsEqual() {
    LocalID[] a = [new("a"), new("b"), new("c")];
    LocalID[] b = [new("a"), new("b"), new("c")];
    Assert.False(a.Equals(b)); // Control

    DeepEqualArray<LocalID> c = new([new("a"), new("b"), new("c")]);
    DeepEqualArray<LocalID> d = new([new("a"), new("b"), new("c")]);
    Assert.True(c.Equals(d));
  }

  [Fact]
  public void FromArrayIsSequenceEqual() {
    LocalID[] a = [new("a"), new("b"), new("c")];
    DeepEqualArray<LocalID> b = new(a);

    Assert.True(Enumerable.SequenceEqual(a, b));
  }
}
