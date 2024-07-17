namespace Lilac.Analysis;

class BB {
  public string Id { get; }
  public IL.Label? Entry { get; }
  public IL.Jump? Exit { get; }
  public List<IL.Statement> StmtList { get; }
  public bool TrueBranch { get; }

  public int Count {
    get { return StmtList.Count; }
  }

  public bool Empty {
    get { return StmtList.Count == 0; }
  }

  public BB(string id,
            IL.Label? entry,
            IL.Jump? exit,
            List<IL.Statement> stmtList = null,
            bool trueBranch = false) {
    Id = id;
    Entry = entry;
    Exit = exit;
    if (stmtList is not null) {
      StmtList = stmtList;
    }
    else {
      StmtList = new();
    }
    TrueBranch = trueBranch;
  }

  public override bool Equals(object? obj) {
    if (obj.GetType() != typeof(BB)) {
      return false;
    }

    BB other = (BB)obj;

    return Id.Equals(other.Id);
  }

  public override int GetHashCode() {
    return Id.GetHashCode();
  }

  public BB Clone() {
    // TODO
    throw new NotImplementedException();
  }

  public override string ToString() {
    string s = $"BB#{Id}";

    if (Entry is not null || Exit is not null) {
      s += " (";

      if (Entry is not null) {
        s += $"entry={Entry.ToString()}, ";
      }

      if (Exit is not null) {
        s += $"exit={Exit.ToString()}, ";
      }

      s = s.Remove(s.Length - 2);
      s += ")";
    }

    return s;
  }

  public static List<BB> FromStmtList(List<IL.Statement> stmtList) {
    // TODO
    throw new NotImplementedException();
  }

  public static List<IL.Statement> ToStmtList(List<BB> bbList) {
    // TODO
    throw new NotImplementedException();
  }
}
