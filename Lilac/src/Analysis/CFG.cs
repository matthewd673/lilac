namespace Lilac.Analysis;

public class CFG : Graph<BB> {
  public const string EntryId = "ENTRY";
  public const string ExitId = "EXIT";

  public BB Entry;
  public BB Exit;

  public CFG() : base() {
    // create an ENTRY and an EXIT node
    // NOTE: ENTRY and EXIT are not connected by default
    Entry = new(EntryId, stmtList: new());
    Exit = new(ExitId, stmtList: new());

    AddNode(Entry);
    AddNode(Exit);
  }

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
    Dictionary<string, BB> labelMap = new();

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
        BB successor = labelMap[jump.Target];

        // unlikely but maybe possible
        if (successor is null) {
          // TODO: use a special exception type
          throw new Exception($"CFG attempted to build edge to label that doesn't exist: \"{jump.Target}\"");
        }

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
