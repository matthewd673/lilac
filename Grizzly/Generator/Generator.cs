using System.Text;
using Lilac.IL;
using IL = Lilac.IL;

namespace Grizzly.Generator;

public class Generator {
  public int MinFunctions { get; set; } = 1;
  public int MaxFunctions { get; set; } = 1;

  public int MinGlobals { get; set; } = 0;
  public int MaxGlobals { get; set; } = 4;

  public int MinStmtListLength { get; set; } = 1;
  public int MaxStmtListLength { get; set; } = 10;

  public HashSet<IL.Type> TypeSet { get; set; } = [IL.Type.I32];

  private Random random;

  public Generator() {
    random = new();
  }

  public IL.Program GenerateProgram() {
    IL.Program program = new();

    HashSet<string> globalSet = [];
    HashSet<string> funcSet = [];

    for (int i = 0; i < random.Next(MinGlobals, MaxGlobals); i++) {
      GlobalDef g = GenerateGlobalDef();
      globalSet.Add(g.Id.Name);
      program.AddGlobal(g);
    }

    for (int i = 0; i < random.Next(MinFunctions, MaxFunctions); i++) {
      FuncDef f = GenerateFuncDef();
      funcSet.Add(f.Name);
      program.AddFunc(f);
    }

    foreach (FuncDef f in program.GetFuncs()) {
      f.StmtList.AddRange(GenerateStmtList(funcSet));
    }

    return program;
  }

  private GlobalDef GenerateGlobalDef() {
    IL.Type gType = RandomType();
    return new(gType,
               new GlobalID(RandomIDName()),
               RandomConstant(gType));
  }

  private FuncDef GenerateFuncDef() {
    return new(RandomIDName(),
               [], // TODO: generate param list
               IL.Type.Void, // TODO: other return types
               []);
  }

  private List<Statement> GenerateStmtList(HashSet<string> funcSet) {
    List<Statement> stmtList = [];

    int numStmts = random.Next(MinStmtListLength, MaxStmtListLength);
    for (int i = 0; i < MaxStmtListLength; i++) {
      int stmtType = random.Next(3);

      switch (stmtType) {
        case 0:
          stmtList.Add(GenerateDefinition());
          break;
        case 1:
          stmtList.Add(GenerateLabel());
          break;
        case 2:
          stmtList.Add(GenerateVoidCall(funcSet));
          break;
      }
    }

    return stmtList;
  }

  private Definition GenerateDefinition() {
    IL.Type defType = RandomType();
    return new(defType,
               new ID(RandomIDName()),
               GenerateExpression(defType));
  }

  private Label GenerateLabel() {
    return new(RandomIDName());
  }

  private VoidCall GenerateVoidCall(HashSet<string> funcSet) {
    return new VoidCall(new(RandomFromSet(funcSet), []));
  }

  private Expression GenerateExpression(IL.Type type) {
    // TODO
    return new ValueExpr(RandomConstant(type));
  }

  private IL.Type RandomType() {
    return RandomFromSet(TypeSet);
  }

  private string RandomIDName() {
    string num = random.Next(999_999_999).ToString();
    byte[] enc = Encoding.UTF8.GetBytes(num);
    return Convert.ToBase64String(enc);
  }

  private Constant RandomConstant(IL.Type type) {
    object value = 0;

    // TODO: these values may be outside the range accepted by the type
    if (type.IsFloat()) {
      value = (random.NextDouble() * 999 * 2) - 999;
    }
    else if (type.IsSigned()) {
      value = random.Next(-999, 999);
    }
    else if (type.IsUnsigned()) {
      value = random.Next(999);
    }

    return new(type, value);
  }

  private T RandomFromSet<T>(HashSet<T> set) {
    int choice = random.Next(set.Count);
    int i = 0;
    foreach (T e in set) {
      if (i == choice) {
        return e;
      }

      i += 1;
    }

    return set.First(); // this will never hit
  }
}