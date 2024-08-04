using Lilac.Analysis;
using Lilac.IL;

namespace Lilac.Optimization;

public class LVN(BB block) : OptimizationPass {
  public override string Id => "lvn";

  private BB block = block;
  private ValueNumberMap valueNumberMap = new();
  private IDNumberMap idNumberMap = new();

  public override void Run() {
    foreach (Statement s in block.StmtList) {
      // perform constant folding on conditional jump conditions
      // this is a bonus on top of LVN's core task
      if (s is CondJump condJump) {
        Value cond = (Value)ConstantFolding(condJump.Cond);
        // swap out cond only if the new result is a constant
        if (cond is Constant) {
          condJump.Cond = cond;
        }

        continue; // jobs done with the jumps
      }

      // only definitions are relevant
      if (s is not Definition def) {
        continue;
      }

      // try to precompute rhs (constant-folding)
      Node rhs = ConstantFolding(def.Rhs);

      // TODO: constant folding on IDs in call args
      if (rhs is Call) {
        continue;
      }

      // get or insert the value (existing shows if it existed before or not)
      int? number = valueNumberMap.GetNumberByValue(rhs);
      bool existing = true;
      if (number is null) {
        number = valueNumberMap.InsertValue(rhs);
        existing = false;
      }

      // associate number with the id being assigned to
      idNumberMap.AssignId(def.Id, (int)number);

      // constants on the rhs are always better off staying as constants
      if (rhs is Constant constant) {
        def.Rhs = new ValueExpr(constant);
        continue;
      }

      // brand-new values will not be replaced with a number
      // however, ConstantFolding may have still yielded useful results so
      // we'll replace rhs
      if (!existing) {
        def.Rhs = rhs switch {
          Constant @const => new ValueExpr(@const),
          Expression expr => expr,
          _ => throw new ArgumentOutOfRangeException(),
        };
        continue;
      }

      // if the value exists in another id, set rhs to that id
      ID? existingId = idNumberMap.GetIdByNumber((int)number);
      if (existingId is not null) {
        def.Rhs = new ValueExpr(existingId);
        continue;
      }

      Node? existingHash = valueNumberMap.GetValueByNumber((int)number);
      if (existingHash is null) {
        continue;
      }

      def.Rhs = existingHash switch {
        Value value => new ValueExpr(value),
        Expression expr => expr,
        _ => throw new ArgumentOutOfRangeException(),
      };
    }
  }

  private Node ConstantFolding(Node rhs) {
    switch (rhs) {
      case Constant: // nothing to do
        break;
      case ID id: {
        // check if the id has a value number
        int? idNumber = idNumberMap.GetNumberById(id);
        if (idNumber is null) {
          return rhs;
        }

        // id has a value number so get its value, recurse, and return that
        Node val = valueNumberMap.GetValueByNumber((int)idNumber) ??
                   throw new NullReferenceException();
        return ConstantFolding(val);
      }
      case BinaryOp binaryOp: {
        // recurse on left and right (in case they are ids mapped to constants)
        Value left = (Value)ConstantFolding(binaryOp.Left);
        Value right = (Value)ConstantFolding(binaryOp.Right);

        // calculate if both sides are constants
        if (left is Constant lConst && right is Constant rConst) {
          Constant constantResult =
            InternalMath.Calculate(binaryOp.Op, lConst, rConst);
          return constantResult;
        }

        // otherwise, return a binop with left and right folded
        return new BinaryOp(binaryOp.Op, left, right);
      }
      case UnaryOp unaryOp: {
        // recurse on value (in case they are ids mapped to constants)
        Value value = (Value)ConstantFolding(unaryOp.Value);

        // calculate if it is a constant
        if (value is Constant constant) {
          Constant constantResult =
            InternalMath.Calculate(unaryOp.Op, constant);
          return constantResult;
        }

        // otherwise, just return unop with value folded
        return new UnaryOp(unaryOp.Op, value);
      }
      case Call call: {
        throw new NotImplementedException(); // TODO
      }
      default:
        throw new ArgumentOutOfRangeException();
    }

    throw new ArgumentOutOfRangeException();
  }
}

internal class ValueNumberMap {
  private List<Node> indexToValue = new();
  private Dictionary<Node, int> valueToIndex = new();

  public int InsertValue(Node value) {
    indexToValue.Add(value);
    int number = indexToValue.Count - 1;
    valueToIndex[value] = number;

    return number;
  }

  public Node? GetValueByNumber(int number) {
    try {
      return indexToValue[number];
    }
    catch {
      return null;
    }
  }

  public int? GetNumberByValue(Node value) {
    try {
      return valueToIndex[value];
    }
    catch {
      return null;
    }
  }
}

internal class IDNumberMap {
  private Dictionary<ID, int> idToNumber = new();
  private Dictionary<int, List<ID>> numberToIds = new();

  public void AssignId(ID id, int number) {
    try {
      int oldNumber = idToNumber[id];
      List<ID> oldIdList = numberToIds[oldNumber];
      oldIdList.Remove(id);
    }
    catch {
      // Ignored
    }

    idToNumber[id] = number;

    if (numberToIds.TryGetValue(number, out List<ID> idList)) {
      idList.Add(id);
    }
    else {
      numberToIds.Add(number, [id]);
    }
  }

  public int? GetNumberById(ID id) {
    try {
      return idToNumber[id];
    }
    catch {
      return null;
    }
  }

  public ID? GetIdByNumber(int number) {
    try {
      List<ID> idList = numberToIds[number];
      return idList[0]; // should never be empty
    }
    catch {
      return null;
    }
  }
}

internal class ValueNumber(int number) : Value {
  public int Number { get; } = number;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ValueNumber)) {
      return false;
    }

    ValueNumber other = (ValueNumber)obj;
    return Number.Equals(other.Number);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Number);
  }

  public override ValueNumber Clone() => new(Number);
}