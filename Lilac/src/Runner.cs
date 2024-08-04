using Lilac.IL;

namespace Lilac;

class Runner<T> {
  public Program Program { get; }

  public Runner(Program program) {
    Program = program;
  }

  public void RunPass(T pass) {
    throw new NotImplementedException();
  }
}
