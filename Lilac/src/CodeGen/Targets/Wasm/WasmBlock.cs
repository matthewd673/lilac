using Lilac.Analysis;

namespace Lilac.CodeGen.Targets.Wasm;

public class WasmBlock {
  public BB BB { get; }
  public WasmBlock? NextBlock { get; }

  public WasmBlock(BB bb, WasmBlock? nextBlock = null) {
    BB = bb;
    NextBlock = nextBlock;
  }
}

public class WasmIfBlock : WasmBlock {
  public WasmBlock? TrueBranch { get; }
  public WasmBlock? FalseBranch { get; }

  public WasmIfBlock(BB bb,
                     WasmBlock? trueBranch = null,
                     WasmBlock? falseBranch = null)
    : base(bb) {
    TrueBranch = trueBranch;
    FalseBranch = falseBranch;
  }
}

public class WasmLoopBlock : WasmBlock {
  public WasmBlock? Inner { get; }

  public WasmLoopBlock(BB bb, WasmBlock? inner = null)
    : base(bb) {
    Inner = inner;
  }
}