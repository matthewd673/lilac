# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "il"

module Lilac
  # An ILWalker traverses an IL object and visits each node in it.
  class ILWalker
    extend T::Sig

    sig { params(walk_lambda: T.proc.params(arg0: IL::ILObject).void).void }
    def initialize(walk_lambda)
      @walk_lambda = walk_lambda
    end

    sig { params(il: IL::ILObject).void }
    def walk(il)
      @walk_lambda.call(il)
      case il
      when IL::BinaryOp
        walk(il.left)
        walk(il.right)
      when IL::UnaryOp
        walk(il.value)
      when IL::Call # also covers ExternCall
        il.args.each { |a| walk(a) }
      when IL::Phi
        il.ids.each { |id| walk(id) }
      when IL::Definition
        walk(il.id)
        walk(il.rhs)
      when IL::JumpZero
        walk(il.cond)
      when IL::JumpNotZero
        walk(il.cond)
      when IL::Return
        walk(il.value)
      when IL::VoidCall
        walk(il.call)
      when IL::FuncParam
        walk(il.id)
      when IL::FuncDef
        il.params.each { |p| walk(p) }
        il.stmt_list.each { |s| walk(s) }
      when IL::Program
        il.stmt_list.each { |s| walk(s) }
      end
    end
  end
end
