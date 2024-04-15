# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"
require_relative "../symbol_table"

include Validation

# The type-check validation ensures that there are no definitions or
# expressions with mismatched types in the program.
class Validation::TypeCheck < ValidationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = "typecheck"
    @description = "Detect type mismatchs in definitions and expressions"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    symbols = SymbolTable.new
    funcs = {} # name -> return type

    # store function return types
    program.each_func { |f|
      funcs[f.name] = f.ret_type
    }

    # scan on all items
    symbols.push_scope
    scan_items(program.stmt_list, symbols, funcs)
    # ...and scan on all functions
    program.each_func { |f|
      scan_items(f.stmt_list, symbols, funcs)
    }
    symbols.pop_scope
  end

  private

  sig { params(items: T::Array[IL::Statement],
               symbols: SymbolTable,
               funcs: T::Hash[String, String]).void }
  def scan_items(items, symbols, funcs)
    items.each { |i|
      # only definitions are relevant
      if not i.is_a?(IL::Definition)
        next
      end

      # register id in symbol table for every def (since this is SSA)
      symbols.insert(ILSymbol.new(i.id, i.type))

      # find the type of the rhs
      if i.rhs.is_a?(IL::Constant)
        rhs_type = T.cast(i.rhs, IL::Constant).type
      elsif i.rhs.is_a?(IL::ID)
        rhs_symbol = symbols.lookup(T.cast(i.rhs, IL::ID).key)
        if not rhs_symbol
          raise("Symbol not found: #{T.cast(i.rhs, IL::ID).key}")
        end
        rhs_type = rhs_symbol.type
      elsif i.rhs.is_a?(IL::Call)
        rhs_type = funcs[T.cast(i.rhs, IL::Call).func_name]
      elsif i.rhs.is_a?(IL::Expression)
        rhs_type = get_expr_type(T.cast(i.rhs, IL::Expression), symbols)
      end

      # check for a mismatch
      if not rhs_type
        raise("Expression has nil type: '#{i.rhs}'")
      end

      id_symbol = symbols.lookup(i.id.key)
      if not id_symbol
        raise("Symbol not found: #{i.id.key}")
      end
      if id_symbol.type != rhs_type
        raise("Type mismatch in statement: '#{i}'")
      end
    }
  end

  sig { params(expr: IL::Expression,
               symbols: SymbolTable)
        .returns(T.nilable(IL::Type)) }
  def get_expr_type(expr, symbols)
    if expr.is_a?(IL::BinaryOp)
      # get type of left
      if expr.left.is_a?(IL::Constant)
        lconst = T.cast(expr.left, IL::Constant)
        ltype = lconst.type
      elsif expr.left.is_a?(IL::ID)
        lid = T.cast(expr.left, IL::ID)
        lsymbol = symbols.lookup(lid.key)
        if not lsymbol
          raise("Symbol not found: #{lid.key}")
        end
        ltype = lsymbol.type
      else
        raise("Unsupported left value class: #{expr.left.class}")
      end

      # get type of right
      if expr.right.is_a?(IL::Constant)
        rconst = T.cast(expr.right, IL::Constant)
        rtype = rconst.type
      elsif expr.right.is_a?(IL::ID)
        rid = T.cast(expr.right, IL::ID)
        rsymbol = symbols.lookup(rid.key)
        if not rsymbol
          raise("Symbol not found: #{rid.key}")
        end
        rtype = rsymbol.type
      else
        raise("Unsupported right value class: #{expr.right.class}")
      end

      # return if they match, otherwise nil
      if ltype == rtype then return ltype end
      return nil
    elsif expr.is_a?(IL::UnaryOp)
      # get type of value
      if expr.value.is_a?(IL::Constant)
        vconst = T.cast(expr.value, IL::Constant)
        vtype = vconst.type
      elsif expr.value.is_a?(IL::ID)
        vid = T.cast(expr.value, IL::ID)
        vsymbol = symbols.lookup(vid.key)
        if not vsymbol
          raise("Symbol not found: #{vid.key}")
        end
        vtype = vsymbol.type
      else
        raise("Unsupported value class: #{expr.value.class}")
      end

      return vtype # no need to check for mismatch
    end

    raise("Unsupported expression class: #{expr.class}")
  end
end
