# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "il"

module Lilac
  # An ILSymbol stores information about a symbol in an IL program.
  class ILSymbol
    extend T::Sig

    sig { returns(IL::ID) }
    # The ID that this symbol corresponds to.
    attr_reader :id

    sig { returns(IL::Type) }
    # The type of the symbol.
    attr_reader :type

    sig { params(id: IL::ID, type: IL::Type).void }
    # Construct a new ILSymbol.
    #
    # @param [IL::ID] id The ID that this symbol corresponds to.
    # @param [IL::Type] type The type of the symbol.
    def initialize(id, type)
      @id = id
      @type = type
    end
  end

  # A Scope is a set of symbols that are present within a local scope (such as
  # a +IL::FuncDef+) in a program.
  class Scope
    extend T::Sig

    sig { void }
    # Construct a new Scope.
    def initialize
      @symbols = T.let({}, T::Hash[String, ILSymbol])
    end

    sig { params(symbol: ILSymbol).void }
    # Insert a symbol into this scope. A single scope cannot have any duplicate
    # keys.
    #
    # @param [ILSymbol] symbol The symbol to insert.
    def insert(symbol)
      @symbols[symbol.id.key] = symbol
    end

    sig { params(key: String).returns(T.nilable(ILSymbol)) }
    # Find the symbol with a given key in this scope.
    #
    # @param [String] key The key of the symbol to search for.
    # @return [T.nilable(ILSymbol)] The symbol with the given key. If the symbol
    #   does not exist in this scope it will return +nil+.
    def lookup(key)
      @symbols[key]
    end

    sig { params(block: T.proc.params(arg0: ILSymbol).void).void }
    # Iterate over all the symbols in this scope.
    def each_symbol(&block)
      @symbols.each_value(&block)
    end
  end

  # A SymbolTable contains a stack of scopes and helper functions to manage
  # the stack and the symbols within it.
  class SymbolTable
    extend T::Sig

    sig { void }
    # Construct a new SymbolTable.
    def initialize
      @scopes = T.let([], T::Array[Scope])
    end

    sig { void }
    # Create a new scope and push it on top of the stack.
    def push_scope
      @scopes.push(Scope.new)
    end

    sig { void }
    # Remove the scope at the top of the stack.
    def pop_scope
      @scopes.pop
    end

    sig { params(symbol: ILSymbol).void }
    # Insert a symbol into the top scope in the table.
    #
    # @param [ILSymbol] symbol The symbol to insert.
    def insert(symbol)
      T.unsafe(@scopes[-1]).insert(symbol)
    end

    sig { params(key: String).returns(T.nilable(ILSymbol)) }
    # Search for a symbol in the entire scope stack. If multiple copies of the
    # symbol are present, the one in the topmost scope will be returned.
    #
    # @param [String] key The key of the symbol to search for.
    # @return [T.nilable(ILSymbol)] The topmost symbol with the given key. If
    #   no such symbol exists in the table it will return +nil+.
    def lookup(key)
      @scopes.reverse_each do |s|
        symbol = s.lookup(key)
        if symbol then return symbol end
      end
      nil
    end

    sig { returns(T.nilable(Scope)) }
    # Get the scope at the top of the stack.
    #
    # @return [T.nilable(Scope)] The topmost scope. If there are no scopes
    #   in the table then it will return +nil+.
    def top_scope
      @scopes[-1]
    end
  end
end
