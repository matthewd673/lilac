namespace Lilac.Analysis;

abstract class DFA<T> {
  public enum Direction {
    Forwards,
    Backwards,
  }

  private Direction direction;
  private HashSet<T> boundary;
  private HashSet<T> @init;
  protected CFG CFG { get; }

  protected Dictionary<BB, HashSet<T>> Out;
  protected Dictionary<BB, HashSet<T>> In;
  protected Dictionary<BB, HashSet<T>> Gen;
  protected Dictionary<BB, HashSet<T>> Kill;

  public DFA(Direction direction,
             HashSet<T> boundary,
             HashSet<T> @init,
             CFG cfg) {
    this.direction = direction;
    this.boundary = boundary;
    this.@init = @init;
    CFG = cfg;

    Out = new();
    In = new();
    Gen = new();
    Kill = new();
  }

  public CFGFacts<T> Run() {
    // run custom fact set initialization for each block
    foreach (BB n in CFG.GetNodes()) {
      InitSets(n);
    }

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
    CFGFacts<T> facts = new(CFG);
    facts.AddFactDict("out", Out);
    facts.AddFactDict("in", In);
    facts.AddFactDict("gen", Gen);
    facts.AddFactDict("kill", Kill);

    return facts;
  }

  protected abstract HashSet<T> Transfer(BB block);

  protected abstract HashSet<T> Meet(BB block);

  protected abstract void InitSets(BB block);

  protected HashSet<T> GetSet(Dictionary<BB, HashSet<T>> dict, BB block) {
    HashSet<T>? blockSet;
    if (!dict.TryGetValue(block, out blockSet)) {
      return new();
    }

    return blockSet;
  }

  private void RunForwards() {
    // initialize all nodes
    Out.Add(CFG.Entry, boundary);
    foreach (BB n in CFG.GetNodes()) {
      if (n == CFG.Entry) {
        continue;
      }

      Out.Add(n, @init);
    }

    // iterate
    bool changed = true;
    while (changed) {
      changed = false;

      foreach (BB n in CFG.GetNodes()) {
        if (n == CFG.Entry) {
          continue;
        }

        HashSet<T>? oldOut;
        if (!Out.TryGetValue(n, out oldOut)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepForwards(n);

        HashSet<T>? newOut;
        if (!Out.TryGetValue(n, out newOut)) {
          throw new Exception(); // TODO: nicer exception type
        }

        if (newOut.Count != oldOut.Count) {
          changed = true;
        }
      }
    }
  }

  private void StepForwards(BB block) {
    In[block] = Meet(block);
    Out[block] = Transfer(block);
  }

  private void RunBackwards() {
    // initialize all nodes
    In.Add(CFG.Exit, boundary);
    foreach (BB n in CFG.GetNodes()) {
      if (n == CFG.Exit) {
        continue;
      }

      In.Add(n, @init);
    }

    // iterate
    bool changed = true;
    while (changed) {
      changed = false;

      foreach (BB n in CFG.GetNodes()) {
        if (n == CFG.Exit) {
          continue;
        }

        HashSet<T>? oldIn;
        if (!In.TryGetValue(n, out oldIn)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepBackwards(n);

        HashSet<T>? newIn;
        if (!In.TryGetValue(n, out newIn)) {
          throw new Exception(); // TODO: nicer exception type
        }

        if (newIn.Count != oldIn.Count) {
          changed = true;
        }
      }
    }
  }

  private void StepBackwards(BB block) {
    Out[block] = Meet(block);
    In[block] = Transfer(block);
  }
}
