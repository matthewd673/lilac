# typed: strict
require "sorbet-runtime"
require_relative "il"

# A Visitor is designed to aid in traversing lists, trees, and etc. that
# contain objects of many different classes or subclasses.
class Visitor
  extend T::Sig

  Lambda = T.type_alias {
    T.proc.params(arg0: Visitor, arg1: T.untyped, arg2: T.untyped)
      .returns(T.untyped)
  }

  LambdaHash = T.type_alias {
    T::Hash[T::Class[T.untyped], Lambda]
  }

  sig { params(visit_lambdas: LambdaHash).void }
  # Construct a new Visitor with a hash of Lambdas.
  #
  # @param [LambdaHash] visit_lambdas A Hash of classes -> Lambdas which will
  #   be used by +visit+ calls on this Visitor.
  def initialize(visit_lambdas)
    @visit_lambdas = visit_lambdas
  end

  sig { params(obj: T.untyped, ctx: T.untyped).returns(T.untyped) }
  # Visit an object using the Visitor's visit Lambdas.
  #
  # @param [T.untyped] obj The object to visit. The appropriate visit Lambda
  #   will be chosen according to its class and ancestors.
  #
  # @param [T.untyped] ctx An optional context object which will be ignored by
  #   the Visitor and passed through to the visit Lambda.
  def visit(obj, ctx: nil)
    obj.class.ancestors.each { |a|
      if not @visit_lambdas.include?(a) then next end

      l = @visit_lambdas[a]
      if not l # to appease call below
        raise("Visitor has a NIL lambda registered for #{a}")
      end

      return l.call(self, obj, ctx)
    }

    raise("Visitor does not support #{obj.class} or its ancestors")
  end
end
