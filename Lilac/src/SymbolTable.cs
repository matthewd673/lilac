using Lilac.IL;

namespace Lilac;

public class Symbol {
  public ID Id { get; }
  public IL.Type Type { get; }

  public Symbol(ID id, IL.Type type) {
    Id = id;
    Type = type;
  }
}

public class Scope {
  private Dictionary<ID, Symbol> symbols;

  public Symbol this[ID id] => symbols[id];

  public Scope() {
    symbols = new();
  }

  public void Add(Symbol symbol) {
    symbols.Add(symbol.Id, symbol);
  }

  public IEnumerable<Symbol> GetSymbols() {
    foreach (Symbol s in symbols.Values) {
      yield return s;
    }
  }
}

public class SymbolTable {
  private Stack<Scope> scopes;

  public Symbol? this[ID id] {
    get {
      foreach (Scope s in scopes) {
        try {
          return s[id];
        }
        catch {
          // Ignored
        }
      }

      return null;
    }
  }

  public SymbolTable() {
    scopes = new();
  }

  public void PushScope() {
    scopes.Push(new Scope());
  }

  public void PopScope() {
    scopes.Pop();
  }

  public void Add(Symbol symbol) {
    scopes.Peek().Add(symbol);
  }

  public Scope GetTopScope() {
    return scopes.Peek();
  }
}
