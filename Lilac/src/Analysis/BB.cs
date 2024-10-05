using Lilac.IL;

namespace Lilac.Analysis;

/// <summary>
/// A BB is a basic block.
/// </summary>
/// <remarks>
/// Construct a new BB.
/// </remarks>
/// <param name="Id">The ID of the BB.</param>
/// <param name="Entry">The Label entry of the BB.</param>
/// <param name="Exit">The Jump exit of the BB.</param>
/// <param name="StmtList">The list of IL Statements within the BB.</param>
/// <param name="TrueBranch">
///   Indicates if the BB is the "true" branch of a conditional jump.
/// </param>
public record BB(string Id,
                 Label? Entry = null,
                 Jump? Exit = null,
                 List<Statement>? StmtList = null,
                 bool TrueBranch = false) {
  /// <summary>
  /// The ID of the BB. Must be unique within any collection of BBs.
  /// </summary>
  public string Id { get; } = Id;
  /// <summary>
  /// The Label that marks the entry of the BB. A BB may have no explicit
  /// entry e.g. if it immediately follows a BB with a Jump exit.
  /// </summary>
  public Label? Entry { get; } = Entry;
  /// <summary>
  /// The Jump that marks the exit of the BB. A BB may have no explicit exit
  /// e.g. if it immediately preceeds a BB with a Label entry.
  /// </summary>
  public Jump? Exit { get; } = Exit;
  /// <summary>
  /// The list of IL Statements in the BB. Must not contain Labels or Jumps.
  /// </summary>
  public List<Statement> StmtList { get; } = StmtList ?? [];
  /// <summary>
  /// Indicates if this BB is the "true" branch of a conditional jump. That is,
  /// if conditional jump in another BB has the entry Label of this BB as its
  /// target.
  /// </summary>
  public bool TrueBranch { get; internal set; } = TrueBranch;

  /// <summary>
  /// The number of IL Statements in the statement list.
  /// </summary>
  public int Count => StmtList.Count;

  public override int GetHashCode() => Id.GetHashCode();

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
    List<BB> blocks = [];
    List<Statement> blockStmts = [];
    Label? currentEntry = null;

    foreach (Statement s in stmtList) {
      // mark beginning of a new block
      if (s is Label label) {
        // push previous block onto list (its exit will be null)
        if (!(blockStmts.Count == 0 && currentEntry is null)) {
          blocks.Add(new(Guid.NewGuid().ToString(),
                         Entry: currentEntry,
                         StmtList: blockStmts));
          blockStmts = [];
        }

        currentEntry = label;
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
                     Entry: currentEntry,
                     Exit: (Jump)s,
                     StmtList: blockStmts));
      blockStmts = [];
      currentEntry = null;
    }

    // scoop up stragglers
    if (blockStmts.Count > 0 || currentEntry is not null) {
      blocks.Add(new(Guid.NewGuid().ToString(),
                     Entry: currentEntry,
                     StmtList: blockStmts));
    }

    return blocks;
  }

  public static List<Statement> ToStmtList(List<BB> bbList) {
    // TODO
    throw new NotImplementedException();
  }
}
