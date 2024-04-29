# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"

include Validation

# The SSA validation ensures that the program is in valid SSA form.
class Validation::SSA < ValidationPass
  extend T::Sig

  sig { override.returns(String) }
  def id
    "ssa"
  end

  sig { override.returns(String) }
  def description
    "Ensure the program is in valid SSA form"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    symbols = SymbolTable.new
    symbols.push_scope # top level scope

    # scan top level of program
    scan_stmt_list(program.stmt_list, symbols)

    # scan all funcs
    program.each_func { |f|
      # create a new scope (NOTE: assumes ssa doesn't hold between funcs)
      symbols.push_scope

      # scan and register params
      f.params.each { |p|
        if symbols.lookup(p.id.key)
          raise("Multiple definitions of ID '#{p.id.key}'")
        end
        symbols.insert(ILSymbol.new(p.id, p.type))
      }

      # recursive scan
      scan_stmt_list(f.stmt_list, symbols)
      symbols.pop_scope
    }
  end

  private

  sig { params(stmt_list: T::Array[IL::Statement], symbols: SymbolTable).void }
  def scan_stmt_list(stmt_list, symbols)
    stmt_list.each { |s|
      # only definitions are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      if symbols.lookup(s.id.key)
        raise("Multiple definitions of ID '#{s.id.key}'")
      end
      symbols.insert(ILSymbol.new(s.id, s.type))
    }
  end
end
