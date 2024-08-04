using Lilac.IL;
using Type = Lilac.IL.Type;
using Lilac.Analysis;

namespace Lilac.Tests.AnalysisTests;

public class ReducibleTests {
  [Fact]
  public void ReducibleOne() {
    CFG cfg = new();

    BB a = cfg.Entry;
    BB b = cfg.Exit;
    BB c = new(Guid.NewGuid().ToString());
    BB d = new(Guid.NewGuid().ToString());

    cfg.AddNode(c);
    cfg.AddNode(d);

    cfg.AddEdge(new(a, b));
    cfg.AddEdge(new(a, c));
    cfg.AddEdge(new(b, d));
    cfg.AddEdge(new(c, d));

    Assert.True(new Reducible(cfg).Run());
  }

  [Fact]
  public void ReducibleTwo() {
    CFG cfg = new();

    BB a = cfg.Entry;
    BB b = cfg.Exit;
    BB c = new(Guid.NewGuid().ToString());

    cfg.AddNode(c);

    cfg.AddEdge(new(a, b));
    cfg.AddEdge(new(b, b));
    cfg.AddEdge(new(b, c));

    Assert.True(new Reducible(cfg).Run());
  }

  [Fact]
  public void IrreducibleOne() {
    CFG cfg = new();

    BB a = cfg.Entry;
    BB b = cfg.Exit;
    BB c = new(Guid.NewGuid().ToString());

    cfg.AddNode(c);

    cfg.AddEdge(new(a, b));
    cfg.AddEdge(new(a, c));
    cfg.AddEdge(new(b, c));
    cfg.AddEdge(new(c, b));

    Assert.False(new Reducible(cfg).Run());
  }

  [Fact]
  public void IrreducibleTwo() {
    CFG cfg = new();

    BB a = cfg.Entry;
    BB b = cfg.Exit;
    BB c = new(Guid.NewGuid().ToString());
    BB d = new(Guid.NewGuid().ToString());

    cfg.AddNode(c);
    cfg.AddNode(d);

    cfg.AddEdge(new(a, b));
    cfg.AddEdge(new(b, d));
    cfg.AddEdge(new(c, d));

    Assert.False(new Reducible(cfg).Run());
  }
}