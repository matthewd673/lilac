namespace Lilac.Analysis;

abstract class DFA<T> {
  public enum Direction {
    Forwards,
    Backwards,
  }

  private Direction direction;
  private HashSet<T> boundary;
  private HashSet<T> @init;
  private CFG cfg;

  private Dictionary<BB, HashSet<T>> @out;
  private Dictionary<BB, HashSet<T>> @in;
  private Dictionary<BB, HashSet<T>> gen;
  private Dictionary<BB, HashSet<T>> kill;

  public DFA(Direction direction,
             HashSet<T> boundary,
             HashSet<T> @init,
             CFG cfg) {
    this.direction = direction;
    this.boundary = boundary;
    this.@init = @init;
    this.cfg = cfg;

    @out = new();
    @in = new();
    gen = new();
    kill = new();
  }

  public CFGFacts<T> Run() {
    // run the DFA
    switch (direction) {
      case Direction.Forwards:
        RunForwards();
        break;
      case Direction.Backwards:
        RunBackwards();
        break;
    }

    // construct and return the CFGFacts from the run
    CFGFacts<T> facts = new(cfg);
    facts.AddFactDict("out", @out);
    facts.AddFactDict("in", @in);
    facts.AddFactDict("gen", gen);
    facts.AddFactDict("kill", kill);

    return facts;
  }

  protected abstract HashSet<T> Transfer(BB block);

  protected abstract HashSet<T> Meet(BB block);

  private HashSet<T> GetSet(Dictionary<BB, HashSet<T>> dict, BB block) {
    HashSet<T>? blockSet;
    if (!dict.TryGetValue(block, out blockSet)) {
      return new();
    }

    return blockSet;
  }

  private void RunForwards() {
    // initialize all nodes
    @out.Add(cfg.Entry, boundary);
    foreach (BB n in cfg.GetNodes()) {
      if (n == cfg.Entry) {
        continue;
      }

      @out.Add(n, @init);
    }

    // iterate
    bool changed = true;
    while (changed) {
      changed = false;

      foreach (BB n in cfg.GetNodes()) {
        if (n == cfg.Entry) {
          continue;
        }

        HashSet<T>? oldOut;
        if (!@out.TryGetValue(n, out oldOut)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepForwards(n);

        HashSet<T>? newOut;
        if (!@out.TryGetValue(n, out newOut)) {
          throw new Exception(); // TODO: nicer exception type
        }

        if (newOut.Count != oldOut.Count) {
          changed = true;
        }
      }
    }
  }

  private void StepForwards(BB block) {
    @in.Add(block, Meet(block));
    @out.Add(block, Transfer(block));
  }

  private void RunBackwards() {
    // initialize all nodes
    @in.Add(cfg.Exit, boundary);
    foreach (BB n in cfg.GetNodes()) {
      if (n == cfg.Exit) {
        continue;
      }

      @in.Add(n, @init);
    }

    // iterate
    bool changed = true;
    while (changed) {
      changed = false;

      foreach (BB n in cfg.GetNodes()) {
        if (n == cfg.Exit) {
          continue;
        }

        HashSet<T>? oldIn;
        if (!@in.TryGetValue(n, out oldIn)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepBackwards(n);

        HashSet<T>? newIn;
        if (!@in.TryGetValue(n, out newIn)) {
          throw new Exception(); // TODO: nicer exception type
        }

        if (newIn.Count != oldIn.Count) {
          changed = true;
        }
      }
    }
  }

  private void StepBackwards(BB block) {
    @out.Add(block, Meet(block));
    @in.Add(block, Transfer(block));
  }
}
