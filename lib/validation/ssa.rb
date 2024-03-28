# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "validation_pass"
require_relative "../il"

include Validation

# The SSA validation ensures that the program is in valid SSA form.
class Validation::SSA < ValidationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = "ssa"
    @description = "Ensure the program is in valid SSA form"
  end

  sig { params(program: IL::Program).void }
  def run(program)
    symbols = SymbolTable.new
    symbols.push_scope # top level scope

    scan_items(program.item_list, symbols)
  end

  private

  sig { params(items: T::Array[IL::TopLevelItem], symbols: SymbolTable).void }
  def scan_items(items, symbols)
    items.each { |i|
      # recurse on function defs
      if i.is_a?(IL::FuncDef)
        # create a new scope (NOTE: assumes ssa doesn't hold between funcs)
        symbols.push_scope

        # scan and register params
        i.params.each { |p|
          if symbols.lookup(p.id.key)
            raise("Multiple definitions of ID '#{p.id.key}'")
          end
          symbols.insert(ILSymbol.new(p.id.key, p.type))
        }

        # recursive scan
        scan_items(i.stmt_list, symbols)
        symbols.pop_scope
      end

      # only definitions are relevant
      if not i.is_a?(IL::Definition)
        next
      end

      if symbols.lookup(i.id.key)
        raise("Multiple definitions of ID '#{i.id.key}'")
      end
      symbols.insert(ILSymbol.new(i.id.key, i.type))
    }
  end
end
