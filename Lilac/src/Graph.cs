namespace Lilac;

/// <summary>
/// A Graph is a directed graph with nodes of a given type.
/// </summary>
/// <typeparam name="TNode">The type of the nodes in the graph.</typeparam>
public class Graph<TNode> where TNode : notnull {
  /// <summary>
  /// An Edge is an edge between two nodes in a Graph.
  /// </summary>
  public class Edge {
    /// <summary>
    /// The node that the Edge originates from.
    /// </summary>
    public TNode From { get; }
    /// <summary>
    /// The node that the Edge terminates at.
    /// </summary>
    public TNode To { get; }

    /// <summary>
    /// Construct a new Edge.
    /// </summary>
    /// <param name="from">The source node of the Edge.</param>
    /// <param name="to">The destination node of the Edge.</param>
    public Edge(TNode @from, TNode to) {
      From = @from;
      To = @to;
    }

    public override bool Equals(object? obj) {
      if (obj is null || obj.GetType() != typeof(Edge)) {
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

  private HashSet<TNode> nodes;
  private HashSet<Edge> edges;
  private Dictionary<TNode, HashSet<Edge>> incoming;
  private Dictionary<TNode, HashSet<Edge>> outgoing;

  /// <summary>
  /// The number of nodes in the graph.
  /// </summary>
  public int NodesCount => nodes.Count;

  /// <summary>
  /// The number of edges in the graph.
  /// </summary>
  public int EdgesCount => edges.Count;

  /// <summary>
  /// Construct a new Graph with no nodes and no edges.
  /// </summary>
  public Graph() {
    nodes = new();
    edges = new();
    incoming = new();
    outgoing = new();
  }

  /// <summary>
  /// Enumerate all of hte nodes in the Graph.
  /// </summary>
  /// <returns></returns>
  public IEnumerable<TNode> GetNodes() {
    foreach (TNode n in nodes) {
      yield return n;
    }
  }

  /// <summary>
  /// Enumerate all of the Edges in the Graph.
  /// </summary>
  /// <returns></returns>
  public IEnumerable<Edge> GetEdges() {
    foreach (Edge e in edges) {
      yield return e;
    }
  }

  /// <summary>
  /// Enumerate all of the incoming Edges of a given node (i.e. all of the Edges
  /// <c>e</c> in the Graph where <c>e.To == node</c>).
  /// </summary>
  /// <param name="node">The node to enumerate the incoming Edges for.</param>
  /// <returns></returns>
  public IEnumerable<Edge> GetIncoming(TNode node) {
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      foreach (Edge e in i) {
        yield return e;
      }
    }
  }

  /// <summary>
  /// Enumerate all of the outgoing Edges of a given node (i.e. all of the Edges
  /// <c>e</c> in the Graph where <c>e.From == node</c>).
  /// </summary>
  /// <param name="node">The node to enumerate the outgoing Edges for.</param>
  /// <returns></returns>
  public IEnumerable<Edge> GetOutgoing(TNode node) {
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      foreach (Edge e in o) {
        yield return e;
      }
    }
  }

  /// <summary>
  /// Get the number of incoming Edges of a given node in the Graph.
  /// </summary>
  /// <param name="node">
  ///   The node to get the number of incoming Edges for.
  /// </param>
  /// <returns>The number of incoming edges for the node.</returns>
  public int GetIncomingCount(TNode node) {
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  /// <summary>
  /// Get the number of outgoing Edges of a given node in the Graph.
  /// </summary>
  /// <param name="node">
  ///   The node to get the number of outgoing Edges for.
  /// </param>
  /// <returns>The number of outgoing edges for the node.</returns>
  public int GetOutgoingCount(TNode node) {
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      return o.Count;
    }

    return 0;
  }

  /// <summary>
  /// Enumerate all of the predecessors of a given node in the Graph, i.e. all
  /// of the nodes in the Graph with a directed Edge from them to the given
  /// node.
  /// </summary>
  /// <param name="node">The node to enumerate all predecessors for.</param>
  /// <returns></returns>
  public IEnumerable<TNode> GetPredecessors(TNode node) {
    foreach (Edge e in GetIncoming(node)) {
      yield return e.From;
    }
  }

  /// <summary>
  /// Enumerate all of the successors of a given node in the Graph, i.e. all
  /// of the nodes in the Graph with a directed Edge from the given node to
  /// them.
  /// </summary>
  /// <param name="node">The node to enumerate all successors for.</param>
  /// <returns></returns>
  public IEnumerable<TNode> GetSuccessors(TNode node) {
    foreach (Edge e in GetOutgoing(node)) {
      yield return e.To;
    }
  }

  /// <summary>
  /// Get the number of predecessors of a given node in the Graph.
  /// </summary>
  /// <param name="node">The node to get the number of predecessors for.</param>
  /// <returns>The number of predecessors of the given node.</returns>
  public int GetPredecessorsCount(TNode node) {
    // Copied from GetIncomingCount
    HashSet<Edge>? i;
    if (incoming.TryGetValue(node, out i)) {
      return i.Count;
    }

    return 0;
  }

  /// <summary>
  /// Get the number of successors of a given node in the Graph.
  /// </summary>
  /// <param name="node">The node to get the number of successors for.</param>
  /// <returns>The number of successors of the given node.</returns>
  public int GetSuccessorsCount(TNode node) {
    // Copied from GetOutgoingCount
    HashSet<Edge>? o;
    if (outgoing.TryGetValue(node, out o)) {
      return o.Count;
    }

    return 0;
  }

  /// <summary>
  /// Add a node to the Graph. It must be unique.
  /// </summary>
  /// <param name="node">The node to add.</param>
  /// <returns>
  ///   <c>true</c> if the node was added to the Graph, i.e. it did not exist
  ///   in the Graph before. <c>false</c> otherwise.
  /// </returns>
  public bool AddNode(TNode node) {
    if (!nodes.Add(node)) {
      return false;
    }

    // Prepare dict entries for this node
    incoming.Add(node, []);
    outgoing.Add(node, []);

    return true;
  }

  /// <summary>
  /// Remove a node from the Graph and remove all of the Edges connected to it.
  /// </summary>
  /// <param name="node">The node to remove.</param>
  /// <returns>
  ///   <c>true</c> if the node (and all of its connecting edges) was removed.
  ///   <c>false</c> otherwise, i.e. it did not exist in the Graph.
  /// </returns>
  public bool RemoveNode(TNode node) {
    bool removed = nodes.Remove(node);

    if (!removed) {
      return removed;
    }

    // Remove all connecting edges
    foreach (Edge e in GetIncoming(node)) {
      RemoveEdge(e);
    }

    foreach (Edge e in GetOutgoing(node)) {
      RemoveEdge(e);
    }

    // Clean up associated dict entries
    incoming.Remove(node);
    outgoing.Remove(node);

    return removed;
  }

  /// <summary>
  /// Add an Edge to the Graph. It must be unique and both of its nodes must
  /// exist in the Graph.
  /// </summary>
  /// <param name="edge">The Edge to add to the Graph.</param>
  /// <returns>
  ///   <c>true</c> if the Edge was added to the Graph. <c>false</c> otherwise.
  /// </returns>
  public bool AddEdge(Edge edge) {
    // Do not add an Edge unless both of its nodes are present in the Graph.
    if (!nodes.Contains(edge.To) || !nodes.Contains(edge.From)) {
      return false;
    }

    bool added = edges.Add(edge);

    if (!added) {
      return added;
    }

    // Add this edge to "from"'s outgoing
    outgoing[edge.From].Add(edge);

    // Add this edge to "to"'s incoming
    incoming[edge.To].Add(edge);

    return true;
  }

  /// <summary>
  /// Remove an Edge from the Graph.
  /// </summary>
  /// <param name="edge">The Edge to remove.</param>
  /// <returns>
  ///   <c>true</c> if the Edge was removed from the Graph.
  ///   <c>false</c> otherwise, i.e. it did not exist in the Graph.
  /// </returns>
  public bool RemoveEdge(Edge edge) {
    bool removed = edges.Remove(edge);

    if (!removed) {
      return removed;
    }

    // remove this edge from "from"'s outgoing
    outgoing[edge.From].Remove(edge);

    // remove this edge from "to"'s incoming
    incoming[edge.To].Remove(edge);

    return true;
  }

  /// <summary>
  /// Enumerate a postorder traversal of the Graph starting with the given node.
  /// </summary>
  /// <param name="node">The node to start traversing from.</param>
  /// <returns></returns>
  public IEnumerable<TNode> PostorderTraversal(TNode node) {
    foreach (TNode n in PostorderTraversalHelper(node, [])) {
      yield return n;
    }
  }

  /// <summary>
  /// Compute a postorder numbering of the Graph starting with the given node.
  /// </summary>
  /// <param name="node">The node to start numbering from.</param>
  /// <returns>
  ///   A mapping between nodes and their computed postorder numbering. Nodes
  ///   in the Graph that are not accessible from the starting node may not
  ///   be included in the mapping.
  /// </returns>
  public Dictionary<TNode, int> ComputePostorderNumbering(TNode node) {
    Dictionary<TNode, int> numbering = [];

    int i = 0;
    foreach (TNode n in PostorderTraversal(node)) {
      numbering.Add(n, i);
      i += 1;
    }

    return numbering;
  }

  /// <summary>
  /// Compute a reverse postorder numbering of the Graph starting with the
  /// given node.
  /// </summary>
  /// <param name="node">The node to start numbering from.</param>
  /// <returns>
  ///   A mapping between nodes and their computed reverse postorder numbering.
  ///   Nodes in the Graph that are not accessible from the starting node may
  ///   not be included in the mapping.
  /// </returns>
  public Dictionary<TNode, int> ComputeReversePostorderNumbering(TNode node) {
    Dictionary<TNode, int> numbering = [];

    int i = nodes.Count - 1;
    foreach (TNode n in PostorderTraversal(node)) {
      numbering.Add(n, i);
      i -= 1;
    }

    return numbering;
  }

  /// <summary>
  /// Enumerate a preorder traversal of the Graph starting with the given node.
  /// </summary>
  /// <param name="node">The node to start traversing from.</param>
  /// <returns></returns>
  public IEnumerable<TNode> PreorderTraversal(TNode node) {
    foreach (TNode n in PreorderTraversalHelper(node, [])) {
      yield return n;
    }
  }

  /// <summary>
  /// Compute a preorder numbering of the Graph starting with the given node.
  /// </summary>
  /// <param name="node">The node to start numbering from.</param>
  /// <returns>
  ///   A mapping between nodes and their computed preorder numbering. Nodes in
  ///   the Graph that are not accessible from the starting node may not be
  ///   included in the mapping.
  /// </returns>
  public Dictionary<TNode, int> ComputePreorderNumbering(TNode node) {
    Dictionary<TNode, int> numbering = [];

    int i = 0;
    foreach (TNode n in PostorderTraversal(node)) {
      numbering.Add(n, i);
      i += 1;
    }

    return numbering;
  }

  private IEnumerable<TNode> PostorderTraversalHelper(TNode node, HashSet<TNode> seen) {
    if (seen.Contains(node)) {
      yield break;
    }

    seen.Add(node);

    foreach (TNode s in GetSuccessors(node)) {
      foreach (TNode n in PostorderTraversalHelper(s, seen)) {
        yield return n;
      }
    }

    yield return node;
  }

  private IEnumerable<TNode> PreorderTraversalHelper(TNode node, HashSet<TNode> seen) {
    if (seen.Contains(node)) {
      yield break;
    }

    seen.Add(node);

    yield return node;

    foreach (TNode s in GetSuccessors(node)) {
      foreach (TNode n in PostorderTraversalHelper(s, seen)) {
        yield return n;
      }
    }
  }
}

