using Lilac.IL;

namespace Lilac.Analysis;

/// <summary>
/// A BB is a basic block.
/// </summary>
public class BB {
  /// <summary>
  /// The ID of the BB. Must be unique within any collection of BBs.
  /// </summary>
  public string Id { get; }
  /// <summary>
  /// The Label that marks the entry of the BB. A BB may have no explicit
  /// entry e.g. if it immediately follows a BB with a Jump exit.
  /// </summary>
  public Label? Entry { get; }
  /// <summary>
  /// The Jump that marks the exit of the BB. A BB may have no explicit exit
  /// e.g. if it immediately preceeds a BB with a Label entry.
  /// </summary>
  public Jump? Exit { get; }
  /// <summary>
  /// The list of IL Statements in the BB. Must not contain Labels or Jumps.
  /// </summary>
  public List<Statement> StmtList { get; }
  /// <summary>
  /// Indicates if this BB is the "true" branch of a conditional jump. That is,
  /// if conditional jump in another BB has the entry Label of this BB as its
  /// target.
  /// </summary>
  public bool TrueBranch { get; internal set; }

  /// <summary>
  /// The number of IL Statements in the statement list.
  /// </summary>
  public int Count => StmtList.Count;

  /// <summary>
  /// Construct a new BB.
  /// </summary>
  /// <param name="id">The ID of the BB.</param>
  /// <param name="entry">The Label entry of the BB.</param>
  /// <param name="exit">The Jump exit of the BB.</param>
  /// <param name="stmtList">The list of IL Statements within the BB.</param>
  /// <param name="trueBranch">
  ///   Indicates if the BB is the "true" branch of a conditional jump.
  /// </param>
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

  /// <summary>
  /// Compute a list of BBs from a list of IL Statements. The input statement
  /// list may contain Labels and Jumps with will be used to split blocks.
  /// </summary>
  /// <param name="stmtList">The list of IL Statements.</param>
  /// <returns>
  ///   A list of valid BBs corresponding to the input statement list.
  /// </returns>
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
