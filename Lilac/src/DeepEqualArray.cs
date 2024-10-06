using System.Collections;

namespace Lilac;

/// <summary>
/// A DeepequalArray is an Array that implements deep equality checks for the
/// Equals and GetHashCode methods.
/// </summary>
/// <typeparam name="T">The type of element in the array.</typeparam>
public class DeepEqualArray<T> : IEnumerable<T> {
  private const int HashSeed = 487;
  private const int HashModifier = 31;

  /// <summary>
  /// The underlying array. Accessing this directly will not affect the behavior
  /// of the DeepEqualArray.
  /// </summary>
  public T[] Array { get; }

  public T this[int index] => Array[index];

  /// <summary>
  /// Construct a new empty DeepEqualArray.
  /// </summary>
  public DeepEqualArray() {
    Array = [];
  }

  /// <summary>
  /// Construct a new DeepEqualArray with a given length.
  /// </summary>
  /// <param name="length">The length of the array to construct.</param>
  public DeepEqualArray(int length) {
    Array = new T[length];
  }

  /// <summary>
  /// Construct a new DeepEqualArray with the given array as its underlying
  /// array.
  /// </summary>
  /// <param name="array">
  ///   The underlying array of the new DeepEqualArray.
  /// </param>
  public DeepEqualArray(T[] array) {
    Array = array;
  }

  public IEnumerator<T> GetEnumerator() {
    // NOTE: Casting the Array's existing methods threw a dynamic semantic exception.
    foreach (T e in Array) {
      yield return e;
    }
  }

  IEnumerator IEnumerable.GetEnumerator() => Array.GetEnumerator();

  public override bool Equals(object? obj) =>
    obj is DeepEqualArray<T> other && this.SequenceEqual(other);

  // NOTE: Adapted from https://stackoverflow.com/a/30758270
  public override int GetHashCode() {
    unchecked {
      return this.Aggregate(HashSeed,
        (current, element) => (current * HashModifier) + element.GetHashCode()
      );
    }
  }
}
