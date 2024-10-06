namespace Lilac.CodeGen.Targets.Wasm;

using Type = Instructions.Type;

internal record Signature(DeepEqualList<Type> Params,
                          DeepEqualList<Type> Results) {
  public DeepEqualList<Type> Params { get; } = Params;
  public DeepEqualList<Type> Results { get; } = Results;

  public override int GetHashCode() => HashCode.Combine(Params, Results);
}
