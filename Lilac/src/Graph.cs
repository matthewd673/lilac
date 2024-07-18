namespace Lilac;

public class Graph<T> {
  public class Edge {
    public T From { get; }
    public T To { get; }

    public Edge(T @from, T to) {
      From = @from;
      To = @to;
    }

    public override bool Equals(object? obj) {
      if (obj.GetType() != typeof(Edge)) {
        return false;
      }

      Edge other = (Edge)obj;

      return From.Equals(other.From) && To.Equals(other.To);
    }

    public override int GetHashCode() {
      return HashCode.Combine(From, To);
    }

    public override string ToString() {
      return $"{From} -> {To}";
    }
  }

  private HashSet<T> nodes;
  private HashSet<Edge> edges;
  private Dictionary<T, HashSet<Edge>> incoming;
  private Dictionary<T, HashSet<Edge>> outgoing;

  public int NodesCount {
    get { return nodes.Count; }
  }

  public int EdgesCount {
    get { return edges.Count; }
  }

  public Graph() {
    nodes = new();
    edges = new();
    incoming = new();
    outgoing = new();
  }

  public IEnumerable<T> GetNodes() {
    foreach (T n in nodes) {
      yield return n;
    }
  }

  public IEnumerable<Edge> GetEdges() {
    foreach (Edge e in edges) {
      yield return e;
    }
  }

  public IEnumerable<Edge> GetIncoming(T node) {
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      foreach (Edge e in i) {
        yield return e;
      }
    }
  }

  public IEnumerable<Edge> GetOutgoing(T node) {
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      foreach (Edge e in o) {
        yield return e;
      }
    }
  }

  public int GetIncomingCount(T node) {
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  public int GetOutgoingCount(T node) {
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      return o.Count;
    }

    return 0;
  }

  public IEnumerable<T> GetPredecessors(T node) {
    foreach (Edge e in GetIncoming(node)) {
      yield return e.From;
    }
  }

  public IEnumerable<T> GetSuccessors(T node) {
    foreach (Edge e in GetOutgoing(node)) {
      yield return e.To;
    }
  }

  public int GetPredecessorsCount(T node) {
    // Copied from GetIncomingCount
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  public int GetSuccessorsCount(T node) {
    // Copied from GetOutgoingCount
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      return o.Count;
    }

    return 0;
  }

  public bool AddNode(T node) {
    return nodes.Add(node);
  }

  public bool RemoveNode(T node) {
    bool removed = nodes.Remove(node);

    if (!removed) {
      return removed;
    }

    foreach (Edge e in GetIncoming(node)) {
      RemoveEdge(e);
    }

    foreach (Edge e in GetOutgoing(node)) {
      RemoveEdge(e);
    }

    return removed;
  }

  public bool AddEdge(Edge edge) {
    bool added = edges.Add(edge);

    if (!added) {
      return added;
    }

    // Add this edge to "from"'s outgoing
    if (!outgoing.ContainsKey(edge.From)) {
      outgoing[edge.From] = new();
    }
    outgoing[edge.From].Add(edge);

    // Add this edge to "to"'s incoming
    if (!incoming.ContainsKey(edge.To)) {
      incoming[edge.To] = new();
    }
    incoming[edge.To].Add(edge);

    return added;
  }

  public bool RemoveEdge(Edge edge) {
    bool removed = edges.Remove(edge);

    if (!removed) {
      return removed;
    }

    // remove this edge from "from"'s outgoing
    outgoing[edge.From].Remove(edge);

    // remove this edge from "to"'s incoming
    incoming[edge.To].Remove(edge);

    return removed;
  }
}

