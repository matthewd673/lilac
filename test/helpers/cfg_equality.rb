# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../lib/analysis/cfg"

module CFGEquality
  extend T::Sig

  include Lilac::Analysis

  sig { params(a: CFG, b: CFG).returns(T::Boolean) }
  def self.eql?(a, b)
    # clone so IDs can be overwritten
    a = a.clone
    b = b.clone

    # must have same number of nodes and edges
    if a.nodes_length != b.nodes_length || a.edges_length != b.edges_length
      return false
    end

    true

    # TODO: more in-depth equality check

    # get preorder- and postorder-numbering of each node for each tree
    # a_pre = a.preorder_numbering(a.entry)
    # b_pre = b.preorder_numbering(b.entry)

    # a_post = a.postorder_numbering(a.entry)
    # b_post = b.postorder_numbering(b.entry)

    # # combine pre and post numbers into new IDs
    # a.each_node { |n| n.id = "#{a_pre[n]},#{a_post[n]}" }
    # b.each_node { |n| n.id = "#{b_pre[n]},#{b_post[n]}" }

    # a.each_node { |n| puts "a => #{n.id}" }
    # b.each_node { |n| puts "b => #{n.id}" }
  end
end
