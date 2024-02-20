# typed: strict
require "sorbet-runtime"
require_relative "il"

class Visitor
  extend T::Sig

  LAMBDA = T.type_alias {
    T.proc.params(arg0: Visitor, arg1: T.untyped).returns(T.untyped)
  }

  LAMBDA_HASH = T.type_alias {
    T::Hash[T::Class[T.untyped], LAMBDA]
  }

  sig { params(visit_lambdas: LAMBDA_HASH).void }
  def initialize(visit_lambdas)
    @visit_lambdas = visit_lambdas
  end

  sig { params(object: T.untyped).returns(T.untyped) }
  def visit(object)
    object.class.ancestors.each { |a|
      if not @visit_lambdas.include?(a) then next end

      l = @visit_lambdas[a]
      if not l # to appease call below
        raise("Visitor has a NIL lambda registered for #{a}")
      end

      return l.call(self, object)
    }

    raise("Visitor does not support #{object.class} or its ancestors")
  end
end
