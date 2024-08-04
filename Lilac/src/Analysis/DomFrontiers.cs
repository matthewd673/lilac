namespace Lilac.Analysis;

class DomFrontiers {
  private CFG cfg;
  private DomTree domTree;
  private Dictionary<BB, HashSet<BB>> df;

  public DomFrontiers(CFG cfg, DomTree domTree) {
    this.cfg = cfg;
    this.domTree = domTree;

    df = new();
    foreach (BB n in cfg.GetNodes()) {
      df.Add(n, new());
    }
  }

  public CFGFacts<BB> Run() {
    // DF algorithm
    // for each predecessor of each join node...
    foreach (BB j in cfg.GetNodes()) {
      // check if node is join node
      if (cfg.GetPredecessorsCount(j) <= 1) {
        continue;
      }

      foreach (BB p in cfg.GetPredecessors(j)) {
        // walk up the dom tree from p until we find a node that dominates j
        BB? runner = p;

        // NOTE: original algorithm does not enforce runner != null
        while (runner is not null && runner != domTree.IDom(j)) {
          // add j to runner's DF (which I think may not exist yet)
          HashSet<BB> runnerDf;
          if (!df.TryGetValue(runner, out runnerDf)) {
            runnerDf = new();
            df.Add(runner, runnerDf);
          }
          runnerDf.Add(j);

          // continue moving up dom tree
          runner = domTree.IDom(runner);
        }
      }
    }

    // build output
    CFGFacts<BB> facts = new(cfg);
    facts.AddFactDict("df", df);
    return facts;
  }
}
