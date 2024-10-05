using Lilac.IL;

namespace Lilac.Analysis;

class LiveVars(CFG cfg) : DFA<ID>(Direction.Backwards, [], [], cfg) {
  protected override void InitSets(BB block) {
    // initialize GEN and KILL sets
    // adapted from Figure 8.14 in Cooper & Torczon 2nd edition
    Gen.Add(block, []); // "UEVar"
    Kill.Add(block, []); // "VarKill"

    // we want to examine not only the block stmt list but also its exit
    List<Statement> examinedStmts = new(block.StmtList);
    if (block.Exit is not null) {
      examinedStmts.Add(block.Exit);
    }

    // Check only definitions
    foreach (Definition d in examinedStmts.Where(s => s is Definition).Cast<Definition>()) {
      // add all ids on the rhs to GEN unless they're already in KILL
      HashSet<ID> rhsVars = FindStmtIds(d);
      foreach (ID v in rhsVars) {
        // these indexes will never be null
        if (!Kill[block].Contains(v)) {
          Gen[block].Add(v);
        }
      }

      // add the id being defined into KILL
      Kill[block].Add(d.Id);
    }
  }

  protected override HashSet<ID> Transfer(BB block) =>
    // Union of GEN[B] and (OUT[b] - KILL[b])
    GetSet(Gen, block)
      .Union(GetSet(Out, block).Except(GetSet(Kill, block)))
      .ToHashSet();

  protected override HashSet<ID> Meet(BB block) =>
    // Union of IN[S] for all successors S of B
    CFG.GetSuccessors(block).SelectMany(s => GetSet(In, s)).ToHashSet();

  private static HashSet<ID> FindStmtIds(Statement stmt) => stmt switch {
    Definition definition => FindExprIds(definition.Rhs),
    CondJump condJump => FindValueIds(condJump.Cond),
    VoidCall voidCall => FindExprIds(voidCall.Call),
    _ => throw new ArgumentOutOfRangeException($"Statement \"{stmt}\" not supported by FindStmtIds"),
  };

  private static HashSet<ID> FindExprIds(Expression expr) => expr switch {
    BinaryOp binaryOp => FindValueIds(binaryOp.Left)
                          .Union(FindValueIds(binaryOp.Right)).ToHashSet(),
    UnaryOp unaryOp => FindValueIds(unaryOp.Value),
    IL.Conversion conversion => FindValueIds(conversion.Value),
    Call call => call.Args.SelectMany(FindValueIds).ToHashSet(),
    Phi phi => phi.Ids.SelectMany(FindValueIds).ToHashSet(),
    _ => throw new ArgumentOutOfRangeException($"Expression \"{expr}\" not supported by FindExprIds"),
  };

  private static HashSet<ID> FindValueIds(Value value) => value switch {
    ID id => [id],
    Constant => [],
    _ => throw new ArgumentOutOfRangeException($"Value \"{value}\" not supported by FindValueIds"),
  };
}
