using Lilac.Analysis;

namespace Lilac.CodeGen.Targets.Wasm;

public class WasmBlock {
  public BB BB { get; }
  public WasmBlock? NextBlock { get; set; }

  public WasmBlock(BB bb, WasmBlock? nextBlock = null) {
    BB = bb;
    NextBlock = nextBlock;
  }
}

public class WasmIfBlock : WasmBlock {
  public WasmBlock? TrueBranch { get; set; }
  public WasmBlock? FalseBranch { get; set; }

  public WasmIfBlock(BB bb,
                     WasmBlock? trueBranch = null,
                     WasmBlock? falseBranch = null)
    : base(bb) {
    TrueBranch = trueBranch;
    FalseBranch = falseBranch;
  }
}

public class WasmLoopBlock : WasmBlock {
  public WasmBlock? Inner { get; set; }

  public WasmLoopBlock(BB bb, WasmBlock? inner = null)
    : base(bb) {
    Inner = inner;
  }
}