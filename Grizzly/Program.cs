namespace Grizzly;

class Program {
  static void Main(string[] args) {
    Console.WriteLine("grizzly");

    long totalTests = 0;
    long testFails = 0;

    long maxTicks = 0;
    long minTicks = long.MaxValue;

    Generator generator = new();
    for (int i = 0; i < 1_000_000; i++) {
      Lilac.IL.Program p = generator.GenerateProgram();

      foreach (TestRecord r in Tester.TestProgram(p)) {
        totalTests += 1;

        if (r.Exception is not null) {
          testFails += 1;
        }

        if (r.Ticks > maxTicks) {
          maxTicks = r.Ticks;
        }

        if (r.Ticks < minTicks) {
          minTicks = r.Ticks;
        }
      }
    }

    Console.WriteLine($"{totalTests} performed");
    Console.WriteLine($"{testFails} mauled");
    Console.WriteLine($"Duration (ticks): [{minTicks}, {maxTicks}]");
  }
}