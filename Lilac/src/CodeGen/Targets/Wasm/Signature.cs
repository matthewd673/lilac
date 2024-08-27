using Type = Lilac.CodeGen.Targets.Wasm.Instructions.Type;

internal class Signature(List<Type> @params, List<Type> results) {
  private const int hashSeed = 487;
  private const int hashModifier = 31;

  public List<Type> Params { get; } = @params;
  public List<Type> Results { get; } = results;

  public override bool Equals(object? obj) {
    if (obj is null || obj is not Signature other) {
      return false;
    }

    return Params.SequenceEqual(other.Params) &&
      Results.SequenceEqual(other.Results);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetListHashCode(Params), GetListHashCode(Results));
  }

  // NOTE: Adapted from https://stackoverflow.com/a/30758270 (including hash
  // seed and modifier)
  private int GetListHashCode<T>(List<T> list) where T : notnull {
    unchecked {
      return list.Aggregate(hashSeed,
        (current, item) => (current * hashModifier) + item.GetHashCode()
      );
    }
  }
}
