namespace Lilac.Analysis;

class Dominators : DFA<BB> {
  private HashSet<BB> allNodes;

  public Dominators(CFG cfg)
    : base(Direction.Forwards,
           new() { cfg.Entry }, // boundary
           cfg.GetNodes().ToHashSet(), // init
           cfg) {
    allNodes = cfg.GetNodes().ToHashSet();
  }

  protected override void InitSets(BB block) {
    Gen.Add(block, new() { block });
    Kill.Add(block, new());
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
      return new();
    }

    return i;
  }
}
