namespace Lilac.Analysis;

class DomTree : Graph<BB> {
  public DomTree(CFGFacts<BB> domCfgFacts) : base() {
    ComputeGraph(domCfgFacts);
  }

  public BB? IDom(BB node) =>
    GetIncomingCount(node) == 0
      ? null
      // NOTE: There will only be one IDOM in a valid CFG
      // TODO: Verify this invariant
      : GetPredecessors(node).First();

  public IEnumerable<BB> GetSDom(BB node) {
    // yield each predecessor and recurse on them
    foreach (BB p in GetPredecessors(node)) {
      yield return p;
      foreach (BB rec in GetSDom(p)) {
        yield return rec;
      }
    }
  }

  public IEnumerable<BB> GetDomBy(BB node) {
    yield return node;
    foreach (BB s in GetSuccessors(node)) {
      foreach (BB rec in GetDomBy(s)) {
        yield return rec;
      }
    }
  }

  private void ComputeGraph(CFGFacts<BB> domCfgFacts) {
    foreach (BB n in domCfgFacts.CFG.GetNodes()) {
      AddNode(n);

      // find IDOM and create an edge from it to this block
      BB? idom = ComputeIDom(domCfgFacts, n);

      if (idom is null) {
        // only ENTRY should have a null IDOM
        if (n != domCfgFacts.CFG.Entry) {
          throw new Exception(); // TODO: throw a nice exception
        }

        continue;
      }

      AddEdge(new(idom, n));
    }
  }

  private static BB? ComputeIDom(CFGFacts<BB> domCfgFacts, BB node) {
    BB? idom = null;
    int idomDist = -1;

    foreach (BB d in domCfgFacts.GetFact("out", node)) {
      int domDist = FindDomDist(domCfgFacts.CFG, node, d, 0);
      if (domDist > 0 && (idomDist == -1 || domDist < idomDist)) {
        idom = d;
      }
    }

    return idom;
  }

  private static int FindDomDist(CFG cfg, BB node, BB dom, int dist) {
    // Check if self is Dom, and if so, stop
    if (node == dom) {
      return dist;
    }

    // Recursively check for the first predecessor that is Dom
    try {
      return cfg.GetPredecessors(node)
              .Select(p => FindDomDist(cfg, p, dom, dist + 1))
              .First(newDist => newDist >= 0);
    }
    catch (InvalidOperationException) { // Dom was not found
      return -1;
    }
  }
}
