namespace Lilac.Analysis;

public class Reducible {
  private CFG cfg;

  public Reducible(CFG cfg) {
    this.cfg = cfg;
  }

  public bool Run() {
    // run until no more transformations can be applied
    bool applied = true;

    while (applied) {
      applied = false;

      // T1: remove all self-edges on a node
      foreach (BB n in cfg.GetNodes()) {
        foreach (CFG.Edge o in cfg.GetOutgoing(n)) {
          if (o.To != n) {
            continue;
          }

          cfg.RemoveEdge(o);
          applied = true;
          break;
        }
      }

      // T2: if n has a single predecessor m, fold n into m
      foreach (BB n in cfg.GetNodes()) {
        if (cfg.GetPredecessorsCount(n) != 1) {
          continue;
        }

        BB m = cfg.GetPredecessors(n).First();
        MergeNodes(n, m);
        applied = true;
      }
    }

    return cfg.NodesCount == 1;
  }

  private void MergeNodes(BB n, BB m) {
    // remove edge from m -> n
    CFG.Edge mnEdge = new(m, n);

    cfg.RemoveEdge(mnEdge);

    // make any edges originating from n originate from m instead
    foreach (CFG.Edge o in cfg.GetOutgoing(n)) {
      CFG.Edge newEdge = new(m, o.To);
      cfg.RemoveEdge(o);
      cfg.AddEdge(newEdge);
    }

    // if there are now multiple edges from m to some node, remove them
    HashSet<BB> seenTo = new();
    foreach (CFG.Edge o in cfg.GetOutgoing(m)) {
      // duplicate
      if (seenTo.Contains(o.To)) {
        cfg.RemoveEdge(o);
      }

      seenTo.Add(o.To);
    }

    // remove n
    cfg.RemoveNode(n);
  }
}
