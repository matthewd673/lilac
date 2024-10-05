namespace Lilac.IL;

public record GlobalDef(Type Type, GlobalID Id, Constant Rhs)
  : Component, INamed {
  public Type Type { get; } = Type;
  public GlobalID Id { get; } = Id;
  public Constant Rhs { get; } = Rhs;

  public string Name => Id.Name;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), Type, Id, Rhs);

  public override string ToString() =>
    $"(GlobalDef Type={Type} Id={Id} Rhs={Rhs})";
}
