# typed: strict
require "sorbet-runtime"
require_relative "debugger"
require_relative "../graph"
require_relative "../analysis/bb"

# The GraphVisualizer module provides functions to visualize Graph objects.
# It also includes special features to enhance CFG visualizations.
module Debugger::GraphVisualizer
  extend T::Sig

  sig { params(graph: Graph[T.untyped]).returns(String) }
  # Generate a String representation of the graph in the Graphviz DOT language.
  #
  # @param [Graph] graph The graph to visualize.
  # @return [String] A String containing DOT code.
  def self.generate_graphviz(graph)
    str = "// Generated by Lilac\n"
    str += "digraph {\n"

    # define blocks
    graph.each_node { |n|
      name = n.to_s
      label = name
      shape = "box"

      # special case for CFGs: make ENTRY and EXIT pretty
      if n.is_a?(Analysis::BB)
        name = n.id
        label = n.id
        if n.id == Analysis::CFG::ENTRY
          label = "ENTRY"
          shape = "diamond"
        elsif n.id == Analysis::CFG::EXIT
          label = "EXIT"
          shape = "diamond"
        end
      end

      str += "#{name} [label=#{label} shape=#{shape}]\n"
    }

    # define edges
    graph.each_edge { |e|
      from_name = e.from.id
      to_name = e.to.id

      color = "black"
      # special case for CFGs: highlight cond_branch edges
      if e.is_a?(Analysis::CFG::Edge)
        if e.cond_branch
          color = "blue"
        end
      end

      str += "#{from_name} -> #{to_name} [constraint=false color=#{color}]\n"
    }

    str += "}"
  end
end
