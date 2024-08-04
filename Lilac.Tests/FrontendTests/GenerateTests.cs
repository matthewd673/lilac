using Lilac.IL;
using Lilac.Frontend;

namespace Lilac.Tests.FrontendTests;

public class GenerateTests {
  [Fact]
  public void GenerateDefinition() {
    Program parsed = Parser.ParseFile("./Resources/definition.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateBinop() {
    Program parsed = Parser.ParseFile("./Resources/binop.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateExtern() {
    Program parsed = Parser.ParseFile("./Resources/extern.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateFunc() {
    Program parsed = Parser.ParseFile("./Resources/func.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateGlobals() {
    Program parsed = Parser.ParseFile("./Resources/globals.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateJzJnz() {
    Program parsed = Parser.ParseFile("./Resources/jz_jnz.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateLabelAndJmp() {
    Program parsed = Parser.ParseFile("./Resources/label_and_jmp.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GeneratePhi() {
    Program parsed = Parser.ParseFile("./Resources/phi.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateTypes() {
    Program parsed = Parser.ParseFile("./Resources/types.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }

  [Fact]
  public void GenerateUnop() {
    Program parsed = Parser.ParseFile("./Resources/unop.lilac");

    string generated = new Generator(parsed).Generate();
    Program reparsed = new Parser(generated).Parse();

    Assert.Equal(parsed, reparsed);
  }
}