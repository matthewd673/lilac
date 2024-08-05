using Lilac.Analysis;
using Lilac.IL;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.AnalysisTests;

public class BBFromStmtListTests {
  [Fact]
  public void Simple() {
    List<Statement> stmtList = [
                                 new Definition(Type.I32,
                                                new("a"),
                                                new ValueExpr(new
                                                  Constant(Type.I32, 2))),
                               ];

    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Single(blocks);
    Assert.Null(blocks[0].Entry);
    Assert.Null(blocks[0].Exit);
    Assert.Equal(stmtList, blocks[0].StmtList);
  }

  [Fact]
  public void EntryAndExit() {
    List<Statement> stmtList = [
                                 new Label("label"),
                                 new Definition(Type.I32,
                                                new("a"),
                                                new ValueExpr(new
                                                       Constant(Type.I32, 2))),
                                 new Jump("label"),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Single(blocks);
    Assert.Equal(new Label("label"), blocks[0].Entry);
    Assert.Equal(new Jump("label"), blocks[0].Exit);
    Assert.Single(blocks[0].StmtList);
    Assert.Equal(new Definition(Type.I32,
                                new ID("a"),
                                new ValueExpr(new
                                                Constant(Type.I32, 2))),
                 blocks[0].StmtList[0]);
  }

  [Fact]
  public void BlocksSplitByLabel() {
    List<Statement> stmtList = [
                                 new VoidCall(new Call("a", [])),
                                 new Label("label"),
                                 new VoidCall(new Call("b", [])),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Equal(2, blocks.Count);
    Assert.Null(blocks[0].Entry);
    Assert.Equal(new Label("label"), blocks[1].Entry);
    Assert.Null(blocks[0].Exit);
    Assert.Null(blocks[1].Exit);
    Assert.Single(blocks[0].StmtList);
    Assert.Single(blocks[1].StmtList);
    Assert.Equal(new VoidCall(new Call("a", [])),
                 blocks[0].StmtList[0]);
    Assert.Equal(new VoidCall(new Call("b", [])),
                 blocks[1].StmtList[0]);
  }

  [Fact]
  public void BlocksSplitByJump() {
    List<Statement> stmtList = [
                                 new VoidCall(new Call("a", [])),
                                 new Jump("label"),
                                 new VoidCall(new Call("b", [])),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Equal(2, blocks.Count);
    Assert.Equal(new Jump("label"), blocks[0].Exit);
    Assert.Null(blocks[1].Exit);
    Assert.Null(blocks[0].Entry);
    Assert.Null(blocks[1].Entry);
    Assert.Single(blocks[0].StmtList);
    Assert.Single(blocks[1].StmtList);
    Assert.Equal(new VoidCall(new Call("a", [])),
                 blocks[0].StmtList[0]);
    Assert.Equal(new VoidCall(new Call("b", [])),
                 blocks[1].StmtList[0]);
  }

  [Fact]
  public void BlocksSplitByLabelAndJump() {
    List<Statement> stmtList = [
                                 new VoidCall(new Call("a", [])),
                                 new Jump("label"),
                                 new Label("label"),
                                 new VoidCall(new Call("b", [])),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Equal(2, blocks.Count);
    Assert.Equal(new Jump("label"), blocks[0].Exit);
    Assert.Equal(new Label("label"), blocks[1].Entry);
    Assert.Null(blocks[0].Entry);
    Assert.Null(blocks[1].Exit);
    Assert.Single(blocks[0].StmtList);
    Assert.Single(blocks[1].StmtList);
    Assert.Equal(new VoidCall(new Call("a", [])),
                 blocks[0].StmtList[0]);
    Assert.Equal(new VoidCall(new Call("b", [])),
                 blocks[1].StmtList[0]);
  }

  [Fact]
  public void LabelFirst() {
    List<Statement> stmtList = [
                                 new Label("label"),
                                 new VoidCall(new Call("a", [])),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Single(blocks);
    Assert.Equal(new Label("label"), blocks[0].Entry);
    Assert.Null(blocks[0].Exit);
    Assert.Single(blocks[0].StmtList);
    Assert.Equal(new VoidCall(new Call("a", [])), blocks[0].StmtList[0]);
  }

  [Fact]
  public void JumpLast() {
    List<Statement> stmtList = [
                                 new VoidCall(new Call("a", [])),
                                 new Jump("label"),
                               ];
    List<BB> blocks = BB.FromStmtList(stmtList);

    Assert.Single(blocks);
    Assert.Equal(new Jump("label"), blocks[0].Exit);
    Assert.Null(blocks[0].Entry);
    Assert.Single(blocks[0].StmtList);
    Assert.Equal(new VoidCall(new Call("a", [])), blocks[0].StmtList[0]);
  }
}