using Lilac.CodeGen.Targets.Wasm.Instructions;

namespace Lilac.CodeGen.Targets.Wasm.Optimization;

public class Tee(Module module) : WasmOptimization {
	private Module module = module;

	public override string Id => "tee";

  public override void Run() {
		foreach (Component c in module.Components) {
			switch (c) {
				case Func func:
					TeeifyInstrList(func.Instructions);
					break;
			}
		}
  }

	private void TeeifyInstrList(List<WasmInstruction> instrList) {
		for (int i = 1; i < instrList.Count; i++) {
			if (instrList[i] is LocalGet get && instrList[i - 1] is LocalSet set &&
					get.Variable.Equals(set.Variable)
					) {
				instrList[i - 1] = new LocalTee(get.Variable);
				instrList.RemoveAt(i);
			}
		}
	}
}
