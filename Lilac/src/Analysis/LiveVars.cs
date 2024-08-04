namespace Lilac.Analysis;

class LiveVars : DFA<IL.ID> {
  public LiveVars(CFG cfg) : base(Direction.Backwards, new(), new(), cfg) {
    // Empty
  }

  protected override void InitSets(BB block) {
    // initialize GEN and KILL sets
    // adapted from Figure 8.14 in Cooper & Torczon 2nd edition
    Gen.Add(block, new()); // "UEVar"
    Kill.Add(block, new()); // "VarKill"

    // we want to examine not only the block stmt list but also its exit
    List<IL.Statement> examinedStmts = new(block.StmtList);
    if (block.Exit is not null) {
      examinedStmts.Add(block.Exit);
    }

    foreach (IL.Statement s in examinedStmts) {
      // only definitions are relevant
      if (s is not IL.Definition) {
        continue;
      }

      // add all ids on the rhs to GEN unless they're already in KILL
      HashSet<IL.ID> rhsVars = FindRhsIds(s);
      foreach (IL.ID v in rhsVars) {
        // these indexes will never be null
        if (!Kill[block].Contains(v)) {
          Gen[block].Add(v);
        }
      }

      // add the id being defined into KILL
      Kill[block].Add(((IL.Definition)s).Id);
    }
  }

  protected override HashSet<IL.ID> Transfer(BB block) {
    // union of GEN[B] and (OUT[b] - KILL[b])
    return GetSet(Gen, block)
      .Union(GetSet(Out, block).Except(GetSet(Kill, block)))
      .ToHashSet();
  }

  protected override HashSet<IL.ID> Meet(BB block) {
    // union of IN[S] for all successors S of B
    HashSet<IL.ID> u = new();

    foreach (BB s in CFG.GetSuccessors(block)) {
      u.UnionWith(GetSet(In, s));
    }

    return u;
  }

  private HashSet<IL.ID> FindRhsIds(IL.Statement node) {
    switch (node) {
      case IL.Definition:
        return FindRhsIds(((IL.Definition)node).Rhs);
      case IL.JumpZero:
        return FindRhsIds(((IL.JumpZero)node).Cond);
      case IL.JumpNotZero:
        return FindRhsIds(((IL.JumpNotZero)node).Cond);
      case IL.VoidCall:
        return FindRhsIds(((IL.VoidCall)node).Call);
      default:
        throw new Exception(); // TODO: nice exception type
    }
  }

  private HashSet<IL.ID> FindRhsIds(IL.Expression node) {
    switch (node) {
      case IL.BinaryOp:
        return FindRhsIds(((IL.BinaryOp)node).Left)
          .Union(FindRhsIds(((IL.BinaryOp)node).Right)).ToHashSet();
      case IL.UnaryOp:
        return FindRhsIds(((IL.UnaryOp)node).Value);
      case IL.Conversion:
        return FindRhsIds(((IL.Conversion)node).Value);
      case IL.Call:
        {
          HashSet<IL.ID> ids = new();
          foreach (IL.Value a in ((IL.Call)node).Args) {
            ids.UnionWith(FindRhsIds(a));
          }
          return ids;
        }
      case IL.Phi:
        {
          HashSet<IL.ID> ids = new();
          foreach (IL.ID i in ((IL.Phi)node).Ids) {
            ids.UnionWith(FindRhsIds(i));
          }
          return ids;
        }
      default:
        throw new Exception(); // TODO: nice exception type
    }
  }

  private HashSet<IL.ID> FindRhsIds(IL.Value node) {
    switch (node) {
      case IL.ID:
        return new() { (IL.ID)node };
      case IL.Constant:
        return new();
      default:
        throw new Exception(); // TODO: nice exception type
    }
  }
}
