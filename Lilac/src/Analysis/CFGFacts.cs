namespace Lilac.Analysis;

class CFGFacts<T> {
  public CFG CFG { get; }

  private Dictionary<string, Dictionary<BB, HashSet<T>>> facts;

  public CFGFacts(CFG cfg) {
    CFG = cfg;
    facts = new();
  }

  public void AddFactDict(string key, Dictionary<BB, HashSet<T>> dict) {
    facts.Add(key, dict);
  }

  public HashSet<T> GetFact(string key, BB block) {
    Dictionary<BB, HashSet<T>>? factSet;
    if (!facts.TryGetValue(key, out factSet)) {
      return new();
    }

    HashSet<T>? blockFacts;
    if (!factSet.TryGetValue(block, out blockFacts)) {
      return new();
    }

    return blockFacts;
  }
}
