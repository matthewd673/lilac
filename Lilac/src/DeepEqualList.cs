namespace Lilac;

/// <summary>
/// A DeepEqualList is a List that implements deep equality checks for the
/// Equals and GetHashCode methods.
/// </summary>
/// <typeparam name="T">The type of element in the list.</typeparam>
public class DeepEqualList<T> : List<T> {
  private const int HashSeed = 487;
  private const int HashModifier = 31;

  /// <summary>
  /// Construct a new empty DeepEqualList.
  /// </summary>
  public DeepEqualList() : base() {
    // Empty
  }

  /// <summary>
  /// Construct a DeepEqualList from an IEnumerable.
  /// </summary>
  /// <param name="sequence">
  ///   The sequence to collect into a DeepEqualList. Must be finite.
  /// </param>
  public DeepEqualList(IEnumerable<T> sequence) {
    AddRange(sequence);
  }

  public override bool Equals(object? obj) =>
    obj is DeepEqualList<T> other && this.SequenceEqual(other);

  // NOTE: Adapted from https://stackoverflow.com/a/30758270
  public override int GetHashCode() {
    unchecked {
      return this.Aggregate(HashSeed,
        (current, element) => (current * HashModifier) + element.GetHashCode()
      );
    }
  }
}
