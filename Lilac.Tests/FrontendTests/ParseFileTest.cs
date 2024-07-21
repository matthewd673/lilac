using Lilac.IL;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.FrontendTests;

public class ParseFileTest {
  [Fact]
  public void ParseDefinition() {
    Program expected = new();
    FuncDef main = new("main",
                       [],
                       Type.Void,
                       [
                         new Definition(Type.I32, new("a"),
                                        new ValueExpr(
                                         new Constant(Type.I32, 5)
                                         )),
                       ]
                      );
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/definition.lilac");

    Assert.Equal(expected, actual);
  }
}