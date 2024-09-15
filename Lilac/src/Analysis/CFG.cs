namespace Lilac.Analysis;

/// <summary>
/// A CFG is a control flow graph with BBs as nodes and directed Edges between
/// them representing the control flow of a procedure.
/// </summary>
public class CFG : Graph<BB> {
  /// <summary>
  /// The ID used for the entry BB in a CFG. This ID is reserved and must not
  /// be used by any other BBs in a CFG.
  /// </summary>
  public const string EntryId = "ENTRY";
  /// <summary>
  /// The ID used for the exit BB in a CFG. This ID is reserved and must not be
  /// be used by any other BBs in a CFG.
  /// </summary>
  public const string ExitId = "EXIT";

  /// <summary>
  /// The entry BB in this CFG.
  /// </summary>
  public BB Entry;
  /// <summary>
  /// The exit BB in this CFG.
  /// </summary>
  public BB Exit;


  /// <summary>
  /// Construct a new CFG. It will contain a new entry and exit BB but will
  /// not contain any Edges.
  /// </summary>
  public CFG() : base() {
    // create an ENTRY and an EXIT node
    // NOTE: ENTRY and EXIT are not connected by default
    Entry = new(EntryId, stmtList: new());
    Exit = new(ExitId, stmtList: new());

    AddNode(Entry);
    AddNode(Exit);
  }

  /// <summary>
  /// Construct a new CFG from a list of BBs. These BBs will be added to the CFG
  /// and all Edges, including from and to the entry and exit BBs, will be
  /// computed.
  /// </summary>
  /// <param name="blocks">The list of BBs to construct the CFG from.</param>
  public CFG(List<BB> blocks) : base() {
    // create an ENTRY and an EXIT node
    Entry = new(EntryId, stmtList: new());
    Exit = new(ExitId, stmtList: new());

    AddNode(Entry);
    AddNode(Exit);

    // build the rest of the graph from the blocks list
    ComputeGraph(blocks);
  }

  public CFG Clone() {
    CFG newCfg = new();

    Dictionary<string, BB> nodeRefs = new() {
      { "ENTRY", newCfg.Entry },
      { "EXIT", newCfg.Exit },
    };

    foreach (BB n in GetNodes()) {
      // don't copy over old ENTRY and EXIT
      if (n == Entry || n == Exit) {
        continue;
      }

      nodeRefs[n.Id] = n.Clone();
      newCfg.AddNode(nodeRefs[n.Id]);
    }

    foreach (Edge e in GetEdges()) {
      newCfg.AddEdge(new(nodeRefs[e.From.Id], nodeRefs[e.To.Id]));
    }

    return newCfg;
  }

  private void ComputeGraph(List<BB> blocks) {
    // this can only ever be called at construction so it will never be run
    // more than once.
    Dictionary<string, BB> labelMap = [];

    // add all blocks to the graph nodes
    foreach (BB b in blocks) {
      AddNode(b);

      // if block has a Label, map that label to this block
      if (b.Entry is not null) {
        labelMap.Add(b.Entry.Name, b);
      }
    }

    // connect blocks into graph nodes
    for (int i = 0; i < blocks.Count; i++) {
      BB b = blocks[i];

      // create edge for block exit
      if (b.Exit is not null) {
        IL.Jump jump = b.Exit;
        BB successor = labelMap[jump.Target]
          ?? throw new Exception($"CFG attempted to build edge to label that doesn't exist: \"{jump.Target}\"");

        // create an edge to the target block
        // if jump is conditional then mark the successor as the "true branch"
        successor.TrueBranch = jump is IL.CondJump;
        AddEdge(new(b, successor));

        // if jump is NOT conditional then we don't need to connect a false
        // branch to the next block in the sequence
        if (jump is not IL.CondJump) {
          continue;
        }
      }

      // create an edge to the next block sequentially
      try {
        BB following = blocks[i + 1];
        following.TrueBranch = false;
        AddEdge(new(b, following));
      }
      // if there is no following block, connect to EXIT instead
      catch (ArgumentOutOfRangeException) {
        Exit.TrueBranch = false;
        AddEdge(new(b, Exit));
      }
    }

    // create an edge from ENTRY to first block
    try {
      BB first = blocks[0];
      first.TrueBranch = false;
      AddEdge(new(Entry, first));
    }
    // no blocks, create an edge from ENTRY to EXIT instead
    catch (ArgumentOutOfRangeException) {
      AddEdge(new(Entry, Exit));
    }
  }
}
