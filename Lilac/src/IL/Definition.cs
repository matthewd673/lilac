namespace Lilac.IL;

public record Definition(Type Type, ID Id, Expression Rhs) : Statement {
  public Type Type { get; } = Type;
  public ID Id { get; } = Id;
  public Expression Rhs { get; } = Rhs;

  public override string ToString() =>
    $"(Definition Type={Type} Id={Id} Rhs={Rhs})";
}
