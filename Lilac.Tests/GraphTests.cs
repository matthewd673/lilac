namespace Lilac.Tests;

public class GraphTests {
  [Fact]
  public void AddNode() {
    Graph<Analysis.BB> graph = new();

    graph.AddNode(new("new_node"));

    Assert.Equal(1, graph.NodesCount);
    Assert.Equal(0, graph.EdgesCount);

    Assert.Equal("new_node", graph.GetNodes().First().Id);

    AssertGraphInvariants(graph);
  }

  [Fact]
  public void AddEdge() {
    Graph<Analysis.BB> graph = new();

    Analysis.BB a = new("a");
    Analysis.BB b = new("b");
    graph.AddNode(a);
    graph.AddNode(b);

    graph.AddEdge(new(a, b));

    Assert.Equal(2, graph.NodesCount);

    AssertGraphInvariants(graph);
  }

  [Fact]
  public void AddRemoveNode() {
    Graph<Analysis.BB> graph = new();

    Analysis.BB a = new("a");
    graph.AddNode(a);

    graph.RemoveNode(a);

    Assert.Equal(0, graph.NodesCount);

    AssertGraphInvariants(graph);
  }

  [Fact]
  public void AddRemoveEdge() {
    Graph<Analysis.BB> graph = new();

    Analysis.BB a = new("a");
    Analysis.BB b = new("b");
    graph.AddNode(a);
    graph.AddNode(b);

    Graph<Analysis.BB>.Edge e = new(a, b);
    graph.AddEdge(e);

    graph.RemoveEdge(e);

    Assert.Equal(2, graph.NodesCount);
    Assert.Equal(0, graph.EdgesCount);

    AssertGraphInvariants(graph);
  }

  [Fact]
  public void AddRemoveConnectedNode() {
    Graph<Analysis.BB> graph = new();

    Analysis.BB a = new("a");
    Analysis.BB b = new("b");
    graph.AddNode(a);
    graph.AddNode(b);

    Graph<Analysis.BB>.Edge e = new(a, b);
    graph.AddEdge(e);

    graph.RemoveNode(b);

    Assert.Equal(1, graph.NodesCount);
    Assert.Equal(0, graph.EdgesCount);

    AssertGraphInvariants(graph);
  }

  [Fact]
  public void AddSameEdgeTwice() {
    Graph<Analysis.BB> graph = new();

    Analysis.BB a = new("a");
    Analysis.BB b = new("b");
    graph.AddNode(a);
    graph.AddNode(b);

    Graph<Analysis.BB>.Edge e = new(a, b);
    Graph<Analysis.BB>.Edge f = new(a, b);

    graph.AddEdge(e);
    graph.AddEdge(f);

    Assert.Equal(2, graph.NodesCount);
    Assert.Equal(1, graph.EdgesCount);

    AssertGraphInvariants(graph);
  }

  private void AssertGraphInvariants<T>(Graph<T> graph) where T : notnull {
    AssertIncomingOutgoingEdgeParity(graph);
    AssertIncomingToIsNode(graph);
    AssertOutgoingFromIsNode(graph);
  }

  private void AssertIncomingOutgoingEdgeParity<T>(Graph<T> graph)
    where T : notnull {
    List<Graph<T>.Edge> incoming = new();
    List<Graph<T>.Edge> outgoing = new();

    foreach (T n in graph.GetNodes()) {
      incoming.AddRange(graph.GetIncoming(n));
      outgoing.AddRange(graph.GetOutgoing(n));
    }

    Assert.Equal(incoming.Count, outgoing.Count);
    Assert.Equal(graph.EdgesCount * 2, incoming.Count + outgoing.Count);

    foreach (Graph<T>.Edge e in incoming) {
      Assert.Contains(e, graph.GetEdges());
    }

    foreach (Graph<T>.Edge e in outgoing) {
      Assert.Contains(e, graph.GetEdges());
    }
  }

  private void AssertIncomingToIsNode<T>(Graph<T> graph) where T : notnull {
    foreach (T n in graph.GetNodes()) {
      foreach (Graph<T>.Edge e in graph.GetIncoming(n)) {
        Assert.True(e.To.Equals(n));
      }
    }
  }

  private void AssertOutgoingFromIsNode<T>(Graph<T> graph) where T : notnull {
    foreach (T n in graph.GetNodes()) {
      foreach (Graph<T>.Edge e in graph.GetOutgoing(n)) {
        Assert.True(e.From.Equals(n));
      }
    }
  }
}
