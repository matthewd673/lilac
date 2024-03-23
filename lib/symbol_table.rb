# typed: strict
require "sorbet-runtime"
require_relative "il"

class ILSymbol
  extend T::Sig

  sig { returns(String) }
  attr_reader :key
  sig { returns(IL::Type) }
  attr_reader :type

  sig { params(key: String, type: IL::Type).void }
  def initialize(key, type)
    @key = key
    @type = type
  end
end

class Scope
  extend T::Sig

  sig { void }
  def initialize
    @symbols = T.let({}, T::Hash[String, ILSymbol])
  end

  sig { params(symbol: ILSymbol).void }
  def insert(symbol)
    @symbols[symbol.key] = symbol
  end

  sig { params(key: String).returns(T.nilable(ILSymbol)) }
  def lookup(key)
    @symbols[key]
  end
end

class SymbolTable
  extend T::Sig

  sig { void }
  def initialize
    @scopes = T.let([], T::Array[Scope])
  end

  sig { void }
  def push_scope
    @scopes.push(Scope.new)
  end

  sig { void }
  def pop_scope
    @scopes.pop
  end

  sig { params(symbol: ILSymbol).void }
  def insert(symbol)
    T.unsafe(@scopes[-1]).insert(symbol)
  end

  sig { params(key: String).returns(T.nilable(ILSymbol)) }
  def lookup(key)
    @scopes.reverse_each { |s|
      symbol = s.lookup(key)
      if symbol then return symbol end
    }
    return nil
  end
end
