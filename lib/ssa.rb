# typed: strict
require "sorbet-runtime"
require_relative "pass"
require_relative "il"
require_relative "graph"
require_relative "analysis"
require_relative "analysis/bb"
require_relative "analysis/cfg"

class SSA < Pass
  extend T::Sig

  include Analysis

  sig { void }
  def initialize
    @id = T.let("ssa", String)
    @description = T.let("Transform a CFG into SSA form", String)
  end

  sig { params(cfg: CFG, funcdef: T.nilable(IL::FuncDef)).void }
  def run(cfg, funcdef: nil)
    # find and split all critical edges
    critical_edges = find_critical_edges(cfg)
    critical_edges.each { |e|
      split_edge(cfg, e)
    }

    # TODO
    raise("Unimplemented")
  end

  private

  sig { params(cfg: CFG, edge: Graph::Edge[BB]).void }
  def split_edge(cfg, edge)
    # delete old edge
    cfg.delete_edge(edge)

    # create new block in the middle
    new_id = cfg.max_block_id + 1
    new_block = BB.new(new_id, [])
    cfg.add_block(new_block)

    # create new edges to and from the new block
    cfg.create_edge(edge.from, new_block)
    cfg.create_edge(new_block, edge.to)
  end

  sig { params(cfg: CFG).returns(T::Array[Graph::Edge[BB]]) }
  def find_critical_edges(cfg)
    critical_edges = []

    cfg.each_edge { |e|
      if cfg.predecessors_length(e.to) > 1 and
         cfg.successors_length(e.from) > 1
        critical_edges.push(e)
      end
    }

    return critical_edges
  end
end
