# typed: strict
require "sorbet-runtime"
require_relative "il"

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
  def initialize(visit_lambdas)
    @visit_lambdas = visit_lambdas
  end

  sig { params(obj: T.untyped, ctx: T.untyped).returns(T.untyped) }
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
