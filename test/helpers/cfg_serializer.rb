# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "yaml"
require_relative "../../lib/analysis/cfg"

class CFGSerializer
  extend T::Sig

  include Lilac

  sig { params(cfg: Analysis::CFG).void }
  def initialize(cfg)
    @cfg = cfg
  end

  sig { returns(String) }
  def serialize
    obj = {}

    nodes = []
    @cfg.each_node { |n| nodes.push(n.id) }
    obj["nodes"] = nodes

    edges = []
    @cfg.each_edge { |e| edges.push({ "from" => e.from.id, "to" => e.to.id }) }
    obj["edges"] = edges

    YAML.dump(obj)
  end
end

class CFGDeserializer
  extend T::Sig

  include Lilac

  sig { params(string: String).void }
  def initialize(string)
    @string = string
  end

  sig { returns(Analysis::CFG) }
  def deserialize
    obj = YAML.load(@string)

    cfg = Analysis::CFG.new

    node_refs = {}

    obj["nodes"].each do |n|
      node_refs[n] = Analysis::BB.new(n)
      cfg.add_node(node_refs[n])
    end

    obj["edges"].each do |e|
      cfg.add_edge(Graph::Edge.new(node_refs[e["from"]], node_refs[e["to"]]))
    end

    cfg
  end
end
