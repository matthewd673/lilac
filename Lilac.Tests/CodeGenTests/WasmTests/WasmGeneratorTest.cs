using System.Diagnostics;
using Lilac.Analysis;
using Lilac.CodeGen.Targets.Wasm;
using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.Frontend;
using Lilac.IL;

namespace Lilac.Tests.CodeGenTests.WasmTests;

public class WasmGeneratorTest {
  private const string OutputFileName = "output.tmp.wasm";

  [Fact]
  public void AllTestProgramsGenerateValidWasm() {
    foreach (string filename in Directory.GetFiles("Resources/Wasm")) {
      Program program = Parser.ParseFile(filename);
      CFGProgram cfgProgram = CFGProgram.FromProgram(program);

      WasmTranslator translator = new(cfgProgram);
      Module wasmModule = translator.Translate();

      WasmGenerator generator = new(wasmModule);
      string wasm = generator.Generate();

      File.WriteAllText(OutputFileName, wasm);

      Process process = Process.Start("wasm-validate", [OutputFileName]);
      process.WaitForExit();
      Assert.Equal(0, process.ExitCode);
    }
  }
}
