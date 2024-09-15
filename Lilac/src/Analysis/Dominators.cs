namespace Lilac.Analysis;

class Dominators(CFG cfg)
  : DFA<BB>(Direction.Forwards,
            [cfg.Entry], // boundary
            cfg.GetNodes().ToHashSet(), // init
            cfg) {
  private readonly HashSet<BB> allNodes = cfg.GetNodes().ToHashSet();

  protected override void InitSets(BB block) {
    Gen.Add(block, [block]);
    Kill.Add(block, []);
  }

  protected override HashSet<BB> Transfer(BB block) {
    // union of IN[B] and GEN[B]
    return GetSet(In, block).Union(GetSet(Gen, block)).ToHashSet();
  }

  protected override HashSet<BB> Meet(BB block) {
    // intersection of OUT[P] for all predecessors P of B
    HashSet<BB> i = allNodes;
    int preds = 0;

    foreach (BB p in CFG.GetPredecessors(block)) {
      preds += 1;
      i = i.Intersect(GetSet(Out, p)).ToHashSet();
    }

    // no predecessors = return empty set
    if (preds == 0) {
      return [];
    }

    return i;
  }
}
