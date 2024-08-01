using Lilac.Analysis;

namespace Lilac.CodeGen.Targets.Wasm;

public class Relooper {
  private CFG cfg;
  private DomTree domTree;
  private Dictionary<BB, int> cfgRpo;
  private Dictionary<BB, BlockProperty> props;

  public Relooper(CFG cfg) {
    this.cfg = cfg;

    // these will be filled in later
    domTree = new DomTree(new CFGFacts<BB>(new CFG()));
    cfgRpo = new();
    props = new();
  }

  public WasmBlock Translate() {
    // convert to reducible if necessary
    bool isReducible = new Reducible(cfg).Run();

    if (!isReducible) {
      // TODO: implement ToReducible transformation
      throw new Exception("TODO: implement ToReducible transformation");
    }

    // compute dom tree
    Dominators dominators = new(cfg);
    domTree = new(dominators.Run());

    // compute RPO
    cfgRpo = cfg.ComputeReversePostorderNumbering(cfg.Entry);

    // classify each node in the CFG
    ClassifyNodes();

    // translate everything starting at ENTRY
    return DoTree(cfg.Entry);
  }

  private void ClassifyNodes() {
    foreach (BB n in cfg.GetNodes()) {
      // "a node that has two or more forward inedges is a merge node"
      // (join)
      int forwardInedges = 0;
      foreach (CFG.Edge e in cfg.GetIncoming(n)) {
        if (IsForwardEdge(e)) {
          forwardInedges += 1;
        }
      }

      if (forwardInedges >= 2) { // is a join node
        props.Add(n, BlockProperty.Join);
        continue;
      }

      // "a node that ends in a conditional branch has two outedges and is
      // translated into an if form"
      if (cfg.GetOutgoingCount(n) >= 2) { // TODO: >= or strictly equal?
        props.Add(n, BlockProperty.If);
        continue;
      }

      // "a node that has a back inedge is a loop header, and its translation
      // is wrapped in a loop form"
      bool hasBackInedge = false;
      foreach (CFG.Edge e in cfg.GetIncoming(n)) {
        if (IsBackEdge(e)) {
          hasBackInedge = true;
          break;
        }
      }

      if (hasBackInedge) {
        props.Add(n, BlockProperty.Loop);
        continue;
      }

      props.Add(n, BlockProperty.None);
    }
  }

  private bool IsForwardEdge(CFG.Edge edge) {
    return cfgRpo[edge.From] < cfgRpo[edge.To];

  }

  private bool IsBackEdge(CFG.Edge edge) {
    // self loops are back edges
    return cfgRpo[edge.From] >= cfgRpo[edge.To];
  }

  private WasmBlock DoTree(BB node) {
    // children are sorted by rpo numbering
    List<BB> children = [];
    foreach (BB s in domTree.GetSuccessors(node)) {
      children.Add(s);
    }

    children.Sort((a, b) => cfgRpo[a].CompareTo(cfgRpo[b]));

    // create a new wasm block for this node
    WasmBlock wasmBlock = props[node] switch {
      BlockProperty.Loop => new WasmLoopBlock(node),
      BlockProperty.If => new WasmIfBlock(node),
      _ => new WasmBlock(node),
    };

    WasmBlock lastBlock = wasmBlock; // used to chain children in nextBlock

    foreach (BB c in children) {
      WasmBlock translation = DoTree(c);

      // place child in a conditional wasm block
      // join
      // TODO: what if a node dominates multiple join nodes? see pg. 6 (90:6)
      if (wasmBlock is WasmIfBlock && props[c] == BlockProperty.Join) {
        lastBlock.NextBlock = translation;
        lastBlock = translation;
      }
      // true
      else if (wasmBlock is WasmIfBlock tIfBlock && c.TrueBranch) {
        tIfBlock.TrueBranch = translation;
      }
      // false
      else if (wasmBlock is WasmIfBlock fIfBlock) {
        fIfBlock.FalseBranch = translation;
      }
      // place child in a loop header wasm block
      else if (wasmBlock is WasmLoopBlock loopBlock) {
        // NOTE: this is not derived from the original paper and may produce
        // incorrect behavior

        // if child dominates a node that has a backedge to node
        // then place child in WasmLoopBlock.Inner
        // otherwise, the child is the nextBlock of the loop
        bool isInner = false;
        foreach (BB d in domTree.GetDomBy(c)) {
          foreach (CFG.Edge o in cfg.GetOutgoing(d)) {
            if (o.To == node && IsBackEdge(o)) {
              isInner = true;
              break;
            }
          }

          if (isInner) {
            break;
          }
        }

        if (isInner) {
          loopBlock.Inner = translation;
        }
        else {
          loopBlock.NextBlock = translation;
          lastBlock = translation;
        }
      }
      // place child normally
      else {
        lastBlock.NextBlock = translation;
        lastBlock = translation;
      }
    }

    return wasmBlock;
  }
}