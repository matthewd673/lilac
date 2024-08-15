using System.Diagnostics;
using Lilac.Analysis;
using Lilac.CodeGen.Targets.Wasm;
using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Lilac.Frontend;

namespace Lilac.Tests.CodeGenTests.WasmTests;

public class WatGeneratorTest {
  private const string OutputFileName = "output.tmp.wat";

  [Fact]
  public void AllTestProgramsGenerateValidWat() {
    foreach (string filename in Directory.GetFiles("Resources/Wasm")) {
      Program program = Parser.ParseFile(filename);
      CFGProgram cfgProgram = CFGProgram.FromProgram(program);

      WasmTranslator translator = new(cfgProgram);
      Module wasmModule = translator.Translate();

      WatGenerator generator = new(wasmModule);
      string wat = generator.Generate();

      File.WriteAllText(OutputFileName, wat);

      Process process = Process.Start("wat2wasm", [OutputFileName]);
      process.WaitForExit();
      Assert.Equal(0, process.ExitCode);
    }
  }
}