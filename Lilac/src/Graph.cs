namespace Lilac;

class Graph<T> {
  public class Edge<T> {
    public T From { get; }
    public T To { get; }

    public Edge(T @from, T to) {
      From = @from;
      To = @to;
    }

    public override bool Equals(object? obj) {
      if (obj.GetType() != typeof(Edge<T>)) {
        return false;
      }

      Edge<T> other = (Edge<T>)obj;

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
  private HashSet<Edge<T>> edges;
  private Dictionary<T, HashSet<Edge<T>>> incoming;
  private Dictionary<T, HashSet<Edge<T>>> outgoing;

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

  public IEnumerable<Edge<T>> GetEdges() {
    foreach (Edge<T> e in edges) {
      yield return e;
    }
  }

  public IEnumerable<Edge<T>> GetIncoming(T node) {
    HashSet<Edge<T>>? i;
    if (incoming.TryGetValue(node, out i)) {
      foreach (Edge<T> e in i) {
        yield return e;
      }
    }
  }

  public IEnumerable<Edge<T>> GetOutgoing(T node) {
    HashSet<Edge<T>>? o;
    if (outgoing.TryGetValue(node, out o)) {
      foreach (Edge<T> e in o) {
        yield return e;
      }
    }
  }

  public int GetIncomingCount(T node) {
    HashSet<Edge<T>>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  public int GetOutgoingCount(T node) {
    HashSet<Edge<T>>? o;
    if (outgoing.TryGetValue(node, out o)) {
      return o.Count;
    }

    return 0;
  }

  public IEnumerable<T> GetPredecessors(T node) {
    foreach (Edge<T> e in GetIncoming(node)) {
      yield return e.From;
    }
  }

  public IEnumerable<T> GetSuccessors(T node) {
    foreach (Edge<T> e in GetOutgoing(node)) {
      yield return e.To;
    }
  }

  public int GetPredecessorsCount(T node) {
    // Copied from GetIncomingCount
    HashSet<Edge<T>>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  public int GetSuccessorsCount(T node) {
    // Copied from GetOutgoingCount
    HashSet<Edge<T>>? o;
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

    foreach (Edge<T> e in GetIncoming(node)) {
      RemoveEdge(e);
    }

    foreach (Edge<T> e in GetOutgoing(node)) {
      RemoveEdge(e);
    }

    return removed;
  }

  public bool AddEdge(Edge<T> edge) {
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

  public bool RemoveEdge(Edge<T> edge) {
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

