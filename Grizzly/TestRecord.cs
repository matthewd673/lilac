namespace Grizzly;

public class TestRecord(
  Lilac.IL.Program program,
  long ticks,
  Exception? exception = null) {

  public Lilac.IL.Program Program { get; } = program;
  public long Ticks { get; } = ticks;
  public Exception? Exception { get; } = exception;
}