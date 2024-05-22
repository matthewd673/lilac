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
  # TODO
end
