using System.Diagnostics;
using IL = Lilac.IL;
using Lilac.Analysis;

namespace Grizzly;

public static class Tester {
  public static List<TestRecord> TestProgram(IL.Program program) {
    List<TestRecord> records = [];

    records.Add(TestConvertToCFGProgram(program));
    records.Add(TestGenerateTextFormat(program));

    return records;
  }

  private static TestRecord TestConvertToCFGProgram(IL.Program program) {
    Stopwatch stopwatch = new();
    stopwatch.Start();

    Exception? exception = null;
    try {
      CFGProgram cfgProgram = CFGProgram.FromProgram(program);
    }
    catch (Exception e) {
      exception = e;
    }

    stopwatch.Stop();

    return new(program, stopwatch.ElapsedTicks, exception);
  }

  private static TestRecord TestGenerateTextFormat(IL.Program program) {
    Stopwatch stopwatch = new();
    stopwatch.Start();

    Exception? exception = null;
    try {
      Lilac.Frontend.Generator generator = new(program);
      generator.Generate();
    }
    catch (Exception e) {
      exception = e;
    }

    stopwatch.Stop();

    return new(program, stopwatch.ElapsedTicks, exception);
  }
}