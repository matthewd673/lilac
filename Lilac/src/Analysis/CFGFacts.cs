namespace Lilac.Analysis;

class CFGFacts<T>(CFG cfg)
{
  public CFG CFG { get; } = cfg;

  private readonly Dictionary<string, Dictionary<BB, HashSet<T>>> facts = [];

  public void AddFactDict(string key, Dictionary<BB, HashSet<T>> dict) {
    facts.Add(key, dict);
  }

  public HashSet<T> GetFact(string key, BB block) =>
    facts.TryGetValue(key, out Dictionary<BB, HashSet<T>>? factSet)
      ? (factSet.TryGetValue(block, out HashSet<T>? blockFacts)
          ? blockFacts
          : [])
      : [];
}
