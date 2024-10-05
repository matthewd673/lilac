using Lilac.Analysis;
using System;

namespace Lilac.Transformations;

// TODO: This implementation is not complete.
class ToReducible(CFG cfg) : Pass<CFG> {
  public override string Id => "ToReducible";

  private readonly CFG cfg = cfg;
  private int labelCt = 0;

  public override void Run() {
    labelCt = 0;

    // TODO: this is very rudimentary node splitting, not CNS
    foreach (BB n in cfg.GetNodes()) {
      // split all nodes with more than 1 predecessor
      if (cfg.GetPredecessorsCount(n) > 1) {
        SplitNode(n);
      }
    }
  }

  private void SplitNode(BB node) {
    foreach (CFG.Edge i in cfg.GetIncoming(node)) {
      BB p = i.From;

      // rename the node's label (even if it didn't have one before)
      IL.Label newEntry = new(Guid.NewGuid().ToString());

      // create a copy of the node
      BB newNode = new(Guid.NewGuid().ToString(),
                       entry: newEntry,
                       exit: node.Exit,
                       stmtList: node.StmtList,
                       trueBranch: node.TrueBranch);
      cfg.AddNode(newNode);

      // add incoming edge to new node
      cfg.AddEdge(new(p, newNode));

      // also copy all outgoing edges
      foreach (CFG.Edge o in cfg.GetOutgoing(node)) {
        BB to = o.To;
        if (to == node) {
          to = newNode;
        }

        cfg.AddEdge(new(newNode, to));
      }

      // if predecessor jumps to this node, replace label name with new name
      if (p.Exit is not null) {
        p.Exit.Target = newEntry.Name;
      }
    }

    // remove original node
    cfg.RemoveNode(node);
  }
}
