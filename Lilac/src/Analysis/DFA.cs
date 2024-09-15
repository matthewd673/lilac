namespace Lilac.Analysis;

abstract class DFA<T>(DFA<T>.Direction direction,
                      HashSet<T> boundary,
                      HashSet<T> @init,
                      CFG cfg) {
  public enum Direction {
    Forwards,
    Backwards,
  }

  private readonly Direction direction = direction;
  private readonly HashSet<T> boundary = boundary;
  private readonly HashSet<T> @init = @init;
  protected CFG CFG { get; } = cfg;

  protected Dictionary<BB, HashSet<T>> Out = [];
  protected Dictionary<BB, HashSet<T>> In = [];
  protected Dictionary<BB, HashSet<T>> Gen = [];
  protected Dictionary<BB, HashSet<T>> Kill = [];

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

  protected static HashSet<T> GetSet(Dictionary<BB, HashSet<T>> dict, BB block) =>
    dict.TryGetValue(block, out HashSet<T>? blockSet)
      ? blockSet
      : [];

  private void RunForwards() {
    // initialize all nodes
    Out.Add(CFG.Entry, boundary);
    foreach (BB n in CFG.GetNodes().Where(n => n != CFG.Entry)) {
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

        if (!Out.TryGetValue(n, out HashSet<T>? oldOut)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepForwards(n);

        if (!Out.TryGetValue(n, out HashSet<T>? newOut)) {
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
    foreach (BB n in CFG.GetNodes().Where(n => n != CFG.Exit)) {
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

        if (!In.TryGetValue(n, out HashSet<T>? oldIn)) {
          throw new Exception(); // TODO: nicer exception type
        }

        StepBackwards(n);

        if (!In.TryGetValue(n, out HashSet<T>? newIn)) {
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
