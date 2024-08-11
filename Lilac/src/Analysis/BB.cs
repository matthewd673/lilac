using Lilac.IL;

namespace Lilac.Analysis;

public class BB {
  public string Id { get; }
  public Label? Entry { get; }
  public Jump? Exit { get; }
  public List<Statement> StmtList { get; }
  public bool TrueBranch { get; internal set; }

  public int Count => StmtList.Count;

  public bool Empty => StmtList.Count == 0;

  public BB(string id,
            Label? entry = null,
            Jump? exit = null,
            List<Statement>? stmtList = null,
            bool trueBranch = false) {
    Id = id;
    Entry = entry;
    Exit = exit;
    StmtList = stmtList ?? [];
    TrueBranch = trueBranch;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(BB)) {
      return false;
    }

    BB other = (BB)obj;

    return Id.Equals(other.Id);
  }

  public override int GetHashCode() {
    return Id.GetHashCode();
  }

  public BB Clone() {
    // clone all statements (don't forget entry and exit)
    List<Statement> newStmtList = [];
    foreach (Statement s in StmtList) {
      newStmtList.Add((Statement)s.Clone());
    }

    return new((string)Id.Clone(),
               Entry?.Clone(),
               Exit?.Clone(),
               newStmtList,
               TrueBranch);
  }

  public override string ToString() {
    string s = $"BB#{Id}";

    if (Entry is not null || Exit is not null) {
      s += " (";

      if (Entry is not null) {
        s += $"entry={Entry}, ";
      }

      if (Exit is not null) {
        s += $"exit={Exit}, ";
      }

      s = s.Remove(s.Length - 2);
      s += ")";
    }

    return s;
  }

  public static List<BB> FromStmtList(List<Statement> stmtList) {
    List<BB> blocks = new();
    List<Statement> blockStmts = new();
    Label? currentEntry = null;

    foreach (Statement s in stmtList) {
      // mark beginning of a new block
      if (s is Label) {
        // push previous block onto list (its exit will be null)
        if (!(blockStmts.Count == 0 && currentEntry is null)) {
          blocks.Add(new(Guid.NewGuid().ToString(),
                         entry: currentEntry,
                         stmtList: blockStmts));
          blockStmts = new();
        }

        currentEntry = (Label)s;
      }

      // don't push labels or jumps, they belong in entry/exit
      if (!(s is Label or Jump)) {
        blockStmts.Add(s);
      }

      // mark end of a block
      if (s is not Jump) {
        continue;
      }

      blocks.Add(new(Guid.NewGuid().ToString(),
                     entry: currentEntry,
                     exit: (Jump)s,
                     stmtList: blockStmts));
      blockStmts = new();
      currentEntry = null;
    }

    // scoop up stragglers
    if (blockStmts.Count > 0 || currentEntry is not null) {
      blocks.Add(new(Guid.NewGuid().ToString(),
                     entry: currentEntry,
                     stmtList: blockStmts));
    }

    return blocks;
  }

  public static List<Statement> ToStmtList(List<BB> bbList) {
    // TODO
    throw new NotImplementedException();
  }
}
